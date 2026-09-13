-- Compact, signature-only build transport for the controlled test build. ID 507 is UNRESERVED.
-- Exact equipment links and arbitrary text never leave the client.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Details = {ID=507, VERSION=2, MAX_BYTES=64, MAX_HASH=16777214, FINGERPRINT_MODULUS=32767}
SC.Details = Details

local function Integer(value, minimum, maximum)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge
        or value%1~=0 or value<minimum or value>maximum then return nil end
    return value
end

Details.hashOrder = {
    "sets", "weapons", "traits", "enchants", "armor",
    "champion_all", "champion_combat", "champion_conditioning", "champion_world",
    "masteries", "skills", "food", "potion", "poisons", "mundus",
}

function Details.Hash(value)
    if value == nil then return nil end
    value = tostring(value)
    local hash = 17
    for index=1,#value do hash = (hash * 31 + value:byte(index)) % 16777215 end
    return hash
end

Details.Checksum = Details.Hash

local function Pack24(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then value=0 end
    value = math.max(0, math.min(Details.MAX_HASH, math.floor(value)))
    return string.char(math.floor(value/65536), math.floor(value/256)%256, value%256)
end

local function Unpack24(text, offset)
    local a,b,c = text:byte(offset, offset+2)
    if not a or not b or not c then return nil end
    return a*65536+b*256+c
end

local function AuditValue(snapshot, key)
    local scope = key:match("^champion_(.+)$")
    if scope then
        local value = SC.Audit.Value(snapshot, "champion")
        return SC.Audit.CompareValue("champion", value, string.upper(scope))
    end
    return SC.Audit.Value(snapshot, key)
end

function Details.BuildHashes(snapshot)
    local hashes, known = {}, 0
    for index,key in ipairs(Details.hashOrder) do
        local value = AuditValue(snapshot, key)
        if value ~= nil then
            hashes[key] = Details.Hash(value)
            known = known + 2^(index-1)
        end
    end
    return hashes, known
end

function Details.Encode(snapshot)
    local hashes, known = Details.BuildHashes(snapshot)
    local schema = Details.Hash(table.concat(Details.hashOrder, "|"))
    local parts = {
        string.char(Details.VERSION), Pack24(schema),
        string.char(math.floor(known/256)%256, known%256),
    }
    for _,key in ipairs(Details.hashOrder) do parts[#parts+1] = Pack24(hashes[key] or 0) end
    local body = table.concat(parts)
    if #body > Details.MAX_BYTES then return nil end
    return body
end

function Details.Decode(body)
    local expectedLength = 6 + #Details.hashOrder*3
    if type(body) ~= "string" or #body ~= expectedLength or body:byte(1) ~= Details.VERSION then return nil end
    local schema = Unpack24(body, 2)
    if schema ~= Details.Hash(table.concat(Details.hashOrder, "|")) then return nil end
    local high,low = body:byte(5,6)
    local known = high*256+low
    if known >= 2^#Details.hashOrder then return nil end
    local hashes = {}
    for index,key in ipairs(Details.hashOrder) do
        local hash = Unpack24(body, 7+(index-1)*3)
        local isKnown = math.floor(known/2^(index-1))%2 == 1
        if not hash or (not isKnown and hash ~= 0) then return nil end
        if isKnown then hashes[key] = hash end
    end
    return hashes, known
end

function SC:QueueBuildDetails(force)
    if not self.share or not self.share.detailProtocol or self.inCombat or not self.localSnapshot then return false end
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return false end
    local body = Details.Encode(self.localSnapshot)
    if not body then self.share.detailError = "Build signatures exceed the transport limit; fields remain unknown."; return false end
    local fingerprint=Details.Checksum(body)%Details.FINGERPRINT_MODULUS+1
    -- A detail frame is meaningful only after its matching summary was accepted
    -- by the transport queue. Otherwise a peer still advertising the previous
    -- fingerprint would reject it and wait for a much later detail heartbeat.
    if self.share.lastBuildFingerprint~=fingerprint then return false end
    if not force and body == self.share.lastDetailText and self.NowMs()-(self.share.lastDetailAt or 0)<90000 then return false end
    local protocol = self.share.detailProtocol
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end
    local revision = ((self.share.detailRevision or 0) % 65534) + 1
    local ok, sent = pcall(protocol.Send, protocol, {
        version=Details.VERSION, kind=1, revision=revision, checksum=Details.Checksum(body), body=body,
    }, {isRelevantInCombat=false, replaceQueuedMessages=false})
    if not ok or sent ~= true then return false end
    self.share.detailRevision, self.share.lastDetailText = revision, body
    self.share.lastDetailAt, self.share.detailError = self.NowMs(), nil
    return true
end

function SC:OnDetailData(unitTag, data)
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing
        or not self:IsCurrentGroupMember(unitTag) or self:IsSelf(unitTag) then return end
    if type(data) ~= "table" or data.version ~= Details.VERSION or type(data.body) ~= "string"
        or #data.body > Details.MAX_BYTES or type(data.checksum) ~= "number"
        or data.checksum < 0 or data.checksum > Details.MAX_HASH or data.checksum%1 ~= 0
        or data.checksum ~= Details.Checksum(data.body) then return end
    local kind=Integer(data.kind,0,2)
    if not kind then return end
    if kind==0 then if self.OnPullIdentity then self:OnPullIdentity(unitTag,data) end; return end
    local key, now = self:GetPlayerKey(unitTag), self.NowMs()
    local peer = self.peerData[key]
    if not peer then peer = self:ScanLimitedUnit(unitTag); self.peerData[key] = peer end
    if kind == 2 then
        local uses, inferred, fightStarted, category, cooldown = data.body:match("^(%d+),(%d+),(%d+),([01]),([01])$")
        uses, inferred = Integer(uses,0,1000), Integer(inferred,0,1000)
        fightStarted = Integer(fightStarted,0,4294967295)
        if not uses or not inferred or not fightStarted then return end
        if not self.pull or not self.pull.groupToken or self.pull.groupToken~=fightStarted then return end
        peer.potionEvidence = {count=uses, inferredCount=inferred, evidence="ASUI_SELF_REPORT", receivedAt=now,
            token=fightStarted, exactItemVerified=false, categoryMonitoring=category=="1", cooldownMonitoring=cooldown=="1"}
        self.pull.potions[key] = SC.Audit.Copy(peer.potionEvidence)
        return
    end
    local revision = tonumber(data.revision)
    if kind ~= 1 or not revision or revision<1 or revision>65535 or revision%1~=0 then return end
    if peer.detailRevision == revision and peer.detailAt and now-peer.detailAt < 90000 then return end
    local hashes = Details.Decode(data.body)
    if not hashes then return end
    local fingerprint=data.checksum%32767+1
    if peer.buildDetailFingerprint and peer.buildDetailFingerprint~=fingerprint then return end
    peer.auditHashes, peer.detailAt, peer.detailAliveAt = hashes, now, now
    peer.detailRevision, peer.detailChecksum = revision, data.checksum
    peer.detailBuildFingerprint=fingerprint
    peer.buildDetailFingerprint=peer.buildDetailFingerprint or fingerprint
    peer.detailsEvidence, peer.asui, peer.dataQuality = "ASUI_SHARED_SIGNATURES", true, "ASUI DETAILS"
    self:ScheduleRefresh("build signatures", 100)
end

function SC:SharePotionEvidence()
    if not self.pull or not self.pull.groupToken or not self.share or not self.share.detailProtocol then return end
    if not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return end
    local now = self.NowMs()
    local entry = self.pull.potions[self:GetPlayerKey("player")]
    if not entry then return end
    local body = string.format("%d,%d,%d,%d,%d", entry.count or 0, entry.inferredCount or 0,
        self.pull.groupToken or 0, entry.categoryMonitoring and 1 or 0, entry.cooldownMonitoring and 1 or 0)
    if body==self.share.lastPotionText and now-(self.share.lastPotionAt or 0)<30000 then return end
    if self:SendDetailFrame(2, body) then
        self.share.lastPotionAt, self.share.lastPotionText=now,body
    end
end

function SC:InitializeDetailSharing(LGB, handler)
    if self.share.detailProtocol or self.share.detailRegistrationAttempted then return end
    if not LGB or not LGB.CreateStringField then self.share.detailError="LibGroupBroadcast string fields unavailable"; return end
    self.share.detailRegistrationAttempted=true
    local ok, protocol = pcall(function()
        local p = handler:DeclareProtocol(Details.ID, "AlphaSquadSupportDetailsTest")
        p:AddField(LGB.CreateNumericField("version", {minValue=0,maxValue=7}))
        p:AddField(LGB.CreateNumericField("kind", {minValue=0,maxValue=3}))
        p:AddField(LGB.CreateNumericField("revision", {minValue=0,maxValue=65535}))
        p:AddField(LGB.CreateNumericField("checksum", {minValue=0,maxValue=16777215}))
        p:AddField(LGB.CreateStringField("body", {maxLength=Details.MAX_BYTES}))
        p:OnData(function(tag, data) SC:OnDetailData(tag, data) end)
        assert(p:Finalize({isRelevantInCombat=false, replaceQueuedMessages=false}), "detail protocol validation failed")
        return p
    end)
    if ok then self.share.detailProtocol=protocol else self.share.detailError=tostring(protocol) end
end
