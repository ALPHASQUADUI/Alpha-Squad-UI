-- Bounded raid-session summaries. No raw combat log or per-frame samples are retained.
local SC = AlphaSquadUI.Modules.SupportCoverage
local History = {MAX_METRICS=1024, MAX_SUBJECTS=20, MAX_EFFECTS_PER_UNIT=192, MAX_HISTORY_METRICS=6000}
SC.History = History

local function Flush(metric, now)
    local elapsed = math.max(0, now - metric.at)
    local knownElapsed = 0
    if metric.value ~= nil then
        knownElapsed = math.min(elapsed, math.max(0, (metric.validUntil or now) - metric.at))
        metric.knownMs = metric.knownMs + knownElapsed
        metric.upMs = metric.upMs + knownElapsed * metric.value
        if metric.value == 0 then
            metric.currentGapMs = metric.currentGapMs + knownElapsed
            metric.longestGapMs = math.max(metric.longestGapMs, metric.currentGapMs)
        else metric.currentGapMs = 0 end
    end
    metric.unknownMs = metric.unknownMs + elapsed - knownElapsed
    if knownElapsed < elapsed then metric.currentGapMs = 0 end
    metric.at = now
end
History.Flush = Flush

function History.Observe(pull, subject, effectKey, now, value, validUntil, meta)
    if not pull or not subject or not effectKey then return end
    local id = subject .. "|" .. effectKey
    local metric = pull.metrics[id]
    if not metric then
        if pull.metricCount >= History.MAX_METRICS then pull.truncated = true; return end
        metric = {subject=subject, key=effectKey, at=pull.startedAt, knownMs=0, upMs=0, unknownMs=0,
            currentGapMs=0, longestGapMs=0, value=nil, label=meta and meta.label, scope=meta and meta.scope,
            evidence=meta and meta.evidence or "OBSERVED",
            targetUptime=meta and meta.targetUptime or 0, minimumMeasured=pull.minimumMeasured or 80}
        pull.metrics[id] = metric
        pull.metricCount = pull.metricCount + 1
    end
    Flush(metric, now)
    metric.value = nil
    if value ~= nil then metric.value = math.max(0, math.min(1, value)) end
    metric.validUntil = validUntil or now
    if value ~= 0 then metric.currentGapMs = 0 end
end

function History.Finish(pull, now)
    local summary = {}
    for _, metric in pairs(pull.metrics) do
        Flush(metric, now)
        summary[#summary + 1] = {
            subject=metric.subject, key=metric.key, label=metric.label, scope=metric.scope, evidence=metric.evidence,
            targetUptime=metric.targetUptime, minimumMeasured=metric.minimumMeasured,
            knownMs=math.floor(metric.knownMs), upMs=math.floor(metric.upMs), unknownMs=math.floor(metric.unknownMs),
            longestGapMs=math.floor(metric.longestGapMs),
            uptime=metric.knownMs > 0 and math.floor(metric.upMs / metric.knownMs * 1000 + 0.5) / 10 or nil,
        }
    end
    table.sort(summary, function(a, b)
        if a.subject ~= b.subject then return a.subject < b.subject end
        return (a.label or a.key) < (b.label or b.key)
    end)
    return summary
end

function History.Assess(metric, durationMs)
    local target=tonumber(metric.targetUptime) or 0
    if target<=0 then return "NOT_CONFIGURED" end
    if not metric.uptime or not durationMs or durationMs<=0 then return "UNKNOWN" end
    local measured=(metric.knownMs or 0)/durationMs*100
    if measured<(metric.minimumMeasured or 80) then return "INSUFFICIENT_DATA" end
    return metric.uptime>=target and "PASS" or "BELOW_TARGET"
end

function SC:GetEncounterMetadata()
    local zoneId = self.Try(GetZoneId, self.Try(GetUnitZoneIndex,"player"))
    local zoneName = self.Try(GetUnitZone, "player") or "Unknown raid"
    local names, seen = {}, {}
    for index = 1, 6 do
        local tag = "boss" .. index
        if self.Try(DoesUnitExist, tag) == true then
            local name = self.Try(GetUnitName, tag)
            if name and name ~= "" and not seen[name] then names[#names + 1] = name; seen[name] = true end
        end
    end
    table.sort(names)
    local bossName = #names > 0 and table.concat(names, " + ") or "Unidentified encounter"
    local difficulty = self.Try(GetCurrentZoneDungeonDifficulty)
    return {
        zoneId=zoneId, zoneName=zoneName, bossName=bossName, difficulty=difficulty,
        key=tostring(zoneId or zoneName) .. ":" .. tostring(difficulty or "unknown") .. ":" .. bossName,
        timestamp=GetTimeStamp and GetTimeStamp() or nil,
        -- No guessed hard-mode state or fabricated encounter IDs.
        hardMode=nil,
    }
end

function SC:GetGroupFingerprint()
    if not self:IsGrouped() then return nil end
    local names = {}
    local size = self.Try(GetGroupSize) or 0
    if size <= 0 then return nil end
    for index=1, math.min(12,size) do
        local tag = self.Try(GetGroupUnitTagByIndex,index)
        local name = tag and self.Try(GetUnitDisplayName,tag)
        if not name or name == "" then return nil end
        names[#names+1] = name
    end
    table.sort(names)
    return table.concat(names,"|") .. ":" .. tostring(self.Try(GetUnitName,"player") or "")
end

function History.Trim(session, limit)
    local count=0
    for _, report in ipairs(session.pulls) do count=count+#report.rows end
    while #session.pulls > limit or count > History.MAX_HISTORY_METRICS do
        local removed=table.remove(session.pulls,1)
        if not removed then break end
        count=count-#removed.rows
    end
    session.metricCount=count
end

function SC:SaveHistorySession()
    local session=self.historySession
    if not session or not self.sv.persistHistory or not self.sv.historyEnabled or not self:IsGrouped() then
        self.sv.raidHistory=nil; return
    end
    session.fingerprint=self:GetGroupFingerprint()
    session.savedAt=self.Try(GetTimeStamp)
    session.version=1
    self.sv.raidHistory=session
end

function SC:RestoreHistorySession()
    if self.historyRestored then return end
    self.historyRestored=true
    local saved=self.sv.raidHistory
    local now=self.Try(GetTimeStamp)
    local fingerprint=self:GetGroupFingerprint()
    if not self.sv.persistHistory or type(saved)~="table" or saved.version~=1
        or not fingerprint or saved.fingerprint~=fingerprint or not now or not tonumber(saved.savedAt)
        or now-saved.savedAt<0 or now-saved.savedAt>21600 or type(saved.pulls)~="table" then
        self.sv.raidHistory=nil; return
    end
    local valid={}
    for index=math.max(1,#saved.pulls-49),#saved.pulls do
        local report=saved.pulls[index]
        if type(report)=="table" and type(report.meta)=="table" and type(report.label)=="string"
            and type(report.durationMs)=="number" and report.durationMs>=0 and type(report.rows)=="table" then
            local rows={}
            for i=1,math.min(#report.rows,History.MAX_METRICS) do
                local row=report.rows[i]
                if type(row)=="table" and type(row.subject)=="string" and type(row.key)=="string"
                    and type(row.knownMs)=="number" and type(row.unknownMs)=="number" then rows[#rows+1]=row end
            end
            report.rows=rows;valid[#valid+1]=report
        end
    end
    saved.pulls=valid
    saved.counters=type(saved.counters)=="table" and saved.counters or {}
    saved.sequence=tonumber(saved.sequence) or #valid
    saved.generation=tonumber(saved.generation) or 0
    self.historySession=saved
    History.Trim(saved,self.sv.historyLimit)
    self.lastPull=saved.pulls[#saved.pulls]
end

function SC:EnsureHistorySession()
    if self.historySession then return self.historySession end
    self.historySession = {pulls={}, counters={}, sequence=0, generation=0}
    return self.historySession
end

function SC:ResetHistory(reason)
    local previous = self.historySession
    self.historySession = {pulls={}, counters={}, sequence=0, generation=(previous and previous.generation or 0) + 1, resetReason=reason}
    self.pull, self.lastPull, self.potionObservation = nil, nil, nil
    if self.sv then self.sv.raidHistory=nil end
    self.historySelection = nil
    if self.ClosePullReport then self:ClosePullReport() end
    if self.inspectorWindow and self.inspectorTab == "HISTORY" then
        for _,row in ipairs(self.inspectorWindow.rows or {}) do row.action=nil end
    end
    if self.inspectorWindow and self.inspectorTab == "HISTORY" and self.RefreshInspector then self:RefreshInspector() end
end

function SC:CheckGroupSession()
    if not self.groupSessionReady then return self:IsGrouped() end
    if not self:IsGrouped() then
        self.sv.raidHistory=nil
        self.historyRestored=false
        if self.wasGrouped or self.historySession and #self.historySession.pulls > 0 then self:ResetHistory("Left group / disbanded") end
        self.peerData, self.remotePlan, self.detailReceivers = {}, nil, {}
        self.lastCompletedGroupToken=nil
        if self.share then self.share.detailTransfer=nil; self.share.lastDetailText=nil end
        self.wasGrouped = false
        return false
    end
    self:RestoreHistorySession()
    self.wasGrouped = true
    self:EnsureHistorySession()
    self:SaveHistorySession()
    return true
end

function SC:StartPull()
    if not self.sv or not self.sv.enabled then return end
    self.potionObservation = nil
    if self.reportWindow then self.reportWindow:SetHidden(true) end
    if self.inspectorWindow then self.inspectorWindow:SetHidden(true) end
    if self.matrixWindow then self:CloseMatrix() end
    if self.assignmentBanner then self.assignmentBanner:SetHidden(true) end
    local meta = self:GetEncounterMetadata()
    local requirements=self.Catalog:GetRequirements(self.sv.activeProfile,self.sv)
    local recorded={};for _,key in ipairs(requirements) do recorded[key]=true end
    if self.sv.trackPotionBuffs then
        for _,key in ipairs({"major_brutality_sorcery","major_savagery_prophecy","major_intellect","major_endurance","major_fortitude","minor_heroism"}) do
            if not recorded[key] then requirements[#requirements+1]=key end
        end
    end
    local rules, potions = {}, {}
    for _,key in ipairs(requirements) do rules[key]=self:GetEffectRule(key) end
    for _,player in ipairs(self.roster or {}) do
        potions[player.key or player.displayName]={evidence=player.asui and "ASUI_DATA_NOT_RECEIVED" or "NO_ASUI_DATA",
            count=0,inferredCount=0,opportunitiesMs=0,categoryMonitoring=false,cooldownMonitoring=false}
    end
    self.pull = {startedAt=self.NowMs(), meta=meta, metrics={}, metricCount=0, potions=potions, subjects={}, truncated=false,
        requirements=requirements, rules=rules, minimumMeasured=self.sv.minimumMeasuredPercent,
        profile=self.sv.activeProfile}
    self.observerHasData = {}
end

function SC:FinalizePull()
    local pull = self.pull
    if not pull then return end
    local now = self.NowMs()
    if pull.meta.bossName == "Unidentified encounter" then
        local discovered = self:GetEncounterMetadata()
        if discovered.bossName ~= "Unidentified encounter" then discovered.timestamp=pull.meta.timestamp; pull.meta = discovered end
    end
    local rows = History.Finish(pull, now)
    local session = self:EnsureHistorySession()
    local counter = (tonumber(session.counters[pull.meta.key]) or 0) + 1
    local counterCount=0
    for _ in pairs(session.counters) do counterCount=counterCount+1 end
    if counterCount >= 100 and not session.counters[pull.meta.key] then session.counters = {} end
    session.counters[pull.meta.key] = counter
    session.sequence = session.sequence + 1
    local report = {
        id=session.sequence, meta=pull.meta, label=pull.meta.bossName .. " - Pull " .. counter,
        durationMs=math.max(0, now - pull.startedAt), rows=rows, potions=pull.potions,
        truncated=pull.truncated, profile=pull.profile, subjects=pull.subjects,
    }
    self.lastCompletedGroupToken = pull.groupToken
    self.pull = nil
    self:SetLiveUpdateActive(false)
    -- Keep a report even after its window is closed, but never retain solo history.
    if self.sv.historyEnabled and self:IsGrouped() then
        table.insert(session.pulls, report)
        History.Trim(session,self.sv.historyLimit)
        self:SaveHistorySession()
        self.lastPull = report
        if self.sv.enabled and self.sv.reportAutoOpen and self.OpenPullReport and not self.uiObscured then self:OpenPullReport(report) end
    else self.lastPull = nil end
end

function SC:GetHistoryPulls()
    return self:EnsureHistorySession().pulls
end
