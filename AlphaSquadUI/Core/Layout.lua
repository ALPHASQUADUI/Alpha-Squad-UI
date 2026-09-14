-- One short-lived placement mode for all enabled HUDs. No update loop is needed.
AlphaSquadUI = AlphaSquadUI or {}
local ASUI = AlphaSquadUI
local Layout = { active = false, participants = {} }
ASUI.Layout = Layout

local function Modules()
    local modules = ASUI.Modules or {}
    local ult = modules.ULTTracker
    return { modules.Overload, ult, ult and ult.Group, modules.SupportCoverage }
end

local function Enabled(module)
    if not module or not module.sv or module.loading then return false end
    local modules = ASUI.Modules or {}
    if module == modules.Overload then return module.sv.addonEnabled == true end
    if modules.ULTTracker and module == modules.ULTTracker.Group then
        return modules.ULTTracker.sv and modules.ULTTracker.sv.enabled == true
            and not modules.ULTTracker.loading and module.sv.enabled == true
    end
    return module.sv.enabled == true
end

function Layout.ShouldHidePersonalULT()
    local overload = ASUI.Modules and ASUI.Modules.Overload
    if not Enabled(overload) or not overload.window then return false end
    if not Layout.active and overload.sv.visible == false then return false end
    if overload.IsPvPSuppressed and overload:IsPvPSuppressed() then return false end
    -- This is cached by the event-driven Overload scanner. Never scan skills on hover/render.
    return overload.hasSlottedOverload == true
end

function Layout.IsMoving(module)
    if not Layout.active or not Layout.participants[module] or not Enabled(module) then return false end
    if module == (ASUI.Modules and ASUI.Modules.ULTTracker) and Layout.ShouldHidePersonalULT() then return false end
    return true
end

local function RefreshModule(module)
    if not module or not module.sv then return end
    if module.UpdateLockState then module:UpdateLockState() end
    if module.ApplyVisualSettings then module:ApplyVisualSettings()
    elseif module.RefreshHUD then module:RefreshHUD()
    elseif module.ApplyVisibility then module:ApplyVisibility() end
end

function Layout.Refresh()
    for _, module in pairs(Modules()) do RefreshModule(module) end
end

function Layout.Finish(skipRefresh)
    if not Layout.active then return end
    Layout.active = false
    local previous = Layout.participants
    Layout.participants = {}
    for module in pairs(previous) do
        if module.window and module.window.StopMovingOrResizing then module.window:StopMovingOrResizing() end
        if module.SavePosition then module:SavePosition() end
        if module.sv then module.sv.locked = true end
    end
    -- OnHide may call Finish again; active is cleared first for a harmless re-entry.
    if Layout.toolbar then
        if SCENE_MANAGER and SCENE_MANAGER.HideTopLevel then SCENE_MANAGER:HideTopLevel(Layout.toolbar)
        else Layout.toolbar:SetHidden(true) end
    end
    if skipRefresh ~= true then Layout.Refresh() end
end

function Layout.CreateToolbar()
    if Layout.toolbar then return Layout.toolbar end
    local window = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadUILayoutToolbar")
    window:SetDimensions(510, 64)
    window:SetAnchor(TOP, GuiRoot, TOP, 0, 30)
    window:SetClampedToScreen(true)
    window:SetHidden(true)
    window:SetMouseEnabled(true)
    if window.SetDrawTier and DT_HIGH then window:SetDrawTier(DT_HIGH) end
    if ASUI.Settings and ASUI.Settings.ApplyWindowLayer then ASUI.Settings.ApplyWindowLayer(window, false) end
    local background = WINDOW_MANAGER:CreateControl(nil, window, CT_TEXTURE)
    background:SetAnchorFill(window)
    background:SetColor(0.025, 0.03, 0.04, 0.96)
    local label = WINDOW_MANAGER:CreateControl(nil, window, CT_LABEL)
    label:SetFont("ZoFontGameBold")
    label:SetAnchor(TOPLEFT, window, TOPLEFT, 14, 9)
    label:SetDimensions(360, 48)
    label:SetText("MOVE HUD\nDrag your panels. Done or Esc saves their positions.")
    label:SetColor(1, 0.62, 0.22, 1)
    local done = WINDOW_MANAGER:CreateControl(nil, window, CT_BUTTON)
    done:SetDimensions(104, 42)
    done:SetAnchor(RIGHT, window, RIGHT, -12, 0)
    done:SetFont("ZoFontGameBold")
    done:SetText("DONE")
    done:SetMouseEnabled(true)
    done:SetHandler("OnClicked", Layout.Finish)
    window:SetHandler("OnHide", Layout.Finish)
    if SCENE_MANAGER and SCENE_MANAGER.RegisterTopLevel then
        SCENE_MANAGER:RegisterTopLevel(window, true)
    end
    Layout.toolbar = window
    return window
end

function Layout.Start()
    if Layout.active then return true end
    if IsUnitInCombat and IsUnitInCombat("player") then return false end
    for _, module in pairs(Modules()) do if module.loading then return false end end
    local hasHUD=false
    for _, module in pairs(Modules()) do
        if Enabled(module) and module.window then hasHUD=true;break end
    end
    if not hasHUD then return false end
    local toolbar = Layout.CreateToolbar()
    local settings = ASUI.Settings
    for _, entry in pairs(settings and settings.exclusiveWindows or {}) do
        if entry.control and not entry.control:IsHidden() then
            if entry.close then entry.close() else entry.control:SetHidden(true) end
        end
    end
    if settings and settings.CloseMain then settings.CloseMain() end
    -- Native base scenes retain action bars and other addons' gameplay windows.
    if SCENE_MANAGER and SCENE_MANAGER.ShowBaseScene then SCENE_MANAGER:ShowBaseScene() end
    Layout.active = true
    for _, module in pairs(Modules()) do
        if Enabled(module) and module.window then
            Layout.participants[module] = true
            module.sv.locked = false
        end
    end
    if SCENE_MANAGER and SCENE_MANAGER.ShowTopLevel then SCENE_MANAGER:ShowTopLevel(toolbar)
    else toolbar:SetHidden(false) end
    Layout.Refresh()
    return true
end

-- Register only scene/event boundaries; placement owns no heartbeat or frame callback.
if EVENT_MANAGER then
    if EVENT_PLAYER_DEACTIVATED then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Loading", EVENT_PLAYER_DEACTIVATED, function() Layout.Finish(true) end)
    end
    if EVENT_PLAYER_COMBAT_STATE then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Layout_Combat", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
            if inCombat then Layout.Finish() end
        end)
    end
end
if SCENE_MANAGER and SCENE_MANAGER.RegisterCallback then
    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, _, newState)
        if Layout.active and newState == SCENE_SHOWING and scene and scene.GetName then
            local name = scene:GetName()
            if name ~= "hud" and name ~= "hudui" then Layout.Finish() end
        end
    end)
end
if SLASH_COMMANDS then SLASH_COMMANDS["/asmove"] = Layout.Start end
