-- Minimal opt-in sender. The packaged shared modules use a local host namespace.
AlphaSquadBuildShare={disabled=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage~=nil}
if AlphaSquadBuildShare.disabled then return end
local SC={peerData={},catalogPatch="U50",name="BuildShare",inCombat=false}
AlphaSquadBuildShare.Host={Modules={SupportCoverage=SC}}
SC.NowMs=function() return GetGameTimeMilliseconds() end
function SC:GetPlayerKey(tag) return GetUnitDisplayName(tag) or "" end
function SC:IsGrouped() return IsUnitGrouped("player")==true end
-- The sender has no roster windows and does not rescan when peers send messages.
function SC:ScheduleRefresh() end
