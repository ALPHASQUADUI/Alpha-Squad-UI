-- Shared placement and sizing. Only an active pointer drag owns a frame callback.
AlphaSquadUI=AlphaSquadUI or {}
local ASUI=AlphaSquadUI
local Layout={active=false,participants={},attachments={}}
local TOOLBAR_WIDTH,TOOLBAR_HEIGHT=860,154
ASUI.Layout=Layout
local function Finite(value,fallback)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return fallback end
    return value
end
local function Clamp(value,minimum,maximum) return math.max(minimum,math.min(maximum,value)) end
local function RootSize()
    return math.max(1,Finite(GuiRoot and GuiRoot:GetWidth(),1920)),math.max(1,Finite(GuiRoot and GuiRoot:GetHeight(),1080))
end
local function Modules()
    local modules=ASUI.Modules or {};local ult=modules.ULTTracker;local result={}
    if ult then result[#result+1]=ult;if ult.Group then result[#result+1]=ult.Group end end
    if modules.SupportCoverage then result[#result+1]=modules.SupportCoverage end
    return result
end
local function Enabled(module)
    if not module or not module.sv or module.loading then return false end
    local ult=ASUI.Modules and ASUI.Modules.ULTTracker
    if ult and module==ult.Group then
        return ult.sv and ult.sv.enabled==true and not ult.loading and module.sv.enabled==true
    end
    return module.sv.enabled==true
end
function Layout.IsMoving(module)
    return Layout.active and Layout.participants[module]==true and Enabled(module) or false
end
function Layout.GetDimensions(module,defaultWidth,defaultHeight)
    local bounds=module.layoutBounds or {};local sv=module.sv or {}
    local minW=Clamp(Finite(bounds.minWidth,100),32,4096)
    local minH=Clamp(Finite(bounds.minHeight,40),24,4096)
    local maxW=math.max(minW,Clamp(Finite(bounds.maxWidth,1920),32,4096))
    local maxH=math.max(minH,Clamp(Finite(bounds.maxHeight,1080),24,4096))
    module.layoutDefaultWidth=Finite(defaultWidth,module.layoutDefaultWidth or minW)
    module.layoutDefaultHeight=Finite(defaultHeight,module.layoutDefaultHeight or minH)
    local width=Clamp(Finite(sv.hudWidth,module.layoutDefaultWidth),minW,maxW)
    local height=Clamp(Finite(sv.hudHeight,module.layoutDefaultHeight),minH,maxH)
    return width,height
end
function Layout.GetScale(module,actualWidth,actualHeight)
    local width,height=Layout.GetDimensions(module,module.layoutDefaultWidth,module.layoutDefaultHeight)
    local win=module.window
    -- Native GetWidth/GetHeight are scaled screen dimensions; SetDimensions
    -- and the supplied renderer dimensions are logical. Never fit twice.
    local currentScale=math.max(0.001,Finite(win and win.GetScale and win:GetScale(),1))
    actualWidth=Finite(actualWidth,win and win.GetWidth and Finite(win:GetWidth(),width)/currentScale)
    actualHeight=Finite(actualHeight,win and win.GetHeight and Finite(win:GetHeight(),height)/currentScale)
    if actualWidth and actualWidth>0 then width=actualWidth end
    if actualHeight and actualHeight>0 then height=actualHeight end
    local rootW,rootH=RootSize()
    local requested=Clamp(Finite(module.sv and module.sv.scale,100),60,180)/100
    -- Fitting never overwrites the requested scale. A larger screen restores it.
    return math.max(0.001,math.min(requested,math.max(1,rootW-20)/width,math.max(1,rootH-20)/height))
end
function Layout.GetLogicalDimensions(module)
    local width,height=Layout.GetDimensions(module,module.layoutDefaultWidth,module.layoutDefaultHeight)
    local win=module.window
    if win then
        local scale=math.max(0.001,Finite(win.GetScale and win:GetScale(),1))
        width=math.max(1,Finite(win.GetWidth and win:GetWidth(),width*scale)/scale)
        height=math.max(1,Finite(win.GetHeight and win:GetHeight(),height*scale)/scale)
    end
    return width,height
end
local function RefreshModule(module,geometryOnly)
    if not module or not module.sv then return end
    if not Enabled(module) then
        if module.UpdateLockState then module:UpdateLockState() end
        if module.ApplyVisibility then module:ApplyVisibility() end
        return
    end
    if module.ApplyLayout then module:ApplyLayout()
    elseif module.ApplyVisualSettings then module:ApplyVisualSettings()
    elseif module.RefreshHUD then module:RefreshHUD() end
    -- Geometry helpers differ between modules. Editor transitions must always
    -- update native visibility, appearance and lock state immediately.
    if not geometryOnly then
        if module.ApplyAppearance then module:ApplyAppearance() end
        if module.UpdateLockState then module:UpdateLockState() end
        if module.ApplyVisibility then module:ApplyVisibility() end
    end
    if Layout.IsMoving(module) then
        -- Each module owns its safety policy: Support may keep the grouped
        -- sharing heartbeat while its presentation is being edited.
        if module.SetFlashUpdate then module:SetFlashUpdate(false) end
        if module.SetReadyPulseActive then module:SetReadyPulseActive(false) end
    end
end
local function Place(module,x,y)
    local win=module.window;if not win or not module.sv then return end
    local rootW,rootH=RootSize()
    x=Clamp(Finite(x,0),0,math.max(0,rootW-Finite(win:GetWidth(),1)))
    y=Clamp(Finite(y,0),0,math.max(0,rootH-Finite(win:GetHeight(),1)))
    -- Keep subpixel coordinates throughout a drag; SavePosition rounds only
    -- after release. Rounding every pointer sample produces visible stepping.
    module.sv.x,module.sv.y=x,y
    module.sv.positionSaved=true
    win:ClearAnchors();win:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,module.sv.x,module.sv.y)
end
function Layout.Select(module)
    if Layout.IsMoving(module) then Layout.selected=module;Layout.RefreshToolbar() end
end
function Layout.CycleSelected(direction)
    local choices={};local current=0
    for _,module in ipairs(Modules()) do
        if Layout.IsMoving(module) then
            choices[#choices+1]=module
            if module==Layout.selected then current=#choices end
        end
    end
    if #choices==0 then return false end
    Layout.EndResize()
    local step=Finite(direction,1)<0 and -1 or 1
    Layout.Select(choices[(current-1+step)%#choices+1]);return true
end
function Layout.MoveSelected(dx,dy)
    local module=Layout.selected;if not Layout.IsMoving(module) then return false end
    Layout.EndResize()
    Place(module,module.window:GetLeft()+Finite(dx,0),module.window:GetTop()+Finite(dy,0))
    Layout.RefreshToolbar();return true
end
function Layout.ResizeSelected(dx,dy)
    local module=Layout.selected;if not Layout.IsMoving(module) then return false end
    Layout.EndResize()
    local width,height=Layout.GetLogicalDimensions(module)
    local scale=math.max(0.001,Finite(module.window:GetScale(),1))
    local left,top=module.window:GetLeft(),module.window:GetTop()
    local rootW,rootH=RootSize()
    local bounds=module.layoutBounds or {}
    local minW,minH=Finite(bounds.minWidth,100),Finite(bounds.minHeight,40)
    local nextW=Clamp(width+Finite(dx,0)/scale,minW,math.max(minW,math.min(Finite(bounds.maxWidth,1920),(rootW-left)/scale)))
    local nextH=Clamp(height+Finite(dy,0)/scale,minH,math.max(minH,math.min(Finite(bounds.maxHeight,1080),(rootH-top)/scale)))
    if nextW==width and nextH==height then return false end
    module.sv.hudWidth,module.sv.hudHeight=nextW,nextH
    RefreshModule(module,true);Place(module,left,top);Layout.RefreshToolbar();return true
end
function Layout.CycleOrientation(direction)
    local module=Layout.selected
    if not Layout.IsMoving(module) or not module.SetLayoutOrientation then return false end
    Layout.EndResize()
    local choices=module.GetLayoutOrientations and module:GetLayoutOrientations() or {"horizontal","vertical"}
    local current=module.GetLayoutOrientation and module:GetLayoutOrientation() or "horizontal"
    local index=1;for i,value in ipairs(choices) do if value==current then index=i;break end end
    if #choices==0 then return false end
    local step=Finite(direction,1)<0 and -1 or 1
    local left,top=module.window:GetLeft(),module.window:GetTop()
    module:SetLayoutOrientation(choices[(index-1+step)%#choices+1])
    RefreshModule(module,true);Place(module,left,top);Layout.RefreshToolbar();return true
end
function Layout.CyclePreview(direction)
    local preview=ASUI.Preview
    if not Layout.active or not preview or not preview.SetMode then return false end
    Layout.EndResize()
    local choices={"mixed","ready","missing","overload","live"}
    local current=preview.GetMode and preview.GetMode() or "mixed"
    local index=1;for i,value in ipairs(choices) do if value==current then index=i;break end end
    local step=Finite(direction,1)<0 and -1 or 1
    preview.SetMode(choices[(index-1+step)%#choices+1]);Layout.RefreshToolbar();return true
end
function Layout.EndResize()
    local drag=Layout.drag;if not drag then return end
    Layout.drag=nil
    if drag.handle then drag.handle:SetHandler("OnUpdate",nil) end
    if EVENT_MANAGER and EVENT_GLOBAL_MOUSE_UP then EVENT_MANAGER:UnregisterForEvent("AlphaSquadUI_Layout_Resize",EVENT_GLOBAL_MOUSE_UP) end
    if drag.module.window.StopMovingOrResizing then drag.module.window:StopMovingOrResizing() end
    if drag.changed and drag.module.SavePosition then drag.module:SavePosition() end
    Layout.RefreshToolbar()
end
function Layout.UpdateResize(mouseX,mouseY)
    local drag=Layout.drag;if not drag then return end
    if not Layout.IsMoving(drag.module) then Layout.EndResize();return end
    local x,y=Finite(mouseX),Finite(mouseY)
    if not x or not y then return end
    local dx,dy=x-drag.mouseX,y-drag.mouseY
    if dx==drag.dx and dy==drag.dy then return end
    drag.dx,drag.dy=dx,dy
    local module=drag.module;local sv=module.sv;local changed=false
    if drag.horizontal~=0 and drag.vertical~=0 then
        local distance=drag.width*drag.width+drag.height*drag.height
        local delta=(drag.horizontal*dx*drag.width+drag.vertical*dy*drag.height)/distance
        local rootW,rootH=RootSize()
        local availableW=drag.horizontal<0 and drag.right or rootW-drag.left
        local availableH=drag.vertical<0 and drag.bottom or rootH-drag.top
        local maximum=math.max(0.001,math.min(1.8,math.max(1,rootW-20)/drag.width,
            math.max(1,rootH-20)/drag.height,availableW/drag.width,availableH/drag.height))
        local requested=Clamp(drag.scale+delta,math.min(0.6,maximum),maximum)
        if math.abs(requested-Finite(module.window:GetScale(),drag.scale))>0.000001 then
            sv.scale=requested*100
            -- Corners only change the native parent scale. Children, square
            -- icons and fonts follow in the same frame without rebuilding rows.
            module.window:SetScale(requested);changed=true
        end
    else
        local bounds=module.layoutBounds or {}
        local width=drag.horizontal~=0 and drag.width+drag.horizontal*dx/drag.scale or drag.width
        local height=drag.vertical~=0 and drag.height+drag.vertical*dy/drag.scale or drag.height
        local rootW,rootH=RootSize()
        -- The opposite edge stays fixed until it meets the screen boundary.
        local availableW=drag.horizontal<0 and drag.right or rootW-drag.left
        local availableH=drag.vertical<0 and drag.bottom or rootH-drag.top
        local minW=math.max(32,Finite(bounds.minWidth,100))
        local minH=math.max(24,Finite(bounds.minHeight,40))
        width=Clamp(width,minW,math.max(minW,math.min(Finite(bounds.maxWidth,1920),availableW/drag.scale)))
        height=Clamp(height,minH,math.max(minH,math.min(Finite(bounds.maxHeight,1080),availableH/drag.scale)))
        if math.abs(width-drag.appliedWidth)>0.000001 or math.abs(height-drag.appliedHeight)>0.000001 then
            sv.hudWidth,sv.hudHeight=width,height
            drag.appliedWidth,drag.appliedHeight=width,height
            RefreshModule(module,true);changed=true
        end
    end
    if not changed then return end
    drag.changed=true
    local left=drag.horizontal<0 and drag.right-module.window:GetWidth() or drag.left
    local top=drag.vertical<0 and drag.bottom-module.window:GetHeight() or drag.top
    Place(module,left,top)
    Layout.RefreshToolbar()
end
function Layout.BeginResize(module,horizontal,vertical,handle)
    if not Layout.IsMoving(module) or not GetUIMousePosition or not handle then return false end
    Layout.EndResize();Layout.Select(module)
    local x,y=GetUIMousePosition();x,y=Finite(x),Finite(y)
    if not x or not y then return false end
    local win=module.window;local width,height=Layout.GetLogicalDimensions(module)
    if win.StopMovingOrResizing then win:StopMovingOrResizing() end
    Layout.drag={module=module,handle=handle,horizontal=horizontal,vertical=vertical,
        mouseX=x,mouseY=y,width=width,height=height,appliedWidth=width,appliedHeight=height,dx=0,dy=0,
        left=Finite(win:GetLeft(),0),top=Finite(win:GetTop(),0),
        right=Finite(win:GetLeft(),0)+Finite(win:GetWidth(),width),bottom=Finite(win:GetTop(),0)+Finite(win:GetHeight(),height),
        scale=Finite(win:GetScale(),Layout.GetScale(module))}
    handle:SetHandler("OnUpdate",function()
        local currentX,currentY=GetUIMousePosition();Layout.UpdateResize(currentX,currentY)
    end)
    if EVENT_MANAGER and EVENT_GLOBAL_MOUSE_UP then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Resize",EVENT_GLOBAL_MOUSE_UP,function(_,button)
            if button==MOUSE_BUTTON_INDEX_LEFT then Layout.EndResize() end
        end)
    end
    return true
end
local handleSpecs={
    {"TOPLEFT",-1,-1},{"TOP",0,-1},{"TOPRIGHT",1,-1},{"RIGHT",1,0},
    {"BOTTOMRIGHT",1,1},{"BOTTOM",0,1},{"BOTTOMLEFT",-1,1},{"LEFT",-1,0},
}
function Layout.Attach(module)
    if not module or not module.window then return end
    if Layout.attachments[module] then return Layout.attachments[module] end
    local handles={};local win=module.window
    for _,spec in ipairs(handleSpecs) do
        local point=rawget(_G,spec[1]);local horizontal,vertical=spec[2],spec[3]
        local handle=WINDOW_MANAGER:CreateControl(nil,win,CT_CONTROL)
        handle:SetDimensions(horizontal==0 and 36 or 12,vertical==0 and 36 or 12)
        handle:SetAnchor(point,win,point,0,0);handle:SetMouseEnabled(true)
        if handle.SetDrawLayer and DL_OVERLAY then handle:SetDrawLayer(DL_OVERLAY) end
        if handle.SetDrawLevel then handle:SetDrawLevel(horizontal~=0 and vertical~=0 and 220 or 200) end
        local fill=WINDOW_MANAGER:CreateControl(nil,handle,CT_TEXTURE);fill:SetAnchorFill(handle)
        fill:SetColor(1,0.55,0.12,0.92)
        if ASUI.Theme and ASUI.Theme.BindColor then ASUI.Theme.BindColor(fill,"accent") end
        handle:SetHandler("OnMouseDown",function(_,button)
            if button==MOUSE_BUTTON_INDEX_LEFT then Layout.BeginResize(module,horizontal,vertical,handle) end
        end)
        handle:SetHandler("OnMouseUp",function(_,button) if button==MOUSE_BUTTON_INDEX_LEFT then Layout.EndResize() end end)
        handle:SetHandler("OnHide",function() if Layout.drag and Layout.drag.handle==handle then Layout.EndResize() end end)
        handle:SetHandler("OnMouseEnter",function()
            if ASUI.Tooltips then ASUI.Tooltips.ShowText(handle,horizontal~=0 and vertical~=0
                and "Drag this corner to scale the entire panel. Icons keep their proportions."
                or "Drag this edge to change the panel layout. Icons stay square.") end
        end)
        handle:SetHandler("OnMouseExit",function() if ASUI.Tooltips then ASUI.Tooltips.Hide() end end)
        handle:SetHidden(not Layout.IsMoving(module));handles[#handles+1]=handle
    end
    local surface=win.dragSurface or win.drag or win
    if surface.GetHandler then
        local previous=surface:GetHandler("OnMouseDown")
        surface:SetHandler("OnMouseDown",function(control,...)
            Layout.Select(module);if previous then return previous(control,...) end
        end)
    end
    Layout.attachments[module]=handles
    return handles
end
function Layout.Refresh()
    for _,module in ipairs(Modules()) do
        RefreshModule(module)
        local handles=Layout.IsMoving(module) and Layout.Attach(module) or Layout.attachments[module]
        for _,handle in ipairs(handles or {}) do handle:SetHidden(not Layout.IsMoving(module)) end
    end
    Layout.RefreshToolbar()
end
function Layout.RefreshToolbar()
    local toolbar=Layout.toolbar;if not toolbar then return end
    if not Layout.IsMoving(Layout.selected) then
        Layout.selected=nil
        for _,module in ipairs(Modules()) do if Layout.IsMoving(module) then Layout.selected=module;break end end
    end
    local module=Layout.selected
    local function Text(control,value)
        if control and control.layoutText~=value then control:SetText(value);control.layoutText=value end
    end
    Text(toolbar.selection,module and (module.layoutName or "HUD Panel") or "No active panel")
    local width,height=0,0
    if module then width,height=Layout.GetLogicalDimensions(module) end
    Text(toolbar.values,module and string.format("%.1f%% scale   •   %d%% background   •   %.0f × %.0f",
        Finite(module.window:GetScale(),1)*100,math.floor(Clamp(Finite(module.sv.opacity,92),30,100)),width,height) or "")
    local orientation=module and module.GetLayoutOrientation and module:GetLayoutOrientation()
    Text(toolbar.orientation,orientation and (orientation=="vertical" and "VERTICAL" or "HORIZONTAL") or "FIXED LAYOUT")
    if toolbar.orientation and toolbar.orientation.SetEnabled then toolbar.orientation:SetEnabled(orientation~=nil) end
    local preview=ASUI.Preview;local mode=preview and preview.GetMode and preview.GetMode() or "mixed"
    Text(toolbar.preview,"PREVIEW: "..string.upper(mode))
    local rootW,rootH=RootSize()
    local scale=math.max(0.001,math.min(1,math.max(1,rootW-24)/TOOLBAR_WIDTH,math.max(1,rootH-24)/TOOLBAR_HEIGHT))
    if toolbar.layoutScale~=scale then toolbar:SetScale(scale);toolbar.layoutScale=scale end
end
function Layout.AdjustSelected(field,delta)
    if field~="scale" and field~="opacity" then return end
    delta=Finite(delta,0)
    local module=Layout.selected;if not Layout.IsMoving(module) then return end
    local minimum,maximum,default=field=="scale" and 60 or 30,field=="scale" and 180 or 100,field=="scale" and 100 or 92
    Layout.EndResize()
    local value=Clamp(Finite(module.sv[field],default)+delta,minimum,maximum)
    if value==module.sv[field] then return end
    module.sv[field]=value
    local left,top=module.window:GetLeft(),module.window:GetTop()
    if field=="scale" then
        local width,height=Layout.GetLogicalDimensions(module)
        module.window:SetScale(Layout.GetScale(module,width,height))
    elseif module.ApplyAppearance then module:ApplyAppearance()
    else RefreshModule(module) end
    Place(module,left,top);Layout.RefreshToolbar()
end
function Layout.ResetSelected()
    local module=Layout.selected;if not Layout.IsMoving(module) then return end
    local defaults=module.GetDefaults and module:GetDefaults() or {}
    module.sv.hudWidth,module.sv.hudHeight=defaults.hudWidth,defaults.hudHeight
    module.sv.scale,module.sv.opacity=defaults.scale or 100,defaults.opacity or 92
    if defaults.rowHeight then module.sv.rowHeight=defaults.rowHeight end
    RefreshModule(module)
    local x,y=defaults.x,defaults.y
    if (x==nil or y==nil) and module.GetDefaultPosition then x,y=module:GetDefaultPosition() end
    Place(module,x,y);Layout.RefreshToolbar()
end
function Layout.Finish(skipRefresh)
    if not Layout.active then return end
    Layout.EndResize();Layout.active=false
    local previous=Layout.participants;Layout.participants={};Layout.selected=nil
    for module in pairs(previous) do
        if module.window and module.window.StopMovingOrResizing then module.window:StopMovingOrResizing() end
        if module.SavePosition then module:SavePosition() end
        if module.sv then module.sv.locked=true end
        for _,handle in ipairs(Layout.attachments[module] or {}) do handle:SetHidden(true) end
    end
    if ASUI.Tooltips then ASUI.Tooltips.Hide() end
    if Layout.toolbar then
        if SCENE_MANAGER and SCENE_MANAGER.HideTopLevel then SCENE_MANAGER:HideTopLevel(Layout.toolbar)
        else Layout.toolbar:SetHidden(true) end
    end
    if skipRefresh~=true then Layout.Refresh() end
end
function Layout.CreateToolbar()
    if Layout.toolbar then return Layout.toolbar end
    local win=WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadUILayoutToolbar")
    win:SetDimensions(TOOLBAR_WIDTH,TOOLBAR_HEIGHT);win:SetAnchor(TOP,GuiRoot,TOP,0,12)
    win:SetClampedToScreen(true);win:SetHidden(true);win:SetMouseEnabled(true)
    if ASUI.Settings and ASUI.Settings.ApplyWindowLayer then ASUI.Settings.ApplyWindowLayer(win,false) end
    local background=WINDOW_MANAGER:CreateControl(nil,win,CT_TEXTURE);background:SetAnchorFill(win);background:SetColor(0.025,0.03,0.04,0.97)
    if ASUI.Theme and ASUI.Theme.RegisterSurface then ASUI.Theme.RegisterSurface(win,background,"window") end
    local function Label(text,x,y,width)
        local label=WINDOW_MANAGER:CreateControl(nil,win,CT_LABEL);label:SetFont("ZoFontGameSmall")
        label:SetDimensions(width,24);label:SetAnchor(TOPLEFT,win,TOPLEFT,x,y);label:SetText(text);return label
    end
    Label("MOVE HUD  •  Drag panels to move. Drag edges to reshape. Drag corners to scale.",14,8,730)
    local function Button(text,x,width,callback,y)
        local button=WINDOW_MANAGER:CreateControl(nil,win,CT_BUTTON);button:SetDimensions(width,30)
        button:SetAnchor(TOPLEFT,win,TOPLEFT,x,y or 38);button:SetFont("ZoFontGameBold");button:SetText(text)
        button:SetMouseEnabled(true)
        local bg=WINDOW_MANAGER:CreateControl(nil,button,CT_TEXTURE);bg:SetAnchorFill(button)
        if bg.SetDrawLayer and DL_BACKGROUND then bg:SetDrawLayer(DL_BACKGROUND) end
        bg:SetColor(0.055,0.07,0.095,0.98)
        local theme=ASUI.Theme
        if theme and theme.RegisterSurface then theme.RegisterSurface(button,bg,"button") end
        if button.SetNormalFontColor then button:SetNormalFontColor(0.96,0.97,1,1) end
        if button.SetMouseOverFontColor then button:SetMouseOverFontColor(1,0.68,0.3,1) end
        local function Paint(role)
            if theme and theme.BindColor then theme.BindColor(bg,role)
            else bg:SetColor(role=="hover" and 0.12 or 0.055,0.07,0.095,0.98) end
        end
        button:SetHandler("OnMouseEnter",function()Paint("hover")end)
        button:SetHandler("OnMouseExit",function()Paint("panel")end)
        button:SetHandler("OnClicked",callback)
        if ASUI.Input and ASUI.Input.Register then ASUI.Input.Register(button,{activate=callback,label=text}) end
        return button
    end
    win.selection=Button("HUD Panel",14,220,function()Layout.CycleSelected(1)end)
    Button("SCALE −",244,90,function()Layout.AdjustSelected("scale",-5)end)
    Button("+",336,28,function()Layout.AdjustSelected("scale",5)end)
    Button("OPACITY −",378,114,function()Layout.AdjustSelected("opacity",-5)end)
    Button("+",494,28,function()Layout.AdjustSelected("opacity",5)end)
    Button("RESET PANEL",540,132,Layout.ResetSelected)
    Button("FIT",684,58,function()
        local module=Layout.selected;if Layout.IsMoving(module) then RefreshModule(module);Place(module,module.window:GetLeft(),module.window:GetTop()) end
    end)
    Button("DONE",754,92,Layout.Finish)
    win.orientation=Button("HORIZONTAL",14,170,function()Layout.CycleOrientation(1)end,74)
    win.preview=Button("PREVIEW: MIXED",194,216,function()Layout.CyclePreview(1)end,74)
    Label("Corners scale. Edges reshape. Esc / Back saves.",420,78,430)
    win.values=Label("",14,106,830)
    win.inputHint=Label("",14,130,830)
    win:SetHandler("OnHide",Layout.Finish)
    if ASUI.Input and ASUI.Input.RegisterWindow then ASUI.Input.RegisterWindow(win,{layout=true,close=Layout.Finish}) end
    if SCENE_MANAGER and SCENE_MANAGER.RegisterTopLevel then SCENE_MANAGER:RegisterTopLevel(win,true) end
    Layout.toolbar=win;Layout.RefreshToolbar();return win
end
function Layout.Start()
    if Layout.active then return true end
    if IsUnitInCombat and IsUnitInCombat("player") then return false end
    local hasHUD=false
    for _,module in ipairs(Modules()) do
        if module.loading then return false end
        if Enabled(module) and module.window then hasHUD=true end
    end
    if not hasHUD then return false end
    local toolbar=Layout.CreateToolbar();local settings=ASUI.Settings
    for _,entry in pairs(settings and settings.exclusiveWindows or {}) do
        if entry.control and not entry.control:IsHidden() then if entry.close then entry.close() else entry.control:SetHidden(true) end end
    end
    if settings and settings.CloseMain then settings.CloseMain() end
    if SCENE_MANAGER and SCENE_MANAGER.ShowBaseScene then SCENE_MANAGER:ShowBaseScene() end
    Layout.active=true
    for _,module in ipairs(Modules()) do
        if Enabled(module) and module.window then Layout.participants[module]=true;module.sv.locked=false end
    end
    if SCENE_MANAGER and SCENE_MANAGER.ShowTopLevel then SCENE_MANAGER:ShowTopLevel(toolbar) else toolbar:SetHidden(false) end
    Layout.Refresh();return true
end
if EVENT_MANAGER then
    if EVENT_PLAYER_DEACTIVATED then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Loading",EVENT_PLAYER_DEACTIVATED,function()Layout.Finish(true)end) end
    if EVENT_PLAYER_COMBAT_STATE then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Combat",EVENT_PLAYER_COMBAT_STATE,function(_,combat)if combat then Layout.Finish()end end) end
    if EVENT_SCREEN_RESIZED then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Screen",EVENT_SCREEN_RESIZED,function()if Layout.active then Layout.EndResize();Layout.Refresh() end end) end
    -- Custom UI scale may apply after its setting notification. Observe the
    -- completed native canvas resize, as ESO's own tree layouts do.
    if EVENT_ALL_GUI_SCREENS_RESIZE_STARTED then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_CanvasStart",EVENT_ALL_GUI_SCREENS_RESIZE_STARTED,Layout.EndResize)
    end
    if EVENT_ALL_GUI_SCREENS_RESIZED then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_CanvasReady",EVENT_ALL_GUI_SCREENS_RESIZED,function()
            Layout.EndResize();Layout.Refresh()
        end)
    end
end
if SCENE_MANAGER and SCENE_MANAGER.RegisterCallback then
    SCENE_MANAGER:RegisterCallback("SceneStateChanged",function(scene,_,newState)
        if Layout.active and newState==SCENE_SHOWING and scene and scene.GetName then
            local name=scene:GetName();if name~="hud" and name~="hudui" then Layout.Finish() end
        end
    end)
end
if SLASH_COMMANDS then SLASH_COMMANDS["/asmove"]=Layout.Start end
