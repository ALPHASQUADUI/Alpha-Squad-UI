-- Native Add-Ons metadata, selected-character state and layout boundary regressions.
local count = 0
local function check(value, message) count = count + 1; assert(value, message) end
local unpackValues = unpack or table.unpack
local function copy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return result
end

ADDON_STATE_ENABLED = 1
ADDON_STATE_DISABLED = 2
ADDON_STATE_DEPENDENCIES_DISABLED = 3
ADDON_STATE_VERSION_MISMATCH = 4
ADDON_STATE_ERROR_STATE_UNABLE_TO_LOAD = 5
AlphaSquadUI = {name = "AlphaSquadUI"}
-- ESO exposes GetAddOnManager(); its own source keeps AddOnManager local.
AddOnManager = nil
local names = {
    "LibGroupBroadcast", "LibGroupCombatStats", "LibSetDetection", "LibFoodDrinkBuff",
    "LibCombat", "LibAddonMenu-2.0", "LibDebugLogger",
}
local definitions, versions, dependencies = {}, {}, {}
local allEnabled = true
local api = {
    AreAddOnsEnabled = function() return allEnabled end,
    GetAddOnVersion = function(_, index) return versions[index] end,
    GetAddOnNumDependencies = function(_, index) return #(dependencies[index] or {}) end,
    GetAddOnDependencyInfo = function(_, index, dependencyIndex)
        return unpackValues(dependencies[index][dependencyIndex])
    end,
    GetAddOnInfo = function() error("Use the native selected-character entry snapshot") end,
}
function GetAddOnManager() return api end
local targetDefinition = {
    index = 1, addOnFileName = "AlphaSquadUI", addOnName = "Alpha Squad UI",
    strippedAddOnName = "Alpha Squad UI", addOnEnabled = true, addOnState = ADDON_STATE_ENABLED,
    addOnDescription = "Manifest description", addOnDependencyText = "", expandable = true,
}
local otherDefinition = {
    index = 2, addOnFileName = "AnotherAddon", addOnName = "Another Addon",
    addOnEnabled = false, hasDependencyError = true, addOnDescription = "Keep this description",
    addOnDependencyText = "Keep this native dependency list", expandable = false,
}
for position, name in ipairs(names) do
    definitions[name] = {
        index = position + 10, addOnFileName = name, addOnName = name,
        addOnEnabled = true, addOnState = ADDON_STATE_ENABLED,
    }
    versions[position + 10] = 100
end
local includeTarget = true
local nativeBuilds, nativeSorts, hooks = 0, 0, 0
ZO_AddOnManager = {}
function ZO_AddOnManager:BuildMasterList()
    nativeBuilds = nativeBuilds + 1
    self.addonTypes = {[false] = {copy(otherDefinition)}, [true] = {}}
    if includeTarget then self.addonTypes[false][2] = copy(targetDefinition) end
    for _, name in ipairs(names) do
        if definitions[name] then self.addonTypes[true][#self.addonTypes[true] + 1] = copy(definitions[name]) end
    end
    return "native-build-result"
end
function ZO_AddOnManager:SortScrollList()
    nativeSorts = nativeSorts + 1
    local target = self.addonTypes[false][2]
    if target then
        check(target.addOnDependencyText:find("LibGroupBroadcast", 1, true),
            "Library text is ready before native sorting and row-height measurement")
        self.measuredDependencyText = target.addOnDependencyText
    end
end
function ZO_AddOnManager:RefreshData()
    self:BuildMasterList()
    self:SortScrollList()
end
ADD_ON_MANAGER = setmetatable({}, {__index = ZO_AddOnManager})
local hookedObject
function ZO_PostHook(object, name, callback)
    hooks = hooks + 1
    hookedObject = object
    local original = object[name]
    object[name] = function(self, ...)
        local result = original(self, ...)
        callback(self, ...)
        return result
    end
end
assert(loadfile("AlphaSquadUI/Core/AddOnMenu.lua"))()
local menu = AlphaSquadUI.AddOnMenu
menu.Initialize(); menu.Initialize()
check(hooks == 1, "Repeated initialization installs one native menu hook")
check(hookedObject == ADD_ON_MANAGER or hookedObject == ZO_AddOnManager,
    "The hook targets the native Add-Ons manager")
check(ADD_ON_MANAGER:BuildMasterList() == "native-build-result", "Native BuildMasterList return value is preserved")
ADD_ON_MANAGER:RefreshData()
local function target() return ADD_ON_MANAGER.addonTypes[false][2] end
local function status(name, suffix, color)
    return target().addOnDependencyText:find(color .. name .. " - " .. suffix .. "|r", 1, true)
end
local GREEN, RED = "|c66DD88", "|cFF6666"
for _, name in ipairs(names) do
    check(status(name, "Installed", GREEN), "An available library is green: " .. name)
end
local _, initialLines = target().addOnDependencyText:gsub("\n", "")
check(initialLines == 7, "The complete library checklist contains exactly seven rows")
check(target().hasDependencyError == nil and target().addOnEnabled == true,
    "Feature dependencies do not set native disable flags")
check(target().addOnName == targetDefinition.addOnName and target().strippedAddOnName == targetDefinition.strippedAddOnName,
    "Native title and sorting metadata remain intact")
local other = ADD_ON_MANAGER.addonTypes[false][1]
for key, value in pairs(otherDefinition) do
    check(other[key] == value, "Other addons preserve native field " .. key)
end
local originalText = target().addOnDependencyText
menu.Refresh(ADD_ON_MANAGER)
menu.Refresh(ADD_ON_MANAGER)
check(target().addOnDependencyText == originalText, "Repeated enhancement replaces the checklist without duplicated rows")
ADD_ON_MANAGER:RefreshData()
check(target().addOnDependencyText == originalText and nativeSorts == 2 and nativeBuilds == 3,
    "Native refresh builds and sorts once while preserving the same checklist")

local removed = definitions.LibFoodDrinkBuff
definitions.LibFoodDrinkBuff = nil
ADD_ON_MANAGER:RefreshData()
check(status("LibFoodDrinkBuff", "Missing library", RED), "A missing library has an explicit red explanation")
check(target().hasDependencyError == nil and target().addOnEnabled,
    "Missing group libraries do not disable the parent addon")
definitions.LibFoodDrinkBuff = removed

-- A loaded global can remain present after another character's checkbox is OFF.
LibGroupCombatStats = {}
definitions.LibGroupCombatStats.addOnEnabled = false
ADD_ON_MANAGER:RefreshData()
check(status("LibGroupCombatStats", "Disabled", RED), "Selected-character OFF wins over a stale loaded library global")
LibGroupCombatStats = nil
definitions.LibGroupCombatStats.addOnEnabled = true
ADD_ON_MANAGER:RefreshData()
check(status("LibGroupCombatStats", "Installed", GREEN), "Selected-character ON is read from native metadata without a loaded global")
allEnabled = false
ADD_ON_MANAGER:RefreshData()
for _, name in ipairs(names) do check(status(name, "Disabled", RED), "Global Add-Ons OFF disables displayed availability: " .. name) end
allEnabled = true

local groupIndex = definitions.LibGroupBroadcast.index
dependencies[groupIndex] = {{"LibDebugLogger", false, false, 0, 0}}
ADD_ON_MANAGER:RefreshData()
check(status("LibGroupBroadcast", "Missing dependency", RED), "Installed libraries with missing transitive dependencies are red")
dependencies[groupIndex] = {{"LibDebugLogger", true, false, 0, 100}}
ADD_ON_MANAGER:RefreshData()
check(status("LibGroupBroadcast", "Dependency disabled", RED), "Disabled transitive dependencies cannot appear available")
dependencies[groupIndex] = {{"LibAddonMenu-2.0", true, true, 38, 37}}
ADD_ON_MANAGER:RefreshData()
check(status("LibGroupBroadcast", "Dependency update required", RED), "Old transitive dependencies cannot appear available")
dependencies[groupIndex] = nil
local setIndex = definitions.LibSetDetection.index
versions[setIndex] = 4
ADD_ON_MANAGER:RefreshData()
check(status("LibSetDetection", "Update required (5+)", RED), "LibSetDetection checks the required sharing version")
versions[setIndex] = 5
local menuIndex = definitions["LibAddonMenu-2.0"].index
versions[menuIndex] = 37
ADD_ON_MANAGER:RefreshData()
check(status("LibSetDetection", "Installed", GREEN), "The exact minimum library version is accepted")
check(status("LibAddonMenu-2.0", "Update required (38+)", RED), "Library menu compatibility checks its own minimum version")
local getVersion = api.GetAddOnVersion
api.GetAddOnVersion = nil
ADD_ON_MANAGER:RefreshData()
check(status("LibAddonMenu-2.0", "Installed", GREEN), "Missing version-query API degrades safely to known installed state")
api.GetAddOnVersion = getVersion
versions[menuIndex] = 38
for _, state in ipairs({
    {ADDON_STATE_DEPENDENCIES_DISABLED, "Dependency unavailable"},
    {ADDON_STATE_VERSION_MISMATCH, "Incompatible version"},
    {ADDON_STATE_ERROR_STATE_UNABLE_TO_LOAD, "Unable to load"},
}) do
    definitions.LibCombat.addOnState = state[1]
    ADD_ON_MANAGER:RefreshData()
    check(status("LibCombat", state[2], RED), "Native library load failure is visible: " .. state[2])
end
definitions.LibCombat.addOnState = ADDON_STATE_ENABLED

targetDefinition.hasDependencyError = true
targetDefinition.addOnEnabled = false
ADD_ON_MANAGER:RefreshData()
check(target().hasDependencyError == true and target().addOnEnabled == false,
    "Existing native parent disable flags are preserved rather than cleared")
includeTarget = false
ADD_ON_MANAGER:RefreshData()
check(#ADD_ON_MANAGER.addonTypes[false] == 1, "A missing parent entry does not create a phantom addon")
menu.Refresh({})
check(hooks == 1, "All menu refreshes reuse one hook")
print("Native Add-Ons menu: " .. count .. " assertions passed")
