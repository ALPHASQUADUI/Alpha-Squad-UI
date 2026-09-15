-- Exercise both maintained companion sources and an exact generated package.
local count=0
local function check(value,message) count=count+1;assert(value,message) end
local now,grouped=10000,false
local events,updates,later={},{},{}
local eventNames={"EVENT_ADD_ON_LOADED","EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_COMBAT_STATE",
    "EVENT_PLAYER_DEACTIVATED","EVENT_GROUP_MEMBER_JOINED","EVENT_GROUP_MEMBER_LEFT","EVENT_GROUP_UPDATE","EVENT_GROUP_MEMBER_CONNECTED_STATUS",
    "EVENT_INVENTORY_SINGLE_SLOT_UPDATE","EVENT_ACTION_SLOT_UPDATED","EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED",
    "EVENT_WEREWOLF_STATE_CHANGED","EVENT_ACTIVE_QUICKSLOT_CHANGED","EVENT_CHAMPION_PURCHASE_RESULT","EVENT_SKILL_POINTS_CHANGED",
    "EVENT_SKILLS_FULL_UPDATE","EVENT_SKILL_BUILD_SELECTION_UPDATED","EVENT_SKILL_RESPEC_RESULT",
    "EVENT_ARMORY_BUILD_CHAMPION_SLOTS_MODIFIED","EVENT_EFFECT_CHANGED","REGISTER_FILTER_UNIT_TAG"}
for index,name in ipairs(eventNames) do _G[name]=index end
EVENT_MANAGER={RegisterForEvent=function(_,name,event,fn) events[name..":"..event]=fn end,
    UnregisterForEvent=function(_,name,event) events[name..":"..event]=nil end,
    RegisterForUpdate=function(_,name,ms,fn) updates[name]={ms=ms,fn=fn} end,
    UnregisterForUpdate=function(_,name) updates[name]=nil end,AddFilterForEvent=function() end}
function GetGameTimeMilliseconds() return now end
function GetUnitDisplayName(tag) return tag=="group2" and "@Other" or "@Self" end
function GetUnitName(tag) return GetUnitDisplayName(tag).." Character" end
function GetUnitClassId() return 1 end
function GetUnitClass() return "Dragonknight" end
function GetWorldName() return "Test" end
function GetGroupSize() return grouped and 2 or 0 end
function GetGroupUnitTagByIndex(i) return "group"..i end
function IsUnitGrouped() return grouped end
function IsUnitInCombat() return false end
function IsUnitDead() return false end
function IsUnitOnline() return true end
function AreUnitsEqual(a,b) return a==b or a=="group1" and b=="player" or b=="group1" and a=="player" end
function zo_callLater(fn,ms) later[#later+1]={fn=fn,at=now+(ms or 0)} end
local printed,saved={}
function d(text) printed[#printed+1]=text end
ZO_SavedVars={NewAccountWide=function(_,_,_,_,defaults)
    if saved then return saved end
    local out={};for k,v in pairs(defaults) do out[k]=v end;return out
end}
SLASH_COMMANDS={}
local protocols,native,queued={},{},{}
local rejectSend=false
local function Protocol(id,name)
    if native[id]==nil then native[id]=true end
    return {name=name,AddField=function() end,OnData=function(self,fn) self.receive=fn end,Finalize=function() return true end,
        Send=function(self,data,options)
            if not grouped then return false end
            if rejectSend then return false end
            -- Native Protocol:Send serializes even while disabled. Replacement
            -- happens synchronously in MessageQueue:EnqueueMessage; filtering
            -- of disabled IDs happens later in BroadcastManager:SendData.
            if options and options.replaceQueuedMessages then
                for i=#queued,1,-1 do if queued[i].id==id then table.remove(queued,i) end end
            end
            queued[#queued+1]={id=id,data=data};self.last=data;return true
        end,IsEnabled=function() return native[id] end}
end
LibGroupBroadcast={RegisterHandler=function()
    return {DeclareProtocol=function(_,id,name) local p=Protocol(id,name);protocols[id]=p;return p end,
        SetDisplayName=function() end,SetDescription=function() end}
end}
for _,name in ipairs({"CreateNumericField","CreateFlagField","CreateStringField"}) do LibGroupBroadcast[name]=function() return {} end end
local optionsUnavailable=false
LibGroupBroadcastOptions={}
LibAddonMenu2={RegisterOptionControls=function() end}
CALLBACK_MANAGER={FireCallbacks=function()
    if optionsUnavailable then return end
    local controls={}
    for _,id in ipairs({507,510}) do
        local protocol=protocols[id]
        if protocol then
            local key=id
            controls[#controls+1]={type="header",name=protocol.name}
            controls[#controls+1]={type="checkbox",name="Allow Sending",getFunc=function()return native[key]end,
                setFunc=function(value)native[key]=value end}
        end
    end
    LibAddonMenu2:RegisterOptionControls("LibGroupBroadcastOptions",{{type="submenu",name="Alpha Squad UI — Build Sharing",controls=controls}})
end}
local function Broadcast()
    local sent={}
    for _,entry in ipairs(queued) do if native[entry.id] then sent[#sent+1]=entry end end
    queued={};return sent
end
local packageRoot=arg and arg[1]
local files={"SupportCoverageCatalog.lua","SupportCoverageScanner.lua","SupportCoverageBuild.lua",
    "SupportCoverageSources.lua","SupportCoverageBuildCodec.lua","SupportCoverageShare.lua","SupportCoverageDetails.lua"}
local function LoadCompanion()
    if packageRoot then
        local f=assert(io.open(packageRoot.."/AlphaSquadBuildShare.txt","r"));local manifest=f:read("*a");f:close()
        local paths={}
        for line in manifest:gmatch("[^\r\n]+") do
            if line:sub(1,2)~="##" then
                check(not paths[line],"Companion manifest has no duplicate files")
                paths[line]=true;assert(loadfile(packageRoot.."/"..line))()
            end
        end
    else
        assert(loadfile("companion/Bootstrap.lua"))()
        local core=assert(io.open("AlphaSquadUI/Core/Sharing.lua","r"));local body=core:read("*a");core:close()
        local loader=loadstring or load
        assert(loader("if AlphaSquadBuildShare.disabled then return end\nlocal AlphaSquadUI=AlphaSquadBuildShare.Host\n"..body,"Sharing.lua"))()
        for _,name in ipairs(files) do
            local f=assert(io.open("AlphaSquadUI/Modules/SupportCoverage/"..name,"r"));local body=f:read("*a");f:close()
            local loader=loadstring or load
            assert(loader("if AlphaSquadBuildShare.disabled then return end\nlocal AlphaSquadUI=AlphaSquadBuildShare.Host\n"..body,name))()
        end
        assert(loadfile("companion/Runtime.lua"))()
    end
end
LoadCompanion()
check(AlphaSquadUI==nil,"Companion does not create the full addon's global namespace")
local SC=AlphaSquadBuildShare.Host.Modules.SupportCoverage
local function Fire(event,...)
    local fn=events["AlphaSquadBuildShare:"..event];check(type(fn)=="function","Companion registered expected event")
    fn(event,...)
end
Fire(EVENT_ADD_ON_LOADED,"AlphaSquadBuildShare")
check(SC.sv.enabled and SC.sv.experimentalSharing,"Fresh companion installs enable sharing")
check(next(updates)==nil,"Solo companion has no update loop")
SLASH_COMMANDS['/asbuildshare']('on')
check(SC.sv.enabled and SC.share.available,"Explicit consent enables compatible transport")
check(native[507] and native[510] and SC:GetSharingStatus()=="SHARING","Companion ON applies the two native Allow Sending controls")
check(protocols[507] and protocols[510] and not protocols[508] and not protocols[509],"Companion registers only build protocols")
check(next(updates)==nil,"Solo companion has no heartbeat")
Fire(EVENT_PLAYER_ACTIVATED)
grouped=true;Fire(EVENT_GROUP_MEMBER_JOINED)
check(updates.AlphaSquadBuildShareHeartbeat and updates.AlphaSquadBuildShareHeartbeat.ms==60000,"Grouped companion uses a slow heartbeat")
local pending=later;later={};for _,task in ipairs(pending) do now=task.at;task.fn() end
check(SC.localSnapshot~=nil,"Generated shared scanner executes without full addon infrastructure")
native[507]=false
check(SC:GetSharingStatus()=="LOCAL","A disabled native details protocol cannot report SHARING")
SLASH_COMMANDS['/asbuildshare']('status')
check(printed[#printed]:find('disabled in LibGroupBroadcast',1,true),"Status explains the native sharing blockage")
SLASH_COMMANDS['/asbuildshare']('on')
check(native[507] and native[510],"Explicit ON restores native sharing without opening another panel")
pending=later;later={};for _,task in ipairs(pending) do now=task.at;task.fn() end
local captures,readiness=0,0
local captureNative,readinessNative=SC.ScanLocalPlayer,SC.RefreshReadinessFacts
SC.ScanLocalPlayer=function(self) captures=captures+1;return captureNative(self) end
SC.RefreshReadinessFacts=function(self) readiness=readiness+1;return readinessNative(self) end
local function FlushCaptures()
    local tasks=later;later={}
    for _,task in ipairs(tasks) do now=task.at;task.fn() end
end
Fire(EVENT_EFFECT_CHANGED,0,0,0,'player');FlushCaptures()
check(captures==0 and readiness==1,'Food or boon changes refresh readiness without rescanning every item and skill')
updates.AlphaSquadBuildShareHeartbeat.fn()
check(captures==0 and readiness==2,'Unchanged companion heartbeats reuse the current equipment capture')
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED);Fire(EVENT_SKILL_BUILD_SELECTION_UPDATED);FlushCaptures()
check(captures==1 and not SC.scanDirty,'Multiple build events coalesce into one native capture')
Fire(EVENT_PLAYER_COMBAT_STATE,true)
local statusNative,statusReads=SC.GetSharingStatus,0
SC.GetSharingStatus=function(self)statusReads=statusReads+1;return statusNative(self)end
for _=1,20 do events['AlphaSquadBuildShare:'..EVENT_EFFECT_CHANGED](EVENT_EFFECT_CHANGED,0,0,0,'player') end
check(statusReads==0,'Combat effect events stop before native option reads or sharing-status allocation')
SC.GetSharingStatus=statusNative
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED)
check(SC.scanDirty and captures==1,'Companion remembers build changes while scans are paused in combat')
Fire(EVENT_PLAYER_COMBAT_STATE,false);FlushCaptures()
check(captures==2 and not SC.scanDirty,'A single committed capture runs after combat ends')
local beforeLoading=SC.localSnapshot
Fire(EVENT_PLAYER_DEACTIVATED)
check(SC.loading and not updates.AlphaSquadBuildShareHeartbeat,"Loading suspends the companion heartbeat")
local loadingTasks=later;later={};for _,task in ipairs(loadingTasks) do now=task.at;task.fn() end
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED)
check(SC.localSnapshot==beforeLoading and #later==0,"Loading cancels queued captures and prevents new scans")
Fire(EVENT_PLAYER_ACTIVATED)
check(not SC.loading and updates.AlphaSquadBuildShareHeartbeat,"Activation resumes sharing after loading")
Fire(EVENT_PLAYER_COMBAT_STATE,true)
check(SC.inCombat and not updates.AlphaSquadBuildShareHeartbeat,"Combat stops companion scans and heartbeat")
Fire(EVENT_PLAYER_COMBAT_STATE,false)
check(not SC.inCombat and updates.AlphaSquadBuildShareHeartbeat,"Combat end resumes slow precombat sharing")
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED)
Fire(EVENT_WEREWOLF_STATE_CHANGED)
Fire(EVENT_SKILL_BUILD_SELECTION_UPDATED)
-- Simulate an unsent summary, a partial/acknowledged transfer's next fragment,
-- and a completely unrelated library message at the native queue boundary.
queued={{id=510,data={private="old summary"}},{id=507,data={private="old fragment"}},
    {id=20,data={unrelated="ultimate"}}};native[20]=true
SLASH_COMMANDS['/asbuildshare']('off')
check(not SC.sv.enabled and next(updates)==nil,"Opt-out immediately stops the companion")
check(not native[507] and not native[510] and native[20],"OFF disables only the companion's own native protocols")
local sent=Broadcast()
check(#sent==1 and sent[1].id==20,"The actual send boundary drops queued build frames after OFF while unrelated traffic survives")
pending=later;later={};local before=SC.localSnapshot
for _,task in ipairs(pending) do now=task.at;task.fn() end
check(SC.localSnapshot==before,"Queued captures cannot survive opt-out")
SLASH_COMMANDS['/asbuildshare']('on')
queued={{id=510,data={private="old summary"}},{id=507,data={private="old fragment"}},
    {id=20,data={unrelated="ultimate"}}}
SLASH_COMMANDS['/asbuildshare']('off');SLASH_COMMANDS['/asbuildshare']('on')
sent=Broadcast()
local neutral,unrelated=0,0
for _,entry in ipairs(sent) do
    if entry.id==20 then unrelated=unrelated+1
    else
        neutral=neutral+1
        check(entry.data.version==0 and not entry.data.private,"Rapid OFF -> ON cannot resurrect personal data queued before opt-out")
        if entry.id==507 then check(entry.data.body=="" and entry.data.checksum==0,"A replacement detail frame contains no identity or build") end
    end
end
check(neutral==2 and unrelated==1,"Queue replacement touches each owned protocol and preserves unrelated messages")
queued={{id=507,data={private="unsent detail"}}};rejectSend=true
SLASH_COMMANDS['/asbuildshare']('off');SLASH_COMMANDS['/asbuildshare']('on')
check(not native[507] and not native[510] and SC:GetSharingStatus()=="LOCAL",
    "Failed public queue replacement keeps native protocols disabled across a later ON attempt")
rejectSend=false;SLASH_COMMANDS['/asbuildshare']('on')
sent=Broadcast()
for _,entry in ipairs(sent) do check(not entry.data.private,"Retry clears stale data before native protocols can turn ON") end
check(SC:GetSharingStatus()=="SHARING","Queue revocation recovers when the supported public API succeeds")
queued={{id=507,data={private="previous group build"}},{id=20,data={unrelated="ultimate"}}}
SC.share.mayHaveQueuedBuildData=true
grouped=false;Fire(EVENT_GROUP_MEMBER_LEFT)
SLASH_COMMANDS['/asbuildshare']('off');SLASH_COMMANDS['/asbuildshare']('on')
check(not native[507] and not native[510] and SC:GetSharingStatus()=="LOCAL",
    "A solo OFF -> ON cannot unblock personal data left in the previous group's native queue")
check(SC.share.queueRevokeNeedsGroup and SC.sv.nativeSharingPending==true,
    "Solo reenable keeps its intent pending until grouped queue replacement is possible")
grouped=true;Fire(EVENT_GROUP_MEMBER_JOINED)
sent=Broadcast()
for _,entry in ipairs(sent) do
    if entry.id~=20 then check(not entry.data.private and entry.data.version==0,"New-group activation clears previous-group queued builds before enabling transport") end
end
check(native[507] and native[510] and not SC.share.queueRevokeNeedsGroup and SC:GetSharingStatus()=="SHARING",
    "The pending companion choice resumes in the new group without a second user command")
native[507]=false
optionsUnavailable=true;AlphaSquadBuildShare.Host.Sharing.nativeControls={}
SLASH_COMMANDS['/asbuildshare']('on')
check(SC:GetSharingStatus()=="LOCAL" and printed[#printed]:find("Sharing unavailable",1,true),"Missing native controls never produce a false Sharing ON confirmation")
local oldCapture=SC.localSnapshot
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED);FlushCaptures()
check(SC.localSnapshot==oldCapture,"Unavailable native controls prevent capture and sharing work")
optionsUnavailable=false;SLASH_COMMANDS['/asbuildshare']('on')
check(SC:GetSharingStatus()=="SHARING","Explicit ON retries supported options after they become available")
-- Native OFF after setup remains authoritative across client reloads.
native[507]=false;saved=SC.sv;events={};updates={};later={};protocols={}
LoadCompanion();SC=AlphaSquadBuildShare.Host.Modules.SupportCoverage
Fire(EVENT_ADD_ON_LOADED,"AlphaSquadBuildShare");Fire(EVENT_PLAYER_ACTIVATED)
check(not native[507] and SC:GetSharingStatus()=="LOCAL" and next(updates)==nil,"Reload preserves a native OFF without restarting the sender")
SLASH_COMMANDS['/asbuildshare']('off');saved=SC.sv;events={};updates={};later={};protocols={}
LoadCompanion();SC=AlphaSquadBuildShare.Host.Modules.SupportCoverage
Fire(EVENT_ADD_ON_LOADED,"AlphaSquadBuildShare");Fire(EVENT_PLAYER_ACTIVATED)
check(not SC.sv.enabled and not native[507] and not native[510] and next(updates)==nil,"Saved explicit companion OFF survives reload and activation")
-- Dependency options can finish initialization between addon load and the
-- first player activation. Retry once at that lifecycle boundary.
saved=nil;events={};updates={};later={};protocols={};optionsUnavailable=true
LoadCompanion();SC=AlphaSquadBuildShare.Host.Modules.SupportCoverage
Fire(EVENT_ADD_ON_LOADED,"AlphaSquadBuildShare")
check(SC:GetSharingStatus()=="LOCAL" and SC.sv.nativeSharingPending==true,"Missing startup controls leave fresh consent pending and display no false ON")
optionsUnavailable=false;Fire(EVENT_PLAYER_ACTIVATED)
check(SC:GetSharingStatus()=="SHARING" and SC.sv.nativeSharingPending==nil and native[507] and native[510],
    "First activation completes fresh sharing setup once native controls become available")
-- Co-installing both addons must never register duplicate protocol handlers.
AlphaSquadUI={Modules={SupportCoverage={}}}
events={};LoadCompanion()
check(AlphaSquadBuildShare.disabled and next(events)==nil,"Full addon makes companion entirely dormant")
print('Companion package: '..count..' assertions passed')
