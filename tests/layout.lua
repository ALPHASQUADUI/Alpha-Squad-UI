-- Native placement ownership, proportional sizing and zero idle frame callbacks.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local events,sceneCallbacks,controls={},{},{}
local function Control(parent)
    local control={hidden=true,handlers={},width=320,height=120,scale=1,left=40,top=80,parent=parent}
    function control:SetHidden(hidden)local changed=self.hidden~=hidden;self.hidden=hidden;if changed and hidden and self.handlers.OnHide then self.handlers.OnHide(self)end end
    function control:IsHidden()return self.hidden end
    function control:SetHandler(name,callback)self.handlers[name]=callback end
    function control:GetHandler(name)return self.handlers[name]end
    function control:SetDimensions(w,h)self.width=w;self.height=h end
    function control:SetWidth(w)self.width=w end
    function control:SetHeight(h)self.height=h end
    -- ESO SetDimensions is logical; native getters return scaled dimensions.
    -- See ZO_RadialMenu:PerformLayout and ZO_ScrollContainer_Shared:UpdateScrollBar.
    function control:GetWidth()return self.width*self:GetScale() end
    function control:GetHeight()return self.height*self:GetScale() end
    function control:SetScale(value)self.scale=value end
    function control:GetScale()return self.scale*(self.parent and self.parent:GetScale() or 1) end
    function control:GetLeft()return self.left end
    function control:GetTop()return self.top end
    function control:SetAnchor(point,parent,relative,x,y)if point==TOPLEFT then self.left=x or 0;self.top=y or 0 end end
    function control:SetText(text)self.text=text end
    for _,method in ipairs({'SetClampedToScreen','SetMouseEnabled','SetDrawTier','SetDrawLevel','SetDrawLayer','SetAnchorFill','SetColor','SetFont','StopMovingOrResizing','ClearAnchors'})do control[method]=function()end end
    controls[#controls+1]=control;return control
end
TOPLEFT,TOP,TOPRIGHT,RIGHT,BOTTOMRIGHT,BOTTOM,BOTTOMLEFT,LEFT=1,2,3,4,5,6,7,8
MOUSE_BUTTON_INDEX_LEFT=1
GuiRoot=Control();GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateControl=function(_,_,parent)return Control(parent)end,CreateTopLevelWindow=function()return Control()end}
EVENT_PLAYER_DEACTIVATED,EVENT_PLAYER_COMBAT_STATE,EVENT_GLOBAL_MOUSE_UP,EVENT_SCREEN_RESIZED=1,2,3,4
EVENT_ALL_GUI_SCREENS_RESIZE_STARTED,EVENT_ALL_GUI_SCREENS_RESIZED=6,7
EVENT_PLAYER_ACTIVATED=8
SCENE_SHOWING=5
EVENT_MANAGER={RegisterForEvent=function(_,_,event,callback)events[event]=callback end,
    UnregisterForEvent=function(_,_,event)events[event]=nil end,
    RegisterForUpdate=function()error('Placement must never create a permanent update loop')end}
SLASH_COMMANDS={}
local baseScenes,shown=0,0
SCENE_MANAGER={RegisterCallback=function(_,name,callback)sceneCallbacks[name]=callback end,
    RegisterTopLevel=function(_,control,locks)control.registered=true;control.locks=locks end,
    ShowTopLevel=function(_,control)shown=shown+1;control:SetHidden(false)end,
    HideTopLevel=function(_,control)control:SetHidden(true)end,ShowBaseScene=function()baseScenes=baseScenes+1 end}
local combat,mouseX,mouseY=false,0,0
function IsUnitInCombat()return combat end
function GetUIMousePosition()return mouseX,mouseY end
local function Module(enabled,name)
    local module={sv={enabled=enabled,visible=true,locked=true,scale=100,opacity=92},window=Control(),saves=0,refreshes=0,layoutName=name,
        layoutBounds={minWidth=200,minHeight=80,maxWidth=960,maxHeight=720}}
    function module:SavePosition()self.saves=self.saves+1;self.sv.x=self.window:GetLeft();self.sv.y=self.window:GetTop()end
    function module:ApplyLayout()
        self.refreshes=self.refreshes+1
        local w,h=AlphaSquadUI.Layout.GetDimensions(self,320,120);self.window:SetDimensions(w,h)
        self.window:SetScale(AlphaSquadUI.Layout.GetScale(self))
    end
    function module:UpdateLockState()self.movable=not self.sv.locked end
    function module:ApplyAppearance()self.appliedOpacity=self.sv.opacity end
    function module:ApplyVisibility()
        self.window:SetHidden(not AlphaSquadUI.Layout.IsMoving(self) and self.sv.visible==false)
        self.pulse=not self.window:IsHidden()
    end
    function module:SetFlashUpdate(value)self.pulse=value end
    function module:SetSafetyUpdateActive(value)self.safety=value end
    function module:GetDefaults()return{scale=100,opacity=92,x=40,y=80}end
    return module
end
local overload,ult,group,support=Module(true,'Unused'),Module(true,'Personal Ultimate'),Module(true,'Group Ultimates'),Module(false,'Support Coverage')
overload.sv.addonEnabled=true;ult.Group=group;ult.sv.visible=false
local popup=Control();popup:SetHidden(false);local closes=0
AlphaSquadUI={Modules={Overload=overload,ULTTracker=ult,SupportCoverage=support},Settings={exclusiveWindows={builds={control=popup,close=function()closes=closes+1;popup:SetHidden(true)end}}}}
assert(loadfile('AlphaSquadUI/Core/Layout.lua'))()
local L=AlphaSquadUI.Layout
check(L.ShouldHidePersonalULT==nil,'There is one personal Ultimate target and no Overload window arbitration')
combat=true;check(not L.Start() and shown==0,'Combat blocks placement');combat=false
ult.loading=true;check(not L.Start() and shown==0,'Loading blocks placement');ult.loading=false
check(L.Start() and L.active and baseScenes==1 and shown==1,'Move HUD opens over native gameplay')
check(L.toolbar.registered and L.toolbar.locks,'Native top-level ownership provides Escape dismissal and mouse mode')
check(closes==1 and popup:IsHidden(),'Placement closes previous addon popups')
check(not ult.window:IsHidden() and ult.movable and not ult.pulse and not ult.safety,'Starting Move immediately previews a hidden HUD and stops its animation and safety callbacks')
check(L.IsMoving(ult) and L.IsMoving(group) and not L.IsMoving(overload),'Only personal/group ULT own their respective placement targets')
check(not L.IsMoving(support) and support.sv.locked,'Disabled panels remain inactive')
check(#L.attachments[ult]==8 and #L.attachments[group]==8,'Each active target has exactly eight reusable resize handles')
check(L.Start() and shown==1,'Repeated commands do not duplicate windows')
local handles=L.attachments[ult]
for _,h in ipairs(handles)do check(not h:IsHidden() and not h.handlers.OnUpdate,'Handles are visible without an idle frame callback')end
mouseX,mouseY=0,0
check(L.BeginResize(ult,1,0,handles[4]),'Dragging a side starts sizing')
check(handles[4].handlers.OnUpdate and events[EVENT_GLOBAL_MOUSE_UP],'Only the active drag registers pointer updates and global release')
L.UpdateResize(160,0)
check(ult.sv.hudWidth==480 and ult.sv.hudHeight==120 and ult.sv.scale==100,'Side drag widens the logical panel without changing scale or height')
events[EVENT_GLOBAL_MOUSE_UP](EVENT_GLOBAL_MOUSE_UP,MOUSE_BUTTON_INDEX_LEFT)
check(not L.drag and not handles[4].handlers.OnUpdate and not events[EVENT_GLOBAL_MOUSE_UP],'Releasing outside the handle ends all drag callbacks')
local width,height=ult.sv.hudWidth,ult.sv.hudHeight
mouseX,mouseY=0,0;L.BeginResize(ult,1,1,handles[5]);L.UpdateResize(width*0.5,height*0.5)
check(ult.sv.scale==150 and ult.sv.hudWidth==width and ult.sv.hudHeight==height,'A corner uniformly scales the complete panel and preserves logical aspect ratio')
L.EndResize()
mouseX,mouseY=0,0;L.BeginResize(ult,0,1,handles[6]);L.UpdateResize(0,90)
check(ult.sv.hudHeight==180 and ult.sv.scale==150,'Vertical sizing converts mouse movement through the current scale')
L.EndResize()
local saves=ult.saves
L.toolbar:SetHidden(true)
check(not L.active and ult.saves==saves+1 and group.saves==1,'Escape persists current placements exactly once')
check(ult.sv.locked and group.sv.locked and overload.saves==0,'Finishing locks active HUDs without touching a retired Overload window')
check(ult.window:IsHidden() and not ult.movable and not ult.pulse,'Finishing restores hidden/locked state without waiting for a gameplay event')
for _,h in ipairs(handles)do check(h:IsHidden() and not h.handlers.OnUpdate,'Finishing hides handles and leaves no frame callback')end
L.Finish();check(ult.saves==saves+1,'Repeated dismissal does not resave')
local savedScale=ult.sv.scale
GuiRoot:SetDimensions(400,240)
check(L.GetScale(ult)<savedScale/100 and ult.sv.scale==savedScale,'Small screens fit the panel without overwriting the requested scale')
GuiRoot:SetDimensions(1920,1080)
check(L.GetScale(ult)==savedScale/100,'Returning to a larger screen restores the chosen scale')
GuiRoot:SetDimensions(1920,240);ult.window:SetDimensions(320,300)
check(L.GetScale(ult)<=220/300 and ult.sv.scale==savedScale,'Screen fitting uses rendered height when content is taller than saved geometry')
check(L.GetScale(ult,320,400)<=220/400,'Renderers may explicitly supply their actual dimensions')
GuiRoot:SetDimensions(1920,1080)
ult.sv.hudWidth=0/0;ult.sv.hudHeight=math.huge;ult.sv.scale=0/0
local w,h=L.GetDimensions(ult,320,120)
check(w==320 and h==120 and L.GetScale(ult)==1,'Nonfinite saved geometry cannot reach native controls')
ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale=320,120,100
group.sv.enabled=false;L.Start();check(L.IsMoving(ult) and not L.IsMoving(group),'Group visibility follows its own enabled switch')
L.Select(ult);L.AdjustSelected('opacity',-5);check(ult.sv.opacity==87 and ult.appliedOpacity==87,'Selected-panel opacity is applied immediately without another gameplay refresh')
L.ResetSelected();check(ult.sv.scale==100 and ult.sv.hudWidth==nil and ult.sv.opacity==92,'Reset affects only the selected panel and restores natural dimensions')
mouseX,mouseY=0,0;L.BeginResize(ult,1,1,handles[5])
sceneCallbacks.SceneStateChanged({GetName=function()return 'inventory'end},0,SCENE_SHOWING)
check(not L.active and not L.drag and not handles[5].handlers.OnUpdate,'Opening another scene cancels an active drag')
L.Start();mouseX,mouseY=0,0;L.BeginResize(ult,1,0,handles[4])
events[EVENT_PLAYER_COMBAT_STATE](EVENT_PLAYER_COMBAT_STATE,true)
check(not L.active and not L.drag,'Combat cancels placement and resizing immediately')
L.Start();local refreshes=ult.refreshes
events[EVENT_PLAYER_DEACTIVATED]()
check(not L.active and ult.refreshes==refreshes,'Loading saves placement without rendering dormant modules')
check(not L.Start(),'The editor cannot restart between deactivation and player activation')
events[EVENT_PLAYER_ACTIVATED]()
L.Start();GuiRoot:SetDimensions(640,480);events[EVENT_SCREEN_RESIZED]()
check(L.toolbar.scale<1 and L.toolbar.width*L.toolbar.scale<=616,'Toolbar fits narrow screens proportionally')
L.Finish()
-- A scaled native control must never be interpreted as a larger logical panel.
local function near(a,b)return math.abs(a-b)<0.00001 end
GuiRoot:SetDimensions(1920,1080)
ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale=400,160,150
ult.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,200,180)
check(L.Start(),'A saved enlarged layout reopens for editing')
mouseX,mouseY=0,0
local priorSaves,priorRefreshes=ult.saves,ult.refreshes
L.BeginResize(ult,1,1,handles[5]);L.UpdateResize(0,0)
check(ult.sv.hudWidth==400 and ult.sv.hudHeight==160 and ult.sv.scale==150,
    'Grabbing a 150 percent panel does not bake scaled native dimensions into saved dimensions')
L.EndResize()
check(ult.saves==priorSaves and ult.refreshes==priorRefreshes,'Clicking a handle without moving leaves saved geometry and render work unchanged')
L.BeginResize(ult,1,1,handles[5])
local initialWidth=ult.window:GetWidth()
L.UpdateResize(0.2,0.08)
check(near(ult.sv.scale,150.05) and near(ult.window:GetWidth(),initialWidth+0.2),
    'Subpixel corner movement scales immediately without integer-percent steps')
check(ult.refreshes==priorRefreshes,'Corner scaling uses native parent scaling without rebuilding panel contents')
local lastWidth=ult.window:GetWidth()
for step=2,60 do
    L.UpdateResize(step*0.2,step*0.08)
    check(near(ult.window:GetWidth()-lastWidth,0.2),'Successive pointer samples remain linear and continuous')
    lastWidth=ult.window:GetWidth()
end
L.EndResize()
local oppositeRight=ult.window:GetLeft()+ult.window:GetWidth()
local oppositeBottom=ult.window:GetTop()+ult.window:GetHeight()
L.BeginResize(ult,-1,-1,handles[1]);L.UpdateResize(-40,-16)
check(near(ult.window:GetLeft()+ult.window:GetWidth(),oppositeRight)
    and near(ult.window:GetTop()+ult.window:GetHeight(),oppositeBottom),
    'Dragging the top-left corner anchors the opposite screen edges at non-unit scale')
check(ult.sv.hudWidth==400 and ult.sv.hudHeight==160,'Repeated corner edits retain one stable logical panel size')
L.EndResize()
local scaleNow=ult.window:GetScale()
local leftNow,topNow=ult.window:GetLeft(),ult.window:GetTop()
L.BeginResize(ult,1,0,handles[4]);L.UpdateResize(20*scaleNow,0)
check(near(ult.sv.hudWidth,420) and near(ult.window:GetWidth(),420*scaleNow),
    'An edge edit after repeated scaling converts pointer movement exactly once')
check(near(ult.window:GetLeft(),leftNow) and near(ult.window:GetTop(),topNow),'Right-edge resizing holds the top-left position')
L.EndResize()
L.BeginResize(ult,1,0,handles[4]);L.UpdateResize(10000,0)
local boundedRefreshes=ult.refreshes
L.UpdateResize(11000,0)
check(ult.refreshes==boundedRefreshes,'Dragging beyond a size or screen limit does not rebuild unchanged content')
check(ult.window:GetLeft()+ult.window:GetWidth()<=1920.00001,'Edge expansion remains within the viewport')
L.EndResize()
ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale=400,160,100
ult:ApplyLayout();ult.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,1500,500)
L.BeginResize(ult,1,1,handles[5]);L.UpdateResize(400,160)
check(near(ult.window:GetLeft(),1500) and near(ult.window:GetTop(),500)
    and near(ult.window:GetWidth(),420),'Corner expansion stops at the screen edge without moving the opposite anchor')
L.EndResize()
L.BeginResize(ult,1,0,handles[4])
local requestedWidth,requestedHeight,requestedScale=ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale
events[EVENT_ALL_GUI_SCREENS_RESIZE_STARTED]()
check(L.active and not L.drag and not handles[4].handlers.OnUpdate,
    'Native canvas resize-start stops pointer sampling before UI coordinates change')
GuiRoot:SetDimensions(800,600);events[EVENT_ALL_GUI_SCREENS_RESIZED]()
check(ult.sv.hudWidth==requestedWidth and ult.sv.hudHeight==requestedHeight and ult.sv.scale==requestedScale,
    'Completed custom UI scaling refits the editor without overwriting requested geometry')
GuiRoot:SetDimensions(1920,1080);events[EVENT_ALL_GUI_SCREENS_RESIZED]()
ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale=400,160,180
ult:ApplyLayout()
GuiRoot:SetDimensions(400,240)
for _=1,8 do ult.window:SetScale(L.GetScale(ult)) end
check(near(ult.window:GetScale(),0.95) and ult.sv.scale==180,
    'Repeated screen fitting is stable and leaves the requested scale available for a larger display')
GuiRoot:SetDimensions(1920,1080);ult.window:SetScale(L.GetScale(ult))
check(near(ult.window:GetScale(),1.8),'Restoring the viewport restores the exact requested scale')
ult.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,100,100)
L.Select(ult);L.MoveSelected(5,7)
check(near(ult.window:GetLeft(),105) and near(ult.window:GetTop(),107),'Controller movement uses screen/UI coordinates')
L.ResizeSelected(18,0)
check(near(ult.sv.hudWidth,410) and near(ult.sv.hudHeight,160),'Controller edge resizing divides by the effective scale once')
function ult:GetLayoutOrientation()return self.sv.layoutOrientation or 'horizontal'end
function ult:SetLayoutOrientation(value)self.sv.layoutOrientation=value end
check(L.CycleOrientation(1) and ult.sv.layoutOrientation=='vertical','The shared toolbar changes the selected panel template')
check(L.CycleOrientation(-1) and ult.sv.layoutOrientation=='horizontal','Template selection cycles in both directions')
local previewMode='mixed'
AlphaSquadUI.Preview={GetMode=function()return previewMode end,SetMode=function(value)previewMode=value end}
check(L.CyclePreview(1) and previewMode=='ready','The toolbar advances presentation-only preview states')
check(L.CyclePreview(-1) and previewMode=='mixed','Preview navigation reverses without editing tracking settings')
check(L.CycleSelected(1) and L.selected==ult,'Panel selection excludes disabled panels')
L.Finish()
check(not L.MoveSelected(10,10) and not L.ResizeSelected(10,10) and not L.CyclePreview(1),
    'Controller/editor commands are inert after placement closes')
local inactiveWidth,inactiveHeight,inactiveScale=ult.sv.hudWidth,ult.sv.hudHeight,ult.sv.scale
local inactiveRefreshes,disabledRefreshes=ult.refreshes,support.refreshes
GuiRoot:SetDimensions(640,480);events[EVENT_ALL_GUI_SCREENS_RESIZED]()
check(ult.refreshes==inactiveRefreshes+1 and not L.active and L.toolbar:IsHidden(),
    'Completed native canvas resize also refits normal gameplay HUDs outside the editor')
check(ult.sv.hudWidth==inactiveWidth and ult.sv.hudHeight==inactiveHeight and ult.sv.scale==inactiveScale,
    'Runtime canvas adaptation preserves saved requested dimensions and scale')
check(support.refreshes==disabledRefreshes and handles[4]:IsHidden() and not handles[4].handlers.OnUpdate,
    'Canvas adaptation neither rebuilds disabled modules nor exposes editing handles or idle callbacks')
ult.sv.enabled=false;support.sv.enabled=false
local oldShown,oldScenes=shown,baseScenes
check(not L.Start() and shown==oldShown and baseScenes==oldScenes,'No empty editor opens with every module disabled')
check(type(SLASH_COMMANDS['/asmove'])=='function','One command opens global placement')
print('HUD layout and resizing: '..total..' assertions passed')
