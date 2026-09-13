-- Recipient-aware observations. A missing remote snapshot is not proof of a missing buff.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Catalog, History = SC.Catalog, SC.History
local EM = EVENT_MANAGER

local function FiniteNumber(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function NormalizeEffectName(value)
    return tostring(value or ""):gsub("%^.*$", ""):gsub("’", "'"):lower()
end

local function EffectId(value)
    value=FiniteNumber(value)
    if not value or value<=0 or value>2147483647 or value%1~=0 then return nil end
    return value
end

function SC:RebuildEffectIndex()
    self.effectIdIndex, self.effectNameIndex, self.effectReadableKeys = {}, {}, {}
    for key, effect in pairs(Catalog.effects) do
        self.effectNameIndex[NormalizeEffectName(effect.label)] = key
        for _, alias in ipairs(effect.aliases or {}) do self.effectNameIndex[NormalizeEffectName(alias)] = key end
        for _, rawId in ipairs(effect.abilityIds or {}) do
            local id=EffectId(rawId)
            if id then self.effectIdIndex[id] = key; self.effectReadableKeys[key] = true end
        end
        for id, enabled in pairs(self.sv.customCatalog[key] or {}) do
            id = EffectId(id)
            if enabled and id then self.effectIdIndex[id] = key; self.effectReadableKeys[key] = true end
        end
    end
    for name, key in pairs({
        ["major brutality"]="major_brutality_sorcery", ["major sorcery"]="major_brutality_sorcery",
        ["minor brutality"]="minor_brutality_sorcery", ["minor sorcery"]="minor_brutality_sorcery",
        ["major savagery"]="major_savagery_prophecy", ["major prophecy"]="major_savagery_prophecy",
        ["minor savagery"]="minor_savagery_prophecy", ["minor prophecy"]="minor_savagery_prophecy",
    }) do self.effectNameIndex[NormalizeEffectName(name)] = key end
end

function SC:ObserveEffectsOnUnit(unitTag)
    local observed, raw = {}, {}
    if not unitTag or not GetNumBuffs or not GetUnitBuffInfo then return observed, false, raw end
    if not self.effectIdIndex then self:RebuildEffectIndex() end
    local count = self.Try(GetNumBuffs, unitTag)
    if type(count)~="number" or count~=count or count==math.huge or count==-math.huge then return observed, false, raw end
    count=math.max(0,math.floor(count))
    local complete = true
    local now = self.NowMs()
    local subject = self:GetObservationSubject(unitTag)
    self.observerHasData = self.observerHasData or {}
    if count > 0 then self.observerHasData[subject] = true end
    for index = 1, math.min(count, History.MAX_EFFECTS_PER_UNIT) do
        local ok, name, started, ending, slot, stacks, icon, _, effectType, _, statusType, abilityId, _, castByPlayer = pcall(GetUnitBuffInfo, unitTag, index)
        if not ok then complete = false
        elseif abilityId and abilityId > 0 then
            local key = self.effectIdIndex[abilityId] or self.effectNameIndex[NormalizeEffectName(name)]
            local value = {name=name, abilityId=abilityId, started=started, ending=ending, stacks=tonumber(stacks) or 0,
                icon=icon, slot=slot, effectType=effectType, statusEffectType=statusType, castByPlayer=castByPlayer,
                observedAt=now, evidence=self.effectIdIndex[abilityId] and "ABILITY_ID" or "OBSERVED_NAME"}
            if key then
                -- Cache a witnessed identity for this session; do not silently persist guessed IDs.
                self.effectIdIndex[abilityId] = key
                self.effectReadableKeys[key] = true
                if not observed[key] or value.stacks > observed[key].stacks then observed[key] = value end
            end
            if self.sv.collectAllEffects then raw[abilityId] = value end
        end
    end
    if count > History.MAX_EFFECTS_PER_UNIT then complete = false; if self.pull then self.pull.truncated = true end end
    return observed, complete, raw
end

function SC:GetObservationSubject(unitTag)
    if self:IsSelf(unitTag) then return "player:" .. self:GetPlayerKey("player") end
    if unitTag:match("^boss%d+$") or unitTag == "reticleover" then
        local name = self.Try(GetUnitName, unitTag) or unitTag
        -- ESO exposes combat-event unit IDs, but no general GetUnitId(unitTag)
        -- getter. The current unit tag plus observed name is stable for this pull.
        return "boss:" .. tostring(unitTag .. ":" .. name)
    end
    return "player:" .. self:GetPlayerKey(unitTag)
end

function SC:GetBossObservations()
    local result = {}
    for index = 1, 6 do
        local tag = "boss" .. index
        if self.Try(DoesUnitExist, tag) == true and self.Try(IsUnitDead, tag) ~= true then
            local effects, complete, raw = self:ObserveEffectsOnUnit(tag)
            result[#result + 1] = {subject=self:GetObservationSubject(tag), name=self.Try(GetUnitName, tag) or tag,
                effects=effects, complete=complete, raw=raw}
        end
    end
    -- Reticle data is a distinct target, never OR-merged into other bosses.
    if #result == 0 and self.Try(DoesUnitExist, "reticleover") == true and self.Try(IsUnitAttackable, "reticleover") == true then
        local effects, complete, raw = self:ObserveEffectsOnUnit("reticleover")
        result[1] = {subject=self:GetObservationSubject("reticleover"), name=self.Try(GetUnitName, "reticleover") or "Observed target", effects=effects, complete=complete, raw=raw}
    end
    return result
end

local function EffectValue(sc, key, observed, canProveAbsence)
    local value = observed and observed[key]
    if value then
        local required = FiniteNumber((sc.pull and sc.pull.rules and sc.pull.rules[key] or sc:GetEffectRule(key)).expectedStacks) or 1
        required=math.max(1,math.min(100,required))
        if required > 1 then
            local stacks=FiniteNumber(value.stacks)
            if not stacks then return nil end
            if stacks < required then return 0 end
        end
        return 1
    end
    local proven = canProveAbsence == true and sc.effectReadableKeys and sc.effectReadableKeys[key]
    if type(canProveAbsence)=="table" then proven=canProveAbsence[key]==true end
    if proven then return 0 end
    return nil
end

function SC:RecordObservation(subject, name, effects, complete, raw, scope, now, expiry)
    local pull = self.pull
    if not pull then return end
    if not pull.subjects[subject] then
        if (pull.subjectCount or 0) >= History.MAX_SUBJECTS then pull.truncated = true; return end
        pull.subjectCount = (pull.subjectCount or 0) + 1
        pull.subjects[subject] = name
    end
    for _, key in ipairs(pull.requirements) do
        local effect = Catalog.effects[key]
        if effect and ((scope == "boss" and effect.boss) or (scope == "player" and not effect.boss)) then
            local value = EffectValue(self, key, effects, complete)
            local validUntil = expiry
            local active = effects and effects[key]
            local ending=active and FiniteNumber(active.ending)
            if ending and ending > 0 then validUntil = math.min(validUntil, ending * 1000) end
            History.Observe(pull, subject, key, now, value, validUntil, {scope=scope, label=effect.label, evidence=active and active.evidence or "SAMPLED", targetUptime=(pull.rules and pull.rules[key] or self:GetEffectRule(key)).uptimeTarget})
        end
    end
    if self.sv.logRawEffects then
        local present = {}
        for id, value in pairs(raw or {}) do
            local key = "ability:" .. id
            present[key] = true
            local ending=FiniteNumber(value.ending)
            local expires = ending and ending > 0 and math.min(expiry, ending * 1000) or expiry
            History.Observe(pull, subject, key, now, 1, expires, {scope=scope, label=value.name, evidence="RAW_ABILITY_ID"})
        end
        for _, metric in pairs(pull.metrics) do
            if metric.subject == subject and metric.key:find("ability:", 1, true) == 1 and not present[metric.key] then
                History.Observe(pull, subject, metric.key, now, complete==true and 0 or nil, expiry)
            end
        end
    end
end

function SC:SampleLiveCoverage()
    if not self.inCombat or not self.sv or not self.sv.enabled then return end
    local now = self.NowMs()
    local own, ownComplete, ownRaw = self:ObserveEffectsOnUnit("player")
    self.localLive = {capabilities=own, updatedAt=now, complete=ownComplete}
    self.rawObserved = ownRaw
    if self.ShareLiveSnapshot then self:ShareLiveSnapshot() end
    if self.SharePullIdentity then self:SharePullIdentity() end
    self:SamplePotionEvidence()
    if self.SharePotionEvidence then self:SharePotionEvidence() end
    local bosses = self:GetBossObservations()
    if self.pull and self.pull.meta.bossName=="Unidentified encounter" and #bosses>0 then
        local meta=self:GetEncounterMetadata()
        if meta.bossName~="Unidentified encounter" then meta.timestamp=self.pull.meta.timestamp; self.pull.meta=meta end
    end
    local recipients = {}
    for _, player in ipairs(self.roster or {}) do
        if self.pull and not self.pull.potions[player.key] then
            self.pull.potions[player.key]={evidence=player.asui and "ASUI_DATA_NOT_RECEIVED" or "NO_ASUI_DATA",count=0,inferredCount=0,opportunitiesMs=0,categoryMonitoring=false,cooldownMonitoring=false}
        end
        if player.connected ~= false and self.Try(IsUnitDead, player.unitTag) ~= true then
            local effects, complete, raw, expiry
            if self:IsSelf(player.unitTag) then
                effects, complete, raw, expiry = own, ownComplete, ownRaw, now + 2000
            elseif player.liveCapabilities and now - (player.liveUpdatedAt or 0) <= 5500 then
                -- ASUI LIVE is usable positive evidence even before its build arrives.
                effects, complete, expiry = player.liveCapabilities, player.liveKnownKeys or false, (player.liveUpdatedAt or now) + 5500
            else
                -- Best-effort native observations of non-ASUI group members. Positive only.
                effects, _, raw = self:ObserveEffectsOnUnit(player.unitTag)
                complete, expiry = false, now + 2000
            end
            recipients[#recipients + 1] = {player=player, effects=effects or {}, complete=complete, expiry=expiry}
            self:RecordObservation("player:" .. player.key, player.displayName, effects, complete, raw, "player", now, expiry)
        end
    end
    for _, boss in ipairs(bosses) do
        self:RecordObservation(boss.subject, boss.name, boss.effects, boss.complete and self.observerHasData[boss.subject], boss.raw, "boss", now, now + 2000)
    end
    for _, row in ipairs(self.coverage and self.coverage.entries or {}) do
        local rule = self.pull and self.pull.rules and self.pull.rules[row.key] or self:GetEffectRule(row.key)
        row.liveKnown, row.live, row.liveCount, row.liveTotal, row.liveUnknown = false, nil, 0, 0, 0
        if rule.enabled then
            if row.effect.boss then
                row.targets = {}
                for _, boss in ipairs(bosses) do
                    local value = EffectValue(self, row.key, boss.effects, boss.complete and self.observerHasData[boss.subject])
                    row.targets[#row.targets + 1] = {name=boss.name, value=value}
                    row.liveTotal = row.liveTotal + 1
                    if value == 1 then row.liveCount = row.liveCount + 1 end
                    if value == nil then row.liveUnknown = row.liveUnknown + 1 end
                end
            else
                local eligible = 0
                for _, recipient in ipairs(recipients) do
                    if not rule.targetRole or rule.targetRole == recipient.player.role then
                        eligible = eligible + 1
                        local value = EffectValue(self, row.key, recipient.effects, recipient.complete)
                        if value == 1 then row.liveCount = row.liveCount + 1 end
                        if value == nil then row.liveUnknown = row.liveUnknown + 1 end
                    end
                end
                row.liveTotal = math.min(eligible, rule.targetCount or eligible)
            end
            row.liveCount = math.min(row.liveCount, row.liveTotal)
            if row.liveTotal > 0 then
                if row.liveCount >= row.liveTotal then row.liveKnown, row.live = true, true
                elseif row.liveUnknown == 0 then row.liveKnown, row.live = true, false end
                local value = row.liveKnown and (row.liveCount / row.liveTotal) or nil
                History.Observe(self.pull, "group", row.key, now, value, now + 2000, {scope="group", label=row.effect.label, evidence="RECIPIENT_COVERAGE", targetUptime=rule.uptimeTarget})
            end
        end
    end
    if self.RefreshHUD then self:RefreshHUD() end
end

function SC:SetLiveUpdateActive(enabled)
    enabled = enabled == true
    if self.liveUpdateActive == enabled then return end
    self.liveUpdateActive = enabled
    local name = "AlphaSquadUI_SupportCoverage_Live"
    if enabled then
        EM:RegisterForUpdate(name, 1500, function() SC:SampleLiveCoverage() end)
    else EM:UnregisterForUpdate(name) end
end

function SC:ScheduleObservation()
    if self.observationPending or not self.inCombat or not self.sv.enabled then return end
    self.observationPending = true
    zo_callLater(function()
        SC.observationPending = false
        if SC.inCombat and SC.sv.enabled then
            local now = SC.NowMs()
            local effects, complete, raw = SC:ObserveEffectsOnUnit("player")
            SC.localLive = {capabilities=effects, updatedAt=now, complete=complete}
            SC.rawObserved = raw
            SC:RecordObservation("player:" .. SC:GetPlayerKey("player"), SC:GetPlayerKey("player"), effects, complete, raw, "player", now, now + 2000)
        end
    end, 100)
end
