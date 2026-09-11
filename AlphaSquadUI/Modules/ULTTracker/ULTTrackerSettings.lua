-- Ąlpha Şquad UI - ULT Tracker Settings

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}
local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

local COLORS = ULT.COLORS or {
    bg = {0.010, 0.016, 0.030, 0.98},
    panel = {0.020, 0.030, 0.052, 0.98},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    green = {0.28, 1.00, 0.54, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

local function SetColor(control, c, alpha)
    control:SetColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function Solid(parent, name, color)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    control:SetAnchorFill(parent)
    SetColor(control, color)
    return control
end

local function Label(parent, name, font, text, color)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    control:SetFont(font)
    control:SetText(text or "")
    SetColor(control, color or COLORS.white)
    control:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return control
end

local function Button(parent, name, text, x, y, w, h, callback)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    control:SetDimensions(w, h)
    control:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    control:SetMouseEnabled(true)

    control.bg = Solid(control, name .. "BG", COLORS.panel)
    control.label = Label(control, name .. "Label", "ZoFontGame", text, COLORS.white)
    control.label:SetAnchorFill(control)
    control.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    control:SetHandler("OnMouseEnter", function()
        control.bg:SetColor(0.050, 0.065, 0.090, 1)
    end)
    control:SetHandler("OnMouseExit", function()
        control.bg:SetColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3], COLORS.panel[4])
    end)
    control:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and callback then callback() end
    end)

    return control
end

local function Card(parent, name, x, y, w, h, title)
    local card = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    card:SetDimensions(w, h)
    card:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    card.bg = Solid(card, name .. "BG", {0.018, 0.027, 0.048, 0.99})

    local accent = WINDOW_MANAGER:CreateControl(name .. "Accent", card, CT_TEXTURE)
    accent:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 0)
    accent:SetDimensions(3, h)
    SetColor(accent, COLORS.orange)

    local titleLabel = Label(card, name .. "Title", "ZoFontGameBold", title, COLORS.orange)
    titleLabel:SetDimensions(w - 30, 24)
    titleLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 15, 8)
    titleLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    return card
end

function ULT:RefreshSettings()
    if not self.settingsWindow or not self.settingsRefreshers then return end
    for _, fn in ipairs(self.settingsRefreshers) do fn() end
end

function ULT:ToggleSettings()
    if not self.settingsWindow then return end
    local opening = self.settingsWindow:IsHidden()
    self.settingsWindow:SetHidden(not opening)
    if opening then self:RefreshSettings() end
    self:ApplyVisibility()
end

function ULT:CreateSettings()
    self.settingsRefreshers = {}

    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTTrackerSettings")
    self.settingsWindow = win
    win:SetDimensions(690, 590)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(120)
    win:SetHidden(true)

    Solid(win, "AlphaSquadULTTrackerSettingsBG", {0.008, 0.013, 0.025, 0.995})

    local topLine = WINDOW_MANAGER:CreateControl("AlphaSquadULTTrackerSettingsTop", win, CT_TEXTURE)
    topLine:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    topLine:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    topLine:SetHeight(3)
    SetColor(topLine, COLORS.orange)

    local header = WINDOW_MANAGER:CreateControl("AlphaSquadULTTrackerSettingsHeader", win, CT_CONTROL)
    header:SetDimensions(690, 64)
    header:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    header:SetMouseEnabled(true)
    header:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then win:StartMoving() end
    end)
    header:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then win:StopMovingOrResizing() end
    end)

    local title = Label(win, "AlphaSquadULTTrackerSettingsTitle", "ZoFontWinH2", "ĄLPHA ŞQUAD  •  ULT TRACKER", COLORS.orange)
    title:SetDimensions(500, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = Label(win, "AlphaSquadULTTrackerSettingsSub", "ZoFontGameSmall",
        "Generic MAIN / BACK Ultimate readiness tracker  •  all classes & morphs", COLORS.muted)
    sub:SetDimensions(540, 20)
    sub:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 39)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win, "AlphaSquadULTTrackerSettingsClose", "X", 638, 15, 34, 30, function()
        win:SetHidden(true)
        ULT:ApplyVisibility()
    end)

    local function AddToggle(parent, name, text, y, getter, setter)
        local label = Label(parent, name .. "Text", "ZoFontGame", text, COLORS.white)
        label:SetDimensions(parent:GetWidth() - 112, 30)
        label:SetAnchor(TOPLEFT, parent, TOPLEFT, 15, y)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        local button = Button(parent, name, "", parent:GetWidth() - 90, y, 74, 30, function()
            setter(not getter())
            ULT:RefreshSettings()
        end)

        table.insert(ULT.settingsRefreshers, function()
            local enabled = getter()
            button.label:SetText(enabled and "ON" or "OFF")
            SetColor(button.label, enabled and COLORS.green or COLORS.red)
        end)
    end

    local general = Card(win, "AlphaSquadULTSettingsGeneral", 20, 82, 316, 220, "GENERAL")
    AddToggle(general, "AlphaSquadULTOptEnabled", "Enable ULT Tracker", 43,
        function() return ULT.sv.enabled end,
        function(v) ULT:SetEnabled(v) end)
    AddToggle(general, "AlphaSquadULTOptVisible", "Show HUD", 80,
        function() return ULT.sv.visible end,
        function(v) ULT:SetVisible(v) end)
    AddToggle(general, "AlphaSquadULTOptLocked", "Lock position", 117,
        function() return ULT.sv.locked end,
        function(v) ULT:SetLocked(v) end)
    AddToggle(general, "AlphaSquadULTOptMenus", "Hide when ESO menus open", 154,
        function() return ULT.sv.hideInMenus end,
        function(v) ULT.sv.hideInMenus = v; ULT:ApplyVisibility() end)

    Button(general, "AlphaSquadULTResetPos", "RESET POSITION", 15, 188, 136, 26, function()
        ULT:ResetPosition()
    end)
    Button(general, "AlphaSquadULTMovePos", "UNLOCK & MOVE", 160, 188, 140, 26, function()
        ULT:SetLocked(false)
        ULT:SetVisible(true)
        win:SetHidden(true)
        ULT:ApplyVisibility()
    end)

    local tracking = Card(win, "AlphaSquadULTSettingsTracking", 354, 82, 316, 220, "TRACKING")
    local modeText = Label(tracking, "AlphaSquadULTModeText", "ZoFontGame", "Bars to track", COLORS.white)
    modeText:SetDimensions(280, 28)
    modeText:SetAnchor(TOPLEFT, tracking, TOPLEFT, 15, 43)
    modeText:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local mainBtn = Button(tracking, "AlphaSquadULTModeMain", "MAIN", 15, 75, 86, 32, function() ULT:SetTrackMode("main") end)
    local backBtn = Button(tracking, "AlphaSquadULTModeBack", "BACK", 111, 75, 86, 32, function() ULT:SetTrackMode("back") end)
    local bothBtn = Button(tracking, "AlphaSquadULTModeBoth", "BOTH", 207, 75, 86, 32, function() ULT:SetTrackMode("both") end)

    table.insert(self.settingsRefreshers, function()
        for mode, button in pairs({main=mainBtn, back=backBtn, both=bothBtn}) do
            local selected = ULT.sv.trackMode == mode
            button.bg:SetColor(selected and 0.12 or COLORS.panel[1], selected and 0.07 or COLORS.panel[2], selected and 0.025 or COLORS.panel[3], 1)
            SetColor(button.label, selected and COLORS.orange or COLORS.white)
        end
    end)

    AddToggle(tracking, "AlphaSquadULTReadySound", "Sound when Ultimate becomes READY", 121,
        function() return ULT.sv.readySound end,
        function(v) ULT.sv.readySound = v end)
    AddToggle(tracking, "AlphaSquadULTReadyFlash", "Flash / pulse while READY", 158,
        function() return ULT.sv.readyFlash end,
        function(v)
            ULT.sv.readyFlash = v
            ULT:Refresh("flash changed")
        end)

    local appearance = Card(win, "AlphaSquadULTSettingsAppearance", 20, 320, 650, 150, "APPEARANCE")

    local scaleText = Label(appearance, "AlphaSquadULTScaleText", "ZoFontGame", "HUD scale", COLORS.white)
    scaleText:SetDimensions(190, 30)
    scaleText:SetAnchor(TOPLEFT, appearance, TOPLEFT, 15, 44)
    scaleText:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    local scaleValue = Label(appearance, "AlphaSquadULTScaleValue", "ZoFontGameBold", "", COLORS.cyan)
    scaleValue:SetDimensions(72, 30)
    scaleValue:SetAnchor(TOPLEFT, appearance, TOPLEFT, 206, 44)
    scaleValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    Button(appearance, "AlphaSquadULTScaleMinus", "−", 284, 44, 38, 30, function()
        ULT.sv.scale = ULT.Clamp(ULT.sv.scale - 5, 70, 150); ULT:ApplyAppearance(); ULT:RefreshSettings()
    end)
    Button(appearance, "AlphaSquadULTScalePlus", "+", 328, 44, 38, 30, function()
        ULT.sv.scale = ULT.Clamp(ULT.sv.scale + 5, 70, 150); ULT:ApplyAppearance(); ULT:RefreshSettings()
    end)

    local opacityText = Label(appearance, "AlphaSquadULTOpacityText", "ZoFontGame", "Background opacity", COLORS.white)
    opacityText:SetDimensions(190, 30)
    opacityText:SetAnchor(TOPLEFT, appearance, TOPLEFT, 15, 88)
    opacityText:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    local opacityValue = Label(appearance, "AlphaSquadULTOpacityValue", "ZoFontGameBold", "", COLORS.cyan)
    opacityValue:SetDimensions(72, 30)
    opacityValue:SetAnchor(TOPLEFT, appearance, TOPLEFT, 206, 88)
    opacityValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    Button(appearance, "AlphaSquadULTOpacityMinus", "−", 284, 88, 38, 30, function()
        ULT.sv.opacity = ULT.Clamp(ULT.sv.opacity - 5, 30, 100); ULT:ApplyAppearance(); ULT:RefreshSettings()
    end)
    Button(appearance, "AlphaSquadULTOpacityPlus", "+", 328, 88, 38, 30, function()
        ULT.sv.opacity = ULT.Clamp(ULT.sv.opacity + 5, 30, 100); ULT:ApplyAppearance(); ULT:RefreshSettings()
    end)

    local info = Label(appearance, "AlphaSquadULTAppearanceInfo", "ZoFontGameSmall",
        "Opacity affects the background only. Ultimate icons, names and readiness states remain fully visible.", COLORS.muted)
    info:SetDimensions(245, 70)
    info:SetAnchor(TOPRIGHT, appearance, TOPRIGHT, -18, 45)
    info:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    info:SetVerticalAlignment(TEXT_ALIGN_TOP)

    table.insert(self.settingsRefreshers, function()
        scaleValue:SetText(tostring(ULT.sv.scale) .. "%")
        opacityValue:SetText(tostring(ULT.sv.opacity) .. "%")
    end)

    local help = Card(win, "AlphaSquadULTSettingsHelp", 20, 488, 650, 80, "COMMAND")
    local helpText = Label(help, "AlphaSquadULTSettingsHelpText", "ZoFontGameSmall",
        "/asult opens these settings.  /asult main | back | both  •  /asult lock | unlock  •  /asult status", COLORS.muted)
    helpText:SetDimensions(610, 36)
    helpText:SetAnchor(TOPLEFT, help, TOPLEFT, 15, 36)
    helpText:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    self:RefreshSettings()
end
