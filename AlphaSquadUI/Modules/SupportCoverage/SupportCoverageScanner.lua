-- Ąlpha Şquad UI - Support Coverage local/limited scanners

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local MAX_INTEGER_ID = 2147483647

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h, i, j, k, l, m, n
end

local function FiniteNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function Integer(value, minimum, maximum)
    value = FiniteNumber(value)
    if not value or value % 1 ~= 0 or value < minimum or value > maximum then return nil end
    return value
end

local function Count(value, maximum)
    value = FiniteNumber(value)
    if not value then return 0 end
    return math.floor(math.max(0, math.min(maximum, value)))
end

local function Normalize(value)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.Normalize then
        return AlphaSquadUI.Utils.Normalize(value)
    end
    return string.lower(tostring(value or ""))
end

local EQUIP_SLOTS, SLOT_DETAILS = {}, {}
for order, definition in ipairs({
    {"FEET", "Feet"}, {"LEGS", "Legs"}, {"WAIST", "Waist"}, {"HAND", "Hands"},
    {"CHEST", "Chest"}, {"SHOULDERS", "Shoulders"}, {"HEAD", "Head"},
    {"NECK", "Necklace"}, {"RING1", "Ring 1"}, {"RING2", "Ring 2"},
    {"MAIN_HAND", "Front bar main hand", "PRIMARY"}, {"OFF_HAND", "Front bar off hand", "PRIMARY"},
    {"BACKUP_MAIN", "Back bar main hand", "BACKUP"}, {"BACKUP_OFF", "Back bar off hand", "BACKUP"},
}) do
    local slot = rawget(_G, "EQUIP_SLOT_" .. definition[1])
    if slot ~= nil then
        EQUIP_SLOTS[#EQUIP_SLOTS + 1] = slot
        SLOT_DETAILS[slot] = {slot=slot, slotKey=definition[1], slotName=definition[2],
            order=order, bar=definition[3] or "BOTH"}
    end
end
SC.EquipmentSlotOrder = EQUIP_SLOTS
SC.EquipmentSlotDetails = SLOT_DETAILS

local ARMOR_SLOTS = {}
for _, value in ipairs({
    EQUIP_SLOT_HEAD, EQUIP_SLOT_CHEST, EQUIP_SLOT_SHOULDERS, EQUIP_SLOT_WAIST,
    EQUIP_SLOT_HAND, EQUIP_SLOT_LEGS, EQUIP_SLOT_FEET,
}) do
    if value ~= nil then ARMOR_SLOTS[value] = true end
end

local function AddCapability(target, key, source)
    if not key or not Catalog or not Catalog.effects[key] then return end
    target[key] = target[key] or {sources = {}}
    if source and source ~= "" then
        target[key].sources[source] = true
    end
end

local function GetLink(slot)
    if not GetItemLink or BAG_WORN == nil then return nil end
    local link = SafeCall(GetItemLink, BAG_WORN, slot, LINK_STYLE_DEFAULT or 0)
    return link ~= nil and tostring(link) or nil
end

local function ClassifyEnchant(header, description, enchantId)
    -- Native categories are language independent, unlike translated glyph text.
    local category = enchantId and SafeCall(GetEnchantSearchCategoryType, enchantId)
    if category ~= nil then
        local categories = {
            PRISMATIC_DEFENSE="prismatic", REDUCE_ARMOR="crusher", REDUCE_POWER="weakening", MAGICKA="magicka",
            STAMINA="stamina", HEALTH="health", BERSERKER="weapon_spell_damage",
            HEALTH_REGEN="recovery", MAGICKA_REGEN="recovery", STAMINA_REGEN="recovery",
            PRISMATIC_REGEN="recovery",
        }
        for suffix, kind in pairs(categories) do
            if category == rawget(_G, "ENCHANTMENT_SEARCH_CATEGORY_" .. suffix) then return kind end
        end
    end
    local text = Normalize((header or "") .. " " .. (description or ""))

    local patterns = {
        prismatic = {"prismatic", "multi-effect", "tri-stat", "tristat", "hakeijo"},
        magicka = {"maximum magicka", "max magicka"},
        stamina = {"maximum stamina", "max stamina"},
        health = {"maximum health", "max health"},
        crusher = {"crushing", "crusher", "reduce the target's physical and spell resistance"},
        weakening = {"weakening"},
        weapon_spell_damage = {"weapon and spell damage"},
        recovery = {"recovery", "regeneration"},
    }

    for _, kind in ipairs({"prismatic","crusher","weakening","magicka","stamina","health","weapon_spell_damage","recovery"}) do
        local list=patterns[kind]
        for _, token in ipairs(list) do
            if text:find(Normalize(token), 1, true) then return kind end
        end
    end
    return text ~= "" and "other" or "unknown"
end

function SC:IsTwoHandedWeapon(item)
    if type(item) ~= "table" or not item.isWeapon then return false end
    if item.weaponType == nil then return nil end
    for _, kind in ipairs({"TWO_HANDED_SWORD", "TWO_HANDED_AXE", "TWO_HANDED_HAMMER", "BOW",
        "FIRE_STAFF", "FROST_STAFF", "LIGHTNING_STAFF", "HEALING_STAFF"}) do
        local nativeType = rawget(_G, "WEAPONTYPE_" .. kind)
        if nativeType ~= nil and item.weaponType == nativeType then return true end
    end
    return false
end

function SC:DescribeEquipmentItem(slot, link)
    if type(link) ~= "string" or link == "" then return nil end
    local descriptor = SLOT_DETAILS[slot] or {slot=slot, slotName="Equipment", bar="BOTH", order=99}
    local trait, traitDescription = SafeCall(GetItemLinkTraitInfo, link)
    trait = Integer(trait, 0, 255)
    local traitName = trait and SafeCall(GetString, SI_ITEMTRAITTYPE, trait) or nil
    local traitKnown = trait ~= nil and type(traitDescription) == "string"
    local hasSet, setName, _, normalEquipped, maxEquipped, setId, perfectedEquipped = SafeCall(GetItemLinkSetInfo, link, false)
    local hasCharges, enchantName, enchantDescription = SafeCall(GetItemLinkEnchantInfo, link)
    local enchantId = Integer(SafeCall(GetItemLinkFinalEnchantId, link), 0, MAX_INTEGER_ID)
    if enchantId == nil then
        -- A final ID of zero explicitly means no enchantment. Only resolve the
        -- applied/default chain when the final-enchant API could not answer.
        local appliedId = Integer(SafeCall(GetItemLinkAppliedEnchantId, link), 0, MAX_INTEGER_ID)
        if appliedId and appliedId > 0 then enchantId = appliedId
        elseif appliedId == 0 then
            enchantId = Integer(SafeCall(GetItemLinkDefaultEnchantId, link), 0, MAX_INTEGER_ID)
        end
    end
    local hasEnchant
    if enchantId ~= nil then hasEnchant = enchantId > 0
    elseif tostring(enchantName or "") ~= "" or tostring(enchantDescription or "") ~= "" then hasEnchant = true end
    if hasEnchant == false then enchantName, enchantDescription = "", "" end
    local item = {
        slot=slot, slotKey=descriptor.slotKey, slotName=descriptor.slotName, order=descriptor.order,
        bar=descriptor.bar, link=link, name=tostring(SafeCall(GetItemLinkName, link) or ""),
        icon=tostring(SafeCall(GetItemLinkIcon, link) or ""), setName=tostring(setName or ""),
        hasSet=hasSet, setVerified=type(hasSet) == "boolean", setNormalEquipped=Count(normalEquipped, 24),
        setMaxEquipped=Count(maxEquipped, 24), setPerfectedEquipped=Count(perfectedEquipped, 24),
        setId=Integer(setId, 1, MAX_INTEGER_ID), trait=trait,
        traitKnown=traitKnown, traitName=trait and tostring(traitName or "") or "",
        traitDescription=traitKnown and traitDescription or "",
        armorType=SafeCall(GetItemLinkArmorType, link), weaponType=SafeCall(GetItemLinkWeaponType, link),
        quality=Integer(SafeCall(GetItemLinkDisplayQuality, link), 0, 16),
        level=Integer(SafeCall(GetItemLinkRequiredLevel, link), 0, 100),
        championPoints=Integer(SafeCall(GetItemLinkRequiredChampionPoints, link), 0, 3600),
        enchantId=enchantId, hasEnchant=hasEnchant, enchantHasCharges=hasCharges,
        enchantTextKnown=hasEnchant ~= nil and type(enchantName) == "string" and type(enchantDescription) == "string",
        enchantName=tostring(enchantName or ""), enchantDescription=tostring(enchantDescription or ""),
        isArmor=ARMOR_SLOTS[slot] == true, isWeapon=descriptor.bar ~= "BOTH",
    }
    item.twoHanded = self:IsTwoHandedWeapon(item)
    if hasEnchant == nil then item.enchant = "unknown"
    elseif not hasEnchant then item.enchant = "missing"
    else item.enchant = ClassifyEnchant(enchantName, enchantDescription, enchantId) end
    return item
end

function SC:ScanEquipment()
    local snapshot = {
        complete = GetItemLink ~= nil and GetItemLinkSetInfo ~= nil,
        sets = {},
        setList = {},
        items = {},
        slots = {},
        glyphs = {
            armorTotal = 0,
            armorMissing = 0,
            prismatic = 0,
            magicka = 0,
            stamina = 0,
            health = 0,
            other = 0,
            crusher = 0,
        },
        capabilities = {},
    }

    local setSeen = {}

    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetLink(slot)
        local descriptor = SLOT_DETAILS[slot]
        local state = {slot=slot, slotKey=descriptor.slotKey, slotName=descriptor.slotName,
            order=descriptor.order, bar=descriptor.bar, known=link ~= nil, empty=link == ""}
        snapshot.slots[#snapshot.slots + 1] = state
        if link == nil then
            snapshot.complete = false
            snapshot.glyphs.unknown = (snapshot.glyphs.unknown or 0) + (ARMOR_SLOTS[slot] and 1 or 0)
        elseif link ~= "" then
            local item = self:DescribeEquipmentItem(slot, link)
            state.item = item

            local hasSet, setName, setId = item.hasSet, item.setName, item.setId
            if not item.setVerified then snapshot.complete = false end
            if hasSet and setName and setName ~= "" then
                local numericSetId = Integer(setId, 1, MAX_INTEGER_ID) or 0
                local setKey = numericSetId > 0 and tostring(numericSetId) or "name:" .. Normalize(setName)
                if not setSeen[setKey] then
                    local entry = {
                        id = numericSetId,
                        name = setName,
                        equipped = item.setNormalEquipped,
                        perfected = item.setPerfectedEquipped,
                        maxEquipped = item.setMaxEquipped,
                        mainCount = 0, backCount = 0,
                        physicalCount = 0, bodyItemCount = 0, primaryItemCount = 0, backupItemCount = 0,
                    }
                    snapshot.sets[setKey] = entry
                    snapshot.setList[#snapshot.setList + 1] = entry
                    setSeen[setKey] = true


                end
            end

            if hasSet and setName and setName ~= "" then
                local numericSetId = Integer(setId, 1, MAX_INTEGER_ID) or 0
                local setKey = numericSetId > 0 and tostring(numericSetId) or "name:" .. Normalize(setName)
                item.setId = numericSetId > 0 and numericSetId or nil
                local set = snapshot.sets[setKey]
                local twoHanded = item.twoHanded == true
                local pieces = twoHanded and 2 or 1
                local mainOnly = slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND
                local backOnly = slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF
                if not backOnly then set.mainCount = set.mainCount + pieces end
                if not mainOnly then set.backCount = set.backCount + pieces end
                set.physicalCount = set.physicalCount + 1
                if mainOnly then set.primaryItemCount = set.primaryItemCount + 1
                elseif backOnly then set.backupItemCount = set.backupItemCount + 1
                else set.bodyItemCount = set.bodyItemCount + 1 end
            end

            if item.isWeapon then
                item.enchantCharges = Integer(SafeCall(GetChargeInfoForItem, BAG_WORN, slot), 0, 1000000)
                if item.enchantCharges == nil then
                    item.enchantCharges = Integer(SafeCall(GetItemLinkNumEnchantCharges, link), 0, 1000000)
                end
                if item.enchantCharges and item.enchantCharges > 0 then item.enchantHasCharges = true end
                if item.enchantCharges == 0 then item.enchantHasCharges = false end
                -- This API refers to our worn slots and must never be called while decoding a peer's links.
                item.enchantSuppressedByPoison = SafeCall(IsItemAffectedByPairedPoison, slot)
            end

            if ARMOR_SLOTS[slot] then
                snapshot.glyphs.armorTotal = snapshot.glyphs.armorTotal + 1
                if item.hasEnchant == nil then
                    snapshot.glyphs.unknown = (snapshot.glyphs.unknown or 0) + 1
                elseif item.hasEnchant == false then
                    snapshot.glyphs.armorMissing = snapshot.glyphs.armorMissing + 1
                elseif snapshot.glyphs[item.enchant] ~= nil then
                    snapshot.glyphs[item.enchant] = snapshot.glyphs[item.enchant] + 1
                else
                    snapshot.glyphs.other = snapshot.glyphs.other + 1
                end
            elseif item.isWeapon and item.enchant == "crusher" and item.enchantHasCharges ~= false
                and item.enchantSuppressedByPoison ~= true then
                snapshot.glyphs.crusher = snapshot.glyphs.crusher + 1
                AddCapability(snapshot.capabilities, "crusher", "Crusher Enchantment")
                local capability = snapshot.capabilities.crusher
                capability.conditional, capability.evidence = true, "EQUIPPED_ENCHANT"
                capability.mainBar = capability.mainBar or item.bar == "PRIMARY"
                capability.backBar = capability.backBar or item.bar == "BACKUP"
                capability.sourceDetails = capability.sourceDetails or {}
                capability.sourceDetails["Crusher Enchantment (" .. item.slotName .. ")"] = {name="Crusher Enchantment",
                    kind="enchant", slot=slot, slotName=item.slotName, mainBar=item.bar == "PRIMARY",
                    backBar=item.bar == "BACKUP", conditions="Requires a charged weapon enchantment without paired poison."}
            end

            snapshot.items[#snapshot.items + 1] = item
        elseif ARMOR_SLOTS[slot] then
            snapshot.glyphs.armorTotal = snapshot.glyphs.armorTotal + 1
            snapshot.glyphs.armorMissing = snapshot.glyphs.armorMissing + 1
        end
    end

    snapshot.glyphs.verified = (snapshot.glyphs.unknown or 0) == 0
        and snapshot.glyphs.armorTotal == 7

    for _, set in ipairs(snapshot.setList) do
        set.activeOnMain, set.activeOnBack = false, false
        for _, source in ipairs(Catalog and Catalog.setSources or {}) do
            local identityMatch = source.setId and set.id == source.setId
            local nameHint = not source.setId and Normalize(set.name):find(Normalize(source.token), 1, true)
            if identityMatch or nameHint then
                local required = tonumber(source.requiredPieces) or 5
                local main, back = set.mainCount >= required, set.backCount >= required
                set.activeOnMain = set.activeOnMain or main
                set.activeOnBack = set.activeOnBack or back
                if main or back then
                    for _, key in ipairs(source.provides) do
                        AddCapability(snapshot.capabilities, key, set.name)
                        local cap = snapshot.capabilities[key]
                        cap.evidence = identityMatch and "SET_ID" or "SET_NAME_HINT"
                        cap.mainBar, cap.backBar = main, back
                    end
                end
            end
        end
    end

    table.sort(snapshot.setList, function(a, b)
        return Normalize(a.name) < Normalize(b.name)
    end)

    return snapshot
end

-- Champion descriptions accept the total points to preview, despite the API
-- argument's name "numPendingPoints". Never substitute the inspecting player's
-- allocation for a peer's shared points (see ESO championdatamanager.lua).
function SC:DescribeChampionSkill(id, slot, points, pointsKnown)
    id = Integer(id, 1, MAX_INTEGER_ID)
    if not id then return nil end
    points = Integer(points, 0, 3600)
    pointsKnown = pointsKnown ~= false and points ~= nil
    local abilityId = Integer(SafeCall(GetChampionAbilityId, id), 1, MAX_INTEGER_ID)
    return {id=id, slot=slot, points=pointsKnown and points or nil, pointsKnown=pointsKnown,
        discipline=self.GetChampionDiscipline and self:GetChampionDiscipline(id),
        name=tostring(SafeCall(GetChampionSkillName, id) or ""), abilityId=abilityId,
        icon=abilityId and tostring(SafeCall(GetAbilityIcon, abilityId) or "") or "",
        description=pointsKnown and tostring(SafeCall(GetChampionSkillDescription, id, points) or "") or "",
        currentBonus=pointsKnown and tostring(SafeCall(GetChampionSkillCurrentBonusText, id, points) or "") or ""}
end

function SC:ScanSkills()
    local result = {
        primary = {},
        backup = {},
        werewolf = {}, werewolfKnown = false,
        champion = {},
        championKnown = HOTBAR_CATEGORY_CHAMPION ~= nil and GetSlotBoundId ~= nil,
        known = GetSlotBoundId ~= nil and HOTBAR_CATEGORY_PRIMARY ~= nil and HOTBAR_CATEGORY_BACKUP ~= nil,
        capabilities = {},
    }

    local ultimateBase = ACTION_BAR_ULTIMATE_SLOT_INDEX or 7
    local ultimateSlot = ultimateBase + 1
    local categories = {
        primary = HOTBAR_CATEGORY_PRIMARY,
        backup = HOTBAR_CATEGORY_BACKUP,
    }
    local curse = self.ScanCurse and self:ScanCurse() or {}
    if curse.known and curse.kind == "WEREWOLF" and HOTBAR_CATEGORY_WEREWOLF ~= nil then
        categories.werewolf = HOTBAR_CATEGORY_WEREWOLF
        result.werewolfKnown = GetSlotBoundId ~= nil
    end

    for key, category in pairs(categories) do
        if category ~= nil then
            for slot = 3, ultimateSlot do
                local boundId = SafeCall(GetSlotBoundId, slot, category)
                local validBoundId = Integer(boundId, 0, MAX_INTEGER_ID)
                if validBoundId == nil then
                    if key == "werewolf" then result.werewolfKnown = false else result.known = false end
                end
                boundId = validBoundId or 0
                if boundId > 0 then
                    local effectiveId = boundId
                    local slotType = SafeCall(GetSlotType, slot, category)
                    local crafted = ACTION_TYPE_CRAFTED_ABILITY ~= nil and slotType == ACTION_TYPE_CRAFTED_ABILITY
                    local craftedId = crafted and boundId or nil
                    if crafted then
                        -- Crafted slots bind a grimoire ID, not an ability ID.
                        effectiveId = Integer(SafeCall(GetAbilityIdForCraftedAbilityId, craftedId), 1, MAX_INTEGER_ID)
                        if not effectiveId then
                            if key == "werewolf" then result.werewolfKnown = false else result.known = false end
                        end
                    elseif GetEffectiveAbilityIdForAbilityOnHotbar then
                        local resolved = SafeCall(GetEffectiveAbilityIdForAbilityOnHotbar, boundId, category)
                        resolved = Integer(resolved, 1, MAX_INTEGER_ID)
                        if resolved then effectiveId = resolved end
                    end

                    local name = SafeCall(GetSlotName, slot, category)
                    if not name or name == "" then name = SafeCall(GetAbilityName, effectiveId or 0) or "" end
                    local icon = crafted and SafeCall(GetSlotTexture, slot, category)
                        or SafeCall(GetAbilityIcon, effectiveId or 0)
                    if not icon or icon == "" then icon = SafeCall(GetSlotTexture, slot, category) or "" end
                    local rank = Integer(SafeCall(GetAbilityProgressionRankFromAbilityId, effectiveId or 0), 1, 100)
                    local entry = {
                        slot = slot,
                        boundAbilityId = boundId,
                        abilityId = effectiveId or 0,
                        name = tostring(name or ""),
                        icon = tostring(icon or ""),
                        ultimate = slot == ultimateSlot,
                        bar = key == "primary" and "PRIMARY" or key == "backup" and "BACKUP" or "WEREWOLF",
                        rank = rank,
                        description = tostring(SafeCall(GetAbilityDescription, effectiveId or 0, rank, "player") or ""),
                        craftedAbilityId = craftedId,
                    }
                    local skillType, lineIndex = SafeCall(GetSpecificSkillAbilityKeysByAbilityId, effectiveId or 0)
                    if skillType and lineIndex then
                        entry.lineId = Integer(SafeCall(GetSkillLineId, skillType, lineIndex), 1, MAX_INTEGER_ID)
                        entry.lineName = tostring(SafeCall(GetSkillLineNameById, entry.lineId or 0) or "")
                    end
                    if crafted then
                        local first, second, third = SafeCall(GetCraftedAbilityActiveScriptIds, craftedId)
                        entry.scripts, entry.scriptsKnown = {}, true
                        for _, scriptId in ipairs({first or false, second or false, third or false}) do
                            scriptId = Integer(scriptId, 1, MAX_INTEGER_ID)
                            if scriptId then
                                entry.scripts[#entry.scripts + 1] = {id=scriptId,
                                    name=tostring(SafeCall(GetCraftedAbilityScriptDisplayName, scriptId) or ""),
                                    description=tostring(SafeCall(GetCraftedAbilityScriptDescription, craftedId, scriptId) or "")}
                            else entry.scriptsKnown = false end
                        end
                    end
                    result[key][#result[key] + 1] = entry

                    -- The alternate form is an inspected bar, not proof that its
                    -- sources are available on either normal weapon bar.
                    if Catalog and key ~= "werewolf" then
                        local matched = Catalog:MatchSkill(entry.abilityId, entry.name)
                        if not crafted and entry.boundAbilityId ~= entry.abilityId then
                            for capability in pairs(Catalog:MatchSkill(entry.boundAbilityId, entry.name)) do
                                matched[capability] = true
                            end
                        end
                        for capability in pairs(matched) do
                            AddCapability(result.capabilities, capability, entry.name)
                            local cap = result.capabilities[capability]
                            cap.mainBar = cap.mainBar or key == "primary"
                            cap.backBar = cap.backBar or key == "backup"
                            cap.conditional, cap.evidence = true, "SLOTTED_SKILL"
                        end
                    end
                end
            end
        end
    end

    if HOTBAR_CATEGORY_CHAMPION ~= nil and GetSlotBoundId then
        local startSlot, endSlot = 1, 12
        if GetAssignableChampionBarStartAndEndSlots then
            local a, b = SafeCall(GetAssignableChampionBarStartAndEndSlots)
            a, b = Integer(a, 1, 64), Integer(b, 1, 64)
            if a and b and a <= b and b - a <= 23 then startSlot, endSlot = a, b
            else result.championKnown = false end
        end

        for slot = startSlot, endSlot do
            local starId = SafeCall(GetSlotBoundId, slot, HOTBAR_CATEGORY_CHAMPION)
            if starId == nil then result.championKnown = false end
            local validStarId = Integer(starId, 0, MAX_INTEGER_ID)
            if validStarId == nil then result.championKnown = false end
            starId = validStarId or 0
            if starId > 0 then
                local points = Integer(SafeCall(GetNumPointsSpentOnChampionSkill, starId), 0, 3600)
                result.champion[#result.champion + 1] = self:DescribeChampionSkill(starId, slot, points, points ~= nil)
            end
        end
    end

    return result
end

function SC:ScanFood(unitTag)
    unitTag = unitTag or "player"

    local lib = rawget(_G, "LibFoodDrinkBuff") or rawget(_G, "LIB_FOOD_DRINK_BUFF")
    if lib and type(lib.GetFoodBuffInfos) == "function" then
        local buffType, isDrink, abilityId, buffName, timeStarted, timeEnds, icon =
            SafeCall(lib.GetFoodBuffInfos, lib, unitTag)
        if unitTag == "player" and LFDB_BUFF_TYPE_NONE ~= nil and buffType == LFDB_BUFF_TYPE_NONE then
            return {active=false, verified=true, source="LibFoodDrinkBuff"}
        end
        abilityId = Integer(abilityId, 1, MAX_INTEGER_ID)
        if abilityId then
            return {
                active = true,
                verified = true,
                source = "LibFoodDrinkBuff",
                abilityId = abilityId,
                name = tostring(buffName or ""),
                isDrink = isDrink == true,
                timeStarted = FiniteNumber(timeStarted) or 0,
                timeEnds = FiniteNumber(timeEnds) or 0,
                icon = tostring(icon or ""),
            }
        end
    end

    -- Local fallback heuristic adapted from the same public ESO buff information
    -- used by food-reminder addons. Remote fallback is intentionally conservative.
    if unitTag ~= "player" or not GetNumBuffs or not GetUnitBuffInfo then
        return {active=false, verified=false, source="unknown"}
    end

    local now = GetGameTimeMilliseconds and GetGameTimeMilliseconds() / 1000 or 0
    local count = tonumber(SafeCall(GetNumBuffs, unitTag))
    if not count or count~=count or count==math.huge or count==-math.huge then
        return {active=false, verified=false, source="ESO heuristic"}
    end
    count = math.max(0, math.min(256, math.floor(count)))
    for i = 1, count do
        local name, started, ending, _, _, icon, _, _, _, _, abilityId, canClickOff =
            SafeCall(GetUnitBuffInfo, unitTag, i)
        started, ending = FiniteNumber(started), FiniteNumber(ending)
        local duration = started and ending and ending - started or 0
        if canClickOff and duration >= 1800 and ending > now then
            return {
                active = true,
                verified = false,
                source = "ESO heuristic",
                abilityId = Integer(abilityId, 1, MAX_INTEGER_ID) or 0,
                name = tostring(name or ""),
                isDrink = false,
                timeStarted = started or 0,
                timeEnds = ending or 0,
                icon = tostring(icon or ""),
            }
        end
    end

    return {active=false, verified=false, source="ESO heuristic"}
end

function SC:ScanPotion()
    local result = {
        known=false, selectionKnown=false, isPotion=false, name="", itemId=0,
        effects="", link=nil, cooldownRemaining=nil,
    }
    if not GetCurrentQuickslot or not GetSlotItemLink then return result end

    local slot = Integer(SafeCall(GetCurrentQuickslot), 1, 64)
    if not slot then return result end
    result.slot = slot

    local link = SafeCall(GetSlotItemLink, slot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    if link == nil then return result end
    link = tostring(link)
    if link == "" then
        result.selectionKnown = true
        result.evidence = "EMPTY_QUICKSLOT"
        return result
    end

    local itemType = SafeCall(GetItemLinkItemType, link)
    if ITEMTYPE_POTION == nil or itemType == nil then return result end

    result.selectionKnown = true
    result.link = link
    result.name = tostring(SafeCall(GetItemLinkName, link) or "")
    if itemType ~= ITEMTYPE_POTION then
        result.evidence = "SELECTED_NON_POTION"
        return result
    end

    result.known = true
    result.isPotion = true
    result.cooldownRemaining, result.cooldownDuration = SafeCall(GetSlotCooldownInfo, slot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    result.cooldownRemaining = FiniteNumber(result.cooldownRemaining)
    result.cooldownDuration = FiniteNumber(result.cooldownDuration)
    if result.cooldownRemaining then result.cooldownRemaining = math.max(0, result.cooldownRemaining) end
    if result.cooldownDuration then result.cooldownDuration = math.max(0, result.cooldownDuration) end
    result.itemId = Integer(SafeCall(GetItemLinkItemId, link), 0, MAX_INTEGER_ID) or 0

    if GetItemLinkOnUseAbilityInfo then
        local hasAbility, header, description = SafeCall(GetItemLinkOnUseAbilityInfo, link)
        if hasAbility then
            result.effects = tostring(header or "") .. " " .. tostring(description or "")
        end
    end

    return result
end

local SUPPORT_CP_HINTS = {
    "enlivening overflow",
    "from the brink",
    "hope infusion",
    "soothing tide",
    "swift renewal",
    "salve of renewal",
    "focused mending",
}

function SC:GetSupportScore(capabilities, skills)
    local score = 0
    local count = 0
    for _ in pairs(capabilities or {}) do count = count + 1 end
    score = score + math.min(18, count * 3)

    for _, star in ipairs(skills and skills.champion or {}) do
        local name = Normalize(star.name)
        for _, token in ipairs(SUPPORT_CP_HINTS) do
            if name:find(token, 1, true) then
                score = score + 3
                break
            end
        end
    end

    return math.min(31, score)
end

function SC:GetRoleHint(unitTag, capabilities)
    unitTag = unitTag or "player"
    local selectedRole
    if GetGroupMemberSelectedRole then selectedRole = SafeCall(GetGroupMemberSelectedRole, unitTag) end
    if (selectedRole == nil or selectedRole == LFG_ROLE_INVALID)
        and self.IsSelf and self:IsSelf(unitTag) and GetSelectedLFGRole then
        selectedRole = SafeCall(GetSelectedLFGRole)
    end
    if selectedRole ~= nil and selectedRole == LFG_ROLE_TANK then return "MT/OT" end
    if selectedRole ~= nil and selectedRole == LFG_ROLE_HEAL then return "HEAL" end

    local supportCount = 0
    for _ in pairs(capabilities or {}) do supportCount = supportCount + 1 end
    if selectedRole ~= nil and selectedRole == LFG_ROLE_DPS then
        return supportCount >= 2 and "DD SUPPORT" or "DD PARSE"
    end
    return "UNKNOWN"
end

function SC:ScanLocalPlayer()
    local equipment = self:ScanEquipment()
    local skills = self:ScanSkills()

    local capabilities = {}
    for key, value in pairs(equipment.capabilities or {}) do capabilities[key] = value end
    for key, value in pairs(skills.capabilities or {}) do
        capabilities[key] = capabilities[key] or {sources={}}
        for source in pairs(value.sources or {}) do capabilities[key].sources[source] = true end
    end

    local displayName = self:GetPlayerKey("player")
    local classId = Integer(SafeCall(GetUnitClassId, "player"), 0, 255) or 0
    local className = tostring(SafeCall(GetUnitClass, "player") or "")

    local snapshot = {
        protocolVersion = 2,
        catalogPatch = self.catalogPatch,
        displayName = displayName,
        characterName = tostring(SafeCall(GetUnitName, "player") or ""),
        classId = classId,
        className = className,
        role = self:GetRoleHint("player", capabilities),
        supportScore = self:GetSupportScore(capabilities, skills),
        dataQuality = "ASUI",
        asui = true,
        -- Capability sources are finite hints; absence is not proof that a player
        -- cannot provide an effect through a source unknown to this catalog.
        capabilitiesComplete = false,
        connected = self.IsOnline and self:IsOnline("player"),
        dead = SafeCall(IsUnitDead, "player") == true,
        scannedAt = self.NowMs(),
        equipment = equipment,
        skills = skills,
        curse = self.ScanCurse and self:ScanCurse() or {known=false},
        food = self:ScanFood("player"),
        potion = self:ScanPotion(),
        masteries = self.ScanClassMasteries and self:ScanClassMasteries() or {known=false},
        poisons = self.ScanPoisons and self:ScanPoisons() or {known=false},
        mundus = self.ScanMundus and self:ScanMundus() or {known=false},
        capabilities = capabilities,
    }

    for key,value in pairs(snapshot.masteries.capabilities or {}) do
        snapshot.capabilities[key]=snapshot.capabilities[key] or value
    end
    if self.DeriveBuildCapabilities then
        snapshot.capabilities = self:DeriveBuildCapabilities(snapshot)
    elseif self.ScanClassPassives then
        for key,value in pairs(self:ScanClassPassives(skills, snapshot.masteries)) do
            snapshot.capabilities[key] = snapshot.capabilities[key] or value
        end
    end
    snapshot.role = self:GetRoleHint("player", snapshot.capabilities)
    snapshot.supportScore = self:GetSupportScore(snapshot.capabilities, skills)
    return snapshot
end

function SC:ScanLimitedUnit(unitTag)
    local capabilities = {}
    local quality = "LIMITED"

    local ult = nil
    local lgcs = rawget(_G, "LibGroupCombatStats")
    if lgcs and type(lgcs.RegisterAddon) == "function" then
        -- Do not register a second consumer here; ULT Tracker may already own it.
        local group = AlphaSquadUI.Modules
            and AlphaSquadUI.Modules.ULTTracker
            and AlphaSquadUI.Modules.ULTTracker.Group
        if group and group.lgcs and type(group.lgcs.GetUnitULT) == "function" then
            ult = SafeCall(group.lgcs.GetUnitULT, group.lgcs, unitTag)
        end
    end

    return {
        protocolVersion = 0,
        catalogPatch = self.catalogPatch,
        displayName = self:GetPlayerKey(unitTag),
        characterName = tostring(SafeCall(GetUnitName, unitTag) or ""),
        classId = Integer(SafeCall(GetUnitClassId, unitTag), 0, 255) or 0,
        className = tostring(SafeCall(GetUnitClass, unitTag) or ""),
        role = self:GetRoleHint(unitTag, capabilities),
        dataQuality = quality,
        asui = false,
        capabilitiesComplete = false,
        connected = self.IsOnline and self:IsOnline(unitTag),
        dead = SafeCall(IsUnitDead, unitTag) == true,
        food = self:ScanFood(unitTag),
        ult = ult,
        capabilities = capabilities,
        scannedAt = self.NowMs(),
    }
end
