-- Real profile-switch, event-ownership and library-setting boundary regressions.
local count=0
local function check(value,message) count=count+1;assert(value,message) end
unpack=unpack or table.unpack
local disk={};local character="A"
function GetWorldName() return "EU" end
local function Clone(value) if type(value)~="table" then return value end;local out={};for k,v in pairs(value) do out[k]=Clone(v) end;return out end
local function Open(name,namespace,key,defaults)
    local id=name..":"..tostring(namespace)..":"..key
    disk[id]=disk[id] or Clone(defaults)
    local values=disk[id]
    return setmetatable({},{__index=values,__newindex=function(_,k,v) values[k]=v end})
end
ZO_SavedVars={NewAccountWide=function(_,name,_,namespace,defaults) return Open(name,namespace,"account",defaults) end,
    NewCharacterIdSettings=function(_,name,_,namespace,defaults) return Open(name,namespace,character,defaults) end}
AlphaSquadUI={Modules={ULTTracker={Group={}}},Settings={}}
assert(loadfile('AlphaSquadUI/Core/Preferences.lua'))()
local P=AlphaSquadUI.Preferences;local module=AlphaSquadUI.Modules.ULTTracker
module.sv=P.Open('ULTTracker','existing','EU',{enabled=true,x=20,group={tracked={17},x=60}})
module.Group.sv=module.sv.group
module.sv.x=90;module.sv.group.x=80
module.sv.enabled=false;module.sv.group.warn=false
local account=module.sv
P.SetCrossSync(false)
check(module.sv~=account and module.sv.x==90,'Cross-sync OFF preserves the current position in a separate character profile')
check(module.sv.enabled==false and module.sv.group.warn==false,'Cross-sync preserves explicit OFF switches at every nesting level')
check(module.Group.sv==module.sv.group and module.Group.sv~=account.group,'Group HUD follows the new profile without sharing nested tables')
module.sv.x=120;module.sv.group.tracked[1]=33
check(account.x==90 and account.group.tracked[1]==17,'Character edits do not mutate account layout or nested filters')
local charA=module.sv
character='B';P.entries={}
module.sv=P.Open('ULTTracker','existing','EU',{enabled=true,x=20,group={tracked={},x=60}})
check(module.sv.x==90 and module.sv.group.tracked[1]==17,'A new character starts from the existing account profile')
module.sv.x=250;P.SetCrossSync(true)
check(module.sv.x==250 and account.x==250,'Cross-sync ON saves the active character placement for the account')
check(module.sv.enabled==false and module.sv.group.warn==false,'Restoring shared preferences never converts OFF into a missing value')
check(charA.x==120,'Existing character profile remains intact')
character='A';P.entries={}
module.sv=P.Open('ULTTracker','existing','EU',{})
check(module.sv.x==250,'Reloading on another character restores the shared position')
P.sv.ultimateSharing=false;P.SetCrossSync(false)
check(P.sv.ultimateSharing==false,'Sharing preference is independent of character layouts')

local registered,filters={},{}
EVENT_MANAGER={RegisterForEvent=function(_,name,event,callback) registered[name..event]=callback end,
    UnregisterForEvent=function(_,name,event)registered[name..event]=nil end,
    AddFilterForEvent=function(_,name,event,...)filters[name..event]={...}end,
    RegisterForUpdate=function()end,UnregisterForUpdate=function()end}
assert(loadfile('AlphaSquadUI/Core/Events.lua'))()
local scope=AlphaSquadUI.Events.NewScope(function(_,event)return event==1 end)
local function event()end
scope:RegisterForEvent('activate',1,event);scope:RegisterForEvent('power',2,event)
scope:AddFilterForEvent('power',2,3,'player',4,5)
scope:SetActive(false)
check(registered.activate1 and not registered.power2,'Disabling tracking unregisters gameplay callbacks but preserves activation')
scope:SetActive(true)
check(registered.power2==event and filters.power2[2]=='player' and filters.power2[4]==5,'Re-enabling restores the original native callback and filters')
scope:UnregisterForEvent('power',2);scope:SetActive(false);scope:SetActive(true)
check(not registered.power2,'Explicitly retired event subscriptions never reappear')

local enabled={[20]=true,[21]=true,[40]=true,[99]=true};local removed=0
local function Protocol(id,name) return {GetId=function()return id end,GetName=function()return name end,IsEnabled=function()return enabled[id] end} end
local handlers={{addonName='LibGroupCombatStats',protocols={Protocol(20,'UltType'),Protocol(21,'UltValue')}},
    {addonName='Unrelated',protocols={Protocol(99,'Other')}},{addonName='LibSetDetection',protocols={Protocol(40,'SetData')}}}
LibGroupBroadcast={internal={handlerManager={GetHandlers=function()return handlers end},protocolManager={
    SetProtocolEnabled=function(_,id,value)enabled[id]=value end,
    RemoveDisabledMessages=function()removed=removed+1 end}}}
local senders=0
LibGroupCombatStats={RegisterAddon=function(_,stats)check(#stats==1 and stats[1]=='ULT','Only Ultimate sending is requested');senders=senders+1;return {} end}
assert(loadfile('AlphaSquadUI/Core/Sharing.lua'))()
local S=AlphaSquadUI.Sharing
check(S.SetEnabled('ultimate',false) and not enabled[20] and not enabled[21],'Library OFF changes both actual Ultimate protocol settings')
check(enabled[40] and enabled[99] and removed==1,'Other transports remain enabled and disabled messages are pruned')
check(not S.IsEnabled('ultimate') and P.sv.ultimateSharing==false,'Displayed OFF matches the stored library choice')
check(S.SetEnabled('ultimate',true) and enabled[20] and enabled[21] and senders==1,'Library ON restarts the sender independently of tracking')
S.StartUltimateSender();check(senders==1,'Repeated activation does not register a second sender')
handlers[1].protocols[1]=Protocol(20,'UnrelatedProtocol')
check(S.SetEnabled('ultimate',false)==false and enabled[20] and enabled[21],'An incompatible library protocol identity cannot be toggled by numeric coincidence')
handlers[1].protocols[1]=Protocol(20,'UltType')
module.sv.enabled=false
check(S.IsEnabled('ultimate'),'Dashboard OFF does not change the library protocol setting')
local tracked=0
local sc={sv={enabled=false},IsGrouped=function()return true end,InitializeSharing=function()end,
    UpdateRuntime=function()tracked=tracked+1 end,MarkScanDirty=function()end,ResetSharingState=function()end}
AlphaSquadUI.Modules.SupportCoverage=sc
S.SetEnabled('builds',true)
check(sc.sv.experimentalSharing and sc.sv.shareData and not sc.sv.enabled and tracked==1,'Build consent wakes only the data path when the UI module is disabled')
S.SetEnabled('builds',false)
check(not sc.sv.shareData and not sc.sv.experimentalSharing and P.sv.buildSharing==false,'One build switch removes all outgoing consent')
print('Profiles and sharing controls: '..count..' assertions passed')
