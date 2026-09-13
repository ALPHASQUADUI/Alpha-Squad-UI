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
    local result = {known=false, eligible=nil, selected={}, learned={}, learnedIds={}, capabilities={}, nativeLines=0, foreignLines=0}
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
                                local id,name=Try(progression.GetAbilityId,progression),Try(progression.GetName,progression)
                                if type(id)=="number" and id==id and id>0 and id<math.huge and id%1==0
                                    and type(name)=="string" and name~="" then
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
                            local learnedRank=skill.GetCurrentRank and skill:GetCurrentRank() or 1
                            local learnedId=Try(progression.GetAbilityId,progression)
                            local learnedName=Try(progression.GetName,progression)
                            if type(learnedName)=="string" and learnedName~="" then
                                result.learned[MasteryName(learnedName)]=learnedRank
                            else
                                complete=false
                            end
                            if type(learnedId)=="number" and learnedId==learnedId and learnedId>0
                                and learnedId<math.huge and learnedId%1==0 then
                                result.learnedIds[learnedId]=learnedRank
                            else
                                complete=false
                            end
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
    if result.known then
        local allMaxed = Try(HasMaxRankInAllClassSkillLines)
        local activePlayerLines = Try(manager.GetNumPlayerClassActiveSkillLines, manager)
        local activeClassLines = Try(manager.GetNumActiveClassSkillLines, manager)
        if allMaxed ~= nil and activePlayerLines ~= nil and activeClassLines ~= nil then
            result.eligible = allMaxed == true and activePlayerLines == activeClassLines
            result.eligibilityEvidence = "NATIVE_CLASS_MASTERY_API"
        else
            result.eligible = result.nativeLines == 3 and result.foreignLines == 0 and mastered == 3
            result.eligibilityEvidence = "SKILL_LINE_FALLBACK"
        end
    end
    if not ok then result.selected = {}; result.learned={}; result.learnedIds={} end
    if result.known and result.eligible then
        for _,selected in ipairs(result.selected) do
            for _,source in ipairs(self.Catalog.masterySources or {}) do
                local matchedById=selected.id==source.abilityId
                local selectedMatch=matchedById or MasteryName(selected.name)==MasteryName(source.name)
                if not selectedMatch then
                    for _,alias in ipairs(source.aliases or {}) do
                        if MasteryName(selected.name)==MasteryName(alias) then selectedMatch=true;break end
                    end
                end
                local requiredRank=source.rank or 1
                local prerequisiteMatch=not source.requires
                for _,abilityId in ipairs(source.requiresIds or {}) do
                    if (result.learnedIds[abilityId] or 0)>=requiredRank then prerequisiteMatch=true;break end
                end
                if not prerequisiteMatch and source.requires then
                    prerequisiteMatch=(result.learned[MasteryName(source.requires)] or 0)>=requiredRank
                end
                if selectedMatch and prerequisiteMatch then
                    for _,key in ipairs(source.provides) do
                        result.capabilities[key]={sources={[source.name]=true},
                            evidence=matchedById and "SELECTED_MASTERY_ID" or "SELECTED_MASTERY_NAME",conditional=true}
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

function SC:RefreshReadinessFacts()
    if not self.localSnapshot then return false end
    self.localSnapshot.food = self:ScanFood("player")
    self.localSnapshot.potion = self:ScanPotion()
    self.localSnapshot.mundus = self:ScanMundus()
    self.localSnapshot.dead = Try(IsUnitDead, "player") == true
    self.localSnapshot.connected = self:IsOnline("player")
    self.localSnapshot.readinessAt = self.NowMs()
    local food=self.localSnapshot.food or {};local potion=self.localSnapshot.potion or {}
    local mundus=self.localSnapshot.mundus or {}
    local potionSignature="UNKNOWN"
    if potion.known then potionSignature=potion.link or tostring(potion.itemId or 0)
    elseif potion.selectionKnown then potionSignature="NONE" end
    local signature=table.concat({food.verified and "1" or "0",food.active and "1" or "0",tostring(food.abilityId or 0),
        potionSignature,table.concat(mundus.ids or {},",")},"|")
    local changed=self.lastReadinessSignature~=nil and self.lastReadinessSignature~=signature
    self.lastReadinessSignature=signature
    return changed
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
