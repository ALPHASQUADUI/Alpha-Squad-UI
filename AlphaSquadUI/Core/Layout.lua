-- Shared placement and sizing. Only an active pointer drag owns a frame callback.
AlphaSquadUI=AlphaSquadUI or {}
local ASUI=AlphaSquadUI
local function L(text, ...)
    if ASUI.L then return ASUI.L(text, ...) end
    return select("#", ...)>0 and string.format(text, ...) or text
end
local Layout={active=false,participants={},attachments={}}
local TOOLBAR_WIDTH,TOOLBAR_HEIGHT=620,120
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
local function FitDimensions(module,width,height)
    if module.GetLayoutFitDimensions then
        local fitWidth,fitHeight=module:GetLayoutFitDimensions(width,height)
        return math.max(1,Finite(fitWidth,width)),math.max(1,Finite(fitHeight,height))
    end
    return width,height
end
local function ResizeHeightLimit(module,available,scale)
    if not module.GetLayoutResizeHeightLimit then return available end
    local _,rootH=RootSize()
    return math.min(available,Finite(module:GetLayoutResizeHeightLimit(math.max(1,rootH-20)/scale),available))
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
local function GameplayScene(scene)
    local name=scene and scene.GetName and scene:GetName()
    return name=="hud" or name=="hudui"
end
local function CanStart()
    if Layout.loading or (ASUI.Input and ASUI.Input.loading)
        or (IsUnitInCombat and IsUnitInCombat("player"))
        or (ZO_Dialogs_IsShowingDialog and ZO_Dialogs_IsShowingDialog())
        or (ZO_GenericGamepadDialog_IsShowing and ZO_GenericGamepadDialog_IsShowing()) then return false end
    local hasHUD=false
    for _,module in ipairs(Modules()) do
        if module.loading then return false end
        if Enabled(module) and module.window then hasHUD=true end
    end
    return hasHUD
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
    width,height=FitDimensions(module,width,height)
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
    local nextH=Clamp(height+Finite(dy,0)/scale,minH,math.max(minH,ResizeHeightLimit(module,math.min(Finite(bounds.maxHeight,1080),(rootH-top)/scale),scale)))
    if nextW==width and nextH==height then return false end
    if module.SetLayoutDimensions then module:SetLayoutDimensions(nextW,nextH)
    else module.sv.hudWidth,module.sv.hudHeight=nextW,nextH end
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
    if drag.move then
        drag.changed=drag.module.window:GetLeft()~=drag.left or drag.module.window:GetTop()~=drag.top
    end
    if drag.module.window.StopMovingOrResizing then drag.module.window:StopMovingOrResizing() end
    if drag.changed and drag.module.SavePosition then drag.module:SavePosition() end
    Layout.RefreshToolbar()
end
local function RegisterPointerRelease()
    if EVENT_MANAGER and EVENT_GLOBAL_MOUSE_UP then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Resize",EVENT_GLOBAL_MOUSE_UP,function(_,button)
            if button==MOUSE_BUTTON_INDEX_LEFT then Layout.EndResize() end
        end)
    end
end
function Layout.BeginMove(module,surface)
    if not Layout.IsMoving(module) or not surface or not module.window.StartMoving then return false end
    Layout.EndResize();Layout.Select(module)
    if ASUI.Tooltips then ASUI.Tooltips.Hide() end
    local win=module.window
    Layout.drag={module=module,handle=surface,move=true,left=win:GetLeft(),top=win:GetTop()}
    -- ESO owns translation at every UI scale. Only resize needs pointer samples;
    -- release anywhere and the normal editor cancellation paths stop both kinds.
    win:StartMoving();RegisterPointerRelease();return true
end
function Layout.UpdateResize(mouseX,mouseY)
    local drag=Layout.drag;if not drag then return end
    if not Layout.IsMoving(drag.module) then Layout.EndResize();return end
    if drag.move then return end
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
        local fitWidth,fitHeight=FitDimensions(module,drag.width,drag.height)
        local maximum=math.max(0.001,math.min(1.8,math.max(1,rootW-20)/fitWidth,
            math.max(1,rootH-20)/fitHeight,availableW/drag.width,availableH/drag.height))
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
        height=Clamp(height,minH,math.max(minH,ResizeHeightLimit(module,math.min(Finite(bounds.maxHeight,1080),availableH/drag.scale),drag.scale)))
        if math.abs(width-drag.appliedWidth)>0.000001 or math.abs(height-drag.appliedHeight)>0.000001 then
            if module.SetLayoutDimensions then module:SetLayoutDimensions(width,height)
            else sv.hudWidth,sv.hudHeight=width,height end
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
    if ASUI.Tooltips then ASUI.Tooltips.Hide() end
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
    RegisterPointerRelease()
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
        fill:SetColor(0.62,0.7,0.73,0.8)
        handle:SetHandler("OnMouseDown",function(_,button)
            if button==MOUSE_BUTTON_INDEX_LEFT then Layout.BeginResize(module,horizontal,vertical,handle) end
        end)
        handle:SetHandler("OnMouseUp",function(_,button) if button==MOUSE_BUTTON_INDEX_LEFT then Layout.EndResize() end end)
        handle:SetHandler("OnHide",function() if Layout.drag and Layout.drag.handle==handle then Layout.EndResize() end end)
        handle:SetHandler("OnMouseEnter",function()
            if ASUI.Tooltips then ASUI.Tooltips.ShowText(handle,L(horizontal~=0 and vertical~=0
                and "Resize the whole panel."
                or "Change the panel's width or height.")) end
        end)
        handle:SetHandler("OnMouseExit",function() if ASUI.Tooltips then ASUI.Tooltips.Hide() end end)
        handle:SetHidden(not Layout.IsMoving(module));handles[#handles+1]=handle
    end
    -- Transparent group rows have mouse-enabled tooltips and no visible header.
    -- An editor-only hit surface lets every row move the panel, without replacing
    -- gameplay handlers or putting content above the resize/orientation controls.
    local surface=WINDOW_MANAGER:CreateControl(nil,win,CT_CONTROL)
    surface:SetAnchorFill(win);surface:SetMouseEnabled(true)
    if surface.SetDrawLayer and DL_OVERLAY then surface:SetDrawLayer(DL_OVERLAY) end
    if surface.SetDrawLevel then surface:SetDrawLevel(180) end
    surface:SetHandler("OnMouseDown",function(_,button)
        if button==MOUSE_BUTTON_INDEX_LEFT then Layout.BeginMove(module,surface) end
    end)
    local function EndMove()
        if Layout.drag and Layout.drag.handle==surface then Layout.EndResize() end
    end
    surface:SetHandler("OnMouseUp",function(_,button) if button==MOUSE_BUTTON_INDEX_LEFT then EndMove() end end)
    surface:SetHandler("OnHide",EndMove)
    surface:SetHandler("OnEffectivelyHidden",EndMove)
    surface:SetHidden(not Layout.IsMoving(module));handles.moveSurface=surface
    if module.SetLayoutOrientation then
        local button=WINDOW_MANAGER:CreateControl(nil,win,CT_CONTROL)
        button:SetDimensions(28,28);button:SetMouseEnabled(true)
        if button.SetDrawLayer and DL_OVERLAY then button:SetDrawLayer(DL_OVERLAY) end
        if button.SetDrawLevel then button:SetDrawLevel(225) end
        local background=WINDOW_MANAGER:CreateControl(nil,button,CT_TEXTURE)
        background:SetAnchorFill(button);background:SetColor(0.035,0.04,0.05,0.85)
        button.tiles={}
        for index=1,3 do
            local tile=WINDOW_MANAGER:CreateControl(nil,button,CT_TEXTURE)
            tile:SetDimensions(5,5);tile:SetColor(0.84,0.9,0.88,1);button.tiles[index]=tile
        end
        local function Switch()
            if not Layout.IsMoving(module) then return end
            Layout.Select(module);Layout.CycleOrientation(1)
        end
        button:SetHandler("OnMouseUp",function(_,mouseButton,inside)
            if mouseButton==MOUSE_BUTTON_INDEX_LEFT and inside~=false then Switch() end
        end)
        button:SetHandler("OnMouseEnter",function()
            if ASUI.Tooltips then ASUI.Tooltips.ShowText(button,L(module:GetLayoutOrientation()=="horizontal"
                and "Switch to vertical layout" or "Switch to horizontal layout")) end
        end)
        button:SetHandler("OnMouseExit",function()if ASUI.Tooltips then ASUI.Tooltips.Hide() end end)
        if ASUI.Input then ASUI.Input.Register(button,{window=Layout.toolbar,activate=Switch,label="Change orientation"}) end
        handles.orientation=button
    end
    Layout.attachments[module]=handles
    return handles
end
function Layout.RefreshOrientation(module)
    local handles=Layout.attachments[module]
    local button=handles and handles.orientation
    if not button then return end
    button:SetHidden(not Layout.IsMoving(module))
    if not Layout.IsMoving(module) then return end
    local rootW=RootSize();local win=module.window
    local footprint=34*math.max(0.001,Finite(win.GetScale and win:GetScale(),1))
    button:ClearAnchors()
    if win:GetLeft()+win:GetWidth()+footprint<=rootW then button:SetAnchor(TOPLEFT,win,TOPRIGHT,6,0)
    elseif win:GetLeft()>=footprint then button:SetAnchor(TOPRIGHT,win,TOPLEFT,-6,0)
    else button:SetAnchor(TOPRIGHT,win,TOPRIGHT,-3,3) end
    local vertical=module:GetLayoutOrientation()=="horizontal"
    for index,tile in ipairs(button.tiles) do
        tile:ClearAnchors();tile:SetAnchor(TOPLEFT,button,TOPLEFT,vertical and 11 or 4+(index-1)*7,vertical and 4+(index-1)*7 or 11)
    end
end
function Layout.Refresh()
    for _,module in ipairs(Modules()) do
        RefreshModule(module)
        local handles=Layout.IsMoving(module) and Layout.Attach(module) or Layout.attachments[module]
        for _,handle in ipairs(handles or {}) do handle:SetHidden(not Layout.IsMoving(module)) end
        if handles and handles.moveSurface then handles.moveSurface:SetHidden(not Layout.IsMoving(module)) end
        Layout.RefreshOrientation(module)
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
    Text(toolbar.selection,L(module and (module.layoutName or "HUD Panel") or "No active panel"))
    Text(toolbar.size,module and L("SIZE %.0f%% −",Finite(module.window:GetScale(),1)*100) or L("SIZE −"))
    Text(toolbar.opacity,module and L("BACKGROUND %d%% −",math.floor(Clamp(Finite(module.sv.opacity,92),30,100))) or L("BACKGROUND −"))
    local backgroundEnabled=module and module.layoutBackground~=false
    if toolbar.opacity.SetEnabled then toolbar.opacity:SetEnabled(backgroundEnabled==true) end
    if toolbar.opacityPlus.SetEnabled then toolbar.opacityPlus:SetEnabled(backgroundEnabled==true) end
    toolbar.opacity:SetHidden(backgroundEnabled~=true)
    toolbar.opacityPlus:SetHidden(backgroundEnabled~=true)
    for _,participant in ipairs(Modules()) do Layout.RefreshOrientation(participant) end
    local preview=ASUI.Preview;local mode=preview and preview.GetMode and preview.GetMode() or "mixed"
    local names={mixed="EXAMPLES: MIXED",ready="EXAMPLES: READY",missing="EXAMPLES: MISSING",overload="EXAMPLES: OVERLOAD",live="LIVE DATA"}
    Text(toolbar.preview,L(names[mode] or names.mixed))
    local rootW,rootH=RootSize()
    local format=rootW>=644 and "wide" or rootW>=624 and "compact" or "narrow"
    if toolbar.layoutFormat~=format or toolbar.layoutBackground~=backgroundEnabled then
        toolbar.layoutFormat=format
        toolbar.layoutBackground=backgroundEnabled
        local function PlaceControl(control,x,y,width)
            if not control then return end
            control:ClearAnchors();control:SetAnchor(TOPLEFT,toolbar,TOPLEFT,x,y);control:SetWidth(width)
        end
        local positions
        if format=="wide" then
            toolbar.layoutWidth,toolbar.layoutHeight=TOOLBAR_WIDTH,TOOLBAR_HEIGHT
            positions={selection={14,10,188},preview={210,10,260},done={478,10,128},
                size={14,48,128},sizePlus={146,48,30},opacity={184,48,184},opacityPlus={372,48,30},reset={410,48,112},fit={530,48,76}}
            if not backgroundEnabled then positions.reset={184,48,112};positions.fit={304,48,76} end
        elseif format=="compact" then
            toolbar.layoutWidth,toolbar.layoutHeight=600,158
            positions={selection={14,10,396},done={424,10,162},preview={14,48,218},
                size={244,48,128},sizePlus={376,48,34},reset={430,48,156},opacity={14,86,192},opacityPlus={210,86,34},fit={260,86,70}}
        else
            toolbar.layoutWidth,toolbar.layoutHeight=440,204
            positions={selection={14,10,280},done={306,10,120},preview={14,48,412},
                size={14,86,128},sizePlus={146,86,34},opacity={196,86,192},opacityPlus={392,86,34},reset={14,124,132},fit={162,124,70}}
        end
        toolbar:SetDimensions(toolbar.layoutWidth,toolbar.layoutHeight)
        for key,position in pairs(positions) do PlaceControl(toolbar[key],position[1],position[2],position[3]) end
        PlaceControl(toolbar.inputHint,14,format=="wide" and 88 or format=="compact" and 126 or 164,toolbar.layoutWidth-28)
        toolbar.inputHint:SetHeight(format=="narrow" and 36 or 24)
    end
    local scale=math.max(0.001,math.min(1,math.max(1,rootW-24)/toolbar.layoutWidth,math.max(1,rootH-24)/toolbar.layoutHeight))
    if toolbar.layoutScale~=scale then toolbar:SetScale(scale);toolbar.layoutScale=scale end
end
function Layout.AdjustSelected(field,delta)
    if field~="scale" and field~="opacity" then return end
    delta=Finite(delta,0)
    local module=Layout.selected;if not Layout.IsMoving(module) then return end
    if field=="opacity" and module.layoutBackground==false then return end
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
function Layout.Finish(skipRefresh,restoreOrigin)
    local returnTarget=Layout.returnTarget or (Layout.pending and Layout.pending.returnTarget)
    Layout.pending,Layout.returnTarget=nil,nil
    if not Layout.active then
        if restoreOrigin==true and returnTarget and ASUI.Settings then
            local restore=ASUI.Settings.ReturnFromLayout or ASUI.Settings.RestoreReturnTarget
            if restore then restore(returnTarget) end
        end
        return
    end
    Layout.EndResize();Layout.active=false
    local previous=Layout.participants;Layout.participants={};Layout.selected=nil
    for module in pairs(previous) do
        if module.window and module.window.StopMovingOrResizing then module.window:StopMovingOrResizing() end
        if module.SavePosition then module:SavePosition() end
        if module.sv then module.sv.locked=true end
        for _,handle in ipairs(Layout.attachments[module] or {}) do handle:SetHidden(true) end
        local handles=Layout.attachments[module]
        if handles and handles.moveSurface then handles.moveSurface:SetHidden(true) end
        Layout.RefreshOrientation(module)
    end
    if ASUI.Tooltips then ASUI.Tooltips.Hide() end
    if Layout.toolbar then
        if SCENE_MANAGER and SCENE_MANAGER.HideTopLevel then SCENE_MANAGER:HideTopLevel(Layout.toolbar)
        else Layout.toolbar:SetHidden(true) end
    end
    if skipRefresh~=true then Layout.Refresh() end
    -- The shared navigation bridge restores the originating page and cursor
    -- after ESO releases the editor's native top-level mouse ownership.
    if restoreOrigin==true and returnTarget and ASUI.Settings then
        local restore=ASUI.Settings.ReturnFromLayout or ASUI.Settings.RestoreReturnTarget
        if restore then restore(returnTarget) end
    end
end
-- Only deliberate Done/Back navigation returns to the originating addon page.
-- Scene changes, loading, combat and programmatic hides must never reopen it.
function Layout.Done()
    Layout.Finish(false,true)
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
        label:SetDimensions(width,24);label:SetAnchor(TOPLEFT,win,TOPLEFT,x,y);if ASUI.Localization then ASUI.Localization.Bind(label,text) else label:SetText(text) end
        if label.SetMaxLineCount then label:SetMaxLineCount(2) end
        if label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
        return label
    end
    local function Button(text,x,width,callback,y,help)
        local button=WINDOW_MANAGER:CreateControl(nil,win,CT_BUTTON);button:SetDimensions(width,30)
        button:SetAnchor(TOPLEFT,win,TOPLEFT,x,y or 10);button:SetFont("ZoFontGameBold");if ASUI.Localization then ASUI.Localization.Bind(button,text) else button:SetText(text) end
        button:SetMouseEnabled(true)
        local bg=WINDOW_MANAGER:CreateControl(nil,button,CT_TEXTURE);bg:SetAnchorFill(button)
        if bg.SetDrawLayer and DL_BACKGROUND then bg:SetDrawLayer(DL_BACKGROUND) end
        bg:SetColor(0.055,0.07,0.095,0.98)
        local theme=ASUI.Theme
        if theme and theme.RegisterSurface then theme.RegisterSurface(button,bg,"button") end
        if button.SetNormalFontColor then button:SetNormalFontColor(0.96,0.97,1,1) end
        if button.SetMouseOverFontColor then button:SetMouseOverFontColor(0.8,0.9,0.86,1) end
        local function Paint(role)
            if theme and theme.BindColor then theme.BindColor(bg,role)
            else bg:SetColor(role=="hover" and 0.12 or 0.055,0.07,0.095,0.98) end
        end
        button:SetHandler("OnMouseEnter",function()
            Paint("hover")
            if help and ASUI.Tooltips then ASUI.Tooltips.ShowText(button,L(help)) end
        end)
        button:SetHandler("OnMouseExit",function()Paint("panel");if ASUI.Tooltips then ASUI.Tooltips.Hide() end end)
        button:SetHandler("OnClicked",callback)
        if ASUI.Input and ASUI.Input.Register then ASUI.Input.Register(button,{activate=callback,label=text}) end
        return button
    end
    win.selection=Button("HUD Panel",14,220,function()Layout.CycleSelected(1)end,nil,"Choose the next active panel, or click the panel itself.")
    win.preview=Button("EXAMPLES: MIXED",418,218,function()Layout.CyclePreview(1)end,nil,"Cycle example states. Examples are never shared with the group.")
    win.done=Button("DONE",646,120,Layout.Done,nil,"Save placement and return.")
    win.size=Button("SIZE −",14,128,function()Layout.AdjustSelected("scale",-5)end,48)
    win.sizePlus=Button("+",146,34,function()Layout.AdjustSelected("scale",5)end,48)
    win.opacity=Button("BACKGROUND −",196,192,function()Layout.AdjustSelected("opacity",-5)end,48)
    win.opacityPlus=Button("+",392,34,function()Layout.AdjustSelected("opacity",5)end,48)
    win.reset=Button("RESET PANEL",444,132,Layout.ResetSelected,48,"Restore only this panel's default position, size and background.")
    win.fit=Button("FIT",586,70,function()
        local module=Layout.selected;if Layout.IsMoving(module) then RefreshModule(module);Place(module,module.window:GetLeft(),module.window:GetTop()) end
    end,48,"Keep this panel inside the screen.")
    -- These values are computed from the selected HUD; rebinding their initial
    -- placeholders would overwrite the live values on an equivalent-language switch.
    if ASUI.Localization and ASUI.Localization.Unbind then
        for _,control in ipairs({win.selection,win.size,win.opacity,win.preview}) do ASUI.Localization.Unbind(control) end
    end
    win.inputHint=Label("Drag a panel to move it. Drag a corner to resize. Esc saves.",14,88,752)
    win:SetHandler("OnHide",Layout.Finish)
    if ASUI.Input and ASUI.Input.RegisterWindow then ASUI.Input.RegisterWindow(win,{layout=true,close=Layout.Done,dismiss=Layout.Finish}) end
    if SCENE_MANAGER and SCENE_MANAGER.RegisterTopLevel then SCENE_MANAGER:RegisterTopLevel(win,true) end
    Layout.toolbar=win;Layout.RefreshToolbar();return win
end
local function ActivatePending()
    local pending=Layout.pending
    if not pending then return false end
    if not CanStart() then Layout.Finish();return false end
    Layout.pending=nil;Layout.returnTarget=pending.returnTarget
    Layout.active=true
    for _,module in ipairs(Modules()) do
        if Enabled(module) and module.window then Layout.participants[module]=true;module.sv.locked=false end
    end
    if SCENE_MANAGER and SCENE_MANAGER.ShowTopLevel then SCENE_MANAGER:ShowTopLevel(Layout.toolbar)
    else Layout.toolbar:SetHidden(false) end
    Layout.Refresh();Layout.Select(pending.preferredModule);return true
end
function Layout.Start(preferredModule)
    if Layout.active then Layout.Select(preferredModule);return true end
    if Layout.pending then if type(preferredModule)=="table" then Layout.pending.preferredModule=preferredModule end;return true end
    if not CanStart() then return false end
    Layout.CreateToolbar();local settings=ASUI.Settings
    local returnTarget=settings and settings.CaptureReturnTarget and settings.CaptureReturnTarget() or {id="settings",page="dashboard"}
    if settings and settings.DismissAllWindows then settings.DismissAllWindows()
    else
        for _,entry in pairs(settings and settings.exclusiveWindows or {}) do
            if entry.control and not entry.control:IsHidden() then if entry.close then entry.close() else entry.control:SetHidden(true) end end
        end
        if settings and settings.CloseMain then settings.CloseMain() end
    end
    Layout.pending={returnTarget=returnTarget,preferredModule=type(preferredModule)=="table" and preferredModule or nil}
    -- Native scene transitions are asynchronous. Showing a top-level before
    -- the previous menu finishes hiding lets its scene cleanup close the editor.
    -- One permanent scene callback completes/cancels this request; no polling,
    -- queued CallWhen closures or permanent frame updates are needed.
    local current=SCENE_MANAGER and SCENE_MANAGER.GetCurrentScene and SCENE_MANAGER:GetCurrentScene()
    if not current or (GameplayScene(current) and (not current.GetState or current:GetState()==SCENE_SHOWN)) then
        if SCENE_MANAGER and SCENE_MANAGER.ShowBaseScene then SCENE_MANAGER:ShowBaseScene() end
        if Layout.active then return true end
        -- A minimal compatibility host may not publish scene transitions.
        if not current or not current.GetState then return ActivatePending() end
        current=SCENE_MANAGER:GetCurrentScene()
        if GameplayScene(current) and current:GetState()==SCENE_SHOWN then return ActivatePending() end
        return true
    end
    if SCENE_MANAGER and SCENE_MANAGER.ShowBaseScene then SCENE_MANAGER:ShowBaseScene() end
    return true
end
if EVENT_MANAGER then
    if EVENT_PLAYER_DEACTIVATED then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Loading",EVENT_PLAYER_DEACTIVATED,function()Layout.loading=true;Layout.Finish(true)end) end
    if EVENT_PLAYER_ACTIVATED then EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Activated",EVENT_PLAYER_ACTIVATED,function()Layout.loading=false end) end
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
        if Layout.pending and newState==SCENE_SHOWN and GameplayScene(scene) then
            ActivatePending()
        elseif (Layout.active or Layout.pending) and newState==SCENE_SHOWING and scene and scene.GetName then
            if not GameplayScene(scene) then Layout.Finish() end
        end
    end)
end
if SLASH_COMMANDS then SLASH_COMMANDS["/asmove"]=Layout.Start end

if ASUI.Localization then ASUI.Localization.RegisterCallback("Layout",function()Layout.RefreshToolbar() end) end
