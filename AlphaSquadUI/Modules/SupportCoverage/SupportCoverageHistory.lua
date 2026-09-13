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
    local size = tonumber(self.Try(GetGroupSize)) or 0
    if size~=size or size==math.huge or size==-math.huge then return nil end
    size=math.max(0,math.floor(size))
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
    if type(session) ~= "table" then return end
    session.pulls = type(session.pulls) == "table" and session.pulls or {}
    limit=tonumber(limit)
    if not limit or limit~=limit or limit==math.huge or limit==-math.huge then limit=20 end
    limit = math.max(1, math.min(50, math.floor(limit)))
    local count=0
    for index=#session.pulls,1,-1 do
        local report=session.pulls[index]
        if type(report)~="table" or type(report.rows)~="table" then table.remove(session.pulls,index)
        else count=count+#report.rows end
    end
    while #session.pulls > limit or count > History.MAX_HISTORY_METRICS do
        local removed=table.remove(session.pulls,1)
        if not removed then break end
        count=count-#removed.rows
    end
    session.metricCount=count
end

local function Number(value, minimum, maximum, fallback)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return fallback end
    return math.max(minimum,math.min(maximum,value))
end

local function Text(value, fallback, maximum)
    if type(value)~="string" then return fallback end
    return value:sub(1,maximum or 160)
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
    local now=Number(self.Try(GetTimeStamp),0,4294967295,nil)
    local savedAt=Number(saved and saved.savedAt,0,4294967295,nil)
    local fingerprint=self:GetGroupFingerprint()
    if not self.sv.persistHistory or not self.sv.historyEnabled or type(saved)~="table" or saved.version~=1
        or not fingerprint or saved.fingerprint~=fingerprint or not now or not savedAt
        or now-savedAt<0 or now-savedAt>21600 or type(saved.pulls)~="table" then
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
            local cleanRows={}
            for _,row in ipairs(rows) do
                cleanRows[#cleanRows+1]={
                    subject=Text(row.subject,"unknown",180), key=Text(row.key,"unknown",100),
                    label=Text(row.label,nil,160), scope=Text(row.scope,nil,20), evidence=Text(row.evidence,"UNKNOWN",80),
                    targetUptime=Number(row.targetUptime,0,100,0), minimumMeasured=Number(row.minimumMeasured,0,100,80),
                    knownMs=Number(row.knownMs,0,21600000,0), upMs=Number(row.upMs,0,21600000,0),
                    unknownMs=Number(row.unknownMs,0,21600000,0), longestGapMs=Number(row.longestGapMs,0,21600000,0),
                    uptime=Number(row.uptime,0,100,nil),
                }
            end
            local meta=report.meta
            local clean={
                id=Number(report.id,0,1000000,#valid+1), label=Text(report.label,"Recovered pull",180),
                durationMs=Number(report.durationMs,0,21600000,0), rows=cleanRows,
                profile=Text(report.profile,"full",24), truncated=report.truncated==true,
                meta={zoneId=Number(meta.zoneId,0,2147483647,nil), zoneName=Text(meta.zoneName,"Unknown raid",160),
                    bossName=Text(meta.bossName,"Unidentified encounter",160), difficulty=Number(meta.difficulty,0,20,nil),
                    key=Text(meta.key,"recovered",240), timestamp=Number(meta.timestamp,0,4294967295,nil)},
                potions={}, subjects={},
            }
            local subjectCount=0
            for key,value in pairs(type(report.subjects)=="table" and report.subjects or {}) do
                if subjectCount>=History.MAX_SUBJECTS then break end
                if type(key)=="string" and type(value)=="string" then clean.subjects[Text(key,"",180)]=Text(value,"Unknown",160);subjectCount=subjectCount+1 end
            end
            local potionCount=0
            for key,value in pairs(type(report.potions)=="table" and report.potions or {}) do
                if potionCount>=12 then break end
                if type(key)=="string" and type(value)=="table" then
                    clean.potions[Text(key,"",180)]={count=Number(value.count,0,1000,0),inferredCount=Number(value.inferredCount,0,1000,0),
                        opportunitiesMs=Number(value.opportunitiesMs,0,21600000,0),evidence=Text(value.evidence,"UNKNOWN",80),
                        categoryMonitoring=value.categoryMonitoring==true,cooldownMonitoring=value.cooldownMonitoring==true,
                        exactItemVerified=value.exactItemVerified==true}
                    potionCount=potionCount+1
                end
            end
            valid[#valid+1]=clean
        end
    end
    local session={pulls=valid,counters={},sequence=Number(saved.sequence,0,1000000,#valid),
        generation=Number(saved.generation,0,1000000,0),fingerprint=fingerprint,savedAt=now,version=1}
    local counterCount=0
    for key,value in pairs(type(saved.counters)=="table" and saved.counters or {}) do
        if counterCount>=100 then break end
        if type(key)=="string" and key~="" and Number(value,0,100000,nil) then
            session.counters[Text(key,"",240)]=Number(value,0,100000,0)
            counterCount=counterCount+1
        end
    end
    self.historySession=session
    History.Trim(session,self.sv.historyLimit)
    self.lastPull=session.pulls[#session.pulls]
end

function SC:EnsureHistorySession()
    if self.historySession then return self.historySession end
    self.historySession = {pulls={}, counters={}, sequence=0, generation=0}
    return self.historySession
end

function SC:ResetHistory(reason)
    local previous = self.historySession
    self.historySession = {pulls={}, counters={}, sequence=0, generation=(previous and previous.generation or 0) + 1, resetReason=reason}
    self.combatEndGeneration=(self.combatEndGeneration or 0)+1
    self.inCombat=false
    if self.SetLiveUpdateActive then self:SetLiveUpdateActive(false) end
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
        if self.ResetSharingState then self:ResetSharingState("Left group / disbanded")
        else self.peerData, self.remotePlan, self.detailReceivers = {}, nil, {} end
        self.lastCompletedGroupToken=nil
        self.wasGrouped = false
        return false
    end
    local newlyGrouped = self.wasGrouped ~= true
    self:RestoreHistorySession()
    self.wasGrouped = true
    self:EnsureHistorySession()
    self:SaveHistorySession()
    if newlyGrouped and self.sv.enabled and self.sv.shareData and self.sv.experimentalSharing then
        -- A client that joins an already formed group also needs to advertise its
        -- current build; it cannot rely on receiving MEMBER_JOINED for itself.
        self.buildSharePending = true
        self.detailSharePending = true
    end
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
    if not pull then
        if self.SetLiveUpdateActive then self:SetLiveUpdateActive(false) end
        return
    end
    local now = self.NowMs()
    if pull.meta.bossName == "Unidentified encounter" then
        local discovered = self:GetEncounterMetadata()
        if discovered.bossName ~= "Unidentified encounter" then discovered.timestamp=pull.meta.timestamp; pull.meta = discovered end
    end
    local rows = History.Finish(pull, now)
    self.lastCompletedGroupToken = pull.groupToken
    self.pull = nil
    self:SetLiveUpdateActive(false)
    if not self.sv.historyEnabled or not self:IsGrouped() then self.lastPull=nil;return end

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
    -- Keep a report even after its window is closed, but never retain solo history.
    table.insert(session.pulls, report)
    History.Trim(session,self.sv.historyLimit)
    self:SaveHistorySession()
    self.lastPull = report
    if self.sv.enabled and self.sv.reportAutoOpen and self.OpenPullReport and not self.uiObscured then self:OpenPullReport(report) end
    if self.sv.enabled and not self.sv.reportAutoOpen and self.ShowPullSummaryBanner and not self.uiObscured then self:ShowPullSummaryBanner(report) end
end

function SC:GetHistoryPulls()
    return self:EnsureHistorySession().pulls
end
