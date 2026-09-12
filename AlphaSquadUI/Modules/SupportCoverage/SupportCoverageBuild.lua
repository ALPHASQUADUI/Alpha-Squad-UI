-- Additional local build facts. Missing APIs yield UNKNOWN, never guessed selections.
local SC = AlphaSquadUI.Modules.SupportCoverage
local function Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if ok then return a, b, c, d, e, f, g, h end
end
SC.Try = Try
local function MasteryName(name)
    return string.lower(tostring(name or ""):gsub("’","'"):gsub("%^.*$", ""))
end

function SC:IsSelf(unitTag)
    if unitTag == "player" then return true end
    return Try(AreUnitsEqual, unitTag, "player") == true
end

function SC:IsOnline(unitTag)
    local value = Try(IsUnitOnline, unitTag)
    if value == nil then return nil end
    return value == true
end

function SC:ScanClassMasteries()
    local result = {known=false, eligible=nil, selected={}, learned={}, capabilities={}, nativeLines=0, foreignLines=0}
    local manager = SKILLS_DATA_MANAGER
    if not manager or not manager.GetSkillTypeData or not SKILL_TYPE_CLASS then return result end
    local classType = Try(manager.GetSkillTypeData, manager, SKILL_TYPE_CLASS)
    if not classType or not classType.SkillLineIterator or not GetSkillLineDynamicInfo then return result end
    local classId = Try(GetUnitClassId, "player")
    local complete, mastered = type(classId)=="number" and classId>0, 0
    local ok = pcall(function()
        for _, line in classType:SkillLineIterator() do
            local skillType, lineIndex = line:GetIndices()
            -- Read committed state, not the UI's pending respec/activation state.
            local rank, _, active, _, _, _, isMastery = Try(GetSkillLineDynamicInfo, skillType, lineIndex)
            if rank == nil or isMastery == nil then complete = false end
            if isMastery then
                if line:GetClassId() == classId then
                    for _, skill in line:SkillIterator() do
                        if skill:IsPurchased() then
                            local progression = skill:GetCurrentProgressionData()
                            if progression then
                                local id,name=progression:GetAbilityId(),progression:GetName()
                                if type(id)=="number" and id>0 and type(name)=="string" then
                                    result.selected[#result.selected + 1] = {
                                        id=id, name=name, rank=skill.GetCurrentRank and skill:GetCurrentRank() or 1,
                                    }
                                else complete=false end
                            else complete = false end
                        end
                    end
                end
            elseif active then
                for _,skill in line:SkillIterator() do
                    if skill:IsPurchased() then
                        local progression=skill:GetCurrentProgressionData()
                        if progression then
                            result.learned[MasteryName(progression:GetName())]=skill.GetCurrentRank and skill:GetCurrentRank() or 1
                        end
                    end
                end
                if line:GetClassId() == classId then
                    result.nativeLines = result.nativeLines + 1
                    if tonumber(rank) and rank >= 50 then mastered = mastered + 1 end
                else
                    result.foreignLines = result.foreignLines + 1
                end
            end
        end
    end)
    result.known = ok and complete
    if result.known then result.eligible = result.nativeLines == 3 and result.foreignLines == 0 and mastered == 3 end
    if not ok then result.selected = {}; result.learned={} end
    if result.known and result.eligible then
        for _,selected in ipairs(result.selected) do
            if MasteryName(selected.name)=="above and beyond" then result.criticalDamageCap=155 end
            for _,source in ipairs(self.Catalog.masterySources or {}) do
                if MasteryName(selected.name)==MasteryName(source.name)
                    and (not source.requires or (result.learned[MasteryName(source.requires)] or 0)>=(source.rank or 1)) then
                    for _,key in ipairs(source.provides) do
                        result.capabilities[key]={sources={[source.name]=true},evidence="SELECTED_MASTERY_NAME",conditional=true}
                    end
                end
            end
        end
    end
    table.sort(result.selected, function(a, b) return a.id < b.id end)
    return result
end

function SC:GetChampionDiscipline(starId)
    local manager=CHAMPION_DATA_MANAGER
    if not manager then return nil end
    local skill=Try(manager.GetChampionSkillData,manager,starId)
    local discipline=skill and Try(skill.GetChampionDisciplineData,skill)
    local kind=discipline and Try(discipline.GetType,discipline)
    if kind==nil then return nil end
    if kind==CHAMPION_DISCIPLINE_TYPE_COMBAT then return "COMBAT" end
    if kind==CHAMPION_DISCIPLINE_TYPE_CONDITIONING then return "CONDITIONING" end
    if kind==CHAMPION_DISCIPLINE_TYPE_WORLD then return "WORLD" end
end

function SC:ScanPoisons()
    local result = {known=false, items={}}
    if BAG_WORN == nil or not GetItemLink or EQUIP_SLOT_POISON == nil or EQUIP_SLOT_BACKUP_POISON == nil then return result end
    result.known = true
    for _, slot in ipairs({EQUIP_SLOT_POISON, EQUIP_SLOT_BACKUP_POISON}) do
        local link = Try(GetItemLink, BAG_WORN, slot, LINK_STYLE_DEFAULT or 0)
        if link == nil then result.known = false end
        result.items[#result.items + 1] = {slot=slot, link=link or "", name=link and Try(GetItemLinkName, link) or ""}
    end
    return result
end

function SC:ScanMundus()
    local result = {known=false, ids={}}
    local count = Try(GetNumBuffs, "player")
    if count == nil or not GetUnitBuffInfo then return result end
    -- The client does not expose a portable Mundus getter. Exact configured IDs are
    -- preferred; English names are display hints only and do not verify absence.
    local configured = self.sv and self.sv.mundusAbilityIds or {}
    local countConfigured,complete = 0,true
    for _ in pairs(configured) do countConfigured = countConfigured + 1 end
    for index = 1, count do
        local ok, name, _, _, _, _, _, _, _, _, _, id = pcall(GetUnitBuffInfo, "player", index)
        if not ok then complete=false end
        if ok and id and configured[tostring(id)] then result.ids[#result.ids + 1] = id end
        if ok and name and name:find("Boon:", 1, true) then result.hint = name end
    end
    result.known = #result.ids > 0 and complete
    -- A partial ID registry cannot prove that a different Mundus is absent.
    return result
end

function SC:RefreshReadinessFacts()
    if not self.localSnapshot then return end
    self.localSnapshot.food = self:ScanFood("player")
    self.localSnapshot.potion = self:ScanPotion()
    self.localSnapshot.dead = Try(IsUnitDead, "player") == true
    self.localSnapshot.connected = self:IsOnline("player")
    self.localSnapshot.readinessAt = self.NowMs()
end

function SC:SamplePotionEvidence()
    if not self.pull then return end
    local potion = self:ScanPotion()
    local now = self.NowMs()
    local evidence = self.pull.potions
    local key = self:GetPlayerKey("player")
    local entry = evidence[key] or {count=0, inferredCount=0, evidence="UNKNOWN", opportunitiesMs=0}
    entry.categoryMonitoring = ITEM_SOUND_CATEGORY_POTION ~= nil and EVENT_INVENTORY_ITEM_USED ~= nil
    evidence[key] = entry
    local previous = self.potionObservation
    local remaining = potion.cooldownRemaining
    if potion.known and remaining ~= nil then
        entry.cooldownMonitoring = true
        entry.evidence = "LOCAL_COOLDOWN"
        entry.itemId = potion.itemId
        entry.name = potion.name
        if previous and previous.link == potion.link and now - previous.at <= 2500 then
            local elapsed = math.max(0, now - previous.at)
            if previous.remaining ~= nil and previous.remaining <= 0 then entry.opportunitiesMs = entry.opportunitiesMs + elapsed end
            if previous.remaining ~= nil and remaining > 1000 and remaining > previous.remaining + 1000 then
                -- A cooldown transition is evidence, not proof of the exact consumed item.
                entry.inferredCount = entry.inferredCount + 1
                entry.evidence = "INFERRED_COOLDOWN"
                entry.lastObservedAt = now - self.pull.startedAt
            end
        end
    end
    self.potionObservation = {at=now, remaining=remaining, link=potion.link}
end

function SC:OnConsumableUsed(itemSoundCategory)
    -- ESO's inventory-used event carries a sound category, not an item ID.
    -- Count only documented potion-category events; never infer a use from a buff alone.
    if not self.pull or ITEM_SOUND_CATEGORY_POTION == nil or itemSoundCategory ~= ITEM_SOUND_CATEGORY_POTION then return end
    local key = self:GetPlayerKey("player")
    local entry = self.pull.potions[key] or {count=0, inferredCount=0, opportunitiesMs=0}
    self.pull.potions[key] = entry
    entry.categoryMonitoring = true
    entry.count = entry.count + 1
    entry.evidence = "POTION_CATEGORY_EVENT"
    entry.exactItemVerified = false
end
