-- Scoped navigation, native-dialog handoff and controller lifecycle regressions.
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function Control(parent, x, y, width, height)
    local control = { parent = parent, x = x or 0, y = y or 0, width = width or 100, height = height or 30, handlers = {}, hidden = false }
    function control:GetParent() return self.parent end
    function control:SetParent(value) self.parent = value end
    function control:GetLeft() return self.x end
    function control:GetTop() return self.y end
    function control:GetWidth() return self.width end
    function control:GetHeight() return self.height end
    function control:GetHandler(name) return self.handlers[name] end
    function control:SetHandler(name, callback) self.handlers[name] = callback end
    function control:IsHidden() return self.hidden end
    function control:IsControlHidden() return self.hidden or self.parent and self.parent:IsControlHidden() or false end
    function control:SetHidden(hidden)
        if self.hidden == hidden then return end
        self.hidden = hidden
        local handler = self.handlers[hidden and "OnEffectivelyHidden" or "OnEffectivelyShown"]
        if handler then handler(self) end
    end
    function control:SetWidth(value) self.width = value end
    function control:SetHeight(value) self.height = value end
    function control:SetText(value) self.text = value end
    for _, name in ipairs({"SetColor", "SetDrawLayer", "SetDrawLevel", "ClearAnchors", "SetAnchor"}) do control[name] = function() end end
    return control
end
for index, name in ipairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CT_TEXTURE", "DL_OVERLAY", "MOUSE_BUTTON_INDEX_LEFT",
    "KEY_UPARROW", "KEY_DOWNARROW", "KEY_LEFTARROW", "KEY_RIGHTARROW", "KEY_ENTER", "KEY_ESCAPE", "KEY_TAB", "KEY_SHIFT", "KEY_SPACEBAR", "KEY_PAGEUP", "KEY_PAGEDOWN",
    "EVENT_PLAYER_COMBAT_STATE", "EVENT_PLAYER_ACTIVATED", "EVENT_PLAYER_DEACTIVATED", "EVENT_GAMEPAD_PREFERRED_MODE_CHANGED",
    "MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL", "MOVEMENT_CONTROLLER_DIRECTION_VERTICAL", "MOVEMENT_CONTROLLER_MOVE_NEXT", "MOVEMENT_CONTROLLER_MOVE_PREVIOUS",
    "SCENE_SHOWING", "SCENE_SHOWN", "ZO_DI_LEFT_STICK", "ZO_DI_LEFT_STICK_NO_KEYBOARD", "ZO_DI_DPAD"}) do _G[name] = index end
GuiRoot = Control()
WINDOW_MANAGER = {CreateControl = function(_, _, parent) return Control(parent) end}
local callbacks, events, queue, prehooks, defaults = {}, {}, {}, {}, {}
EVENT_MANAGER = {RegisterForEvent = function(_, _, event, callback) events[event] = callback end}
CALLBACK_MANAGER = {RegisterCallback = function(_, name, callback) callbacks[name] = callback end}
function zo_callLater(callback) queue[#queue + 1] = callback end
function ZO_PreHook(name, hook)
    prehooks[name] = hook
    local original = _G[name]
    _G[name] = function(...) hook(...); return original(...) end
end
function ZO_CreateStringId(name, value) _G[name] = value end
function CreateDefaultActionBind(name, ...) defaults[name] = {...} end
local layers, pushes, removals = {}, 0, 0
function PushActionLayerByName(name) layers[name] = true; pushes = pushes + 1 end
function RemoveActionLayerByName(name) layers[name] = nil; removals = removals + 1 end
local listener, activations, deactivations, stickX, stickY = nil, 0, 0, 0, 0
DIRECTIONAL_INPUT = {
    Activate = function(_, object) listener = object; activations = activations + 1 end,
    Deactivate = function(_, object) if listener == object then listener = nil end; deactivations = deactivations + 1 end,
    GetXY = function() return stickX, stickY end,
    Consume = function() end,
}
ZO_MovementController = {New = function(_, _, _, query)
    return { SetAllowAcceleration = function() end, CheckMovement = function()
        local value = query()
        return value > 0 and MOVEMENT_CONTROLLER_MOVE_PREVIOUS or value < 0 and MOVEMENT_CONTROLLER_MOVE_NEXT or 0
    end }
end}
local combat, dialog, gamepad = false, false, false
function IsUnitInCombat() return combat end
function ZO_Dialogs_IsShowingDialog() return dialog end
function ZO_Dialogs_ShowDialog() dialog = true end
function ZO_Dialogs_ShowGamepadDialog() dialog = true end
function ZO_Dialogs_ShowPlatformDialog() return ZO_Dialogs_ShowDialog() end
function IsInGamepadPreferredMode() return gamepad end
function GetFrameDeltaTimeSeconds() return 1 / 60 end
local base = {GetName = function() return "hud" end}
local scene = base
SCENE_MANAGER = {
    GetCurrentScene = function() return scene end, GetBaseScene = function() return base end,
    RegisterCallback = function(_, name, callback) callbacks[name] = callback end,
    CallWhen = function(_, name, state, callback) callbacks[name .. state] = callback end,
    ShowBaseScene = function() scene = base; local callback = callbacks["hud" .. SCENE_SHOWN]; if callback then callbacks["hud" .. SCENE_SHOWN] = nil; callback() end end,
}
local customCategories = {}
GAMEPAD_OPTIONS = {RegisterCustomCategory = function(_, entry) customCategories[#customCategories + 1] = entry end}
ZO_GamepadEntryData = {New = function(_, label, icon) return {label = label, icon = icon, SetIconTintOnSelection = function() end} end}
local moved, resized, scaled, cycled, finished, opened = nil, nil, nil, nil, 0, 0
AlphaSquadUI = {
    Layout = {active = false, MoveSelected = function(x, y) moved = {x, y}; return true end,
        ResizeSelected = function(x, y) resized = {x, y}; return true end,
        AdjustSelected = function(key, value) scaled = {key, value} end,
        CycleSelected = function(delta) cycled = delta; return true end,
        Finish = function() AlphaSquadUI.Layout.active = false; finished = finished + 1 end,
        Start = function() AlphaSquadUI.Layout.active = true; return true end},
    Shell = {ToggleSettingsWindow = function() opened = opened + 1 end},
    Settings = {OpenPage = function(page) opened = opened + 1; check(page == "dashboard", "Controller entry opens dashboard") end},
}
assert(loadfile("AlphaSquadUI/Core/Input.lua"))()
local Input = AlphaSquadUI.Input
local window = Control(GuiRoot); window.hidden = true
Input.RegisterWindow(window, {close = function() window:SetHidden(true) end})
local hovered, exited, clicked = 0, 0, 0
local first = Control(window, 10, 10)
first:SetHandler("OnMouseEnter", function() hovered = hovered + 1 end)
first:SetHandler("OnMouseExit", function() exited = exited + 1 end)
local firstEntry = Input.Register(first, {activate = function() clicked = clicked + 1 end, label = "First"})
check(Input.Register(first, {kind = "inspect", label = "Updated"}) == firstEntry and firstEntry.activate, "Repeated registration preserves activation without duplicate entries")
local second = Control(window, 160, 10)
local secondEntry = Input.Register(second, {activate = function() clicked = clicked + 10 end})
local disabled = Control(window, 320, 10); disabled.enabled = false
Input.Register(disabled, {activate = function() error("Disabled control activated") end})
local hidden = Control(window, 10, 100); hidden.hidden = true
Input.Register(hidden)
local scroll = Control(window, 0, 100)
scroll.EnsureControlVisible = function(_, control) scroll.ensured = control end
local below = Control(scroll, 10, 400)
local belowEntry = Input.Register(below, {kind = "inspect"})
local hud = Control(GuiRoot, 10, 10)
Input.Register(hud, {activate = function() error("Live HUD stole input") end})
Input.Initialize()
check(not listener and not next(layers), "Closed windows never register directional input or activate an action layer")
check(#customCategories == 1 and customCategories[1].label == "Ąlpha Şquad UI", "Native controller settings gets one branded additive category")
Input.Initialize(); Input.RegisterGamepadEntry()
check(#customCategories == 1, "Initialization and later player activation do not duplicate native category")
check(defaults.ASUI_KEY_ACCEPT[1] == KEY_ENTER and defaults.ASUI_KEY_BACK[1] == KEY_ESCAPE, "Scoped Enter/Escape defaults are registered")
check(defaults.ASUI_KEY_UP[1] == KEY_UPARROW and defaults.ASUI_KEY_DOWN[1] == KEY_DOWNARROW
    and defaults.ASUI_KEY_LEFT[1] == KEY_LEFTARROW and defaults.ASUI_KEY_RIGHT[1] == KEY_RIGHTARROW
    and defaults.ASUI_KEY_MODE[1] == KEY_SPACEBAR, "Every arrow and Space uses the documented native key constant")
check(not defaults.ASUI_OPEN_SETTINGS and not defaults.ASUI_MOVE_HUD, "Opening binds never claim existing gameplay keys")
check(prehooks.ZO_Dialogs_ShowDialog and prehooks.ZO_Dialogs_ShowPlatformDialog and prehooks.ZO_Dialogs_ShowGamepadDialog, "All native modal entrypoints are observed without blocking them")
window:SetHidden(false)
check(Input.activeWindow == window and listener == Input and layers.AlphaSquadUIInput, "Showing a registered window activates only the own layer and native listener")
check(Input.focus == firstEntry and hovered == 1, "Initial visible focus invokes the live native tooltip handler")
check(Input.Action("primary") and clicked == 1, "Controller/keyboard activation runs existing button callback")
Input.SetDirection("right", true); Input:UpdateDirectionalInput(); Input.SetDirection("right", false)
check(Input.focus == secondEntry and exited >= 1, "Arrow navigation follows geometry and exits previous tooltip")
Input.Navigate(1, 0)
check(Input.focus == secondEntry, "Disabled controls and unrelated always-visible HUDs cannot receive focus")
Input.Cycle(1)
check(Input.focus == belowEntry and scroll.ensured == below, "Offscreen entries scroll into view on focus")
Input.Cycle(1)
check(Input.focus == firstEntry, "Tab wraps across visible eligible controls only")
Input.Cycle(-1)
check(Input.focus == belowEntry, "Shift-Tab cycles backwards")
below:SetHidden(true)
check(Input.focus == nil, "Hidden focused content relinquishes tooltip and ring")
Input.Refresh()
check(Input.focus == firstEntry, "Page refresh recovers focus to visible content")
local adjacentRows = {}
for index = 1, 3 do
    adjacentRows[index] = Input.Register(Control(window, 500 - index * 50, 500 + index * 2), {kind = "inspect"})
end
Input.Focus(adjacentRows[1]); Input.Cycle(1)
check(Input.focus == adjacentRows[2], "Closely spaced rows sort transitively despite reversed horizontal positions")
Input.Cycle(1)
check(Input.focus == adjacentRows[3], "Focus ordering remains deterministic for the third adjacent row")
local comboControl = Control(window, 200, 100)
local one, two, unavailable = {name = "One"}, {name = "Two"}, {name = "Unavailable", enabled = false}
local combo = {items = {one, unavailable, two}, selected = one}
function combo:GetItems() return self.items end
function combo:GetSelectedItemData() return self.selected end
function combo:SelectItem(item) self.selected = item end
function combo:HideDropdown() self.closed = true end
local comboEntry = Input.Register(comboControl, {kind = "dropdown", combo = combo})
Input.Focus(comboEntry); Input.Navigate(1, 0)
check(combo.selected == two and combo.closed, "Dropdown uses the native item selection API and skips disabled options")
Input.Navigate(-1, 0)
check(combo.selected == one, "Dropdown changes work in both directions")
local slider = Control(window, 200, 200); slider.value = 95
function slider:GetValue() return self.value end
function slider:SetValue(value) self.value = value end
function slider:GetMinMax() return 0, 100 end
Input.Focus(Input.Register(slider, {kind = "slider", step = 10})); Input.Navigate(1, 0)
check(slider.value == 100, "Slider adjustment clamps to native maximum")
Input.Navigate(-1, 0)
check(slider.value == 90, "Slider uses configured step")
gamepad = true; events[EVENT_GAMEPAD_PREFERRED_MODE_CHANGED]()
check(listener == Input and next(Input.keys) == nil, "Input mode change clears held keys and renews scoped native input")
Input.Focus(firstEntry); stickX = 1; Input:UpdateDirectionalInput(); stickX = 0
check(Input.focus == secondEntry, "Native controller stick navigates the same visible controls")
Input.SetDirection("down", true)
ZO_Dialogs_ShowPlatformDialog()
check(dialog and not next(layers) and not listener and next(Input.keys) == nil, "Native URL/modal dialog receives exclusive controls before opening")
check(not Input.Action("back") and not window:IsHidden(), "Back during a native dialog cannot close the underlying addon")
for _, callback in ipairs(queue) do callback() end; queue = {}
check(not listener and not next(layers), "Deferred dialog check never steals controls back from an active native dialog")
dialog = false; callbacks.AllDialogsHidden()
check(listener == Input and Input.activeWindow == window, "Native dialog completion restores visible addon navigation")
prehooks.ZO_Dialogs_ShowDialog()
check(not listener, "Queued/failed dialog request initially releases input")
for _, callback in ipairs(queue) do callback() end; queue = {}
check(listener == Input, "A failed native dialog request recovers without leaving a stuck window")
combat = true; events[EVENT_PLAYER_COMBAT_STATE](nil, true)
check(not listener and not next(layers) and not Input.OpenSettings() and not Input.MoveHUD(), "Combat stops all input capture and refuses editor/open actions")
combat = false; events[EVENT_PLAYER_COMBAT_STATE](nil, false)
check(listener == Input, "An existing visible menu can resume after combat ends")
events[EVENT_PLAYER_DEACTIVATED]()
check(Input.loading and not listener and not Input.OpenSettings(), "Loading clears listener and blocks reopening")
events[EVENT_PLAYER_ACTIVATED]()
check(not Input.loading and listener == Input, "Player activation restores a visible menu once")
callbacks.SceneStateChanged({}, nil, SCENE_SHOWING)
check(window:IsHidden() and not listener and not next(layers), "Opening another native scene closes the addon input context")
local layoutWindow = Control(GuiRoot); layoutWindow.hidden = true; layoutWindow.inputHint = Control(layoutWindow)
local toolbarButton = Control(layoutWindow)
Input.Register(toolbarButton, {activate = function() clicked = clicked + 100 end})
Input.RegisterWindow(layoutWindow, {layout = true, close = function() AlphaSquadUI.Layout.Finish(); layoutWindow:SetHidden(true) end})
AlphaSquadUI.Layout.active = true; layoutWindow:SetHidden(false)
check(Input.layoutMode == "move" and layoutWindow.inputHint.text:find("Move", 1, true), "Move HUD starts with understandable input mode hint")
check(not Input.GetHint():find("LB/RB", 1, true) and not Input.GetHint():find(" / A", 1, true), "Fallback controller hints are platform-neutral")
ZO_Keybindings_GetHighestPriorityBindingStringFromAction = function(action) return "native:" .. action end
check(Input.GetHint():find("native:ASUI_PAD_BACK", 1, true), "Controller hint uses native current-device binding glyphs")
ZO_Keybindings_GetHighestPriorityBindingStringFromAction = nil
gamepad = false; Input.SetDirection("right", true); Input:UpdateDirectionalInput(); Input.SetDirection("right", false)
check(moved and moved[1] == 3 and moved[2] == 0, "Held keyboard movement uses frame time and exact logical screen delta")
gamepad = true; stickX = 1; Input.SetDirection("right", true); Input:UpdateDirectionalInput(); Input.SetDirection("right", false); stickX = 0
check(moved[1] == 3 and Input.axisX == 1, "Hybrid keyboard arrows already present in D-pad input cannot double movement speed")
gamepad = false
Input.Action("mode"); Input.SetDirection("up", true); Input:UpdateDirectionalInput(); Input.SetDirection("up", false)
check(scaled and scaled[1] == "scale" and scaled[2] > 0, "Scale mode resizes proportionally using Layout's single geometry authority")
Input.Action("mode"); Input.SetDirection("right", true); Input:UpdateDirectionalInput(); Input.SetDirection("right", false)
check(resized and resized[1] > 0 and resized[2] == 0, "Width mode reshapes without changing height")
Input.Action("mode"); Input.SetDirection("up", true); Input:UpdateDirectionalInput(); Input.SetDirection("up", false)
check(resized[1] == 0 and resized[2] > 0, "Height mode reshapes without changing width")
Input.Action("panelPrevious")
check(cycled == -1, "Shoulder/PageUp switches HUD participant through Layout")
Input.Action("next")
check(Input.layoutMode == "controls", "Tab reaches toolbar controls from direct manipulation")
local priorClicks = clicked; Input.Action("primary")
check(clicked == priorClicks + 100, "Controller/keyboard can activate every registered toolbar control")
check(Input.Action("back") and layoutWindow:IsHidden() and not listener and not AlphaSquadUI.Layout.active, "Escape/B saves and exits Move HUD without lingering callbacks")
check(pushes == removals and activations == deactivations, "Every opened action layer and native directional listener is released")
scene = {}; customCategories[1].callback()
check(scene == base and opened == 1, "Native gamepad options closes before addon dashboard opens")
check(Input.OpenSettings() and opened == 2 and Input.MoveHUD(), "Bindable entrypoints work without text commands")
check(Input.MoveHUD() and not AlphaSquadUI.Layout.active, "Move HUD binding toggles editor off")
print(string.format("Input: %d assertions passed", assertions))
