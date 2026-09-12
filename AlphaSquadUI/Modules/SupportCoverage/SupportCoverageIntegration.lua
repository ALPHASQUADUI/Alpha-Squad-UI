-- Integration guards for the recovered Support Coverage test build.
local SC=AlphaSquadUI.Modules.SupportCoverage
local initializeSharing=SC.InitializeSharing
function SC:InitializeSharing()
    if not self.sv or not self.sv.enabled or not self.sv.experimentalSharing then
        self.share.available=false
        self.share.error="Experimental sharing is OFF. Unreserved protocol IDs are for controlled tests only."
        return
    end
    if self.share.handler then return end
    initializeSharing(self)
end
local shareBuild,shareLive,sharePlan=SC.ShareLocalSnapshot,SC.ShareLiveSnapshot,SC.BroadcastPlan
function SC:ShareLocalSnapshot(reason)
    if not self.sv.enabled or not self.sv.experimentalSharing or self.inCombat then return false end
    return shareBuild(self,reason)
end
function SC:ShareLiveSnapshot()
    if not self.sv.enabled or not self.sv.experimentalSharing then return false end
    return shareLive(self)
end
function SC:BroadcastPlan()
    if not self.sv.enabled or not self.sv.experimentalSharing then return false end
    return sharePlan(self)
end
function SC:IsCurrentGroupMember(tag)
    if not tag or not self:IsGrouped() then return false end
    for index=1,math.min(12,self.Try(GetGroupSize) or 0) do
        local other=self.Try(GetGroupUnitTagByIndex,index) or ("group"..index)
        if other==tag or self.Try(AreUnitsEqual,other,tag)==true then return true end
    end
    return self:IsSelf(tag)
end
