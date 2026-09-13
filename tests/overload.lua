-- Deterministic Overload lifecycle tests. These doubles are not ESO runtime validation.
local total=0
local function check(value,message) total=total+1;assert(value,message) end

local updates,events={},{}
EVENT_MANAGER={
    RegisterForEvent=function(_,name,event,callback) events[name]={event=event,callback=callback} end,
    UnregisterForEvent=function(_,name) events[name]=nil end,
    AddFilterForEvent=function() end,
    RegisterForUpdate=function(_,name,interval,callback) updates[name]={interval=interval,callback=callback} end,
    UnregisterForUpdate=function(_,name) updates[name]=nil end,
}
EVENT_ADD_ON_LOADED=1
ACTION_BAR_ULTIMATE_SLOT_INDEX=7
COMBAT_MECHANIC_FLAGS_ULTIMATE=10
POWERTYPE_ULTIMATE=10
SLASH_COMMANDS={}
function d() end

AlphaSquadUI={version="test",Modules={},Utils={
    Clamp=function(value,minimum,maximum)
        value=tonumber(value) or minimum
        if value~=value or value==math.huge or value==-math.huge then value=minimum end
        return math.max(minimum,math.min(maximum,value))
    end,
    Normalize=function(value) return string.lower(tostring(value or "")) end,
}}

assert(loadfile("AlphaSquadUI/Modules/Overload/Overload.lua"))()
local AOT=AlphaSquadUI.Modules.Overload
check(type(AOT)=="table" and type(AOT.SetHealthSyncActive)=="function","Overload module is exported for suite integration")
GetUnitPower=function() return 0/0,math.huge,-math.huge end
local current,maximum,effective=AOT:GetUltimatePower()
check(current==0 and maximum==0 and effective==0,"Non-finite native Ultimate values recover safely")
GetUnitPower=nil

AOT.sv={addonEnabled=false,visible=false,locked=true}
AOT:SetAddonEnabled(true)
check(updates.AlphaSquadUI_HealthSync==nil,
    "Enabling a hidden Overload HUD does not start a recovery heartbeat")
AOT:SetAddonEnabled(false)
check(updates.AlphaSquadUI_HealthSync==nil,"Disabling Overload stops its recovery heartbeat")

AOT:RegisterSlashCommands()
SLASH_COMMANDS["/asoverload"]("move")
check(AOT.sv.addonEnabled and AOT.sv.visible and not AOT.sv.locked,
    "Move command re-enables, shows and unlocks Overload through lifecycle setters")

local hidden=false
AOT.sv.scale,AOT.sv.opacity=100,95
AOT.UpdateLockState=function() end
AOT.window={
    SetScale=function() end,SetAlpha=function() end,
    SetHidden=function(_,value) hidden=value end,IsHidden=function() return hidden end,
    SetMovable=function() end,SetMouseEnabled=function() end,
}
AOT:ApplyVisualSettings()
check(updates.AlphaSquadUI_HealthSync~=nil,"A visible gameplay HUD restores the recovery heartbeat")
AlphaSquadUI.Settings={AnyExclusiveWindowVisible=function() return true end}
AOT:ApplyVisualSettings()
check(hidden and updates.AlphaSquadUI_HealthSync==nil,"Shared configuration hides Overload and stops its recovery loop")
AlphaSquadUI.Settings.AnyExclusiveWindowVisible=function() return false end
AOT:ApplyVisualSettings()
check(not hidden and updates.AlphaSquadUI_HealthSync~=nil,"Closing shared configuration wakes the enabled Overload HUD")

AOT:SetAutoDormant(true)
check(updates.AlphaSquadUI_HealthSync==nil,"Dormant Overload unregisters its recovery heartbeat")
AOT:SetAutoDormant(false)
check(updates.AlphaSquadUI_HealthSync~=nil,"Slot-event wake restores the visible recovery heartbeat")

AOT.window=nil
AOT:SetAddonEnabled(false)
check(updates.AlphaSquadUI_HealthSync==nil,"Final disable leaves no Overload update registered")

print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
