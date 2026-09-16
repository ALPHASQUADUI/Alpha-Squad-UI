-- Curated support families and food evidence boundaries, without an ESO client.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
local now=100000
function GetGameTimeMilliseconds() return now end
function GetUnitName(tag) return tag=="group2" and "PeerCharacter" or "OtherCharacter" end
function GetAbilityName(id) return "Native "..id end
function GetAbilityIcon(id) return "native/"..id..".dds" end
function zo_strformat(_,value) return value end
EVENT_MANAGER={}
AlphaSquadUI={Modules={ULTTracker={sv={group={}},Clamp=function(v,min,max) return math.max(min,math.min(max,v)) end}}}
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroup.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroupCatalog.lua"))()
local ULT=AlphaSquadUI.Modules.ULTTracker
local G=ULT.Group
G:EnsureSavedVariables()
check(#G.catalogFamilies==19 and G.catalogVersion==1,"The synchronization catalog has nineteen ordered support families")
check(G:GetTrackedAbilityCount()==7,"Fresh profiles enable the seven core raid support families")
check(G.sv.trackedAbilities==nil,"Legacy arbitrary skill filters are removed after migration")
local seen,keys={},{}
for _,family in ipairs(G.catalogFamilies) do
    check(not keys[family.key] and type(G.sv.trackedFamilies[family.key])=="boolean","Every family has one stable key and explicit selection bit")
    keys[family.key]=true
    for _,id in ipairs(family.ids) do
        check(not seen[id] and G:GetAbilityFamily(id)==family,"Each verified native morph belongs to exactly one family")
        seen[id]=true
    end
end
check(G:IsAbilityTracked(40223) and G:IsAbilityTracked(40220),"Both native War Horn morphs share the family switch")
check(not G:GetAbilityFamily(30366),"Personal damage Ultimates do not enter the curated support catalog")
check(not G:GetAbilityFamily(29230) and not G:GetAbilityFamily(61747),"Debuff and buff effect IDs cannot masquerade as slotted Ultimates")
check(not G:GetAbilityFamily(32958),"Shifting Standard cannot inherit the other morph's group buff")
check(not G:GetAbilityFamily(17878),"Corrosive Armor does not inherit Magma Shell's ally shield")
check(not G:GetAbilityFamily(35508.5) and not G:GetAbilityFamily(0/0),"Invalid IDs cannot match a catalog family")
SKILLS_DATA_MANAGER={GetProgressionDataByAbilityId=function(_,id)
    if id==900001 then return {abilityId=40223} end
    if id==900002 then return {abilityId=17878} end
    return nil
end}
check(G:GetAbilityFamily(900001).key=="war_horn","Native progression resolves rank variants to their exact canonical morph")
check(not G:GetAbilityFamily(900002),"Rank normalization never expands to an unapproved sibling morph")
SKILLS_DATA_MANAGER=nil
local refreshes,changes,lastKey,lastValue=0,0
G.Refresh=function() refreshes=refreshes+1 end
G.OnFiltersChanged=function(_,key,value) changes=changes+1;lastKey,lastValue=key,value end
check(G:SetAbilityTracked("war_horn",false),"Family keys are accepted by settings toggles")
check(not G:IsAbilityTracked(40223) and not G:IsAbilityTracked(40220),"A family toggle updates every supported morph")
check(changes==1 and lastKey=="war_horn" and lastValue==false,"One family change emits one synchronization notification")
G.CanEditFilters=function() return false,"locked" end
local ok,reason=G:SetAbilityTracked(40223,true)
check(not ok and reason=="locked" and changes==1,"Non-leaders cannot modify or broadcast family switches")
check(not G:SetAllTracked(true) and changes==1,"Non-leaders cannot bypass authority with Select All")
G.CanEditFilters=nil
G:SetAllTracked(false)
check(G:GetTrackedAbilityCount()==0 and changes==2 and refreshes==2,"All Off is one bounded mutation and refresh")
check(lastKey==nil and lastValue==false,"Bulk synchronization distinguishes All Off from a missing family")
G:EnsureSavedVariables()
check(G:GetTrackedAbilityCount()==0,"Explicit All Off persists through normalization and profile refresh")
G:SetAllTracked(true)
check(G:GetTrackedAbilityCount()==19,"All On enables only the nineteen support families")
local effective={war_horn=true}
G.GetEffectiveTrackedFamilies=function() return effective end
check(G:GetTrackedAbilityCount()==1 and G:IsAbilityTracked(38563) and not G:IsAbilityTracked(195031),"Verified raid-lead selection overrides local preferences")
G.roster={{shared=true,ult1ID=38563,ult2ID=40223},{shared=true,ult1ID=40220,ult2ID=195031},
    {shared=true,ult1ID=30366,ult2ID=61747},{shared=false,ult1ID=38563,ult2ID=40223}}
local available=G:GetAvailableAbilities()
check(#available==19 and available[1].key=="war_horn" and available[1].users==2,"Settings remain ordered and count one player per family")
check(available[5].id==195031 and available[5].users==1,"Cryptcanon requires the actual shared Ultimate ability ID")
check(not available[5].tracked and available[1].tracked,"Every settings toggle reflects the effective leader map")
local originalCryptName,originalCryptIcon=G:GetAbilityMeta(195031)
AlphaSquadUI.Preferences={sv={language="fr"},Initialize=function() end}
assert(loadfile("AlphaSquadUI/Core/Localization.lua"))()
assert(loadfile("AlphaSquadUI/Localization/NativeNames.lua"))()
AlphaSquadUI.Localization.Initialize()
local frenchCrypt=G:GetAvailableAbilities()[5]
check(frenchCrypt.name=="Vêtements du Chanoine de la crypte" and frenchCrypt.id==195031,
    "The French selector uses the official mythic set name while preserving the actual skill ID")
local liveCryptName,liveCryptIcon=G:GetAbilityMeta(195031)
check(liveCryptName==originalCryptName and liveCryptIcon==originalCryptIcon,
    "The translated selector never renames the unverified special ability or changes its native icon")
AlphaSquadUI.Localization.SetLanguage("en")
check(G:GetAvailableAbilities()[5].name=="Cryptcanon Vestments" and G:GetAbilityMeta(195031)==originalCryptName,
    "The English selector follows the language choice independently of live ability metadata")
G.GetEffectiveTrackedFamilies=nil
ULT.sv.group={trackedAbilities={["40220"]=true,["195031"]=true,["30366"]=true}}
G:EnsureSavedVariables()
check(G:GetTrackedAbilityCount()==2 and G:IsAbilityTracked(40223) and G:IsAbilityTracked(195031),"Known legacy filters migrate to supported families without retaining damage-only IDs")
ULT.sv.group={trackedFamilies={war_horn="yes",cryptcanon=true,forged=true}}
G:EnsureSavedVariables()
check(G:GetTrackedAbilityCount()==1 and not G.sv.trackedFamilies.forged,"Malformed and unknown saved family keys fail closed")

-- Shared values/costs remain the source of readiness; the filter supplies no cost.
local crypt={shared=true,ult1ID=195031,ult2ID=0,ult1Cost=200,ult2Cost=0,ultValue=150}
local matches=G:GetMatchingUltimates(crypt)
check(#matches==1 and matches[1].id==195031 and matches[1].value==150 and not matches[1].ready,"Cryptcanon uses received identity, points and cost without inferring donation gains")
crypt.ultValue=200
check(G:GetMatchingUltimates(crypt)[1].ready,"Cryptcanon readiness requires a verified positive shared cost")
crypt.ult1Cost=0
check(not G:GetMatchingUltimates(crypt)[1].ready,"Unknown Cryptcanon cost cannot become ready")
crypt.ult1ID=30366;crypt.ultActivatedSetID=3
check(#G:GetMatchingUltimates(crypt)==0,"A gear hint never replaces an unrelated slotted skill with Cryptcanon")

local entry={key="@Peer",displayName="@Peer",unitTag="group2",connected=true}
check(G:GetFoodState(entry)=="unknown","Missing Support Coverage data remains unknown")
local sc={sv={shareData=true,experimentalSharing=true},peerData={},byKey={}}
AlphaSquadUI.Modules.SupportCoverage=sc
local peer={displayName="@Peer",characterName="PeerCharacter",unitTag="group2",connected=true,scannedAt=now,
    asui=true,food={active=false,verified=true},summaryFood={active=true,verified=true}}
sc.peerData[entry.key]=peer
check(G:GetFoodState(entry)=="active","The latest verified summary takes priority over older detailed food")
peer.summaryFood.active=false
check(G:GetFoodState(entry)=="inactive","Only an explicit verified absence reports inactive")
peer.summaryFood.verified=false
check(G:GetFoodState(entry)=="unknown","Unverified absence is not converted to inactive")
peer.summaryFood={verified=true}
check(G:GetFoodState(entry)=="unknown","Missing active flag cannot become inactive")
peer.summaryFood={verified=true,active=true,timeEnds=now/1000+1}
check(G:GetFoodState(entry)=="active","An unexpired verified food report remains active")
peer.summaryFood.timeEnds=now/1000
check(G:GetFoodState(entry)=="unknown","Expiry removes certainty and does not invent a no-food observation")
peer.summaryFood.timeEnds=0/0
check(G:GetFoodState(entry)=="unknown","Non-finite food expiry fails closed")
peer.summaryFood.timeEnds=-1
check(G:GetFoodState(entry)=="unknown","Negative food expiry fails closed")
peer.summaryFood.timeEnds=nil
peer.scannedAt=now-75001
check(G:GetFoodState(entry)=="unknown","Food reports expire after the existing 75-second summary validity limit")
peer.scannedAt=now+1
check(G:GetFoodState(entry)=="unknown","Future timestamps cannot prove food status")
peer.scannedAt=0/0
check(G:GetFoodState(entry)=="unknown","Malformed timestamps cannot prove food status")
peer.scannedAt=now
peer.characterName="PreviousCharacter"
check(G:GetFoodState(entry)=="unknown","An account's previous character cannot lend food status")
peer.characterName="PeerCharacter";peer.unitTag="group3"
check(G:GetFoodState(entry)=="unknown","Reused group tags cannot inherit another roster slot's food")
peer.unitTag="group2";peer.displayName="@Other"
check(G:GetFoodState(entry)=="unknown","Food evidence is bound to the exact account")
peer.displayName="@Peer";entry.connected=false
check(G:GetFoodState(entry)=="unknown","Disconnected group members do not appear freshly fed")
entry.connected=true;peer.connected=false
check(G:GetFoodState(entry)=="unknown","Disconnected cached peers remain unknown")
peer.connected=true;sc.loading=true
check(G:GetFoodState(entry)=="unknown","Loading invalidates active food presentation")
sc.loading=false;sc.share={transportPaused=true};sc.inCombat=true
check(G:GetFoodState(entry)=="active","A combat sending pause does not revoke a fresh already verified report")
sc.sv.shareData=false
check(G:GetFoodState(entry)=="unknown","Revoked build consent immediately hides shared food evidence")
sc.peerData={};sc.byKey[entry.key]=peer
check(G:GetFoodState(entry)=="unknown","Revocation cannot be bypassed by a stale copied roster view")
sc.sv.shareData=true;sc.sv.experimentalSharing=false
check(G:GetFoodState(entry)=="unknown","Disabled build exchange invalidates copied ASUI food evidence")
peer.asui=false;peer.food={verified=true,active=true,timeEnds=now/1000+60};peer.summaryFood=nil
check(G:GetFoodState(entry)=="active","Verified native limited data needs no private build-sharing consent")
sc.byKey[entry.key]=nil
check(G:GetFoodState(entry)=="unknown","Missing peers never default to inactive")
-- Integration: real catalog setters run through the real synchronization hooks.
local own,grouped="@Crown",true
local members={"@Crown","@Peer"}
function IsUnitGrouped() return grouped end
function IsUnitInCombat() return false end
function GetGroupSize() return grouped and #members or 0 end
function GetGroupUnitTagByIndex(index) return "group"..index end
function GetGroupLeaderUnitTag() return "group1" end
function DoesUnitExist(tag) return tag=="player" or tag=="group1" or tag=="group2" end
function GetUnitDisplayName(tag)
    if tag=="player" then return own end
    return members[tonumber(tag:match("group(%d+)"))] or ""
end
function GetWorldName() return "Fixture" end
function zo_callLater() end -- The catalog does not depend on running a timer.
ULT.sv.enabled=true;G.sv.enabled=true
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroupSync.lua"))()
G.Sync:Initialize()
check(G:CanEditFilters(),"The native crown can edit the real curated catalog")
check(G:SetAbilityTracked("barrier",true) and G.Sync.shared.barrier==true,
    "The actual catalog setter updates the authority's effective family map")
check(G:SetAllTracked(false) and G:GetTrackedAbilityCount()==0 and G.Sync:Payload(1).mask==0,
    "Real All Off preserves an explicit zero mask through the sync layer")
check(G:SetAllTracked(true) and G:GetTrackedAbilityCount()==19 and G.Sync:Payload(1).mask==2^19-1,
    "Real All On includes every versioned family in the published bit order")
check(G.Sync:Payload(1).catalog==G.catalogVersion,"Wire payload and runtime catalog use the same schema revision")
own="@Peer";now=now+1
local oldBarrier=G.sv.trackedFamilies.barrier
check(not G:SetAbilityTracked("barrier",false) and G.sv.trackedFamilies.barrier==oldBarrier,
    "A non-leader cannot bypass real authority through a direct catalog setter")
grouped=false;now=now+1
check(G:SetAllTracked(false) and G:GetTrackedAbilityCount()==0,
    "Leaving the group restores editable local filters without stale raid authority")
print(string.format("Group curated catalog and food evidence: %d assertions passed",assertions))
