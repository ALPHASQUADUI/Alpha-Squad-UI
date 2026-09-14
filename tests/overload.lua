-- Overload is a behavior of one native Ultimate HUD, never a separate module.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local events,updates,later={},{},{}
EVENT_ADD_ON_LOADED=1;EVENT_EFFECT_CHANGED=2;REGISTER_FILTER_UNIT_TAG=3
EVENT_PLAYER_ACTIVATED=4;EVENT_PLAYER_DEACTIVATED=5
HOTBAR_CATEGORY_PRIMARY=1;HOTBAR_CATEGORY_BACKUP=2
ACTION_BAR_ULTIMATE_SLOT_INDEX=7;COMBAT_MECHANIC_FLAGS_ULTIMATE=10
EVENT_MANAGER={RegisterForEvent=function(_,name,event,callback) events[name]={event=event,callback=callback} end,
 UnregisterForEvent=function(_,name) events[name]=nil end,AddFilterForEvent=function() end,
 RegisterForUpdate=function(_,name,interval,callback) updates[name]=callback end,UnregisterForUpdate=function(_,name) updates[name]=nil end}
SLASH_COMMANDS={};function d() end
function zo_callLater(fn,delay) later[#later+1]={fn=fn,delay=delay} end
local now=20000
function GetGameTimeMilliseconds() return now end
function GetWorldName() return "TestWorld" end
local legacy={}
ZO_SavedVars={NewAccountWide=function() return legacy end}
AlphaSquadUI={Modules={},Settings={AnyExclusiveWindowVisible=function() return false end},Preferences={sv={crossSync=true}}}
local activeBar=HOTBAR_CATEGORY_PRIMARY
function GetActiveHotbarCategory() return activeBar end
function GetAbilityIcon(id) return id==30366 and "native/power_overload.dds" or id==30381 and "native/energy_overload.dds" or "native/other.dds" end
local buffs,toggles={},{}
local buffScans=0
function GetNumBuffs() buffScans=buffScans+1;return #buffs end
function GetUnitBuffInfo(_,index)
 local buff=buffs[index]
 return buff.name,0,0,index,1,buff.icon,0,0,0,0,buff.id,buff.canClickOff,true
end
function IsSlotToggled(_,category) return toggles[category]==true end
local cancellations={}
function CancelBuff(index) cancellations[#cancellations+1]=index end
local sounds=0
SOUNDS={GENERAL_ALERT_NOTIFICATION=1,GENERAL_ALERT_ERROR=2}
function PlaySound() sounds=sounds+1 end
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTracker.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTOverload.lua"))()
local ULT=AlphaSquadUI.Modules.ULTTracker;local O=ULT.Overload
ULT.sv={enabled=true,visible=true,locked=true,trackMode="auto",scale=100,x=400,y=100,readyFlash=true}
ULT.Refresh=function() end;ULT.RefreshSettings=function() end
ULT.bars.primary={key="primary",category=1,abilityId=101,name="Meteor",icon="native/meteor.dds",ready=false}
ULT.bars.backup={key="backup",category=2,abilityId=30366,name="Power Overload",icon="native/power_overload.dds",ready=false}
O:Migrate()
check(ULT.sv.overload.enabled and ULT.sv.overload.reserveThreshold==130,"New installs initialize the optional Overload behavior")
check(AlphaSquadUI.Modules.Overload==nil,"No second Overload module or HUD is created")
check(O:GetPriorityBar()=="backup" and ULT:ShouldTrackBar("backup") and not ULT:ShouldTrackBar("primary"),"AUTO prioritizes actually slotted Overload on the other bar")
ULT.sv.trackMode="main"
check(ULT:ShouldTrackBar("backup") and not ULT:ShouldTrackBar("primary"),"Enabled Overload priority is explicit even with Front preference")
ULT.sv.trackMode="both"
check(ULT:ShouldTrackBar("primary") and ULT:ShouldTrackBar("backup"),"Explicit Both preserves both cards in the same HUD")
O:SetOption("enabled",false);ULT.sv.trackMode="main"
check(ULT:ShouldTrackBar("primary") and not ULT:ShouldTrackBar("backup"),"Behavior OFF restores ordinary Front/Back selection")
check(events.AlphaSquadUI_ULTTracker_OverloadEffect==nil,"Behavior OFF removes its only specialized event")
O:SetOption("enabled",true);ULT.sv.trackMode="auto"
O:Update(420,"slot changed")
check(ULT.bars.backup.overload and ULT.bars.backup.overloadState=="ready" and not ULT.bars.primary.overload,"Readiness specializes only the actual Overload morph")
check(ULT.bars.backup.icon=="native/power_overload.dds","Specialization preserves the native slotted morph artwork")
check(sounds==1,"The first ready-reminder transition sounds immediately")
O:Update(425,"power")
check(sounds==1,"Repeated power events do not spam readiness sounds")
local previousScans=buffScans
O:Update(430,"power")
check(buffScans==previousScans,"Power-only updates reuse native effect evidence instead of rescanning buffs")
buffs={{name="Native Overload",icon="native/power_overload.dds",id=30366,canClickOff=true}}
toggles[2]=true
O:Update(150,"effect")
check(O.active and O.level=="warning" and #cancellations==0,"Low reserve warns before the cutoff without cancelling early")
O:Update(125,"power")
check(O.level=="critical" and #cancellations==1 and cancellations[1]==1,"Cutoff cancels only the freshly verified native click-off buff index")
O:Update(120,"power")
check(#cancellations==1,"One critical episode makes one automatic cancellation request")
buffs[1].canClickOff=false
check(not O:TryCancel("manual") and #cancellations==1,"Non-click-off effects never reach CancelBuff")
buffs={}
check(not O:TryCancel("manual") and #cancellations==1,"Previously cached effects cannot authorize cancellation after removal")
local moving=true
AlphaSquadUI.Layout={IsMoving=function(module) return moving and module==ULT end}
buffs={{name="Native Overload",icon="native/power_overload.dds",id=30366,canClickOff=true}}
O.cancelAttempted=false;local beforeSounds=sounds
O:Update(125,"layout")
check(#cancellations==1 and sounds==beforeSounds and not O:TryCancel("preview"),"Placement never cancels or plays alarms")
moving=false;ULT.loading=true;O:UpdateRuntime()
check(events.AlphaSquadUI_ULTTracker_OverloadEffect==nil and not O:TryCancel("loading"),"Loading removes effect subscriptions and blocks native actions")
ULT.loading=false;ULT.sv.enabled=false;O:UpdateRuntime()
check(events.AlphaSquadUI_ULTTracker_OverloadEffect==nil,"Parent OFF removes specialized tracking while retaining settings")
ULT.sv.enabled=true;O:UpdateRuntime()
check(events.AlphaSquadUI_ULTTracker_OverloadEffect~=nil,"Parent activation restores the filtered effect subscription")
O:SetOption("disableInPvP",true);IsInCampaign=function() return true end
check(O:Suppressed() and not O:TryCancel("PvP"),"Optional PvP suppression blocks specialized actions")
IsInCampaign=nil;O:SetOption("disableInPvP",false)
O:SetOption("reserveThreshold",175)
check(ULT.sv.overload.reserveWarningThreshold>=ULT.sv.overload.reserveThreshold,"Warning never falls below cutoff")
O:SetOption("reserveThreshold",0/0);O:SetOption("readyReminderThreshold",math.huge)
check(ULT.sv.overload.reserveThreshold==130 and ULT.sv.overload.readyReminderThreshold==400,"Malformed numeric options recover to bounded defaults")
O:RegisterCommands();SLASH_COMMANDS["/asoverload"]("off")
check(not ULT.sv.overload.enabled and ULT.sv.enabled,"Legacy OFF disables only specialized behavior")
SLASH_COMMANDS["/asoverload"]("on")
check(ULT.sv.overload.enabled,"Legacy ON restores specialized behavior")
ULT.bars.backup.abilityId=101;ULT.bars.backup.icon="native/meteor.dds";ULT.bars.backup.name="Meteor"
O:Update(200,"slot changed")
check(not O:GetPriorityBar() and events.AlphaSquadUI_ULTTracker_OverloadEffect==nil,"Removing Overload returns standard tracking and removes specialized events")
check(next(updates)==nil,"The Overload engine owns no duplicate heartbeat or animation timer")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
