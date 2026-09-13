-- Ąlpha Şquad UI - Support Coverage responsive raidlead HUD

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local Catalog = SC.Catalog

local C = (AlphaSquadUI.Theme and AlphaSquadUI.Theme.colors) or {
    bg={0.01,0.016,0.03,0.96}, panel={0.02,0.03,0.052,0.98},
    white={0.95,0.97,1,1}, muted={0.53,0.62,0.72,1},
    orange={1,0.58,0.16,1}, green={0.34,0.82,0.52,1},
    red={1,0.30,0.35,1}, gold={0.97,0.78,0.30,1}, cyan={0.20,0.82,1,1},
}

local MAX_ROWS = 10

local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function Solid(parent, name, color)
    local t = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    t:SetAnchorFill(parent)
    SetColor(t, color)
    return t
end

local function Label(parent, name, font, text, color)
    local l = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    l:SetFont(font)
    l:SetText(text or "")
    SetColor(l, color or C.white)
    l:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return l
end

function SC:GetEffectiveScale()
    local configured = self.Clamp(self.sv and self.sv.scale or 100, 60, 180) / 100
    local rootW = GuiRoot and GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot and GuiRoot:GetHeight() or 1080
    local width = self.Clamp(self.sv and self.sv.width or 410, 300, 680)
    local estimatedH = 72 + MAX_ROWS * self.Clamp(self.sv and self.sv.rowHeight or 30, 24, 48)
    local fit = math.min(1, (rootW - 32) / width, (rootH - 48) / estimatedH)
    return configured * math.max(0.55, fit)
end

function SC:ApplyPosition()
    if not self.window or not self.sv then return end
    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.sv.x, self.sv.y)
end

function SC:SavePosition()
    if not self.window or not self.sv then return end
    local left, top = self.window:GetLeft(), self.window:GetTop()
    if left and top then
        self.sv.x = math.floor(left + 0.5)
        self.sv.y = math.floor(top + 0.5)
        self.sv.positionSaved = true
    end
end

function SC:ResetPosition()
    local x, y = self:GetDefaultPosition()
    self.sv.x, self.sv.y = x, y
    self.sv.positionSaved = true
    self:ApplyPosition()
    self:ClampToScreen(true)
end

function SC:ClampToScreen(save)
    if not self.window or not GuiRoot then return end
    local rootW, rootH = GuiRoot:GetWidth() or 1920, GuiRoot:GetHeight() or 1080
    local scale = self.window:GetScale() or 1
    local w = (self.window:GetWidth() or 410) * scale
    local h = (self.window:GetHeight() or 100) * scale
    local left, top = self.window:GetLeft() or 0, self.window:GetTop() or 0
    left = self.Clamp(left, 0, math.max(0, rootW - w))
    top = self.Clamp(top, 0, math.max(0, rootH - h))
    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left / scale, top / scale)
    if save then self:SavePosition() end
end

function SC:UpdateLockState()
    if not self.window or not self.sv then return end
    local movable = not self.sv.locked
    self.window:SetMovable(movable)
    self.window:SetMouseEnabled(true)
    if self.window.dragSurface then self.window.dragSurface:SetMouseEnabled(movable) end
    if self.window.lockHint then self.window.lockHint:SetHidden(not movable) end
end

function SC:ApplyAppearance()
    if not self.window or not self.sv then return end
    local width = self.Clamp(self.sv.width or 410, 300, 680)
    local rowHeight = self.Clamp(self.sv.rowHeight or 30, 24, 48)
    self.window:SetWidth(width)
    self.window:SetScale(self:GetEffectiveScale())
    if self.window.bg then self.window.bg:SetAlpha(self.Clamp(self.sv.opacity or 94, 30, 100) / 100) end

    for _, row in ipairs(self.window.rows or {}) do
        row:SetDimensions(width - 16, rowHeight)
        row.label:SetDimensions(width - 124, rowHeight)
        row.value:SetDimensions(104, rowHeight)
    end
    self:UpdateLockState()
end

function SC:ApplyVisibility()
    if not self.window or not self.sv then return end
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    local sharedSettingsVisible = settings and settings.mainWindow and not settings.mainWindow:IsHidden() or false
    local hidden = not self.sv.enabled
        or not self.sv.visible
        or (self.sv.hideInMenus and self.uiObscured)
        or sharedSettingsVisible
        or (self.settingsPageVisible == true)
    self.window:SetHidden(hidden)
    if self.SetSafetyUpdateActive then self:SetSafetyUpdateActive(not hidden) end
    if hidden and self.banner then self.banner:SetHidden(true) end
end

local function RowColor(severity)
    if severity == "error" then return C.red end
    if severity == "warning" then return C.gold end
    if severity == "unknown" then return C.muted end
    return C.white
end

function SC:GetHUDIssues()
    local result = {}
    local coverage = self.coverage or {}

    if self.inCombat and coverage.entries then
        for _, row in ipairs(coverage.entries) do
            if row.liveKnown and row.live == false and row.effect.priority == "core" then
                result[#result + 1] = {
                    severity = "error",
                    text = row.effect.label,
                    value = "DOWN",
                }
            elseif row.liveKnown and row.effect.group and row.liveTotal and row.liveTotal > 0
                and row.liveCount and row.liveCount < row.liveTotal then
                result[#result + 1] = {
                    severity = "warning",
                    text = row.effect.label,
                    value = string.format("%d/%d%s", row.liveCount, row.liveTotal,
                        (row.liveUnknown or 0) > 0 and (" +" .. tostring(row.liveUnknown) .. "?") or ""),
                }
            end
        end
    end

    if #result == 0 and not self.inCombat then
        for _, issue in ipairs(coverage.issues or {}) do
            result[#result + 1] = {
                severity = issue.severity,
                text = issue.text,
                value = issue.severity == "unknown" and "LIMITED" or "",
            }
            if #result >= MAX_ROWS then break end
        end
    end

    return result
end

function SC:RefreshHUD()
    if not self.window or not self.sv then return end
    self:ApplyVisibility()
    if self.window:IsHidden() then return end

    local coverage = self.coverage or {}
    local issues = self:GetHUDIssues()
    local width = self.Clamp(self.sv.width or 410, 300, 680)
    local rowHeight = self.Clamp(self.sv.rowHeight or 30, 24, 48)
    local visibleRows = math.min(MAX_ROWS, #issues)

    local compact = self.sv.problemsOnly and visibleRows == 0
    local height = compact and 66 or (72 + visibleRows * (rowHeight + 1))
    self.window:SetDimensions(width, height)

    local covered = tonumber(coverage.coveredCount) or 0
    local required = tonumber(coverage.requiredCount) or 0
    local limited = tonumber(coverage.limitedPlayers) or 0

    if self.inCombat then
        self.window.title:SetText("SUPPORT COVERAGE")
        if visibleRows == 0 then
            self.window.status:SetText(string.format("%d/%d • STABLE", covered, required))
            SetColor(self.window.status, C.green)
        else
            self.window.status:SetText(string.format("%d ISSUE%s", visibleRows, visibleRows == 1 and "" or "S"))
            SetColor(self.window.status, C.red)
        end
    else
        self.window.title:SetText("SUPPORT COVERAGE • " .. tostring(coverage.profileLabel or "PROFILE"))
        self.window.status:SetText(string.format("%d/%d%s", covered, required, limited > 0 and (" • " .. limited .. " LIMITED") or ""))
        SetColor(self.window.status, coverage.ready and C.green or (limited > 0 and C.gold or C.red))
    end

    local pen = coverage.penetration or {}
    local crit = coverage.critical or {}
    self.window.metrics:SetText(string.format("PEN %s/%s   •   GROUP CRIT +%s%%",
        tostring(pen.covered or 0), tostring(pen.target or 18200), tostring(crit.groupBonus or 0)))

    for i, row in ipairs(self.window.rows) do
        local issue = issues[i]
        row:SetHidden(issue == nil or i > visibleRows)
        if issue and i <= visibleRows then
            local color = RowColor(issue.severity)
            row.accent:SetColor(color[1], color[2], color[3], 0.95)
            row.label:SetText(issue.text or "")
            row.value:SetText(issue.value or "")
            SetColor(row.label, color)
            SetColor(row.value, color)
        end
    end

    self:ApplyAppearance()
    self:ClampToScreen(false)
end

function SC:ShowReadyBanner(ready, covered, required, limited)
    if not self.banner or self.inCombat then return end
    local signature = string.format("%s:%s:%d:%d:%d", tostring(self.sv.activeProfile), tostring(ready), covered or 0, required or 0, limited or 0)
    if self.lastBannerSignature == signature then return end
    self.lastBannerSignature = signature

    self.banner:SetHidden(false)
    if ready then
        self.banner.label:SetText(string.format("COVERAGE READY  %d/%d", covered or 0, required or 0))
        SetColor(self.banner.label, C.green)
        self.banner.accent:SetColor(C.green[1], C.green[2], C.green[3], 1)
        if self.sv.optionalSounds and PlaySound and SOUNDS then
            local sound=SOUNDS.POSITIVE_CLICK or SOUNDS.GENERAL_ALERT_NOTIFICATION
            if sound then PlaySound(sound) end
        end
    else
        self.banner.label:SetText(string.format("COVERAGE CHECK  %d/%d%s",
            covered or 0, required or 0, (limited or 0) > 0 and "  •  LIMITED DATA" or ""))
        SetColor(self.banner.label, (limited or 0) > 0 and C.gold or C.red)
        local cc = (limited or 0) > 0 and C.gold or C.red
        self.banner.accent:SetColor(cc[1], cc[2], cc[3], 1)
    end

    local stamp = self.NowMs()
    self.bannerStamp = stamp
    zo_callLater(function()
        if SC and SC.banner and SC.bannerStamp == stamp and not SC.inCombat then
            SC.banner:SetHidden(true)
        end
    end, 2800)
end

function SC:HideReadyBanner()
    if self.banner then self.banner:SetHidden(true) end
end

function SC:ShowPersonalAssignmentBanner()
    if not self.assignmentBanner or self.inCombat then return end
    local assignments = self.GetMyRemoteAssignments and self:GetMyRemoteAssignments() or {}
    local role = self.remotePlan and self.remotePlan.myRole or nil
    if #assignments == 0 and (not role or role == "UNKNOWN") then
        self.assignmentBanner:SetHidden(true)
        return
    end

    local parts = {}
    if role and role ~= "UNKNOWN" then parts[#parts + 1] = role end
    for i = 1, math.min(3, #assignments) do parts[#parts + 1] = assignments[i] end
    if #assignments > 3 then parts[#parts + 1] = "+" .. tostring(#assignments - 3) end

    self.assignmentBanner.label:SetText("YOUR ASSIGNMENT  •  " .. table.concat(parts, "  •  "))
    SetColor(self.assignmentBanner.label, C.orange)
    self.assignmentBanner:SetHidden(false)

    local stamp = self.NowMs()
    self.assignmentBannerStamp = stamp
    zo_callLater(function()
        if SC and SC.assignmentBanner and SC.assignmentBannerStamp == stamp and not SC.inCombat then
            SC.assignmentBanner:SetHidden(true)
        end
    end, 5000)
end

function SC:ShowPullSummaryBanner(pull)
    if not self.assignmentBanner or not pull or self.inCombat then return end

    local worstKey, worstUptime, worstGap = nil, 101, 0
    for _, data in ipairs(pull.rows or {}) do
        if Catalog and Catalog.effects[data.key] and data.uptime and data.uptime < worstUptime then
            worstKey, worstUptime, worstGap = data.key, data.uptime, data.longestGapMs or 0
        end
    end

    if not worstKey or not Catalog or not Catalog.effects[worstKey] then return end
    local effect = Catalog.effects[worstKey]
    self.assignmentBanner.label:SetText(string.format(
        "PULL SUPPORT  •  LOWEST %s %.1f%%  •  GAP %.1fs",
        effect.label, worstUptime, worstGap / 1000))
    SetColor(self.assignmentBanner.label, C.gold)
    self.assignmentBanner:SetHidden(false)

    local stamp = self.NowMs()
    self.assignmentBannerStamp = stamp
    zo_callLater(function()
        if SC and SC.assignmentBanner and SC.assignmentBannerStamp == stamp and not SC.inCombat then
            SC.assignmentBanner:SetHidden(true)
        end
    end, 6000)
end

function SC:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSupportCoverageHUD")
    self.window = win
    win:SetDimensions(410, 100)
    win:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.sv.x, self.sv.y)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(60)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetClampedToScreen(true)

    win.bg = Solid(win, "AlphaSquadSupportCoverageBG", C.bg)

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageTop", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(2)
    SetColor(top, C.orange)

    win.title = Label(win, "AlphaSquadSupportCoverageTitle", "ZoFontGameBold", "SUPPORT COVERAGE", C.white)
    win.title:SetAnchor(TOPLEFT, win, TOPLEFT, 10, 7)
    win.title:SetDimensions(270, 22)
    win.title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.status = Label(win, "AlphaSquadSupportCoverageStatus", "ZoFontGameBold", "", C.green)
    win.status:SetAnchor(TOPRIGHT, win, TOPRIGHT, -10, 7)
    win.status:SetDimensions(150, 22)
    win.status:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.metrics = Label(win, "AlphaSquadSupportCoverageMetrics", "ZoFontGameSmall", "", C.muted)
    win.metrics:SetAnchor(TOPLEFT, win, TOPLEFT, 10, 31)
    win.metrics:SetDimensions(390, 20)
    win.metrics:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.lockHint = Label(win, "AlphaSquadSupportCoverageMove", "ZoFontGameSmall", "DRAG", C.muted)
    win.lockHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -10, 31)
    win.lockHint:SetDimensions(50, 20)
    win.lockHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    local drag = WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageDrag", win, CT_CONTROL)
    drag:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    drag:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    drag:SetHeight(54)
    drag:SetMouseEnabled(true)
    drag:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and SC.sv and not SC.sv.locked then win:StartMoving() end
    end)
    drag:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and SC.sv and not SC.sv.locked then
            win:StopMovingOrResizing()
            SC:SavePosition()
        end
    end)
    win.dragSurface = drag

    win.rows = {}
    for i = 1, MAX_ROWS do
        local row = WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageRow" .. i, win, CT_CONTROL)
        row:SetAnchor(TOPLEFT, win, TOPLEFT, 8, 60 + (i - 1) * 31)
        row.bg = Solid(row, "AlphaSquadSupportCoverageRowBG" .. i, C.panel)

        row.accent = WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageRowAccent" .. i, row, CT_TEXTURE)
        row.accent:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
        row.accent:SetDimensions(3, 30)
        SetColor(row.accent, C.orange)

        row.label = Label(row, "AlphaSquadSupportCoverageRowLabel" .. i, "ZoFontGame", "", C.white)
        row.label:SetAnchor(TOPLEFT, row, TOPLEFT, 10, 0)
        row.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.value = Label(row, "AlphaSquadSupportCoverageRowValue" .. i, "ZoFontGameBold", "", C.white)
        row.value:SetAnchor(TOPRIGHT, row, TOPRIGHT, -8, 0)
        row.value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

        row:SetHidden(true)
        win.rows[i] = row
    end

    local banner = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSupportCoverageBanner")
    self.banner = banner
    banner:SetDimensions(360, 42)
    banner:SetAnchor(TOP, GuiRoot, TOP, 0, 120)
    banner:SetDrawTier(DT_HIGH)
    banner:SetDrawLayer(DL_OVERLAY)
    banner:SetDrawLevel(90)
    banner:SetHidden(true)
    banner.bg = Solid(banner, "AlphaSquadSupportCoverageBannerBG", C.bg)
    banner.accent = WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageBannerAccent", banner, CT_TEXTURE)
    banner.accent:SetAnchor(TOPLEFT, banner, TOPLEFT, 0, 0)
    banner.accent:SetDimensions(4, 42)
    SetColor(banner.accent, C.green)
    banner.label = Label(banner, "AlphaSquadSupportCoverageBannerLabel", "ZoFontGameBold", "", C.green)
    banner.label:SetAnchorFill(banner)
    banner.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local assignment = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSupportAssignmentBanner")
    self.assignmentBanner = assignment
    assignment:SetDimensions(620, 42)
    assignment:SetAnchor(TOP, GuiRoot, TOP, 0, 168)
    assignment:SetDrawTier(DT_HIGH)
    assignment:SetDrawLayer(DL_OVERLAY)
    assignment:SetDrawLevel(91)
    assignment:SetHidden(true)
    assignment.bg = Solid(assignment, "AlphaSquadSupportAssignmentBG", C.bg)
    assignment.label = Label(assignment, "AlphaSquadSupportAssignmentLabel", "ZoFontGameBold", "", C.orange)
    assignment.label:SetAnchorFill(assignment)
    assignment.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    self:ApplyAppearance()
    self:ApplyVisibility()
    self:RefreshHUD()
end
