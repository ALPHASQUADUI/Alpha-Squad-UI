-- Replace only the player's native ultimate presentation while its HUD is usable.
-- ESO shares ActionButton8 / ActionBarTimer8 between keyboard and gamepad styles.
-- Their descendants contain the frame, meter, number, effects and keybind labels.
local ASUI = AlphaSquadUI
local ULT = ASUI and ASUI.Modules and ASUI.Modules.ULTTracker
if not ULT then return end

local NativeUI = ULT.NativeUI or {}
ULT.NativeUI = NativeUI
local records = {}
local hookedClasses = {}
local HANDLER_NAME = "AlphaSquadUI_PersonalUltimate"

local function LocalAlpha(control)
    if not control or type(control.GetControlAlpha) ~= "function" then return nil end
    local alpha = control:GetControlAlpha()
    if type(alpha) ~= "number" or alpha ~= alpha or alpha < 0 or alpha > 1 then return nil end
    return alpha
end

local function Release(record)
    if not record then return end
    local control = record.control
    if record.watching then
        control:SetHandler("OnEffectivelyShown", nil, HANDLER_NAME)
        record.watching = false
    end
    -- A newer external write owns the property. Do not overwrite it on release.
    if record.alpha ~= nil and LocalAlpha(control) == 0 then
        control:SetAlpha(record.alpha)
    end
    record.alpha = nil
    if record.mouse and record.mouseEnabled ~= nil then
        if record.mouse:IsMouseEnabled() == false then
            record.mouse:SetMouseEnabled(record.mouseEnabled)
        end
        record.mouseEnabled = nil
    end
end

function NativeUI:CanReplace()
    local sv, window = ULT.sv, ULT.window
    if not sv or sv.enabled ~= true or sv.visible ~= true or not window
        or type(window.IsHidden) ~= "function" or window:IsHidden()
        or ULT.loading or ULT.uiObscured then return false end
    if ASUI.Layout and ASUI.Layout.IsMoving and ASUI.Layout.IsMoving(ULT) then return false end
    if type(window.GetAlpha) == "function" and window:GetAlpha() <= 0 then return false end
    return true
end

function NativeUI:Restore()
    if self.busy then return end
    self.busy, self.active = true, false
    for _, record in pairs(records) do Release(record) end
    self.busy = false
end

local function WatchStyle(class)
    if type(class) ~= "table" or hookedClasses[class] or type(class.ApplyStyle) ~= "function"
        or type(SecurePostHook) ~= "function" then return end
    -- Hook the Lua presentation method, never protected actions or control methods.
    SecurePostHook(class, "ApplyStyle", function(button)
        if not NativeUI.active or NativeUI.busy then return end
        for _, record in pairs(records) do
            if record.control == button.slot then NativeUI:Refresh(); return end
        end
    end)
    hookedClasses[class] = true
end

local function Suppress(name, hasButton)
    local control = _G[name]
    local record = records[name]
    if record and record.control ~= control then Release(record); records[name] = nil; record = nil end
    if not control or type(control.SetAlpha) ~= "function" or type(control.SetHandler) ~= "function"
        or type(control.GetParent) ~= "function" or control:GetParent() ~= ZO_ActionBar1
        or not ZO_ActionBar1 then
        Release(record); records[name] = nil; return
    end
    local alpha = LocalAlpha(control)
    if alpha == nil then return end
    local mouse = hasButton and control.GetNamedChild and control:GetNamedChild("Button") or nil
    -- An invisible clickable slot is not a usable replacement. Unsupported controls
    -- stay native instead of leaving a hidden mouse target over the action bar.
    if hasButton and (not mouse or type(mouse.SetMouseEnabled) ~= "function"
        or type(mouse.IsMouseEnabled) ~= "function") then
        Release(record); records[name] = nil; return
    end
    if not record then record = {control = control}; records[name] = record end
    if record.alpha == nil or alpha ~= 0 then record.alpha = alpha end
    if mouse then
        if record.mouse and record.mouse ~= mouse and record.mouseEnabled ~= nil
            and record.mouse:IsMouseEnabled() == false then
            record.mouse:SetMouseEnabled(record.mouseEnabled)
        end
        if record.mouse ~= mouse then record.mouseEnabled = nil end
        record.mouse = mouse
        local enabled = mouse:IsMouseEnabled()
        if record.mouseEnabled == nil or enabled ~= false then record.mouseEnabled = enabled end
        if enabled then mouse:SetMouseEnabled(false) end
    end
    if not record.watching then
        control:SetHandler("OnEffectivelyShown", function()
            if NativeUI.active and not NativeUI.busy then NativeUI:Refresh() end
        end, HANDLER_NAME)
        record.watching = true
    end
    if alpha ~= 0 then control:SetAlpha(0) end
end

function NativeUI:Refresh()
    if self.busy then return end
    if not self:CanReplace() then self:Restore(); return end
    self.busy, self.active = true, true
    local slot = (ACTION_BAR_ULTIMATE_SLOT_INDEX or 7) + 1
    Suppress("ActionButton" .. slot, true)
    Suppress("ActionBarTimer" .. slot, false)
    WatchStyle(ActionButton)
    WatchStyle(ZO_ActionBarTimer)
    self.busy = false
end

function NativeUI:Initialize()
    self.initialized = true
    self:Refresh()
end
