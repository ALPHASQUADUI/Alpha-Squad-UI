-- Native definition mocks deliberately use synthetic Storm Voice / script IDs.
-- They verify identity boundaries and wire roundtrips, not live ESO rendering.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
AlphaSquadUI={Modules={SupportCoverage={}}}
local SC=AlphaSquadUI.Modules.SupportCoverage
SKILL_TYPE_CLASS=1
SCRIBING_SLOT_PRIMARY=1;SCRIBING_SLOT_SECONDARY=2;SCRIBING_SLOT_TERTIARY=3
local nativeRank,nativeLine,nativePassive,iconQueries=2,36,true,0
local locale='fr'
function GetAbilityName(id)
    if id==700002 then return locale=='fr' and 'La voix de la tempête' or 'Die Sturmstimme' end
    if id==29430 then return locale=='fr' and 'Brûlures traumatiques' or 'Traumatische Verbrennungen' end
    return 'Native '..id
end
function GetAbilityIcon(id)
    iconQueries=iconQueries+1
    return id==700002 and '/esoui/art/icons/ability_dragonknight_031_u49_new.dds' or '/esoui/art/icons/unknown.dds'
end
function GetSpecificSkillAbilityKeysByAbilityId(id)
    if id==700002 then return SKILL_TYPE_CLASS,2,10,0,nativeRank end
    if id==900001 then return SKILL_TYPE_CLASS,9001,1,0,1 end
    if id==900002 then return SKILL_TYPE_CLASS,9002,1,0,1 end
end
function GetSkillLineId(_,lineIndex)
    if lineIndex==9001 then return 35 end
    if lineIndex==9002 then return 44 end
    return nativeLine
end
function IsSkillAbilityPassive() return nativePassive end
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua')
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuild.lua')
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSources.lua')
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildCodec.lua')
local C=SC.Catalog
local snapshot={classId=1,equipment={complete=false,slots={},setList={}},
    skills={known=true,primary={{slot=3,abilityId=900001,rank=1,lineId=35}},backup={},champion={}},
    masteries={known=true,eligible=true,selected={{id=263247,rank=1}},learnedIds={[700002]=2,[29430]=1}}}
local function Roundtrip(value)
    local body,reason=SC.BuildCodec.Encode(value)
    check(body~=nil,'Source facts encode without a wire change: '..tostring(reason))
    local result=SC.BuildCodec.Decode(body)
    check(result~=nil,'Source facts reconstruct through the actual codec')
    return result
end
for _,language in ipairs({'fr','de'}) do
    locale=language
    local direct=SC:DeriveBuildCapabilities(snapshot)
    local received=Roundtrip(snapshot)
    for _,key in ipairs({'major_berserk','major_protection','traumatic_burns'}) do
        check(direct[key] and received.capabilities[key],key..' survives sharing without an English name dictionary')
    end
    check(next(received.masteries.learned)==nil,'Coverage does not require transmitting display names')
end
nativeRank=1
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'Reported rank two cannot upgrade a rank-one native identity')
nativeRank=2;nativeLine=35
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'A matching texture in a different line cannot impersonate the prerequisite')
nativeLine=36;nativePassive=false
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'A combat bundle with the same image is not a learned passive')
nativePassive=true
local identityApi=GetSpecificSkillAbilityKeysByAbilityId
GetSpecificSkillAbilityKeysByAbilityId=nil
snapshot.masteries.learned={['the storm voice']=2}
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'Missing native definition API stays unknown rather than trusting a name')
GetSpecificSkillAbilityKeysByAbilityId=identityApi
snapshot.masteries.selected[1].id=999999;snapshot.masteries.selected[1].name='Lead From the Front'
iconQueries=0
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'A received mastery name cannot impersonate its native ID')
check(iconQueries==0,'Unrelated selected masteries do not scan native prerequisite textures')
snapshot.masteries.selected[1].id=263247
snapshot.masteries.learnedIds[29430]=nil;snapshot.masteries.learned['traumatic burns']=1
check(not SC:DeriveBuildCapabilities(snapshot).traumatic_burns,'A received passive name cannot impersonate learned Traumatic Burns')
snapshot.masteries.learnedIds[29430]=1

-- Legal recipe membership and exact script positions are independent of the
-- inspecting player's unlocks/recipe. Never query those personal APIs here.
function GetCraftedAbilityActiveScriptIds() error('Do not use the viewer recipe') end
function GetAbilityIdForCraftedAbilityId() error('Do not use the viewer effective Scribing ability') end
local grimoires={
    [100]='soulmagic1',[101]='soulmagic2',[102]='assault',[103]='staffresto',[104]='dualwield',
    [105]='magesguild',[106]='fightersguild',[107]='2handed',[108]='bow',[109]='staffdestro',[110]='1handed',
}
local definitions={
    [10]={1,'scribing_primary_magicka.dds'},[11]={1,'scribing_primary_healing.dds'},
    [12]={1,'scribing_primary_damageshield.dds'},[13]={1,'scribing_primary_resourcerestore.dds'},
    [20]={2,'scribing_secondary_classmod.dds'},[21]={2,'scribing_secondary_opportunism.dds'},
    [30]={3,'scribing_tertiary_breach.dds'},[31]={3,'scribing_tertiary_heroism.dds'},
    [32]={3,'scribing_tertiary_courage.dds'},[33]={3,'scribing_tertiary_protection.dds'},
    [34]={3,'scribing_tertiary_brittle.dds'},[35]={3,'scribing_tertiary_intellectendurance.dds'},
    [36]={3,'scribing_tertiary_vitality.dds'},[37]={3,'scribing_tertiary_berserk.dds'},
    [38]={3,'scribing_tertiary_force.dds'},[39]={3,'scribing_tertiary_cowardice.dds'},
}
local permitted={{10,11,12,13},{20,21},{30,31,32,33,34,35,36,37,38,39}}
local valid,disabled=true,false
function GetCraftedAbilityIcon(id) return grimoires[id] and '/esoui/art/icons/ability_grimoire_'..grimoires[id]..'.dds' end
function GetCraftedAbilityScriptScribingSlot(id) return definitions[id] and definitions[id][1] end
function GetCraftedAbilityScriptIcon(id) return definitions[id] and '/esoui/art/icons/'..definitions[id][2] end
function GetNumScriptsInSlotForCraftedAbility(_,slot) return #permitted[slot] end
function GetScriptIdAtSlotIndexForCraftedAbility(_,slot,index) return permitted[slot][index] end
function IsScribableScriptCombinationForCraftedAbility() return valid end
function IsCraftedAbilityScriptDisabled() return disabled end
function IsCraftedAbilityDisabled() return false end
local function Recipe(grimoire,focus,affix,signature)
    return {slot=3,abilityId=900001,boundAbilityId=grimoire,craftedAbilityId=grimoire,rank=1,
        scriptsKnown=true,scripts={{id=focus},{id=signature or 20},{id=affix}}}
end
local function Cap(grimoire,focus,affix,signature) return SC:DeriveScribingCapabilities(Recipe(grimoire,focus,affix,signature)) end
check(Cap(100,10,30).major_breach and not Cap(100,10,30).minor_breach,'Wield Soul applies Major Breach')
check(Cap(101,10,30).minor_breach and not Cap(101,10,30).major_breach,'Soul Burst applies Minor Breach from the same Affix')
check(not Cap(100,11,30).major_breach,'Healing an ally does not establish an enemy debuff')
check(not Cap(101,10,32).minor_courage,'Damage Focus does not turn personal Courage into an ally buff')
check(Cap(101,11,32).minor_courage,'Healing Soul Burst can apply the selected Courage to allies')
check(Cap(101,12,32).minor_courage and Cap(101,12,32).group_shield,'Shield Soul Burst separately supplies its shield and allied Affix')
check(not Cap(102,10,31).major_heroism and not Cap(102,10,31).minor_heroism,'Trample Heroism is personal, not Banner Heroism')
check(not Cap(102,10,33).major_protection,'Trample Protection stays personal')
check(Cap(103,13,31).minor_heroism,'Mender link grants its Heroism to allies even with Restore Resources Focus')
check(Cap(103,11,34).minor_brittle,'Mender link can debuff enemies crossing a healing link')
check(not Cap(104,10,37).minor_berserk and not Cap(104,10,38).minor_force,'Traveling Knife Berserk/Force remain caster-only')
check(Cap(104,10,39,21).warriors_opportunity,'Traveling Knife Signature supplies its unique Martial vulnerability')
check(not Cap(105,10,30,21).warriors_opportunity,'Same Signature on Ulfsild does not inherit Traveling Knife effect')
check(Cap(100,11,35).major_intellect and Cap(100,11,35).major_endurance,'Healing Wield Soul supplies both Major recoveries')
check(Cap(105,11,35).minor_intellect and not Cap(105,11,35).major_intellect,'Healing Ulfsild supplies Minor recoveries instead')
check(Cap(106,11,31).minor_heroism,'Healing Torchbearer grants allied Heroism')
check(Cap(107,12,36).minor_vitality,'Shield Smash grants allied Vitality')
check(Cap(108,11,37).minor_berserk,'Healing Vault grants allied Berserk')
check(Cap(109,10,34).minor_brittle,'Elemental Explosion supports its Brittle Affix')
check(Cap(110,10,39).major_cowardice,'Shield Throw Cowardice uses its actual Major tier')
check(next(Cap(999,10,30))==nil,'Unrecognized grimoire cannot establish coverage')
valid=false;check(next(Cap(101,11,32))==nil,'An illegal native combination stays unknown');valid=true
disabled=true;check(next(Cap(101,11,32))==nil,'A disabled native script stays unknown');disabled=false
local wrong=Recipe(101,11,32);wrong.scripts[3].id=11
check(next(SC:DeriveScribingCapabilities(wrong))==nil,'Duplicate or wrongly slotted scripts are rejected')
snapshot.skills.primary={Recipe(103,13,31)}
local received=Roundtrip(snapshot)
check(received.capabilities.minor_heroism and received.capabilities.minor_heroism.mainBar,
    'Exact Mender recipe reconstructs allied Heroism and its weapon bar after sharing')
for _,grimoire in pairs(C.scribingGrimoires) do
    for _,recipient in ipairs({'enemy','ally'}) do
        for _,keys in pairs(grimoire[recipient] or {}) do
            for _,key in ipairs(keys) do check(C.effects[key]~=nil,'Every Scribing source maps to a selectable effect') end
        end
    end
end
-- Shared line claims cannot override an ability's resolvable native definition.
-- These are synthetic identity fixtures, not a claim about a live ESO ability.
local lineSnapshot={classId=1,equipment={complete=false,slots={},setList={}},
    skills={known=true,primary={{slot=3,abilityId=900001,boundAbilityId=900001,rank=1,lineId=44}},backup={}},
    masteries={known=true,eligible=true,selected={{id=263587,rank=1}},learnedIds={[45215]=2}}}
local mismatched=Roundtrip(lineSnapshot)
check(mismatched.skills.primary[1].declaredLineId==44 and mismatched.skills.primary[1].lineId==nil
    and mismatched.skills.primary[1].lineIdentityEvidence=='CONTRADICTORY','Conflicting declared line stays distinct from native identity')
check(not mismatched.capabilities.minor_sorcery and not mismatched.capabilities.bright_harbinger,
    'A contradictory line cannot activate a learned passive or its mastery trigger')
lineSnapshot.skills.primary[1].abilityId=900002;lineSnapshot.skills.primary[1].boundAbilityId=900002
local matching=Roundtrip(lineSnapshot)
check(matching.skills.primary[1].lineId==44 and matching.skills.primary[1].lineIdentityEvidence=='NATIVE_DEFINITION',
    'A matching native line is retained independently of viewer purchases')
check(matching.capabilities.minor_sorcery and matching.capabilities.bright_harbinger,
    'Verified remote line permits the declared learned passive and mastery prerequisites')
lineSnapshot.skills.primary[1].lineId=nil
local withoutClaim=Roundtrip(lineSnapshot)
check(withoutClaim.skills.primary[1].lineId==44 and withoutClaim.skills.primary[1].declaredLineId==nil,
    'An omitted line can be resolved from the public native ability definition')
lineSnapshot.skills.primary[1].lineId=44
local savedIdentity=GetSpecificSkillAbilityKeysByAbilityId
GetSpecificSkillAbilityKeysByAbilityId=nil
local unresolved=Roundtrip(lineSnapshot)
check(unresolved.skills.primary[1].lineId==nil and unresolved.skills.primary[1].declaredLineId==44
    and unresolved.skills.primary[1].lineIdentityEvidence=='UNRESOLVED','Missing definition API preserves the claim without promoting it')
check(not unresolved.capabilities.minor_sorcery and not unresolved.capabilities.bright_harbinger,
    'Unavailable remote line definitions stay unknown instead of using the viewer build')
GetSpecificSkillAbilityKeysByAbilityId=savedIdentity
print('Source roundtrips: '..assertions..' assertions passed')
