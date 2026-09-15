-- Regression checks for exact character-sheet facts, not viewer-derived guesses.
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local names = {"EQUIP_SLOT_FEET","EQUIP_SLOT_LEGS","EQUIP_SLOT_WAIST","EQUIP_SLOT_HAND","EQUIP_SLOT_CHEST",
    "EQUIP_SLOT_SHOULDERS","EQUIP_SLOT_HEAD","EQUIP_SLOT_NECK","EQUIP_SLOT_RING1","EQUIP_SLOT_RING2",
    "EQUIP_SLOT_MAIN_HAND","EQUIP_SLOT_OFF_HAND","EQUIP_SLOT_BACKUP_MAIN","EQUIP_SLOT_BACKUP_OFF",
    "WEAPONTYPE_TWO_HANDED_SWORD","WEAPONTYPE_TWO_HANDED_AXE","WEAPONTYPE_TWO_HANDED_HAMMER","WEAPONTYPE_BOW",
    "WEAPONTYPE_FIRE_STAFF","WEAPONTYPE_FROST_STAFF","WEAPONTYPE_LIGHTNING_STAFF","WEAPONTYPE_HEALING_STAFF",
    "BAG_WORN","HOTBAR_CATEGORY_PRIMARY","HOTBAR_CATEGORY_BACKUP","HOTBAR_CATEGORY_CHAMPION","HOTBAR_CATEGORY_WEREWOLF",
    "CURSE_TYPE_NONE","CURSE_TYPE_VAMPIRE","CURSE_TYPE_WEREWOLF","SI_ITEMTRAITTYPE","ACTION_TYPE_ABILITY"}
for index,name in ipairs(names) do _G[name] = index end
ACTION_BAR_ULTIMATE_SLOT_INDEX = 7
local SC = {Catalog={effects={crusher={}},setSources={},masterySources={}}}
function SC.Catalog:MatchSkill() return {} end
AlphaSquadUI = {Modules={SupportCoverage=SC}}
local itemLink = "|H1:item:123:50:160:456:7:-1|hStaff|h"
local worn = {[EQUIP_SLOT_BACKUP_MAIN]=itemLink}
function GetItemLink(_,slot) return worn[slot] or "" end
function GetItemLinkName(link) return link == itemLink and "Exact staff" or "Unexpected item" end
function GetItemLinkIcon() return "staff.dds" end
function GetItemLinkSetInfo() return true,"Perfected Crushing Wall",1,2,2,101,0 end
function GetItemSetUnperfectedSetId(id) return id == 101 and 100 or nil end
function GetItemLinkWeaponType() return WEAPONTYPE_FROST_STAFF end
function GetItemLinkTraitInfo() return 4,"Increases weapon enchantment effect." end
function GetString(_,trait) return trait == 4 and "Infused" or "Wrong trait" end
local finalId,appliedId,defaultId = 456,456,999
function GetItemLinkFinalEnchantId() return finalId end
function GetItemLinkAppliedEnchantId() return appliedId end
function GetItemLinkDefaultEnchantId() return defaultId end
function GetItemLinkEnchantInfo() return true,"Crushing Enchantment","Reduces enemy resistances." end
function GetChargeInfoForItem() return 100,100 end
function IsItemAffectedByPairedPoison() return false end
function GetSlotBoundId() return 0 end
function GetAbilityName(id) return "Morph "..id end
function GetAbilityIcon(id) return "ability_"..id..".dds" end
function GetChampionAbilityId(id) return id + 9000 end
function GetChampionSkillName(id) return "Champion "..id end
local cpDescriptionPoints,cpBonusPoints
function GetChampionSkillDescription(_,points) cpDescriptionPoints=points;return "Allocation "..points end
function GetChampionSkillCurrentBonusText(_,points) cpBonusPoints=points;return "Bonus "..points end
function GetNumPointsSpentOnChampionSkill() return 50 end
function GetAbilityProgressionRankFromAbilityId() return 3 end
local skillDescriptionArgs
function GetAbilityDescription(id,rank,caster)
    skillDescriptionArgs={id,rank,caster};return "Exact skill description"
end
local curseType,transformed = CURSE_TYPE_NONE,false
function GetPlayerCurseType() return curseType end
function IsPlayerInWerewolfForm() return transformed end

dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageScanner.lua")
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuild.lua")
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSources.lua")
local item = SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,itemLink)
check(item.link == itemLink and item.name == "Exact staff", "The item link including applied enchant fields is preserved unchanged")
check(item.traitKnown and item.traitName == "Infused" and item.traitDescription:find("enchantment",1,true),
    "Trait name and description are read from the exact same equipped link")
check(item.enchantId == 456 and item.enchantName == "Crushing Enchantment", "Applied enchant identity and text agree")
finalId=0
item=SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,itemLink)
check(item.hasEnchant == false and item.enchantId == 0, "Final enchant zero cannot be replaced with the item's default glyph")
check(item.enchantName == "" and item.enchantDescription == "", "An absent enchant cannot display stale or unrelated enchant text")
finalId=nil; appliedId=456
check(SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,itemLink).enchantId == 456, "Applied enchant precedes default when final API is unavailable")
appliedId=0
check(SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,itemLink).enchantId == 999, "Confirmed no applied enchant permits the native default")
local nativeTrait=GetItemLinkTraitInfo
GetItemLinkTraitInfo=function() return 0/0,"Wrong trait description" end
item=SC:DescribeEquipmentItem(EQUIP_SLOT_BACKUP_MAIN,itemLink)
check(not item.traitKnown and item.traitName == "" and item.traitDescription == "", "Unreadable trait cannot display an unrelated name or description")
GetItemLinkTraitInfo=nativeTrait;finalId=456
local equipment=SC:ScanEquipment()
local set=equipment.setList[1]
check(set.id == 100 and set.physicalCount == 1 and set.backupItemCount == 1, "Perfected-family merging retains one physical arena staff")
check(set.mainCount == 0 and set.backCount == 2, "One physical two-handed weapon correctly contributes two back-bar set pieces")

local savedDiscipline=SC.GetChampionDiscipline
SC.GetChampionDiscipline=function() return "COMBAT" end
CHAMPION_DISCIPLINE_TYPE_COMBAT=1
function ZO_GetChampionBarDisciplineTextures(kind)
    assert(kind==CHAMPION_DISCIPLINE_TYPE_COMBAT)
    return {slotted="EsoUI/Art/Champion/ActionBar/champion_bar_combat_slotted.dds"}
end
local star=SC:DescribeChampionSkill(42,1,20,true)
check(star.points == 20 and star.pointsKnown and cpDescriptionPoints == 20 and cpBonusPoints == 20,
    "Champion tooltip uses the shared total allocation, not zero or the viewer's fifty points")
check(star.icon == "EsoUI/Art/Champion/ActionBar/champion_bar_combat_slotted.dds" and star.currentBonus == "Bonus 20", "Champion uses the native discipline slot texture and the correct invested bonus")
star=SC:DescribeChampionSkill(42,1,0,true)
check(star.points == 0 and star.description == "Allocation 0", "A known zero-point star remains distinguishable from unknown allocation")
cpDescriptionPoints=nil
star=SC:DescribeChampionSkill(42,1,nil,false)
check(star.points == nil and not star.pointsKnown and star.description == "" and cpDescriptionPoints == nil,
    "Unknown remote CP allocation never uses the inspecting player's allocation")
check(SC:DescribeChampionSkill(42,1,0/0,true).pointsKnown == false, "Non-finite Champion allocation stays unknown")

SC.GetChampionDiscipline=savedDiscipline

function GetSlotBoundId(slot,category)
    if category==HOTBAR_CATEGORY_CHAMPION then return slot==1 and 42 or 0 end
    if slot==3 then return category==HOTBAR_CATEGORY_PRIMARY and 1000 or category==HOTBAR_CATEGORY_BACKUP and 2000 or 3000 end
    if slot==8 then return category==HOTBAR_CATEGORY_PRIMARY and 1001 or category==HOTBAR_CATEGORY_BACKUP and 2001 or 3001 end
    return 0
end
function GetSlotType() return ACTION_TYPE_ABILITY end
function GetEffectiveAbilityIdForAbilityOnHotbar(id) return id+10 end
local skills=SC:ScanSkills()
check(skills.champion[1].points == 50 and skills.champion[1].description == "Allocation 50", "Local CP scan passes committed points to its description")
check(skills.primary[1].abilityId == 1010 and skills.primary[1].icon == "ability_1010.dds", "The displayed icon belongs to the effective slotted morph")
check(skills.primary[1].rank == 3 and skillDescriptionArgs[2] == 3 and skillDescriptionArgs[3] == "player",
    "Local skill descriptions use the exact rank and explicit native caster")
check(skills.primary[2].ultimate and skills.backup[2].ultimate and skills.primary[2].abilityId ~= skills.backup[2].abilityId,
    "Both bar ultimates remain distinct with their actual morph identities")
check(#skills.werewolf == 0 and not skills.werewolfKnown, "Non-werewolves cannot inherit a cached Werewolf bar")
check(SC:ScanCurse().kind == "NONE", "A native no-curse response is explicit")
curseType=CURSE_TYPE_VAMPIRE
local curse=SC:ScanCurse()
check(curse.kind == "VAMPIRE" and curse.stage == nil and curse.transformed == nil, "Vampire identity never invents a stage or Werewolf transformation")
curseType=CURSE_TYPE_WEREWOLF;transformed=false
curse=SC:ScanCurse();skills=SC:ScanSkills()
check(curse.kind == "WEREWOLF" and curse.transformed == false, "Werewolf curse does not imply the player is transformed")
check(skills.werewolfKnown and #skills.werewolf == 2 and skills.werewolf[1].bar == "WEREWOLF", "The actual Werewolf hotbar is captured separately")
check(skills.primary[1].abilityId == 1010 and skills.backup[1].abilityId == 2010,
    "Werewolf inspection never replaces either normal weapon bar")
transformed=true
check(SC:ScanCurse().transformed == true, "Active transformation comes from the native form API")
local nativeBound=GetSlotBoundId
GetSlotBoundId=function(slot,category) if category==HOTBAR_CATEGORY_WEREWOLF then return nil end;return nativeBound(slot,category) end
skills=SC:ScanSkills()
check(skills.known and not skills.werewolfKnown, "Unreadable alternate form cannot invalidate verified normal bars")
curseType=nil
check(not SC:ScanCurse().known and SC:ScanCurse().kind == nil, "Unavailable curse API remains unknown")
-- Deliberately reorder the native discipline ranges: no hard-coded 1-4 rule.
CHAMPION_DISCIPLINE_TYPE_COMBAT=1
CHAMPION_DISCIPLINE_TYPE_CONDITIONING=2
CHAMPION_DISCIPLINE_TYPE_WORLD=3
function GetAssignableChampionBarStartAndEndSlots() return 1,12 end
function GetRequiredChampionDisciplineIdForSlot(slot,category)
    assert(category == HOTBAR_CATEGORY_CHAMPION)
    return slot<=4 and 2 or slot<=8 and 1 or 3
end
function GetChampionDisciplineType(id) return id end
local layout=SC:GetChampionSlotLayout()
check(layout[1].discipline == "CONDITIONING" and layout[7].discipline == "COMBAT" and layout[7].index == 3,
    "Champion positions use the native required discipline and preserve preceding empty slots")
check(layout[12].discipline == "WORLD" and layout[12].index == 4, "All twelve native Champion positions remain individually addressable")
GetRequiredChampionDisciplineIdForSlot=function() return nil end
check(SC:GetChampionSlotLayout() == nil, "Unavailable slot layouts never create guessed Champion positions")
check(equipment.items[1].twoHanded == true, "A decoded native two-handed item can explain its occupied off hand")

-- Complete native-scanner to wire to native-link reconstruction round trip.
function GetItemLinkName(link) return link:find("item:123:50:160:456:7:-1",1,true) and "Exact staff" or "Unexpected item" end
SC.DeriveBuildCapabilities=nil -- This scenario verifies evidence, not catalog claims.
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildCodec.lua")
local body,err=SC.BuildCodec.Encode({classId=1,equipment=equipment,skills={primary={},backup={},champion={}},masteries={}})
check(body~=nil, "Actual native equipment can be encoded: "..tostring(err))
local decoded=SC.BuildCodec.Decode(body)
check(decoded~=nil, "Actual native equipment reconstructs through the shared codec")
local peerItem=decoded.equipment.items[1]
check(peerItem.link:match("|H%d+:item:([^|]+)|h") == itemLink:match("|H%d+:item:([^|]+)|h"),
    "Every signed numeric item-link field survives sharing unchanged")
check(peerItem.name == "Exact staff" and peerItem.traitName == "Infused"
    and peerItem.traitDescription == "Increases weapon enchantment effect.", "Shared trait name and description resolve from the exact received item")
check(peerItem.enchantId == 456 and peerItem.enchantName == "Crushing Enchantment"
    and peerItem.enchantDescription == "Reduces enemy resistances.", "Shared glyph identity and text resolve from the exact received item")
local peerSet=decoded.equipment.setList[1]
check(peerSet.physicalCountKnown and peerSet.physicalCount == 1 and peerSet.backCount == 2,
    "Full sharing preserves one physical arena staff and its two set-bonus pieces")
print("Build accuracy: "..checks.." assertions passed")
