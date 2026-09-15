-- Group CP coverage requires the inspected player's real unlocked allocation.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
AlphaSquadUI={Modules={SupportCoverage={}}}
local SC=AlphaSquadUI.Modules.SupportCoverage
CHAMPION_SKILL_TYPE_NORMAL=0
CHAMPION_SKILL_TYPE_NORMAL_SLOTTABLE=1
CHAMPION_SKILL_TYPE_STAT_POOL_SLOTTABLE=2
local thresholds={[263]=50,[261]=50,[262]=10,[29]=50,[260]=10}
local kind=CHAMPION_SKILL_TYPE_NORMAL_SLOTTABLE
local reportedPoints
function GetChampionSkillType() return kind end
function GetChampionSkillMaxPoints() return 50 end
function WouldChampionSkillNodeBeUnlocked(id,points)
    reportedPoints=points
    return thresholds[id] and points>=thresholds[id] or false
end
function DoesChampionSkillHaveJumpPoints() return true end
function GetChampionSkillJumpPoints(id) return 0,thresholds[id],50 end
function GetNumPointsSpentOnChampionSkill() error("Never substitute the viewer's allocation") end
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua")
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuild.lua")
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSources.lua")
local function Derive(id,points,known,name)
    local star={id=id,slot=1,points=points,pointsKnown=known,name=name or "Nom localisé"}
    return SC:DeriveBuildCapabilities({skills={championKnown=true,champion={star}}})
end
for _,data in ipairs({{263,"enlivening_overflow"},{261,"minor_heroism"},{262,"from_the_brink"},
    {29,"cleansing_revival"},{260,"salve_of_renewal"}}) do
    local id,key=data[1],data[2]
    local cap=Derive(id,thresholds[id],true)[key]
    check(cap~=nil,"Native node "..id.." matches its support provider independently of translated names")
    check(reportedPoints==thresholds[id],"Native unlock check receives the inspected player's points")
    check(not Derive(id,thresholds[id]-1,true)[key],"Insufficient allocation cannot provide "..key)
    check(not Derive(id,0,true)[key],"Zero-point slotted star cannot provide "..key)
    check(not Derive(id,50,false)[key],"Unverified allocation cannot provide "..key)
end
check(not Derive(263,51,true).enlivening_overflow,"Above-native-maximum allocation is rejected")
check(not Derive(263,0/0,true).enlivening_overflow,"NaN allocation is rejected")
check(not Derive(263,math.huge,true).enlivening_overflow,"Infinite allocation is rejected")
check(not Derive(263,49.5,true).enlivening_overflow,"Fractional allocation is rejected")
check(not Derive(263,nil,true).enlivening_overflow,"Missing allocation is rejected")
check(not Derive(263,50,nil).enlivening_overflow,"Missing allocation evidence is rejected")
thresholds[999]=50
check(not Derive(999,50,true,"Enlivening Overflow").enlivening_overflow,
    "A name cannot impersonate a different verified native Champion node")
kind=CHAMPION_SKILL_TYPE_NORMAL
check(not Derive(263,50,true).enlivening_overflow,"A non-slottable native node cannot prove slotted group coverage")
kind=CHAMPION_SKILL_TYPE_NORMAL_SLOTTABLE
local nativeUnlocked=WouldChampionSkillNodeBeUnlocked
WouldChampionSkillNodeBeUnlocked=function() return true end
check(not Derive(263,1,true).enlivening_overflow,"First positive native jump is required even if the node is accessible")
GetChampionSkillJumpPoints=function() return 0,0/0 end
check(not Derive(263,50,true).enlivening_overflow,"Unreadable native jump thresholds stay unverified")
GetChampionSkillJumpPoints=function() return 0 end
check(not Derive(263,50,true).enlivening_overflow,"A jump-point node without an active stage cannot prove coverage")
DoesChampionSkillHaveJumpPoints=function() return nil end
check(not Derive(263,50,true).enlivening_overflow,"Unreadable native activation model stays unverified")
DoesChampionSkillHaveJumpPoints=function() return false end
check(Derive(262,1,true).from_the_brink~=nil,"Continuous native nodes use the explicit native unlock result")
WouldChampionSkillNodeBeUnlocked=function() return false end
check(not Derive(262,50,true).from_the_brink,"A native locked node never proves a capability")
WouldChampionSkillNodeBeUnlocked=nil
check(not Derive(263,50,true).enlivening_overflow,"Missing unlock API never substitutes local player points")
WouldChampionSkillNodeBeUnlocked=nativeUnlocked

-- Absent overrides are defaults, not an implicit OFF for every effect.
local baseline=SC.Catalog:GetRequirements("trial",{profileOverrides={trial={}}})
check(#baseline>0,"Trial has default requirements")
for _,saved in ipairs({{}, {profileOverrides={}}, {profileOverrides={trial=false}}}) do
    check(#SC.Catalog:GetRequirements("trial",saved)==#baseline,"Absent or invalid override table preserves profile defaults")
end
local override={profileOverrides={trial={[baseline[1]]=false}}}
check(#SC.Catalog:GetRequirements("trial",override)==#baseline-1,"An explicit OFF still removes one tracked requirement")
print("Champion coverage: "..assertions.." assertions passed")
