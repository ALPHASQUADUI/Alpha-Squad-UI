-- Work counters validate lifecycle boundaries, not in-game frame times.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
local queued,events,updates,updateIntervals={},{},{},{}
local now,groupSize=10000,2
local names={"EVENT_ADD_ON_LOADED","EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_DEACTIVATED",
    "EVENT_PLAYER_COMBAT_STATE","EVENT_EFFECT_CHANGED","EVENT_GROUP_MEMBER_JOINED",
    "EVENT_GROUP_MEMBER_LEFT","EVENT_GROUP_UPDATE","EVENT_ACTIVE_QUICKSLOT_CHANGED"}
for index,name in ipairs(names) do _G[name]=index end
EVENT_MANAGER={RegisterForEvent=function(_,name,event,fn) events[name]=fn end,
    UnregisterForEvent=function(_,name) events[name]=nil end,AddFilterForEvent=function() end,
    RegisterForUpdate=function(_,name,interval,fn) updates[name]=fn;updateIntervals[name]=interval end,
    UnregisterForUpdate=function(_,name) updates[name]=nil;updateIntervals[name]=nil end}
function zo_callLater(fn) queued[#queued+1]=fn end
function GetGameTimeMilliseconds() return now end
function GetGroupSize() return groupSize end
function IsUnitGrouped() return groupSize>0 end
function IsUnitInCombat() return false end
function IsUnitDead() return false end
function IsUnitOnline() return true end
AlphaSquadUI={Modules={}}
assert(loadfile("AlphaSquadUI/Core/Events.lua"))()
assert(loadfile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverage.lua"))()
assert(loadfile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuild.lua"))()
local SC=AlphaSquadUI.Modules.SupportCoverage
SC.initialized=true;SC.loading=false
SC.sv={enabled=true,visible=true,shareData=false,experimentalSharing=false}
local foodReads,potionReads,mundusReads,scans,rosters,evaluations,renders=0,0,0,0,0,0,0
local foodId=101
SC.ScanFood=function() foodReads=foodReads+1;return {verified=true,active=true,abilityId=foodId,timeEnds=200} end
SC.ScanPotion=function() potionReads=potionReads+1;return {known=true,link="fixture-potion"} end
SC.ScanMundus=function() mundusReads=mundusReads+1;return {known=true,ids={201}} end
SC.ScanLocalPlayer=function(self)
    scans=scans+1
    return {food=self:ScanFood(),potion=self:ScanPotion(),mundus=self:ScanMundus(),dead=false,connected=true}
end
SC.BuildRoster=function() rosters=rosters+1 end
SC.EvaluateCoverage=function() evaluations=evaluations+1 end
SC.RefreshHUD=function() renders=renders+1 end
SC.RefreshSettings=function() end
SC:RegisterEvents()
SC:Refresh("initial")
check(scans==1 and foodReads==1 and potionReads==1 and mundusReads==1,
    "A complete snapshot is not immediately rescanned for readiness")
local function Flush()
    local pending=queued;queued={}
    for _,fn in ipairs(pending) do fn() end
end
local effect=events.AlphaSquadUI_SupportCoverage_LocalEffects
for _=1,25 do effect(nil,nil,nil,nil,"player") end
check(#queued==1,"A burst of unrelated local effects queues one readiness check")
Flush()
check(scans==1 and foodReads==2 and rosters==1 and evaluations==1 and renders==1,
    "Unchanged readiness does not rebuild a roster, coverage model or HUD")
foodId=102;effect(nil,nil,nil,nil,"player");Flush()
check(scans==1 and rosters==2 and evaluations==2,
    "A real readiness change still updates group preparation without a full build scan")
effect(nil,nil,nil,nil,"player")
SC:ScheduleRefresh("shared peer changed",100)
check(#queued==1,"A peer update coalesces with an existing readiness task")
Flush()
check(rosters==3 and evaluations==3,
    "A peer update upgrades the pending lightweight task to a full coverage refresh")
SC:ScheduleRefresh("roster changed",100)
effect(nil,nil,nil,nil,"player");Flush()
check(rosters==4,"A later readiness event cannot downgrade a queued roster refresh")
effect(nil,nil,nil,nil,"player");SC:MarkScanDirty("equipment changed");Flush()
check(scans==2 and rosters==5 and foodReads==6,
    "An equipment change upgrades the queued task and scans readiness only once")
local prior=evaluations
now=196000;SC:Refresh("safety")
check(evaluations==prior+1,
    "The safety refresh still reevaluates expiry thresholds without a changed readiness signature")
local pauses,resumes=0,0
SC.PauseBuildSharing=function() pauses=pauses+1 end
SC.ResumeBuildSharing=function() resumes=resumes+1;return true end
local beforeScans,beforeFood=scans,foodReads
SC:OnCombatState(true);SC:MarkScanDirty("combat equipment");Flush()
check(scans==beforeScans and foodReads==beforeFood and pauses==1,
    "Combat pauses sharing and performs neither build nor readiness scans")
SC:OnCombatState(false);Flush()
check(scans==beforeScans+1 and resumes==1,
    "Leaving combat resumes transport and consumes the deferred build invalidation")
SC.peerData={peer={}}
events.AlphaSquadUI_SupportCoverage_Left()
check(pauses==2 and next(SC.peerData)==nil and resumes==1,
    "A departure revokes queued sharing and drops peer state before deferred work")
Flush()
check(resumes==2 and not SC.resumeSharingPending,
    "Sharing resumes once after the updated group roster can settle")
events.AlphaSquadUI_SupportCoverage_Deactivated()
check(pauses==3 and SC.loading and not SC:NeedsBuildData(),
    "Loading revokes transport before suspending gameplay subscriptions")

-- Saved consent is not proof that native sending remains ON. Preserve only
-- lightweight wake/invalidation work while no active consumer needs a scan.
SC.loading=false;SC.inCombat=false;SC.sv.enabled=false
SC.sv.shareData=true;SC.sv.experimentalSharing=true
local nativeStatus,sends="LOCAL",0
SC.GetSharingStatus=function() return nativeStatus end
SC.share={available=true,lastSendAt=now,protocol={IsEnabled=function() return nativeStatus=="SHARING" end}}
SC.ShareLocalSnapshot=function(self)
    if nativeStatus~="SHARING" or self.inCombat or self.loading then return false end
    sends=sends+1;self.share.lastSendAt=now;return true
end
SC:UpdateRuntime()
check(events.AlphaSquadUI_SupportCoverage_Combat and events.AlphaSquadUI_SupportCoverage_LocalEffects
    and updateIntervals.AlphaSquadUI_SupportCoverage_Safety==60000,
    "Tracking OFF preserves lightweight lifecycle guards and the slow native-state wake timer")
beforeScans,beforeFood=scans,foodReads
SC:MarkScanDirty("equipment changed while native OFF");Flush()
updates.AlphaSquadUI_SupportCoverage_Safety()
check(scans==beforeScans and foodReads==beforeFood and sends==0 and SC.scanDirty,
    "Tracking OFF and native OFF perform no build or readiness capture and retain dirty state")
SC:ScheduleRefresh("language or interface changed",50,true);Flush()
check(scans==beforeScans and sends==0,"A UI refresh cannot emit build data while native sending is OFF")
nativeStatus="SHARING"
updates.AlphaSquadUI_SupportCoverage_Safety()
check(scans==beforeScans+1 and sends==1 and not SC.scanDirty,
    "An external native ON resumes with one fresh capture on the retained heartbeat")
SC:ScheduleRefresh("cached interface presentation",50,true);Flush()
check(scans==beforeScans+1 and sends==1,
    "An unchanged presentation refresh does not scan or send a new build after sharing resumes")
nativeStatus="LOCAL";SC:MarkScanDirty("another hidden build change");Flush()
nativeStatus="SHARING";SC:UpdateRuntime();SC:MarkScanDirty("explicit sharing ON");Flush()
check(scans==beforeScans+2 and sends==2,
    "An explicit sharing ON consumes the retained invalidation without waiting for the heartbeat")
nativeStatus="LOCAL";beforeScans=scans;local pausesBefore=pauses
SC:OnCombatState(true);SC:MarkScanDirty("combat build change");Flush()
check(pauses==pausesBefore+1 and scans==beforeScans and SC.scanDirty,
    "Native OFF does not remove combat queue revocation or consume deferred build changes")
nativeStatus="SHARING";SC:OnCombatState(false);Flush()
check(scans==beforeScans+1 and sends==3,
    "Leaving combat resumes one fresh permitted sender capture after an external ON")
print("Performance lifecycle: "..assertions.." assertions passed; no ESO frame-time measurement")
