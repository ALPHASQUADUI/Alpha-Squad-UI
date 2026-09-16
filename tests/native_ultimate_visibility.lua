-- Model ESO's shared keyboard/gamepad slot roots and independently owned alpha.
local assertions, hooks, writes = 0, 0, 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function same(actual, expected, message) check(actual == expected, message) end
ACTION_BAR_ULTIMATE_SLOT_INDEX = 7
ZO_ActionBar1 = {alpha = 0.4}
local moving = false
local ULT = {sv = {enabled = false, visible = true}, window = {hidden = false}}
function ULT.window:IsHidden() return self.hidden end
AlphaSquadUI = {Modules = {ULTTracker = ULT}, Layout = {IsMoving = function() return moving end}}
local function Control(alpha, mouseEnabled, parent)
    local control = {alpha = alpha, hidden = false, parent = parent, handlers = {}, children = {}}
    function control:GetParent() return self.parent end
    function control:GetNamedChild(name) return self.children[name] end
    function control:GetControlAlpha() return self.alpha end
    function control:GetAlpha() return self.alpha * (self.parent and self.parent.alpha or 1) end
    function control:SetAlpha(value) writes = writes + 1; self.alpha = value end
    function control:SetHidden(value)
        self.hidden = value
        if not value then for _, callback in pairs(self.handlers) do callback(self) end end
    end
    function control:SetHandler(event, callback, namespace)
        check(event == "OnEffectivelyShown", "No polling or existing native handler is replaced")
        check(namespace == "AlphaSquadUI_PersonalUltimate", "Native handlers use an addon namespace")
        self.handlers[namespace] = callback
    end
    if mouseEnabled ~= nil then
        control.children.Button = {mouseEnabled = mouseEnabled}
        function control.children.Button:IsMouseEnabled() return self.mouseEnabled end
        function control.children.Button:SetMouseEnabled(value) writes = writes + 1; self.mouseEnabled = value end
    end
    return control
end
ActionButton8 = Control(0.8, true, ZO_ActionBar1)
ActionBarTimer8 = Control(0.65, nil, ZO_ActionBar1)
CompanionUltimateButton = Control(0.7, true, ZO_ActionBar1)
ActionButton7 = Control(1, true, ZO_ActionBar1)
ActionButton = {}
function ActionButton:ApplyStyle(style)
    self.slot.style = style
    -- A style refresh may change presentation and hidden state. It does not
    -- change casting or keybinding registrations on this native button object.
    self.slot:SetHidden(false)
end
ZO_ActionBarTimer = {}
function ZO_ActionBarTimer:ApplyStyle(style) self.slot.style = style; self.slot:SetHidden(false) end
local mainButton = setmetatable({slot = ActionButton8}, {__index = ActionButton})
local timerButton = setmetatable({slot = ActionBarTimer8}, {__index = ZO_ActionBarTimer})
function SecurePostHook(class, name, callback)
    hooks = hooks + 1
    local original = class[name]
    class[name] = function(...) local result = original(...); callback(...); return result end
end

assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTNativeUI.lua"))()
local native = ULT.NativeUI
native:Initialize(); native:Initialize()
same(writes, 0, "Disabled startup never changes native controls")
same(hooks, 0, "Disabled startup installs no hooks")
ULT.sv.enabled = true
native:Refresh()
same(ActionButton8.alpha, 0, "The active ultimate presentation is suppressed")
same(ActionBarTimer8.alpha, 0, "The native back-bar ultimate timer is also suppressed")
same(ActionButton8.children.Button.mouseEnabled, false, "No invisible ultimate mouse target remains")
same(ActionButton8.hidden, false, "The native root hidden state is not changed")
same(CompanionUltimateButton.alpha, 0.7, "The companion ultimate is unchanged")
same(CompanionUltimateButton.children.Button.mouseEnabled, true, "Companion mouse interaction is unchanged")
same(ActionButton7.alpha, 1, "Other action buttons are unchanged")
same(hooks, 2, "Each native Lua style class is hooked once")
local initialWrites = writes
for _ = 1, 20 do native:Refresh(); native:Initialize() end
same(writes, initialWrites, "Unchanged active refreshes avoid redundant property writes")
same(hooks, 2, "Repeated initialize/refresh calls do not duplicate hooks")

mainButton:ApplyStyle("gamepad"); timerButton:ApplyStyle("gamepad")
same(ActionButton8.alpha, 0, "Gamepad style uses the same suppressed ultimate root")
same(ActionBarTimer8.alpha, 0, "Gamepad back-bar style remains suppressed")
ActionButton8:SetHidden(true); ActionButton8:SetHidden(false)
same(ActionButton8.alpha, 0, "Native hide/show updates cannot reveal the suppressed root")
ULT.sv.enabled = false
native:Refresh()
same(ActionButton8.alpha, 0.8, "Disabling restores local alpha, not inherited parent alpha")
same(ActionBarTimer8.alpha, 0.65, "Disabling restores the timer's own opacity")
same(ActionButton8.children.Button.mouseEnabled, true, "Disabling restores native mouse interaction")
same(next(ActionButton8.handlers), nil, "Disabling removes only the owned show handler")
same(hooks, 2, "Inactive secure style hooks are retained without duplication")
initialWrites = writes
mainButton:ApplyStyle("keyboard"); native:Restore()
same(writes, initialWrites, "Disabled native style changes and repeated restore perform no writes")

ULT.sv.enabled = true
for _, reason in ipairs({"invisible", "menu", "loading", "placement", "window"}) do
    native:Refresh()
    if reason == "invisible" then ULT.sv.visible = false
    elseif reason == "menu" then ULT.uiObscured = true
    elseif reason == "loading" then ULT.loading = true
    elseif reason == "placement" then moving = true
    else ULT.window.hidden = true end
    ActionButton8:SetHidden(true)
    native:Refresh()
    same(ActionButton8.alpha, 0.8, reason .. " restores native ultimate ownership")
    same(ActionButton8.hidden, true, reason .. " never force-shows a native hidden control")
    ULT.sv.visible, ULT.uiObscured, ULT.loading, moving, ULT.window.hidden = true, false, false, false, false
    ActionButton8:SetHidden(false)
end

native:Refresh()
ActionButton8:SetAlpha(0.45)
native:Refresh()
same(ActionButton8.alpha, 0, "A refreshed external alpha is suppressed while the HUD replaces it")
ULT.sv.visible = false; native:Refresh()
same(ActionButton8.alpha, 0.45, "The newest observed external alpha becomes the restoration baseline")
ULT.sv.visible = true; native:Refresh()
ActionButton8:SetAlpha(0.3)
ULT.sv.enabled = false; native:Refresh()
same(ActionButton8.alpha, 0.3, "Restore preserves a newer external write without first refreshing")
ActionButton8:SetAlpha(0)
ActionButton8.children.Button:SetMouseEnabled(false)
ULT.sv.enabled = true; native:Refresh()
ULT.sv.enabled = false; native:Refresh()
same(ActionButton8.alpha, 0, "A native/other-addon zero alpha is not forced visible")
same(ActionButton8.children.Button.mouseEnabled, false, "An originally disabled mouse target remains disabled")

-- SavedVariables/profile replacement must be read live, never captured at init.
ActionButton8:SetAlpha(1)
ULT.sv = {enabled = true, visible = true}; native:Refresh()
ULT.sv = {enabled = true, visible = false}; native:Refresh()
same(ActionButton8.alpha, 1, "A hidden personal HUD in a new profile restores native presentation")
ULT.sv = {enabled = true, visible = true}; native:Refresh()
ULT.sv = {enabled = false, visible = true}; native:Refresh()
same(ActionButton8.alpha, 1, "A disabled replacement profile restores native presentation")

-- Loading late or replacement controls do not require a timer or global search.
local oldMain = ActionButton8
ActionButton8, ActionBarTimer8 = nil, nil
ULT.sv.enabled = true; native:Refresh()
same(oldMain.alpha, 1, "Removed native roots release their original presentation")
ActionButton8 = Control(0.55, true, ZO_ActionBar1)
ActionBarTimer8 = Control(0.9, nil, ZO_ActionBar1)
native:Refresh()
same(ActionButton8.alpha, 0, "Late native controls are discovered on the next lifecycle refresh")
same(hooks, 2, "New controls reuse the existing bounded native style hooks")
ULT.window = nil; native:Refresh()
same(ActionButton8.alpha, 0.55, "A missing replacement window immediately restores the native slot")
ULT.window = {IsHidden = function() return false end}
native:Refresh()
ActionButton8.parent = {}
native:Refresh()
same(ActionButton8.alpha, 0.55, "A native control moved by another owner releases suppression")
same(ActionButton8.children.Button.mouseEnabled, true, "A moved native control regains its original mouse state")
ActionButton8 = Control(0.55, true, {})
native:Refresh()
same(ActionButton8.alpha, 0.55, "An unrelated same-name control outside the native action bar is not touched")
ActionButton8 = Control(0.55, true, ZO_ActionBar1)
ActionButton8.GetControlAlpha = nil
native:Refresh()
same(ActionButton8.alpha, 0.55, "Missing local-alpha API leaves the native slot available")
ActionButton8 = Control(0.55, nil, ZO_ActionBar1)
native:Refresh()
same(ActionButton8.alpha, 0.55, "An unsupported mouse target is never made invisibly clickable")
print(string.format("Native ultimate visibility: %d assertions passed", assertions))
