-- Enhance only this suite's entry in ESO's native Add-Ons menu.
-- Dependencies remain optional at load time so missing libraries can be diagnosed.
local ASUI = AlphaSquadUI
local function L(text, ...)
    if ASUI.L then return ASUI.L(text, ...) end
    return select("#", ...)>0 and string.format(text, ...) or text
end
local Menu = {}
ASUI.AddOnMenu = Menu

local libraries = {
    {name = "LibGroupBroadcast"},
    {name = "LibGroupCombatStats"},
    {name = "LibSetDetection", minimum = 5},
    {name = "LibFoodDrinkBuff"},
    {name = "LibCombat"},
    {name = "LibAddonMenu-2.0", minimum = 38},
    {name = "LibDebugLogger"},
}
local GREEN, RED = "|c66DD88", "|cFF6666"
local DESCRIPTION = "Modular Alpha Squad UI with pre-combat group readiness and voluntary build inspection.\n\nLibraries below are required for the complete group feature set. Local trackers remain available without them."

local function LibraryStatus(api, entry, library, enabled)
    if not entry then return L("Missing library") end
    if not enabled or not entry.addOnEnabled then return L("Disabled") end
    if library.minimum and type(api.GetAddOnVersion) == "function" then
        local version = tonumber(api:GetAddOnVersion(entry.index)) or 0
        if version < library.minimum then return L("Update required (%d+)",library.minimum) end
    end
    -- Read the selected character's native dependency state, not loaded globals.
    if type(api.GetAddOnNumDependencies) == "function" and type(api.GetAddOnDependencyInfo) == "function" then
        for index = 1, api:GetAddOnNumDependencies(entry.index) do
            local _, exists, active, minimum, version = api:GetAddOnDependencyInfo(entry.index, index)
            if not exists then return L("Missing dependency") end
            if not active then return L("Dependency disabled") end
            if (tonumber(version) or 0) < (tonumber(minimum) or 0) then return L("Dependency update required") end
        end
    end
    if entry.addOnState == ADDON_STATE_DEPENDENCIES_DISABLED then return L("Dependency unavailable") end
    if entry.addOnState == ADDON_STATE_VERSION_MISMATCH then return L("Incompatible version") end
    if entry.addOnState == ADDON_STATE_ERROR_STATE_UNABLE_TO_LOAD then return L("Unable to load") end
    return nil
end

function Menu.Refresh(manager)
    local api = type(GetAddOnManager) == "function" and GetAddOnManager() or nil
    if not api or type(api.AreAddOnsEnabled) ~= "function" or type(manager.addonTypes) ~= "table" then return end
    local installed, target = {}, nil
    -- Reuse the native snapshot: one pass only when the menu refreshes.
    for _, entries in pairs(manager.addonTypes) do
        if type(entries) == "table" then
            for _, entry in ipairs(entries) do
                if type(entry) == "table" and entry.addOnFileName then
                    installed[entry.addOnFileName] = entry
                    if entry.addOnFileName == ASUI.name then target = entry end
                end
            end
        end
    end
    if not target then return end
    local lines, enabled = {}, api:AreAddOnsEnabled()
    for _, library in ipairs(libraries) do
        local issue = LibraryStatus(api, installed[library.name], library, enabled)
        local text = library.name .. " - " .. (issue or L("Installed"))
        lines[#lines + 1] = "\n    •  " .. (issue and RED or GREEN) .. text .. "|r"
    end
    target.addOnDescription = L(DESCRIPTION)
    target.addOnDependencyText = table.concat(lines)
    target.expandable = true
    -- Do not alter native enablement, error flags, sorting or other addons.
end

function Menu.Initialize()
    if Menu.hooked or type(ZO_PostHook) ~= "function" then return end
    local manager = ADD_ON_MANAGER or ZO_AddOnManager
    if not manager or type(manager.BuildMasterList) ~= "function" then return end
    ZO_PostHook(manager, "BuildMasterList", Menu.Refresh)
    Menu.hooked = true
end

Menu.Initialize()

if ASUI.Localization then ASUI.Localization.RegisterCallback("AddOnMenu",function()
    local manager=ADD_ON_MANAGER or ZO_AddOnManager
    if manager then Menu.Refresh(manager) end
end) end
