-- Exclusive panel history distinguishes deliberate Back from native teardown.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local function Control()
    return {hidden=true,SetHidden=function(self,value)self.hidden=value end,
        IsHidden=function(self)return self.hidden end}
end
local inputWindows={}
local combat=false
IsUnitInCombat=function()return combat end
AlphaSquadUI={Modules={},Utils={GetLogicalWidth=function()return 100 end,GetLogicalHeight=function()return 100 end},
    Input={RegisterWindow=function(control,options)inputWindows[control]=options end}}
assert(loadfile("AlphaSquadUI/Core/Settings.lua"))()
local S=AlphaSquadUI.Settings
local main,coverage,builds,group=Control(),Control(),Control(),Control()
local restores,refreshes=0,0
local function Register(id,control,page)
    S.RegisterExclusiveWindow(id,control,function()control:SetHidden(true)end,
        {fallbackPage=page,restore=function()restores=restores+1 end})
end
Register("settings",main)
Register("coverage",coverage,"supportcoverage")
Register("builds",builds,"supportcoverage")
Register("group",group,"ulttracker")
S.AttachShell(main,function(page)main.page=page end,function()refreshes=refreshes+1 end)
local function Only(control)
    local count=0
    for _,entry in pairs(S.exclusiveWindows)do if not entry.control:IsHidden()then count=count+1 end end
    return count==1 and not control:IsHidden()
end
S.OpenPage("supportcoverage");S.ShowExclusiveWindow("coverage");S.ShowExclusiveWindow("builds")
check(Only(builds),"Opening nested panels preserves exclusive visibility")
check(#S.windowHistory==2,"Only the previous visible panels enter navigation history")
inputWindows[builds].close()
check(Only(coverage) and restores==1,"Input Back restores Coverage from Builds and refreshes cached presentation")
S.CloseExclusiveWindow("coverage")
check(Only(main) and main.page=="supportcoverage","Closing Coverage restores its original module page")
check(#S.windowHistory==0,"Returning to the root clears secondary history")
S.ShowExclusiveWindow("coverage");S.ShowExclusiveWindow("builds");S.ShowExclusiveWindow("coverage")
check(#S.windowHistory==1,"Revisiting a previous panel removes forward history instead of creating a loop")
S.CloseExclusiveWindow("coverage")
check(Only(main),"Alternating Coverage and Builds still returns to the root")
S.CloseMain();S.ShowExclusiveWindow("group");S.CloseExclusiveWindow("group")
check(Only(main) and main.page=="ulttracker","A secondary opened directly from a HUD returns to its own module settings")
S.ShowExclusiveWindow("coverage");S.ShowExclusiveWindow("builds")
local token=S.CaptureReturnTarget()
S.DismissAllWindows()
check(not S.AnyExclusiveWindowVisible() and #S.windowHistory==0,"Placement entry dismisses all panels without navigating")
check(token.id=="builds" and #token.history==2,"Placement captures an independent bounded return token")
S.RestoreReturnTarget(token)
check(Only(builds) and #S.windowHistory==2,"Explicit placement Done restores the original secondary and its history")
S.CloseExclusiveWindow("builds");S.CloseExclusiveWindow("coverage")
check(Only(main) and main.page=="ulttracker","Nested return preserves the page actually visible before opening Coverage")
S.ShowExclusiveWindow("builds")
inputWindows[builds].dismiss()
check(not S.AnyExclusiveWindowVisible(),"Native scene dismissal uses raw teardown without reopening a parent")
check(not S.CloseExclusiveWindow("builds") and not S.AnyExclusiveWindowVisible(),"A delayed close for an already hidden panel cannot resurrect menus")
S.ShowExclusiveWindow("builds");combat=true;S.CloseExclusiveWindow("builds")
check(not S.AnyExclusiveWindowVisible(),"A combat transition between click and close suppresses return navigation")
check(not S.RestoreReturnTarget(token),"A captured placement token cannot reopen panels in combat")
combat=false;AlphaSquadUI.Input.loading=true
check(not S.RestoreReturnTarget(token),"Loading suppresses deferred panel restoration")
AlphaSquadUI.Input.loading=false;AlphaSquadUI.Modules.SupportCoverage={loading=true}
check(not S.RestoreReturnTarget(token),"Module loading state also blocks restoration before input initializes")
AlphaSquadUI.Modules.SupportCoverage.loading=false
check(S.RestoreReturnTarget({id="removed",page="dashboard"}) and Only(main),"An unavailable return destination falls back to the root settings")
inputWindows[main].close()
check(not S.AnyExclusiveWindowVisible(),"An explicit root close still dismisses the addon")
local sceneName,inUIMode,cursorCalls="hud",false,0
SCENE_MANAGER={GetCurrentScene=function()return {GetName=function()return sceneName end}end,
    IsInUIMode=function()return inUIMode end,
    SetInUIMode=function(_,value)inUIMode=value;cursorCalls=cursorCalls+1 end}
S.OpenPage("dashboard")
check(Only(main) and inUIMode and S.ownsCursor,"First explicit open from gameplay acquires mouse mode without needing chat or a previous panel")
S.ShowExclusiveWindow("group")
check(Only(group) and inUIMode and S.ownsCursor,"Opening a secondary preserves the cursor ownership acquired at the root")
S.CloseExclusiveWindow("group");inputWindows[main].close()
check(not inUIMode and not S.ownsCursor,"Returning through a secondary and closing the root releases only addon-owned mouse mode")
local dialog=true
ZO_Dialogs_IsShowingDialog=function()return dialog end
local beforeDialog=cursorCalls
S.OpenPage("dashboard")
check(cursorCalls==beforeDialog and not S.ownsCursor,"An open native dialog retains control of cursor mode")
dialog=false;ZO_Dialogs_IsShowingDialog=nil;inputWindows[main].close()
S.RestoreReturnTarget({id="settings",page="dashboard"})
check(Only(main) and inUIMode and S.ownsCursor,"Returning from placement restores native cursor access after the toolbar releases it")
inputWindows[main].close()
check(not inUIMode and not S.ownsCursor,"Explicit Back from the root releases mouse mode entered by the addon")
inUIMode=true;S.RestoreReturnTarget({id="settings",page="dashboard"});inputWindows[main].close()
check(inUIMode,"Closing the addon preserves mouse mode that was already enabled by the player")
inUIMode=false;S.RestoreReturnTarget({id="settings",page="dashboard"});sceneName="inventory"
local beforeDismiss=cursorCalls
inputWindows[main].dismiss()
check(cursorCalls==beforeDismiss and not S.ownsCursor,"External native scenes keep control of their mouse mode during raw dismissal")
S.RestoreReturnTarget({id="settings",page="dashboard"})
check(cursorCalls==beforeDismiss,"Returning within native options does not replace the game's scene or mouse mode")
SCENE_MANAGER=nil
S.OpenPage("libraries")
for index=1,12 do local window=Control();Register("extra"..index,window,"dashboard");S.ShowExclusiveWindow("extra"..index)end
check(#S.windowHistory==8 and S.windowHistory[1].id=="settings","Window history stays bounded while retaining its root destination")
check(not S.CloseExclusiveWindow("missing") and not S.ShowExclusiveWindow("missing"),"Unknown panel IDs are harmless")
check(refreshes>0,"Returning to settings refreshes its current values")
print(string.format("Navigation: %d assertions passed",total))
