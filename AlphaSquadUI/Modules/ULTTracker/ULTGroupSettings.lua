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

local function AbilityMeta(id)
    id = tonumber(id) or 0
    if id <= 0 then return "No Ultimate", "", 0 end

    local name = GetAbilityName and GetAbilityName(id) or ""
    local icon = GetAbilityIcon and GetAbilityIcon(id) or ""
    if not name or name == "" then name = "Ultimate " .. tostring(id) end

    return zo_strformat("<<C:1>>", name), icon or "", id
end

local function ShortMode(mode)
    if mode == "main" then return "FRONT" end
    if mode == "back" then return "BACK" end
    return "BOTH"
end

function Group:GetModeText(entry)
    local assignment = entry and entry.assignment or nil
    local mode = assignment and assignment.mode or "both"
    local frontName = AbilityMeta(entry and entry.ult1ID)
    local backName = AbilityMeta(entry and entry.ult2ID)

    if mode == "main" then
        return "FRONT • " .. frontName
    elseif mode == "back" then
        return "BACK • " .. backName
    end

    return "BOTH • " .. frontName .. " + " .. backName
end

local function CreateMemberRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(736, 34)

    row.bg = Solid(row, "AlphaSquadULTGroupConfigRow" .. index .. "BG", {0.016, 0.024, 0.042, 0.98})

    row.name = Label(row, "AlphaSquadULTGroupConfigRow" .. index .. "Name", "ZoFontGameSmall", "", COLORS.white)
    row.name:SetDimensions(176, 32)
    row.name:SetAnchor(LEFT, row, LEFT, 10, 0)
    row.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.name:SetMaxLineCount(1)

    row.share = Label(row, "AlphaSquadULTGroupConfigRow" .. index .. "Share", "ZoFontGameSmall", "", COLORS.muted)
    row.share:SetDimensions(74, 32)
    row.share:SetAnchor(LEFT, row, LEFT, 190, 0)
    row.share:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    row.trackButton = Button(row, "AlphaSquadULTGroupConfigRow" .. index .. "Track", "", 272, 3, 76, 28, nil)
    row.ultButton = Button(row, "AlphaSquadULTGroupConfigRow" .. index .. "Ult", "", 356, 3, 366, 28, nil)
    row.ultButton.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.ultButton.label:SetAnchor(TOPLEFT, row.ultButton, TOPLEFT, 8, 0)
    row.ultButton.label:SetDimensions(350, 28)
    row.ultButton.label:SetMaxLineCount(1)
    if row.ultButton.label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.ultButton.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    return row
end

local function CreateSelectorOption(parent, name, y, mode, color)
    local option = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    option:SetDimensions(570, 54)
    option:SetAnchor(TOPLEFT, parent, TOPLEFT, 20, y)
    option:SetMouseEnabled(true)

    option.bg = Solid(option, name .. "BG", {0.020, 0.030, 0.052, 0.99})

    option.accent = WINDOW_MANAGER:CreateControl(name .. "Accent", option, CT_TEXTURE)
    option.accent:SetAnchor(TOPLEFT, option, TOPLEFT, 0, 0)
    option.accent:SetDimensions(3, 54)
    SetColor(option.accent, color or COLORS.cyan)

    option.mode = Label(option, name .. "Mode", "ZoFontGameBold", mode, color or COLORS.cyan)
    option.mode:SetDimensions(64, 52)
    option.mode:SetAnchor(LEFT, option, LEFT, 10, 0)
    option.mode:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    option.icon1 = WINDOW_MANAGER:CreateControl(name .. "Icon1", option, CT_TEXTURE)
    option.icon1:SetDimensions(36, 36)
    option.icon1:SetAnchor(LEFT, option, LEFT, 82, 0)
    option.icon1:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    option.icon2 = WINDOW_MANAGER:CreateControl(name .. "Icon2", option, CT_TEXTURE)
    option.icon2:SetDimensions(36, 36)
    option.icon2:SetAnchor(LEFT, option, LEFT, 122, 0)
    option.icon2:SetTextureCoords(0.05, 0.95, 0.05, 0.95)
    option.icon2:SetHidden(true)

    option.name = Label(option, name .. "Name", "ZoFontGame", "", COLORS.white)
    option.name:SetDimensions(330, 26)
    option.name:SetAnchor(TOPLEFT, option, TOPLEFT, 130, 4)
    option.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    option.name:SetMaxLineCount(1)

    option.cost = Label(option, name .. "Cost", "ZoFontGameSmall", "", COLORS.muted)
    option.cost:SetDimensions(330, 18)
    option.cost:SetAnchor(TOPLEFT, option, TOPLEFT, 130, 29)
    option.cost:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    option.selected = Label(option, name .. "Selected", "ZoFontGameBold", "", COLORS.green)
    option.selected:SetDimensions(90, 52)
    option.selected:SetAnchor(RIGHT, option, RIGHT, -10, 0)
    option.selected:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    return option
end

function Group:HideUltimateSelector()
    if not self.configWindow or not self.configWindow.selectorOverlay then return end
    self.configWindow.selectorOverlay:SetHidden(true)
    self.configWindow.selectorEntry = nil
end

function Group:SelectUltimateMode(mode)
    local win = self.configWindow
    local entry = win and win.selectorEntry
    if not entry then return end

    self:SetMemberMode(entry.key, mode)
    self:HideUltimateSelector()
    self:RefreshConfig()
end

function Group:RefreshUltimateSelector(entry)
    local win = self.configWindow
    if not win or not win.selectorOverlay or not entry then return end

    local frontName, frontIcon = AbilityMeta(entry.ult1ID)
    local backName, backIcon = AbilityMeta(entry.ult2ID)
    local frontCost = tonumber(entry.ult1Cost) or 0
    local backCost = tonumber(entry.ult2Cost) or 0
    local currentMode = entry.assignment and entry.assignment.mode or "both"

    win.selectorTitle:SetText("SELECT ULTIMATE • " .. (entry.characterName or entry.key or "Player"))

    local front = win.selectorFront
    front.icon1:SetHidden(frontIcon == "")
    if frontIcon ~= "" then front.icon1:SetTexture(frontIcon) end
    front.icon2:SetHidden(true)
    front.name:SetAnchor(TOPLEFT, front, TOPLEFT, 130, 4)
    front.name:SetText(frontName)
    front.cost:SetAnchor(TOPLEFT, front, TOPLEFT, 130, 29)
    front.cost:SetText(frontCost > 0 and ("Front bar • Cost " .. tostring(frontCost)) or "Front bar • No cost data")
    front.selected:SetText(currentMode == "main" and "SELECTED" or "")

    local back = win.selectorBack
    back.icon1:SetHidden(backIcon == "")
    if backIcon ~= "" then back.icon1:SetTexture(backIcon) end
    back.icon2:SetHidden(true)
    back.name:SetAnchor(TOPLEFT, back, TOPLEFT, 130, 4)
    back.name:SetText(backName)
    back.cost:SetAnchor(TOPLEFT, back, TOPLEFT, 130, 29)
    back.cost:SetText(backCost > 0 and ("Back bar • Cost " .. tostring(backCost)) or "Back bar • No cost data")
    back.selected:SetText(currentMode == "back" and "SELECTED" or "")

    local both = win.selectorBoth
    both.icon1:SetHidden(frontIcon == "")
    if frontIcon ~= "" then both.icon1:SetTexture(frontIcon) end
    both.icon2:SetHidden(backIcon == "")
    if backIcon ~= "" then both.icon2:SetTexture(backIcon) end
    both.name:SetAnchor(TOPLEFT, both, TOPLEFT, 170, 4)
    both.name:SetText(frontName .. "  +  " .. backName)
    both.cost:SetAnchor(TOPLEFT, both, TOPLEFT, 170, 29)
    both.cost:SetText(string.format("Front %s • Back %s",
        frontCost > 0 and tostring(frontCost) or "?",
        backCost > 0 and tostring(backCost) or "?"))
    both.selected:SetText(currentMode == "both" and "SELECTED" or "")
end

function Group:ShowUltimateSelector(entry)
    if not self.configWindow or not entry then return end

    self.configWindow.selectorEntry = entry
    self:RefreshUltimateSelector(entry)
    self.configWindow.selectorOverlay:SetHidden(false)
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

    local display = entry.characterName or entry.key or "Unknown"
    if entry.displayName and entry.displayName ~= "" then
        display = display .. "  " .. entry.displayName
    end
    row.name:SetText(display)

    row.share:SetText(entry.shared and "SHARE" or "NO DATA")
    SetColor(row.share, entry.shared and COLORS.green or COLORS.muted)

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
            Group:ShowUltimateSelector(row.entry)
        end
    end)
end

function Group:RefreshConfig()
    if not self.configWindow or self.configWindow:IsHidden() then return end

    local roster = self.roster or {}
    local shared, total = self:GetSharingCount()

    if not self.libraryAvailable then
        self.configWindow.source:SetText("Group share unavailable • LibGroupCombatStats not detected")
        SetColor(self.configWindow.source, COLORS.red)
    else
        self.configWindow.source:SetText(string.format("%d/%d group members sharing Ultimate data", shared, total))
        SetColor(self.configWindow.source, shared > 0 and COLORS.green or COLORS.muted)
    end

    self.configWindow.empty:SetHidden(#roster > 0)

    for index, row in ipairs(self.configWindow.rows) do
        local entry = roster[index]
        self:RefreshConfigRow(row, entry)

        if entry then
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.configWindow, TOPLEFT, 22, 132 + ((index - 1) * 36))
        end
    end

    local g = self.sv
    self.configWindow.enabledButton.label:SetText(g.enabled and "GROUP: ON" or "GROUP: OFF")
    SetColor(self.configWindow.enabledButton.label, g.enabled and COLORS.green or COLORS.red)

    self.configWindow.visibleButton.label:SetText(g.visible and "HUD: SHOW" or "HUD: HIDE")
    SetColor(self.configWindow.visibleButton.label, g.visible and COLORS.green or COLORS.muted)

    self.configWindow.lockButton.label:SetText(g.locked and "LOCKED" or "UNLOCKED")
    SetColor(self.configWindow.lockButton.label, g.locked and COLORS.green or COLORS.gold)

    self.configWindow.selfButton.label:SetText(g.includeSelf and "SELF: ON" or "SELF: OFF")
    SetColor(self.configWindow.selfButton.label, g.includeSelf and COLORS.green or COLORS.muted)

    self.configWindow.scaleValue:SetText(tostring(g.scale or 100) .. "%")
    self.configWindow.opacityValue:SetText(tostring(g.opacity or 92) .. "%")
    self.configWindow.soundButton.label:SetText(g.readySound and "SOUND ON" or "SOUND OFF")
    SetColor(self.configWindow.soundButton.label, g.readySound and COLORS.green or COLORS.muted)

    if self.configWindow.selectorEntry then
        local updatedEntry = self.byKey and self.byKey[self.configWindow.selectorEntry.key]
        if updatedEntry then
            self.configWindow.selectorEntry = updatedEntry
            self:RefreshUltimateSelector(updatedEntry)
        else
            self:HideUltimateSelector()
        end
    end
end

function Group:OpenConfig()
    if not self.configWindow then return end
    self:BuildRoster()
    self:ApplyConfigWindowScale()
    self.configWindow:SetHidden(false)
    self:RefreshConfig()
    self:ApplyVisibility()
end

function Group:CloseConfig()
    if not self.configWindow then return end
    self:HideUltimateSelector()
    self.configWindow:SetHidden(true)
    self:ApplyVisibility()
end

function Group:ToggleConfig()
    if not self.configWindow then return end
    if self.configWindow:IsHidden() then self:OpenConfig() else self:CloseConfig() end
end

function Group:CreateConfigWindow()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupConfigWindow")
    self.configWindow = win

    win:SetDimensions(780, 700)
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

    local title = Label(win, "AlphaSquadULTGroupConfigTitle", "ZoFontWinH2", "GROUP ULTIMATE CONFIG", COLORS.orange)
    title:SetDimensions(480, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = Label(win, "AlphaSquadULTGroupConfigSub", "ZoFontGameSmall",
        "Track players and choose FRONT, BACK or BOTH shared Ultimates.", COLORS.muted)
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

    win.enabledButton = Button(win, "AlphaSquadULTGroupConfigEnabled", "", 22, 96, 130, 28, function()
        Group:SetEnabled(not Group.sv.enabled)
        Group:RefreshConfig()
    end)

    win.visibleButton = Button(win, "AlphaSquadULTGroupConfigVisible", "", 160, 96, 130, 28, function()
        Group:SetVisible(not Group.sv.visible)
        Group:RefreshConfig()
    end)

    win.lockButton = Button(win, "AlphaSquadULTGroupConfigLock", "", 298, 96, 130, 28, function()
        Group:SetLocked(not Group.sv.locked)
        Group:RefreshConfig()
    end)

    win.selfButton = Button(win, "AlphaSquadULTGroupConfigSelf", "", 436, 96, 130, 28, function()
        Group.sv.includeSelf = not Group.sv.includeSelf
        Group:Refresh("include self")
        Group:RefreshConfig()
    end)

    win.soundButton = Button(win, "AlphaSquadULTGroupReadySound", "", 574, 96, 184, 28, function()
        Group.sv.readySound = not Group.sv.readySound
        Group:RefreshConfig()
    end)

    local playerHeader = Label(win, "AlphaSquadULTGroupConfigPlayerHeader", "ZoFontGameBold", "PLAYER", COLORS.orange)
    playerHeader:SetDimensions(176, 20)
    playerHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 32, 128)
    playerHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local shareHeader = Label(win, "AlphaSquadULTGroupConfigShareHeader", "ZoFontGameBold", "DATA", COLORS.orange)
    shareHeader:SetDimensions(74, 20)
    shareHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 212, 128)
    shareHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local trackHeader = Label(win, "AlphaSquadULTGroupConfigTrackHeader", "ZoFontGameBold", "SHOW", COLORS.orange)
    trackHeader:SetDimensions(76, 20)
    trackHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 294, 128)
    trackHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local ultHeader = Label(win, "AlphaSquadULTGroupConfigUltHeader", "ZoFontGameBold", "ULTIMATE", COLORS.orange)
    ultHeader:SetDimensions(366, 20)
    ultHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 378, 128)
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

    win.scaleMinus = Button(win, "AlphaSquadULTGroupScaleMinus", "−", 22, 582, 34, 28, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) - 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.scaleValue = Label(win, "AlphaSquadULTGroupScaleValue", "ZoFontGameBold", "", COLORS.cyan)
    win.scaleValue:SetDimensions(58, 28)
    win.scaleValue:SetAnchor(TOPLEFT, win, TOPLEFT, 60, 582)
    win.scaleValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.scalePlus = Button(win, "AlphaSquadULTGroupScalePlus", "+", 122, 582, 34, 28, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) + 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    local scaleLabel = Label(win, "AlphaSquadULTGroupScaleLabel", "ZoFontGameSmall", "HUD SCALE", COLORS.muted)
    scaleLabel:SetDimensions(90, 28)
    scaleLabel:SetAnchor(TOPLEFT, win, TOPLEFT, 164, 582)
    scaleLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.opacityMinus = Button(win, "AlphaSquadULTGroupOpacityMinus", "−", 282, 582, 34, 28, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) - 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.opacityValue = Label(win, "AlphaSquadULTGroupOpacityValue", "ZoFontGameBold", "", COLORS.cyan)
    win.opacityValue:SetDimensions(58, 28)
    win.opacityValue:SetAnchor(TOPLEFT, win, TOPLEFT, 320, 582)
    win.opacityValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.opacityPlus = Button(win, "AlphaSquadULTGroupOpacityPlus", "+", 382, 582, 34, 28, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) + 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    local opacityLabel = Label(win, "AlphaSquadULTGroupOpacityLabel", "ZoFontGameSmall", "OPACITY", COLORS.muted)
    opacityLabel:SetDimensions(90, 28)
    opacityLabel:SetAnchor(TOPLEFT, win, TOPLEFT, 424, 582)
    opacityLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.resetButton = Button(win, "AlphaSquadULTGroupReset", "RESET HUD", 620, 582, 138, 28, function()
        Group:ResetPosition()
    end)

    local footer = Label(win, "AlphaSquadULTGroupConfigFooter", "ZoFontGameSmall",
        "Click a player's Ultimate field to choose FRONT, BACK or BOTH inside this window.", COLORS.muted)
    footer:SetDimensions(736, 34)
    footer:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 620)
    footer:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    -- Internal Ultimate selector overlay. It is part of GROUP ULTIMATE CONFIG
    -- and never opens ESO's external popup menu.
    win.selectorOverlay = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupSelectorOverlay", win, CT_CONTROL)
    win.selectorOverlay:SetAnchorFill(win)
    win.selectorOverlay:SetMouseEnabled(true)
    win.selectorOverlay:SetHidden(true)

    local shade = Solid(win.selectorOverlay, "AlphaSquadULTGroupSelectorShade", {0.000, 0.000, 0.000, 0.72})

    win.selectorPanel = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupSelectorPanel", win.selectorOverlay, CT_CONTROL)
    win.selectorPanel:SetDimensions(610, 250)
    win.selectorPanel:SetAnchor(CENTER, win.selectorOverlay, CENTER, 0, 0)
    Solid(win.selectorPanel, "AlphaSquadULTGroupSelectorPanelBG", {0.010, 0.016, 0.030, 0.995})

    local selectorTop = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupSelectorTop", win.selectorPanel, CT_TEXTURE)
    selectorTop:SetAnchor(TOPLEFT, win.selectorPanel, TOPLEFT, 0, 0)
    selectorTop:SetAnchor(TOPRIGHT, win.selectorPanel, TOPRIGHT, 0, 0)
    selectorTop:SetHeight(2)
    SetColor(selectorTop, COLORS.orange)

    win.selectorTitle = Label(win.selectorPanel, "AlphaSquadULTGroupSelectorTitle", "ZoFontGameBold", "", COLORS.white)
    win.selectorTitle:SetDimensions(500, 28)
    win.selectorTitle:SetAnchor(TOPLEFT, win.selectorPanel, TOPLEFT, 20, 10)
    win.selectorTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win.selectorPanel, "AlphaSquadULTGroupSelectorClose", "X", 560, 8, 30, 28, function()
        Group:HideUltimateSelector()
    end)

    win.selectorFront = CreateSelectorOption(win.selectorPanel, "AlphaSquadULTSelectorFront", 44, "FRONT", COLORS.cyan)
    win.selectorBack = CreateSelectorOption(win.selectorPanel, "AlphaSquadULTSelectorBack", 103, "BACK", COLORS.orange)
    win.selectorBoth = CreateSelectorOption(win.selectorPanel, "AlphaSquadULTSelectorBoth", 162, "BOTH", COLORS.gold)

    win.selectorFront:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then Group:SelectUltimateMode("main") end
    end)
    win.selectorBack:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then Group:SelectUltimateMode("back") end
    end)
    win.selectorBoth:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then Group:SelectUltimateMode("both") end
    end)

    self:ApplyConfigWindowScale()
end
