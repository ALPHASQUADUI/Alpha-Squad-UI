-- Event-driven preparation HUD and shared native ESO control helpers.
local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local Theme = AlphaSquadUI.Theme
local C = Theme.colors
local UI = {}; SC.UI = UI
UI.colors = C

function UI.Text(value)
    return (tostring(value or ""):gsub("|[cC]%x%x%x%x%x%x", ""):gsub("|[rR]", ""):gsub("|", "||"):gsub("[\r]", ""))
end
function UI.Color(control, color)
    control:SetColor(color[1], color[2], color[3], color[4] or 1)
end
function UI.BindColor(control,color)
    if Theme.BindColor then Theme.BindColor(control,color) else UI.Color(control,color) end
end
function UI.Surface(parent,background,kind)
    if Theme.RegisterSurface then Theme.RegisterSurface(parent,background,kind) end
end
function UI.Separator(parent,name,x,y,width)
    local line=WINDOW_MANAGER:CreateControl(name,parent,CT_TEXTURE)
    line:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);line:SetDimensions(width,1)
    UI.BindColor(line,C.border or C.muted)
    return line
end
function UI.Solid(parent, name, color, dynamic)
    local t = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    t:SetAnchorFill(parent)
    if dynamic then UI.Color(t,color or C.panel) else UI.BindColor(t,color or C.panel) end
    return t
end
function UI.Label(parent, name, text, font, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font or "ZoFontGameSmall"); label:SetText(text or "")
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER); UI.BindColor(label, color or C.white)
    return label
end
function UI.Tooltip(control, text)
    if AlphaSquadUI.Tooltips then return AlphaSquadUI.Tooltips.ShowText(control,text) end
    if not InformationTooltip or not InitializeTooltip then return end
    InitializeTooltip(InformationTooltip, control, TOPLEFT, 8, 4, TOPRIGHT)
    SetTooltipText(InformationTooltip, UI.Text(text))
end
function UI.ItemTooltip(control,item,remote)
    if AlphaSquadUI.Tooltips then return AlphaSquadUI.Tooltips.ShowItem(control,item,remote) end
end
function UI.SkillTooltip(control,skill,remote)
    if AlphaSquadUI.Tooltips then return AlphaSquadUI.Tooltips.ShowSkill(control,skill,remote) end
end
function UI.ChampionTooltip(control,star)
    if AlphaSquadUI.Tooltips then return AlphaSquadUI.Tooltips.ShowChampion(control,star) end
end
function UI.ClearTooltip()
    if AlphaSquadUI.Tooltips then return AlphaSquadUI.Tooltips.Hide() end
    if ClearTooltip and InformationTooltip then ClearTooltip(InformationTooltip) end
    if ClearTooltip and ItemTooltip then ClearTooltip(ItemTooltip) end
end
function UI.Hover(control, text)
    control:SetMouseEnabled(true)
    control:SetHandler("OnMouseWheel",function(c,delta) UI.ForwardWheel(c,delta) end)
    local enter=control.GetHandler and control:GetHandler("OnMouseEnter")
    local leave=control.GetHandler and control:GetHandler("OnMouseExit")
    control:SetHandler("OnMouseEnter", function()
        if enter then enter(control) end
        local value = type(text) == "function" and text() or text
        if value and value ~= "" then UI.Tooltip(control, value) end
    end)
    control:SetHandler("OnMouseExit", function()
        if leave then leave(control) end
        UI.ClearTooltip()
    end)
    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(control,{kind="inspect"}) end
end
function UI.SetButtonSelected(button,selected)
    button.selected=selected==true
    local color=button.hovered and (C.hover or C.panelActive) or button.selected and (C.selected or C.panelActive) or C.panel
    UI.BindColor(button.bg,color or C.panel)
end
function UI.Button(parent, name, caption, width, height, action)
    local b = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    b:SetDimensions(width, height or 30); b:SetMouseEnabled(true)
    b:SetHandler("OnMouseWheel",function(c,delta) UI.ForwardWheel(c,delta) end)
    b.bg = UI.Solid(b, name .. "BG", C.panel)
    -- Tiny grid switches keep a simple fill instead of four extra edge textures each.
    if width>=60 then UI.Surface(b,b.bg,"button") end
    b.label = UI.Label(b, name .. "Label", caption, "ZoFontGameBold")
    b.label:SetAnchorFill(b); b.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    b:SetHandler("OnMouseEnter", function() b.hovered=true;UI.SetButtonSelected(b,b.selected) end)
    b:SetHandler("OnMouseExit", function() b.hovered=false;UI.SetButtonSelected(b,b.selected);UI.ClearTooltip() end)
    b:SetHandler("OnMouseUp", function(_, button, inside)
        if button == MOUSE_BUTTON_INDEX_LEFT and inside ~= false and action then action(b) end
    end)
    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then
        AlphaSquadUI.Input.Register(b,{label=caption,activate=action and function() action(b) end})
    end
    return b
end
function UI.Scroll(parent, name)
    local list=WINDOW_MANAGER:CreateControl(name,parent,CT_CONTROL)
    local child,viewport,slider=AlphaSquadUI.Settings.CreateScrollArea(list,name.."Viewport",0,0,100,100,100)
    viewport:ClearAnchors(); viewport:SetAnchor(TOPLEFT,list,TOPLEFT,0,0)
    viewport:SetAnchor(BOTTOMRIGHT,list,BOTTOMRIGHT,-16,0)
    slider:ClearAnchors(); slider:SetAnchor(TOPRIGHT,list,TOPRIGHT,-2,0)
    slider:SetAnchor(BOTTOMRIGHT,list,BOTTOMRIGHT,-2,0)
    list.content,list.viewport,list.rows=child,viewport,{}
    list.scrollRoot=viewport
    return list
end
function UI.FinishScroll(list, height, width)
    list.content:SetDimensions(math.max(1,width), math.max(1,height))
    list.viewport.UpdateBounds()
end
function UI.ForwardWheel(control,delta)
    local parent=control
    for _=1,8 do
        if not parent then return end
        if parent.scrollRoot then
            local scroll=parent.scrollRoot
            scroll.scrollbar:SetValue(math.max(0,math.min(scroll.maximum or 0,(scroll.offset or 0)-delta*40)))
            return
        end
        parent=parent:GetParent()
    end
end
function UI.Window(name, title, close)
    if AlphaSquadUI.Theme.Brand then
        local section=title:match("UI%s+•%s+(.+)$")
        title=AlphaSquadUI.Theme.Brand(section)
    end
    local win = WINDOW_MANAGER:CreateTopLevelWindow(name)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0); win:SetHidden(true)
    win:SetClampedToScreen(true); win:SetDrawTier(DT_HIGH); win:SetDrawLayer(DL_OVERLAY); win:SetDrawLevel(150)
    if AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win) end
    win:SetMouseEnabled(true); win:SetMovable(true)
    win.bg = UI.Solid(win, name .. "BG", C.bg)
    UI.Surface(win,win.bg,"window")
    if not Theme.RegisterSurface then
        local accent = WINDOW_MANAGER:CreateControl(name .. "Accent",win,CT_TEXTURE)
        accent:SetAnchor(TOPLEFT,win,TOPLEFT,0,0); accent:SetAnchor(TOPRIGHT,win,TOPRIGHT,0,0)
        accent:SetHeight(2); UI.BindColor(accent,C.accent or C.orange)
    end
    win.title=UI.Label(win,name .. "Title",title,"ZoFontWinH2",C.orange)
    win.title:SetAnchor(TOPLEFT,win,TOPLEFT,18,12); win.title:SetHeight(32)
    win.title:SetAnchor(TOPRIGHT,win,TOPRIGHT,-106,12)
    win.subtitle=UI.Label(win,name .. "Subtitle","","ZoFontGameSmall",C.muted)
    win.subtitle:SetAnchor(TOPLEFT,win,TOPLEFT,18,46); win.subtitle:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,46)
    win.subtitle:SetHeight(42)
    local drag=WINDOW_MANAGER:CreateControl(name .. "Drag",win,CT_CONTROL)
    drag:SetAnchor(TOPLEFT,win,TOPLEFT,0,0); drag:SetAnchor(TOPRIGHT,win,TOPRIGHT,-100,0)
    drag:SetHeight(44); drag:SetMouseEnabled(true)
    drag:SetHandler("OnMouseDown",function(_,button) if button==MOUSE_BUTTON_INDEX_LEFT then win:StartMoving() end end)
    drag:SetHandler("OnMouseUp",function() win:StopMovingOrResizing() end)
    win.close=UI.Button(win,name .. "Close","CLOSE",78,30,close)
    win.close:SetAnchor(TOPRIGHT,win,TOPRIGHT,-16,14)
    win.footer=UI.Label(win,name .. "Footer","","ZoFontGameSmall",C.muted)
    win.footer:SetAnchor(BOTTOMLEFT,win,BOTTOMLEFT,18,-12); win.footer:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-18,-12)
    win.footer:SetHeight(36)
    return win
end
function UI.FitWindow(win)
    local rootW,rootH=GuiRoot:GetWidth(),GuiRoot:GetHeight()
    local width=math.min(1060,math.max(640,rootW-40))
    local height=math.min(800,math.max(450,rootH-40))
    win:SetDimensions(width,height)
    win:SetScale(math.min(1,(rootW-20)/width,(rootH-20)/height))
    return width,height
end
function UI.RegisterWindow(id,win,close)
    local settings=AlphaSquadUI.Settings
    if settings and settings.RegisterExclusiveWindow then settings.RegisterExclusiveWindow(id,win,close) end
end
function UI.ShowWindow(id,win)
    local settings=AlphaSquadUI.Settings
    if settings and settings.ShowExclusiveWindow then settings.ShowExclusiveWindow(id)
    else
        if settings and settings.mainWindow then settings.mainWindow:SetHidden(true) end
        if SC.matrixWindow and SC.matrixWindow~=win then SC.matrixWindow:SetHidden(true) end
        if SC.inspectorWindow and SC.inspectorWindow~=win then SC.inspectorWindow:SetHidden(true) end
        win:SetHidden(false)
    end
    -- Windows with their own logical layout fit once after binding content.
    -- A temporary larger size can otherwise move a clamped window on opening.
    if not win.hasContentLayout then UI.FitWindow(win) end
    SC:ApplyVisibility()
end
function UI.PlayerSources(player,key)
    local capability=player and player.capabilities and player.capabilities[key]
    local sources={}
    for name,enabled in pairs(capability and capability.sources or {}) do
        if enabled and type(name)=="string" and name~="Shared build" and name~="ASUI peer" then sources[#sources+1]=name end
    end
    table.sort(sources)
    local effect=SC.Catalog.effects[key]
    local heading=(player and player.displayName or "Unknown player") .. "\n" .. (effect and effect.label or "Support source")
    if #sources==0 then return heading .. "\nThis player has shared a capability summary only. Open Builds to request exact skills, sets and Class Masteries." end
    local lines={heading}
    for _,source in ipairs(sources) do
        local detail=SC.Catalog.GetSourceTooltip and SC.Catalog:GetSourceTooltip(key,source)
        lines[#lines+1]=detail or source
    end
    if capability.mainBar or capability.backBar then
        lines[#lines+1]="Set available on: " .. (capability.mainBar and "front bar" or "")
            .. (capability.mainBar and capability.backBar and " + " or "") .. (capability.backBar and "back bar" or "")
    end
    return table.concat(lines,"\n\n")
end
function UI.EffectTooltip(key)
    local catalog=SC.Catalog
    if not catalog then return "Coverage information is unavailable." end
    local text=catalog:GetEffectTooltip(key)
    local visual=catalog.GetEffectVisual and catalog:GetEffectVisual(key)
    if visual and visual.isFallback then
        text=text.."\n\nIcon: native category symbol; an exact effect or item image is unavailable."
    elseif visual and visual.iconKind=="source" and visual.sourceName then
        text=text.."\n\nIcon: "..visual.sourceName..", one of this effect's possible sources."
    end
    return text
end
function UI.Status(row)
    if row.status=="off" or row.optional then return "TRACKING OFF",C.muted end
    if row.status=="covered" then return "COVERED",C.green end
    if row.unverified or row.status=="unknown" then return "UNKNOWN",C.gold end
    return "MISSING",C.red
end

SC.layoutName="Support Coverage"
SC.layoutBounds={minWidth=300,minHeight=210,maxWidth=1000,maxHeight=900}
function SC:GetHUDDimensions()
    local width=self.Clamp(self.sv and self.sv.width or 410,300,680)
    local height=398
    local layout=AlphaSquadUI.Layout
    if layout and layout.GetDimensions then width,height=layout.GetDimensions(self,width,height) end
    return self.Clamp(width,300,1000),self.Clamp(height,210,900)
end
function SC:GetEffectiveScale(width,height)
    local layout=AlphaSquadUI.Layout
    if layout and layout.GetScale then return layout.GetScale(self,width,height) end
    local scale=self.Clamp(self.sv.scale or 100,60,180)/100
    if not width or not height then width,height=self:GetHUDDimensions() end
    return math.min(scale,(GuiRoot:GetWidth()-24)/width,(GuiRoot:GetHeight()-24)/height)
end
function SC:ApplyLayout()
    if not self.window or not self.sv then return end
    self:ApplyAppearance();self:RefreshHUD();self:ClampToScreen(true)
end
function SC:ApplyPosition()
    if not self.window or not self.sv then return end
    self.window:ClearAnchors(); self.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,self.sv.x,self.sv.y)
end
function SC:SavePosition()
    if not self.window or not self.sv then return end
    self.sv.x=math.floor((self.window:GetLeft() or 0)+0.5)
    self.sv.y=math.floor((self.window:GetTop() or 0)+0.5); self.sv.positionSaved=true
end
function SC:ResetPosition()
    self.sv.x,self.sv.y=self:GetDefaultPosition(); self:ApplyPosition(); self:ClampToScreen(true)
end
function SC:ClampToScreen(save)
    if not self.window or not GuiRoot then return end
    self.window:SetClampedToScreen(true)
    if save then self:SavePosition() end
end
function SC:UpdateLockState()
    if not self.window then return end
    self.window:SetMovable(not self.sv.locked)
    self.window.drag:SetMouseEnabled(not self.sv.locked)
end
function SC:ApplyAppearance()
    if not self.window or not self.sv then return end
    local width,height=self:GetHUDDimensions()
    self.layoutWidth,self.layoutHeight=width,height
    self.window:SetDimensions(width,height)
    self.window:SetScale(self:GetEffectiveScale(width,height))
    self.window.bg:SetAlpha(self.Clamp(self.sv.opacity or 94,30,100)/100)
    if self.window.actions then
        local actionWidth=(width-28)/2
        for index,button in ipairs(self.window.actions) do
            button:ClearAnchors();button:SetAnchor(TOPLEFT,self.window,TOPLEFT,12+(index-1)*(actionWidth+4),91)
            button:SetWidth(actionWidth)
        end
    end
    self:UpdateLockState()
end
function SC:ApplyVisibility()
    if not self.window or not self.sv then return end
    local settings=AlphaSquadUI.Settings
    local anyPopup=settings and settings.AnyExclusiveWindowVisible and settings.AnyExclusiveWindowVisible()
    local popup=(self.matrixWindow and not self.matrixWindow:IsHidden()) or (self.inspectorWindow and not self.inspectorWindow:IsHidden())
    local menu=settings and settings.mainWindow and not settings.mainWindow:IsHidden()
    local moving=AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(self)
    local hidden=self.loading==true or not self.sv.enabled or self.inCombat==true
        or (not moving and (not self.sv.visible or (self.sv.hideInMenus and self.uiObscured))) or anyPopup or popup or menu
    self.window:SetHidden(hidden==true)
    if self.SetSafetyUpdateActive then
        local grouped=self.IsGrouped and self:IsGrouped()
        local tracking=self.sv.enabled and (grouped or not hidden or popup or self.settingsPageVisible)==true
        local sharing=self.sv.shareData and self.sv.experimentalSharing and grouped
        self:SetSafetyUpdateActive(not self.loading and not self.inCombat and (tracking or sharing)==true)
    end
end
function SC:SetLayoutPreview(mode)
    self.layoutPreview=mode
    self:RefreshHUD()
end
function SC:GetHUDPresentation()
    local layout=AlphaSquadUI.Layout
    local moving=layout and layout.IsMoving and layout.IsMoving(self)
    local preview=AlphaSquadUI.Preview
    local mode=preview and preview.GetMode and preview.GetMode() or self.layoutPreview or "mixed"
    if not moving or mode=="live" then return self.coverage or {},#(self.roster or {}) end
    if mode=="overload" then mode="mixed" end
    if self.hudPreview and self.hudPreviewMode==mode then return self.hudPreview,12 end
    local catalog=self.Catalog
    local keys=catalog and catalog.GetAllEffectKeys and catalog:GetAllEffectKeys() or {}
    local data={entries={},requiredCount=0,coveredCount=0,profileLabel="Layout preview",preview=true}
    local cycle={"covered","missing","unknown","covered","off"}
    for index=1,math.min(12,#keys) do
        local key=keys[index]
        local status=mode=="ready" and "covered" or mode=="missing" and "missing" or mode=="off" and "off" or cycle[(index-1)%#cycle+1]
        local duplicate=mode=="mixed" and (index-1)%#cycle==3
        local owners={}
        if status=="covered" then
            for owner=1,duplicate and 3 or 1 do owners[owner]={displayName=string.format("@Preview%02d",((index+owner-2)%12)+1)} end
        end
        data.entries[index]={key=key,effect=catalog.effects[key],status=status,owners=owners,
            duplicatePlayers=duplicate and owners or {},optional=status=="off",preview=true}
        if status~="off" then data.requiredCount=data.requiredCount+1 end
        if status=="covered" then data.coveredCount=data.coveredCount+1 end
    end
    data.ready=data.coveredCount==data.requiredCount and data.requiredCount>0
    self.hudPreview,self.hudPreviewMode=data,mode
    return data,12
end
function SC:GetHUDIssues(coverage)
    local rows={}
    coverage=coverage or self.coverage
    for _,row in ipairs(coverage and coverage.entries or {}) do
        local duplicate=#(row.duplicatePlayers or {})>1
        if coverage.preview or not self.sv.problemsOnly or row.status~="covered" or duplicate then rows[#rows+1]=row end
    end
    return rows
end
function SC:RefreshHUD()
    if not self.window or not self.sv then return end
    self:ApplyVisibility(); if self.window:IsHidden() then return end
    local win=self.window
    local coverage,players=self:GetHUDPresentation()
    local rows=self:GetHUDIssues(coverage); local rowHeight=self.Clamp(self.sv.rowHeight or 30,24,48)
    local width,height=self:GetHUDDimensions()
    win:SetDimensions(width,height)
    win.status:SetText(string.format("%d / %d covered",coverage.coveredCount or 0,coverage.requiredCount or 0))
    UI.Color(win.status,coverage.ready and C.green or C.gold)
    win.summary:SetText((coverage.profileLabel or "Group preparation") .. "  •  " .. tostring(players) .. " players")
    win.note:SetText(coverage.preview and "Preview only • sample players and states" or #rows==0 and "No preparation issues to display." or #rows*rowHeight>height-158 and "Scroll for more • Coverage has every source" or "Hover for details • open Coverage for sources")
    for index,data in ipairs(rows) do
        local row=win.list.rows[index]
        if not row then
            local name="AlphaSquadSupportHUDRow" .. index
            row=WINDOW_MANAGER:CreateControl(name,win.list.content,CT_CONTROL)
            row.bg=UI.Solid(row,name .. "BG",C.surface or C.panel)
            row.icon=WINDOW_MANAGER:CreateControl(name.."Icon",row,CT_TEXTURE)
            row.icon:SetAnchor(TOPLEFT,row,TOPLEFT,6,3);row.icon:SetDimensions(22,22)
            row.divider=UI.Separator(row,name.."Divider",0,0,1)
            row.name=UI.Label(row,name .. "Name","","ZoFontGameSmall")
            row.name:SetAnchor(TOPLEFT,row,TOPLEFT,34,0)
            if row.name.SetWrapMode then row.name:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
            row.value=UI.Label(row,name .. "Value","","ZoFontGameSmall")
            row.value:SetAnchor(TOPRIGHT,row,TOPRIGHT,-6,0); row.value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
            UI.Hover(row,function()
                if not row.data then return nil end
                local effect=row.data.effect or {}
                local names={}; for _,player in ipairs(row.data.owners or {}) do names[#names+1]=player.displayName or "Unknown player" end
                local text=(effect.label or "Support coverage").."\n\n"..(effect.description or "Available build source")
                local visual=SC.Catalog and SC.Catalog.GetEffectVisual and SC.Catalog:GetEffectVisual(row.data.key)
                if visual and visual.isFallback then text=text.."\n\nIcon: native category symbol; exact artwork is unavailable."
                elseif visual and visual.iconKind=="source" and visual.sourceName then text=text.."\n\nSource icon: "..visual.sourceName end
                return (row.data.preview and "Layout preview • sample data only\n\n" or "")..text
                    .."\n\nSource carriers: "..(#names>0 and table.concat(names,", ") or "Not verified")
                    .."\n\nOpen Coverage for tracking switches, all possible sources and each player's details."
            end)
            win.list.rows[index]=row
        end
        row.data=data; row:SetHidden(false); row:ClearAnchors()
        row:SetAnchor(TOPLEFT,win.list.content,TOPLEFT,0,(index-1)*rowHeight)
        row:SetDimensions(width-42,rowHeight-2)
        row.name:SetDimensions(width-198,rowHeight-2); row.value:SetDimensions(112,rowHeight-2)
        local iconSize=math.min(22,rowHeight-6)
        row.icon:ClearAnchors();row.icon:SetAnchor(TOPLEFT,row,TOPLEFT,6,2);row.icon:SetDimensions(iconSize,iconSize)
        row.divider:ClearAnchors();row.divider:SetAnchor(BOTTOMLEFT,row,BOTTOMLEFT,0,0);row.divider:SetWidth(width-42)
        local visual=self.Catalog and self.Catalog.GetEffectVisual and self.Catalog:GetEffectVisual(data.key)
        local icon=visual and visual.icon
        row.icon:SetTexture(icon or "");row.icon:SetHidden(type(icon)~="string" or icon=="")
        row.name:SetText(UI.Text(data.effect.label))
        local status,color=UI.Status(data)
        if #(data.duplicatePlayers or {})>1 then status="DUPLICATE " .. #data.duplicatePlayers; color=C.gold end
        row.value:SetText(status); UI.Color(row.value,color)
    end
    for index=#rows+1,#win.list.rows do win.list.rows[index]:SetHidden(true); win.list.rows[index].data=nil end
    UI.FinishScroll(win.list,#rows*rowHeight,width-42)
    self:ApplyAppearance()
end
-- Preparation state is shown inside the HUD; no autonomous popup interrupts play.
function SC:ShowReadyBanner() self:RefreshHUD() end
function SC:HideReadyBanner() end
function SC:ShowPersonalAssignmentBanner() end
function SC:ShowPullSummaryBanner() end

function SC:CreateHUD()
    local win=WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSupportCoverageHUD"); self.window=win
    win:SetDimensions(410,398); win:SetClampedToScreen(true); win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY); win:SetDrawLevel(60); win:SetMouseEnabled(true)
    if AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win,true) end
    win.bg=UI.Solid(win,"AlphaSquadSupportHUDBG",C.bg)
    UI.Surface(win,win.bg,"window")
    win.title=UI.Label(win,"AlphaSquadSupportHUDTitle",(AlphaSquadUI.Theme.Brand and AlphaSquadUI.Theme.Brand() or "Ąlpha Şquad UI"),"ZoFontGameBold",C.orange)
    win.title:SetAnchor(TOPLEFT,win,TOPLEFT,12,8); win.title:SetDimensions(240,24)
    win.status=UI.Label(win,"AlphaSquadSupportHUDStatus","","ZoFontGameBold")
    win.status:SetAnchor(TOPLEFT,win,TOPLEFT,12,36); win.status:SetHeight(24)
    win.summary=UI.Label(win,"AlphaSquadSupportHUDSummary","","ZoFontGameSmall",C.muted)
    win.summary:SetAnchor(TOPLEFT,win,TOPLEFT,12,62); win.summary:SetAnchor(TOPRIGHT,win,TOPRIGHT,-12,62); win.summary:SetHeight(22)
    win.drag=WINDOW_MANAGER:CreateControl("AlphaSquadSupportHUDDrag",win,CT_CONTROL)
    win.drag:SetAnchor(TOPLEFT,win,TOPLEFT,0,0); win.drag:SetAnchor(TOPRIGHT,win,TOPRIGHT,-40,0); win.drag:SetHeight(84)
    win.drag:SetHandler("OnMouseDown",function(_,b) if b==MOUSE_BUTTON_INDEX_LEFT and not SC.sv.locked then win:StartMoving() end end)
    win.drag:SetHandler("OnMouseUp",function() win:StopMovingOrResizing(); SC:SavePosition() end)
    local close=UI.Button(win,"AlphaSquadSupportHUDClose","×",28,24,function() SC:SetVisible(false) end)
    close:SetAnchor(TOPRIGHT,win,TOPRIGHT,-8,8)
    local actions={{"Coverage",function() SC:OpenMatrix() end},{"Builds",function() SC:OpenInspector("BUILD") end}}
    win.actions={}
    for index,data in ipairs(actions) do
        local b=UI.Button(win,"AlphaSquadSupportHUDAction" .. index,data[1],88,28,data[2])
        b:SetAnchor(TOPLEFT,win,TOPLEFT,12+(index-1)*92,91);win.actions[index]=b
    end
    win.list=UI.Scroll(win,"AlphaSquadSupportHUDList")
    win.list:SetAnchor(TOPLEFT,win,TOPLEFT,12,126); win.list:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-8,-30)
    win.note=UI.Label(win,"AlphaSquadSupportHUDNote","","ZoFontGameSmall",C.muted)
    win.note:SetAnchor(BOTTOMLEFT,win,BOTTOMLEFT,12,-5); win.note:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-12,-5); win.note:SetHeight(22)
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.Attach then AlphaSquadUI.Layout.Attach(self) end
    self:ApplyPosition(); self:ApplyAppearance(); self:RefreshHUD()
end


-- Repaint only cached visible presentation. Theme changes never scan or request builds.
if Theme.OnChanged then Theme.OnChanged(function()
    UI.ClearTooltip()
    if SC.window and not SC.window:IsHidden() then SC:RefreshHUD() end
    if SC.RefreshMatrix then SC:RefreshMatrix() end
    if SC.RefreshInspector then SC:RefreshInspector() end
end) end
