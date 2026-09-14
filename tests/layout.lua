-- Native-scene and lifecycle boundaries for the shared HUD placement mode.
local total = 0
local function check(value, message) total = total + 1; assert(value, message) end
local events, sceneCallbacks = {}, {}
local function Control()
    local control = { hidden = true, handlers = {} }
    function control:SetHidden(hidden)
        local changed = self.hidden ~= hidden
        self.hidden = hidden
        if changed and hidden and self.handlers.OnHide then self.handlers.OnHide(self) end
    end
    function control:IsHidden() return self.hidden end
    function control:SetHandler(name, callback) self.handlers[name] = callback end
    for _, method in ipairs({ "SetDimensions", "SetAnchor", "SetClampedToScreen", "SetMouseEnabled", "SetDrawTier",
        "SetAnchorFill", "SetColor", "SetFont", "SetText", "StopMovingOrResizing" }) do control[method] = function() end end
    return control
end
GuiRoot = Control()
WINDOW_MANAGER = { CreateControl = function() return Control() end, CreateTopLevelWindow = function() return Control() end }
EVENT_PLAYER_DEACTIVATED, EVENT_PLAYER_COMBAT_STATE = 1, 2
SCENE_SHOWING = 3
EVENT_MANAGER = { RegisterForEvent = function(_, name, event, callback) events[event] = callback end,
    RegisterForUpdate = function() error("HUD placement must not create a polling loop") end }
SLASH_COMMANDS = {}
local baseScenes, shown, hidden = 0, 0, 0
SCENE_MANAGER = {
    RegisterCallback = function(_, name, callback) sceneCallbacks[name] = callback end,
    RegisterTopLevel = function(_, control, locks) control.registered = true; control.locks = locks end,
    ShowTopLevel = function(_, control) shown = shown + 1; control:SetHidden(false) end,
    HideTopLevel = function(_, control) hidden = hidden + 1; control:SetHidden(true) end,
    ShowBaseScene = function() baseScenes = baseScenes + 1 end,
}
local combat = false
function IsUnitInCombat() return combat end
local function Module(enabled)
    local module = { sv = {enabled = enabled, visible = true, locked = true}, window = Control(), saves = 0, refreshes = 0 }
    function module:SavePosition() self.saves = self.saves + 1; self.sv.x = 420 end
    function module:RefreshHUD() self.refreshes = self.refreshes + 1 end
    function module:UpdateLockState() self.movable = not self.sv.locked end
    return module
end
local overload, ult, group, support = Module(true), Module(true), Module(true), Module(false)
overload.sv.addonEnabled, overload.hasSlottedOverload = true, true
overload.IsPvPSuppressed = function() return false end
ult.Group = group
local popup = Control(); popup:SetHidden(false)
local closes = 0
AlphaSquadUI = { Modules = {Overload = overload, ULTTracker = ult, SupportCoverage = support},
    Settings = {exclusiveWindows = { builds = { control = popup, close = function() closes = closes + 1; popup:SetHidden(true) end } }} }
assert(loadfile("AlphaSquadUI/Core/Layout.lua"))()
local Layout = AlphaSquadUI.Layout
check(Layout.ShouldHidePersonalULT(), "An available slotted Overload HUD owns personal Ultimate presentation")
overload.sv.addonEnabled = false
check(not Layout.ShouldHidePersonalULT(), "Disabling Overload immediately restores personal ULT ownership")
overload.sv.addonEnabled, overload.hasSlottedOverload = true, false
check(not Layout.ShouldHidePersonalULT(), "A dormant Overload module cannot hide a different Ultimate")
overload.hasSlottedOverload = true
overload.sv.visible = false
check(not Layout.ShouldHidePersonalULT(), "Hiding Overload does not leave both personal trackers invisible")

combat = true
check(not Layout.Start() and shown == 0, "Placement cannot be opened during combat")
combat = false
ult.loading = true
check(not Layout.Start() and shown == 0, "Placement cannot be opened during a loading transition")
ult.loading = false
check(Layout.Start() and Layout.active and baseScenes == 1 and shown == 1, "Placement opens a registered overlay over native gameplay")
check(Layout.toolbar.registered and Layout.toolbar.locks, "Native top-level ownership enables mouse mode and Escape dismissal")
check(closes == 1 and popup:IsHidden(), "Opening placement closes build/settings popups")
check(Layout.IsMoving(overload) and not overload.sv.visible, "Preview exposes an enabled hidden HUD without changing its visibility preference")
check(not Layout.IsMoving(ult) and Layout.IsMoving(group), "Overload suppresses the duplicate personal preview but preserves Group ULT")
check(not Layout.IsMoving(support) and support.sv.locked and not support.sv.enabled, "Dashboard-disabled modules remain disabled and locked")
check(Layout.Start() and shown == 1, "Repeated move commands do not duplicate the overlay")

Layout.toolbar:SetHidden(true) -- Native Escape closes registered top levels.
check(not Layout.active and overload.saves == 1 and group.saves == 1, "Escape saves positions and ends placement exactly once")
check(overload.sv.locked and ult.sv.locked and group.sv.locked, "Completing placement locks every participating HUD")
check(not overload.sv.visible and not support.sv.enabled and support.saves == 0, "Ending placement preserves unrelated module and visibility choices")
Layout.Finish()
check(overload.saves == 1, "Repeated dismissal does not rewrite saved positions")

overload.hasSlottedOverload = false
group.sv.enabled = false
Layout.Start()
check(Layout.IsMoving(ult) and not Layout.IsMoving(group), "Normal Ultimate previews respect the separate Group ULT switch")
sceneCallbacks.SceneStateChanged({GetName=function() return "inventory" end}, 0, SCENE_SHOWING)
check(not Layout.active, "Opening another native game scene ends placement")
Layout.Start()
events[EVENT_PLAYER_COMBAT_STATE](EVENT_PLAYER_COMBAT_STATE, true)
check(not Layout.active, "Entering combat closes placement immediately")
Layout.Start()
local refreshes = overload.refreshes
events[EVENT_PLAYER_DEACTIVATED]()
check(not Layout.active and overload.refreshes == refreshes, "Loading saves layout without refreshing gameplay work")
check(type(SLASH_COMMANDS["/asmove"]) == "function", "One slash command opens the common placement mode")
overload.sv.addonEnabled=false;ult.sv.enabled=false;support.sv.enabled=false
local priorShown,priorScenes=shown,baseScenes
check(not Layout.Start() and not Layout.active and shown==priorShown and baseScenes==priorScenes,
    "With every module OFF, placement keeps the current scene and opens no empty overlay")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.", total, _VERSION))
