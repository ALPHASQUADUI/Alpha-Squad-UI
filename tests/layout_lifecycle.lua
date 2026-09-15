-- Exercise Layout and Input together with asynchronous native scene transitions.
-- Native references: zo_scenemanager_base.lua and ingamescenemanager.lua.
local assertions=0
local function check(value,message)assertions=assertions+1;assert(value,message)end
for index,name in ipairs({"TOPLEFT","TOP","TOPRIGHT","RIGHT","BOTTOMRIGHT","BOTTOM","BOTTOMLEFT","LEFT",
    "CT_CONTROL","CT_TEXTURE","CT_LABEL","CT_BUTTON","DL_OVERLAY","DL_BACKGROUND","MOUSE_BUTTON_INDEX_LEFT",
    "SCENE_HIDING","SCENE_HIDDEN","SCENE_SHOWING","SCENE_SHOWN","EVENT_PLAYER_DEACTIVATED",
    "EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_COMBAT_STATE"})do _G[name]=index end
local function Control(parent)
    local c={parent=parent,hidden=false,handlers={},width=300,height=116,scale=1,x=30,y=50}
    function c:GetParent()return self.parent end
    function c:SetParent(value)self.parent=value end
    function c:IsHidden()return self.hidden end
    function c:IsControlHidden()return self.hidden or (self.parent and self.parent:IsControlHidden()) or false end
    function c:GetHandler(name)return self.handlers[name]end
    function c:SetHandler(name,callback)self.handlers[name]=callback end
    function c:SetHidden(value)
        if self.hidden==value then return end
        self.hidden=value
        local handler=self.handlers[value and "OnHide" or "OnShow"];if handler then handler(self)end
        handler=self.handlers[value and "OnEffectivelyHidden" or "OnEffectivelyShown"];if handler then handler(self)end
    end
    function c:SetDimensions(w,h)self.width,self.height=w,h end
    function c:SetWidth(value)self.width=value end
    function c:SetHeight(value)self.height=value end
    function c:GetScale()return self.scale*(self.parent and self.parent:GetScale() or 1)end
    function c:SetScale(value)self.scale=value end
    function c:GetWidth()return self.width*self:GetScale()end
    function c:GetHeight()return self.height*self:GetScale()end
    function c:GetLeft()return self.x end
    function c:GetTop()return self.y end
    function c:SetText(value)self.text=value end
    function c:SetAnchor(point,_,_,x,y)if point==TOPLEFT then self.x,self.y=x or 0,y or 0 end end
    for _,name in ipairs({"SetClampedToScreen","SetMouseEnabled","SetDrawTier","SetDrawLayer","SetDrawLevel",
        "SetAnchorFill","SetColor","SetFont","StopMovingOrResizing","ClearAnchors"})do c[name]=function()end end
    return c
end
GuiRoot=Control();GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateTopLevelWindow=function()return Control()end,CreateControl=function(_,_,parent)return Control(parent)end}
local sceneCallbacks,events={},{}
EVENT_MANAGER={RegisterForEvent=function(_,name,event,callback)events[event]=events[event] or {};events[event][name]=callback end,
    UnregisterForEvent=function(_,name,event)if events[event]then events[event][name]=nil end end,
    RegisterForUpdate=function()error("Editor entry must not poll")end}
local function Event(event,...)
    for _,callback in pairs(events[event] or {})do callback(event,...)end
end
local function Scene(name)return{name=name,state=SCENE_SHOWN,GetName=function(self)return self.name end,GetState=function(self)return self.state end}end
local hud,hudui,menu,inventory=Scene("hud"),Scene("hudui"),Scene("gameMenuInGame"),Scene("inventory")
local current,base,nextScene=menu,hud,nil
local registered,topCount,shownCount,uiMode={ },0,0,false
local function State(scene,state)
    local old=scene.state;scene.state=state
    for _,callback in ipairs(sceneCallbacks)do callback(scene,old,state)end
end
local function Queue(scene)
    if current==scene and current.state==SCENE_SHOWN then return end
    nextScene=scene
    if current.state~=SCENE_HIDING then State(current,SCENE_HIDING)end
end
local function Advance()
    local target=nextScene;if not target then return end
    nextScene=nil;State(current,SCENE_HIDDEN);current=target
    State(current,SCENE_SHOWING);State(current,SCENE_SHOWN)
end
SCENE_MANAGER={
    RegisterCallback=function(_,_,callback)sceneCallbacks[#sceneCallbacks+1]=callback end,
    GetCurrentScene=function()return current end,GetBaseScene=function()return base end,
    ShowBaseScene=function()Queue(base)end,
    RegisterTopLevel=function(_,control,locks)registered[control]=true;control.locksUIMode=locks end,
    ShowTopLevel=function(_,control)
        if registered[control] and control:IsControlHidden()then
            control:SetHidden(false);topCount=topCount+1;shownCount=shownCount+1
            if not uiMode then uiMode=true;base=hudui;Queue(base)end
        end
    end,
    HideTopLevel=function(_,control)
        if registered[control] and not control:IsControlHidden()then
            control:SetHidden(true);topCount=topCount-1
            if topCount==0 and uiMode then uiMode=false;base=hud;Queue(base)end
        end
    end,
}
local layers=0
function PushActionLayerByName()layers=layers+1 end
function RemoveActionLayerByName()layers=layers-1 end
local combat,dialog=false,false
function IsUnitInCombat()return combat end
function ZO_Dialogs_IsShowingDialog()return dialog end
local restores,dismisses,captures=0,0,0
local origin=Control(GuiRoot)
local module={window=Control(),sv={enabled=true,locked=true,scale=100,opacity=92},saves=0,layoutName="Personal Ultimate"}
local disabled={window=Control(),sv={enabled=false,locked=true},saves=0}
AlphaSquadUI={Modules={ULTTracker=module,SupportCoverage=disabled},Settings={}}
local ASUI=AlphaSquadUI
function module:ApplyLayout()self.window:SetDimensions(300,116)end
function module:ApplyVisibility()self.window:SetHidden(not ASUI.Layout.IsMoving(self))end
function module:SavePosition()self.saves=self.saves+1 end
ASUI.Settings.CaptureReturnTarget=function()
    captures=captures+1
    if not origin:IsHidden()then return{id="settings",page="ulttracker"}end
end
ASUI.Settings.DismissAllWindows=function()
    dismisses=dismisses+1
    origin:SetHidden(true)
end
ASUI.Settings.RestoreReturnTarget=function(target)
    check(target.id=="settings" and target.page=="ulttracker","Done retains the originating Alpha page")
    restores=restores+1;origin:SetHidden(false)
    -- Settings uses native fragments/raw windows rather than top-level counters.
    -- Its return bridge restores cursor mode after the editor top-level closes.
    uiMode=true;base=hudui
end
assert(loadfile("AlphaSquadUI/Core/Layout.lua"))()
assert(loadfile("AlphaSquadUI/Core/Input.lua"))()
local L,I=ASUI.Layout,ASUI.Input
I.RegisterWindow(origin,{close=function()origin:SetHidden(true)end,dismiss=function()origin:SetHidden(true)end})
I.Initialize()
check(I.activeWindow==origin and layers==1,"Native settings initially owns addon navigation")
check(L.Start() and L.pending and not L.active,"Clicking Move HUD queues entry until the previous native menu closes")
check(L.toolbar:IsHidden() and module.sv.locked and not I.activeWindow,"Pending entry neither unlocks panels nor captures input")
check(L.Start() and captures==1 and dismisses==1,"Repeated clicks cannot create duplicate pending entry or lose its return target")
Advance()
check(L.active and not L.pending and not L.toolbar:IsHidden(),"The completed HUD scene activates the editor exactly once")
check(I.activeWindow==L.toolbar and layers==1 and shownCount==1,"Editor input activates after the old menu transition")
check(nextScene==hudui,"Native top-level cursor ownership requests a second HUDUI transition")
Advance()
check(L.active and not L.toolbar:IsHidden() and I.activeWindow==L.toolbar and layers==1,
    "The native HUD to HUDUI cursor handoff must not immediately close Move HUD")
check(L.IsMoving(module) and not L.IsMoving(disabled) and disabled.sv.locked,"Editor preserves disabled modules")
I.Action("back")
check(not L.active and L.toolbar:IsHidden() and not origin:IsHidden() and restores==1,"Keyboard or controller Back returns to Alpha settings")
check(uiMode and topCount==0 and I.activeWindow==origin,
    "Done releases editor top-level ownership and restores settings cursor input")
Advance()
check(I.activeWindow==origin and not origin:IsHidden(),"The completed native cursor handoff does not hide the returned settings page")
check(module.saves==1 and module.sv.locked and disabled.saves==0,"Finishing saves and locks only participating HUDs")
L.Done();check(restores==1,"Repeated Done cannot reopen a consumed return target")
local function StartAgain()
    check(L.Start(),"Editor accepts reopening")
    for _=1,3 do if nextScene then Advance()end end
    check(L.active and I.activeWindow==L.toolbar,"Editor reopens through all native cursor transitions")
end
StartAgain()
local done
for control in pairs(I.entries)do if control.text=="DONE" then done=control end end
done:GetHandler("OnClicked")(done)
check(not L.active and restores==2 and I.activeWindow==origin,"Mouse Done uses the same explicit return path")
StartAgain();local before=restores
Queue(inventory);Advance()
check(not L.active and L.toolbar:IsHidden() and origin:IsHidden() and restores==before,
    "Opening an unrelated native scene dismisses placement without reopening settings")
check(not I.activeWindow and layers==0,"A native menu never retains the editor action layer")
-- Cancel entry before the asynchronous HUD transition completes.
origin:SetHidden(false);check(L.Start() and L.pending,"A second external menu entry waits for native completion")
combat=true;Event(EVENT_PLAYER_COMBAT_STATE,true)
check(not L.pending and not L.active and restores==before,"Combat cancels pending entry without navigation")
Advance();check(not L.active and L.toolbar:IsHidden(),"A later scene completion cannot resurrect canceled placement")
combat=false;Event(EVENT_PLAYER_COMBAT_STATE,false)
current=menu;menu.state=SCENE_SHOWN;base=hud;nextScene=nil
origin:SetHidden(false);check(L.Start() and L.pending,"Loading scenario begins with pending placement")
Event(EVENT_PLAYER_DEACTIVATED)
Advance()
check(not L.active and not L.pending and not L.Start(),"Loading cancels pending entry and blocks it until player activation")
Event(EVENT_PLAYER_ACTIVATED)
check(L.Start(),"Player activation permits a new deliberate editor request")
for _=1,3 do if nextScene then Advance()end end
check(L.active,"A fresh request after loading works")
L.Finish()
check(restores==before,"Programmatic finish never follows a user return path")
for _=1,3 do if nextScene then Advance()end end
current=menu;menu.state=SCENE_SHOWN;base=hud;nextScene=nil
origin:SetHidden(false);check(L.Start() and L.pending,"Modal interruption scenario starts pending")
dialog=true;Advance()
check(not L.active and not L.pending,"A modal appearing before scene completion blocks editor activation")
dialog=false
check(layers==0 and topCount==0,"No action layer or native top-level ownership leaks after canceled transitions")
print("Move HUD scene lifecycle: "..assertions.." assertions passed")
