-- Native build snapshots: independent bars, localized glyphs, Scribing and committed passives.
local total=0
local function check(value,message) total=total+1; assert(value,message) end
local constants={"EQUIP_SLOT_FEET","EQUIP_SLOT_LEGS","EQUIP_SLOT_WAIST","EQUIP_SLOT_HAND","EQUIP_SLOT_CHEST",
    "EQUIP_SLOT_SHOULDERS","EQUIP_SLOT_HEAD","EQUIP_SLOT_NECK","EQUIP_SLOT_RING1","EQUIP_SLOT_RING2",
    "EQUIP_SLOT_MAIN_HAND","EQUIP_SLOT_OFF_HAND","EQUIP_SLOT_BACKUP_MAIN","EQUIP_SLOT_BACKUP_OFF",
    "WEAPONTYPE_TWO_HANDED_SWORD","WEAPONTYPE_TWO_HANDED_AXE","WEAPONTYPE_TWO_HANDED_HAMMER","WEAPONTYPE_BOW",
    "WEAPONTYPE_FIRE_STAFF","WEAPONTYPE_FROST_STAFF","WEAPONTYPE_LIGHTNING_STAFF","WEAPONTYPE_HEALING_STAFF",
    "BAG_WORN","HOTBAR_CATEGORY_PRIMARY","HOTBAR_CATEGORY_BACKUP","HOTBAR_CATEGORY_CHAMPION",
    "HOTBAR_CATEGORY_QUICKSLOT_WHEEL","ACTION_TYPE_CRAFTED_ABILITY","ACTION_TYPE_ABILITY","SI_ITEMTRAITTYPE",
    "ENCHANTMENT_SEARCH_CATEGORY_REDUCE_ARMOR","ENCHANTMENT_SEARCH_CATEGORY_PRISMATIC_DEFENSE","SKILL_TYPE_CLASS"}
for index,name in ipairs(constants) do _G[name]=index end
ACTION_BAR_ULTIMATE_SLOT_INDEX=7
local Catalog={effects={major_courage={},crusher={},minor_sorcery={},major_heroism={}},
    setSources={{setId=10,requiredPieces=5,provides={"major_courage"}}},masterySources={}}
function Catalog:MatchSkill(id) return id==900 and {minor_sorcery=true} or {} end
local SC={Catalog=Catalog}
AlphaSquadUI={Modules={SupportCoverage=SC}}
local worn,items={},{}
function GetItemLink(_,slot) if worn[slot]==false then return nil end; return worn[slot] or "" end
function GetItemLinkName(link) return items[link].name end
function GetItemLinkIcon() return "item.dds" end
function GetItemLinkWeaponType(link) return items[link].weaponType or 0 end
function GetItemLinkArmorType() return 1 end
function GetItemLinkTraitInfo() return 4,"Translated trait description" end
function GetString(_,id) return id==4 and "Divines" or "" end
function GetItemLinkSetInfo(link)
    local item=items[link]
    return item.setId~=nil,item.setId and "Test Support Set" or "",1,99,12,item.setId,0
end
function GetItemLinkFinalEnchantId(link) return items[link].enchant or 0 end
function GetItemLinkDefaultEnchantId(link) return items[link].enchant or 0 end
function GetItemLinkEnchantInfo() return true,"Glyphe inconnu","Texte dans une autre langue" end
function GetEnchantSearchCategoryType(id)
    if id==1 then return ENCHANTMENT_SEARCH_CATEGORY_REDUCE_ARMOR end
    if id==2 then return ENCHANTMENT_SEARCH_CATEGORY_PRISMATIC_DEFENSE end
    return 0
end
function GetItemLinkNumEnchantCharges(link) return items[link].charges end
local poison=false
function IsItemAffectedByPairedPoison() return poison end
function GetItemLinkDisplayQuality() return 5 end
function GetItemLinkRequiredLevel() return 50 end
function GetItemLinkRequiredChampionPoints() return 160 end
function GetUnitClassId() return 1 end
function GetAbilityName(id) return "Ability "..id end
function GetAbilityDescription(id) return "Description "..id end
function GetAbilityIcon() return "ability.dds" end
function GetSkillLineNameById(id) return "Line "..id end
function GetSlotBoundId() return 0 end
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageScanner.lua")
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuild.lua")
local function Equip(slot,key,setId,weaponType,enchant,charges)
    worn[slot]=key
    items[key]={name=key,setId=setId,weaponType=weaponType,enchant=enchant,charges=charges}
end
Equip(EQUIP_SLOT_FEET,"Boots",10,nil,2)
Equip(EQUIP_SLOT_LEGS,"Legs",10,nil,2)
Equip(EQUIP_SLOT_WAIST,"Belt",10,nil,2)
Equip(EQUIP_SLOT_MAIN_HAND,"Front sword",10,1)
Equip(EQUIP_SLOT_BACKUP_MAIN,"Back sword",10,1)
local equipment=SC:ScanEquipment()
check(equipment.setList[1].mainCount==4 and equipment.setList[1].backCount==4,
    "Separate weapon bars may not combine into a fictitious five-piece bonus")
check(equipment.capabilities.major_courage==nil,"Server aggregate equipped count is not a bar-active proof")
Equip(EQUIP_SLOT_BACKUP_MAIN,"Back staff",10,WEAPONTYPE_FROST_STAFF,1,100)
equipment=SC:ScanEquipment()
check(equipment.setList[1].mainCount==4 and equipment.setList[1].backCount==5,"Two-handed weapons count as two on their own bar")
check(equipment.capabilities.major_courage and not equipment.capabilities.major_courage.mainBar
    and equipment.capabilities.major_courage.backBar,"A back-bar-only five-piece set provides its conditional capability")
check(#equipment.slots==14 and equipment.slots[1].slotName=="Feet" and equipment.slots[7].slotName=="Head",
    "Inspector retains all equipment positions in feet-to-head order")
check(equipment.slots[4].known and equipment.slots[4].empty and equipment.slots[4].item==nil,
    "Known empty armor is distinct from an unreadable slot")
check(equipment.items[1].traitName=="Divines" and equipment.items[1].setName=="Test Support Set",
    "Slot details expose human-readable trait and set names")
check(equipment.items[1].enchant=="prismatic","Prismatic glyphs use native categories on non-English clients")
check(equipment.capabilities.crusher and equipment.capabilities.crusher.backBar,"Localized Crusher is recognized natively on its bar")
items["Back staff"].charges=0
check(SC:ScanEquipment().capabilities.crusher==nil,"A depleted weapon enchant cannot prove Crusher readiness")
items["Back staff"].charges=100; poison=true
check(SC:ScanEquipment().capabilities.crusher==nil,"Paired poison suppresses the Crusher claim")
poison=false;items["Back staff"].charges=0
function GetChargeInfoForItem() return 80,100 end
check(SC:ScanEquipment().capabilities.crusher~=nil,"Current worn charge information takes priority over a stale item link")
GetChargeInfoForItem=nil; items["Back staff"].charges=100
poison=false; worn[EQUIP_SLOT_HAND]=false
equipment=SC:ScanEquipment()
check(not equipment.complete and not equipment.slots[4].known and not equipment.slots[4].empty,
    "Unavailable equipment is retained as unknown")
local calls=0
IsItemAffectedByPairedPoison=function() calls=calls+1; return true end
local decoded=SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,"Back staff")
check(calls==0 and decoded.enchantSuppressedByPoison==nil,
    "Describing a peer's item link never reads the receiver's worn poison state")
check(decoded.quality==5 and decoded.championPoints==160 and decoded.enchantName=="Glyphe inconnu",
    "Detailed item evidence includes quality, CP level and exact glyph text")
function GetItemLinkEquipType() return 42 end
function ZO_Character_DoesEquipSlotUseEquipType(slot,equipType) return slot==EQUIP_SLOT_BACKUP_MAIN and equipType==42 end
check(SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,"Back staff").equipSlotValid==true,
    "Item-link descriptions confirm compatible slots through the native equipment map")
check(SC:DescribeEquipmentItem(EQUIP_SLOT_HEAD,"Back staff").equipSlotValid==false,
    "A staff falsely assigned to the head slot is marked incompatible")
GetItemLinkEquipType=nil;ZO_Character_DoesEquipSlotUseEquipType=nil

local crafted=true
function GetSlotBoundId(slot,category)
    if slot==3 and category==HOTBAR_CATEGORY_PRIMARY then return crafted and 2 or 901 end
    return 0
end
function GetSlotType() return crafted and ACTION_TYPE_CRAFTED_ABILITY or ACTION_TYPE_ABILITY end
function GetAbilityIdForCraftedAbilityId(id) check(id==2,"Crafted slots bind grimoire IDs"); return 900 end
function GetCraftedAbilityActiveScriptIds() return 11,12,13 end
function GetCraftedAbilityScriptDisplayName(id) return "Script "..id end
function GetCraftedAbilityScriptDescription(_,id) return "Script effect "..id end
function GetSpecificSkillAbilityKeysByAbilityId() return SKILL_TYPE_CLASS,1,1 end
function GetSkillLineId() return 44 end
local skills=SC:ScanSkills()
check(skills.primary[1].abilityId==900 and skills.primary[1].boundAbilityId==2
    and skills.primary[1].craftedAbilityId==2,"Scribing resolves a grimoire into the actual ability ID")
check(skills.primary[1].scriptsKnown and #skills.primary[1].scripts==3
    and skills.primary[1].scripts[3].name=="Script 13","All three committed Scribing scripts are inspected")
check(skills.primary[1].lineId==44 and skills.primary[1].lineName=="Line 44","Slotted skills retain exact line provenance")
GetCraftedAbilityActiveScriptIds=function() return 11,nil,13 end
check(not SC:ScanSkills().primary[1].scriptsKnown,"An incomplete Scribing response is never marked complete")
GetAbilityIdForCraftedAbilityId=function() return nil end
local unavailable=SC:ScanSkills()
check(not unavailable.known and unavailable.primary[1].abilityId==0,"Unreadable grimoire conversion cannot masquerade as an ability")
crafted=false
function GetEffectiveAbilityIdForAbilityOnHotbar() return 900 end
check(SC:ScanSkills().primary[1].abilityId==900,"Ordinary hotbar overrides retain effective ability resolution")

Catalog.passiveSources={{name="Illuminate",abilityIds={31743},rank=1,skillLineIds={44},
    provides={"minor_sorcery"},conditions="Cast a Dawn's Wrath ability.",trigger="CAST_LINE"}}
local masteries={known=true,learnedIds={[31743]=1},learned={}}
local passives=SC:ScanClassPassives({primary={{lineId=44}},backup={}},masteries)
check(passives.minor_sorcery and passives.minor_sorcery.mainBar and not passives.minor_sorcery.backBar,
    "Learned class passive coverage requires a trigger on the appropriate bar")
check(passives.minor_sorcery.sourceDetails.Illuminate.conditions~=nil,"Passive capability includes explanatory provenance")
check(SC:ScanClassPassives({primary={},backup={}},masteries).minor_sorcery==nil,
    "A passive requiring a class-line skill cannot be inferred from class alone")
masteries.learnedIds[31743]=nil
check(SC:ScanClassPassives({primary={{lineId=44}}},masteries).minor_sorcery==nil,"Unpurchased passives provide no coverage")
masteries.learnedIds[31743]=1; masteries.known=false
check(SC:ScanClassPassives({primary={{lineId=44}}},masteries).minor_sorcery==nil,"Unreadable committed passive state stays unknown")

local nativeCount,activeCount,lineRank=3,3,50
local purchased={IsPurchased=function() return true end,IsPassive=function() return true end,
    GetCurrentRank=function() return 1 end,GetCurrentProgressionData=function()
        return {GetAbilityId=function() return 31743 end,GetName=function() return "Illuminate" end}
    end}
local lines={}
for index=1,3 do
    local lineIndex=index
    lines[index]={GetIndices=function() return SKILL_TYPE_CLASS,lineIndex end,
        GetClassId=function() return 1 end,GetId=function() return 40+lineIndex end,
        GetName=function() return "Class line" end,SkillIterator=function()
            local once=false
            return function() if not once then once=true; return 1,purchased end end
        end}
end
local classType={SkillLineIterator=function()
    local index=0; return function() index=index+1; if lines[index] then return index,lines[index] end end
end}
SKILLS_DATA_MANAGER={GetSkillTypeData=function() return classType end,
    GetNumPlayerClassActiveSkillLines=function() return nativeCount end,
    GetNumActiveClassSkillLines=function() return activeCount end}
function GetSkillLineDynamicInfo() return lineRank,false,true,true,false,false,false end
function HasMaxRankInAllClassSkillLines() return true end
local classScan=SC:ScanClassMasteries()
check(classScan.known and classScan.eligible and #classScan.skillLines==3 and #classScan.passives==3,
    "Committed class lines and purchased passive details are captured")
nativeCount=0;activeCount=0
check(SC:ScanClassMasteries().eligible==false,"Zero-equals-zero class counts cannot imply pure-class mastery eligibility")
nativeCount=2;activeCount=3
check(SC:ScanClassMasteries().eligible==false,"Subclassing disables native class masteries")
nativeCount=3;activeCount=3;lineRank=0/0
check(SC:ScanClassMasteries().known==false,"Non-finite skill-line ranks remain unknown")

LFDB_BUFF_TYPE_NONE=0
LibFoodDrinkBuff={GetFoodBuffInfos=function(_,unitTag)
    if unitTag=="group2" then return 1,false,123,"Group food",0,2000,"food.dds" end
    return LFDB_BUFF_TYPE_NONE
end}
check(SC:ScanFood("group2").verified,"Recognized native group food can be seen without a build sender")
check(not SC:ScanFood("group3").verified,"No visible remote food does not prove that the player has none")
check(SC:ScanFood("player").verified and not SC:ScanFood("player").active,"A local library-confirmed missing food is explicit")
SC.sv={roleOverrides=true}
check(SC:GetRoleHint("player",{})=="UNKNOWN","Legacy role overrides do not override native group facts or break the scanner")
local refreshed=0
function SC:ScheduleRefresh() refreshed=refreshed+1 end
SC:OnConsumableUsed(); SC.inCombat=true; SC:OnConsumableUsed()
check(refreshed==1 and SC.SamplePotionEvidence==nil,"Consumables trigger readiness only, without combat reports")
print("Scanner details: "..total.." assertions passed")
