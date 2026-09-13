-- Small session messages sent through the experimental detail protocol.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Details=SC.Details

local function Integer(value, minimum, maximum)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge
        or value%1~=0 or value<minimum or value>maximum then return nil end
    return value
end

function SC:SendDetailFrame(kind,body)
    local protocol=self.share and self.share.detailProtocol
    if not protocol or type(body)~="string" or #body>Details.MAX_BYTES or not self.sv.enabled
        or not self.sv.shareData or not self.sv.experimentalSharing or not self:IsGrouped() then return false end
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end
    local ok,queued=pcall(protocol.Send,protocol,{version=Details.VERSION,kind=kind,revision=1,
        checksum=Details.Checksum(body),body=body},
        {isRelevantInCombat=true,replaceQueuedMessages=false})
    return ok and queued==true
end

function SC:SharePullIdentity()
    if not self.pull or not self.inCombat or not self:IsRaidLead() or not self.pull.meta.timestamp then return end
    local now=self.NowMs()
    self.pull.groupToken=self.pull.meta.timestamp
    local body=string.format("%d,%d",self.pull.groupToken,self.pull.meta.zoneId or 0)
    if body==self.share.lastPullIdentityText and now-(self.share.lastPullIdentityAt or 0)<30000 then return end
    if self:SendDetailFrame(0,body) then
        self.share.lastPullIdentityAt,self.share.lastPullIdentityText=now,body
    end
end

function SC:OnPullIdentity(unitTag,data)
    if not self.pull or not self.inCombat or self.Try(IsUnitGroupLeader,unitTag)~=true then return end
    local token,zone=data.body:match("^(%d+),(%d+)$")
    token,zone=Integer(token,0,4294967295),Integer(zone,0,2147483647)
    if not token or not zone or not self.pull.meta.timestamp or math.abs(token-self.pull.meta.timestamp)>2 then return end
    if token==self.lastCompletedGroupToken or zone~=(self.pull.meta.zoneId or 0) then return end
    if self.pull.groupToken and self.pull.groupToken~=token then return end
    self.pull.groupToken=token
end
