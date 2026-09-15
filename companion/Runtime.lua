-- Small configurable sender with no UI modules, combat logging, uptime or history.
if AlphaSquadBuildShare.disabled then return end
local SC=AlphaSquadBuildShare.Host.Modules.SupportCoverage
local EM=EVENT_MANAGER
local addon="AlphaSquadBuildShare"
local heartbeat=addon.."Heartbeat"
local generation=0
-- A sender has no remote roster. Ignore summaries/responses and retain no peer
-- builds; only addressed requests and acknowledgments are relevant here.
SC.OnPeerShareData=function() end
local receiveDetails=SC.OnDetailData
function SC:OnDetailData(tag,data)
    if type(data)=="table" and (data.kind==0 or data.kind==3) then return receiveDetails(self,tag,data) end
end
local function Print(text) if d then d("Ąlpha Şquad Build Share: "..text) end end
local function Refresh()
    if not SC.sv or not SC.sv.enabled or not SC:IsGrouped() or SC.inCombat or SC.loading then return end
    if SC.scanDirty or not SC.localSnapshot then
        SC.localSnapshot=SC:ScanLocalPlayer()
        SC.scanDirty=false
    elseif SC.RefreshReadinessFacts then SC:RefreshReadinessFacts() end
    SC:ShareLocalSnapshot("companion build update")
end
local function ScheduleCapture(buildChanged)
    if buildChanged==true then SC.scanDirty=true end
    if not SC.sv or not SC.sv.enabled or not SC:IsGrouped() or SC.inCombat or SC.loading or SC.capturePending then return end
    SC.capturePending=true
    local token=generation
    zo_callLater(function()
        if token~=generation then return end
        SC.capturePending=false
        Refresh()
    end,1500)
end
local function UpdateHeartbeat()
    EM:UnregisterForUpdate(heartbeat)
    if SC.sv and SC.sv.enabled and SC:IsGrouped() and not SC.inCombat and not SC.loading then
        EM:RegisterForUpdate(heartbeat,60000,Refresh)
    end
end
local function Reset()
    generation=generation+1;SC.capturePending=false
    SC:ResetBuildDetailState();SC.peerData={}
    UpdateHeartbeat()
end
local function SetEnabled(value)
    SC.sv.enabled=value==true
    SC.sv.experimentalSharing=value==true
    SC.sv.shareData=value==true
    Reset()
    if value then SC:InitializeSharing();ScheduleCapture(true) end
end
local function Register(event,callback)
    if event then EM:RegisterForEvent(addon,event,callback) end
end
local function Loaded(_,name)
    if name~=addon then return end
    EM:UnregisterForEvent(addon,EVENT_ADD_ON_LOADED)
    local defaults={enabled=true,shareData=true,experimentalSharing=true}
    SC.sv=ZO_SavedVars:NewAccountWide("AlphaSquadBuildShareSavedVariables",1,GetWorldName and GetWorldName(),defaults)
    SC.sv.enabled=SC.sv.enabled==true
    SC.sv.shareData=SC.sv.enabled
    SC.sv.experimentalSharing=SC.sv.enabled
    SC.inCombat=IsUnitInCombat("player")==true
    SC.scanDirty=true
    SC.loading=true -- First capture waits for the initial PLAYER_ACTIVATED.
    SLASH_COMMANDS["/asbuildshare"]=function(text)
        local command=tostring(text or ""):lower():match("^%s*(.-)%s*$")
        if command=="on" then
            SetEnabled(true)
            Print("Sharing ON. Current group members using compatible sharing can request your equipped items, both skill bars, Champion stars, food, potion, class choices and Werewolf or Vampire status. Protocol IDs are provisional; incompatible registration disables sharing.")
        elseif command=="off" then SetEnabled(false);Print("Sharing OFF.")
        elseif command=="status" or command=="" then
            local state,reason=SC:GetSharingStatus()
            Print(state..(reason and " — "..reason or "")..". Commands: /asbuildshare on, /asbuildshare off, /asbuildshare status")
        else Print("Commands: /asbuildshare on, /asbuildshare off, /asbuildshare status") end
    end
    Register(EVENT_PLAYER_ACTIVATED,function()
        SC.loading=false
        SC.inCombat=IsUnitInCombat("player")==true
        Reset();SC:InitializeSharing();ScheduleCapture(true)
    end)
    Register(EVENT_PLAYER_DEACTIVATED,function()
        SC.loading=true
        Reset()
    end)
    Register(EVENT_PLAYER_COMBAT_STATE,function(_,combat)
        SC.inCombat=combat==true
        if SC.inCombat then SC:CancelBuildDetailTransfer("Combat started") end
        UpdateHeartbeat()
        if not SC.inCombat then ScheduleCapture() end
    end)
    local function GroupChanged()
        if not SC:IsGrouped() then Reset()
        elseif SC.PrunePeerSharingData then SC:PrunePeerSharingData() end
        UpdateHeartbeat();ScheduleCapture()
    end
    Register(EVENT_GROUP_MEMBER_JOINED,GroupChanged)
    Register(EVENT_GROUP_MEMBER_LEFT,GroupChanged)
    Register(EVENT_GROUP_UPDATE,GroupChanged)
    local function Dirty() ScheduleCapture(true) end
    Register(EVENT_INVENTORY_SINGLE_SLOT_UPDATE,function(_,bag) if bag==BAG_WORN then Dirty() end end)
    Register(EVENT_ACTION_SLOT_UPDATED,Dirty)
    Register(EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED,Dirty)
    Register(EVENT_WEREWOLF_STATE_CHANGED,Dirty)
    Register(EVENT_ACTIVE_QUICKSLOT_CHANGED,ScheduleCapture)
    Register(EVENT_CHAMPION_PURCHASE_RESULT,Dirty)
    Register(EVENT_SKILL_POINTS_CHANGED,Dirty)
    Register(EVENT_SKILLS_FULL_UPDATE,Dirty)
    Register(EVENT_SKILL_BUILD_SELECTION_UPDATED,Dirty)
    Register(EVENT_SKILL_RESPEC_RESULT,Dirty)
    Register(EVENT_SKILL_LINE_ADDED,Dirty)
    Register(EVENT_ARMORY_BUILD_CHAMPION_SLOTS_MODIFIED,Dirty)
    Register(EVENT_GROUP_MEMBER_CONNECTED_STATUS,GroupChanged)
    Register(EVENT_EFFECT_CHANGED,function(_,_,_,_,tag) if tag=="player" then ScheduleCapture() end end)
    if EVENT_EFFECT_CHANGED and REGISTER_FILTER_UNIT_TAG then
        EM:AddFilterForEvent(addon,EVENT_EFFECT_CHANGED,REGISTER_FILTER_UNIT_TAG,"player")
    end
    SC:InitializeSharing();UpdateHeartbeat();ScheduleCapture()
end
EM:RegisterForEvent(addon,EVENT_ADD_ON_LOADED,Loaded)
