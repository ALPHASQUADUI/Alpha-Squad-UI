-- Ąlpha Şquad UI - ULT Tracker / Group Configuration

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT or not ULT.Group then return end

local Group = ULT.Group

local COLORS = ULT.COLORS or {
    bg = {0.010, 0.016, 0.030, 0.98},
    panel = {0.020, 0.030, 0.052, 0.98},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function Solid(parent, name, color)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetAnchorFill(parent)
    SetColor(texture, color)
    return texture
end

local function Label(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(text or "")
    SetColor(label, color or COLORS.white)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return label
end

local function Button(parent, name, text, x, y, w, h, callback)
    local button = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    button:SetDimensions(w, h)
    button:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    button:SetMouseEnabled(true)

    button.bg = Solid(button, name .. "BG", COLORS.panel)
    button.label = Label(button, name .. "Label", "ZoFontGameSmall", text or "", COLORS.white)
    button.label:SetAnchorFill(button)
    button.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    button:SetHandler("OnMouseEnter", function()
        button.bg:SetColor(0.050, 0.065, 0.090, 1)
    end)
    button:SetHandler("OnMouseExit", function()
        button.bg:SetColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3], COLORS.panel[4])
    end)
    button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and callback then
            callback(button)
        end
    end)

    return button
end

local function AbilityLabel(id, fallback)
    id = tonumber(id) or 0
    if id <= 0 then return fallback or "No Ultimate" end

    local name = GetAbilityName and GetAbilityName(id) or ""
    if not name or name == "" then return fallback or ("Ultimate " .. tostring(id)) end
    return zo_strformat("<<C:1>>", name)
end

function Group:GetModeText(entry)
    local assignment = entry and entry.assignment or nil
    local mode = assignment and assignment.mode or "auto"

    if mode == "main" then
        return "MAIN • " .. AbilityLabel(entry and entry.ult1ID, "No Ultimate")
    elseif mode == "back" then
        return "BACK • " .. AbilityLabel(entry and entry.ult2ID, "No Ultimate")
    end

    return "AUTO • Best ready"
end

function Group:ShowUltimateMenu(entry, anchorButton)
    if not entry or not anchorButton then return end

    local options = {
        { mode = "auto", text = "AUTO • Best ready" },
        { mode = "main", text = "MAIN • " .. AbilityLabel(entry.ult1ID, "No Ultimate") },
        { mode = "back", text = "BACK • " .. AbilityLabel(entry.ult2ID, "No Ultimate") },
    }

    if ClearMenu and AddMenuItem and ShowMenu then
        ClearMenu()

        for _, option in ipairs(options) do
            AddMenuItem(option.text, function()
                Group:SetMemberMode(entry.key, option.mode)
            end)
        end

        ShowMenu(anchorButton)
        return
    end

    -- Safe fallback on clients where the standard popup menu helper is unavailable.
    local current = entry.assignment and entry.assignment.mode or "auto"
    local nextMode = current == "auto" and "main" or (current == "main" and "back" or "auto")
    self:SetMemberMode(entry.key, nextMode)
end

local function CreateMemberRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(736, 42)

    row.bg = Solid(row, "AlphaSquadULTGroupConfigRow" .. index .. "BG", {0.016, 0.024, 0.042, 0.98})

    row.name = Label(row, "AlphaSquadULTGroupConfigRow" .. index .. "Name", "ZoFontGameSmall", "", COLORS.white)
    row.name:SetDimensions(178, 20)
    row.name:SetAnchor(TOPLEFT, row, TOPLEFT, 12, 3)
    row.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.name:SetMaxLineCount(1)

    row.account = Label(row, "AlphaSquadULTGroupConfigRow" .. index .. "Account", "ZoFontGameSmall", "", COLORS.muted)
    row.account:SetDimensions(178, 16)
    row.account:SetAnchor(TOPLEFT, row, TOPLEFT, 12, 22)
    row.account:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.account:SetMaxLineCount(1)

    row.share = Label(row, "AlphaSquadULTGroupConfigRow" .. index .. "Share", "ZoFontGameSmall", "", COLORS.muted)
    row.share:SetDimensions(86, 40)
    row.share:SetAnchor(TOPLEFT, row, TOPLEFT, 198, 1)
    row.share:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    row.trackButton = Button(row, "AlphaSquadULTGroupConfigRow" .. index .. "Track", "", 292, 6, 80, 30, nil)
    row.ultButton = Button(row, "AlphaSquadULTGroupConfigRow" .. index .. "Ult", "", 382, 6, 340, 30, nil)

    return row
end

function Group:RefreshConfigRow(row, entry)
    if not row then return end

    if not entry then
        row:SetHidden(true)
        row.entry = nil
        return
    end

    row:SetHidden(false)
    row.entry = entry

    row.name:SetText(entry.characterName or entry.key or "Unknown")
    row.account:SetText(entry.displayName ~= "" and entry.displayName or entry.unitTag or "")

    if entry.shared then
        row.share:SetText("SHARING")
        SetColor(row.share, COLORS.green)
    else
        row.share:SetText("NO DATA")
        SetColor(row.share, COLORS.muted)
    end

    local tracked = entry.assignment and entry.assignment.tracked == true
    row.trackButton.label:SetText(tracked and "TRACK" or "HIDE")
    SetColor(row.trackButton.label, tracked and COLORS.green or COLORS.red)

    row.ultButton.label:SetText(self:GetModeText(entry))
    SetColor(row.ultButton.label, entry.shared and COLORS.white or COLORS.muted)

    row.trackButton:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and row.entry then
            local assignment = row.entry.assignment or Group:GetAssignment(row.entry.key)
            Group:SetMemberTracked(row.entry.key, not (assignment and assignment.tracked == true))
        end
    end)

    row.ultButton:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and row.entry then
            Group:ShowUltimateMenu(row.entry, row.ultButton)
        end
    end)
end

function Group:RefreshConfig()
    if not self.configWindow or self.configWindow:IsHidden() then return end

    local roster = self.roster or {}
    local shared, total = self:GetSharingCount()

    if not self.libraryAvailable then
        self.configWindow.source:SetText("LibGroupCombatStats not detected • group ULT values cannot be read")
        SetColor(self.configWindow.source, COLORS.red)
    else
        self.configWindow.source:SetText(string.format("LibGroupCombatStats connected • %d/%d members currently sharing ULT data", shared, total))
        SetColor(self.configWindow.source, shared > 0 and COLORS.green or COLORS.muted)
    end

    self.configWindow.empty:SetHidden(#roster > 0)

    for index, row in ipairs(self.configWindow.rows) do
        local entry = roster[index]
        self:RefreshConfigRow(row, entry)

        if entry then
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.configWindow, TOPLEFT, 22, 132 + ((index - 1) * 44))
        end
    end

    local g = self.sv
    self.configWindow.enabledButton.label:SetText(g.enabled and "GROUP TRACKING: ON" or "GROUP TRACKING: OFF")
    SetColor(self.configWindow.enabledButton.label, g.enabled and COLORS.green or COLORS.red)

    self.configWindow.visibleButton.label:SetText(g.visible and "HUD: SHOWN" or "HUD: HIDDEN")
    SetColor(self.configWindow.visibleButton.label, g.visible and COLORS.green or COLORS.muted)

    self.configWindow.lockButton.label:SetText(g.locked and "POSITION: LOCKED" or "POSITION: UNLOCKED")
    SetColor(self.configWindow.lockButton.label, g.locked and COLORS.green or COLORS.gold)

    self.configWindow.selfButton.label:SetText(g.includeSelf and "SELF: INCLUDED" or "SELF: HIDDEN")
    SetColor(self.configWindow.selfButton.label, g.includeSelf and COLORS.green or COLORS.muted)

    if self.configWindow.scaleValue then
        self.configWindow.scaleValue:SetText(tostring(g.scale or 100) .. "%")
    end
    if self.configWindow.opacityValue then
        self.configWindow.opacityValue:SetText(tostring(g.opacity or 92) .. "%")
    end
    if self.configWindow.soundButton then
        self.configWindow.soundButton.label:SetText(g.readySound and "SOUND ON" or "SOUND OFF")
        SetColor(self.configWindow.soundButton.label, g.readySound and COLORS.green or COLORS.muted)
    end
end

function Group:OpenConfig()
    if not self.configWindow then return end

    self:BuildRoster()
    self.configWindow:SetHidden(false)
    self:RefreshConfig()
    self:ApplyVisibility()
end

function Group:CloseConfig()
    if not self.configWindow then return end
    self.configWindow:SetHidden(true)
    self:ApplyVisibility()
end

function Group:ToggleConfig()
    if not self.configWindow then return end

    if self.configWindow:IsHidden() then
        self:OpenConfig()
    else
        self:CloseConfig()
    end
end

function Group:CreateConfigWindow()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupConfigWindow")
    self.configWindow = win

    win:SetDimensions(780, 760)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(140)
    win:SetHidden(true)

    Solid(win, "AlphaSquadULTGroupConfigBG", {0.008, 0.013, 0.025, 0.997})

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigTop", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(3)
    SetColor(top, COLORS.orange)

    local header = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigHeader", win, CT_CONTROL)
    header:SetDimensions(780, 64)
    header:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    header:SetMouseEnabled(true)
    header:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then win:StartMoving() end
    end)
    header:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then win:StopMovingOrResizing() end
    end)

    local title = Label(win, "AlphaSquadULTGroupConfigTitle", "ZoFontWinH2",
        "GROUP ULTIMATE CONFIG", COLORS.orange)
    title:SetDimensions(480, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = Label(win, "AlphaSquadULTGroupConfigSub", "ZoFontGameSmall",
        "Choose who to track and which shared Ultimate the raidlead window should display.", COLORS.muted)
    sub:SetDimensions(610, 20)
    sub:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 40)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win, "AlphaSquadULTGroupConfigClose", "X", 730, 15, 32, 30, function()
        Group:CloseConfig()
    end)

    win.source = Label(win, "AlphaSquadULTGroupConfigSource", "ZoFontGameSmall", "", COLORS.muted)
    win.source:SetDimensions(736, 22)
    win.source:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 69)
    win.source:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.enabledButton = Button(win, "AlphaSquadULTGroupConfigEnabled", "", 22, 96, 170, 30, function()
        Group:SetEnabled(not Group.sv.enabled)
        Group:RefreshConfig()
    end)

    win.visibleButton = Button(win, "AlphaSquadULTGroupConfigVisible", "", 202, 96, 150, 30, function()
        Group:SetVisible(not Group.sv.visible)
        Group:RefreshConfig()
    end)

    win.lockButton = Button(win, "AlphaSquadULTGroupConfigLock", "", 362, 96, 180, 30, function()
        Group:SetLocked(not Group.sv.locked)
        Group:RefreshConfig()
    end)

    win.selfButton = Button(win, "AlphaSquadULTGroupConfigSelf", "", 552, 96, 206, 30, function()
        Group.sv.includeSelf = not Group.sv.includeSelf
        Group:Refresh("include self")
        Group:RefreshConfig()
    end)

    local playerHeader = Label(win, "AlphaSquadULTGroupConfigPlayerHeader", "ZoFontGameBold", "PLAYER", COLORS.orange)
    playerHeader:SetDimensions(178, 20)
    playerHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 34, 128)
    playerHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local shareHeader = Label(win, "AlphaSquadULTGroupConfigShareHeader", "ZoFontGameBold", "DATA", COLORS.orange)
    shareHeader:SetDimensions(86, 20)
    shareHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 220, 128)
    shareHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local trackHeader = Label(win, "AlphaSquadULTGroupConfigTrackHeader", "ZoFontGameBold", "DISPLAY", COLORS.orange)
    trackHeader:SetDimensions(80, 20)
    trackHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 314, 128)
    trackHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local ultHeader = Label(win, "AlphaSquadULTGroupConfigUltHeader", "ZoFontGameBold", "ULTIMATE TO TRACK", COLORS.orange)
    ultHeader:SetDimensions(340, 20)
    ultHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 404, 128)
    ultHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.rows = {}
    for index = 1, 12 do
        win.rows[index] = CreateMemberRow(win, index)
        win.rows[index]:SetHidden(true)
    end

    win.empty = Label(win, "AlphaSquadULTGroupConfigEmpty", "ZoFontGame", "No group members found.", COLORS.muted)
    win.empty:SetDimensions(736, 80)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 180)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    win.empty:SetHidden(true)

    win.scaleMinus = Button(win, "AlphaSquadULTGroupScaleMinus", "SCALE −", 22, 666, 82, 30, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) - 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.scaleValue = Label(win, "AlphaSquadULTGroupScaleValue", "ZoFontGameBold", "", COLORS.cyan)
    win.scaleValue:SetDimensions(62, 30)
    win.scaleValue:SetAnchor(TOPLEFT, win, TOPLEFT, 108, 666)
    win.scaleValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.scalePlus = Button(win, "AlphaSquadULTGroupScalePlus", "SCALE +", 174, 666, 82, 30, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) + 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.opacityMinus = Button(win, "AlphaSquadULTGroupOpacityMinus", "OPACITY −", 274, 666, 96, 30, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) - 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.opacityValue = Label(win, "AlphaSquadULTGroupOpacityValue", "ZoFontGameBold", "", COLORS.cyan)
    win.opacityValue:SetDimensions(62, 30)
    win.opacityValue:SetAnchor(TOPLEFT, win, TOPLEFT, 374, 666)
    win.opacityValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.opacityPlus = Button(win, "AlphaSquadULTGroupOpacityPlus", "OPACITY +", 440, 666, 96, 30, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) + 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.soundButton = Button(win, "AlphaSquadULTGroupReadySound", "", 550, 666, 96, 30, function()
        Group.sv.readySound = not Group.sv.readySound
        Group:RefreshConfig()
    end)

    win.resetButton = Button(win, "AlphaSquadULTGroupReset", "RESET HUD", 656, 666, 102, 30, function()
        Group:ResetPosition()
    end)

    local footer = Label(win, "AlphaSquadULTGroupConfigFooter", "ZoFontGameSmall",
        "AUTO follows the Ultimate closest to READY. MAIN/BACK follows that player's shared weapon-bar Ultimate. Players without shared data remain selectable but show NO DATA.", COLORS.muted)
    footer:SetDimensions(736, 38)
    footer:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 708)
    footer:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    footer:SetVerticalAlignment(TEXT_ALIGN_TOP)
end
