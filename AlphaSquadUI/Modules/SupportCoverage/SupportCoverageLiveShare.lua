-- Verified-format live observations over the experimental detail protocol.
-- A catalog fingerprint prevents mixed-version masks from being misinterpreted.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Details=SC.Details
local keys=SC.Catalog:GetAllEffectKeys()
local schema=Details.Checksum(table.concat(keys,","))
local MAX=16777215
local function Set(mask,index) return mask+2^index end
local function Has(mask,index) return math.floor(mask/2^index)%2==1 end

function SC:SendDetailFrame(kind,body)
    local protocol=self.share and self.share.detailProtocol
    if not protocol or not self.sv.enabled or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return false end
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end
    if #body>Details.CHUNK_BYTES then return false end
    local ok,queued=pcall(protocol.Send,protocol,{version=Details.VERSION,kind=kind,revision=1,index=1,total=1,checksum=Details.Checksum(body),body=body},
        {isRelevantInCombat=true,replaceQueuedMessages=false})
    return ok and queued==true
end

function SC:ShareVerifiedLive()
    if not self.sv or not self.sv.enabled or not self.sv.experimentalSharing or not self.sv.shareData
        or not self.share or not self.share.detailProtocol or not self:IsGrouped()
        or not self.inCombat or not self.localLive or #keys>96 then return end
    local now=self.NowMs()
    if now-(self.share.lastVerifiedLiveAt or 0)<2500 then return end
    local up,known={0,0,0,0},{0,0,0,0}
    for index,key in ipairs(keys) do
        local mask=math.floor((index-1)/24)+1;local bit=(index-1)%24
        local present=self.localLive.capabilities[key]~=nil
        if present then up[mask]=Set(up[mask],bit) end
        if present or self.localLive.complete and self.effectReadableKeys[key] then known[mask]=Set(known[mask],bit) end
    end
    local text=Details.Encode(self.localSnapshot)
    local build=text and Details.Checksum(text) or 0
    local stagger=self.localLive.capabilities.stagger
    local stack=stagger and tonumber(stagger.stacks) or -1
    stack=math.max(-1,math.min(15,stack or -1))
    local values={schema,build,up[1],up[2],up[3],up[4],known[1],known[2],known[3],known[4],stack}
    local sentAt=self.Try(GetTimeStamp)
    if not sentAt or sentAt<0 or sentAt>4294967295 then return end
    -- Fixed 36-byte body: format, ten uint24 values, stack count, UTC send time.
    -- Text CSV would require roughly three times as many group-broadcast frames.
    local parts={string.char(2)}
    for index=1,10 do
        local value=math.floor(values[index])
        parts[#parts+1]=string.char(math.floor(value/65536),math.floor(value/256)%256,value%256)
    end
    parts[#parts+1]=string.char(stack+1)
    parts[#parts+1]=string.char(math.floor(sentAt/16777216)%256,math.floor(sentAt/65536)%256,math.floor(sentAt/256)%256,sentAt%256)
    if self:SendDetailFrame(3,table.concat(parts)) then self.share.lastVerifiedLiveAt=now end
end

function SC:OnVerifiedLive(unitTag,data)
    if #keys>96 or #data.body~=36 or data.body:byte(1)~=2 or data.checksum~=Details.Checksum(data.body) then return end
    local a,b,c,d=data.body:byte(33,36)
    local sentAt=a*16777216+b*65536+c*256+d
    local epoch=self.Try(GetTimeStamp)
    if not epoch or epoch-sentAt>5 or epoch-sentAt < -2 then return end
    local observedAt=self.NowMs()-math.max(0,epoch-sentAt)*1000
    local values={}
    for index=1,10 do
        local offset=2+(index-1)*3
        local a,b,c=data.body:byte(offset,offset+2)
        values[index]=a*65536+b*256+c
    end
    values[11]=data.body:byte(32)-1
    if values[1]~=schema or values[11]>15 then return end
    local caps,known={},{}
    for index,key in ipairs(keys) do
        local mask=math.floor((index-1)/24);local bit=(index-1)%24
        local present=Has(values[3+mask],bit);local readable=Has(values[7+mask],bit)
        if present and not readable then return end
        if readable then known[key]=true end
        if present then
            caps[key]={evidence="ASUI_OBSERVED",sources={["ASUI live"]=true}}
            if key=="stagger" and values[11]>=0 then caps[key].stacks=values[11] end
        end
    end
    local key=self:GetPlayerKey(unitTag)
    local peer=self.peerData[key] or self:ScanLimitedUnit(unitTag)
    self.peerData[key]=peer
    peer.liveCapabilities,peer.liveKnownKeys=caps,known
    peer.liveUpdatedAt,peer.verifiedLiveUpdatedAt=observedAt,observedAt
    peer.asui=true;peer.unitTag=unitTag
    if not peer.buildVerified then peer.dataQuality="ASUI LIVE" end
    if peer.detailChecksum and peer.detailChecksum==values[2] then
        peer.detailAliveAt=self.NowMs()
    elseif values[2]>0 and peer.detailChecksum and peer.detailChecksum~=values[2] then
        -- The peer reports a different build; do not keep old expectations marked PASS.
        peer.auditValues,peer.detailCapabilities,peer.detailAliveAt=nil,nil,nil
    end
end

function SC:SharePullIdentity()
    if not self.pull or not self.inCombat or not self:IsRaidLead() or not self.pull.meta.timestamp then return end
    local now=self.NowMs()
    self.pull.groupToken=self.pull.meta.timestamp
    if now-(self.share.lastPullIdentityAt or 0)<4500 then return end
    local body=string.format("%d,%d",self.pull.groupToken,self.pull.meta.zoneId or 0)
    if self:SendDetailFrame(0,body) then self.share.lastPullIdentityAt=now end
end

function SC:OnPullIdentity(unitTag,data)
    if not self.pull or not self.inCombat or self.Try(IsUnitGroupLeader,unitTag)~=true or data.checksum~=Details.Checksum(data.body) then return end
    local token,zone=data.body:match("^(%d+),(%d+)$")
    token,zone=tonumber(token),tonumber(zone)
    if not token or not self.pull.meta.timestamp or math.abs(token-self.pull.meta.timestamp)>2 then return end
    if token==self.lastCompletedGroupToken or zone~=(self.pull.meta.zoneId or 0) then return end
    if self.pull.groupToken and self.pull.groupToken~=token then return end
    self.pull.groupToken=token
end
