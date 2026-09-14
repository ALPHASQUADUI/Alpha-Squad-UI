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
    local mainWindow = settings and settings.mainWindow
    if mainWindow and not mainWindow:IsHidden() and settings.RefreshMain then
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
-- without coupling module-specific behavior to the Core shell.
function ULT:BuildIntegratedSettingsPage(page,ui)
    if not page or not ui then return end
    local C=ui.colors or COLORS
    page.responsiveCards=true;page.contentHeight=590
    local width=page:GetWidth()-16;local half=(width-16)/2
    local function Label(parent,name,text,x,y,w,h,font,color)
        local label=ui.CreateLabel(parent,name,font or "ZoFontGameSmall",text,color or C.muted)
        label:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);label:SetDimensions(w,h)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT);label:SetVerticalAlignment(TEXT_ALIGN_TOP)
        return label
    end
    Label(page,"AlphaSquadULTIntegratedTitle","ULT TRACKER",8,2,width,34,"ZoFontWinH2",C.orange)
    Label(page,"AlphaSquadULTIntegratedSub","Your Ultimates and optional Overload behavior share one personal HUD. Configure group tracking separately below.",8,42,width,32)
    local general=ui.CreateCard(page,"AlphaSquadULTIntegratedGeneral",8,86,half,216,"PERSONAL HUD",C.orange)
    ui.AddToggleRow(general,"AlphaSquadULTIntegratedVisible","Show personal HUD",42,
        function() return ULT.sv and ULT.sv.visible==true end,function(v) ULT:SetVisible(v) end)
    ui.AddToggleRow(general,"AlphaSquadULTIntegratedMenus","Hide in game menus",82,
        function() return ULT.sv and ULT.sv.hideInMenus==true end,function(v) ULT.sv.hideInMenus=v==true;ULT:ApplyVisibility() end)
    Label(general,"AlphaSquadULTPlacementHelp","Position, size and opacity are adjusted together in Move HUD. Drag edges to rearrange the panel; drag corners to scale it.",14,132,half-28,66)
    local tracking=ui.CreateCard(page,"AlphaSquadULTIntegratedTracking",half+24,86,half,216,"BARS & READINESS",C.cyan)
    local choices={{"auto","AUTO"},{"main","FRONT"},{"back","BACK"},{"both","BOTH"}}
    local buttons={};local buttonWidth=(half-28-24)/4
    for index,choice in ipairs(choices) do
        local mode=choice[1]
        local button=ui.CreateButton(tracking,"AlphaSquadULTMode"..mode,choice[2],14+(index-1)*(buttonWidth+8),44,buttonWidth,34,function() ULT:SetTrackMode(mode) end)
        button.help="Auto follows the active weapon bar. Enabled Overload behavior takes priority over Auto, Front and Back when slotted on either bar. Both always shows both native Ultimate cards."
        buttons[mode]=button
    end
    ui.RegisterRefresher(function()
        for mode,button in pairs(buttons) do
            local selected=ULT.sv and ULT.sv.trackMode==mode
            button.restingColor=selected and C.panelActive or C.panel
            SetColor(button.bg,button.restingColor);SetColor(button.label,selected and C.orange or C.white)
        end
    end)
    ui.AddToggleRow(tracking,"AlphaSquadULTIntegratedSound","Standard Ultimate ready sounds",104,
        function() return ULT.sv and ULT.sv.readySound==true end,function(v) ULT.sv.readySound=v==true end)
    ui.AddToggleRow(tracking,"AlphaSquadULTIntegratedFlash","Highlight standard ready Ultimates",146,
        function() return ULT.sv and ULT.sv.readyFlash==true end,function(v) ULT.sv.readyFlash=v==true;ULT:Refresh("ready highlight") end)
    local overload=ui.CreateCard(page,"AlphaSquadULTIntegratedOverload",8,318,half,112,"OVERLOAD",C.gold)
    Label(overload,"AlphaSquadULTOverloadIntro","Reserve alerts, native auto-stop and the ready reminder.",14,38,half-220,60)
    ui.CreateButton(overload,"AlphaSquadULTOverloadSettings","OVERLOAD SETTINGS",half-194,42,180,38,function() AlphaSquadUI.Settings.OpenPage("ultoverload") end)
    local runtime=ui.CreateCard(page,"AlphaSquadULTIntegratedRuntime",half+24,318,half,244,"CURRENT ULTIMATES",C.green)
    local nativeRows={}
    for index,key in ipairs({"primary","backup"}) do
        local rowY=40+(index-1)*74
        local icon=WINDOW_MANAGER:CreateControl("AlphaSquadULTSettingsIcon"..key,runtime,CT_TEXTURE)
        icon:SetAnchor(TOPLEFT,runtime,TOPLEFT,14,rowY);icon:SetDimensions(44,44);icon:SetMouseEnabled(true)
        icon:SetHandler("OnMouseEnter",function()
            local bar=ULT.bars[key]
            if bar and bar.abilityId>0 and AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.ShowSkill(icon,{id=bar.abilityId,name=bar.name},false) end
        end)
        icon:SetHandler("OnMouseExit",function() if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end end)
        local text=Label(runtime,"AlphaSquadULTSettingsNative"..key,"",70,rowY,half-84,62)
        nativeRows[key]={icon=icon,text=text}
    end
    local counter=Label(runtime,"AlphaSquadULTIntegratedCurrent","",14,192,half-28,28,"ZoFontGameBold",C.gold)
    ui.RegisterRefresher(function()
        for key,row in pairs(nativeRows) do
            local bar=ULT.bars[key];local label=key=="primary" and "FRONT" or "BACK"
            row.icon:SetHidden(not bar or bar.abilityId<=0 or bar.icon=="")
            if bar and bar.icon~="" then row.icon:SetTexture(bar.icon) end
            row.text:SetText(label.." • "..(bar and bar.name~="" and bar.name or "No Ultimate").."\n"..string.upper(bar and bar.state or "empty"))
        end
        counter:SetText(string.format("ULTIMATE: %d",tonumber(ULT.currentUltimate) or 0))
    end)
    local group=ui.CreateCard(page,"AlphaSquadULTIntegratedGroup",8,446,half,116,"GROUP ULTIMATES",C.cyan)
    local groupStatus=Label(group,"AlphaSquadULTIntegratedGroupStatus","",14,38,half-222,68)
    ui.CreateButton(group,"AlphaSquadULTIntegratedGroupConfig","CONFIGURE GROUP",half-194,42,180,38,function() if ULT.Group then ULT.Group:OpenConfig() end end)
    ui.RegisterRefresher(function()
        local tracker=ULT.Group
        if not tracker or not tracker.sv then groupStatus:SetText("Group Ultimate tracking");return end
        local shared,count=tracker:GetSharingCount()
        if not tracker.libraryAvailable then groupStatus:SetText("LibGroupCombatStats required for group values.");SetColor(groupStatus,C.red)
        else groupStatus:SetText(string.format("%d / %d sharing\n%s",shared,count,tracker.sv.enabled and "Tracking enabled" or "Tracking disabled"));SetColor(groupStatus,C.muted) end
    end)
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ulttracker",function(page,ui) ULT:BuildIntegratedSettingsPage(page,ui) end)
end

function ULT:BuildOverloadSettingsPage(page,ui)
    local C=ui.colors or COLORS
    page.responsiveCards=true;page.contentHeight=590
    local width=page:GetWidth()-16;local half=(width-16)/2
    local function Label(parent,name,text,x,y,w,h,font,color)
        local label=ui.CreateLabel(parent,name,font or "ZoFontGameSmall",text,color or C.muted)
        label:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);label:SetDimensions(w,h)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT);label:SetVerticalAlignment(TEXT_ALIGN_TOP)
        return label
    end
    Label(page,"AlphaSquadOverloadOptionsTitle","OVERLOAD",8,2,width-200,34,"ZoFontWinH2",C.orange)
    ui.CreateButton(page,"AlphaSquadOverloadBack","ULT TRACKER",width-174,2,172,34,function() AlphaSquadUI.Settings.OpenPage("ulttracker") end)
    Label(page,"AlphaSquadOverloadOptionsIntro","Optional Overload behavior in your personal Ultimate HUD. One position, one size and no duplicate panel.",8,42,width,40)
    local behavior=ui.CreateCard(page,"AlphaSquadOverloadBehavior",8,94,half,172,"BEHAVIOR",C.orange)
    local function Toggle(parent,id,text,key,y,help)
        ui.AddToggleRow(parent,"AlphaSquadOverloadOption"..id,text,y,
            function() return ULT.sv and ULT.sv.overload and ULT.sv.overload[key]==true end,
            function(value) if ULT.Overload then ULT.Overload:SetOption(key,value) end end,help)
    end
    Toggle(behavior,"Enabled","Use Overload behavior","enabled",42,"ON prioritizes slotted Overload on either bar, except in Both mode. OFF uses standard Ultimate behavior. This does not change group sharing.")
    Toggle(behavior,"PvP","Disable specialized behavior in PvP","disableInPvP",82,"Use standard Ultimate tracking in PvP while retaining your Overload settings for PvE.")
    Label(behavior,"AlphaSquadOverloadSameLayout","Use Move HUD to place or resize this shared personal panel.",14,124,half-28,40)
    local reserve=ui.CreateCard(page,"AlphaSquadOverloadReserve",half+24,94,half,252,"ULTIMATE RESERVE",C.red)
    Toggle(reserve,"Reserve","Reserve alerts and auto-stop","reserveCutoffEnabled",42,"Warn below the reserve threshold. Auto-stop uses CancelBuff only if ESO confirms the current player effect is click-off capable; otherwise press your Ultimate key.")
    Toggle(reserve,"ReserveSound","Reserve alert sounds","reserveSound",82)
    local function Step(parent,id,text,key,y,minimum)
        ui.AddStepperRow(parent,"AlphaSquadOverloadOption"..id,text,y,
            function() return ULT.sv and ULT.sv.overload and ULT.sv.overload[key] or minimum end,
            function(value) if ULT.Overload then ULT.Overload:SetOption(key,value) end end,5,minimum,500,"",C.gold)
    end
    Step(reserve,"Warning","Warning starts","reserveWarningThreshold",126,25)
    Step(reserve,"Stop","Auto-stop at","reserveThreshold",170,25)
    Label(reserve,"AlphaSquadOverloadReserveNote","Warnings cannot be lower than auto-stop. No simulated key press is used.",14,212,half-28,34)
    local ready=ui.CreateCard(page,"AlphaSquadOverloadReady",8,282,half,198,"READY REMINDER",C.gold)
    Toggle(ready,"Ready","Remind when ready to activate","readyReminderEnabled",42)
    Toggle(ready,"ReadySound","Reminder sound","readyReminderSound",82)
    Step(ready,"ReadyThreshold","Ready at","readyReminderThreshold",126,100)
    local help=ui.CreateCard(page,"AlphaSquadOverloadHelp",half+24,362,half,118,"HOW IT WORKS",C.cyan)
    Label(help,"AlphaSquadOverloadHelpText","The native slotted morph supplies the icon and name. Reserve alerts apply only to active Overload; the reminder applies while it is off. Layout previews never cancel effects or play alerts.",14,38,half-28,74)
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ultoverload",function(page,ui) ULT:BuildOverloadSettingsPage(page,ui) end)
end
