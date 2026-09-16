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
local controls={}
WINDOW_MANAGER={CreateControl=function(_,name) local control=Control();if name then controls[name]=control end;return control end,
    CreateTopLevelWindow=function(_,name) local control=Control();if name then controls[name]=control end;return control end}
local updates={}
EVENT_MANAGER={RegisterForEvent=function()end,UnregisterForEvent=function()end,
    RegisterForUpdate=function(_,name,_,callback)updates[name]=callback end,UnregisterForUpdate=function(_,name)updates[name]=nil end}
AlphaSquadUI={Modules={ULTTracker={sv={enabled=true},uiObscured=false,Clamp=function(v,a,b)
    v=tonumber(v);if not v or v~=v or v==math.huge or v==-math.huge then v=a end;return math.max(a,math.min(b,v))end}}}
AlphaSquadUI.Preferences={sv={language="en"},Initialize=function()end}
assert(loadfile('AlphaSquadUI/Core/Localization.lua'))()
assert(loadfile('AlphaSquadUI/Localization/fr.lua'))()
AlphaSquadUI.Localization.Initialize()
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
local fullRoster=entries
local fullRowHeight=G:GetRowHeight()
entries={fullRoster[1],fullRoster[2]};G:RefreshHUD()
check(G:GetRowHeight()==fullRowHeight and G.window.height<200,'A smaller filtered roster shrinks its frame without enlarging its rows')
check(G.sv.hudHeight==800,'Roster changes retain the saved twelve-player design height')
local geometryCalls=0
local applyGeometry=G.ApplyListGeometry
G.ApplyListGeometry=function(self)geometryCalls=geometryCalls+1;return applyGeometry(self)end
local anchorCalls=0
local clearAnchors=G.window.rows[1].ClearAnchors
G.window.rows[1].ClearAnchors=function(self)anchorCalls=anchorCalls+1;return clearAnchors(self)end
entries[1].chargePercent=63;G:RefreshHUD()
check(G.window.rows[1].percent.text=='63%' and geometryCalls==0 and anchorCalls==0,'Charge updates refresh the percentage without reapplying row geometry')
entries={fullRoster[2],fullRoster[1]};G:RefreshHUD()
check(G.window.rows[1].entry==fullRoster[2] and geometryCalls==0 and anchorCalls==0,'Readiness sorting reuses positioned row controls')
G.sv.scale=150;GuiRoot:SetDimensions(1920,800);G:RefreshHUD()
local compactScale=G.window:GetScale()
entries=fullRoster;G:RefreshHUD()
check(G.window:GetScale()==compactScale,'Screen fitting keeps row pixels stable when the full roster returns')
GuiRoot:SetDimensions(1920,1080);G.sv.scale=100
G.ApplyListGeometry=applyGeometry;G.window.rows[1].ClearAnchors=clearAnchors
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
check(G.window.rows[1].iconBorder.color[2]>G.window.rows[1].iconBorder.color[1] and G.window.rows[1].ready,'A steady green ready outline remains semantic after a theme change')
check(G.window.bg.hidden and G.window.rows[1].bg.hidden and G.window.rows[1].readyOverlay.hidden,'Gameplay has no panel, row background or flashing orange overlay')
check(not updates.AlphaSquadUI_ULTGroup_ReadyPulse,'A ready group adds no animation timer')
local L=AlphaSquadUI.Layout;L.active=true;L.participants[G]=true
G:ApplyVisibility()
check(not updates.AlphaSquadUI_ULTGroup_ReadyPulse and not updates.AlphaSquadUI_ULTGroup_Safety,'Placement suppresses group animation and safety polling')
local liveEntries=entries
G:SetLayoutPreview("mixed");G:RefreshHUD()
local demos=G:GetHUDEntries()
check(#demos==12 and demos[1].displayName=="@Tank01" and demos[12].displayName=="@Damage08","Move HUD supplies twelve clearly fictional accounts")
check(G:GetTrackedEntries()==liveEntries and #G.roster==0 and next(G.previousUltValues)==nil,"Group examples never enter live roster, filters or readiness state")
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
local savedHorizontalHeight=G.sv.hudHeight
G:SetLayoutOrientation('vertical');G:SetLayoutOrientation('horizontal')
check(G.sv.hudHeight==savedHorizontalHeight,'Switching templates with only two real players preserves the full-roster size')
L.active=true;L.selected=G;G:SetLayoutPreview('live');G.sv.scale=100;G:RefreshHUD()
local previousHeight,previousWidth=G.window.height,G.window.width
L.ResizeSelected(0,12)
check(math.abs(G.window.height-previousHeight-12)<0.00001 and G.window.width==previousWidth,'Controller height resizing follows the visible Live preview by the requested pixels')
local editedRowHeight=G:GetRowHeight()
entries=fullRoster;G:RefreshHUD()
check(G:GetRowHeight()==editedRowHeight,'The resized Live preview applies the same row height to players who appear later')
entries={fullRoster[1],fullRoster[2]};G:SetLayoutOrientation('vertical')
GuiRoot:SetDimensions(1920,800);G.sv.hudWidth=312;G.sv.hudHeight=800;G.sv.scale=100;G:RefreshHUD()
function GetUIMousePosition()return 0,0 end
check(L.BeginResize(G,1,1,L.attachments[G][5]),'A corner drag begins on a compact Live roster')
L.UpdateResize(-40,-20);L.EndResize()
local pointerScale=G.window:GetScale();G:RefreshHUD()
check(math.abs(G.window:GetScale()-pointerScale)<0.00001,'A charge refresh cannot snap a resized compact roster back to a different scale')
L.BeginResize(G,0,1,L.attachments[G][6]);L.UpdateResize(0,500)
local edgeScale=G.window:GetScale();L.EndResize();G:RefreshHUD()
check(math.abs(edgeScale-pointerScale)<0.00001 and math.abs(G.window:GetScale()-pointerScale)<0.00001,
    'Edge resizing stops at the full-roster screen limit without changing scale mid-drag')
L.active=false
local tracker=AlphaSquadUI.Modules.ULTTracker
local entryReads,rowWrites=0,0
local getEntries,refreshRow=G.GetTrackedEntries,G.RefreshRow
G.GetTrackedEntries=function(self) entryReads=entryReads+1;return getEntries(self) end
G.RefreshRow=function(self,...) rowWrites=rowWrites+1;return refreshRow(self,...) end
tracker.uiObscured=true;G.sv.hideInMenus=true;G:ApplyVisibility()
G:RefreshHUD()
check(entryReads==0 and rowWrites==0 and G.hudDirty,
    'Menu-hidden group HUDs defer sorting and row writes while data can still change')
entries[1].chargePercent=73
tracker.uiObscured=false;G:ApplyVisibility()
check(entryReads==1 and rowWrites==12 and not G.hudDirty and G.window.rows[1].percent.text=='73%',
    'Restoring group visibility renders the latest state once without waiting for another packet')
G.GetTrackedEntries,G.RefreshRow=getEntries,refreshRow
-- Live language changes repaint existing HUD/config controls and keep native
-- ability names intact; metadata fallbacks must not cache the previous language.
local localization=AlphaSquadUI.Localization
entries={{displayName="@Example",key="@Example",connected=false,recentlyUsed=true,
    anyReady=true,bestUltimate={name="Native Ultimate",icon="native.dds"}}}
G:RefreshHUD()
check(G.window.rows[1].percent.text=="OFFLINE" and not G.window.rows[1].ready,
    'Offline availability takes precedence over a spent marker and stale ready flag')
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTGroupSettings.lua'))()
G:CreateConfigWindow();G.configWindow:SetHidden(false)
G.sv.trackedAbilities={['123']=true}
G:RefreshConfig()
local row=G.configWindow.abilityRows[1]
local enter,click=row.handlers.OnMouseEnter,row.handlers.OnMouseUp
G:RefreshConfig()
check(row.handlers.OnMouseEnter==enter and row.handlers.OnMouseUp==click,
    'Refreshing a filter reuses event closures instead of rebuilding them per row')
local nativeAbilityName=GetAbilityName
GetAbilityName=function() return "" end
check(G:GetAbilityMeta(88888)=="Unknown Ultimate",'Unknown metadata starts in the selected language')
GetAbilityName=nativeAbilityName
check(localization.SetLanguage('fr'),'French can be selected without reloading the addon')
check(G.configWindow.abilityRows[1].name.text=='Native Ultimate 123',
    'Switching addon language never replaces native ability names')
check(controls.AlphaSquadULTGroupConfigTitle.text=='ULTIMES DU GROUPE'
    and controls.AlphaSquadULTGroupMoveHUDLabel.text=='DÉPLACER LE HUD',
    'An existing group configuration and its placement button switch to French together')
check(G:GetAbilityMeta(88888)=='Ultime inconnu','Cached fallback metadata follows the selected language')
G.configWindow:SetHidden(true);G:ApplyVisibility()
check(G.window.rows[1].percent.text=='ABSENT','A hidden HUD renders current French text when gameplay returns')
check(G.window.rows[1].percent:GetWidth()==74,'Localized compact status has reserved width separate from the account name')
entries[1].connected=true;entries[1].dead=true;G:RefreshHUD()
check(G.window.rows[1].percent.text==AlphaSquadUI.L('DEAD') and not G.window.rows[1].ready,
    'A dead player never shows the previous ready or recently-spent state')
localization.SetLanguage('en');G:RefreshHUD()
check(G.window.rows[1].percent.text=='DEAD','Switching back restores English in the same pooled row')
G.roster={};G:SetSafetyUpdateActive(true)
check(not updates.AlphaSquadUI_ULTGroup_Safety,'Solo gameplay does not retain the group fallback polling loop')
G.roster={{key='@Example'}};G:SetSafetyUpdateActive(true)
check(updates.AlphaSquadUI_ULTGroup_Safety,'The fallback resumes when a roster exists')
G.roster={};G:SetSafetyUpdateActive(false)
print('Group HUD resizing and live language: '..count..' assertions passed')
