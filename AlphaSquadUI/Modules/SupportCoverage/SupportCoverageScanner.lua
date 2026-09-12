-- Ąlpha Şquad UI - Support Coverage local/limited scanners

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h
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
    if not GetItemLink or BAG_WORN == nil then return "" end
    local link = SafeCall(GetItemLink, BAG_WORN, slot, LINK_STYLE_DEFAULT or 0)
    return tostring(link or "")
end

local function ClassifyEnchant(header, description)
    local text = Normalize((header or "") .. " " .. (description or ""))

    local patterns = {
        prismatic = {"prismatic", "multi-effect", "tri-stat", "tristat", "hakeijo", "prismatique", "prismatisch"},
        magicka = {"maximum magicka", "max magicka", "magie maximale", "magicka maximale", "maximale magicka"},
        stamina = {"maximum stamina", "max stamina", "vigueur maximale", "ausdauer", "stamina maximale"},
        health = {"maximum health", "max health", "santé maximale", "gesundheit", "leben"},
        crusher = {"crushing", "crusher", "reduce the target's physical and spell resistance", "résistance physique et magique", "physische und magieresistenz"},
        weapon_spell_damage = {"weapon and spell damage", "dégâts des armes et des sorts", "waffen- und magiekraft"},
        recovery = {"recovery", "récupération", "regeneration", "regénération"},
    }

    for kind, list in pairs(patterns) do
        for _, token in ipairs(list) do
            if text:find(Normalize(token), 1, true) then return kind end
        end
    end
    return text ~= "" and "other" or "unknown"
end

function SC:ScanEquipment()
    local snapshot = {
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
        if link ~= "" then
            local itemName = SafeCall(GetItemLinkName, link) or ""
            local item = {
                slot = slot,
                link = link,
                name = itemName,
                enchant = "unknown",
                hasEnchant = false,
            }

            local hasSet, setName, _, normalEquipped, maxEquipped, setId, perfectedEquipped =
                SafeCall(GetItemLinkSetInfo, link, true)
            if hasSet and setName and setName ~= "" then
                local setKey = tonumber(setId) and tostring(setId) or Normalize(setName)
                if not setSeen[setKey] then
                    local entry = {
                        id = tonumber(setId) or 0,
                        name = setName,
                        equipped = tonumber(normalEquipped) or 0,
                        perfected = tonumber(perfectedEquipped) or 0,
                        maxEquipped = tonumber(maxEquipped) or 0,
                    }
                    snapshot.sets[setKey] = entry
                    snapshot.setList[#snapshot.setList + 1] = entry
                    setSeen[setKey] = true

                    if Catalog then
                        local matched = Catalog:MatchSetName(setName)
                        for capability in pairs(matched) do
                            AddCapability(snapshot.capabilities, capability, setName)
                        end
                    end
                end
            end

            local hasEnchant, enchantHeader, enchantDescription = SafeCall(GetItemLinkEnchantInfo, link)
            item.hasEnchant = hasEnchant == true
            if item.hasEnchant then
                item.enchant = ClassifyEnchant(enchantHeader, enchantDescription)
            else
                item.enchant = "missing"
            end

            if ARMOR_SLOTS[slot] then
                snapshot.glyphs.armorTotal = snapshot.glyphs.armorTotal + 1
                if not item.hasEnchant then
                    snapshot.glyphs.armorMissing = snapshot.glyphs.armorMissing + 1
                elseif snapshot.glyphs[item.enchant] ~= nil then
                    snapshot.glyphs[item.enchant] = snapshot.glyphs[item.enchant] + 1
                else
                    snapshot.glyphs.other = snapshot.glyphs.other + 1
                end
            elseif item.enchant == "crusher" then
                snapshot.glyphs.crusher = snapshot.glyphs.crusher + 1
                AddCapability(snapshot.capabilities, "crusher", "Crusher Enchantment")
            end

            snapshot.items[#snapshot.items + 1] = item
        elseif ARMOR_SLOTS[slot] then
            snapshot.glyphs.armorTotal = snapshot.glyphs.armorTotal + 1
            snapshot.glyphs.armorMissing = snapshot.glyphs.armorMissing + 1
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
                boundId = tonumber(boundId) or 0
                if boundId > 0 then
                    local effectiveId = boundId
                    if GetEffectiveAbilityIdForAbilityOnHotbar then
                        local resolved = SafeCall(GetEffectiveAbilityIdForAbilityOnHotbar, boundId, category)
                        if tonumber(resolved) and tonumber(resolved) > 0 then effectiveId = tonumber(resolved) end
                    end

                    local name = SafeCall(GetSlotName, slot, category)
                    if not name or name == "" then name = SafeCall(GetAbilityName, effectiveId) or "" end
                    local icon = SafeCall(GetSlotTexture, slot, category) or ""
                    local entry = {
                        slot = slot,
                        abilityId = effectiveId,
                        name = tostring(name or ""),
                        icon = tostring(icon or ""),
                        ultimate = slot == ultimateSlot,
                    }
                    result[key][#result[key] + 1] = entry

                    if Catalog then
                        local matched = Catalog:MatchSkillName(entry.name)
                        for capability in pairs(matched) do
                            AddCapability(result.capabilities, capability, entry.name)
                        end
                    end
                end
            end
        end
    end

    if HOTBAR_CATEGORY_CHAMPION ~= nil and GetSlotBoundId then
        for slot = 1, 12 do
            local starId = SafeCall(GetSlotBoundId, slot, HOTBAR_CATEGORY_CHAMPION)
            starId = tonumber(starId) or 0
            if starId > 0 then
                local name = ""
                if GetChampionSkillName then name = SafeCall(GetChampionSkillName, starId) or "" end
                result.champion[#result.champion + 1] = {
                    slot = slot,
                    id = starId,
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
        if abilityId and tonumber(abilityId) and tonumber(abilityId) > 0 then
            return {
                active = true,
                verified = true,
                source = "LibFoodDrinkBuff",
                abilityId = tonumber(abilityId) or 0,
                name = tostring(buffName or ""),
                isDrink = isDrink == true,
                timeStarted = tonumber(timeStarted) or 0,
                timeEnds = tonumber(timeEnds) or 0,
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
    local count = tonumber(GetNumBuffs(unitTag)) or 0
    for i = 1, count do
        local name, started, ending, _, _, icon, _, _, _, _, abilityId, canClickOff =
            GetUnitBuffInfo(unitTag, i)
        local duration = (tonumber(ending) or 0) - (tonumber(started) or 0)
        if canClickOff and duration >= 1800 and (tonumber(ending) or 0) > now then
            return {
                active = true,
                verified = false,
                source = "ESO heuristic",
                abilityId = tonumber(abilityId) or 0,
                name = tostring(name or ""),
                isDrink = false,
                timeStarted = tonumber(started) or 0,
                timeEnds = tonumber(ending) or 0,
                icon = tostring(icon or ""),
            }
        end
    end

    return {active=false, verified=false, source="ESO heuristic"}
end

function SC:ScanPotion()
    local result = {known=false, name="", itemId=0, effects=""}
    if not GetCurrentQuickslot or not GetSlotItemLink then return result end

    local slot = SafeCall(GetCurrentQuickslot)
    if not slot then return result end

    local link = SafeCall(GetSlotItemLink, slot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
    if not link or link == "" then link = SafeCall(GetSlotItemLink, slot) end
    if not link or link == "" then return result end

    local itemType = SafeCall(GetItemLinkItemType, link)
    local consumable = SafeCall(IsItemLinkConsumable, link)
    if consumable ~= true and itemType ~= ITEMTYPE_POTION then return result end

    result.known = true
    result.name = tostring(SafeCall(GetItemLinkName, link) or "")
    result.itemId = tonumber(SafeCall(GetItemLinkItemId, link)) or 0

    if GetItemLinkOnUseAbilityInfo then
        local hasAbility, description = SafeCall(GetItemLinkOnUseAbilityInfo, link)
        if hasAbility then result.effects = tostring(description or "") end
    end

    return result
end

function SC:GetRoleHint(unitTag, capabilities)
    unitTag = unitTag or "player"
    local key = self:GetPlayerKey(unitTag)
    if self.sv and self.sv.roleOverrides and self.sv.roleOverrides[key] then
        return self.sv.roleOverrides[key]
    end

    local isDps, isHealer, isTank = false, false, false
    if GetGroupMemberRoles then
        local a, b, c = SafeCall(GetGroupMemberRoles, unitTag)
        isDps, isHealer, isTank = a == true, b == true, c == true
    end

    if isTank then return "MT/OT" end
    if isHealer then return "HEAL" end

    local supportCount = 0
    for _ in pairs(capabilities or {}) do supportCount = supportCount + 1 end
    if isDps or supportCount > 0 then
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
    local classId = tonumber(SafeCall(GetUnitClassId, "player")) or 0
    local className = tostring(SafeCall(GetUnitClass, "player") or "")

    local snapshot = {
        protocolVersion = 1,
        catalogPatch = self.catalogPatch,
        displayName = displayName,
        characterName = tostring(SafeCall(GetUnitName, "player") or ""),
        classId = classId,
        className = className,
        role = self:GetRoleHint("player", capabilities),
        dataQuality = "ASUI",
        asui = true,
        connected = true,
        dead = IsUnitDead and IsUnitDead("player") or false,
        scannedAt = self.NowMs(),
        equipment = equipment,
        skills = skills,
        food = self:ScanFood("player"),
        potion = self:ScanPotion(),
        capabilities = capabilities,
    }

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
        classId = tonumber(SafeCall(GetUnitClassId, unitTag)) or 0,
        className = tostring(SafeCall(GetUnitClass, unitTag) or ""),
        role = self:GetRoleHint(unitTag, capabilities),
        dataQuality = quality,
        asui = false,
        connected = IsUnitOnline and IsUnitOnline(unitTag) or true,
        dead = IsUnitDead and IsUnitDead(unitTag) or false,
        food = self:ScanFood(unitTag),
        ult = ult,
        capabilities = capabilities,
        scannedAt = self.NowMs(),
    }
end
