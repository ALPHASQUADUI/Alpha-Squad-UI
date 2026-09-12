-- Ąlpha Şquad UI - ULT Tracker Settings
-- Normal runtime uses the shared Settings > Ąlpha Şquad shell.

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

local COLORS = ULT.COLORS
    or (AlphaSquadUI.Theme and AlphaSquadUI.Theme.colors)
    or {
        panel = {0.020, 0.030, 0.052, 0.98},
        white = {0.95, 0.97, 1.00, 1.00},
        muted = {0.53, 0.62, 0.72, 1.00},
        orange = {1.00, 0.58, 0.16, 1.00},
        cyan = {0.20, 0.82, 1.00, 1.00},
        green = {0.34, 0.82, 0.52, 1.00},
        red = {1.00, 0.30, 0.35, 1.00},
        gold = {0.97, 0.78, 0.30, 1.00},
    }

local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

function ULT:RefreshSettings()
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    if settings and settings.RefreshMain then
        settings.RefreshMain()
    end
end

function ULT:ToggleSettings()
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    if settings and settings.OpenPage then
        settings.OpenPage("ulttracker")
    end
    self:ApplyVisibility()
end

-- Build the ULT Tracker page inside the shared Settings > Ąlpha Şquad shell.
-- UI primitives are provided by the shell so the module keeps the same visual language
-- without moving module-specific behavior into the Overload source file.
function ULT:BuildIntegratedSettingsPage(page, ui)
    if not page or not ui then return end

    local CreateLabel = ui.CreateLabel
    local CreateCard = ui.CreateCard
    local AddToggleRow = ui.AddToggleRow
    local AddStepperRow = ui.AddStepperRow
    local CreateButton = ui.CreateButton
    local RegisterRefresher = ui.RegisterRefresher
    local C = ui.colors or COLORS

    local title = CreateLabel(page, "AlphaSquadULTIntegratedTitle", "ZoFontWinH2", "ULT TRACKER", C.white)
    title:SetDimensions(420, 32)
    title:SetAnchor(TOPLEFT, page, TOPLEFT, 8, 2)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local sub = CreateLabel(page, "AlphaSquadULTIntegratedSub", "ZoFontGameSmall",
        "MAIN / BACK Ultimate readiness • all classes • all morphs • dynamic slot detection", C.muted)
    sub:SetDimensions(650, 22)
    sub:SetAnchor(TOPLEFT, page, TOPLEFT, 9, 34)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local general = CreateCard(page, "AlphaSquadULTIntegratedGeneral", 8, 68, 322, 226, "GENERAL", C.orange)

    AddToggleRow(general, "AlphaSquadULTIntegratedEnabled", "Enable ULT Tracker", 42,
        function() return ULT.sv and ULT.sv.enabled == true end,
        function(v) if ULT.sv then ULT:SetEnabled(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedVisible", "Show tracker HUD", 78,
        function() return ULT.sv and ULT.sv.visible == true end,
        function(v) if ULT.sv then ULT:SetVisible(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedLocked", "Lock position", 114,
        function() return ULT.sv and ULT.sv.locked == true end,
        function(v) if ULT.sv then ULT:SetLocked(v) end end)

    AddToggleRow(general, "AlphaSquadULTIntegratedMenus", "Hide when ESO menus open", 150,
        function() return ULT.sv and ULT.sv.hideInMenus == true end,
        function(v)
            if ULT.sv then
                ULT.sv.hideInMenus = v == true
                ULT:ApplyVisibility()
            end
        end)

    CreateButton(general, "AlphaSquadULTIntegratedReset", "RESET POSITION", 14, 188, 140, 30, function()
        if ULT.sv then ULT:ResetPosition() end
    end)

    CreateButton(general, "AlphaSquadULTIntegratedMove", "UNLOCK & MOVE", 164, 188, 144, 30, function()
        if not ULT.sv then return end
        ULT:SetVisible(true)
        ULT:SetLocked(false)
        local mainSettings = AlphaSquadUI and AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
        if mainSettings then mainSettings:SetHidden(true) end
        ULT:ApplyVisibility()
    end)

    local tracking = CreateCard(page, "AlphaSquadULTIntegratedTracking", 344, 68, 322, 226, "TRACKING", C.cyan)

    local modeLabel = CreateLabel(tracking, "AlphaSquadULTIntegratedModeLabel", "ZoFontGame", "Bars to track", C.white)
    modeLabel:SetDimensions(290, 28)
    modeLabel:SetAnchor(TOPLEFT, tracking, TOPLEFT, 14, 42)
    modeLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local function SelectTrackMode(mode)
        if not ULT.sv then return end
        ULT:SetTrackMode(mode)
        local refreshMain = AlphaSquadUI
            and AlphaSquadUI.Settings
            and AlphaSquadUI.Settings.RefreshMain
        if refreshMain then refreshMain() end
    end

    local mainButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeMain", "MAIN", 14, 74, 88, 32, function()
        SelectTrackMode("main")
    end)
    local backButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeBack", "BACK", 116, 74, 88, 32, function()
        SelectTrackMode("back")
    end)
    local bothButton = CreateButton(tracking, "AlphaSquadULTIntegratedModeBoth", "BOTH", 218, 74, 88, 32, function()
        SelectTrackMode("both")
    end)

    RegisterRefresher(function()
        local selectedMode = ULT.sv and ULT.sv.trackMode or "both"
        for mode, button in pairs({ main = mainButton, back = backButton, both = bothButton }) do
            local selected = selectedMode == mode
            if button.bg then
                if selected then
                    button.bg:SetColor(0.13, 0.075, 0.025, 0.98)
                else
                    button.bg:SetColor(C.panel[1], C.panel[2], C.panel[3], C.panel[4])
                end
            end
            if button.label then
                local color = selected and C.orange or C.white
                button.label:SetColor(color[1], color[2], color[3], 1)
            end
        end
    end)

    AddToggleRow(tracking, "AlphaSquadULTIntegratedSound", "Sound when Ultimate is READY", 122,
        function() return ULT.sv and ULT.sv.readySound == true end,
        function(v) if ULT.sv then ULT.sv.readySound = v == true end end)

    AddToggleRow(tracking, "AlphaSquadULTIntegratedFlash", "Flash / pulse while READY", 158,
        function() return ULT.sv and ULT.sv.readyFlash == true end,
        function(v)
            if ULT.sv then
                ULT.sv.readyFlash = v == true
                ULT:Refresh("integrated settings flash")
            end
        end)

    local appearance = CreateCard(page, "AlphaSquadULTIntegratedAppearance", 8, 310, 322, 214, "APPEARANCE", C.cyan)

    AddStepperRow(appearance, "AlphaSquadULTIntegratedScale", "Tracker scale", 42,
        function() return ULT.sv and ULT.sv.scale or 100 end,
        function(v)
            if ULT.sv then
                ULT.sv.scale = v
                ULT:ApplyAppearance()
            end
        end,
        5, 70, 150, "%", C.cyan)

    AddStepperRow(appearance, "AlphaSquadULTIntegratedOpacity", "Background opacity", 82,
        function() return ULT.sv and ULT.sv.opacity or 92 end,
        function(v)
            if ULT.sv then
                ULT.sv.opacity = v
                ULT:ApplyAppearance()
            end
        end,
        5, 30, 100, "%", C.cyan)

    local note = CreateLabel(appearance, "AlphaSquadULTIntegratedAppearanceNote", "ZoFontGameSmall",
        "Background opacity never dims the Ultimate icons, names, readiness status or active-bar indicator.", C.muted)
    note:SetDimensions(288, 76)
    note:SetAnchor(TOPLEFT, appearance, TOPLEFT, 14, 130)
    note:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    note:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local runtime = CreateCard(page, "AlphaSquadULTIntegratedRuntime", 344, 310, 322, 214, "LIVE STATUS", C.green)

    local livePrimary = CreateLabel(runtime, "AlphaSquadULTIntegratedPrimary", "ZoFontGameSmall", "", C.white)
    livePrimary:SetDimensions(288, 52)
    livePrimary:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 42)
    livePrimary:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    livePrimary:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local liveBackup = CreateLabel(runtime, "AlphaSquadULTIntegratedBackup", "ZoFontGameSmall", "", C.white)
    liveBackup:SetDimensions(288, 52)
    liveBackup:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 94)
    liveBackup:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    liveBackup:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local current = CreateLabel(runtime, "AlphaSquadULTIntegratedCurrent", "ZoFontGameBold", "", C.gold)
    current:SetDimensions(288, 28)
    current:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 154)
    current:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    RegisterRefresher(function()
        local p = ULT.bars and ULT.bars.primary
        local b = ULT.bars and ULT.bars.backup
        local pName = p and p.name ~= "" and p.name or "No Ultimate"
        local bName = b and b.name ~= "" and b.name or "No Ultimate"
        livePrimary:SetText(string.format("MAIN  •  %s\n%s  •  Cost %s",
            pName, p and string.upper(p.state or "empty") or "EMPTY", p and tostring(p.cost or "?") or "?"))
        liveBackup:SetText(string.format("BACK  •  %s\n%s  •  Cost %s",
            bName, b and string.upper(b.state or "empty") or "EMPTY", b and tostring(b.cost or "?") or "?"))
        current:SetText(string.format("CURRENT ULTIMATE: %d", tonumber(ULT.currentUltimate) or 0))
    end)

    local groupCard = CreateCard(page, "AlphaSquadULTIntegratedGroup", 8, 540, 658, 78, "GROUP TRACKING • RAIDLEAD TOOL", C.gold)

    local groupStatus = CreateLabel(groupCard, "AlphaSquadULTIntegratedGroupStatus", "ZoFontGameSmall", "", C.muted)
    groupStatus:SetDimensions(410, 38)
    groupStatus:SetAnchor(TOPLEFT, groupCard, TOPLEFT, 14, 34)
    groupStatus:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    groupStatus:SetVerticalAlignment(TEXT_ALIGN_TOP)

    CreateButton(groupCard, "AlphaSquadULTIntegratedGroupConfig", "CONFIGURE GROUP", 466, 34, 176, 32, function()
        if ULT.Group and ULT.Group.OpenConfig then
            ULT.Group:OpenConfig()
        end
    end)

    RegisterRefresher(function()
        local group = ULT.Group
        if not group or not group.sv then
            groupStatus:SetText("Group tracker initializing...")
            SetColor(groupStatus, C.muted)
            return
        end

        local shared, total = group:GetSharingCount()
        if not group.libraryAvailable then
            groupStatus:SetText("OFFLINE • LibGroupCombatStats required for live group Ultimate values")
            SetColor(groupStatus, C.red)
        elseif not group.sv.enabled then
            groupStatus:SetText(string.format("DISABLED • %d/%d group members sharing ULT data", shared, total))
            SetColor(groupStatus, C.muted)
        else
            groupStatus:SetText(string.format("ENABLED • %d/%d sharing • Event-driven raidlead list", shared, total))
            SetColor(groupStatus, C.green)
        end
    end)
end


if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ulttracker", function(page, ui)
        ULT:BuildIntegratedSettingsPage(page, ui)
    end)
end
