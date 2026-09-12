-- Ąlpha Şquad UI - ULT Tracker / Group Ultimate Filter Configuration

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

local function CreateAbilityRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupAbilityRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(354, 32)
    row:SetMouseEnabled(true)

    row.bg = Solid(row, "AlphaSquadULTGroupAbilityRow" .. index .. "BG", {0.016, 0.024, 0.042, 0.96})

    row.icon = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupAbilityRow" .. index .. "Icon", row, CT_TEXTURE)
    row.icon:SetDimensions(24, 24)
    row.icon:SetAnchor(LEFT, row, LEFT, 6, 0)
    row.icon:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    row.name = Label(row, "AlphaSquadULTGroupAbilityRow" .. index .. "Name", "ZoFontGameSmall", "", COLORS.white)
    row.name:SetDimensions(220, 30)
    row.name:SetAnchor(LEFT, row, LEFT, 36, 0)
    row.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.name:SetMaxLineCount(1)
    if row.name.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.name:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    row.users = Label(row, "AlphaSquadULTGroupAbilityRow" .. index .. "Users", "ZoFontGameSmall", "", COLORS.muted)
    row.users:SetDimensions(42, 30)
    row.users:SetAnchor(RIGHT, row, RIGHT, -52, 0)
    row.users:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.state = Label(row, "AlphaSquadULTGroupAbilityRow" .. index .. "State", "ZoFontGameBold", "", COLORS.muted)
    row.state:SetDimensions(48, 30)
    row.state:SetAnchor(RIGHT, row, RIGHT, -4, 0)
    row.state:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.ability = nil
    return row
end

function Group:RefreshAbilityRow(row, ability)
    if not row then return end

    if not ability then
        row:SetHidden(true)
        row.ability = nil
        return
    end

    row:SetHidden(false)
    row.ability = ability

    row.icon:SetHidden(not ability.icon or ability.icon == "")
    if ability.icon and ability.icon ~= "" then row.icon:SetTexture(ability.icon) end

    row.name:SetText(ability.name or ("Ultimate " .. tostring(ability.id)))
    row.users:SetText(tostring(ability.users or 0) .. "x")

    local tracked = self:IsAbilityTracked(ability.id)
    row.state:SetText(tracked and "ON" or "OFF")
    SetColor(row.state, tracked and COLORS.green or COLORS.muted)

    if tracked then
        row.bg:SetColor(0.040, 0.085, 0.062, 0.94)
    else
        row.bg:SetColor(0.016, 0.024, 0.042, 0.96)
    end

    row:SetHandler("OnMouseEnter", function()
        if tracked then
            row.bg:SetColor(0.055, 0.110, 0.078, 1)
        else
            row.bg:SetColor(0.045, 0.058, 0.080, 1)
        end
    end)

    row:SetHandler("OnMouseExit", function()
        if Group:IsAbilityTracked(ability.id) then
            row.bg:SetColor(0.040, 0.085, 0.062, 0.94)
        else
            row.bg:SetColor(0.016, 0.024, 0.042, 0.96)
        end
    end)

    row:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and row.ability then
            local enabled = Group:IsAbilityTracked(row.ability.id)
            Group:SetAbilityTracked(row.ability.id, not enabled)
        end
    end)
end

function Group:RefreshConfig()
    if not self.configWindow or self.configWindow:IsHidden() then return end

    local abilities = self:GetAvailableAbilities()
    local shared, total = self:GetSharingCount()
    local trackedCount = self:GetTrackedAbilityCount()

    if not self.libraryAvailable then
        self.configWindow.source:SetText("Group share unavailable • LibGroupCombatStats not detected")
        SetColor(self.configWindow.source, COLORS.red)
    else
        self.configWindow.source:SetText(string.format("%d/%d members sharing • %d unique Ultimates available • %d selected",
            shared, total, #abilities, trackedCount))
        SetColor(self.configWindow.source, shared > 0 and COLORS.green or COLORS.muted)
    end

    self.configWindow.empty:SetHidden(#abilities > 0)

    for index, row in ipairs(self.configWindow.abilityRows) do
        local ability = abilities[index]
        self:RefreshAbilityRow(row, ability)

        if ability then
            local col = index <= 12 and 0 or 1
            local rowIndex = col == 0 and index or (index - 12)
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.configWindow, TOPLEFT,
                col == 0 and 22 or 404,
                152 + ((rowIndex - 1) * 34))
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

    self.configWindow.soundButton.label:SetText(g.readySound and "READY SOUND: ON" or "READY SOUND: OFF")
    SetColor(self.configWindow.soundButton.label, g.readySound and COLORS.green or COLORS.muted)

    self.configWindow.scaleValue:SetText(tostring(g.scale or 100) .. "%")
    self.configWindow.opacityValue:SetText(tostring(g.opacity or 92) .. "%")
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

    win:SetDimensions(780, 650)
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
    header:SetDimensions(780, 62)
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
        "Select the Ultimates to monitor. Players are added automatically when they have one slotted.", COLORS.muted)
    sub:SetDimensions(660, 20)
    sub:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 39)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win, "AlphaSquadULTGroupConfigClose", "X", 730, 15, 32, 28, function()
        Group:CloseConfig()
    end)

    win.source = Label(win, "AlphaSquadULTGroupConfigSource", "ZoFontGameSmall", "", COLORS.muted)
    win.source:SetDimensions(736, 20)
    win.source:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 68)
    win.source:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.enabledButton = Button(win, "AlphaSquadULTGroupConfigEnabled", "", 22, 96, 120, 28, function()
        Group:SetEnabled(not Group.sv.enabled)
        Group:RefreshConfig()
    end)

    win.visibleButton = Button(win, "AlphaSquadULTGroupConfigVisible", "", 150, 96, 120, 28, function()
        Group:SetVisible(not Group.sv.visible)
        Group:RefreshConfig()
    end)

    win.lockButton = Button(win, "AlphaSquadULTGroupConfigLock", "", 278, 96, 110, 28, function()
        Group:SetLocked(not Group.sv.locked)
        Group:RefreshConfig()
    end)

    win.selfButton = Button(win, "AlphaSquadULTGroupConfigSelf", "", 396, 96, 110, 28, function()
        Group.sv.includeSelf = not Group.sv.includeSelf
        Group:Refresh("include self")
        Group:RefreshConfig()
    end)

    win.soundButton = Button(win, "AlphaSquadULTGroupReadySound", "", 514, 96, 244, 28, function()
        Group.sv.readySound = not Group.sv.readySound
        Group:RefreshConfig()
    end)

    local listHeader = Label(win, "AlphaSquadULTGroupAbilitiesHeader", "ZoFontGameBold",
        "ULTIMATES AVAILABLE IN CURRENT GROUP", COLORS.orange)
    listHeader:SetDimensions(736, 22)
    listHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 128)
    listHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.abilityRows = {}
    for index = 1, 24 do
        win.abilityRows[index] = CreateAbilityRow(win, index)
        win.abilityRows[index]:SetHidden(true)
    end

    win.empty = Label(win, "AlphaSquadULTGroupConfigEmpty", "ZoFontGame", "No shared Ultimates found in the group.", COLORS.muted)
    win.empty:SetDimensions(736, 80)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 210)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    win.empty:SetHidden(true)

    local controlsY = 570

    Button(win, "AlphaSquadULTGroupSelectAll", "SELECT ALL", 22, controlsY, 110, 28, function()
        for _, ability in ipairs(Group:GetAvailableAbilities()) do
            Group.sv.trackedAbilities[tostring(ability.id)] = true
        end
        Group:Refresh("select all abilities")
    end)

    Button(win, "AlphaSquadULTGroupClearAll", "CLEAR ALL", 140, controlsY, 110, 28, function()
        Group.sv.trackedAbilities = {}
        Group:Refresh("clear tracked abilities")
    end)

    win.scaleMinus = Button(win, "AlphaSquadULTGroupScaleMinus", "−", 278, controlsY, 32, 28, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) - 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)
    win.scaleValue = Label(win, "AlphaSquadULTGroupScaleValue", "ZoFontGameBold", "", COLORS.cyan)
    win.scaleValue:SetDimensions(54, 28)
    win.scaleValue:SetAnchor(TOPLEFT, win, TOPLEFT, 314, controlsY)
    win.scaleValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    win.scalePlus = Button(win, "AlphaSquadULTGroupScalePlus", "+", 372, controlsY, 32, 28, function()
        Group.sv.scale = ULT.Clamp((Group.sv.scale or 100) + 5, 70, 140)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    win.opacityMinus = Button(win, "AlphaSquadULTGroupOpacityMinus", "−", 438, controlsY, 32, 28, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) - 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)
    win.opacityValue = Label(win, "AlphaSquadULTGroupOpacityValue", "ZoFontGameBold", "", COLORS.cyan)
    win.opacityValue:SetDimensions(54, 28)
    win.opacityValue:SetAnchor(TOPLEFT, win, TOPLEFT, 474, controlsY)
    win.opacityValue:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    win.opacityPlus = Button(win, "AlphaSquadULTGroupOpacityPlus", "+", 532, controlsY, 32, 28, function()
        Group.sv.opacity = ULT.Clamp((Group.sv.opacity or 92) + 5, 30, 100)
        Group:ApplyAppearance()
        Group:RefreshConfig()
    end)

    Button(win, "AlphaSquadULTGroupReset", "RESET HUD", 648, controlsY, 110, 28, function()
        Group:ResetPosition()
    end)

    local footer = Label(win, "AlphaSquadULTGroupConfigFooter", "ZoFontGameSmall",
        "READY players pulse in the raid list. After an Ultimate is spent, that @UserID is strongly dimmed for a few seconds.", COLORS.muted)
    footer:SetDimensions(736, 36)
    footer:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 607)
    footer:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    footer:SetVerticalAlignment(TEXT_ALIGN_TOP)

    self:ApplyConfigWindowScale()
end
