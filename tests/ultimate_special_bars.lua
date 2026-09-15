-- Native active-category and timed-effect contracts, without a fixed skill list.
local count=0
local function check(value,message) count=count+1;assert(value,message) end
EVENT_ADD_ON_LOADED=1;EVENT_PLAYER_ACTIVATED=2
EVENT_ACTION_SLOT_EFFECT_UPDATE=3;EVENT_ACTION_SLOT_EFFECTS_CLEARED=4
HOTBAR_CATEGORY_PRIMARY=1;HOTBAR_CATEGORY_BACKUP=2;HOTBAR_CATEGORY_WEREWOLF=3;HOTBAR_CATEGORY_TEMPORARY=4
ACTION_TYPE_ABILITY=1;ACTION_TYPE_CRAFTED_ABILITY=2;ACTION_TYPE_ITEM=3
ACTION_BAR_ULTIMATE_SLOT_INDEX=7;COMBAT_MECHANIC_FLAGS_ULTIMATE=10
local events,queued={},{}
EVENT_MANAGER={RegisterForEvent=function(_,name,code,fn) events[name]=fn end,UnregisterForEvent=function() end,
 RegisterForUpdate=function() end,UnregisterForUpdate=function() end,AddFilterForEvent=function() end}
function zo_callLater(fn) queued[#queued+1]=fn end
function zo_strformat(_,value) return value end
SLASH_COMMANDS={}
local active=HOTBAR_CATEGORY_PRIMARY
local slots={
 [1]={id=101,name="Native vampire morph",icon="native/vampire-morph.dds",cost=200,remaining=0},
 [2]={id=102,name="Native back morph",icon="native/back-morph.dds",cost=100,remaining=0},
 [3]={id=103,name="Native transformed morph",icon="native/transformed-morph.dds",cost=0,remaining=0,toggled=true},
 [4]={id=104,name="Native temporary ultimate",icon="native/temporary.dds",cost=80,remaining=0},
}
function GetActiveHotbarCategory() return active end
function GetSlotBoundId(_,category) return slots[category].id end
function GetSlotType(_,category) return slots[category].actionType or ACTION_TYPE_ABILITY end
function GetEffectiveAbilityIdForAbilityOnHotbar(id) return id end
function GetSlotName(_,category) return slots[category].name end
function GetSlotTexture(_,category) return slots[category].icon end
function GetSlotAbilityCost(_,_,category) return slots[category].cost end
function GetActionSlotEffectTimeRemaining(_,category) return slots[category].remaining end
function IsSlotToggled(_,category) return slots[category].toggled==true end
function GetUnitPower() return 220 end
function GetGameTimeMilliseconds() return 20000 end
function GetAbilityName(id) return "Native "..id end
function GetAbilityIcon(id) return "native/"..id..".dds" end
AlphaSquadUI={Modules={},Settings={},Layout={IsMoving=function() return false end}}
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTTracker.lua'))()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTTrackerUI.lua'))()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTOverload.lua'))()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTGroup.lua'))()
local U=AlphaSquadUI.Modules.ULTTracker
U.sv={enabled=true,visible=true,trackMode="both",readySound=false,readyFlash=false,
 overload={enabled=false},group={enabled=true,visible=false,includeSelf=true,readySound=true,trackedAbilities={['101']=true}}}
U.initialized=true;U.RefreshHUD=function() end;U.RefreshSettings=function() end
U:Refresh("normal")
check(U:ShouldTrackBar("primary") and U:ShouldTrackBar("backup"),"Both reads the real weapon bars outside a transformation")
check(U.bars.primary.ready and U.bars.primary.name==slots[1].name,"Vampire morph identity and readiness come from the native slot")
slots[1].remaining=19000;U:Refresh("native duration")
check(U.bars.primary.state=="active" and not U.bars.primary.ready,"Native timed Ultimate duration prevents false READY during a transformation")
slots[1].remaining=0;U:Refresh("effect ends")
check(U.bars.primary.ready,"Readiness recovers when native duration ends")
active=HOTBAR_CATEGORY_WEREWOLF;U:Refresh("transformed")
check(U:ShouldTrackBar("primary") and not U:ShouldTrackBar("backup"),"A transformed hotbar suppresses inaccessible weapon cards")
check(U:GetHUDBar("primary").abilityId==103 and U:GetHUDBar("primary").icon==slots[3].icon,"The active transformation uses its own native morph and texture")
check(U:GetHUDBar("primary").state=="active" and not U:GetHUDBar("primary").ready,"A native toggled transformation is active rather than charging or ready")
check(U.bars.primary.abilityId==101 and U.bars.backup.abilityId==102 and U.sv.trackMode=="both","Special-bar display does not overwrite weapon data or the saved Both choice")
active=HOTBAR_CATEGORY_TEMPORARY;U:Refresh("temporary")
check(U:GetHUDBar("primary").abilityId==104 and U:GetHUDBar("primary").ready,"An unfamiliar temporary category uses the native ultimate without an ability allowlist")
U:OnUltimateUsed(U.ULTIMATE_SLOT)
check(U.specialBar.recentlyUsedUntil==21200 and not U.specialBar.ready,"Using a temporary Ultimate clears its readiness immediately")
slots[4].id=105;U:Refresh("new morph")
check(U.specialBar.recentlyUsedUntil==0 and U.specialBar.abilityId==105,"A replacement morph cannot inherit the previous ability's spent state")
slots[4].actionType=ACTION_TYPE_ITEM;U:Refresh("non ability slot")
check(U:GetHUDBar("primary").abilityId==0 and U:GetHUDBar("primary").state=="empty","An item action ID cannot be interpreted as an Ultimate ability")
active=HOTBAR_CATEGORY_BACKUP;U:Refresh("normal restored")
check(U.specialBar==nil and U:GetHUDBar("primary")==U.bars.primary and U:ShouldTrackBar("backup"),"Leaving a special bar restores the original Both layout and data")
U:RegisterEvents();local before=#queued
local effect=events.AlphaSquadUI_ULTTracker_SlotEffect
effect(nil,HOTBAR_CATEGORY_PRIMARY,3)
check(#queued==before,"Ordinary skill durations do not rescan Ultimate slots")
effect(nil,HOTBAR_CATEGORY_PRIMARY,U.ULTIMATE_SLOT);events.AlphaSquadUI_ULTTracker_EffectsCleared()
check(#queued==before+1,"Native Ultimate effect transitions coalesce into one refresh")
local G=U.Group
G:EnsureSavedVariables()
check(G.sv.enabled==false and G.sv.visible==nil and G.sv.includeSelf==nil and G.sv.readySound==nil,"Single-switch migration preserves hidden OFF while retiring self and sound settings")
G.sv.enabled=true;G:EnsureSavedVariables()
check(G.sv.enabled and G.sv.trackedAbilities['101'],"Later activation and saved filters survive repeated migration")
local _,percent=G:GetBestMatchingUltimate({matchingUltimates={{id=101,cost=250,value=249,ready=false}}})
check(percent==99,"A charging Ultimate cannot round up to 100 percent before it is ready")
_,percent=G:GetBestMatchingUltimate({matchingUltimates={{id=101,cost=250,value=250,ready=true}}})
check(percent==100,"A ready Ultimate is exactly 100 percent")
G.sv.trackedAbilities={['101']=true}
local matches=G:GetMatchingUltimates({shared=true,ultValue=225,ult1ID=101,ult2ID=101,ult1Cost=250,ult2Cost=225})
check(#matches==1 and matches[1].slot=="back" and matches[1].ready,"Identical morphs on different bars retain the lower native shared cost without duplicate rows")
G.byUnitTag={group2={ult1ID=101,ult2ID=0,ult1Cost=100,ult2Cost=0,ultValue=200}}
check(G:UpdateEntryFromUltData("group2",{ultValue=200,ult1ID=102}),"Partial native library updates can change a slot")
check(G.byUnitTag.group2.ult1Cost==0,"A replacement shared Ultimate cannot borrow the previous morph's cheap cost")
check(not G:UpdateEntryFromUltData({}, {ultValue=200}),"Malformed callback unit tags cannot reach native unit getters")
print('Ultimate special bars: '..count..' assertions passed')
