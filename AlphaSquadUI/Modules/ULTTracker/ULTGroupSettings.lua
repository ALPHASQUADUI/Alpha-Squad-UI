-- Ąlpha Şquad UI - ULT Tracker / Group Ultimate Filter Configuration

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT or not ULT.Group then return end

local Group = ULT.Group
local function L(text, ...)
    if AlphaSquadUI.L then return AlphaSquadUI.L(text, ...) end
    return select("#", ...) > 0 and string.format(text, ...) or text
end

local COLORS = ULT.COLORS or {
    bg = {0.010, 0.016, 0.030, 0.98},
    panel = {0.020, 0.030, 0.052, 0.98},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

local function Palette(role,fallback)
    local theme=AlphaSquadUI.Theme
    return theme and theme.colors and theme.colors[role] or COLORS[role] or fallback or COLORS.bg
end
local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function Solid(parent, name, color)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetAnchorFill(parent)
    SetColor(texture, color)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(texture,color) end
    return texture
end

local function Label(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(L(text or ""))
    if text and text ~= "" and AlphaSquadUI.Localization then AlphaSquadUI.Localization.Bind(label, text) end
    SetColor(label, color or COLORS.white)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(label,color or COLORS.white) end
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return label
end

local function Button(parent, name, text, x, y, w, h, callback)
    local button = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    button:SetDimensions(w, h)
    button:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    button:SetMouseEnabled(true)

    button.bg = Solid(button, name .. "BG", Palette("panel"))
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(button,button.bg,"button") end
    button.label = Label(button, name .. "Label", "ZoFontGameSmall", text or "", COLORS.white)
    button.label:SetAnchorFill(button)
    button.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    button.label:SetMaxLineCount(1)
    if button.label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then button.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end

    button:SetHandler("OnMouseEnter", function()
        SetColor(button.bg,Palette("hover",COLORS.panel))
        if button.help and AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.ShowText(button, L(button.help)) end
    end)
    button:SetHandler("OnMouseExit", function()
        SetColor(button.bg,Palette("panel"))
        if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
    end)
    button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and callback then
            callback(button)
        end
    end)

    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(button,{activate=function() if callback then callback(button) end end,label=text}) end
    return button
end

function Group:ShowAuthorityNotice(reason)
    local win = self.configWindow
    if win and win.permission then
        win.notice = reason or "Only the designated raid leader can change Ultimate filters."
        win.permission:SetText(L(win.notice))
        SetColor(win.permission, COLORS.gold)
    end
end

function Group:TrySetTracked(key, enabled)
    if self.CanEditFilters then
        local allowed, reason = self:CanEditFilters()
        if not allowed then self:ShowAuthorityNotice(reason); return false end
    end
    local changed, reason = self:SetAbilityTracked(key, enabled)
    if changed == false then self:ShowAuthorityNotice(reason); return false end
    if self.configWindow then self.configWindow.notice = nil end
    self:RefreshConfig()
    return true
end

function Group:RefreshLeaderChoice()
    local win, sync = self.configWindow, self.Sync
    if not win then return end
    local members = sync and sync.GetMembers and sync:GetMembers() or {}
    local leader = sync and sync.GetLeader and sync:GetLeader() or nil
    local canAssign = sync and sync.CanAssignLeader and sync:CanAssignLeader() or false
    local language = AlphaSquadUI.Localization and AlphaSquadUI.Localization.GetLanguage() or "en"
    local signature = {language}
    for _, member in ipairs(members) do
        signature[#signature + 1] = tostring(member.account) .. (member.isCrown and "1" or "0")
    end
    signature = table.concat(signature, "|")
    local authority = table.concat({signature, tostring(leader), tostring(canAssign)}, "|")
    if win.authoritySignature ~= authority then win.notice = nil; win.authoritySignature = authority end
    local combo = win.leaderCombo
    if combo then
        if win.leaderSignature ~= signature then
            win.leaderSignature = signature
            combo:ClearItems()
            for _, member in ipairs(members) do
                local account = member.account
                local text = member.isCrown and L("%s (crown)", account) or account
                local item = combo:CreateItemEntry(text, function()
                    local current = Group.Sync
                    if not current then return end
                    local allowed, reason = current:CanAssignLeader()
                    if not allowed then Group:ShowAuthorityNotice(reason); return end
                    local changed, failure = current:SetLeader(account)
                    if changed == false then Group:ShowAuthorityNotice(failure)
                    else win.notice = nil; Group:RefreshConfig() end
                end)
                item.account = account
                combo:AddItem(item)
            end
        end
        if #members > 0 then
            combo:SetSelectedItemByEval(function(item) return item.account == leader end, true)
        elseif combo.SetSelectedItem then combo:SetSelectedItem(L("No group")) end
        if combo.SetEnabled then combo:SetEnabled(canAssign) end
    elseif win.leaderFallback then
        win.leaderFallback:SetText(leader or L("No group"))
    end
    if win.permission then
        local text = win.notice or (#members == 0 and "Solo: filters are saved for your next group."
            or "The crown appoints the raid leader. The raid leader controls these filters.")
        win.permission:SetText(L(text))
        SetColor(win.permission, win.notice and COLORS.gold or COLORS.muted)
    end
    if win.syncStatus then
        win.syncStatus:SetText(L(sync and sync.GetStatus and sync:GetStatus() or "Settings sync unavailable"))
    end
end

local function CreateAbilityRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupAbilityRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(232, 64)
    row:SetMouseEnabled(true)

    row.bg = Solid(row, "AlphaSquadULTGroupAbilityRow" .. index .. "BG", Palette("surface"))
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(row,row.bg,"tile") end

    row.icon = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupAbilityRow" .. index .. "Icon", row, CT_TEXTURE)
    row.icon:SetDimensions(32, 32)
    row.icon:SetAnchor(LEFT, row, LEFT, 8, 0)
    row.icon:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    row.name = Label(row, "AlphaSquadULTGroupAbilityRow" .. index .. "Name", "ZoFontGameSmall", "", COLORS.white)
    row.name:SetDimensions(138, 42)
    row.name:SetAnchor(LEFT, row, LEFT, 46, 0)
    row.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.name:SetMaxLineCount(2)
    if row.name.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.name:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    row.state = Label(row, "AlphaSquadULTGroupAbilityRow" .. index .. "State", "ZoFontGameBold", "", COLORS.muted)
    row.state:SetDimensions(38, 30)
    row.state:SetAnchor(RIGHT, row, RIGHT, -4, 0)
    row.state:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.ability = nil
    row:SetHandler("OnMouseEnter", function()
        if row.ability and Group:IsAbilityTracked(row.ability.key or row.ability.id) then
            SetColor(row.bg,Palette("selected",COLORS.panel))
        else
            SetColor(row.bg,Palette("hover",COLORS.panel))
        end
        local tooltips = AlphaSquadUI.Tooltips
        local ability = row.ability
        if tooltips and ability then
            local description = ""
            if GetAbilityDescription then
                local ok, value = pcall(GetAbilityDescription, ability.id)
                if ok and type(value) == "string" then description = value end
            end
            tooltips.ShowText(row, (ability.name or L("Unknown Ultimate"))
                .. (description ~= "" and ("\n\n" .. description) or "")
                .. "\n\n" .. L("One toggle includes every listed morph in this family.")
                .. "\n" .. L("%d group members", ability.users or 0))
        end
    end)

    row:SetHandler("OnMouseExit", function()
        if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
        if row.ability and Group:IsAbilityTracked(row.ability.key or row.ability.id) then
            SetColor(row.bg,Palette("selected",COLORS.panel))
        else
            SetColor(row.bg,Palette("surface"))
        end
    end)

    row:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and row.ability then
            local enabled = Group:IsAbilityTracked(row.ability.key or row.ability.id)
            Group:TrySetTracked(row.ability.key or row.ability.id, not enabled)
        end
    end)
    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then
        AlphaSquadUI.Input.Register(row,{activate=function()
            if row.ability then Group:TrySetTracked(row.ability.key or row.ability.id,not Group:IsAbilityTracked(row.ability.key or row.ability.id)) end
        end,label="Ultimate filter"})
    end
    return row
end

function Group:RefreshAbilityRow(row, ability, canEdit)
    if not row then return end

    if not ability then
        row:SetHidden(true)
        row.ability = nil
        return
    end

    row:SetHidden(false)
    row.ability = ability

    row.icon:SetHidden(false)
    row.icon:SetTexture(ability.icon and ability.icon~="" and ability.icon or "EsoUI/Art/ActionBar/abilityFrame64_up.dds")

    row.name:SetText(ability.name and ability.name ~= "" and ability.name or L("Unknown Ultimate"))
    row:SetAlpha(canEdit and 1 or 0.65)

    local tracked = self:IsAbilityTracked(ability.key or ability.id)
    row.state:SetText(L(tracked and "ON" or "OFF"))
    SetColor(row.state, tracked and COLORS.green or COLORS.muted)

    if tracked then
        SetColor(row.bg,Palette("selected",COLORS.panel))
    else
        SetColor(row.bg,Palette("surface"))
    end
end

function Group:RefreshConfig()
    if not self.configWindow or self.configWindow:IsHidden() then return end

    self:RefreshLeaderChoice()
    local abilities = self:GetAvailableAbilities()
    local shared, total = self:GetSharingCount()
    local trackedCount = self:GetTrackedAbilityCount()

    if not self.libraryAvailable then
        self.configWindow.source:SetText(L("Group sharing unavailable • Check Libraries"))
        SetColor(self.configWindow.source, COLORS.red)
    else
        self.configWindow.source:SetText(L("%d/%d sharing • %d families selected",
            shared, total, trackedCount))
        SetColor(self.configWindow.source, shared > 0 and COLORS.green or COLORS.muted)
    end

    self.configWindow.empty:SetHidden(#abilities > 0)
    if #abilities==0 then
        self.configWindow.empty:SetText(L(total==0 and "Join a group to view shared Ultimates."
            or "No shared Ultimates. Check Libraries."))
    end

    local canEdit = not self.CanEditFilters or self:CanEditFilters()
    for index, row in ipairs(self.configWindow.abilityRows) do
        local ability = abilities[index]
        self:RefreshAbilityRow(row, ability, canEdit)

        if ability then
            row:ClearAnchors()
            local column = (index - 1) % 3
            local line = math.floor((index - 1) / 3)
            local parent = self.configWindow.abilityContent or self.configWindow
            row:SetAnchor(TOPLEFT, parent, TOPLEFT, (self.configWindow.abilityContent and 0 or 22) + column * 242,
                (self.configWindow.abilityContent and 0 or 216) + line * 72)
        end
    end
    if self.configWindow.abilityContent then
        self.configWindow.abilityContent:SetHeight(math.max(324, math.ceil(math.min(#abilities, 24) / 3) * 72))
    end

end

function Group:OpenConfig()
    if not self.configWindow then return end
    if self.Sync and self.Sync.RequestRefresh then self.Sync:RequestRefresh() end
    self:BuildRoster()
    self:ApplyConfigWindowScale()
    local settings = AlphaSquadUI.Settings
    if settings and settings.ShowExclusiveWindow then settings.ShowExclusiveWindow("groupultimate")
    else self.configWindow:SetHidden(false) end
    self:RefreshConfig()
    self:ApplyVisibility()
end

function Group:CloseConfig()
    if not self.configWindow then return end
    self.configWindow:SetHidden(true)
    if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
    self:ApplyVisibility()
    local settings = AlphaSquadUI.Settings
    if settings and settings.RefreshModuleVisibility then settings.RefreshModuleVisibility() end
end

function Group:ToggleConfig()
    if not self.configWindow then return end
    if self.configWindow:IsHidden() then self:OpenConfig()
    elseif AlphaSquadUI.Settings and AlphaSquadUI.Settings.CloseExclusiveWindow then AlphaSquadUI.Settings.CloseExclusiveWindow("groupultimate")
    else self:CloseConfig() end
end

function Group:CreateConfigWindow()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupConfigWindow")
    self.configWindow = win

    win:SetDimensions(780, 630)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(140)
    if AlphaSquadUI.Settings and AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win, false) end
    win:SetHidden(true)
    local settings = AlphaSquadUI.Settings
    if settings and settings.RegisterExclusiveWindow then
        settings.RegisterExclusiveWindow("groupultimate", win, function() Group:CloseConfig() end, {fallbackPage="ulttracker"})
    end

    win.bg=Solid(win,"AlphaSquadULTGroupConfigBG",Palette("bg"))
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(win,win.bg,"window") end

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigTop", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(3)
    SetColor(top,Palette("accent",COLORS.orange))

    local header = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupConfigHeader", win, CT_CONTROL)
    header:SetDimensions(780, 62)
    header:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    header:SetMouseEnabled(true)
    header:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then win:StartMoving() end
    end)
    header:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then win:StopMovingOrResizing() end
    end)

    local title = Label(win, "AlphaSquadULTGroupConfigTitle", "ZoFontWinH2", "GROUP ULTIMATES", COLORS.orange)
    title:SetDimensions(480, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    title:SetMaxLineCount(1)
    if title.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then title:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end

    local sub = Label(win, "AlphaSquadULTGroupConfigSub", "ZoFontGameSmall",
        "Group support Ultimates and their morphs.", COLORS.muted)
    sub:SetDimensions(704, 24)
    sub:SetMaxLineCount(1)
    sub:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 39)
    sub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    Button(win, "AlphaSquadULTGroupConfigClose", "X", 730, 15, 32, 28, function()
        local settings=AlphaSquadUI.Settings
        if settings and settings.CloseExclusiveWindow then settings.CloseExclusiveWindow("groupultimate")
        else Group:CloseConfig() end
    end)

    win.source = Label(win, "AlphaSquadULTGroupConfigSource", "ZoFontGameSmall", "", COLORS.muted)
    win.source:SetDimensions(736, 24)
    win.source:SetMaxLineCount(1)
    win.source:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 68)
    win.source:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local leaderLabel = Label(win, "AlphaSquadULTGroupLeaderLabel", "ZoFontGameBold", "RAID LEADER", COLORS.white)
    leaderLabel:SetDimensions(166, 30)
    leaderLabel:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 102)
    if WINDOW_MANAGER.CreateControlFromVirtual and type(ZO_ComboBox_ObjectFromContainer) == "function" then
        local container = WINDOW_MANAGER:CreateControlFromVirtual("AlphaSquadULTGroupLeaderChoice", win, "ZO_ComboBox")
        container:SetDimensions(400, 32)
        container:SetAnchor(TOPLEFT, win, TOPLEFT, 192, 100)
        win.leaderCombo = ZO_ComboBox_ObjectFromContainer(container)
        win.leaderCombo:SetSortsItems(false)
        if AlphaSquadUI.Theme and AlphaSquadUI.Theme.ConfigureDropdown then
            AlphaSquadUI.Theme.ConfigureDropdown(win.leaderCombo)
        end
        if AlphaSquadUI.Input then
            AlphaSquadUI.Input.Register(container, {kind="dropdown", combo=win.leaderCombo, label="Raid leader"})
        end
    else
        win.leaderFallback = Label(win, "AlphaSquadULTGroupLeaderFallback", "ZoFontGame", "No group", COLORS.muted)
        win.leaderFallback:SetDimensions(400, 32)
        win.leaderFallback:SetAnchor(TOPLEFT, win, TOPLEFT, 192, 100)
    end
    win.permission = Label(win, "AlphaSquadULTGroupPermission", "ZoFontGameSmall", "", COLORS.muted)
    win.permission:SetDimensions(736, 38)
    win.permission:SetMaxLineCount(2)
    win.permission:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 138)
    win.permission:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    win.syncStatus = Label(win, "AlphaSquadULTGroupSyncStatus", "ZoFontGameSmall", "", COLORS.muted)
    win.syncStatus:SetDimensions(480, 22)
    win.syncStatus:SetMaxLineCount(1)
    win.syncStatus:SetAnchor(TOPRIGHT, win, TOPRIGHT, -22, 186)
    win.syncStatus:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    local listHeader = Label(win, "AlphaSquadULTGroupAbilitiesHeader", "ZoFontGameBold",
        "ULTIMATE FILTERS", COLORS.orange)
    listHeader:SetDimensions(736, 22)
    listHeader:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 186)
    listHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.abilityRows = {}
    if settings and settings.CreateScrollArea then
        win.abilityContent, win.abilityScroll = settings.CreateScrollArea(win, "AlphaSquadULTGroupAbilityScroll", 22, 216, 736, 324, 324)
    end
    for index = 1, 24 do
        win.abilityRows[index] = CreateAbilityRow(win.abilityContent or win, index)
        win.abilityRows[index]:SetHidden(true)
    end

    win.empty = Label(win, "AlphaSquadULTGroupConfigEmpty", "ZoFontGame", "No shared Ultimates. Check Libraries.", COLORS.muted)
    win.empty:SetDimensions(736, 80)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 22, 270)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    win.empty:SetHidden(true)

    local controlsY = 552

    local function SetAll(enabled)
        if Group.CanEditFilters then
            local allowed, reason = Group:CanEditFilters()
            if not allowed then Group:ShowAuthorityNotice(reason); return end
        end
        if Group.SetAllTracked then
            local changed, reason = Group:SetAllTracked(enabled)
            if changed == false then Group:ShowAuthorityNotice(reason); return end
        else
            for _, ability in ipairs(Group:GetAvailableAbilities()) do
                Group:SetAbilityTracked(ability.key or ability.id, enabled)
            end
        end
        win.notice = nil
        Group:RefreshConfig()
    end
    Button(win, "AlphaSquadULTGroupSelectAll", "SELECT ALL", 22, controlsY, 148, 28, function() SetAll(true) end)
    Button(win, "AlphaSquadULTGroupClearAll", "CLEAR ALL", 178, controlsY, 148, 28, function() SetAll(false) end)

    Button(win, "AlphaSquadULTGroupMoveHUD", "MOVE HUD", 590, controlsY, 168, 28, function()
        if AlphaSquadUI.Layout and AlphaSquadUI.Layout.Start then AlphaSquadUI.Layout.Start(Group) end
    end)

    local saveNote=Label(win,"AlphaSquadULTGroupSaveNote","ZoFontGameSmall",
        "Food: green = active; red = verified absent; ? = unknown.",COLORS.muted)
    saveNote:SetDimensions(736,32)
    saveNote:SetAnchor(TOPLEFT,win,TOPLEFT,22,586)
    saveNote:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    saveNote:SetVerticalAlignment(TEXT_ALIGN_TOP)

    self:ApplyConfigWindowScale()
end
