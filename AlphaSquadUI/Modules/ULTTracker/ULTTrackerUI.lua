-- Ąlpha Şquad UI - ULT Tracker HUD

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}
local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

local COLORS = (AlphaSquadUI.Theme and AlphaSquadUI.Theme.colors) or {
    bg = {0.010, 0.016, 0.030, 0.96},
    panel = {0.020, 0.030, 0.052, 0.98},
    panelActive = {0.050, 0.035, 0.020, 0.99},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    cyanDim = {0.10, 0.36, 0.49, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

ULT.COLORS = COLORS

local function SetColor(control, c, alpha)
    if not control or not c then return end
    control:SetColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function Solid(parent, name, color)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    control:SetAnchorFill(parent)
    SetColor(control, color)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(control,color) end
    return control
end

local function Label(parent, name, font, text, color)
    local control = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    control:SetFont(font)
    control:SetText(text or "")
    SetColor(control, color or COLORS.white)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(control,color or COLORS.white) end
    control:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return control
end

local function CreateCard(parent, key, x)
    local card = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_Card", parent, CT_CONTROL)
    card:SetDimensions(276, 94)
    card:SetAnchor(TOPLEFT, parent, TOPLEFT, x, 36)

    card.bg = Solid(card, "AlphaSquadULTTracker_" .. key .. "_BG", COLORS.panel)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(card,card.bg,"card") end

    card.activeAccent = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_ActiveAccent", card, CT_TEXTURE)
    card.activeAccent:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 0)
    card.activeAccent:SetDimensions(4, 94)
    SetColor(card.activeAccent, COLORS.orange)

    card.iconBorder = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_IconBorder", card, CT_TEXTURE)
    card.iconBorder:SetDimensions(60, 60)
    card.iconBorder:SetAnchor(LEFT, card, LEFT, 13, 1)
    SetColor(card.iconBorder, COLORS.cyanDim)

    card.iconBG = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_IconBG", card, CT_TEXTURE)
    card.iconBG:SetDimensions(56, 56)
    card.iconBG:SetAnchor(CENTER, card.iconBorder, CENTER, 0, 0)
    card.iconBG:SetColor(0.005, 0.010, 0.020, 1)

    card.icon = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_Icon", card, CT_TEXTURE)
    card.icon:SetDimensions(52, 52)
    card.icon:SetAnchor(CENTER, card.iconBorder, CENTER, 0, 0)
    card.icon:SetTextureCoords(0.04, 0.96, 0.04, 0.96)

    card.readyGlow = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_ReadyGlow", card, CT_TEXTURE)
    card.readyGlow:SetDimensions(68, 68)
    card.readyGlow:SetAnchor(CENTER, card.iconBorder, CENTER, 0, 0)
    card.readyGlow:SetBlendMode(TEX_BLEND_MODE_ADD)
    card.readyGlow:SetColor(COLORS.green[1], COLORS.green[2], COLORS.green[3], 0)
    card.readyGlow:SetDrawLayer(DL_OVERLAY)

    card.barLabel = Label(card, "AlphaSquadULTTracker_" .. key .. "_Bar", "ZoFontGameSmall", "", COLORS.orange)
    card.barLabel:SetDimensions(102, 18)
    card.barLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 83, 8)
    card.barLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    card.activeLabel = Label(card, "AlphaSquadULTTracker_" .. key .. "_Active", "ZoFontGameSmall", "", COLORS.orange)
    card.activeLabel:SetDimensions(76, 18)
    card.activeLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, -9, 8)
    card.activeLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    card.nameLabel = Label(card, "AlphaSquadULTTracker_" .. key .. "_Name", "ZoFontGameBold", "NO ULTIMATE", COLORS.white)
    card.nameLabel:SetDimensions(180, 23)
    card.nameLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 83, 27)
    card.nameLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    card.nameLabel:SetMaxLineCount(1)
    if card.nameLabel.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        card.nameLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    card.statusLabel = Label(card, "AlphaSquadULTTracker_" .. key .. "_Status", "ZoFontGameBold", "EMPTY", COLORS.muted)
    card.statusLabel:SetDimensions(110, 20)
    card.statusLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 83, 51)
    card.statusLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    card.costLabel = Label(card, "AlphaSquadULTTracker_" .. key .. "_Cost", "ZoFontGameSmall", "", COLORS.muted)
    card.costLabel:SetDimensions(72, 20)
    card.costLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, -9, 51)
    card.costLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    card.progressBG = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_ProgressBG", card, CT_TEXTURE)
    card.progressBG:SetDimensions(180, 4)
    card.progressBG:SetAnchor(BOTTOMLEFT, card, BOTTOMLEFT, 83, -12)
    card.progressBG:SetColor(0.05, 0.08, 0.12, 1)

    card.progress = WINDOW_MANAGER:CreateControl("AlphaSquadULTTracker_" .. key .. "_Progress", card, CT_TEXTURE)
    card.progress:SetDimensions(0, 4)
    card.progress:SetAnchor(LEFT, card.progressBG, LEFT, 0, 0)
    SetColor(card.progress, COLORS.cyan)

    card:SetMouseEnabled(true)
    card:SetHandler("OnMouseEnter",function()
        local bar=ULT.bars[key]
        local tooltips=AlphaSquadUI.Tooltips
        if tooltips and bar and bar.abilityId>0 then
            if bar.overload and bar.overloadState=="critical" then
                tooltips.ShowText(card,"Low Ultimate reserve. Click to request native Overload cancellation, or press your Ultimate key.")
            elseif tooltips.ShowSkill then tooltips.ShowSkill(card,{id=bar.abilityId,name=bar.name},false) end
        end
    end)
    card:SetHandler("OnMouseExit",function() if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end end)
    card:SetHandler("OnMouseUp",function(_,button,inside)
        if button==MOUSE_BUTTON_INDEX_LEFT and inside~=false and ULT.sv.locked then
            local bar=ULT.bars[key]
            if bar.overload and bar.overloadState=="critical" and ULT.Overload then ULT.Overload:TryCancel("manual") end
        end
    end)
    return card
end

ULT.layoutName="Personal Ultimate"
ULT.layoutBounds={minWidth=320,minHeight=142,maxWidth=1500,maxHeight=700}
function ULT:GetWindowWidth()
    return self.sv and self.sv.trackMode=="both" and 610 or 360
end
function ULT:ApplyLayout()
    if not self.window or not self.sv then return end
    local layout=AlphaSquadUI.Layout
    local width,height=self:GetWindowWidth(),142
    self.layoutBounds.minHeight=142
    if layout and layout.GetDimensions then width,height=layout.GetDimensions(self,width,height)
    else width=self.sv.hudWidth or width;height=self.sv.hudHeight or height end
    width=self.Clamp(width,320,1500);height=self.Clamp(height,142,700)
    local keys={}
    for _,key in ipairs({"primary","backup"}) do if self:ShouldTrackBar(key) then keys[#keys+1]=key end end
    local stacked=#keys==2 and width<580
    self.layoutBounds.minHeight=stacked and 248 or 142
    if stacked then height=math.max(height,248) end
    self.window:SetDimensions(width,height)
    local count=math.max(1,#keys)
    local cardW=stacked and width-24 or (width-24-((count-1)*10))/count
    local cardH=stacked and (height-48-10)/2 or height-48
    for _,card in pairs(self.window.cards) do card:SetHidden(true) end
    for index,key in ipairs(keys) do
        local card=self.window.cards[key]
        card:SetHidden(false);card:ClearAnchors()
        card:SetAnchor(TOPLEFT,self.window,TOPLEFT,12+(stacked and 0 or (index-1)*(cardW+10)),36+(stacked and (index-1)*(cardH+10) or 0))
        card:SetDimensions(cardW,cardH);card.activeAccent:SetHeight(cardH)
        local icon=math.max(40,math.min(68,cardH-30))
        card.iconBorder:SetDimensions(icon+8,icon+8);card.iconBG:SetDimensions(icon+4,icon+4)
        card.icon:SetDimensions(icon,icon);card.readyGlow:SetDimensions(icon+16,icon+16)
        local textX=icon+32;local textW=math.max(120,cardW-textX-10)
        for _,entry in ipairs({{card.barLabel,8,18},{card.nameLabel,27,23},{card.statusLabel,52,22}}) do
            entry[1]:ClearAnchors();entry[1]:SetAnchor(TOPLEFT,card,TOPLEFT,textX,entry[2]);entry[1]:SetDimensions(textW,entry[3])
        end
        card.barLabel:SetWidth(math.max(60,textW-60));card.activeLabel:SetWidth(54)
        card.costLabel:SetHidden(cardW<365)
        card.statusLabel:SetWidth(cardW<365 and textW or math.max(70,textW-74))
        card.progressBG:ClearAnchors();card.progressBG:SetAnchor(BOTTOMLEFT,card,BOTTOMLEFT,textX,-10)
        card.progressBG:SetWidth(textW);card.progressWidth=textW
        local cost=self.bars[key].cost or 0
        card.progress:SetWidth(cost>0 and textW*math.max(0,math.min(1,(self.currentUltimate or 0)/cost)) or 0)
    end
    self.window.brand:SetFont(width<460 and "ZoFontGameSmall" or "ZoFontGameBold")
    self.window.brand:SetDimensions(math.max(140,width-164),24)
    self.window.brand:SetText(AlphaSquadUI.Theme and AlphaSquadUI.Theme.Brand and AlphaSquadUI.Theme.Brand("ULT") or "Alpha Squad UI • ULT")
    self.window.ultCounter:ClearAnchors();self.window.ultCounter:SetAnchor(TOPRIGHT,self.window,TOPRIGHT,-14,8)
    self.window.moveHint:ClearAnchors();self.window.moveHint:SetAnchor(TOPRIGHT,self.window,TOPRIGHT,-98,10)
    self.window.moveHint:SetDimensions(48,20);self.window.moveHint:SetText("DRAG")
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end

function ULT:ApplyPosition()
    if not self.window or not self.sv then return end
    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.sv.x, self.sv.y)
end

function ULT:ClampToScreen(saveIfChanged)
    if not self.window or not self.sv or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale = self.window:GetScale() or ((self.sv.scale or 100) / 100)
    local width = (self.window:GetWidth() or self:GetWindowWidth()) * scale
    local height = (self.window:GetHeight() or 142) * scale

    local left = self.window:GetLeft()
    local top = self.window:GetTop()
    if left == nil or top == nil then return end

    local maxX = math.max(0, rootW - width)
    local maxY = math.max(0, rootH - height)
    local clampedX = ULT.Clamp(left, 0, maxX)
    local clampedY = ULT.Clamp(top, 0, maxY)

    if math.abs(clampedX - left) > 0.5 or math.abs(clampedY - top) > 0.5 then
        self.window:ClearAnchors()
        self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, clampedX, clampedY)
        if saveIfChanged then
            self.sv.x = math.floor(clampedX + 0.5)
            self.sv.y = math.floor(clampedY + 0.5)
            self.sv.positionSaved = true
        end
    end
end

function ULT:SavePosition()
    if not self.window or not self.sv then return end
    local left, top = self.window:GetLeft(), self.window:GetTop()
    if left and top then
        self.sv.x = math.floor(left + 0.5)
        self.sv.y = math.floor(top + 0.5)
        self.sv.positionSaved = true
        self:ClampToScreen(true)
    end
end

function ULT:ResetPosition()
    if not self.sv then return end
    local x, y = self:GetDefaultPosition()
    self.sv.x, self.sv.y = x, y
    self.sv.positionSaved = true
    self:ApplyPosition()
    if self.RefreshSettings then self:RefreshSettings() end
end

function ULT:UpdateLockState()
    if not self.window or not self.sv then return end
    self.window:SetMovable(not self.sv.locked)
    self.window.dragSurface:SetMouseEnabled(not self.sv.locked)
    self.window.moveHint:SetHidden(self.sv.locked)
end

function ULT:ApplyVisibility()
    if not self.window or not self.sv then return end

    local settingsVisible = self.settingsWindow and not self.settingsWindow:IsHidden() or false
    local sharedSettings = AlphaSquadUI and AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
    local sharedSettingsVisible = sharedSettings and not sharedSettings:IsHidden() or false
    local settings = AlphaSquadUI.Settings
    if settings and settings.AnyExclusiveWindowVisible then
        sharedSettingsVisible = sharedSettingsVisible or settings.AnyExclusiveWindowVisible()
    end
    local moving = AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(self)
    local hidden =
        self.loading == true
        or not self.sv.enabled
        or (not self.sv.visible and not moving)
        or settingsVisible
        or sharedSettingsVisible
        or (self.sv.hideInMenus and self.uiObscured and not moving)

    self.window:SetHidden(hidden)
    if self.SetSafetyUpdateActive then self:SetSafetyUpdateActive(not hidden and not moving) end

    if hidden then
        self:SetFlashUpdate(false)
    else
        self:SetFlashUpdate(self:NeedsPulse() and not moving)
    end

    if self.Group and self.Group.ApplyVisibility then
        self.Group:ApplyVisibility()
    end
end

function ULT:GetEffectiveScale()
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.GetScale then return AlphaSquadUI.Layout.GetScale(self) end
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local baseW = self.window:GetWidth() or self:GetWindowWidth()
    local baseH = self.window:GetHeight() or 142

    -- Preserve the player's chosen size on normal/large screens, but automatically
    -- cap it when necessary so the full HUD can still fit on smaller resolutions.
    local fitX = math.max(0.55, (rootW - 24) / math.max(1, baseW))
    local fitY = math.max(0.55, (rootH - 24) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function ULT:ApplyAppearance()
    if not self.window or not self.sv then return end
    self.window:SetScale(self:GetEffectiveScale())
    self.window:SetAlpha(1)
    self.window.bg:SetAlpha((self.sv.opacity or 92) / 100)
    self:ClampToScreen(true)
end

function ULT:RefreshCard(card, bar)
    if not card or not bar then return end

    card.barLabel:SetText(bar.label)
    card.activeLabel:SetText(bar.activeBar and "ACTIVE" or "")
    card.activeAccent:SetHidden(not bar.activeBar)
    local bgColor = bar.activeBar and COLORS.panelActive or COLORS.panel
    card.bg:SetColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    if bar.abilityId <= 0 then
        card.icon:SetHidden(true)
        card.nameLabel:SetText("NO ULTIMATE")
        card.statusLabel:SetText("EMPTY")
        SetColor(card.statusLabel, COLORS.muted)
        card.costLabel:SetText("")
        SetColor(card.iconBorder, COLORS.cyanDim, 0.35)
        card.readyGlow:SetColor(COLORS.green[1], COLORS.green[2], COLORS.green[3], 0)
        card.progress:SetWidth(0)
        return
    end

    card.icon:SetHidden(false)
    if bar.icon and bar.icon ~= "" then card.icon:SetTexture(bar.icon) end
    card.nameLabel:SetText(zo_strformat("<<C:1>>", bar.name ~= "" and bar.name or "Ultimate"))
    card.costLabel:SetText(bar.cost > 0 and ("COST " .. tostring(bar.cost)) or "COST ?")

    local state = bar.overload and bar.overloadState or bar.state or "charging"
    local color = COLORS.cyan
    local statusText = "CHARGING"

    if bar.overload then
        if state=="critical" then statusText="TURN OFF!";color=COLORS.red
        elseif state=="warning" then statusText="LOW RESERVE";color=COLORS.red
        elseif state=="active" then statusText="OVERLOAD ON";color=COLORS.green
        elseif state=="ready" then statusText="READY TO ACTIVATE";color=COLORS.gold
        else statusText="OVERLOAD OFF";color=COLORS.muted end
        card.costLabel:SetText("RESERVE "..tostring(self.sv.overload.reserveThreshold))
    elseif state == "ready" then
        statusText = "READY"
        color = COLORS.green
    elseif state == "active" then
        statusText = "ACTIVE"
        color = COLORS.orange
    elseif state == "used" then
        statusText = "USED"
        color = COLORS.gold
    elseif state == "empty" then
        statusText = "EMPTY"
        color = COLORS.muted
    end

    card.statusLabel:SetText(statusText)
    SetColor(card.statusLabel, color)
    SetColor(card.iconBorder, color, state == "ready" and 0.88 or 0.72)
    card.icon:SetAlpha(state == "ready" and 0.96 or (state == "active" and 1 or 0.72))

    local progress = 0
    if bar.cost > 0 then
        progress = math.min(1, math.max(0, (self.currentUltimate or 0) / bar.cost))
    end
    card.progress:SetWidth(math.floor((card.progressWidth or 180) * progress))
    SetColor(card.progress, color)
end

function ULT:RefreshHUD()
    if not self.window or not self.sv then return end

    self.window.ultCounter:SetText(string.format("ULT %d", tonumber(self.currentUltimate) or 0))
    self:ApplyLayout()
    self:RefreshCard(self.window.cards.primary, self.bars.primary)
    self:RefreshCard(self.window.cards.backup, self.bars.backup)
end

function ULT:UpdateReadyPulse()
    if not self.window or not self.sv or self.window:IsHidden() then return end

    local t = (GetGameTimeMilliseconds and GetGameTimeMilliseconds() or 0) / 1000
    -- Slow, restrained breathing pulse: readable without a fluorescent/neon effect.
    local pulse = (math.sin(t * 2.8) + 1) * 0.5
    local alpha = 0.06 + (pulse * 0.22)
    local borderAlpha = 0.76 + (pulse * 0.14)

    for key, card in pairs(self.window.cards) do
        local bar = self.bars[key]
        if self:ShouldTrackBar(key) and bar and bar.overload and (bar.overloadState=="critical" or bar.overloadState=="warning" or bar.overloadState=="ready") then
            local danger=bar.overloadState~="ready"
            local rate=bar.overloadState=="critical" and 17 or danger and 10 or 3
            local wave=(math.sin(t*rate)+1)*0.5
            local color=danger and COLORS.red or COLORS.gold
            card.readyGlow:SetColor(color[1],color[2],color[3],0.08+wave*0.46)
            card.iconBorder:SetColor(color[1],color[2],color[3],0.65+wave*0.35)
        elseif self:ShouldTrackBar(key) and bar and bar.ready and self.sv.readyFlash then
            card.readyGlow:SetColor(0.24, 0.78, 0.46, alpha)
            card.iconBorder:SetColor(0.32, 0.90, 0.55, borderAlpha)
            card.icon:SetScale(1)
        else
            card.readyGlow:SetColor(COLORS.green[1], COLORS.green[2], COLORS.green[3], 0)
            card.icon:SetScale(1)
        end
    end
end

function ULT:ResetPulseVisuals()
    if not self.window then return end
    for _, card in pairs(self.window.cards) do
        card.readyGlow:SetColor(COLORS.green[1], COLORS.green[2], COLORS.green[3], 0)
        card.icon:SetScale(1)
    end
    if self.initialized then self:RefreshHUD() end
end

function ULT:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTTrackerWindow")
    self.window = win
    win:SetDimensions(610, 142)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(90)
    if AlphaSquadUI.Settings and AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win, true) end

    win.bg = Solid(win, "AlphaSquadULTTrackerBG", COLORS.bg)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(win,win.bg,"window") end

    local topLine = WINDOW_MANAGER:CreateControl("AlphaSquadULTTrackerTopLine", win, CT_TEXTURE)
    topLine:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    topLine:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    topLine:SetHeight(2)
    SetColor(topLine, COLORS.orange)

    win.brand = Label(win, "AlphaSquadULTTrackerBrand", "ZoFontGameBold", (AlphaSquadUI.Theme and AlphaSquadUI.Theme.Brand and AlphaSquadUI.Theme.Brand("ULT") or "Ąlpha Şquad UI • ULT"), COLORS.orange)
    win.brand:SetDimensions(310, 24)
    win.brand:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 7)
    win.brand:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.moveHint = Label(win, "AlphaSquadULTTrackerMoveHint", "ZoFontGameSmall", "CLICK + DRAG", COLORS.gold)
    win.moveHint:SetDimensions(105, 22)
    win.moveHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.ultCounter = Label(win, "AlphaSquadULTTrackerCounter", "ZoFontGameBold", "ULT 0", COLORS.white)
    win.ultCounter:SetDimensions(78, 22)
    win.ultCounter:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.cards = {
        primary = CreateCard(win, "primary", 18),
        backup = CreateCard(win, "backup", 316),
    }

    win.dragSurface = WINDOW_MANAGER:CreateControl("AlphaSquadULTTrackerDragSurface", win, CT_CONTROL)
    win.dragSurface:SetAnchorFill(win)
    win.dragSurface:SetMouseEnabled(true)

    win.dragSurface:SetHandler("OnMouseDown", function()
        if ULT.sv and not ULT.sv.locked then win:StartMoving() end
    end)
    win.dragSurface:SetHandler("OnMouseUp", function()
        if ULT.sv and not ULT.sv.locked then
            win:StopMovingOrResizing()
            ULT:SavePosition()
        end
    end)

    -- Covers releases outside the drag surface and movement stopped by the UI system.
    win:SetHandler("OnMoveStop", function()
        if ULT.sv and not ULT.sv.locked then
            ULT:SavePosition()
        end
    end)

    self:ApplyLayout()
    self:ApplyPosition()
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.Attach then AlphaSquadUI.Layout.Attach(self) end
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.OnChanged then AlphaSquadUI.Theme.OnChanged(function() ULT:RefreshHUD() end) end
end
