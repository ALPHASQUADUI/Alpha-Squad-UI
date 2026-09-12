-- On-demand, paginated build inspection and pull reports. No OnUpdate handlers.
local SC = AlphaSquadUI.Modules.SupportCoverage
local C = AlphaSquadUI.Theme.colors
local PAGE_SIZE = 12
local ROLES = {"UNKNOWN","MT","OT","H1","H2","DD PARSE","DD SUPPORT"}

local function SafeText(value)
    return tostring(value or "UNKNOWN"):gsub("|", "||"):gsub("[\r\n]", " ")
end
local function Next(list, current)
    for index, value in ipairs(list) do if value == current then return list[index % #list + 1] end end
    return list[1]
end
local function Label(parent, name, font, text, width, height, x, y)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetDimensions(width, height)
    label:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    label:SetColor(C.white[1], C.white[2], C.white[3], 1)
    label:SetText(text or "")
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetMaxLineCount(1)
    if label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
    return label
end
local function Button(parent, name, text, x, y, width, action)
    local button = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    button:SetDimensions(width, 28)
    button:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    button:SetMouseEnabled(true)
    local bg = WINDOW_MANAGER:CreateControl(name .. "BG", button, CT_TEXTURE)
    bg:SetAnchorFill(button); bg:SetColor(0.04,0.065,0.10,1)
    button.label = Label(button, name .. "Label", "ZoFontGameSmall", text, width-8, 28, 4, 0)
    button.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    button:SetHandler("OnMouseUp", function(_, which, inside)
        if which == MOUSE_BUTTON_INDEX_LEFT and inside ~= false and action then action() end
    end)
    return button
end
local function CreateWindow(name, title, close)
    local win = WINDOW_MANAGER:CreateTopLevelWindow(name)
    win:SetDimensions(1000, 750); win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetClampedToScreen(true); win:SetDrawTier(DT_HIGH); win:SetDrawLayer(DL_OVERLAY); win:SetDrawLevel(150)
    win:SetMouseEnabled(true); win:SetMovable(true); win:SetHidden(true)
    local bg = WINDOW_MANAGER:CreateControl(name .. "BG", win, CT_TEXTURE)
    bg:SetAnchorFill(win); bg:SetColor(C.bg[1],C.bg[2],C.bg[3],0.99)
    win.title = Label(win, name .. "Title", "ZoFontWinH2", title, 860, 35, 18, 10)
    win.subtitle = Label(win, name .. "Subtitle", "ZoFontGameSmall", "", 960, 26, 18, 47)
    Button(win, name .. "Close", "CLOSE", 900, 14, 80, close)
    local drag = WINDOW_MANAGER:CreateControl(name .. "Drag", win, CT_CONTROL)
    drag:SetDimensions(870, 40); drag:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0); drag:SetMouseEnabled(true)
    drag:SetHandler("OnMouseDown", function(_, b) if b == MOUSE_BUTTON_INDEX_LEFT then win:StartMoving() end end)
    drag:SetHandler("OnMouseUp", function(_, b) if b == MOUSE_BUTTON_INDEX_LEFT then win:StopMovingOrResizing() end end)
    win.rows = {}
    for index=1,PAGE_SIZE do
        local row = WINDOW_MANAGER:CreateControl(name .. "Row" .. index, win, CT_CONTROL)
        row:SetDimensions(960, 41); row:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 168+(index-1)*43)
        row.title = Label(row, name .. "RowTitle" .. index, "ZoFontGameBold", "", 800, 21, 5, 0)
        row.detail = Label(row, name .. "RowDetail" .. index, "ZoFontGameSmall", "", 800, 20, 5, 20)
        row.button = Button(row, name .. "RowAction" .. index, "", 817, 6, 138, function()
            if row.action then row.action() end
        end)
        win.rows[index] = row
    end
    win.footer = Label(win, name .. "Footer", "ZoFontGameSmall", "", 690, 26, 18, 708)
    return win
end
local function RenderRows(win, rows, page)
    local pages = math.max(1, math.ceil(#rows/PAGE_SIZE))
    page = math.max(1, math.min(pages, page or 1))
    for index, row in ipairs(win.rows) do
        local data = rows[(page-1)*PAGE_SIZE + index]
        row:SetHidden(data == nil)
        if data then
            row.title:SetText(SafeText(data.title))
            row.detail:SetText(SafeText(data.detail or ""))
            row.button.label:SetText(data.button or "")
            row.button:SetHidden(data.action == nil)
            row.action = data.action
            local color = data.color or C.white
            row.title:SetColor(color[1],color[2],color[3],1)
        else row.action = nil end
    end
    win.footer:SetText(string.format("Page %d/%d  |  %d entries  |  UNKNOWN never means FAIL or PASS", page, pages, #rows))
    return page
end

function SC:ResizeInspector()
    for _, win in ipairs({self.inspectorWindow or false, self.reportWindow or false}) do
        if win then win:SetScale(math.min(1, (GuiRoot:GetWidth()-24)/1000, (GuiRoot:GetHeight()-24)/750)) end
    end
end
function SC:GetInspectedPlayer()
    local players = self.roster or {}
    self.inspectorPlayer = math.max(1, math.min(#players, self.inspectorPlayer or 1))
    return players[self.inspectorPlayer] or self.localSnapshot
end
function SC:CloseInspector()
    if self.inspectorWindow then self.inspectorWindow:SetHidden(true) end
    self:ApplyVisibility()
end
function SC:OpenInspector(tab)
    if self.inCombat then return end
    self.inspectorTab, self.inspectorPage = tab or "CHECKS", 1
    if not self.inspectorWindow then
        local win = CreateWindow("AlphaSquadSupportInspector", "SUPPORT COVERAGE - INSPECTOR", function() SC:CloseInspector() end)
        self.inspectorWindow = win
        for index, key in ipairs({"CHECKS","BUILD","EXPECTED","EFFECTS","PLANNER","HISTORY"}) do
            Button(win, "AlphaSquadInspectorTab" .. key, key, 18+(index-1)*125, 82, 118, function()
                SC.inspectorTab, SC.inspectorPage = key, 1; SC:RefreshInspector()
            end)
        end
        Button(win, "AlphaSquadInspectorPrevPlayer", "NEXT PLAYER", 18, 120, 126, function()
            SC.inspectorPlayer = ((SC.inspectorPlayer or 1) % math.max(1,#SC.roster))+1; SC:RefreshInspector()
        end)
        win.roleButton = Button(win, "AlphaSquadInspectorRole", "ROLE", 154, 120, 155, function()
            local player = SC:GetInspectedPlayer()
            if player then
                SC.sv.roleOverrides[player.key or player.displayName] = Next(ROLES, player.role)
                SC:Refresh("inspector role")
            end
        end)
        Button(win, "AlphaSquadInspectorCapture", "CAPTURE AS EXPECTED", 319, 120, 184, function()
            local player = SC:GetInspectedPlayer()
            if player then
                local _, message = SC:CaptureExpectedBuild(player.role, player, player.key or player.displayName)
                SC.inspectorNotice = message; SC:RefreshInspector()
            end
        end)
        Button(win, "AlphaSquadInspectorClearTemplate", "CLEAR EXPECTED", 513, 120, 152, function()
            local player = SC:GetInspectedPlayer()
            if player then
                local _, key = SC:GetExpectedTemplate(player)
                SC.sv.buildTemplates[key] = nil; SC:RefreshInspector()
            end
        end)
        Button(win, "AlphaSquadInspectorResetHistory", "RESET HISTORY", 785, 82, 195, function()
            if SC.resetConfirmAt and SC.NowMs()-SC.resetConfirmAt < 5000 then
                SC.resetConfirmAt=nil; SC:ResetHistory("Manual reset"); SC.inspectorNotice="History cleared. Build settings were preserved."
            else SC.resetConfirmAt=SC.NowMs(); SC.inspectorNotice="Click RESET HISTORY again within five seconds to confirm." end
            SC:RefreshInspector()
        end)
        Button(win, "AlphaSquadInspectorPrevious", "PREVIOUS", 715, 708, 120, function()
            SC.inspectorPage=math.max(1,(SC.inspectorPage or 1)-1); SC:RefreshInspector()
        end)
        Button(win, "AlphaSquadInspectorNext", "NEXT", 845, 708, 135, function()
            SC.inspectorPage=(SC.inspectorPage or 1)+1; SC:RefreshInspector()
        end)
    end
    self:ResizeInspector(); self.inspectorWindow:SetHidden(false); self:RefreshInspector(); self:ApplyVisibility()
end

function SC:GetInspectorRows()
    local rows, player = {}, self:GetInspectedPlayer()
    local function Add(title, detail, button, action, color)
        rows[#rows + 1] = {title=title, detail=detail, button=button, action=action, color=color}
    end
    if self.inspectorTab == "CHECKS" then
        for _, key in ipairs(self.Audit.order) do
            Add(self.Audit.labels[key], "OFF: not enforced | WARN: informational | REQUIRED: mismatch blocks readiness", self.sv.checkModes[key], function()
                self.sv.checkModes[key]=Next({"OFF","WARN","REQUIRED"}, self.sv.checkModes[key]); self:Refresh("check mode"); self:RefreshInspector()
            end)
        end
        for _, item in ipairs({
            {"checkFoodPresence","Food presence check"}, {"checkMissingGlyphs","Missing armor glyph check"},
            {"historyEnabled","Record bounded raid history"}, {"persistHistory","Preserve history on UI reload in the same group"}, {"autoContextProfile","Auto-load a saved encounter profile"}, {"trackPotionBuffs","Record potion-related buff coverage (source unverified)"}, {"reportAutoOpen","Open report after each pull"},
            {"collectAllEffects","Collect all observable local effect IDs"}, {"logRawEffects","Include raw IDs in history (higher memory use)"},
            {"hideInMenus","Hide HUD in ESO menus"}, {"showReadyBanner","Show readiness banner"},
        }) do
            local key, label = item[1], item[2]
            Add(label, "Independent optional setting. No compulsory meta build.", self.sv[key] and "ON" or "OFF", function()
                self.sv[key]=not self.sv[key]; self:Refresh("option"); self:RefreshInspector()
            end)
        end
        Add("Champion discipline to compare", "Four slottables in the selected discipline; order is ignored, committed point values are checked.", self.sv.championScope, function()
            self.sv.championScope=Next({"COMBAT","CONDITIONING","WORLD","ALL"},self.sv.championScope); self:Refresh("champion scope"); self:RefreshInspector()
        end)
        Add("Minimum measured pull coverage", "Below this threshold an uptime target is INSUFFICIENT_DATA, never a pass or failure.", tostring(self.sv.minimumMeasuredPercent).."%", function()
            self.sv.minimumMeasuredPercent=Next({0,50,80,90,95,100},self.sv.minimumMeasuredPercent); self:RefreshInspector()
        end)
        Add("Maximum stored pulls", "Oldest pulls are evicted. History resets after leaving/disbanding the group.", tostring(self.sv.historyLimit), function()
            self.sv.historyLimit=Next({5,10,20,30,50}, self.sv.historyLimit)
            self.History.Trim(self:EnsureHistorySession(),self.sv.historyLimit); self:SaveHistorySession()
            self:RefreshInspector()
        end)
        Add("Report auto-close", "A new fight always closes the window. Closing never deletes the stored pull.", tostring(self.sv.reportAutoCloseSeconds) .. " seconds", function()
            self.sv.reportAutoCloseSeconds=Next({0,10,20,30,60,120}, self.sv.reportAutoCloseSeconds); self:RefreshInspector()
        end)
        Add("Experimental test sharing", "Unreserved IDs 507-510. Controlled tests only; public release is blocked.", self.sv.experimentalSharing and "ON" or "OFF", function()
            self.sv.experimentalSharing=not self.sv.experimentalSharing
            if self.sv.experimentalSharing then self:InitializeSharing(); self:MarkScanDirty("test sharing") end
            self:RefreshInspector()
        end, C.gold)
    elseif self.inspectorTab == "PLANNER" then
        Add("Build plan", "Search recorded loadouts only. No equipment changes are made.", "CALCULATE", function()
            local _,message=self:ComputeBuildPlan();self.inspectorNotice=message;self:RefreshInspector()
        end)
        if self.buildPlan then
            local plan=self.buildPlan
            Add((plan.stale and "STALE - " or "").."Suggested changes: "..plan.changes,plan.notice)
            Add("Uncovered requirements",#plan.missing>0 and table.concat(plan.missing,", ") or "All selected requirements have a potential source.")
            if plan.lockFailures>0 then Add("Assignment locks need review",tostring(plan.lockFailures).." locked requirements cannot be met by this proposal.") end
            for _,choice in ipairs(plan.choices) do
                local effects={};for key in pairs(choice.candidate.capabilities) do effects[#effects+1]=self.Catalog.effects[key].label end;table.sort(effects)
                Add(choice.player.." - "..choice.candidate.label, table.concat(effects,", "),nil,nil,choice.candidate.current and C.white or C.gold)
            end
        end
        if player then
            Add("Saved loadouts for "..tostring(player.displayName),"Capture verified builds with CAPTURE AS EXPECTED. Up to four alternatives per character.","CLEAR SAVED",function()
                self.sv.loadoutLibrary[player.key or player.displayName]=nil;self.buildPlan=nil;self:RefreshInspector()
            end)
        end
    elseif self.inspectorTab == "EFFECTS" then
        local selected=self.inspectorEffect
        if selected and self.Catalog.effects[selected] then
            local effect=self.Catalog.effects[selected]
            local rule=self:GetEffectRule(selected)
            local override=self.sv.effectRules[selected] or {};self.sv.effectRules[selected]=override
            Add(effect.label,"Profile-specific requirement; target rules are optional.","ALL EFFECTS",function() self.inspectorEffect=nil;self.inspectorPage=1;self:RefreshInspector() end)
            local wanted=false;for _,key in ipairs(self.Catalog:GetRequirements(self.sv.activeProfile,self.sv)) do if key==selected then wanted=true end end
            Add("Required in "..self.sv.activeProfile,"OFF does not discard raw observations.",wanted and "ON" or "OFF",function()
                self.sv.profileOverrides[self.sv.activeProfile]=self.sv.profileOverrides[self.sv.activeProfile] or {}
                self.sv.profileOverrides[self.sv.activeProfile][selected]=not wanted;self:Refresh("effect requirement")
            end)
            Add("Target recipients","ALL means all eligible online, living players; boss effects remain per target.",rule.targetRole or "ALL",function()
                local role=Next({"ALL","MT","OT","H1","H2","DD PARSE","DD SUPPORT"},rule.targetRole or "ALL")
                override.targetRole=role~="ALL" and role or nil;self:RefreshInspector()
            end)
            Add("Expected recipient count","0 uses all eligible recipients; the set's default limit is preserved until changed.",tostring(rule.targetCount or 0),function()
                override.targetCount=Next({0,1,2,3,4,5,6,8,10,12},rule.targetCount or 0);self:RefreshInspector()
            end)
            Add("Required stacks","Unknown remote stack data is never treated as full stacks.",tostring(rule.expectedStacks),function()
                override.expectedStacks=Next({1,2,3,4,5,6,10},rule.expectedStacks);self:RefreshInspector()
            end)
            Add("Target uptime","0 disables the target. This is compared only against measured, known time.",tostring(rule.uptimeTarget).."%",function()
                override.uptimeTarget=Next({0,50,60,70,75,80,85,90,95,98,100},rule.uptimeTarget);self:RefreshInspector()
            end)
            Add("Exact effect identifiers","Register an observed ID with /assupport custom "..selected.." <abilityId>. No unverified ID is invented.")
        else
            local wanted={};for _,key in ipairs(self.Catalog:GetRequirements(self.sv.activeProfile,self.sv)) do wanted[key]=true end
            for _,key in ipairs(self.Catalog:GetAllEffectKeys()) do
                local effect=self.Catalog.effects[key]
                Add(effect.label,effect.category.." | "..(wanted[key] and "Selected requirement" or "Optional / not required"),"CONFIGURE",function()
                    self.inspectorEffect=key;self.inspectorPage=1;self:RefreshInspector()
                end)
            end
        end
    elseif self.inspectorTab == "HISTORY" then
        local pulls=self:GetHistoryPulls()
        for index=#pulls,1,-1 do
            local pull=pulls[index]
            Add(pull.label, string.format("%s | %.1fs | %d metrics%s", pull.meta.zoneName, pull.durationMs/1000, #pull.rows, pull.truncated and " | TRUNCATED" or ""), "OPEN REPORT", function() self:OpenPullReport(pull) end)
        end
        if #pulls==0 then Add("No stored pulls", "History clears on leaving/disbanding. Optional UI-reload recovery requires the same group and expires after six hours.") end
    elseif self.inspectorTab == "EXPECTED" then
        local audit=self:EvaluateBuildAudit(player)
        if #audit.rows==0 then Add("All expectation checks are OFF", "Capture a known build, then enable only the desired checks in CHECKS.") end
        for _, check in ipairs(audit.rows) do
            Add(check.label .. " - " .. check.status, check.reason .. " Expected: " .. tostring(check.expected or "not configured") .. " | Actual: " .. tostring(check.actual or "unavailable"), nil, nil,
                check.status=="PASS" and C.green or check.status=="MISMATCH" and C.gold or C.muted)
        end
    else
        for _, key in ipairs(self.Audit.order) do
            local value=self.Audit.Value(player,key)
            Add(self.Audit.labels[key], value or ((player and player.asui) and "Unavailable or not shared by this ASUI client." or "No ASUI build data; this field cannot be analyzed."), nil,nil,value and C.white or C.muted)
        end
        if player then
            for _, set in ipairs(player.equipment and player.equipment.setList or {}) do
                Add("SET - " .. tostring(set.name), string.format("ID %s | MAIN %s | BACK %s | Presence is not proof of proc uptime", tostring(set.id), tostring(set.mainCount or "?"), tostring(set.backCount or "?")))
            end
            for _, star in ipairs(player.skills and player.skills.champion or {}) do Add("CHAMPION - " .. tostring(star.name), "Slot " .. star.slot .. " | ID " .. star.id .. " | Spent points " .. tostring(star.points or "UNKNOWN")) end
            for _, mastery in ipairs(player.masteries and player.masteries.selected or {}) do Add("CLASS MASTERY - " .. tostring(mastery.name), "ID " .. mastery.id .. " | Committed selection; eligibility checked separately") end
        end
    end
    return rows
end

function SC:RefreshInspector()
    local win=self.inspectorWindow
    if not win or win:IsHidden() then return end
    local player=self:GetInspectedPlayer()
    local heading=player and ((player.displayName or "player") .. " | " .. tostring(player.role) .. " | " .. tostring(player.dataQuality)) or "No player data"
    win.subtitle:SetText(SafeText(self.inspectorNotice or (self.inspectorTab .. " | " .. heading)))
    win.roleButton.label:SetText("ROLE: " .. tostring(player and player.role or "UNKNOWN"))
    self.inspectorPage=RenderRows(win,self:GetInspectorRows(),self.inspectorPage)
end

function SC:ClosePullReport()
    local win=self.reportWindow
    if win then win:SetHidden(true); win.report=nil end
    self.reportGeneration=(self.reportGeneration or 0)+1
end
function SC:OpenPullReport(report)
    if not report or self.inCombat then return end
    if not self.reportWindow then
        local win=CreateWindow("AlphaSquadSupportPullReport","SUPPORT PERFORMANCE",function() SC:ClosePullReport() end)
        self.reportWindow=win
        Button(win,"AlphaSquadReportPrevious","PREVIOUS",715,708,120,function() win.page=math.max(1,(win.page or 1)-1); SC:RefreshPullReport() end)
        Button(win,"AlphaSquadReportNext","NEXT",845,708,135,function() win.page=(win.page or 1)+1; SC:RefreshPullReport() end)
        Button(win,"AlphaSquadReportHistory","OPEN HISTORY",18,82,155,function() SC:ClosePullReport(); SC:OpenInspector("HISTORY") end)
        Label(win,"AlphaSquadReportEvidence","ZoFontGameSmall","Uptime is measured time only. Unknown time is shown separately. Assigned owners are not confirmed casters.",960,30,18,122)
    end
    self.reportWindow.report,self.reportWindow.page=report,1
    self:ResizeInspector(); self.reportWindow:SetHidden(false); self:RefreshPullReport()
    self.reportGeneration=(self.reportGeneration or 0)+1
    local generation=self.reportGeneration
    local delay=self.sv.reportAutoCloseSeconds
    if delay and delay>0 then zo_callLater(function() if SC.reportGeneration==generation then SC:ClosePullReport() end end,delay*1000) end
end
function SC:RefreshPullReport()
    local win=self.reportWindow
    local report=win and win.report
    if not report or win:IsHidden() then return end
    win.title:SetText(SafeText(report.label))
    win.subtitle:SetText(SafeText(string.format("%s | %.1fs | Profile %s%s",report.meta.zoneName,report.durationMs/1000,report.profile or "?",report.truncated and " | METRIC LIMIT REACHED" or "")))
    local rows={}
    local potionKeys={}; for key in pairs(report.potions or {}) do potionKeys[#potionKeys+1]=key end; table.sort(potionKeys)
    for _, key in ipairs(potionKeys) do
        local potion=report.potions[key]
        rows[#rows+1]={title=key .. " - POTION EVIDENCE", detail=string.format("Category-use events: %s | Inferred cooldown starts: %s | %s | Exact potion item: UNVERIFIED",potion.categoryMonitoring and tostring(potion.count or 0) or "UNKNOWN",potion.cooldownMonitoring and tostring(potion.inferredCount or 0) or "UNKNOWN",potion.evidence or "UNKNOWN"),color=C.gold}
    end
    for _, metric in ipairs(report.rows) do
        local measured=report.durationMs>0 and math.min(100,(metric.knownMs/report.durationMs)*100) or 0
        rows[#rows+1]={title=(report.subjects and report.subjects[metric.subject] or metric.subject) .. " - " .. (metric.label or metric.key),
            detail=string.format("Uptime %s | Measured %.1f%% | Unknown %.1fs | Gap %.1fs | Goal %s%%: %s",metric.uptime and (metric.uptime.."%") or "UNKNOWN",measured,(metric.unknownMs or 0)/1000,(metric.longestGapMs or 0)/1000,tostring(metric.targetUptime or 0),self.History.Assess(metric,report.durationMs)),
            color=self.History.Assess(metric,report.durationMs)=="BELOW_TARGET" and C.gold or C.white}
    end
    if #rows==0 then rows[1]={title="No analyzable observations",detail="No data is better than fabricated uptime. Verify effect IDs, peer sharing, and encounter visibility.",color=C.muted} end
    win.page=RenderRows(win,rows,win.page)
end
