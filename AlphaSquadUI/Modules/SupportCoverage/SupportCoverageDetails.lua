-- Optional bounded detail transport for the controlled test build. ID 507 is UNRESERVED.
-- No code execution, arbitrary table deserialization, DPS, chat messages, or item links beyond build facts.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Details = {ID=507, VERSION=1, MAX_BYTES=4096, CHUNK_BYTES=120, MAX_PARTS=35}
SC.Details = Details
local allowed = {capabilities=true}
for _, key in ipairs(SC.Audit.order) do allowed[key] = true end

local function Escape(text)
    return tostring(text):gsub("([%%\r\n])", function(c) return string.format("%%%02X", string.byte(c)) end)
end
local function Unescape(text)
    if text:gsub("%%[%x][%x]", ""):find("%%") then return nil end
    return text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
end
function Details.Checksum(text)
    local sum = 17
    for index=1,#text do sum = (sum * 31 + text:byte(index)) % 16777215 end
    return sum
end
function Details.Encode(snapshot)
    local lines = {}
    for _, key in ipairs(SC.Audit.order) do
        local value = SC.Audit.Value(snapshot, key)
        if value ~= nil then lines[#lines + 1] = key .. "=" .. Escape(value) end
    end
    local caps={}
    for key in pairs(snapshot and snapshot.capabilities or {}) do
        if SC.Catalog.effects[key] then caps[#caps+1]=key end
    end
    table.sort(caps)
    lines[#lines+1]="capabilities="..Escape(table.concat(caps,","))
    local text = table.concat(lines, "\n")
    if #text > Details.MAX_BYTES then return nil end
    return text
end
function Details.Decode(text)
    if type(text) ~= "string" or #text > Details.MAX_BYTES then return nil end
    local values, count = {}, 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line ~= "" then
            local key, value = line:match("^([a-z]+)=(.*)$")
            if not key or not allowed[key] or values[key] ~= nil then return nil end
            value = Unescape(value)
            if value == nil then return nil end
            values[key] = value
            count = count + 1
        end
    end
    return values, count
end

function SC:QueueBuildDetails(force)
    if not self.share or not self.share.detailProtocol or self.inCombat or not self.localSnapshot then return end
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return end
    local text = Details.Encode(self.localSnapshot)
    if not text then self.share.detailError = "Build detail exceeds the transport limit; fields remain unknown."; return end
    if self.share.detailTransfer and self.share.detailTransfer.text==text then return end
    if not force and text == self.share.lastDetailText and self.NowMs()-(self.share.lastDetailAt or 0)<60000 then return end
    local revision = ((self.share.detailRevision or 0) % 65534) + 1
    self.share.detailRevision = revision
    local transfer = {text=text, revision=revision, index=1, total=math.max(1, math.ceil(#text/Details.CHUNK_BYTES)), checksum=Details.Checksum(text)}
    self.share.detailTransfer = transfer
    local function SendNext()
        if not SC.share or SC.share.detailTransfer ~= transfer then return end
        if not SC.sv.enabled or not SC.sv.shareData or not SC.sv.experimentalSharing or not SC:IsGrouped() then SC.share.detailTransfer=nil; return end
        if SC.inCombat then SC.share.detailTransfer=nil; SC.share.lastDetailText=nil; return end
        local protocol = SC.share.detailProtocol
        if protocol.IsEnabled and not protocol:IsEnabled() then SC.share.detailTransfer=nil; return end
        local first = (transfer.index - 1) * Details.CHUNK_BYTES + 1
        local ok, sent = pcall(protocol.Send, protocol, {version=Details.VERSION, kind=1, revision=revision,
            index=transfer.index, total=transfer.total, checksum=transfer.checksum,
            body=text:sub(first, first + Details.CHUNK_BYTES - 1)}, {isRelevantInCombat=false, replaceQueuedMessages=false})
        if not ok or not sent then SC.share.detailTransfer=nil; return end
        transfer.index = transfer.index + 1
        if transfer.index <= transfer.total then zo_callLater(SendNext, 3500)
        else SC.share.lastDetailText=text; SC.share.lastDetailAt=SC.NowMs(); SC.share.detailTransfer=nil end
    end
    zo_callLater(SendNext, 300 + (self.NowMs() % 900))
end

function SC:OnDetailData(unitTag, data)
    if not self.sv.enabled or not self.sv.experimentalSharing or not self:IsCurrentGroupMember(unitTag) or self:IsSelf(unitTag) then return end
    if type(data) ~= "table" or data.version ~= Details.VERSION or type(data.body) ~= "string" or #data.body > Details.CHUNK_BYTES then return end
    if data.kind==3 then if self.OnVerifiedLive then self:OnVerifiedLive(unitTag,data) end; return end
    if data.kind==0 then if self.OnPullIdentity then self:OnPullIdentity(unitTag,data) end; return end
    local key, now = self:GetPlayerKey(unitTag), self.NowMs()
    local peer = self.peerData[key]
    if not peer then peer = self:ScanLimitedUnit(unitTag); self.peerData[key] = peer end
    if data.kind == 2 then
        if data.checksum~=Details.Checksum(data.body) then return end
        -- Counts are self-reported session evidence, not proof of the exact potion item.
        local uses, inferred, fightStarted, category, cooldown = data.body:match("^(%d+),(%d+),(%d+),([01]),([01])$")
        uses, inferred, fightStarted = tonumber(uses), tonumber(inferred), tonumber(fightStarted)
        if not uses or uses > 1000 or not inferred or inferred > 1000 then return end
        peer.potionEvidence = {count=uses, inferredCount=inferred, evidence="ASUI_SELF_REPORT", receivedAt=now, token=fightStarted, exactItemVerified=false, categoryMonitoring=category=="1", cooldownMonitoring=cooldown=="1"}
        if self.pull and self.pull.groupToken and fightStarted and self.pull.groupToken==fightStarted then self.pull.potions[key] = SC.Audit.Copy(peer.potionEvidence) end
        return
    end
    if data.kind ~= 1 or type(data.total) ~= "number" or data.total < 1 or data.total > Details.MAX_PARTS
        or type(data.index) ~= "number" or data.index < 1 or data.index > data.total or data.index % 1 ~= 0
        or data.total % 1 ~= 0 or type(data.revision) ~= "number" or data.revision < 1 or data.revision > 65535 or data.revision % 1 ~= 0
        or type(data.checksum) ~= "number" or data.checksum < 0 or data.checksum > 16777214 or data.checksum % 1 ~= 0 then return end
    -- Ignore duplicate completed revisions while current. A sender may restart after a UI reload.
    if peer.detailRevision == data.revision and peer.detailAt and now-peer.detailAt < 60000 then return end
    self.detailReceivers = self.detailReceivers or {}
    local transfer = self.detailReceivers[key]
    if transfer and now - transfer.at > 180000 then transfer=nil; self.detailReceivers[key]=nil end
    if not transfer or transfer.revision ~= data.revision then
        if transfer and data.index ~= 1 then return end
        transfer = {revision=data.revision, total=data.total, checksum=data.checksum, parts={}, at=now, bytes=0}
        self.detailReceivers[key] = transfer
        peer.auditValues = nil
    end
    if transfer.total ~= data.total or transfer.checksum ~= data.checksum then return end
    if transfer.parts[data.index] then return end
    transfer.parts[data.index] = data.body
    transfer.bytes = transfer.bytes + #data.body
    if transfer.bytes > Details.MAX_BYTES then self.detailReceivers[key]=nil; return end
    for index=1,transfer.total do if not transfer.parts[index] then return end end
    local text = table.concat(transfer.parts)
    self.detailReceivers[key] = nil
    if Details.Checksum(text) ~= transfer.checksum then return end
    local values = Details.Decode(text)
    if not values then return end
    peer.auditValues, peer.detailAt, peer.detailsEvidence = values, now, "ASUI_SHARED_FACTS"
    peer.detailRevision = data.revision
    peer.detailChecksum = transfer.checksum
    peer.detailAliveAt = now
    peer.detailCapabilities={}
    for key in tostring(values.capabilities or ""):gmatch("[^,]+") do
        if SC.Catalog.effects[key] then peer.detailCapabilities[key]={sources={["ASUI detail"]=true},evidence="ASUI_SHARED_FACTS"} end
    end
    peer.asui = true
    if not peer.buildVerified then peer.dataQuality = "ASUI DETAILS" end
    self:ScheduleRefresh("build details", 100)
end

function SC:SharePotionEvidence()
    if not self.pull or not self.pull.groupToken or not self.share or not self.share.detailProtocol then return end
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return end
    local now = self.NowMs()
    if now - (self.share.lastPotionAt or 0) < 5000 then return end
    local entry = self.pull.potions[self:GetPlayerKey("player")]
    if not entry then return end
    local protocol = self.share.detailProtocol
    if protocol.IsEnabled and not protocol:IsEnabled() then return end
    local body = string.format("%d,%d,%d,%d,%d", entry.count or 0, entry.inferredCount or 0, self.pull.groupToken or 0, entry.categoryMonitoring and 1 or 0, entry.cooldownMonitoring and 1 or 0)
    local ok, sent = pcall(protocol.Send, protocol, {version=Details.VERSION, kind=2, revision=1, index=1, total=1,
        checksum=Details.Checksum(body), body=body}, {isRelevantInCombat=true, replaceQueuedMessages=false})
    if ok and sent then self.share.lastPotionAt=now end
end

function SC:InitializeDetailSharing(LGB, handler)
    if not LGB.CreateStringField then self.share.detailError="LibGroupBroadcast string fields unavailable"; return end
    local ok, protocol = pcall(function()
        local p = handler:DeclareProtocol(Details.ID, "AlphaSquadSupportDetailsTest")
        p:AddField(LGB.CreateNumericField("version", {minValue=0,maxValue=7}))
        p:AddField(LGB.CreateNumericField("kind", {minValue=0,maxValue=3}))
        p:AddField(LGB.CreateNumericField("revision", {minValue=0,maxValue=65535}))
        p:AddField(LGB.CreateNumericField("index", {minValue=0,maxValue=63}))
        p:AddField(LGB.CreateNumericField("total", {minValue=0,maxValue=63}))
        p:AddField(LGB.CreateNumericField("checksum", {minValue=0,maxValue=16777215}))
        p:AddField(LGB.CreateStringField("body", {maxLength=Details.CHUNK_BYTES}))
        p:OnData(function(tag, data) SC:OnDetailData(tag, data) end)
        assert(p:Finalize({isRelevantInCombat=false, replaceQueuedMessages=false}), "detail protocol validation failed")
        return p
    end)
    if ok then self.share.detailProtocol=protocol else self.share.detailError=tostring(protocol) end
end
