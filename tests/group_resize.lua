-- Real Group ULT geometry, square native icons and saved edge/corner changes.
local count=0
local function check(value,message)count=count+1;assert(value,message)end
local function Control()
    local c={width=312,height=90,scale=1,left=20,top=90,hidden=true,handlers={}}
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:SetWidth(v)self.width=v end
    function c:SetHeight(v)self.height=v end
    function c:GetWidth()return self.width*self.scale end
    function c:GetHeight()return self.height*self.scale end
    function c:SetScale(v)self.scale=v end
    function c:GetScale()return self.scale end
    function c:GetLeft()return self.left end
    function c:GetTop()return self.top end
    function c:SetHidden(v)self.hidden=v end
    function c:IsHidden()return self.hidden end
    function c:SetText(v)self.text=v end
    function c:SetColor(r,g,b,a)self.color={r,g,b,a}end
    function c:SetHandler(k,v)self.handlers[k]=v end
    function c:GetHandler(k)return self.handlers[k]end
    function c:SetAnchor(point,relative,_,x,y)self.anchor={point,relative,x,y};if relative==GuiRoot then self.left=x or 0;self.top=y or 0 end end
    for _,name in ipairs({'SetClampedToScreen','SetMovable','SetMouseEnabled','SetDrawTier','SetDrawLayer','SetDrawLevel',
        'SetAnchorFill','SetFont','SetVerticalAlignment','SetHorizontalAlignment','SetAlpha','SetMaxLineCount',
        'SetWrapMode','SetTextureCoords','SetTexture','SetBlendMode','ClearAnchors','StartMoving','StopMovingOrResizing'})do c[name]=function()end end
    return c
end
function zo_strformat(_,value) return value end
function GetAbilityName(id) return "Native Ultimate "..id end
function GetAbilityIcon(id) return "native/"..id..".dds" end
TOPLEFT,TOP,TOPRIGHT,RIGHT,BOTTOMRIGHT,BOTTOM,BOTTOMLEFT,LEFT,CENTER=1,2,3,4,5,6,7,8,9
MOUSE_BUTTON_INDEX_LEFT=1
CT_TEXTURE,CT_CONTROL,CT_LABEL,CT_BUTTON=10,11,12,13
GuiRoot=Control();GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateControl=function()return Control()end,CreateTopLevelWindow=function()return Control()end}
local updates={}
EVENT_MANAGER={RegisterForEvent=function()end,UnregisterForEvent=function()end,
    RegisterForUpdate=function(_,name,_,callback)updates[name]=callback end,UnregisterForUpdate=function(_,name)updates[name]=nil end}
AlphaSquadUI={Modules={ULTTracker={sv={enabled=true},uiObscured=false,Clamp=function(v,a,b)
    v=tonumber(v);if not v or v~=v or v==math.huge or v==-math.huge then v=a end;return math.max(a,math.min(b,v))end}}}
assert(loadfile('AlphaSquadUI/Core/Theme.lua'))()
assert(loadfile('AlphaSquadUI/Core/Layout.lua'))()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTGroup.lua'))()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTGroupUI.lua'))()
local G=AlphaSquadUI.Modules.ULTTracker.Group
G:EnsureSavedVariables();G:CreateHUD()
local entries={}
for index=1,12 do entries[index]={displayName='@Player'..index,key='@Player'..index,chargePercent=50,
    connected=true,bestUltimate={icon='native_ultimate_'..index..'.dds'}}end
G.GetTrackedEntries=function()return entries end
G:RefreshHUD()
check(#G.window.rows==12 and G.window:GetWidth()==312,'The group list retains all twelve pooled player rows')
local naturalHeight=G.window:GetHeight()
G.sv.hudWidth=620;G.sv.hudHeight=800;G:ApplyLayout()
check(G.window:GetWidth()==620 and G.window:GetHeight()==800,'Edge dimensions are applied without being replaced by the natural list height')
for _,row in ipairs(G.window.rows)do
    check(row.icon:GetWidth()==row.icon:GetHeight() and row.icon:GetWidth()<=44,'Every native Ultimate icon keeps square proportions')
end
local last=G.window.rows[12];local bottom=last.anchor[4]+last:GetHeight()
check(bottom<=800 and not last:IsHidden(),'Twelve players fit inside the resized panel')
check(G.window.rows[1].user:GetWidth()>300,'Extra width is used for account names rather than stretched artwork')
G.sv.hudHeight=90;G:ApplyLayout()
check(G.window:GetHeight()>=12*28+24,'A too-short saved panel retains enough room for all current players')
G.sv.hudHeight=800;G.sv.scale=150;G:ApplyLayout()
check(G.window.width==620 and G.window.height==800 and G.sv.scale==150,'Corner scale leaves logical dimensions intact')
check(G.window:GetScale()<1.5,'A large scaled list fits inside the screen')
GuiRoot:SetDimensions(2560,1600);G:ApplyLayout()
check(G.window:GetScale()==1.5 and G.sv.scale==150,'The requested scale returns on a larger screen without a preference rewrite')
local saved=G.sv;G:EnsureSavedVariables();G:ApplyLayout()
check(G.sv==saved and G.window.height==800 and G.window.width==620,'Reload normalization preserves custom height and width')
G.sv.hudHeight=0/0;G.sv.hudWidth=math.huge;G:EnsureSavedVariables();G:ApplyLayout()
check(G.window.width==312 and G.window.height==G.layoutBounds.minHeight,'Corrupt geometry is normalized before it reaches native controls')
entries={};G.sv.hudHeight=nil;G.sv.scale=100;G:ApplyLayout()
check(G.window:GetHeight()>=70 and G.window.empty.anchor[4]+G.window.empty:GetHeight()<=G.window:GetHeight(),'An empty group hint fits entirely within its compact panel')
check(#AlphaSquadUI.Layout.attachments[G]==8,'Group ULT attaches the shared resize handles once')
entries={{displayName='@Ready',key='@Ready',chargePercent=100,anyReady=true,bestUltimate={icon='native_ultimate.dds'}},
    {displayName='@Charging',key='@Charging',chargePercent=50,bestUltimate={icon='native_ultimate.dds'}}}
G:RefreshHUD();local oldSurface=G.window.rows[2].bg.color[1]
G.BuildRoster=function()error('Theme updates must not rebuild the network roster')end
AlphaSquadUI.Theme.SetPreset('ember')
check(G.window.rows[2].bg.color[1]~=oldSurface,'Changing the global theme repaints normal Group ULT rows')
check(G.window.rows[1].bg.color[1]==0.18 and G.window.rows[1].ready,'Ready-state meaning stays intact after a theme change')
check(G.window.bg.color[1]==AlphaSquadUI.Theme.colors.bg[1],'Group background uses the selected global surface palette')
local L=AlphaSquadUI.Layout;L.active=true;L.participants[G]=true
G:ApplyVisibility()
check(not updates.AlphaSquadUI_ULTGroup_ReadyPulse and not updates.AlphaSquadUI_ULTGroup_Safety,'Placement suppresses group animation and safety polling')
local liveEntries=entries
G:SetLayoutPreview("mixed");G:RefreshHUD()
local demos=G:GetHUDEntries()
check(#demos==12 and demos[1].displayName=="@Tank01" and demos[12].displayName=="@Damage08","Move HUD supplies twelve clearly fictional accounts")
check(G:GetTrackedEntries()==liveEntries and #G.roster==0 and next(G.readyState)==nil,"Group examples never enter live roster, filters or readiness state")
check(demos[7].recentlyUsed and demos[8].previewState=="off" and demos[9].previewState=="missing" and demos[10].connected==false,"The group preview includes spent, sharing-off, missing and offline states")
check(not G.window.rows[9].icon.hidden,"Missing Ultimate examples still show a native empty-slot frame")
G:SetLayoutOrientation("horizontal")
check(G.layoutColumns==4 and G.window.rows[4].anchor[3]>G.window.rows[1].anchor[3] and G.window.rows[5].anchor[4]>G.window.rows[1].anchor[4],"The horizontal group template arranges twelve accounts in a stable 4 by 3 grid")
local logicalW,logicalH=G.window.width,G.window.height
G.sv.hudWidth=1100;G.sv.hudHeight=210;G:RefreshHUD()
G:SetLayoutOrientation("vertical");G:SetLayoutOrientation("horizontal")
check(G.window.width==1100 and G.window.height==210,"Switching templates retains each orientation's saved size")
G:SetLayoutPreview("ready");check(G:GetHUDEntries()[12].anyReady,"All twelve accounts can preview ready")
G:SetLayoutPreview("missing");check(G:GetHUDEntries()[1].previewState=="missing","Missing preview covers all group rows")
L.active=false;G:RefreshHUD()
check(G:GetHUDEntries()==liveEntries,"Closing placement restores the real group immediately")
print('Group HUD resizing: '..count..' assertions passed')
