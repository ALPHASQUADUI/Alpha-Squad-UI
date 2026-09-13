-- Ąlpha Şquad UI - Support Coverage settings page and raidlead matrix

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local C = (AlphaSquadUI.Theme and AlphaSquadUI.Theme.colors) or {
    bg={0.01,0.016,0.03,0.96}, panel={0.02,0.03,0.052,0.98},
    white={0.95,0.97,1,1}, muted={0.53,0.62,0.72,1},
    orange={1,0.58,0.16,1}, green={0.34,0.82,0.52,1},
    red={1,0.30,0.35,1}, gold={0.97,0.78,0.30,1}, cyan={0.20,0.82,1,1},
}

local PROFILE_ORDER = {"full","progression","damage","trash","boss","custom"}
local ROLE_ORDER = {"UNKNOWN","MT","OT","H1","H2","DD PARSE","DD SUPPORT"}

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

local function Button(parent, name, text, x, y, w, h, callback)
    local b = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    b:SetDimensions(w, h)
    b:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    b:SetMouseEnabled(true)
    b.bg = Solid(b, name .. "BG", C.panel)
    b.label = Label(b, name .. "Label", "ZoFontGame", text or "", C.white)
    b.label:SetAnchorFill(b)
    b.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    b:SetHandler("OnMouseEnter", function() b.bg:SetColor(0.06,0.09,0.13,1) end)
    b:SetHandler("OnMouseExit", function() b.bg:SetColor(C.panel[1],C.panel[2],C.panel[3],C.panel[4]) end)
    b:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and callback then callback() end
    end)
    return b
end

local function NextFrom(list, current)
    local index = 1
    for i, value in ipairs(list) do
        if value == current then index = i + 1 break end
    end
    if index > #list then index = 1 end
    return list[index]
end

function SC:RefreshSettings()
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    if settings and settings.RefreshMain then settings.RefreshMain() end
    if self.matrixWindow and not self.matrixWindow:IsHidden() then self:RefreshMatrix() end
end

function SC:BuildIntegratedSettingsPage(page, ui)
    if not page or not ui or not self.sv then return end

    local CreateLabel = ui.CreateLabel
    local CreateCard = ui.CreateCard
    local AddToggleRow = ui.AddToggleRow
    local AddStepperRow = ui.AddStepperRow
    local CreateButton = ui.CreateButton
    local RegisterRefresher = ui.RegisterRefresher

    local title = CreateLabel(page, "AlphaSquadSupportPageTitle", "ZoFontWinH2", "SUPPORT COVERAGE", C.white)
    title:SetDimensions(440, 34)
    title:SetAnchor(TOPLEFT, page, TOPLEFT, 8, 2)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = CreateLabel(page, "AlphaSquadSupportPageSub", "ZoFontGameSmall",
        "Raidlead planner • capability scanner • live coverage • U50 catalog", C.muted)
    sub:SetDimensions(650, 22)
    sub:SetAnchor(TOPLEFT, page, TOPLEFT, 9, 35)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local statusCard = CreateCard(page, "AlphaSquadSupportStatusCard", 8, 66, 658, 94, "RAID READINESS", C.orange)
    local status = CreateLabel(statusCard, "AlphaSquadSupportStatusText", "ZoFontGameBold", "", C.white)
    status:SetDimensions(402, 48)
    status:SetAnchor(TOPLEFT, statusCard, TOPLEFT, 14, 34)
    status:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local matrix = CreateButton(statusCard, "AlphaSquadSupportOpenMatrix", "OPEN COVERAGE MATRIX", 438, 36, 202, 34, function()
        SC:OpenMatrix()
    end)

    local profileCard = CreateCard(page, "AlphaSquadSupportProfileCard", 8, 170, 322, 188, "PROFILE & PLANNER", C.gold)
    local profileLabel = CreateLabel(profileCard, "AlphaSquadSupportProfileCurrent", "ZoFontGameBold", "", C.gold)
    profileLabel:SetDimensions(286, 30)
    profileLabel:SetAnchor(TOPLEFT, profileCard, TOPLEFT, 14, 36)
    profileLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    CreateButton(profileCard, "AlphaSquadSupportProfileNext", "NEXT PROFILE", 14, 72, 138, 30, function()
        SC:SetActiveProfile(NextFrom(PROFILE_ORDER, SC.sv.activeProfile))
    end)
    CreateButton(profileCard, "AlphaSquadSupportProfileSave", "SAVE CONTEXT", 158, 72, 140, 30, function()
        SC:SaveContextProfile()
        SC:RefreshSettings()
    end)
    CreateButton(profileCard, "AlphaSquadSupportProfileLoad", "LOAD CONTEXT", 14, 108, 138, 30, function()
        SC:LoadContextProfile()
        SC:RefreshSettings()
    end)
    CreateButton(profileCard, "AlphaSquadSupportRescan", "RESCAN BUILD", 158, 108, 140, 30, function()
        SC:MarkScanDirty("settings rescan")
    end)

    local context = CreateLabel(profileCard, "AlphaSquadSupportContext", "ZoFontGameSmall", "", C.muted)
    context:SetDimensions(282, 40)
    context:SetAnchor(TOPLEFT, profileCard, TOPLEFT, 14, 144)
    context:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    context:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local controlCard = CreateCard(page, "AlphaSquadSupportControlCard", 344, 170, 322, 260, "MODULE", C.cyan)
    AddToggleRow(controlCard, "AlphaSquadSupportEnabled", "Enable module", 40,
        function() return SC.sv.enabled end, function(v) SC:SetEnabled(v) end)
    AddToggleRow(controlCard, "AlphaSquadSupportVisible", "Show compact HUD", 76,
        function() return SC.sv.visible end, function(v) SC:SetVisible(v) end)
    AddToggleRow(controlCard, "AlphaSquadSupportProblems", "Problems only", 112,
        function() return SC.sv.problemsOnly end, function(v) SC.sv.problemsOnly = v; SC:RefreshHUD() end)
    AddToggleRow(controlCard, "AlphaSquadSupportAuto", "Auto assign owners", 148,
        function() return SC.sv.autoAssign end, function(v) SC.sv.autoAssign = v; SC:Refresh("autoassign") end)
    AddToggleRow(controlCard, "AlphaSquadSupportShare", "Send / receive ASUI data", 184,
        function() return SC.sv.shareData end,
        function(v) SC:SetShareData(v) end)
    AddToggleRow(controlCard, "AlphaSquadSupportUnknown", "Show unverified details", 220,
        function() return SC.sv.showUnknown end, function(v) SC.sv.showUnknown = v; SC:RefreshHUD() end)

    local auditCard = CreateCard(page, "AlphaSquadSupportAuditCard", 8, 368, 322, 250, "LOCAL BUILD AUDIT", C.green)
    local audit = CreateLabel(auditCard, "AlphaSquadSupportAuditText", "ZoFontGameSmall", "", C.white)
    audit:SetDimensions(286, 200)
    audit:SetAnchor(TOPLEFT, auditCard, TOPLEFT, 14, 38)
    audit:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    audit:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local appearanceCard = CreateCard(page, "AlphaSquadSupportAppearanceCard", 344, 440, 322, 178, "HUD APPEARANCE", C.orange)
    AddStepperRow(appearanceCard, "AlphaSquadSupportScale", "Scale", 40,
        function() return SC.sv.scale end,
        function(v) SC.sv.scale=v; SC:ApplyAppearance(); SC:ClampToScreen(true) end,
        5, 60, 180, "%", C.cyan)
    AddStepperRow(appearanceCard, "AlphaSquadSupportWidth", "Width", 76,
        function() return SC.sv.width end,
        function(v) SC.sv.width=v; SC:ApplyAppearance(); SC:RefreshHUD() end,
        10, 300, 680, "", C.cyan)
    AddStepperRow(appearanceCard, "AlphaSquadSupportRow", "Row height", 112,
        function() return SC.sv.rowHeight end,
        function(v) SC.sv.rowHeight=v; SC:ApplyAppearance(); SC:RefreshHUD() end,
        2, 24, 48, "", C.cyan)
    AddStepperRow(appearanceCard, "AlphaSquadSupportOpacity", "Background", 148,
        function() return SC.sv.opacity end,
        function(v) SC.sv.opacity=v; SC:ApplyAppearance() end,
        5, 30, 100, "%", C.cyan)

    RegisterRefresher(function()
        local coverage = SC.coverage or {}
        local shareMode = SC:GetSharingStatus()
        status:SetText(string.format("%d/%d COVERED  •  %d MISSING  •  %d LIMITED  •  %s",
            tonumber(coverage.coveredCount) or 0,
            tonumber(coverage.requiredCount) or 0,
            tonumber(coverage.missingCount) or 0,
            tonumber(coverage.limitedPlayers) or 0,
            tostring(shareMode)))
        SetColor(status, coverage.ready and C.green or C.gold)

        local profile = Catalog:GetProfile(SC.sv.activeProfile)
        profileLabel:SetText((profile and profile.label or SC.sv.activeProfile) .. "  •  " .. SC.catalogPatch)
        context:SetText("Context: " .. tostring(SC:GetContextKey()))

        local s = SC.localSnapshot or {}
        local eq = s.equipment or {}
        local glyphs = eq.glyphs or {}
        local sets = eq.setList or {}
        local setNames = {}
        for i = 1, math.min(3, #sets) do setNames[#setNames + 1] = sets[i].name end
        local food = s.food or {}
        local potion = s.potion or {}
        local foodLabel = "UNKNOWN"
        if food.verified then foodLabel = food.active and (food.name ~= "" and food.name or "ACTIVE") or "MISSING" end
        local potionLabel = "UNKNOWN"
        if potion.known then potionLabel = potion.name ~= "" and potion.name or "CONFIGURED"
        elseif potion.selectionKnown then potionLabel = "NO POTION SELECTED" end
        audit:SetText(string.format(
            "ROLE  %s\nGLYPHS  missing %d • tri %d • mag %d • stam %d • health %d\nFOOD  %s\nPOTION  %s\nSETS  %s",
            tostring(s.role or "UNKNOWN"),
            tonumber(glyphs.armorMissing) or 0,
            tonumber(glyphs.prismatic) or 0,
            tonumber(glyphs.magicka) or 0,
            tonumber(glyphs.stamina) or 0,
            tonumber(glyphs.health) or 0,
            foodLabel,
            potionLabel,
            #setNames > 0 and table.concat(setNames, ", ") or "none detected"
        ))
    end)
end

local function CycleRole(player)
    local current = SC.sv.roleOverrides[player.key] or player.role or "UNKNOWN"
    local nextRole = NextFrom(ROLE_ORDER, current)
    SC.sv.roleOverrides[player.key] = nextRole
    SC:SanitizePlanningSettings()
    SC:Refresh("role override")
    if SC.SchedulePlanBroadcast then SC:SchedulePlanBroadcast() end
end

local function CycleOwner(effectKey)
    local coverage = SC.coverage or {}
    local rowData = nil
    for _, row in ipairs(coverage.entries or {}) do
        if row.key == effectKey then rowData = row break end
    end
    if not rowData then return end

    local choices = {}
    for _, owner in ipairs(rowData.owners or {}) do choices[#choices + 1] = owner.key end

    if #choices == 0 then
        SC.sv.assignmentLocks[effectKey] = nil
        SC:Refresh("unlock no owner")
        return
    end

    local current = SC.sv.assignmentLocks[effectKey]
    if not current then
        SC.sv.assignmentLocks[effectKey] = choices[1]
    else
        local found = false
        for i, key in ipairs(choices) do
            if key == current then
                SC.sv.assignmentLocks[effectKey] = choices[i + 1]
                if i == #choices then SC.sv.assignmentLocks[effectKey] = nil end
                found = true
                break
            end
        end
        if not found then SC.sv.assignmentLocks[effectKey] = choices[1] end
    end
    SC:Refresh("owner lock")
    if SC.SchedulePlanBroadcast then SC:SchedulePlanBroadcast() end
end

local function ToggleBackups(effectKey)
    local coverage = SC.coverage or {}
    local rowData
    for _, row in ipairs(coverage.entries or {}) do
        if row.key == effectKey then rowData = row break end
    end
    if not rowData then return end

    SC.sv.duplicateBackups[effectKey] = SC.sv.duplicateBackups[effectKey] or {}
    local backups = SC.sv.duplicateBackups[effectKey]
    local assignedKey = rowData.assigned and rowData.assigned.key

    local shouldEnable = false
    for _, owner in ipairs(rowData.owners or {}) do
        if owner.key ~= assignedKey and not backups[owner.key] then
            shouldEnable = true
            break
        end
    end

    for _, owner in ipairs(rowData.owners or {}) do
        if owner.key ~= assignedKey then backups[owner.key] = shouldEnable or nil end
    end

    SC:SanitizePlanningSettings()
    SC:Refresh("backup duplicate")
end

function SC:RefreshMatrix()
    local win = self.matrixWindow
    if not win or win:IsHidden() then return end
    local coverage = self.coverage or {}

    win.summary:SetText(string.format("%s  •  %d/%d COVERED  •  %d LIMITED  •  PEN %d/%d  •  CRIT +%d%%",
        tostring(coverage.profileLabel or ""),
        tonumber(coverage.coveredCount) or 0,
        tonumber(coverage.requiredCount) or 0,
        tonumber(coverage.limitedPlayers) or 0,
        coverage.penetration and coverage.penetration.covered or 0,
        coverage.penetration and coverage.penetration.target or 18200,
        coverage.critical and coverage.critical.groupBonus or 0))

    for i, row in ipairs(win.requirementRows) do
        local data = coverage.entries and coverage.entries[i]
        row:SetHidden(data == nil)
        if data then
            row.effectKey = data.key
            row.name:SetText(data.effect.label)
            local statusColor = data.status == "covered" and C.green or (data.unverified and C.gold or C.red)
            row.status:SetText(data.status == "missing" and (data.unverified and "NO SOURCE ?" or "NO SOURCE") or string.upper(data.status))
            SetColor(row.status, statusColor)

            local ownerText = data.assigned and data.assigned.displayName or "AUTO / NONE"
            if data.locked then ownerText = "[LOCKED] " .. ownerText end
            row.owner.label:SetText(ownerText)

            if #data.duplicatePlayers > 0 then
                row.duplicate:SetText("DUP: " .. table.concat(data.duplicatePlayers, ", "))
                SetColor(row.duplicate, C.gold)
            else
                row.duplicate:SetText("")
            end

            local backupCount = 0
            local backups = SC.sv.duplicateBackups[data.key] or {}
            for _, owner in ipairs(data.owners or {}) do
                if backups[owner.key] then backupCount = backupCount + 1 end
            end
            row.backup.label:SetText(backupCount > 0 and ("BACKUP " .. backupCount) or "BACKUP")
        end
    end

    for i, row in ipairs(win.playerRows) do
        local player = SC.roster and SC.roster[i]
        row:SetHidden(player == nil)
        if player then
            row.player = player
            row.user:SetText(player.displayName or "?")
            row.role.label:SetText(SC.sv.roleOverrides[player.key] or player.role or "UNKNOWN")
            local buildKnown = player.dataQuality == "ASUI" or player.buildVerified == true
            row.quality:SetText(buildKnown and "ASUI" or tostring(player.dataQuality or "LIMITED"))
            SetColor(row.quality, buildKnown and C.green or C.gold)

            local food = player.food
            local foodText = food and food.verified and (food.active and "FOOD ✓" or "NO FOOD") or "FOOD ?"
            row.food:SetText(foodText)
            SetColor(row.food, food and food.verified and (food.active and C.green or C.red) or C.gold)

            local glyphs = player.equipment and player.equipment.glyphs
            local missing = glyphs and tonumber(glyphs.armorMissing) or 0
            row.glyph:SetText(glyphs and glyphs.verified and (missing > 0 and ("GLYPH -" .. missing) or "GLYPH ✓") or "GLYPH ?")
            SetColor(row.glyph, (not glyphs or glyphs.verified ~= true) and C.gold or (missing > 0 and C.red or C.green))
        end
    end
end

function SC:OpenMatrix()
    if self.inCombat then return false end
    if not self.matrixWindow then self:CreateMatrixWindow() end
    if self.inspectorWindow and not self.inspectorWindow:IsHidden() then self:CloseInspector() end
    if self.reportWindow and not self.reportWindow:IsHidden() then self:ClosePullReport() end
    self.matrixWindow:SetHidden(false)
    self.settingsPageVisible = true
    self:ApplyVisibility()
    self:RefreshMatrix()
    return true
end

function SC:CloseMatrix()
    if self.matrixWindow then self.matrixWindow:SetHidden(true) end
    self.settingsPageVisible = false
    self:ApplyVisibility()
end

function SC:CreateMatrixWindow()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSupportCoverageMatrix")
    self.matrixWindow = win
    win:SetDimensions(1040, 740)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(120)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetHidden(true)
    win.bg = Solid(win, "AlphaSquadSupportMatrixBG", {0.009,0.014,0.025,0.995})

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadSupportMatrixTop", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(3)
    SetColor(top, C.orange)

    local title = Label(win, "AlphaSquadSupportMatrixTitle", "ZoFontWinH2", "ĄLPHA ŞQUAD • SUPPORT COVERAGE MATRIX", C.white)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 10)
    title:SetDimensions(620, 34)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.summary = Label(win, "AlphaSquadSupportMatrixSummary", "ZoFontGameSmall", "", C.muted)
    win.summary:SetAnchor(TOPLEFT, win, TOPLEFT, 19, 44)
    win.summary:SetDimensions(840, 24)
    win.summary:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win, "AlphaSquadSupportMatrixClose", "X", 990, 12, 34, 30, function() SC:CloseMatrix() end)

    local profileX = 18
    for _, key in ipairs(PROFILE_ORDER) do
        local profile = Catalog:GetProfile(key)
        local label = profile and profile.label or key
        local short = label
        if #short > 14 then short = string.sub(short, 1, 14) end
        Button(win, "AlphaSquadSupportProfile_" .. key, short, profileX, 76, 150, 28, function()
            SC:SetActiveProfile(key)
            SC:RefreshMatrix()
        end)
        profileX = profileX + 156
    end

    local reqHeader = Label(win, "AlphaSquadSupportReqHeader", "ZoFontGameBold",
        "REQUIREMENT                     STATUS        OWNER / LOCK                         DUPLICATES", C.orange)
    reqHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 118)
    reqHeader:SetDimensions(650, 22)
    reqHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.requirementRows = {}
    for i = 1, 20 do
        local row = WINDOW_MANAGER:CreateControl("AlphaSquadSupportReqRow" .. i, win, CT_CONTROL)
        row:SetDimensions(650, 27)
        row:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 143 + (i - 1) * 28)
        row.bg = Solid(row, "AlphaSquadSupportReqRowBG" .. i, i % 2 == 0 and {0.018,0.027,0.046,0.95} or {0.014,0.022,0.038,0.95})

        row.name = Label(row, "AlphaSquadSupportReqName" .. i, "ZoFontGameSmall", "", C.white)
        row.name:SetAnchor(TOPLEFT, row, TOPLEFT, 8, 0)
        row.name:SetDimensions(205, 27)
        row.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.status = Label(row, "AlphaSquadSupportReqStatus" .. i, "ZoFontGameBold", "", C.white)
        row.status:SetAnchor(TOPLEFT, row, TOPLEFT, 216, 0)
        row.status:SetDimensions(74, 27)
        row.status:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.owner = Button(row, "AlphaSquadSupportReqOwner" .. i, "", 292, 1, 175, 25, function()
            if row.effectKey then CycleOwner(row.effectKey) end
        end)

        row.duplicate = Label(row, "AlphaSquadSupportReqDup" .. i, "ZoFontGameSmall", "", C.muted)
        row.duplicate:SetAnchor(TOPLEFT, row, TOPLEFT, 474, 0)
        row.duplicate:SetDimensions(112, 27)
        row.duplicate:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.backup = Button(row, "AlphaSquadSupportReqBackup" .. i, "BACKUP", 588, 1, 58, 25, function()
            if row.effectKey then ToggleBackups(row.effectKey) end
        end)

        row:SetHidden(true)
        win.requirementRows[i] = row
    end

    local playersHeader = Label(win, "AlphaSquadSupportPlayersHeader", "ZoFontGameBold",
        "GROUP • CLICK ROLE TO ASSIGN MANUALLY", C.orange)
    playersHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 690, 118)
    playersHeader:SetDimensions(325, 22)
    playersHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.playerRows = {}
    for i = 1, 12 do
        local row = WINDOW_MANAGER:CreateControl("AlphaSquadSupportPlayerRow" .. i, win, CT_CONTROL)
        row:SetDimensions(326, 42)
        row:SetAnchor(TOPLEFT, win, TOPLEFT, 690, 143 + (i - 1) * 45)
        row.bg = Solid(row, "AlphaSquadSupportPlayerRowBG" .. i, {0.018,0.027,0.046,0.96})

        row.user = Label(row, "AlphaSquadSupportPlayerUser" .. i, "ZoFontGameBold", "", C.white)
        row.user:SetAnchor(TOPLEFT, row, TOPLEFT, 8, 2)
        row.user:SetDimensions(145, 20)
        row.user:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.quality = Label(row, "AlphaSquadSupportPlayerQuality" .. i, "ZoFontGameSmall", "", C.green)
        row.quality:SetAnchor(TOPLEFT, row, TOPLEFT, 154, 2)
        row.quality:SetDimensions(62, 20)
        row.quality:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.role = Button(row, "AlphaSquadSupportPlayerRole" .. i, "", 220, 3, 100, 24, function()
            if row.player then CycleRole(row.player) end
        end)

        row.food = Label(row, "AlphaSquadSupportPlayerFood" .. i, "ZoFontGameSmall", "", C.muted)
        row.food:SetAnchor(TOPLEFT, row, TOPLEFT, 8, 22)
        row.food:SetDimensions(94, 18)
        row.food:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row.glyph = Label(row, "AlphaSquadSupportPlayerGlyph" .. i, "ZoFontGameSmall", "", C.muted)
        row.glyph:SetAnchor(TOPLEFT, row, TOPLEFT, 108, 22)
        row.glyph:SetDimensions(100, 18)
        row.glyph:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        row:SetHidden(true)
        win.playerRows[i] = row
    end

    local footer = Label(win, "AlphaSquadSupportMatrixFooter", "ZoFontGameSmall",
        "Owner click = lock/cycle • BACKUP = mark extra owners intentional • NO ASUI = LIMITED / unverified • /assupport custom <effect_key> <abilityId>",
        C.muted)
    footer:SetAnchor(BOTTOMLEFT, win, BOTTOMLEFT, 18, -12)
    footer:SetDimensions(980, 22)
    footer:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
end

if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("supportcoverage", function(page, ui)
        SC:BuildIntegratedSettingsPage(page, ui)
    end)
end
