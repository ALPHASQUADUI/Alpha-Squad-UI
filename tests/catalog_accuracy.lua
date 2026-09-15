-- Catalog identities and evidence boundaries. Synthetic API data is not in-game verification.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local SC={}
AlphaSquadUI={Modules={SupportCoverage=SC}}
local nativeNames={
    [115252]='Boneyard',[117805]='Unnerving Boneyard',[117850]='Avid Boneyard',
    [114860]='Blastbones',[117690]='Blighted Blastbones',[117749]="Grave Lord's Sacrifice",
    [17874]='Magma Shell',[17878]='Corrosive Armor',[26858]='Luminous Shards',[26869]='Blazing Spear',
    [32632]='Pounce',[32633]='Roar',[39113]='Ferocious Roar',[39114]='Deafening Roar',
    [263247]='Lead From the Front',[238232]='Inexorable Descent',[263554]="Veil's Forfeit",
}
function GetAbilityName(id) return nativeNames[id] or '' end
function SC.Try(fn,...) if type(fn)=='function' then local ok,a,b,c,d,e,f=pcall(fn,...);if ok then return a,b,c,d,e,f end end end
function SC:ScanEquipment() return {setList={},capabilities={},items={},complete=true} end
function SC:ScanPotion() return {known=false} end
function SC:ScanClassPassives() return {} end
function SC:IsChampionStarActive() return false end
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua')
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSources.lua')
dofile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageAudit.lua')
local C=SC.Catalog
local function has(id,key,name)
    for _,source in ipairs(C:FindSkillSources(id,name or GetAbilityName(id))) do
        for _,provided in ipairs(source.provides) do if provided==key then return true end end
    end
    return false
end
for _,id in ipairs({115252,117805,117850}) do check(has(id,'minor_vulnerability'),'Boneyard family provides Minor Vulnerability') end
for _,id in ipairs({114860,117690,117749}) do check(not has(id,'minor_vulnerability','Boneyard'),'Blastbones family cannot impersonate Boneyard') end
check(has(117805,'major_breach'),'Unnerving morph grants its separate Major Breach')
check(not has(115252,'major_breach'),'Base Boneyard does not inherit morph-exclusive Breach')
check(has(17874,'group_shield'),'Magma Shell is a group-shield source')
check(not has(17878,'group_shield','Magma Shell'),'Corrosive Armor cannot inherit Magma Shell shield')
check(has(26858,'resource_synergy'),'Luminous Shards has its correct ID')
local blazing=C:FindSkillSources(26869,'Luminous Shards')
check(#blazing==1 and blazing[1].label=='Blazing Spear','Native Blazing Spear is labelled accurately rather than another morph')
check(not has(32632,'feeding_frenzy','Roar'),'Pounce is not Roar')
check(has(32633,'feeding_frenzy') and has(39113,'major_courage'),'Actual Roar morphs carry their U50 group effects')
check(next(C:MatchSkillName('Not Magma Shell'))==nil,'Fragment names do not falsely match a skill')
local effectCount,setIds=0,{}
for key,effect in pairs(C.effects) do
    effectCount=effectCount+1
    check(effect.key==key and type(effect.description)=='string' and #effect.description>0,'Every effect has a stable key and readable description')
    check(type(C:GetEffectVisual(key).icon)=='string' and C:GetEffectVisual(key).icon~='','Every effect has a visible native/category icon')
end
check(effectCount==159,'Catalog retains all existing effect keys')
for _,kind in ipairs({'setSources','skillSources','passiveSources','masterySources','championSources'}) do
    for _,source in ipairs(C[kind]) do
        for _,key in ipairs(source.provides) do check(C.effects[key]~=nil,'No supplier references an unknown effect') end
        if source.setId then setIds[source.setId]=true end
    end
end
local count=0;for _ in pairs(setIds) do count=count+1 end
check(count==76,'All 76 verified set families remain available')
check(not C.effects.alkosh.penetration and not C.effects.crusher.penetration,'Variable enchant/set reduction is not hard-coded into the penetration budget')
check(not C.effects.major_intellect.personal and not C.effects.major_aegis.personal,'Real group aura providers are not misclassified as personal-only checks')
local snapshot={equipment={complete=true,setList={},items={}},skills={known=true,primary={},backup={},werewolfKnown=true,
    werewolf={{abilityId=39113,name='Ferocious Roar'}}},curse={known=true,kind='WEREWOLF',transformed=false}}
check(not SC:DeriveBuildCapabilities(snapshot).major_courage,'Inactive transformation bar does not establish a usable Roar')
snapshot.curse.transformed=true
local cap=SC:DeriveBuildCapabilities(snapshot)
check(cap.major_courage and cap.feeding_frenzy and cap.minor_force,'Current known transformation bar supplies its actual group capabilities')
check(not cap.major_courage.mainBar and not cap.major_courage.backBar,'Transformation does not pretend to be both normal weapon bars')
snapshot.skills.werewolfKnown=false
check(not SC:DeriveBuildCapabilities(snapshot).major_courage,'Unknown transformation skills do not supply a Roar')
snapshot.masteries={known=true,eligible=true,selected={{id=238232,name='Lead From the Front'}},learned={['the storm voice']=2}}
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'Inexorable Descent cannot impersonate Lead From the Front')
snapshot.masteries.selected={{id=263247,name='Lead From the Front'}}
snapshot.masteries.learned={};snapshot.masteries.learnedIds={[44951]=2}
check(not SC:DeriveBuildCapabilities(snapshot).major_berserk,'Elder Dragon rank 2 is not The Storm Voice prerequisite')
snapshot.masteries.learned={['the storm voice']=2}
check(SC:DeriveBuildCapabilities(snapshot).major_berserk,'Verified selected mastery and actual named prerequisite establish conditional source')
SCRIBING_SLOT_PRIMARY=1;SCRIBING_SLOT_SECONDARY=2;SCRIBING_SLOT_TERTIARY=3
local scriptDefs={
    [10]={1,'scribing_primary_flame.dds'},[11]={1,'scribing_primary_immobilized.dds'},
    [20]={2,'scribing_secondary_classmod.dds'},[30]={3,'scribing_tertiary_heroism.dds'},
    [31]={3,'scribing_tertiary_brutalitysorcery.dds'},
}
function GetCraftedAbilityScriptScribingSlot(id) return scriptDefs[id] and scriptDefs[id][1] end
function GetCraftedAbilityScriptIcon(id) return scriptDefs[id] and '/esoui/art/icons/'..scriptDefs[id][2] end
function GetCraftedAbilityIcon(id) return id==100 and '/esoui/art/icons/ability_grimoire_support.dds' or '/esoui/art/icons/ability_grimoire_trample.dds' end
local allowed={{10,11},{20},{30,31}}
function GetNumScriptsInSlotForCraftedAbility(_,slot) return #allowed[slot] end
function GetScriptIdAtSlotIndexForCraftedAbility(_,slot,index) return allowed[slot][index] end
local valid,disabled=true,false
function IsScribableScriptCombinationForCraftedAbility() return valid end
function IsCraftedAbilityScriptDisabled() return disabled end
function IsCraftedAbilityDisabled() return false end
local skill={craftedAbilityId=100,scriptsKnown=true,scripts={{id=10},{id=20},{id=30}}}
local scribed=SC:DeriveScribingCapabilities(skill)
check(scribed.banner_dot and scribed.minor_heroism,'Exact valid Banner recipe contributes the distinct Focus and group Affix')
check(not scribed.major_heroism and not scribed.major_force,'Scribing Class Mastery is not class passive mastery or Major Heroism')
skill.craftedAbilityId=101
check(next(SC:DeriveScribingCapabilities(skill))==nil,'Same Heroism Affix on another grimoire does not inherit Banner recipients')
skill.craftedAbilityId=100;skill.scripts[3].id=31
check(not SC:DeriveScribingCapabilities(skill).major_brutality_sorcery,'Personal Banner Affix does not become a group damage buff')
skill.scripts[1].id=11
check(not SC:DeriveScribingCapabilities(skill).group_cleanse,'Personal Immobilize Focus does not become group cleanse')
skill.scripts[1].id=10;skill.scripts[3].id=30;valid=false
check(next(SC:DeriveScribingCapabilities(skill))==nil,'Invalid native recipe cannot establish capability')
valid=true;disabled=true
check(next(SC:DeriveScribingCapabilities(skill))==nil,'Disabled script cannot establish capability')
disabled=false;skill.scripts[2].id=10
check(next(SC:DeriveScribingCapabilities(skill))==nil,'Duplicate or wrong-order scripts cannot establish capability')
local cyclic={};cyclic.self=cyclic
check(SC.Audit.Copy(cyclic).self==nil,'Snapshot copier terminates cyclic input')
print('catalog_accuracy: '..total..' assertions passed')
