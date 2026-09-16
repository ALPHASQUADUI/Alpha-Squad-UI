-- Ąlpha Şquad UI - ULT Tracker Settings
-- Normal runtime uses the shared Settings > Ąlpha Şquad shell.

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

local function L(text,...)
    if AlphaSquadUI.L then return AlphaSquadUI.L(text,...) end
    return select("#",...)>0 and string.format(text,...) or text
end
local function MovePersonalHUD()
    local layout=AlphaSquadUI.Layout
    if layout and layout.Start then layout.Start(ULT) end
end

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

local function LogicalWidth(control)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.GetLogicalWidth then return AlphaSquadUI.Utils.GetLogicalWidth(control) end
    return control:GetWidth()/math.max(0.001,control.GetScale and control:GetScale() or 1)
end

local function Place(control,parent,x,y,width,height)
    control:ClearAnchors();control:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y)
    control:SetDimensions(width,height)
end

local function PageLabels(page,ui,C)
    local labels={}
    local function Label(parent,name,text,x,y,w,h,font,color)
        local label=ui.CreateLabel(parent,name,font or "ZoFontGameSmall",text,color or C.muted)
        label:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);label:SetDimensions(w,h)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT);label:SetVerticalAlignment(TEXT_ALIGN_TOP)
        labels[#labels+1]={control=label,parent=parent,left=x,right=LogicalWidth(parent)-x-w}
        return label
    end
    local function Reflow()
        for _,entry in ipairs(labels) do
            entry.control:SetWidth(math.max(1,LogicalWidth(entry.parent)-entry.left-entry.right))
        end
    end
    return Label,Reflow
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
    local width=LogicalWidth(page)-16;local half=(width-16)/2
    local Label,ReflowLabels=PageLabels(page,ui,C)
    Label(page,"AlphaSquadULTIntegratedTitle","ULT TRACKER",8,2,width,34,"ZoFontWinH2",C.orange)
    Label(page,"AlphaSquadULTIntegratedSub","Current points, native cost and progress. The green arrow marks your active bar.",8,42,width,40)
    local general=ui.CreateCard(page,"AlphaSquadULTIntegratedGeneral",8,86,half,216,"PERSONAL HUD",C.orange)
    ui.AddToggleRow(general,"AlphaSquadULTIntegratedVisible","Show personal HUD",42,
        function() return ULT.sv and ULT.sv.visible==true end,function(v) ULT:SetVisible(v) end,
        "Shows your Ultimate points without changing the game action bar or other addons.")
    ui.AddToggleRow(general,"AlphaSquadULTIntegratedMenus","Hide in game menus",82,
        function() return ULT.sv and ULT.sv.hideInMenus==true end,function(v) ULT.sv.hideInMenus=v==true;ULT:ApplyVisibility() end)
    ui.CreateButton(general,"AlphaSquadULTMoveHUD","MOVE HUD",14,134,190,36,MovePersonalHUD)
    local tracking=ui.CreateCard(page,"AlphaSquadULTIntegratedTracking",half+24,86,half,216,"BARS & READINESS",C.cyan)
    ui.AddToggleRow(tracking,"AlphaSquadULTIntegratedSound","Ready sounds",44,
        function() return ULT.sv and ULT.sv.readySound==true end,function(v) ULT.sv.readySound=v==true end)
    ui.AddToggleRow(tracking,"AlphaSquadULTIntegratedFlash","Ready highlight",86,
        function() return ULT.sv and ULT.sv.readyFlash==true end,function(v) ULT.sv.readyFlash=v==true;ULT:Refresh("ready highlight") end)
    Label(tracking,"AlphaSquadULTBothBarsHelp","One shared Ultimate pool. Each bar keeps its own cost.",14,132,half-28,50)
    local overload=ui.CreateCard(page,"AlphaSquadULTIntegratedOverload",8,318,half,112,"OVERLOAD",C.gold)
    Label(overload,"AlphaSquadULTOverloadIntro","Reserve warnings and the ready reminder.",14,38,half-220,60)
    local overloadButton=ui.CreateButton(overload,"AlphaSquadULTOverloadSettings","SETTINGS",half-194,42,180,38,function() AlphaSquadUI.Settings.OpenPage("ultoverload") end)
    local runtime=ui.CreateCard(page,"AlphaSquadULTIntegratedRuntime",half+24,318,half,244,"CURRENT ULTIMATES",C.green)
    local nativeRows={}
    for index,key in ipairs({"primary","backup"}) do
        local rowY=40+(index-1)*74
        local icon=WINDOW_MANAGER:CreateControl("AlphaSquadULTSettingsIcon"..key,runtime,CT_TEXTURE)
        icon:SetAnchor(TOPLEFT,runtime,TOPLEFT,14,rowY);icon:SetDimensions(44,44);icon:SetMouseEnabled(true)
        icon:SetHandler("OnMouseEnter",function()
            local bar=ULT:GetLiveBar(key)
            if bar and bar.abilityId>0 and AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.ShowSkill(icon,{id=bar.abilityId,name=bar.name},false) end
        end)
        icon:SetHandler("OnMouseExit",function() if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end end)
        local text=Label(runtime,"AlphaSquadULTSettingsNative"..key,"",70,rowY,half-84,62)
        if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(icon,{kind="inspect",label="Current Ultimate"}) end
        nativeRows[key]={icon=icon,text=text}
    end
    local counter=Label(runtime,"AlphaSquadULTIntegratedCurrent","",14,192,half-28,28,"ZoFontGameBold",C.gold)
    ui.RegisterRefresher(function()
        for key,row in pairs(nativeRows) do
            local bar=ULT:GetLiveBar(key);local label=bar and bar.label=="ACTIVE BAR" and "ACTIVE BAR" or (key=="primary" and "FRONT BAR" or "BACK BAR")
            local unavailable=key=="backup" and ULT:HasSpecialActiveBar()
            local state=bar and bar.state or "empty"
            if state=="off" then state="inactive" end
            row.icon:SetHidden(unavailable or not bar or bar.abilityId<=0 or bar.icon=="")
            if bar and bar.icon~="" then row.icon:SetTexture(bar.icon) end
            local name=bar and bar.name~="" and bar.name or L("No Ultimate")
            local localization=AlphaSquadUI.Localization
            if bar and localization and localization.GetNativeName then name=localization.GetNativeName("ability",bar.abilityId,name) end
            row.text:SetText(unavailable and L("BACK BAR\nUnavailable on the current action bar") or (L(label).." • "..name.."\n"..L(string.upper(state))))
        end
        counter:SetText(L("ULTIMATE: %d",tonumber(ULT.currentUltimate) or 0))
    end)
    local group=ui.CreateCard(page,"AlphaSquadULTIntegratedGroup",8,446,half,116,"GROUP ULTIMATES",C.cyan)
    local groupStatus=Label(group,"AlphaSquadULTIntegratedGroupStatus","",180,78,half-194,28)
    ui.AddToggleRow(group,"AlphaSquadULTIntegratedGroupEnabled","Group tracking",36,
        function() return ULT.Group and ULT.Group.sv and ULT.Group.sv.enabled==true end,
        function(value) if ULT.Group then ULT.Group:SetEnabled(value) end end)

    ui.CreateButton(group,"AlphaSquadULTIntegratedGroupConfig","CONFIGURE",14,78,150,28,function() if ULT.Group then ULT.Group:OpenConfig() end end)
    ui.RegisterRefresher(function()
        local tracker=ULT.Group
        if not tracker or not tracker.sv then groupStatus:SetText(L("Group Ultimate tracking"));return end
        local shared,count=tracker:GetSharingCount()
        if not tracker.libraryAvailable then groupStatus:SetText(L("See Libraries for group data."));SetColor(groupStatus,C.red)
        else groupStatus:SetText(L("%d / %d sharing",shared,count));SetColor(groupStatus,C.muted) end
    end)
    if ui.RegisterLayout then
        ui.RegisterLayout(page,function(pageWidth)
            local inner=math.max(280,pageWidth-16)
            local twoColumns=pageWidth>=860
            local cardWidth=twoColumns and (inner-16)/2 or inner
            local right=24+cardWidth
            if twoColumns then
                Place(general,page,8,94,cardWidth,208)
                Place(tracking,page,right,94,cardWidth,208)
                Place(overload,page,8,318,cardWidth,112)
                Place(group,page,8,446,cardWidth,124)
                Place(runtime,page,right,318,cardWidth,252)
                page.contentHeight=582
            else
                Place(general,page,8,94,cardWidth,196)
                Place(tracking,page,8,306,cardWidth,202)
                Place(overload,page,8,524,cardWidth,112)
                Place(group,page,8,652,cardWidth,124)
                Place(runtime,page,8,792,cardWidth,236)
                page.contentHeight=1040
            end
            Place(overloadButton,overload,cardWidth-194,42,180,38)
            ReflowLabels()
        end)
    end
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ulttracker",function(page,ui) ULT:BuildIntegratedSettingsPage(page,ui) end)
end

function ULT:BuildOverloadSettingsPage(page,ui)
    local C=ui.colors or COLORS
    page.responsiveCards=true;page.contentHeight=590
    local width=LogicalWidth(page)-16;local half=(width-16)/2
    local Label,ReflowLabels=PageLabels(page,ui,C)
    Label(page,"AlphaSquadOverloadOptionsTitle","OVERLOAD",8,2,width-200,34,"ZoFontWinH2",C.orange)
    local back=ui.CreateButton(page,"AlphaSquadOverloadBack","ULT TRACKER",width-174,2,172,34,function() AlphaSquadUI.Settings.OpenPage("ulttracker") end)
    Label(page,"AlphaSquadOverloadOptionsIntro","Optional reserve warnings and reminders in your personal Ultimate HUD.",8,42,width,40)
    local behavior=ui.CreateCard(page,"AlphaSquadOverloadBehavior",8,94,half,172,"BEHAVIOR",C.orange)
    local function Toggle(parent,id,text,key,y,help)
        ui.AddToggleRow(parent,"AlphaSquadOverloadOption"..id,text,y,
            function() return ULT.sv and ULT.sv.overload and ULT.sv.overload[key]==true end,
            function(value) if ULT.Overload then ULT.Overload:SetOption(key,value) end end,help)
    end
    Toggle(behavior,"Enabled","Use Overload behavior","enabled",42,"Adds reserve warnings to slotted Overload. Both weapon bars stay visible. Group sharing is unchanged.")
    Toggle(behavior,"PvP","Disable in PvP","disableInPvP",82,"Use standard Ultimate tracking in PvP while retaining your Overload settings for PvE.")
    ui.CreateButton(behavior,"AlphaSquadOverloadMoveHUD","MOVE HUD",14,124,190,34,MovePersonalHUD)
    local reserve=ui.CreateCard(page,"AlphaSquadOverloadReserve",half+24,94,half,252,"ULTIMATE RESERVE",C.red)
    Toggle(reserve,"Reserve","Reserve warnings","reserveAlertsEnabled",42,"Warn while active Overload reaches the selected reserve. Use your Ultimate binding to switch it off.")
    Toggle(reserve,"ReserveSound","Warning sounds","reserveSound",82)
    local function Step(parent,id,text,key,y,minimum,help)
        ui.AddStepperRow(parent,"AlphaSquadOverloadOption"..id,text,y,
            function() return ULT.sv and ULT.sv.overload and ULT.sv.overload[key] or minimum end,
            function(value) if ULT.Overload then ULT.Overload:SetOption(key,value) end end,5,minimum,500,"",C.gold,help)
    end
    Step(reserve,"Warning","Warning starts","reserveWarningThreshold",126,25)
    Label(reserve,"AlphaSquadOverloadReserveNote","Press your Ultimate binding to stop Overload.",14,176,half-28,62)
    local ready=ui.CreateCard(page,"AlphaSquadOverloadReady",8,282,half,198,"READY REMINDER",C.gold)
    Toggle(ready,"Ready","Ready reminder","readyReminderEnabled",42)
    Toggle(ready,"ReadySound","Reminder sound","readyReminderSound",82)
    Step(ready,"ReadyThreshold","Ready at","readyReminderThreshold",126,100,
        "The reminder is a target, not the ability cost. The marker shows the reserve warning threshold.")
    local help=ui.CreateCard(page,"AlphaSquadOverloadHelp",half+24,362,half,118,"HOW IT WORKS",C.cyan)
    Label(help,"AlphaSquadOverloadHelpText","Gold: active. Green pulse: ready. Red pulse: stop. Use your Ultimate binding to switch Overload off.",14,38,half-28,74)
    if ui.RegisterLayout then
        ui.RegisterLayout(page,function(pageWidth)
            local inner=math.max(280,pageWidth-16)
            local twoColumns=pageWidth>=860
            local cardWidth=twoColumns and (inner-16)/2 or inner
            local right=24+cardWidth
            Place(back,page,inner-174,2,172,34)
            if twoColumns then
                Place(behavior,page,8,94,cardWidth,172)
                Place(reserve,page,right,94,cardWidth,244)
                Place(ready,page,8,282,cardWidth,210)
                Place(help,page,right,354,cardWidth,138)
                page.contentHeight=504
            else
                Place(behavior,page,8,94,cardWidth,172)
                Place(reserve,page,8,282,cardWidth,244)
                Place(ready,page,8,542,cardWidth,198)
                Place(help,page,8,756,cardWidth,138)
                page.contentHeight=906
            end
            ReflowLabels()
        end)
    end
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("ultoverload",function(page,ui) ULT:BuildOverloadSettingsPage(page,ui) end)
end
