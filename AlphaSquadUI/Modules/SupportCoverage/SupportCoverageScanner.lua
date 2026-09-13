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

local EQUIP_SLOTS = {}
for _, value in ipairs({
    EQUIP_SLOT_HEAD, EQUIP_SLOT_CHEST, EQUIP_SLOT_SHOULDERS, EQUIP_SLOT_WAIST,
    EQUIP_SLOT_HAND, EQUIP_SLOT_LEGS, EQUIP_SLOT_FEET, EQUIP_SLOT_NECK,
    EQUIP_SLOT_RING1, EQUIP_SLOT_RING2, EQUIP_SLOT_MAIN_HAND, EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_BACKUP_MAIN, EQUIP_SLOT_BACKUP_OFF,
}) do
    if value ~= nil then EQUIP_SLOTS[#EQUIP_SLOTS + 1] = value end
end

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

local function ClassifyEnchant(header, description)
    local text = Normalize((header or "") .. " " .. (description or ""))

    local patterns = {
        prismatic = {"prismatic", "multi-effect", "tri-stat", "tristat", "hakeijo"},
        magicka = {"maximum magicka", "max magicka"},
        stamina = {"maximum stamina", "max stamina"},
        health = {"maximum health", "max health"},
        crusher = {"crushing", "crusher", "reduce the target's physical and spell resistance"},
        weapon_spell_damage = {"weapon and spell damage"},
        recovery = {"recovery", "regeneration"},
    }

    for _, kind in ipairs({"prismatic","crusher","magicka","stamina","health","weapon_spell_damage","recovery"}) do
        local list=patterns[kind]
        for _, token in ipairs(list) do
            if text:find(Normalize(token), 1, true) then return kind end
        end
    end
    return text ~= "" and "other" or "unknown"
end

function SC:ScanEquipment()
    local snapshot = {
        complete = GetItemLink ~= nil and GetItemLinkSetInfo ~= nil,
        sets = {},
        setList = {},
        items = {},
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
        if link == nil then
            snapshot.complete = false
            snapshot.glyphs.unknown = (snapshot.glyphs.unknown or 0) + (ARMOR_SLOTS[slot] and 1 or 0)
        elseif link ~= "" then
            local itemName = SafeCall(GetItemLinkName, link) or ""
            local item = {
                slot = slot,
                link = link,
                name = itemName,
                enchant = "unknown",
                hasEnchant = nil,
                trait = SafeCall(GetItemLinkTraitInfo, link),
                armorType = SafeCall(GetItemLinkArmorType, link),
                weaponType = SafeCall(GetItemLinkWeaponType, link),
                enchantId = nil,
                enchantHasCharges = nil,
                isArmor = ARMOR_SLOTS[slot] == true,
                isWeapon = slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND
                    or slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF,
            }

            local hasSet, setName, _, normalEquipped, maxEquipped, setId, perfectedEquipped =
                SafeCall(GetItemLinkSetInfo, link, true)
            if hasSet == nil then snapshot.complete = false end
            if hasSet and setName and setName ~= "" then
                local numericSetId = Integer(setId, 1, MAX_INTEGER_ID) or 0
                local setKey = numericSetId > 0 and tostring(numericSetId) or "name:" .. Normalize(setName)
                if not setSeen[setKey] then
                    local entry = {
                        id = numericSetId,
                        name = setName,
                        equipped = Count(normalEquipped, 24),
                        perfected = Count(perfectedEquipped, 24),
                        maxEquipped = Count(maxEquipped, 24),
                        mainCount = 0, backCount = 0,
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
                local twoHanded = item.isWeapon and item.weaponType ~= nil and (
                    item.weaponType == WEAPONTYPE_TWO_HANDED_SWORD or item.weaponType == WEAPONTYPE_TWO_HANDED_AXE
                    or item.weaponType == WEAPONTYPE_TWO_HANDED_HAMMER or item.weaponType == WEAPONTYPE_BOW
                    or item.weaponType == WEAPONTYPE_FIRE_STAFF or item.weaponType == WEAPONTYPE_FROST_STAFF
                    or item.weaponType == WEAPONTYPE_LIGHTNING_STAFF or item.weaponType == WEAPONTYPE_HEALING_STAFF)
                local pieces = twoHanded and 2 or 1
                local mainOnly = slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND
                local backOnly = slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF
                if not backOnly then set.mainCount = set.mainCount + pieces end
                if not mainOnly then set.backCount = set.backCount + pieces end
            end

            local hasCharges, enchantHeader, enchantDescription = SafeCall(GetItemLinkEnchantInfo, link)
            item.enchantHasCharges = hasCharges
            local enchantId = SafeCall(GetItemLinkFinalEnchantId, link)
            if not enchantId or enchantId == 0 then
                enchantId = SafeCall(GetItemLinkAppliedEnchantId, link)
                if not enchantId or enchantId == 0 then enchantId = SafeCall(GetItemLinkDefaultEnchantId, link) end
            end
            item.enchantId = Integer(enchantId, 0, MAX_INTEGER_ID)
            if item.enchantId ~= nil then
                item.hasEnchant = item.enchantId > 0
            elseif tostring(enchantHeader or "") ~= "" or tostring(enchantDescription or "") ~= "" then
                item.hasEnchant = true
            end
            if item.hasEnchant == nil then
                item.enchant = "unknown"
            elseif item.hasEnchant then
                item.enchant = ClassifyEnchant(enchantHeader, enchantDescription)
            else
                item.enchant = "missing"
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
            elseif item.enchant == "crusher" and item.enchantHasCharges ~= false then
                snapshot.glyphs.crusher = snapshot.glyphs.crusher + 1
                AddCapability(snapshot.capabilities, "crusher", "Crusher Enchantment")
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

function SC:ScanSkills()
    local result = {
        primary = {},
        backup = {},
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

    for key, category in pairs(categories) do
        if category ~= nil then
            for slot = 3, ultimateSlot do
                local boundId = SafeCall(GetSlotBoundId, slot, category)
                if boundId == nil then result.known = false end
                local validBoundId = Integer(boundId, 0, MAX_INTEGER_ID)
                if validBoundId == nil then result.known = false end
                boundId = validBoundId or 0
                if boundId > 0 then
                    local effectiveId = boundId
                    if GetEffectiveAbilityIdForAbilityOnHotbar then
                        local resolved = SafeCall(GetEffectiveAbilityIdForAbilityOnHotbar, boundId, category)
                        resolved = Integer(resolved, 1, MAX_INTEGER_ID)
                        if resolved then effectiveId = resolved end
                    end

                    local name = SafeCall(GetSlotName, slot, category)
                    if not name or name == "" then name = SafeCall(GetAbilityName, effectiveId) or "" end
                    local icon = SafeCall(GetSlotTexture, slot, category) or ""
                    local entry = {
                        slot = slot,
                        boundAbilityId = boundId,
                        abilityId = effectiveId,
                        name = tostring(name or ""),
                        icon = tostring(icon or ""),
                        ultimate = slot == ultimateSlot,
                    }
                    result[key][#result[key] + 1] = entry

                    if Catalog then
                        local matched = Catalog:MatchSkill(entry.abilityId, entry.name)
                        if entry.boundAbilityId ~= entry.abilityId then
                            for capability in pairs(Catalog:MatchSkill(entry.boundAbilityId, entry.name)) do
                                matched[capability] = true
                            end
                        end
                        for capability in pairs(matched) do
                            AddCapability(result.capabilities, capability, entry.name)
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
                local name = ""
                if GetChampionSkillName then name = SafeCall(GetChampionSkillName, starId) or "" end
                result.champion[#result.champion + 1] = {
                    slot = slot,
                    id = starId,
                    points = Integer(SafeCall(GetNumPointsSpentOnChampionSkill,starId), 0, 3600),
                    discipline = self.GetChampionDiscipline and self:GetChampionDiscipline(starId),
                    name = tostring(name or ""),
                }
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
    local key = self:GetPlayerKey(unitTag)
    if self.sv and self.sv.roleOverrides and self.sv.roleOverrides[key] then
        return self.sv.roleOverrides[key]
    end

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
    if selectedRole == LFG_ROLE_DPS or supportCount > 0 then
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
        connected = true,
        dead = IsUnitDead and IsUnitDead("player") or false,
        scannedAt = self.NowMs(),
        equipment = equipment,
        skills = skills,
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
        dead = IsUnitDead and IsUnitDead(unitTag) or false,
        food = self:ScanFood(unitTag),
        ult = ult,
        capabilities = capabilities,
        scannedAt = self.NowMs(),
    }
end
