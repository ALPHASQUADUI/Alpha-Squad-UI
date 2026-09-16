-- Compact native-skill HUD: both weapon bars, transparent outside skill frames.
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}
local ASUI = AlphaSquadUI
local ULT = ASUI.Modules.ULTTracker
if not ULT then return end
local BAR_KEYS = {"primary", "backup"}
local CARD_WIDTH,CARD_HEIGHT,CARD_GAP=152,48,12
local COLORS = {
    white={0.95,0.97,1,1}, muted={0.65,0.68,0.72,1},
    cyan={0.56,0.74,0.79,1}, green={0.25,0.88,0.38,1},
    red={1,0.23,0.24,1}, gold={0.93,0.78,0.42,1},
}
-- Settings use the shell theme; gameplay status colors remain semantic.
local function L(text,...)
    if ASUI.L then return ASUI.L(text,...) end
    return select("#",...)>0 and string.format(text,...) or text
end
local function Now() return GetGameTimeMilliseconds and GetGameTimeMilliseconds() or 0 end
local function Color(control,c,alpha) control:SetColor(c[1],c[2],c[3],alpha or c[4] or 1) end
local function Texture(name,parent,width,height,color)
    local control=WINDOW_MANAGER:CreateControl(name,parent,CT_TEXTURE)
    control:SetDimensions(width,height)
    if color then Color(control,color) end
    return control
end
local function Label(name,parent)
    local control=WINDOW_MANAGER:CreateControl(name,parent,CT_LABEL)
    control:SetFont("ZoFontGameSmall")
    control:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    control:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    control:SetMaxLineCount(1)
    if control.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then control:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
    return control
end
local function CreateCard(parent,key)
    local prefix="AlphaSquadULTTracker_"..key
    local card=WINDOW_MANAGER:CreateControl(prefix.."_Card",parent,CT_CONTROL)
    card.iconBorder=Texture(prefix.."_IconBorder",card,56,56,COLORS.muted)
    card.icon=Texture(prefix.."_Icon",card,52,52)
    card.icon:SetAnchor(CENTER,card.iconBorder,CENTER,0,0)
    card.icon:SetTextureCoords(0.04,0.96,0.04,0.96)
    card.readyGlow=Texture(prefix.."_ReadyGlow",card,58,58)
    card.readyGlow:SetAnchor(CENTER,card.iconBorder,CENTER,0,0)
    card.readyGlow:SetTexture("EsoUI/Art/ActionBar/abilityFrame64_up.dds")
    card.readyGlow:SetDrawLayer(DL_OVERLAY)
    card.readyGlow:SetColor(0,0,0,0)
    card.activeArrow=WINDOW_MANAGER:CreateControl(prefix.."_ActiveArrow",card,CT_CONTROL)
    card.activeArrow:SetDimensions(12,18)
    -- Small chevron built from nine static scanlines: no external texture,
    -- uncertain asset path, rotation support or recurring animation required.
    for row=0,8 do
        local inset=4-math.abs(row-4)
        local line=Texture(prefix.."_Arrow"..row,card.activeArrow,5,2,COLORS.green)
        line:SetAnchor(TOPLEFT,card.activeArrow,TOPLEFT,inset*1.75,row*2)
    end
    card.progressBG=Texture(prefix.."_ProgressBG",card,52,3,{0.06,0.07,0.08,0.65})
    card.progress=Texture(prefix.."_Progress",card,0,3,COLORS.cyan)
    card.progress:SetAnchor(LEFT,card.progressBG,LEFT,0,0)
    card.reserveMarker=Texture(prefix.."_Reserve",card.progressBG,1,7,COLORS.white)
    card.reserveMarker:SetDrawLayer(DL_OVERLAY)
    card.reserveMarker:SetHidden(true)
    card.valueLabel=Label(prefix.."_Value",card)
    Color(card.valueLabel,COLORS.white)
    card.statusLabel=Label(prefix.."_Status",card)
    card:SetMouseEnabled(true)
    card:SetHandler("OnMouseEnter",function()
        local bar=ULT:GetHUDBar(key)
        if bar and bar.abilityId>0 and ASUI.Tooltips and ASUI.Tooltips.ShowSkill then
            ASUI.Tooltips.ShowSkill(card,{id=bar.abilityId,name=bar.name},false)
        end
    end)
    card:SetHandler("OnMouseExit",function() if ASUI.Tooltips then ASUI.Tooltips.Hide() end end)
    if ASUI.Input and ASUI.Input.Register then ASUI.Input.Register(card,{kind="inspect",label="Personal Ultimate"}) end
    return card
end
ULT.layoutName="Personal Ultimate"
ULT.layoutBounds={minWidth=CARD_WIDTH*2+CARD_GAP,minHeight=CARD_HEIGHT,maxWidth=1800,maxHeight=1000}
ULT.layoutBackground=false
local EMPTY_ICON="EsoUI/Art/ActionBar/abilityFrame64_up.dds"
local previewBars,previewMode
local function PreviewMode(module)
    if not (AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(module)) then return "live" end
    local preview=AlphaSquadUI.Preview
    return preview and preview.GetMode and preview.GetMode() or module.layoutPreviewMode or "mixed"
end
function ULT:SetLayoutPreview(mode)
    self.layoutPreviewMode=mode
    if self.RefreshHUD then self:RefreshHUD() end
end
function ULT:GetHUDBar(key)
    local mode=PreviewMode(self)
    if mode=="live" then return self:GetLiveBar(key) end
    if not previewBars or previewMode~=mode then
        previewMode=mode;previewBars={}
        for index,barKey in ipairs({"primary","backup"}) do
            -- Resolve identity through ESO. These examples never enter the live bars.
            local overload=mode=="overload" and index==1
            local id=overload and 30366 or (index==1 and 40223 or 122174)
            local state=mode=="missing" and "empty" or (mode=="ready" and "ready" or (index==1 and "ready" or "charging"))
            if mode=="overload" then state=overload and "active" or "ready" end
            local name=GetAbilityName and GetAbilityName(id) or "Ultimate"
            local icon=GetAbilityIcon and GetAbilityIcon(id) or EMPTY_ICON
            previewBars[barKey]={key=barKey,label=index==1 and "FRONT BAR" or "BACK BAR",abilityId=state=="empty" and 0 or id,
                name=name,icon=icon~="" and icon or EMPTY_ICON,cost=index==1 and 200 or 250,
                value=mode=="overload" and 300 or (mode=="ready" and 250 or 200),
                ready=state=="ready",state=state,activeBar=index==1,preview=true,
                overload=overload,overloadState=overload and "active" or nil}
        end
    end
    return previewBars[key]
end
function ULT:GetLayoutOrientation()
    return self.sv and self.sv.hudOrientation=="vertical" and "vertical" or "horizontal"
end
function ULT:GetLayoutOrientations()
    return {"horizontal","vertical"}
end
function ULT:SetLayoutOrientation(orientation)
    if not self.sv or (orientation~="horizontal" and orientation~="vertical") then return false end
    local previous=self:GetLayoutOrientation()
    if previous==orientation then return false end
    if type(self.sv.hudLayouts)~="table" then self.sv.hudLayouts={} end
    self.sv.hudLayouts[previous]={width=self.layoutWidth or self.sv.hudWidth,height=self.layoutHeight or self.sv.hudHeight}
    self.sv.hudOrientation=orientation
    local saved=self.sv.hudLayouts[orientation]
    self.sv.hudWidth=type(saved)=="table" and saved.width or nil
    self.sv.hudHeight=type(saved)=="table" and saved.height or nil
    self:RefreshHUD()
    return true
end
function ULT:GetWindowWidth()
    return self:GetLayoutOrientation()=="vertical" and CARD_WIDTH or CARD_WIDTH*2+CARD_GAP
end
function ULT:ApplyLayout()
    if not self.window or not self.sv then return end
    local count=self:ShouldTrackBar("backup") and 2 or 1
    local vertical=self:GetLayoutOrientation()=="vertical"
    local gap=CARD_GAP
    self.layoutBounds.minWidth=vertical and CARD_WIDTH or count*CARD_WIDTH+(count-1)*gap
    self.layoutBounds.minHeight=vertical and count*CARD_HEIGHT+(count-1)*gap or CARD_HEIGHT
    local width,height=self.layoutBounds.minWidth,self.layoutBounds.minHeight
    local layout=ASUI.Layout
    if layout and layout.GetDimensions then width,height=layout.GetDimensions(self,width,height)
    else width=self.sv.hudWidth or width;height=self.sv.hudHeight or height end
    width=self.Clamp(width,self.layoutBounds.minWidth,1800)
    height=self.Clamp(height,self.layoutBounds.minHeight,1000)
    local signature=table.concat({width,height,count,vertical and 1 or 0,self.sv.scale or 100,
        GuiRoot and GuiRoot:GetWidth() or 1920,GuiRoot and GuiRoot:GetHeight() or 1080},":")
    if signature~=self.layoutSignature then
        self.layoutSignature=signature
        self.layoutWidth,self.layoutHeight=width,height
        self.window:SetDimensions(width,height)
        local cardW=vertical and width or (width-(count-1)*gap)/count
        local cardH=vertical and (height-(count-1)*gap)/count or height
        for index,key in ipairs(BAR_KEYS) do
            local card=self.window.cards[key]
            card:SetHidden(index>count)
            if index<=count then
                card:ClearAnchors()
                card:SetAnchor(TOPLEFT,self.window,TOPLEFT,vertical and 0 or (index-1)*(cardW+gap),vertical and (index-1)*(cardH+gap) or 0)
                card:SetDimensions(cardW,cardH)
                local icon=math.max(40,math.min(52,cardW-112,cardH-8))
                local top=math.max(0,(cardH-icon-2)/2)
                local detailLeft=icon+26
                local detailWidth=cardW-detailLeft
                card.iconBorder:ClearAnchors();card.iconBorder:SetAnchor(TOPLEFT,card,TOPLEFT,16,top)
                card.iconBorder:SetDimensions(icon+2,icon+2)
                card.icon:SetDimensions(icon,icon);card.readyGlow:SetDimensions(icon+4,icon+4)
                card.activeArrow:ClearAnchors();card.activeArrow:SetAnchor(RIGHT,card.iconBorder,LEFT,-4,0)
                local detailTop=(cardH-43)/2
                card.valueLabel:ClearAnchors();card.valueLabel:SetAnchor(TOPLEFT,card,TOPLEFT,detailLeft,detailTop)
                card.valueLabel:SetDimensions(detailWidth,19)
                card.progressBG:ClearAnchors();card.progressBG:SetAnchor(TOPLEFT,card,TOPLEFT,detailLeft,detailTop+21)
                card.progressBG:SetWidth(detailWidth);card.progressWidth=detailWidth
                card.progress:SetWidth((card.progressValue or 0)*detailWidth)
                card.reserveMarkerPosition=nil
                card.statusLabel:ClearAnchors();card.statusLabel:SetAnchor(TOPLEFT,card,TOPLEFT,detailLeft,detailTop+25)
                card.statusLabel:SetDimensions(detailWidth,18)
            end
        end
        self:ApplyAppearance()
    end
    self:RefreshCard(self.window.cards.primary,self:GetHUDBar("primary"))
    self:RefreshCard(self.window.cards.backup,self:GetHUDBar("backup"))
    self:UpdateLockState()
    self:ApplyVisibility()
end

-- A bounded 180 ms interpolation only runs when a visible charging bar increases.
-- Spending, missing costs, slot changes and readiness transitions snap immediately.
function ULT:StopProgressAnimation()
    if self.window and self.progressRunning then self.window:SetHandler("OnUpdate",nil) end
    self.progressRunning=false
    if self.window and self.window.cards then
        for _,card in pairs(self.window.cards) do
            card.progressStarted=nil
            if card.progressTarget then
                card.progressValue=card.progressTarget
                card.progress:SetWidth((card.progressWidth or 0)*card.progressValue)
            end
        end
    end
end
function ULT:UpdateProgressAnimation()
    if not self.window or self.window:IsHidden() then self:StopProgressAnimation();return end
    local now=Now()
    local running=false
    for _,card in pairs(self.window.cards) do
        if card.progressStarted then
            local elapsed=math.max(0,math.min(1,(now-card.progressStarted)/180))
            local eased=elapsed*(2-elapsed)
            card.progressValue=card.progressFrom+(card.progressTarget-card.progressFrom)*eased
            card.progress:SetWidth((card.progressWidth or 0)*card.progressValue)
            if elapsed>=1 then card.progressStarted=nil else running=true end
        end
    end
    if not running then self:StopProgressAnimation() end
end
function ULT:SetCardProgress(card,bar,value,state)
    local changed=card.progressTarget~=value or card.progressAbility~=bar.abilityId or card.progressState~=state
    if not changed then return end
    local moving=ASUI.Layout and ASUI.Layout.IsMoving(self)
    local animate=not moving and not card:IsHidden() and card.progressAbility==bar.abilityId
        and card.progressValue~=nil and value>card.progressValue and value<1 and state=="charging"
    card.progressAbility=bar.abilityId;card.progressTarget=value;card.progressState=state
    if animate then
        card.progressFrom=card.progressValue;card.progressStarted=Now()
        if not self.progressRunning then
            self.progressRunning=true
            self.window:SetHandler("OnUpdate",function() ULT:UpdateProgressAnimation() end)
        end
    else
        card.progressStarted=nil;card.progressValue=value
        card.progress:SetWidth((card.progressWidth or 52)*value)
    end
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
    local width = self.window:GetWidth() or self:GetWindowWidth()
    local height = self.window:GetHeight() or 116

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
end

function ULT:ApplyVisibility()
    if not self.window or not self.sv then
        if self.NativeUI then self.NativeUI:Restore() end
        return
    end

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
        self:StopProgressAnimation()
        self:SetFlashUpdate(false)
    else
        self:SetFlashUpdate(self:NeedsPulse() and not moving)
    end
    if self.NativeUI then self.NativeUI:Refresh() end

    if self.Group and self.Group.ApplyVisibility then
        self.Group:ApplyVisibility()
    end
    if not hidden and self.hudDirty and not self.renderingHUD then self:RefreshHUD() end
end

function ULT:GetEffectiveScale()
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.GetScale then return AlphaSquadUI.Layout.GetScale(self,self.layoutWidth,self.layoutHeight) end
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale=self.window:GetScale() or 1
    local baseW = self.layoutWidth or (self.window:GetWidth() / math.max(0.001,scale))
    local baseH = self.layoutHeight or (self.window:GetHeight() / math.max(0.001,scale))

    -- Preserve the player's chosen size on normal/large screens, but automatically
    -- cap it when necessary so the full HUD can still fit on smaller resolutions.
    local fitX = math.max(0.001, (rootW - 24) / math.max(1, baseW))
    local fitY = math.max(0.001, (rootH - 24) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function ULT:ApplyAppearance()
    if not self.window or not self.sv then return end
    self.window:SetScale(self:GetEffectiveScale())
    self.window:SetAlpha(1)
    self:ClampToScreen(false)
end

function ULT:RefreshCard(card,bar)
    if not card or not bar then return end
    local empty=(bar.abilityId or 0)<=0
    local state=empty and "empty" or (bar.overload and bar.overloadState or bar.state or "unknown")
    local value=math.max(0,tonumber(bar.value or self.currentUltimate) or 0)
    local denominator=bar.cost or 0
    local overloadConfig=self.sv.overload
    if bar.overload then denominator=overloadConfig and overloadConfig.readyReminderThreshold or 400 end
    local progress=denominator>0 and math.max(0,math.min(1,value/denominator)) or 0
    if empty then progress=0 end
    local color,text=COLORS.cyan,"?"
    if state=="ready" then color,text=COLORS.green,L("READY")
    elseif state=="warning" then color,text=COLORS.red,L("STOP")
    elseif state=="active" then color,text=COLORS.gold,L("ACTIVE")
    elseif state=="used" then color,text=COLORS.muted,L("USED")
    elseif state=="empty" then color,text=COLORS.muted,L("EMPTY")
    elseif state=="off" then color,text=COLORS.muted,L("INACTIVE")
    elseif state=="charging" and denominator>0 then text="" end
    local number
    if empty then number="—"
    elseif bar.overload then number=tostring(math.floor(value))
    else number=string.format("%d / %s",math.floor(value),denominator>0 and tostring(math.ceil(denominator)) or "?") end
    if card.numberText~=number then card.numberText=number;card.valueLabel:SetText(number) end
    if card.statusText~=text then card.statusText=text;card.statusLabel:SetText(text) end
    -- A reserve tick is an Overload warning threshold, never an activation cost.
    local reserve=bar.overload and overloadConfig and overloadConfig.reserveAlertsEnabled
        and overloadConfig.reserveWarningThreshold or nil
    local markerVisible=not empty and type(reserve)=="number" and denominator>0 and reserve>=0 and reserve<=denominator
    if card.reserveMarkerVisible~=markerVisible then
        card.reserveMarkerVisible=markerVisible;card.reserveMarker:SetHidden(not markerVisible)
    end
    if markerVisible then
        local position=(card.progressWidth or 0)*reserve/denominator
        if card.reserveMarkerPosition~=position then
            card.reserveMarkerPosition=position
            card.reserveMarker:ClearAnchors();card.reserveMarker:SetAnchor(CENTER,card.progressBG,LEFT,position,0)
        end
    end
    -- The active indicator always describes the native hotbar, never READY.
    local active=bar.activeBar==true
    if card.activeBar~=active then
        card.activeBar=active;card.activeArrow:SetHidden(not active);card:SetAlpha(active and 1 or 0.52)
    end
    local texture=not empty and bar.icon and bar.icon~="" and bar.icon or EMPTY_ICON
    if card.iconTexture~=texture then card.iconTexture=texture;card.icon:SetTexture(texture) end
    if card.empty~=empty then card.empty=empty;card.icon:SetAlpha(empty and 0.45 or 1) end
    if card.presentationState~=state then
        card.presentationState=state
        Color(card.statusLabel,color);Color(card.iconBorder,color,state=="ready" and 0.9 or 0.65)
        Color(card.progress,color)
        card.readyGlow:SetColor(0,0,0,0);card.statusLabel:SetAlpha(1)
    end
    self:SetCardProgress(card,bar,progress,state)
end
function ULT:RefreshHUD()
    if not self.window or not self.sv or self.renderingHUD then return end
    self.renderingHUD=true
    self:ApplyVisibility()
    if self.window:IsHidden() then self.hudDirty=true;self.renderingHUD=false;return end
    self.hudDirty=false
    self:ApplyLayout()
    self.renderingHUD=false
end
function ULT:UpdateReadyPulse()
    if not self.window or not self.sv or self.window:IsHidden() then return end
    local t=Now()/1000
    for key,card in pairs(self.window.cards) do
        local bar=self:GetLiveBar(key)
        if self:ShouldTrackBar(key) and bar then
            local state=bar.overload and bar.overloadState or nil
            if state=="warning" or state=="ready" then
                local color=state=="warning" and COLORS.red or COLORS.green
                local wave=(math.sin(t*(state=="warning" and 7 or 4))+1)*0.5
                card.readyGlow:SetColor(color[1],color[2],color[3],0.15+wave*0.65)
                card.iconBorder:SetColor(color[1],color[2],color[3],0.5+wave*0.5)
                card.statusLabel:SetAlpha(0.55+wave*0.45)
            elseif not bar.overload and bar.ready and self.sv.readyFlash then
                local wave=(math.sin(t*2.8)+1)*0.5
                card.readyGlow:SetColor(COLORS.green[1],COLORS.green[2],COLORS.green[3],0.06+wave*0.22)
            else card.readyGlow:SetColor(0,0,0,0);card.statusLabel:SetAlpha(1) end
        end
    end
end
function ULT:ResetPulseVisuals()
    if not self.window or not self.window.cards then return end
    for _,card in pairs(self.window.cards) do
        card.readyGlow:SetColor(0,0,0,0);card.statusLabel:SetAlpha(1)
        card.presentationState=nil
    end
    if self.initialized then self:RefreshHUD() end
end
function ULT:CreateHUD()
    local win=WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTTrackerWindow")
    self.window=win;self.layoutSignature=nil
    win:SetDimensions(self:GetWindowWidth(),CARD_HEIGHT)
    win:SetClampedToScreen(true);win:SetMovable(true);win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH);win:SetDrawLayer(DL_OVERLAY);win:SetDrawLevel(90)
    if ASUI.Settings and ASUI.Settings.ApplyWindowLayer then ASUI.Settings.ApplyWindowLayer(win,true) end
    win.cards={primary=CreateCard(win,"primary"),backup=CreateCard(win,"backup")}
    win.dragSurface=WINDOW_MANAGER:CreateControl("AlphaSquadULTTrackerDragSurface",win,CT_CONTROL)
    win.dragSurface:SetAnchorFill(win);win.dragSurface:SetMouseEnabled(true)
    win.dragSurface:SetHandler("OnMouseDown",function() if ULT.sv and not ULT.sv.locked then win:StartMoving() end end)
    win.dragSurface:SetHandler("OnMouseUp",function()
        if ULT.sv and not ULT.sv.locked then win:StopMovingOrResizing();ULT:SavePosition() end
    end)
    win:SetHandler("OnMoveStop",function() if ULT.sv and not ULT.sv.locked then ULT:SavePosition() end end)
    self:ApplyLayout();self:ApplyPosition();self:ApplyAppearance();self:UpdateLockState();self:ApplyVisibility()
    if ASUI.Layout and ASUI.Layout.Attach then ASUI.Layout.Attach(self) end
    if ASUI.Localization and ASUI.Localization.RegisterCallback then
        ASUI.Localization.RegisterCallback("personalUltimate",function() ULT:RefreshHUD() end)
    end
end
