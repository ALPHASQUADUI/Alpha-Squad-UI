-- Deterministic lifecycle tests. These doubles are not ESO runtime validation.
local total = 0
local function check(value, message) total = total + 1; assert(value, message) end

local updates, events, delayed = {}, {}, {}
SLASH_COMMANDS = {}
EVENT_MANAGER = {
    RegisterForEvent = function(_, name, event, callback) events[name] = {event=event, callback=callback} end,
    UnregisterForEvent = function(_, name) events[name] = nil end,
    AddFilterForEvent = function() end,
    RegisterForUpdate = function(_, name, interval, callback) updates[name] = {interval=interval, callback=callback} end,
    UnregisterForUpdate = function(_, name) updates[name] = nil end,
}
function zo_callLater(callback, delay) delayed[#delayed + 1] = {callback=callback, delay=delay} end
function zo_strformat(_, value) return value end

local constantNames = {
    "EVENT_ADD_ON_LOADED", "EVENT_PLAYER_ACTIVATED", "EVENT_POWER_UPDATE", "EVENT_ACTION_SLOT_ABILITY_USED",
    "EVENT_HOTBAR_SLOT_UPDATED", "EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED", "EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED",
    "EVENT_ACTION_SLOT_STATE_UPDATED", "EVENT_SCREEN_RESIZED", "EVENT_GROUP_MEMBER_JOINED", "EVENT_GROUP_MEMBER_LEFT",
    "EVENT_GROUP_UPDATE", "EVENT_GROUP_MEMBER_CONNECTED_STATUS", "REGISTER_FILTER_UNIT_TAG", "REGISTER_FILTER_POWER_TYPE",
    "COMBAT_MECHANIC_FLAGS_ULTIMATE", "POWERTYPE_ULTIMATE", "ACTION_BAR_ULTIMATE_SLOT_INDEX", "HOTBAR_CATEGORY_PRIMARY",
    "HOTBAR_CATEGORY_BACKUP", "SCENE_SHOWING", "SCENE_SHOWN",
}
for index, name in ipairs(constantNames) do _G[name] = index end
ACTION_BAR_ULTIMATE_SLOT_INDEX = 7

GuiRoot = {GetWidth=function() return 1920 end, GetHeight=function() return 1080 end}
AlphaSquadUI = {
    version = "test",
    Modules = {},
    Settings = {},
    Utils = {Clamp=function(value, minimum, maximum)
        value = tonumber(value) or minimum
        if value ~= value or value == math.huge or value == -math.huge then value = minimum end
        return math.max(minimum, math.min(maximum, value))
    end},
}

local groupSize, deadTag, slotReads = 0, nil, 0
function GetGameTimeMilliseconds() return 10000 end
function GetWorldName() return "TestWorld" end
function GetGroupSize() return groupSize end
function GetGroupUnitTagByIndex(index) return "group" .. index end
function DoesUnitExist(tag) return tag and tag:match("^group%d+$") ~= nil end
function IsUnitOnline() return true end
function IsUnitDead(tag) return tag == deadTag end
function AreUnitsEqual(a, b) return (a == "group1" and b == "player") or (a == "player" and b == "group1") or a == b end
function GetUnitDisplayName(tag) return "@" .. tag end
function GetUnitName(tag) return "Character " .. tag end
function GetAbilityName(id) return "Ultimate " .. tostring(id) end
function GetAbilityIcon(id) return "icon-" .. tostring(id) end
function GetSlotBoundId() slotReads = slotReads + 1; return 0 end

local function Window()
    local window = {hidden=false, rows={}}
    function window:SetHidden(hidden) self.hidden = hidden == true end
    function window:IsHidden() return self.hidden end
    return window
end

assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTracker.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTrackerUI.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroup.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroupUI.lua"))()

local ULT = AlphaSquadUI.Modules.ULTTracker
local Group = ULT.Group
GetUnitPower=function() return 0/0 end
check(ULT:GetUltimatePower()==0,"A non-finite native Ultimate value recovers safely")
check(ULT:GetEffectiveAbilityId(0/0,HOTBAR_CATEGORY_PRIMARY)==0,"A non-finite slotted ability ID is rejected")
GetSlotAbilityCost=function() return 0/0 end
check(ULT:GetUltimateCost(HOTBAR_CATEGORY_PRIMARY,101)==0,"A non-finite native Ultimate cost recovers safely")
GetUnitPower=nil;GetSlotAbilityCost=nil
ULT.sv = {
    enabled=true, visible=true, locked=false, trackMode="both", readySound=false, readyFlash=false,
    hideInMenus=true, scale=100, opacity=92,
    group={trackedAbilities={}},
}
Group:EnsureSavedVariables()
ULT.initialized, Group.initialized = true, true

for id=1,30 do ULT.sv.group.trackedAbilities[tostring(id)] = true end
ULT.sv.group.trackedAbilities["1.5"] = true
ULT.sv.group.trackedAbilities["2147483648"] = true
Group:EnsureSavedVariables()
check(Group:GetTrackedAbilityCount() == 24, "Tracked Ultimate migration is bounded")
check(Group:SetAbilityTracked(100.5, true) == false, "Fractional ability IDs are rejected")
check(Group:SetAbilityTracked(2147483648, true) == false, "Out-of-range ability IDs are rejected")
check(Group:SetAbilityTracked(100, true) == false, "The tracked Ultimate cap is enforced")

ULT.sv.group.enabled="yes";ULT.sv.group.visible=1;ULT.sv.group.x=0/0;ULT.sv.group.y=math.huge
Group:EnsureSavedVariables()
check(type(Group.sv.enabled)=="boolean" and type(Group.sv.visible)=="boolean", "Corrupt group booleans recover to defaults")
check(Group.sv.x==Group.sv.x and Group.sv.y~=math.huge, "Corrupt group coordinates recover to finite values")
check(Group:UpdateEntryFromUltData("group1", "invalid") == false, "Malformed group Ultimate payloads are rejected")

groupSize = 0/0
Group:BuildRoster()
check(#Group.roster == 0, "Non-finite group sizes recover safely")

Group.sv.trackedAbilities = {['101']=true}
Group.roster = {}
local available = Group:GetAvailableAbilities()
check(#available == 1 and available[1].id == 101 and available[1].tracked, "Tracked Ultimates remain configurable when absent from the roster")

groupSize = 2
Group.lgcs = {GetUnitULT=function(_, tag)
    return {ultValue=100, ult1ID=101, ult2ID=0, ult1Cost=100, ult2Cost=0, _lastUpdated=10000}
end}
Group.previousUltValues.ghost = 200
Group.recentlyUsedUntil.ghost = 20000
deadTag = "group2"
Group:BuildRoster()
check(Group.previousUltValues.ghost == nil and Group.recentlyUsedUntil.ghost == nil, "Departed players cannot retain Ultimate state")
Group.previousUltValues.group1 = 100
Group.recentlyUsedUntil.group1 = 20000
Group.lgcs = {GetUnitULT=function() return nil end}
Group:BuildRoster()
check(Group.previousUltValues.group1 == nil and Group.recentlyUsedUntil.group1 == nil,
    "Players who stop sharing cannot retain stale Ultimate transition state")
Group.lgcs = {GetUnitULT=function(_, tag)
    return {ultValue=100, ult1ID=101, ult2ID=0, ult1Cost=100, ult2Cost=0, _lastUpdated=10000}
end}
Group:BuildRoster()
local originalUlt = Group.byUnitTag.group1.ultValue
check(Group:UpdateEntryFromUltData("group1", {ultValue=-1,ult1ID=101,ult1Cost=100}) == false, "Negative shared Ultimate values are rejected")
check(Group:UpdateEntryFromUltData("group1", {ultValue=0/0,ult1ID=101,ult1Cost=100}) == false, "Non-finite shared Ultimate values are rejected")
check(Group:UpdateEntryFromUltData("group1", {ultValue=50,ult1ID=1.5,ult1Cost=100}) == false, "Malformed shared Ultimate ability IDs are rejected")
check(Group.byUnitTag.group1.ultValue == originalUlt, "Rejected Ultimate payloads leave the roster unchanged")
check(Group:UpdateEntryFromUltData("group1", {ultValue=125,ult1ID=101,ult2ID=0,ult1Cost=100,ult2Cost=0}) == true, "Valid shared Ultimate payloads are accepted")
check(Group.byUnitTag.group1.ultValue == 125, "Valid shared Ultimate values update the roster")
Group.sv.includeSelf = true
local tracked = Group:GetTrackedEntries()
check(#tracked == 2, "Unavailable players remain visible for raidlead context")
check(tracked[1].anyReady == true and tracked[1].unavailable == false, "Usable READY players sort first")
check(tracked[2].anyReady == false and tracked[2].unavailable == true, "Dead players are not actionable READY entries")
groupSize=0;Group.previousUltValues.persist=100;Group.recentlyUsedUntil.persist=20000;Group.readyState.persist=true
Group:BuildRoster()
check(next(Group.previousUltValues)==nil and next(Group.recentlyUsedUntil)==nil and next(Group.readyState)==nil, "Disband clears all transient group Ultimate state")
groupSize=2;Group:BuildRoster()

ULT.window = Window()
Group.window = nil
ULT.uiObscured = false
ULT:ApplyVisibility()
check(updates.AlphaSquadUI_ULTTracker_Safety ~= nil, "Visible personal tracker enables its recovery sync")
ULT.sv.visible = false
ULT:ApplyVisibility()
check(updates.AlphaSquadUI_ULTTracker_Safety == nil, "Hidden personal tracker stops its recovery sync")

ULT.sv.readyFlash = true
ULT.bars.primary.ready = true
ULT:SetFlashUpdate(false)
local originalReadBar = ULT.ReadBar
local originalGetUltimatePower = ULT.GetUltimatePower
local originalRefreshHUD = ULT.RefreshHUD
ULT.ReadBar = function(_, bar)
    bar.abilityId, bar.cost, bar.toggled = 101, 100, false
end
ULT.GetUltimatePower = function() return 100 end
ULT.RefreshHUD = function(self) self:ApplyVisibility() end
ULT:Refresh("hidden ready")
check(updates.AlphaSquadUI_ULTTracker_Flash == nil, "Hidden personal tracker never starts its READY animation")
ULT.ReadBar = originalReadBar
ULT.GetUltimatePower = originalGetUltimatePower
ULT.RefreshHUD = originalRefreshHUD
ULT.sv.readyFlash = false

local observedReads = 0
originalReadBar, originalGetUltimatePower, originalRefreshHUD = ULT.ReadBar, ULT.GetUltimatePower, ULT.RefreshHUD
ULT.ReadBar = function(_, bar) bar.abilityId, bar.cost, bar.toggled = 101, 100, false end
ULT.GetUltimatePower = function() observedReads=observedReads+1;return 5 end
ULT.RefreshHUD = function() end
ULT:Refresh("power event", 125)
check(ULT.currentUltimate==125 and observedReads==0,
    "A power event reuses its supplied Ultimate value without a redundant native read")
ULT:Refresh("fallback")
check(observedReads==1,"Non-power refreshes still recover from the native Ultimate getter")
ULT.ReadBar, ULT.GetUltimatePower, ULT.RefreshHUD = originalReadBar, originalGetUltimatePower, originalRefreshHUD

ULT.sv.visible, ULT.sv.enabled = true, true
Group.window = Window()
Group.sv.visible, Group.sv.enabled = true, true
Group:ApplyVisibility()
check(updates.AlphaSquadUI_ULTGroup_Safety ~= nil, "Visible group tracker enables its recovery sync")
AlphaSquadUI.Settings.AnyExclusiveWindowVisible=function() return true end
ULT:ApplyVisibility()
check(ULT.window:IsHidden() and Group.window:IsHidden(), "Any Alpha Squad configuration window hides both Ultimate HUDs")
check(updates.AlphaSquadUI_ULTTracker_Safety==nil and updates.AlphaSquadUI_ULTGroup_Safety==nil,
    "Opening a shared configuration window stops both Ultimate safety loops")
AlphaSquadUI.Settings.AnyExclusiveWindowVisible=function() return false end
ULT:ApplyVisibility()
check(not ULT.window:IsHidden() and not Group.window:IsHidden(), "Closing shared configuration restores enabled Ultimate HUDs")
Group.sv.visible = false
Group:ApplyVisibility()
check(updates.AlphaSquadUI_ULTGroup_Safety == nil, "Hidden group tracker stops its recovery sync")

local readyRow = Window()
readyRow.ready, readyRow.recentlyUsed = true, false
Group.window.rows = {readyRow}
Group.sv.visible = true
Group:ApplyVisibility()
check(updates.AlphaSquadUI_ULTGroup_ReadyPulse ~= nil, "Showing a READY group row restarts its pulse immediately")
readyRow.ready = false
Group.sv.visible = false
Group:ApplyVisibility()
check(updates.AlphaSquadUI_ULTGroup_ReadyPulse == nil, "Hiding the group tracker stops its READY pulse")

ULT.loading=true;ULT.sv.hideInMenus=false;Group.sv.hideInMenus=false;Group.sv.visible=true
ULT:ApplyVisibility();Group:ApplyVisibility()
check(ULT.window:IsHidden() and Group.window:IsHidden(),"Loading hides both HUDs regardless of menu visibility preferences")
check(updates.AlphaSquadUI_ULTTracker_Safety==nil and updates.AlphaSquadUI_ULTGroup_Safety==nil and updates.AlphaSquadUI_ULTGroup_ReadyPulse==nil,
    "Loading cannot restart Ultimate recovery or pulse loops")
local queuedBeforeLoading=#delayed
Group:ScheduleRefresh(true)
check(#delayed==queuedBeforeLoading,"Group loading cannot queue new roster work")
ULT.loading=false

local before = #delayed
ULT.sv.enabled, Group.sv.enabled = false, true
Group:ScheduleRefresh(true)
check(#delayed == before, "Parent-disabled group tracking stays dormant")

ULT.sv.enabled = false
slotReads = 0
ULT:Refresh("disabled")
check(slotReads == 0, "Disabled personal tracking performs no slot scan")
before = #delayed
ULT:OnUltimateUsed(ULT.ULTIMATE_SLOT)
check(#delayed == before, "Disabled personal tracking queues no settle callbacks")

-- Ownership and preview use the actual UI paths, without a duplicate Ultimate scan.
local moving, suppressed = false, true
AlphaSquadUI.Layout = {
    ShouldHidePersonalULT=function() return suppressed end,
    IsMoving=function(module) return moving and (module==ULT or module==Group) end,
}
ULT.sv.enabled, ULT.sv.visible, ULT.uiObscured = true, true, false
ULT.sv.hideInMenus, Group.sv.hideInMenus = true, true
Group.sv.enabled, Group.sv.visible = true, true
ULT:ApplyVisibility()
check(ULT.window:IsHidden() and not Group.window:IsHidden(), "Overload ownership suppresses only the personal Ultimate HUD")
check(updates.AlphaSquadUI_ULTTracker_Safety==nil, "A duplicate personal Ultimate HUD has no recovery timer")
slotReads=0
ULT:Refresh("overload owns personal HUD")
check(slotReads==0, "Suppressed personal tracking skips both hotbar scans")
suppressed=false
ULT:ApplyVisibility()
check(not ULT.window:IsHidden() and updates.AlphaSquadUI_ULTTracker_Safety~=nil, "Releasing Overload ownership restores personal ULT presentation")
moving=true
ULT.sv.visible, Group.sv.visible, ULT.uiObscured = false, false, true
ULT:ApplyVisibility()
check(not ULT.window:IsHidden() and not Group.window:IsHidden(), "Global move mode exposes both enabled HUDs without editing hidden preferences")
check(not ULT.sv.visible and not Group.sv.visible, "Preview never permanently changes HUD visibility")
check(updates.AlphaSquadUI_ULTTracker_Safety==nil and updates.AlphaSquadUI_ULTGroup_Safety==nil,
    "Placement does not run personal or group recovery timers")
local sounds=0
PlaySound=function() sounds=sounds+1 end; SOUNDS={ABILITY_ULTIMATE_READY=1}
ULT.sv.readySound, Group.sv.readySound = true, true
ULT:PlayReadySound();Group:PlayReadySound()
check(sounds==0, "Dragging previews never produces Ultimate-ready sounds")
moving=false
ULT:ApplyVisibility()
check(ULT.window:IsHidden() and Group.window:IsHidden(), "Finishing placement restores the hidden HUD preferences")
AlphaSquadUI.Layout=nil
PlaySound=nil;SOUNDS=nil

ULT.window, Group.window = nil, nil
Group.RefreshConfig = Group.RefreshConfig or function() end
ULT:RegisterSlashCommands()
ULT.sv.enabled, ULT.sv.visible, ULT.sv.locked = false, false, true
SLASH_COMMANDS["/asult"]("move")
check(ULT.sv.enabled and ULT.sv.visible and not ULT.sv.locked, "Personal move command activates and exposes the HUD")
ULT.sv.enabled, Group.sv.enabled, Group.sv.visible, Group.sv.locked = false, false, false, true
SLASH_COMMANDS["/asult"]("group move")
check(ULT.sv.enabled and Group.sv.enabled and Group.sv.visible and not Group.sv.locked, "Group move command activates and exposes the HUD")

print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.", total, _VERSION))
