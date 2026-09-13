-- Exercise both maintained companion sources and an exact generated package.
local count=0
local function check(value,message) count=count+1;assert(value,message) end
local now,grouped=10000,false
local events,updates,later={},{},{}
local eventNames={"EVENT_ADD_ON_LOADED","EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_COMBAT_STATE",
    "EVENT_GROUP_MEMBER_JOINED","EVENT_GROUP_MEMBER_LEFT","EVENT_GROUP_UPDATE","EVENT_GROUP_MEMBER_CONNECTED_STATUS",
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
function d() end
ZO_SavedVars={NewAccountWide=function(_,_,_,_,defaults) local out={};for k,v in pairs(defaults) do out[k]=v end;return out end}
SLASH_COMMANDS={}
local protocols={}
local function Protocol()
    return {AddField=function() end,OnData=function() end,Finalize=function() return true end,
        Send=function(self,data,options) self.last=data;return true end,IsEnabled=function() return true end}
end
LibGroupBroadcast={RegisterHandler=function()
    return {DeclareProtocol=function(_,id) local p=Protocol();protocols[id]=p;return p end,
        SetDisplayName=function() end,SetDescription=function() end}
end}
for _,name in ipairs({"CreateNumericField","CreateFlagField","CreateStringField"}) do LibGroupBroadcast[name]=function() return {} end end
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
check(not SC.sv.enabled and not SC.sv.experimentalSharing,"Fresh companion installs are opt-in")
check(next(updates)==nil,"Disabled companion has no update loop")
SLASH_COMMANDS['/asbuildshare']('on')
check(SC.sv.enabled and SC.share.available,"Explicit consent enables compatible transport")
check(protocols[507] and protocols[510] and not protocols[508] and not protocols[509],"Companion registers only build protocols")
check(next(updates)==nil,"Solo companion has no heartbeat")
grouped=true;Fire(EVENT_GROUP_MEMBER_JOINED)
check(updates.AlphaSquadBuildShareHeartbeat and updates.AlphaSquadBuildShareHeartbeat.ms==60000,"Grouped companion uses a slow heartbeat")
local pending=later;later={};for _,task in ipairs(pending) do now=task.at;task.fn() end
check(SC.localSnapshot~=nil,"Generated shared scanner executes without full addon infrastructure")
Fire(EVENT_PLAYER_COMBAT_STATE,true)
check(SC.inCombat and not updates.AlphaSquadBuildShareHeartbeat,"Combat stops companion scans and heartbeat")
Fire(EVENT_PLAYER_COMBAT_STATE,false)
check(not SC.inCombat and updates.AlphaSquadBuildShareHeartbeat,"Combat end resumes slow precombat sharing")
Fire(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED)
Fire(EVENT_WEREWOLF_STATE_CHANGED)
Fire(EVENT_SKILL_BUILD_SELECTION_UPDATED)
SLASH_COMMANDS['/asbuildshare']('off')
check(not SC.sv.enabled and next(updates)==nil,"Opt-out immediately stops the companion")
pending=later;later={};local before=SC.localSnapshot
for _,task in ipairs(pending) do now=task.at;task.fn() end
check(SC.localSnapshot==before,"Queued captures cannot survive opt-out")
-- Co-installing both addons must never register duplicate protocol handlers.
AlphaSquadUI={Modules={SupportCoverage={}}}
events={};LoadCompanion()
check(AlphaSquadBuildShare.disabled and next(events)==nil,"Full addon makes companion entirely dormant")
print('Companion package: '..count..' assertions passed')
