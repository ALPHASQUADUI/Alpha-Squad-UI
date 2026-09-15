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

local function NaturalNumber(value, maximum)
    if type(value) ~= "number" or value ~= value or value < 0 or value > maximum or value % 1 ~= 0 then return nil end
    return value
end

-- The curse API describes the committed character state. A slotted Werewolf
-- ultimate does not prove transformation, and a vampire skill does not prove
-- a stage. Stages stay unspecified unless a verified stage source is available.
function SC:ScanCurse()
    local result = {known=false}
    local curseType = Try(GetPlayerCurseType)
    if curseType ~= nil then
        for _, kind in ipairs({"NONE", "VAMPIRE", "WEREWOLF"}) do
            local nativeType = rawget(_G, "CURSE_TYPE_" .. kind)
            if nativeType ~= nil and curseType == nativeType then
                result.known, result.kind = true, kind
                break
            end
        end
    end
    if result.known and result.kind == "WEREWOLF" then
        local transformed = Try(IsPlayerInWerewolfForm)
        if type(transformed) == "boolean" then result.transformed = transformed end
    end
    return result
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
    local result = {known=false, eligible=nil, selected={}, learned={}, learnedIds={}, capabilities={},
        skillLines={}, passives={}, nativeLines=0, foreignLines=0}
    local manager = SKILLS_DATA_MANAGER
    if not manager or not manager.GetSkillTypeData or not SKILL_TYPE_CLASS then return result end
    local classType = Try(manager.GetSkillTypeData, manager, SKILL_TYPE_CLASS)
    if not classType or not classType.SkillLineIterator or not GetSkillLineDynamicInfo then return result end
    local classId = Try(GetUnitClassId, "player")
    local complete, mastered = NaturalNumber(classId, 255) ~= nil and classId > 0, 0
    local ok = pcall(function()
        for _, line in classType:SkillLineIterator() do
            local skillType, lineIndex = line:GetIndices()
            -- Read committed state, not the UI's pending respec/activation state.
            local rank, _, active, _, _, _, isMastery = Try(GetSkillLineDynamicInfo, skillType, lineIndex)
            if not NaturalNumber(rank, 100) or type(isMastery) ~= "boolean" or type(active) ~= "boolean" then complete = false end
            local lineClass = Try(line.GetClassId, line)
            local lineId = Try(line.GetId, line) or Try(GetSkillLineId, skillType, lineIndex)
            local lineName = Try(line.GetName, line) or Try(GetSkillLineNameById, lineId or 0)
            if active or (isMastery and lineClass == classId) then
                result.skillLines[#result.skillLines + 1] = {id=NaturalNumber(lineId, 2147483647),
                    name=tostring(lineName or ""), rank=NaturalNumber(rank, 100), active=active == true,
                    classId=NaturalNumber(lineClass, 255), mastery=isMastery == true, native=lineClass == classId}
            end
            if isMastery then
                if lineClass == classId then
                    for _, skill in line:SkillIterator() do
                        if skill:IsPurchased() then
                            local progression = skill:GetCurrentProgressionData()
                            if progression then
                                local id,name=Try(progression.GetAbilityId,progression),Try(progression.GetName,progression)
                                local selectedRank=NaturalNumber(Try(skill.GetCurrentRank, skill) or 1, 100)
                                if NaturalNumber(id,2147483647) and id>0 and selectedRank and selectedRank>0
                                    and type(name)=="string" and name~="" then
                                    result.selected[#result.selected + 1] = {
                                        id=id, name=name, rank=selectedRank,
                                        icon=tostring(Try(GetAbilityIcon, id) or ""),
                                        description=tostring(Try(GetAbilityDescription, id, selectedRank, "player") or ""),
                                        lineId=lineId,
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
                            local learnedRank=NaturalNumber(Try(skill.GetCurrentRank, skill) or 1, 100)
                            local learnedId=Try(progression.GetAbilityId,progression)
                            local learnedName=Try(progression.GetName,progression)
                            if type(learnedName)=="string" and learnedName~="" and learnedRank and learnedRank>0 then
                                result.learned[MasteryName(learnedName)]=learnedRank
                            else
                                complete=false
                            end
                            if NaturalNumber(learnedId,2147483647) and learnedId>0 and learnedRank and learnedRank>0 then
                                result.learnedIds[learnedId]=learnedRank
                                if Try(skill.IsPassive, skill) == true then
                                    result.passives[#result.passives + 1] = {id=learnedId,
                                        name=tostring(learnedName or ""), rank=learnedRank, lineId=lineId,
                                        lineName=tostring(lineName or ""), active=true,
                                        icon=tostring(Try(GetAbilityIcon, learnedId) or ""),
                                        description=tostring(Try(GetAbilityDescription, learnedId, learnedRank, "player") or "")}
                                end
                            else
                                complete=false
                            end
                        else complete=false end
                    end
                end
                if lineClass == classId then
                    result.nativeLines = result.nativeLines + 1
                    if NaturalNumber(rank, 100) and rank >= 50 then mastered = mastered + 1 end
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
        if type(allMaxed) == "boolean" and NaturalNumber(activePlayerLines, 24) and NaturalNumber(activeClassLines, 24) then
            result.eligible = allMaxed == true and activePlayerLines == 3 and activeClassLines == 3
            result.eligibilityEvidence = "NATIVE_CLASS_MASTERY_API"
        else
            result.eligible = result.nativeLines == 3 and result.foreignLines == 0 and mastered == 3
            result.eligibilityEvidence = "SKILL_LINE_FALLBACK"
        end
    end
    if not ok then result.selected = {}; result.learned={}; result.learnedIds={}; result.passives={}; result.skillLines={} end
    if result.known and result.eligible then
        for _,selected in ipairs(result.selected) do
            for _,source in ipairs(self.Catalog.masterySources or {}) do
                local matchedById=selected.id==source.abilityId
                local selectedMatch=matchedById
                local requiredRank=source.rank or 1
                local prerequisiteMatch=not source.requires
                if selectedMatch and source.requires then
                    prerequisiteMatch=self.Catalog:GetLearnedSourceRank(result,source.requiresIds,source.requiresPassive)>=requiredRank
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

function SC:ScanClassPassives(skills, masteries)
    local capabilities = {}
    if not masteries or not masteries.known then return capabilities end
    for _, source in ipairs(self.Catalog.passiveSources or {}) do
        local learnedRank=self.Catalog:GetLearnedSourceRank(masteries,source.abilityIds,source.nativePassive)
        local evidence="LEARNED_PASSIVE_ID"
        if learnedRank >= (source.rank or 1) then
            local unrestricted = #(source.skillLineIds or {}) == 0
            local main, back = unrestricted, unrestricted
            for _, bar in ipairs({"primary", "backup"}) do
                for _, skill in ipairs((skills or {})[bar] or {}) do
                    for _, lineId in ipairs(source.skillLineIds or {}) do
                        if skill.lineId == lineId then
                            if bar == "primary" then main = true else back = true end
                        end
                    end
                end
            end
            if main or back then
                for _, key in ipairs(source.provides or {}) do
                    if self.Catalog.effects[key] then
                        local cap = capabilities[key] or {sources={}, sourceDetails={}, mainBar=false, backBar=false}
                        cap.sources[source.name] = true
                        cap.mainBar, cap.backBar = cap.mainBar or main, cap.backBar or back
                        cap.conditional, cap.evidence = true, evidence
                        cap.sourceDetails[source.name] = {kind="passive", name=source.name,
                            conditions=source.conditions, trigger=source.trigger, rank=learnedRank,
                            mainBar=main, backBar=back, evidence=evidence}
                        capabilities[key] = cap
                    end
                end
            end
        end
    end
    return capabilities
end

-- ESO assigns Champion disciplines to action slots natively. Keep the real
-- positions, including empty slots, rather than compacting the selected stars.
function SC:GetChampionSlotLayout()
    if HOTBAR_CATEGORY_CHAMPION == nil or type(GetRequiredChampionDisciplineIdForSlot) ~= "function" then return nil end
    local first, last = Try(GetAssignableChampionBarStartAndEndSlots)
    first, last = NaturalNumber(first, 64), NaturalNumber(last, 64)
    if not first or not last or first < 1 or last < first or last - first > 23 then return nil end
    local layout, counts = {}, {}
    for slot = first, last do
        local disciplineId = Try(GetRequiredChampionDisciplineIdForSlot, slot, HOTBAR_CATEGORY_CHAMPION)
        local kind = disciplineId and Try(GetChampionDisciplineType, disciplineId)
        local discipline
        for _, name in ipairs({"COMBAT", "CONDITIONING", "WORLD"}) do
            local nativeKind = rawget(_G, "CHAMPION_DISCIPLINE_TYPE_" .. name)
            if nativeKind ~= nil and kind == nativeKind then discipline = name; break end
        end
        if not discipline then return nil end
        counts[discipline] = (counts[discipline] or 0) + 1
        if counts[discipline] > 4 then return nil end
        layout[slot] = {discipline=discipline, index=counts[discipline]}
    end
    return layout
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

-- Use the inspected player's committed allocation with native preview APIs.
-- IsPurchased() on the local data manager would substitute the viewer's build.
function SC:IsChampionStarActive(star)
    if type(star)~="table" or star.pointsKnown~=true then return false end
    local id,points=NaturalNumber(star.id,2147483647),NaturalNumber(star.points,3600)
    if not id or id<1 or not points or points<1 then return false end
    local maximum=NaturalNumber(Try(GetChampionSkillMaxPoints,id),3600)
    if not maximum or maximum<1 or points>maximum then return false end
    local kind=Try(GetChampionSkillType,id)
    local slottable=false
    for _,name in ipairs({"NORMAL_SLOTTABLE","STAT_POOL_SLOTTABLE"}) do
        local native=rawget(_G,"CHAMPION_SKILL_TYPE_"..name)
        if native~=nil and kind==native then slottable=true end
    end
    if not slottable or Try(WouldChampionSkillNodeBeUnlocked,id,points)~=true then return false end
    local jumps=Try(DoesChampionSkillHaveJumpPoints,id)
    if jumps==false then return true end
    if jumps~=true or type(GetChampionSkillJumpPoints)~="function" then return false end
    local ok,values=pcall(function() return {GetChampionSkillJumpPoints(id)} end)
    if not ok or #values>64 then return false end
    local minimum
    for _,value in ipairs(values) do
        value=NaturalNumber(value,maximum)
        if not value then return false end
        if value>0 and (not minimum or value<minimum) then minimum=value end
    end
    return minimum~=nil and points>=minimum
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

function SC:OnConsumableUsed()
    -- Refresh readiness once after the item event; there are no consumption reports.
    if self.ScheduleRefresh and not self.inCombat then self:ScheduleRefresh("consumable used", 250) end
end
