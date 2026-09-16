-- Scoped keyboard/gamepad navigation. Gameplay bindings are never reassigned.
-- Uses ESO's action layers, directional input, movement controller and dialogs.
local ASUI = AlphaSquadUI
local Input = { entries = {}, windows = {}, keys = {}, layoutMode = "move" }
ASUI.Input = Input
local LAYER = "AlphaSquadUIInput"
local windowOrder, serial = {}, 0
local function Hidden(control)
    if not control then return true end
    if control.IsControlHidden then return control:IsControlHidden() end
    local current = control
    while current do
        if current.IsHidden and current:IsHidden() then return true end
        current = current.GetParent and current:GetParent()
    end
    return false
end
local function DialogVisible()
    return (ZO_Dialogs_IsShowingDialog and ZO_Dialogs_IsShowingDialog())
        or (ZO_GenericGamepadDialog_IsShowing and ZO_GenericGamepadDialog_IsShowing())
end
local function InCombat()
    return IsUnitInCombat and IsUnitInCombat("player")
end
local function Parent(control) return control and control.GetParent and control:GetParent() end
local function Root(control)
    while control do
        if Input.windows[control] then return control end
        control = Parent(control)
    end
end
local function Hook(control, event, callback)
    if not control.SetHandler then return end
    if ZO_PostHookHandler then ZO_PostHookHandler(control, event, callback)
    else
        local previous = control.GetHandler and control:GetHandler(event)
        control:SetHandler(event, function(...)
            if previous then previous(...) end
            callback(...)
        end)
    end
end
local function Handler(control, name, ...)
    local callback = control and control.GetHandler and control:GetHandler(name)
    if callback then return callback(control, ...) end
end
local function Eligible(entry)
    local control = entry and entry.control
    if not control or Hidden(control) or Root(control) ~= Input.activeWindow then return false end
    if entry.enabled and not entry.enabled(control) then return false end
    if control.enabled == false then return false end
    if control.IsEnabled and not control:IsEnabled() then return false end
    if entry.combo and entry.combo.IsEnabled and not entry.combo:IsEnabled() then return false end
    return true
end
local function Coordinates(control)
    local x = control.GetLeft and control:GetLeft() or 0
    local y = control.GetTop and control:GetTop() or 0
    local width = control.GetWidth and control:GetWidth() or 0
    local height = control.GetHeight and control:GetHeight() or 0
    return x + width / 2, y + height / 2, y, x
end
local function Candidates()
    local entries = {}
    for _, entry in pairs(Input.entries) do
        if Eligible(entry) then entries[#entries + 1] = entry end
    end
    table.sort(entries, function(a, b)
        local _, _, ay, ax = Coordinates(a.control)
        local _, _, by, bx = Coordinates(b.control)
        if ay ~= by then return ay < by end
        if ax ~= bx then return ax < bx end
        return a.serial < b.serial
    end)
    return entries
end
local function PaintFocus(control)
    if Input.focusBorders then
        for _, border in ipairs(Input.focusBorders) do border:SetHidden(true) end
    end
    if not control or not WINDOW_MANAGER or not CT_TEXTURE then return end
    if not Input.focusBorders then
        Input.focusBorders = {}
        for i = 1, 4 do
            local border = WINDOW_MANAGER:CreateControl(nil, GuiRoot, CT_TEXTURE)
            border:SetColor(1, 0.65, 0.25, 1)
            if border.SetDrawLayer and DL_OVERLAY then border:SetDrawLayer(DL_OVERLAY) end
            if border.SetDrawLevel then border:SetDrawLevel(250) end
            Input.focusBorders[i] = border
        end
    end
    local specs = {
        {TOPLEFT, TOPRIGHT, "SetHeight"}, {BOTTOMLEFT, BOTTOMRIGHT, "SetHeight"},
        {TOPLEFT, BOTTOMLEFT, "SetWidth"}, {TOPRIGHT, BOTTOMRIGHT, "SetWidth"},
    }
    for i, spec in ipairs(specs) do
        local border = Input.focusBorders[i]
        if border.SetParent then border:SetParent(control) end
        border:ClearAnchors()
        border:SetAnchor(spec[1], control, spec[1], 0, 0)
        border:SetAnchor(spec[2], control, spec[2], 0, 0)
        border[spec[3]](border, 2)
        border:SetHidden(false)
    end
end
function Input.ClearFocus()
    local entry = Input.focus
    Input.focus = nil
    if entry then Handler(entry.control, "OnMouseExit") end
    PaintFocus(nil)
end
function Input.Focus(entry)
    if not Eligible(entry) then return false end
    if Input.focus ~= entry then
        Input.ClearFocus()
        Input.focus = entry
        local ancestor = Parent(entry.control)
        while ancestor and ancestor ~= Input.activeWindow do
            if ancestor.EnsureControlVisible then ancestor:EnsureControlVisible(entry.control) end
            ancestor = Parent(ancestor)
        end
        Handler(entry.control, "OnMouseEnter")
        PaintFocus(entry.control)
    end
    return true
end
function Input.Register(control, options)
    if not control then return end
    local entry = Input.entries[control]
    if not entry then
        serial = serial + 1
        entry = { control = control, serial = serial }
        Input.entries[control] = entry
        -- Mouse selection and virtual focus always share the live control.
        Hook(control, "OnMouseDown", function()
            if Input.activeWindow and Eligible(entry) then Input.Focus(entry) end
        end)
        Hook(control, "OnEffectivelyHidden", function()
            if Input.focus == entry then Input.ClearFocus() end
        end)
    end
    for key, value in pairs(options or {}) do entry[key] = value end
    return entry
end
function Input.RegisterWindow(control, options)
    if not control then return end
    local data = Input.windows[control]
    if not data then
        data = {}; Input.windows[control] = data; windowOrder[#windowOrder + 1] = control
        Hook(control, "OnEffectivelyShown", function() Input.ActivateWindow(control) end)
        Hook(control, "OnEffectivelyHidden", function()
            if Input.activeWindow == control then Input.Deactivate() end
            if Input.suspendedWindow == control then Input.suspendedWindow, Input.suspendedScene = nil, nil end
        end)
    end
    for key, value in pairs(options or {}) do data[key] = value end
    if Input.initialized and not Hidden(control) then Input.ActivateWindow(control) end
end
function Input.GetHint()
    local gamepad = IsInGamepadPreferredMode and IsInGamepadPreferredMode()
    local function Binding(action, fallback)
        if ZO_Keybindings_GetHighestPriorityBindingStringFromAction then
            local label = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(action,
                KEYBIND_TEXT_OPTIONS_ABBREVIATED_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP, gamepad)
            if type(label) == "string" and label ~= "" then return label end
        end
        return fallback
    end
    local selectKey = Binding(gamepad and "ASUI_PAD_ACCEPT" or "ASUI_KEY_ACCEPT", gamepad and "Select" or "Enter")
    local backKey = Binding(gamepad and "ASUI_PAD_BACK" or "ASUI_KEY_BACK", gamepad and "Back" or "Esc")
    local window = Input.windows[Input.activeWindow]
    if window and window.layout then
        if not gamepad then return "Drag a panel to move it. Drag a corner to resize. Esc saves." end
        local mode = Input.layoutMode
        local modeKey = Binding(gamepad and "ASUI_PAD_MODE" or "ASUI_KEY_MODE", gamepad and "Secondary" or "Space")
        local previous = Binding(gamepad and "ASUI_PAD_PANEL_PREVIOUS" or "ASUI_KEY_PANEL_PREVIOUS", gamepad and "Left shoulder" or "PgUp")
        local nextKey = Binding(gamepad and "ASUI_PAD_PANEL_NEXT" or "ASUI_KEY_PANEL_NEXT", gamepad and "Right shoulder" or "PgDn")
        return string.format("%s  |  %s: adjust  |  %s: mode  |  %s/%s: panel  |  %s: controls  |  %s: done",
            mode:sub(1, 1):upper() .. mode:sub(2), gamepad and "Stick" or "Arrows", modeKey, previous, nextKey, selectKey, backKey)
    end
    return string.format("%s: navigate  |  %s: select  |  Left/right: value  |  %s: back",
        gamepad and "Stick / D-pad" or "Arrows / Tab", selectKey, backKey)
end
local function RefreshHint()
    local window = Input.activeWindow
    if window and window.inputHint and window.inputHint.SetText then window.inputHint:SetText(Input.GetHint()) end
end
function Input.Deactivate(keepWindow)
    local window = Input.activeWindow
    local scene = Input.activeScene
    Input.ClearFocus()
    Input.keys = {}; Input.axisX, Input.axisY = 0, 0
    if Input.layerActive then
        Input.layerActive = false
        if RemoveActionLayerByName then RemoveActionLayerByName(LAYER) end
    end
    if Input.directionalActive and DIRECTIONAL_INPUT then
        Input.directionalActive = false
        DIRECTIONAL_INPUT:Deactivate(Input)
    end
    Input.activeWindow, Input.activeScene = nil, nil
    if keepWindow then
        if window then Input.suspendedWindow, Input.suspendedScene = window, scene end
    else Input.suspendedWindow, Input.suspendedScene = nil, nil end
end
function Input.ActivateWindow(window)
    if not Input.initialized or not Input.windows[window] or Hidden(window) or Input.loading
        or InCombat() or DialogVisible() or Input.nativePending then return false end
    if Input.activeWindow == window and Input.layerActive then return true end
    Input.Deactivate()
    Input.activeWindow, Input.suspendedWindow, Input.suspendedScene = window, nil, nil
    Input.activeScene = SCENE_MANAGER and SCENE_MANAGER.GetCurrentScene and SCENE_MANAGER:GetCurrentScene()
    Input.layoutMode = "move"
    if PushActionLayerByName then PushActionLayerByName(LAYER); Input.layerActive = true end
    if DIRECTIONAL_INPUT and ZO_MovementController then
        Input.horizontal = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, 8, function() return -(Input.axisX or 0) end)
        Input.vertical = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, 8, function() return Input.axisY or 0 end)
        Input.horizontal:SetAllowAcceleration(false); Input.vertical:SetAllowAcceleration(false)
        DIRECTIONAL_INPUT:Activate(Input, window); Input.directionalActive = true
    end
    local list = Candidates()
    if list[1] then Input.Focus(list[1]) end
    RefreshHint()
    return true
end
function Input.Refresh()
    if Input.loading or InCombat() or DialogVisible() or Input.nativePending then
        if Input.activeWindow then Input.Deactivate(true) end
        return false
    end
    if Input.activeWindow and not Hidden(Input.activeWindow) then
        if not Eligible(Input.focus) then
            local entries = Candidates(); if entries[1] then Input.Focus(entries[1]) else Input.ClearFocus() end
        end
        return true
    end
    for i = #windowOrder, 1, -1 do
        if not Hidden(windowOrder[i]) then return Input.ActivateWindow(windowOrder[i]) end
    end
    Input.Deactivate()
    return false
end
local function Ready()
    if not Input.activeWindow or Hidden(Input.activeWindow) or InCombat() or Input.loading or DialogVisible() then
        if Input.activeWindow then Input.Deactivate(true) end
        return false
    end
    return true
end
function Input.Cycle(delta)
    if not Ready() then return false end
    local list, current = Candidates(), 0
    for i, entry in ipairs(list) do if entry == Input.focus then current = i end end
    if #list == 0 then return false end
    if current == 0 and delta < 0 then current = 1 end
    return Input.Focus(list[(current - 1 + delta) % #list + 1])
end
function Input.Adjust(entry, delta)
    if not Eligible(entry) then return false end
    if entry.adjust then entry.adjust(delta); return true end
    local combo = entry.combo
    if combo then
        local items = combo.GetItems and combo:GetItems() or {}
        local selected = combo.GetSelectedItemData and combo:GetSelectedItemData()
        local index = 0
        for i, item in ipairs(items) do if item == selected then index = i; break end end
        for offset = 1, #items do
            local candidate = items[(index - 1 + delta * offset) % #items + 1]
            if candidate.enabled ~= false then
                if combo.HideDropdown then combo:HideDropdown() end
                if combo.SelectItem then combo:SelectItem(candidate) end
                Input.Refresh(); return true
            end
        end
        return false
    end
    local control = entry.control
    if entry.kind == "slider" and control.GetValue and control.SetValue and control.GetMinMax then
        local minimum, maximum = control:GetMinMax()
        control:SetValue(math.max(minimum, math.min(maximum, control:GetValue() + delta * (entry.step or 1))))
        return true
    end
    return false
end
function Input.Navigate(dx, dy)
    if not Ready() then return false end
    if dx ~= 0 and Input.focus and Input.Adjust(Input.focus, dx) then return true end
    local list = Candidates()
    if not Eligible(Input.focus) then return list[1] and Input.Focus(list[1]) or false end
    local x, y = Coordinates(Input.focus.control)
    local best, bestScore
    for _, entry in ipairs(list) do
        if entry ~= Input.focus then
            local tx, ty = Coordinates(entry.control)
            local primary = (tx - x) * dx + (ty - y) * dy
            if primary > 1 then
                local perpendicular = math.abs((tx - x) * dy - (ty - y) * dx)
                local score = primary + perpendicular * 3
                if not bestScore or score < bestScore then best, bestScore = entry, score end
            end
        end
    end
    return best and Input.Focus(best) or false
end
local modes = { "move", "scale", "width", "height", "controls" }
function Input.LayoutDirection(dx, dy, step)
    local layout = ASUI.Layout
    if not layout or not layout.active then return false end
    local mode = Input.layoutMode
    if mode == "move" and layout.MoveSelected then return layout.MoveSelected(dx * step, dy * step) end
    if mode == "width" and layout.ResizeSelected then return layout.ResizeSelected((dx - dy) * step, 0) end
    if mode == "height" and layout.ResizeSelected then return layout.ResizeSelected(0, (dx - dy) * step) end
    if mode == "scale" and layout.AdjustSelected then layout.AdjustSelected("scale", (dx - dy) * step / 5); return true end
    return false
end
function Input.SetDirection(direction, down)
    if not Ready() then return false end
    Input.keys[direction] = down == true
    if down and not Input.directionalActive then
        local x = direction == "right" and 1 or direction == "left" and -1 or 0
        local y = direction == "down" and 1 or direction == "up" and -1 or 0
        local window = Input.windows[Input.activeWindow]
        if window and window.layout and Input.layoutMode ~= "controls" then return Input.LayoutDirection(x, y, 4) end
        return Input.Navigate(x, y)
    end
    return true
end
function Input:UpdateDirectionalInput()
    if not Ready() then return end
    local x, y = 0, 0
    if IsInGamepadPreferredMode and IsInGamepadPreferredMode() and DIRECTIONAL_INPUT.GetXY then
        x, y = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK_NO_KEYBOARD or ZO_DI_LEFT_STICK, ZO_DI_DPAD)
        -- The no-keyboard axis aliases the same physical stick consumed by UI.
        if DIRECTIONAL_INPUT.Consume then DIRECTIONAL_INPUT:Consume(ZO_DI_LEFT_STICK) end
    end
    -- Native D-pad input may already include keyboard arrows in hybrid mode.
    x = math.max(-1, math.min(1, x + (Input.keys.right and 1 or 0) - (Input.keys.left and 1 or 0)))
    y = math.max(-1, math.min(1, y + (Input.keys.up and 1 or 0) - (Input.keys.down and 1 or 0)))
    Input.axisX, Input.axisY = x, y
    local window = Input.windows[Input.activeWindow]
    if window and window.layout and Input.layoutMode ~= "controls" then
        if math.abs(x) > 0.15 or math.abs(y) > 0.15 then
            local elapsed = GetFrameDeltaTimeSeconds and GetFrameDeltaTimeSeconds() or 1 / 60
            Input.LayoutDirection(x, -y, math.max(0, math.min(elapsed, 0.05)) * 180)
        end
        return
    end
    local horizontal = Input.horizontal:CheckMovement()
    local vertical = Input.vertical:CheckMovement()
    if horizontal == MOVEMENT_CONTROLLER_MOVE_NEXT then Input.Navigate(1, 0)
    elseif horizontal == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then Input.Navigate(-1, 0)
    elseif vertical == MOVEMENT_CONTROLLER_MOVE_NEXT then Input.Navigate(0, 1)
    elseif vertical == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then Input.Navigate(0, -1) end
end
function Input.Action(action)
    if not Ready() then return false end
    local window = Input.windows[Input.activeWindow]
    if action == "back" then
        local control = Input.activeWindow
        Input.Deactivate()
        if window.close then window.close() else control:SetHidden(true) end
        return true
    end
    if action == "next" or action == "previous" then
        if window.layout then Input.layoutMode = "controls"; RefreshHint() end
        return Input.Cycle(action == "next" and 1 or -1)
    end
    if action == "panelNext" or action == "panelPrevious" then
        if window.layout and ASUI.Layout and ASUI.Layout.CycleSelected then
            return ASUI.Layout.CycleSelected(action == "panelNext" and 1 or -1)
        end
        return Input.Cycle(action == "panelNext" and 1 or -1)
    end
    if action == "mode" and window.layout then
        for index, mode in ipairs(modes) do
            if mode == Input.layoutMode then Input.layoutMode = modes[index % #modes + 1]; break end
        end
        RefreshHint(); return true
    end
    if action == "primary" or action == "mode" then
        if window.layout and Input.layoutMode ~= "controls" then
            Input.layoutMode = "controls"; RefreshHint(); return true
        end
        local entry = Input.focus
        if not Eligible(entry) then return Input.Cycle(1) end
        if entry.activate then entry.activate(entry.control)
        elseif entry.combo then return Input.Adjust(entry, 1)
        elseif entry.kind == "slider" then return Input.Adjust(entry, 1)
        elseif entry.control.GetHandler and entry.control:GetHandler("OnClicked") then Handler(entry.control, "OnClicked", MOUSE_BUTTON_INDEX_LEFT)
        elseif entry.kind ~= "inspect" then Handler(entry.control, "OnMouseUp", MOUSE_BUTTON_INDEX_LEFT, true) end
        Input.Refresh(); return true
    end
    return false
end
function Input.OpenSettings()
    if InCombat() or Input.loading or DialogVisible() then return false end
    if ASUI.Shell and ASUI.Shell.ToggleSettingsWindow then ASUI.Shell:ToggleSettingsWindow(); return true end
    return false
end
function Input.MoveHUD()
    if InCombat() or Input.loading or DialogVisible() then return false end
    if not ASUI.Layout then return false end
    if ASUI.Layout.active or ASUI.Layout.pending then
        if ASUI.Layout.Done then ASUI.Layout.Done() else ASUI.Layout.Finish() end
        return true
    end
    return ASUI.Layout.Start()
end
function Input.RegisterGamepadEntry()
    if Input.gamepadEntry or not GAMEPAD_OPTIONS or not GAMEPAD_OPTIONS.RegisterCustomCategory or not ZO_GamepadEntryData then return false end
    local entry = ZO_GamepadEntryData:New("Ąlpha Şquad UI", "EsoUI/Art/Options/Gamepad/gp_options_interface.dds")
    entry.sortOrder = 1000
    if entry.SetIconTintOnSelection then entry:SetIconTintOnSelection(true) end
    entry.callback = function()
        if InCombat() or Input.loading or DialogVisible() then return end
        local function Open()
            if InCombat() or Input.loading then return end
            if ASUI.Settings and ASUI.Settings.OpenPage then ASUI.Settings.OpenPage("dashboard") end
        end
        local base = SCENE_MANAGER and SCENE_MANAGER.GetBaseScene and SCENE_MANAGER:GetBaseScene()
        if base and base.GetName and SCENE_MANAGER.CallWhen and SCENE_MANAGER.ShowBaseScene then
            if SCENE_MANAGER:GetCurrentScene() == base then Open()
            else SCENE_MANAGER:CallWhen(base:GetName(), SCENE_SHOWN, Open); SCENE_MANAGER:ShowBaseScene() end
        else Open() end
    end
    GAMEPAD_OPTIONS:RegisterCustomCategory(entry); Input.gamepadEntry = entry
    return true
end
local function BeforeDialog()
    if not Input.activeWindow then return end
    Input.nativePending = true
    Input.Deactivate(true)
    -- Failed/queued requests must not strand the addon without its input layer.
    if zo_callLater then zo_callLater(function() Input.nativePending = nil; Input.Refresh() end, 0)
    else Input.nativePending = nil end
end
function Input.Initialize()
    if Input.initialized then return end
    Input.initialized = true
    local defaults = {
        {"ASUI_KEY_UP", KEY_UPARROW}, {"ASUI_KEY_DOWN", KEY_DOWNARROW},
        {"ASUI_KEY_LEFT", KEY_LEFTARROW}, {"ASUI_KEY_RIGHT", KEY_RIGHTARROW},
        {"ASUI_KEY_ACCEPT", KEY_ENTER}, {"ASUI_KEY_BACK", KEY_ESCAPE},
        {"ASUI_KEY_NEXT", KEY_TAB}, {"ASUI_KEY_PREVIOUS", KEY_TAB, KEY_SHIFT},
        {"ASUI_KEY_MODE", KEY_SPACEBAR}, {"ASUI_KEY_PANEL_PREVIOUS", KEY_PAGEUP},
        {"ASUI_KEY_PANEL_NEXT", KEY_PAGEDOWN},
    }
    if CreateDefaultActionBind then
        for _, bind in ipairs(defaults) do
            if bind[2] then CreateDefaultActionBind(bind[1], bind[2], bind[3] or 0, 0, 0, 0) end
        end
    end
    if EVENT_MANAGER then
        local function Event(id, callback)
            if id then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Input", id, callback) end
        end
        Event(EVENT_PLAYER_COMBAT_STATE, function(_, combat)
            if combat then Input.Deactivate(true); if ASUI.Layout then ASUI.Layout.Finish() end
            else Input.Refresh() end
        end)
        Event(EVENT_PLAYER_DEACTIVATED, function() Input.loading = true; Input.Deactivate(true); if ASUI.Layout then ASUI.Layout.Finish(true) end end)
        Event(EVENT_PLAYER_ACTIVATED, function() Input.loading = false; Input.RegisterGamepadEntry(); Input.Refresh() end)
        Event(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() Input.Deactivate(true); Input.Refresh() end)
    end
    if CALLBACK_MANAGER and CALLBACK_MANAGER.RegisterCallback then
        CALLBACK_MANAGER:RegisterCallback("AllDialogsHidden", function() Input.nativePending = nil; Input.Refresh() end)
    end
    if ZO_PreHook then
        for _, name in ipairs({"ZO_Dialogs_ShowDialog", "ZO_Dialogs_ShowGamepadDialog", "ZO_Dialogs_ShowPlatformDialog"}) do
            if type(_G[name]) == "function" then ZO_PreHook(name, BeforeDialog) end
        end
    end
    if SCENE_MANAGER and SCENE_MANAGER.RegisterCallback then
        SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, _, state)
            local control = Input.activeWindow or Input.suspendedWindow
            local previousScene = Input.activeScene or Input.suspendedScene
            if control and state == SCENE_SHOWING and previousScene ~= scene then
                local data = Input.windows[control]
                local name = scene and scene.GetName and scene:GetName()
                local previousName = previousScene and previousScene.GetName and previousScene:GetName()
                local fromGameplay = previousName == "hud" or previousName == "hudui"
                if data and (data.layout or fromGameplay) and (name == "hud" or name == "hudui") then
                    -- Native cursor ownership can itself transition HUD/HUDUI,
                    -- including when Done returns to the addon settings. This
                    -- retains the same context; external menus still dismiss it.
                    if Input.activeWindow then Input.activeScene = scene else Input.suspendedScene = scene end
                    return
                end
                Input.Deactivate()
                local dismiss = data and (data.dismiss or data.close)
                if dismiss then dismiss() elseif control then control:SetHidden(true) end
            end
        end)
    end
    Input.RegisterGamepadEntry()
    Input.Refresh()
end
if ZO_CreateStringId then
    ZO_CreateStringId("SI_BINDING_NAME_ASUI_OPEN_SETTINGS", "Open Alpha Squad UI")
    ZO_CreateStringId("SI_BINDING_NAME_ASUI_MOVE_HUD", "Move Alpha Squad UI HUD")
    ZO_CreateStringId("SI_ASUI_KEYBIND_CATEGORY", "Ąlpha Şquad UI")
end
