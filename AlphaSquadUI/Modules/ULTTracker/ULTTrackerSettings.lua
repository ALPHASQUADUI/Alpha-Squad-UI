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
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    if settings and settings.OpenPage and settings.OpenPage("ulttracker") then
        self:ApplyVisibility()
        return
    end

    -- Fallback for unusual load orders / development copies.
    if not self.settingsWindow and self.CreateSettings then
        self:CreateSettings()
    end
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


-- Build the ULT Tracker page inside the shared Settings > Ąlpha Şquad shell.
-- UI primitives are provided by the shell so the module keeps the same visual language
-- without moving module-specific behavior into the Overload source file.
function ULT:BuildIntegratedSettingsPage(page, ui)
    if not page or not ui then return end

    local CreateLabel = ui.CreateLabel
    local CreateCard = ui.CreateCard
    local AddToggleRow = ui.AddToggleRow
    local AddStepperRow = ui.AddStepperRow
    local CreateButton = ui.CreateButton
    local RegisterRefresher = ui.RegisterRefresher
    local C = ui.colors or COLORS

    local title = CreateLabel(page, "AlphaSquadULTIntegratedTitle", "ZoFontWinH2", "ULT TRACKER", C.white)
    title:SetDimensions(420, 32)
    title:SetAnchor(TOPLEFT, page, TOPLEFT, 8, 2)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = CreateLabel(page, "AlphaSquadULTIntegratedSub", "ZoFontGameSmall",
        "MAIN / BACK Ultimate readiness • all classes • all morphs • dynamic slot detection", C.muted)
    sub:SetDimensions(650, 22)
    sub:SetAnchor(TOPLEFT, page, TOPLEFT, 9, 34)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local general = CreateCard(page, "AlphaSquadULTIntegratedGeneral", 8, 68, 322, 226, "GENERAL", C.orange)

    AddToggleRow(general, "AlphaSquadULTIntegratedEnabled", "Enable ULT Tracker", 42,
        function() return ULT.sv and ULT.sv.enabled == true end,
        function(v) if ULT.sv then ULT:SetEnabled(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedVisible", "Show tracker HUD", 78,
        function() return ULT.sv and ULT.sv.visible == true end,
        function(v) if ULT.sv then ULT:SetVisible(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedLocked", "Lock position", 114,
        function() return ULT.sv and ULT.sv.locked == true end,
        function(v) if ULT.sv then ULT:SetLocked(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedMenus", "Hide when ESO menus open", 150,
        function() return ULT.sv and ULT.sv.hideInMenus == true end,
        function(v)
            if ULT.sv then
                ULT.sv.hideInMenus = v == true
                ULT:ApplyVisibility()
            end
        end)

    CreateButton(general, "AlphaSquadULTIntegratedReset", "RESET POSITION", 14, 188, 140, 30, function()
        if ULT.sv then ULT:ResetPosition() end
    end)

    CreateButton(general, "AlphaSquadULTIntegratedMove", "UNLOCK & MOVE", 164, 188, 144, 30, function()
        if not ULT.sv then return end
        ULT:SetVisible(true)
        ULT:SetLocked(false)
        local mainSettings = AlphaSquadUI and AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
        if mainSettings then mainSettings:SetHidden(true) end
        ULT:ApplyVisibility()
    end)

    local tracking = CreateCard(page, "AlphaSquadULTIntegratedTracking", 344, 68, 322, 226, "TRACKING", C.cyan)

    local modeLabel = CreateLabel(tracking, "AlphaSquadULTIntegratedModeLabel", "ZoFontGame", "Bars to track", C.white)
    modeLabel:SetDimensions(290, 28)
    modeLabel:SetAnchor(TOPLEFT, tracking, TOPLEFT, 14, 42)
    modeLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local function SelectTrackMode(mode)
        if not ULT.sv then return end
        ULT:SetTrackMode(mode)
        local refreshMain = AlphaSquadUI
            and AlphaSquadUI.Settings
            and AlphaSquadUI.Settings.RefreshMain
        if refreshMain then refreshMain() end
    end

    local mainButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeMain", "MAIN", 14, 74, 88, 32, function()
        SelectTrackMode("main")
    end)
    local backButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeBack", "BACK", 116, 74, 88, 32, function()
        SelectTrackMode("back")
    end)
    local bothButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeBoth", "BOTH", 218, 74, 88, 32, function()
        SelectTrackMode("both")
    end)

    RegisterRefresher(function()
        local selectedMode = ULT.sv and ULT.sv.trackMode or "both"
        for mode, button in pairs({ main = mainButton, back = backButton, both = bothButton }) do
            local selected = selectedMode == mode
            if button.bg then
                if selected then
                    button.bg:SetColor(0.13, 0.075, 0.025, 0.98)
                else
                    button.bg:SetColor(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
                end
            end
            if button.label then
                local color = selected and C.orange or C.white
                button.label:SetColor(color[1], color[2], color[3], 1)
            end
        end
    end)

    AddToggleRow(tracking, "AlphaSquadULTIntegratedSound", "Sound when Ultimate is READY", 122,
        function() return ULT.sv and ULT.sv.readySound == true end,
        function(v) if ULT.sv then ULT.sv.readySound = v == true end end)

    AddToggleRow(tracking, "AlphaSquadULTIntegratedFlash", "Flash / pulse while READY", 158,
        function() return ULT.sv and ULT.sv.readyFlash == true end,
        function(v)
            if ULT.sv then
                ULT.sv.readyFlash = v == true
                ULT:Refresh("integrated settings flash")
            end
        end)

    local appearance = CreateCard(page, "AlphaSquadULTIntegratedAppearance", 8, 310, 322, 214, "APPEARANCE", C.cyan)

    AddStepperRow(appearance, "AlphaSquadULTIntegratedScale", "Tracker scale", 42,
        function() return ULT.sv and ULT.sv.scale or 100 end,
        function(v)
            if ULT.sv then
                ULT.sv.scale = v
                ULT:ApplyAppearance()
            end
        end,
        5, 70, 150, "%", C.cyan)

    AddStepperRow(appearance, "AlphaSquadULTIntegratedOpacity", "Background opacity", 82,
        function() return ULT.sv and ULT.sv.opacity or 92 end,
        function(v)
            if ULT.sv then
                ULT.sv.opacity = v
                ULT:ApplyAppearance()
            end
        end,
        5, 30, 100, "%", C.cyan)

    local note = CreateLabel(appearance, "AlphaSquadULTIntegratedAppearanceNote", "ZoFontGameSmall",
        "Background opacity never dims the Ultimate icons, names, readiness status or active-bar indicator.", C.muted)
    note:SetDimensions(288, 76)
    note:SetAnchor(TOPLEFT, appearance, TOPLEFT, 14, 130)
    note:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    note:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local runtime = CreateCard(page, "AlphaSquadULTIntegratedRuntime", 344, 310, 322, 214, "LIVE STATUS", C.green)

    local livePrimary = CreateLabel(runtime, "AlphaSquadULTIntegratedPrimary", "ZoFontGameSmall", "", C.white)
    livePrimary:SetDimensions(288, 52)
    livePrimary:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 42)
    livePrimary:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    livePrimary:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local liveBackup = CreateLabel(runtime, "AlphaSquadULTIntegratedBackup", "ZoFontGameSmall", "", C.white)
    liveBackup:SetDimensions(288, 52)
    liveBackup:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 94)
    liveBackup:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    liveBackup:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local current = CreateLabel(runtime, "AlphaSquadULTIntegratedCurrent", "ZoFontGameBold", "", C.gold)
    current:SetDimensions(288, 28)
    current:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 154)
    current:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    RegisterRefresher(function()
        local p = ULT.bars and ULT.bars.primary
        local b = ULT.bars and ULT.bars.backup
        local pName = p and p.name ~= "" and p.name or "No Ultimate"
        local bName = b and b.name ~= "" and b.name or "No Ultimate"
        livePrimary:SetText(string.format("MAIN  •  %s\n%s  •  Cost %s",
            pName, p and string.upper(p.state or "empty") or "EMPTY", p and tostring(p.cost or "?") or "?"))
        liveBackup:SetText(string.format("BACK  •  %s\n%s  •  Cost %s",
            bName, b and string.upper(b.state or "empty") or "EMPTY", b and tostring(b.cost or "?") or "?"))
        current:SetText(string.format("CURRENT ULTIMATE: %d", tonumber(ULT.currentUltimate) or 0))
    end)

    local groupCard = CreateCard(page, "AlphaSquadULTIntegratedGroup", 8, 540, 658, 78, "GROUP TRACKING • RAIDLEAD TOOL", C.gold)

    local groupStatus = CreateLabel(groupCard, "AlphaSquadULTIntegratedGroupStatus", "ZoFontGameSmall", "", C.muted)
    groupStatus:SetDimensions(410, 38)
    groupStatus:SetAnchor(TOPLEFT, groupCard, TOPLEFT, 14, 34)
    groupStatus:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    groupStatus:SetVerticalAlignment(TEXT_ALIGN_TOP)

    CreateButton(groupCard, "AlphaSquadULTIntegratedGroupConfig", "CONFIGURE GROUP", 466, 34, 176, 32, function()
        if ULT.Group and ULT.Group.OpenConfig then
            ULT.Group:OpenConfig()
        end
    end)

    RegisterRefresher(function()
        local group = ULT.Group
        if not group or not group.sv then
            groupStatus:SetText("Group tracker initializing...")
            SetColor(groupStatus, C.muted)
            return
        end

        local shared, total = group:GetSharingCount()
        if not group.libraryAvailable then
            groupStatus:SetText("OFFLINE • LibGroupCombatStats required for live group Ultimate values")
            SetColor(groupStatus, C.red)
        elseif not group.sv.enabled then
            groupStatus:SetText(string.format("DISABLED • %d/%d group members sharing ULT data", shared, total))
            SetColor(groupStatus, C.muted)
        else
            groupStatus:SetText(string.format("ENABLED • %d/%d sharing • Event-driven raidlead list", shared, total))
            SetColor(groupStatus, C.green)
        end
    end)
end


if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ulttracker", function(page, ui)
        ULT:BuildIntegratedSettingsPage(page, ui)
    end)
end
