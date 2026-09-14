-- Preparation settings and pooled, scrollable coverage lists.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,Catalog=SC.UI,SC.Catalog
local C=UI.colors

function SC:RefreshSettings()
    local settings=AlphaSquadUI.Settings
    if settings and settings.RefreshMain then settings.RefreshMain() end
    self:RefreshMatrix(); self:RefreshInspector()
end
function SC:BuildIntegratedSettingsPage(page,ui)
    if not page or not ui or not self.sv then return end
    page.contentHeight=630
    local title=ui.CreateLabel(page,"AlphaSquadSupportPageTitle","ZoFontWinH2","SUPPORT COVERAGE",C.orange)
    title:SetAnchor(TOPLEFT,page,TOPLEFT,8,2); title:SetDimensions(648,36)
    local sub=ui.CreateLabel(page,"AlphaSquadSupportPageSub","ZoFontGameSmall","Check group support, inspect builds and see who needs food before you start.",C.muted)
    sub:SetAnchor(TOPLEFT,page,TOPLEFT,8,38); sub:SetDimensions(650,26)
    local overview=ui.CreateCard(page,"AlphaSquadSupportOverview",8,76,658,130,"GROUP PREPARATION",C.orange)
    local status=ui.CreateLabel(overview,"AlphaSquadSupportOverviewStatus","ZoFontGameBold","",C.white)
    status:SetAnchor(TOPLEFT,overview,TOPLEFT,14,34); status:SetDimensions(630,38)
    ui.CreateButton(overview,"AlphaSquadSupportSettingsCoverage","COVERAGE",14,82,190,32,function() SC:OpenMatrix() end)
    ui.CreateButton(overview,"AlphaSquadSupportSettingsBuilds","BUILDS",216,82,190,32,function() SC:OpenInspector("BUILD") end)
    local module=ui.CreateCard(page,"AlphaSquadSupportModule",8,218,322,354,"PREPARATION",C.orange)
    local function Toggle(id,label,y,get,set,help) return ui.AddToggleRow(module,"AlphaSquadSupport"..id,label,y,get,set,help) end
    Toggle("Visible","Show preparation HUD",40,function() return SC.sv.visible end,function(v) SC:SetVisible(v) end,
        "Show the compact group checklist on your screen. You can still open Coverage and Builds from settings when the HUD is hidden.")
    Toggle("Problems","Show issues only",80,function() return SC.sv.problemsOnly end,function(v) SC.sv.problemsOnly=v; SC:RefreshHUD() end,
        "Keep the HUD focused on missing support, duplicate sources and checks that need attention. The full Coverage window remains available.")
    Toggle("FoodRequired","Check food",120,function() return SC.sv.checkFoodPresence end,function(v) SC.sv.checkFoodPresence=v; SC:Refresh("food setting") end,
        "Include food and drink in the preparation check. Unknown means the current data cannot confirm whether that player has food; it does not mean food is missing.")
    Toggle("GlyphRequired","Check armor glyphs",160,function() return SC.sv.checkMissingGlyphs end,function(v) SC.sv.checkMissingGlyphs=v; SC:Refresh("glyph setting") end,
        "Flag known missing armor enchantments. Open Builds and hover an item to inspect its exact enchantment and trait. Unavailable equipment data remains Unknown.")
    Toggle("HideMenus","Hide HUD in menus",200,function() return SC.sv.hideInMenus end,function(v) SC.sv.hideInMenus=v; SC:ApplyVisibility() end,
        "Hide the preparation HUD while inventory, Champion Points and other ESO menus are open.")
    local appearance=ui.CreateCard(page,"AlphaSquadSupportAppearance",344,218,322,354,"HUD APPEARANCE",C.gold)
    ui.AddToggleRow(appearance,"AlphaSquadSupportLock","Lock position",40,function() return SC.sv.locked end,function(v) SC.sv.locked=v; SC:UpdateLockState() end)
    local function Step(id,label,y,key,step,min,max,suffix)
        ui.AddStepperRow(appearance,"AlphaSquadSupport"..id,label,y,function() return SC.sv[key] end,function(v)
            SC.sv[key]=v; SC:ApplyAppearance(); SC:RefreshHUD(); SC:ClampToScreen(true)
        end,step,min,max,suffix,C.gold)
    end
    Step("Scale","Scale",80,"scale",5,60,180,"%")
    Step("Width","Width",120,"width",10,300,680,"")
    Step("RowHeight","Row height",160,"rowHeight",2,24,48,"")
    Step("Opacity","Background",200,"opacity",5,30,100,"%")
    ui.CreateButton(appearance,"AlphaSquadSupportResetPosition","RESET POSITION",14,256,140,32,function() SC:ResetPosition() end)
    ui.CreateButton(appearance,"AlphaSquadSupportMove","UNLOCK & MOVE",164,256,144,32,function()
        SC:SetEnabled(true); SC:SetVisible(true); SC.sv.locked=false; SC:UpdateLockState()
        AlphaSquadUI.Settings.CloseMain()
    end)
    local saved=ui.CreateLabel(appearance,"AlphaSquadSupportSaved","ZoFontGameSmall","Changes are saved automatically.",C.muted)
    saved:SetAnchor(TOPLEFT,appearance,TOPLEFT,14,304); saved:SetDimensions(292,28)
    ui.RegisterRefresher(function()
        local coverage=SC.coverage or {}
        status:SetText(string.format("%d / %d covered  •  %d missing  •  %d players with limited data",coverage.coveredCount or 0,coverage.requiredCount or 0,coverage.missingCount or 0,coverage.limitedPlayers or 0))
        UI.Color(status,coverage.ready and C.green or C.gold)
    end)
end

function SC:CloseMatrix()
    if self.matrixWindow then self.matrixWindow:SetHidden(true) end
    UI.ClearTooltip()
    if AlphaSquadUI.Settings.RefreshModuleVisibility then AlphaSquadUI.Settings.RefreshModuleVisibility() else self:ApplyVisibility() end
end
function SC:OpenMatrix()
    if self.loading or self.inCombat then return false end
    if not self.matrixWindow then self:CreateMatrixWindow() end
    UI.ShowWindow("supportCoverage",self.matrixWindow)
    self:RefreshMatrix(); return true
end
function SC:CreateMatrixWindow()
    local win=UI.Window("AlphaSquadSupportCoverageMatrix","Ąlpha Şquad UI  •  Coverage",function() SC:CloseMatrix() end)
    self.matrixWindow=win;UI.RegisterWindow("supportCoverage",win,function() SC:CloseMatrix() end)
    win.trial=UI.Button(win,"AlphaSquadSupportTrial","TRIAL",90,30,function() SC:SetActiveProfile("trial") end)
    win.trial:SetAnchor(TOPLEFT,win,TOPLEFT,18,94)
    win.dungeon=UI.Button(win,"AlphaSquadSupportDungeon","DUNGEON",104,30,function() SC:SetActiveProfile("dungeon") end)
    win.dungeon:SetAnchor(TOPLEFT,win,TOPLEFT,116,94)
    win.filterButtons={}
    for index,filter in ipairs({"ALL","MISSING","DUPLICATES"}) do
        local key=filter
        local b=UI.Button(win,"AlphaSquadSupportFilter"..key,key,116,30,function() SC.matrixFilter=key;SC:RefreshMatrix() end)
        b:SetAnchor(TOPLEFT,win,TOPLEFT,246+(index-1)*124,94);win.filterButtons[key]=b
    end
    win.builds=UI.Button(win,"AlphaSquadMatrixBuilds","BUILDS",106,30,function() SC:OpenInspector("BUILD") end)
    win.builds:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,94)
    win.columns={}
    for index,label in ipairs({"BUFFS","DEBUFFS","GROUP SETS","GROUP MYTHICS"}) do
        win.columns[index]=UI.Label(win,"AlphaSquadCoverageColumn"..index,label,"ZoFontGameBold",C.orange)
    end
    win.list=UI.Scroll(win,"AlphaSquadSupportCoverageList")
    win.list:SetAnchor(TOPLEFT,win,TOPLEFT,18,166);win.list:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-14,-58)
    win.footer:SetText("Hover an effect for sources and conditions. Hover a player for their contribution; click to inspect. Coverage checks build availability, not active effects.")
end
local categoryIndex={buffs=1,debuffs=2,sets=3,mythics=4}
function SC:RefreshMatrix()
    local win=self.matrixWindow;if not win or win:IsHidden() then return end
    win:SetDimensions(1350,720);win:SetScale(math.max(0.1,math.min(1,(GuiRoot:GetWidth()-24)/1350,(GuiRoot:GetHeight()-24)/720)))
    local contentWidth=1284;local columnWidth=(contentWidth-30)/4
    local coverage=self.coverage or {}
    win.subtitle:SetText(string.format("%s  •  %d / %d covered  •  %d missing  •  %d players with limited data",coverage.profileLabel or "Group preparation",coverage.coveredCount or 0,coverage.requiredCount or 0,coverage.missingCount or 0,coverage.limitedPlayers or 0))
    UI.Color(win.trial.label,self.sv.activeProfile=="trial" and C.orange or C.muted)
    UI.Color(win.dungeon.label,self.sv.activeProfile=="dungeon" and C.orange or C.muted)
    for key,b in pairs(win.filterButtons) do UI.Color(b.label,(self.matrixFilter or "ALL")==key and C.orange or C.muted) end
    for index,label in ipairs(win.columns) do label:ClearAnchors();label:SetAnchor(TOPLEFT,win,TOPLEFT,18+(index-1)*(columnWidth+10),136);label:SetDimensions(columnWidth,24) end
    local byKey={};for _,row in ipairs(coverage.entries or {}) do byKey[row.key]=row end
    local selected={};for _,key in ipairs(Catalog:GetRequirements(self.sv.activeProfile,self.sv)) do selected[key]=true end
    local offsets={0,0,0,0};local count=0
    for _,key in ipairs(Catalog:GetAllEffectKeys()) do
        local effect=Catalog.effects[key];local tracked=selected[key]==true;local data=byKey[key]
        if not data then
            local owners=self:GetCapabilityOwners(key)
            data={key=key,effect=effect,owners=owners,status=#owners>0 and "covered" or "missing",unverified=(coverage.limitedPlayers or 0)>0,duplicatePlayers={}}
        end
        local filter=self.matrixFilter or "ALL"
        local duplicate=#(data.duplicatePlayers or {})>1
        if filter=="ALL" or (filter=="MISSING" and tracked and data.status~="covered") or (filter=="DUPLICATES" and tracked and duplicate) then
            count=count+1;local row=win.list.rows[count]
            if not row then
                local name="AlphaSquadSupportCoverageEntry"..count
                row=WINDOW_MANAGER:CreateControl(name,win.list.content,CT_CONTROL)
                row.bg=UI.Solid(row,name.."BG",C.panel)
                row.icon=WINDOW_MANAGER:CreateControl(name.."Icon",row,CT_TEXTURE)
                row.icon:SetAnchor(TOPLEFT,row,TOPLEFT,9,10);row.icon:SetDimensions(30,30)
                row.name=UI.Label(row,name.."Name","","ZoFontGameBold")
                row.name:SetAnchor(TOPLEFT,row,TOPLEFT,47,6);row.name:SetDimensions(columnWidth-59,43)
                UI.Hover(row.name,function() return row.data and Catalog:GetEffectTooltip(row.data.key) end)
                row.toggle=UI.Button(row,name.."Toggle","",46,24,function()
                    if row.data then SC:SetEffectTracking(row.data.key,not SC:IsEffectTracked(row.data.key));SC:RefreshMatrix() end
                end)
                row.toggle:SetAnchor(TOPRIGHT,row,TOPRIGHT,-9,51)
                row.status=UI.Label(row,name.."Status","","ZoFontGameSmall")
                row.status:SetAnchor(TOPLEFT,row,TOPLEFT,10,51);row.status:SetDimensions(columnWidth-72,24)
                UI.Hover(row.status,function() return row.data and Catalog:GetEffectTooltip(row.data.key) end)
                UI.Hover(row.icon,function() return row.data and Catalog:GetEffectTooltip(row.data.key) end)
                row.owners={};win.list.rows[count]=row
            end
            row.data=data;row:SetHidden(false)
            local visual=Catalog:GetEffectVisual(key)
            row.icon:SetTexture(visual and visual.icon or "");row.icon:SetHidden(not visual or not visual.icon or visual.icon=="")
            -- Sets open the native reference tooltip; source/trigger help stays on the title.
            if visual and visual.reference then
                row.icon:SetHandler("OnMouseEnter",function() UI.ItemTooltip(row.icon,visual,true) end)
            else row.icon:SetHandler("OnMouseEnter",function() UI.Tooltip(row.icon,Catalog:GetEffectTooltip(row.data.key)) end) end
            row.name:SetText(UI.Text(effect.label));UI.Color(row.name,tracked and C.white or C.muted)
            row.toggle.label:SetText(tracked and "ON" or "OFF");UI.Color(row.toggle.label,tracked and C.green or C.muted)
            local status,color=UI.Status(data)
            if not tracked then status="OPTIONAL";color=C.muted elseif duplicate then status="DUPLICATE";color=C.gold end
            row.status:SetText(status);UI.Color(row.status,color)
            for index,player in ipairs(data.owners) do
                local control=row.owners[index]
                if not control then
                    control=UI.Button(row,"AlphaSquadSupportCoverageEntry"..count.."Owner"..index,"",142,23,function(button)
                        SC.inspectorPlayerKey=button.player.key or button.player.displayName;SC:OpenInspector("BUILD")
                    end)
                    control.label:SetFont("ZoFontGameSmall")
                    if control.label.SetWrapMode then control.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
                    UI.Hover(control,function() return control.player and row.data and UI.PlayerSources(control.player,row.data.key) end)
                    row.owners[index]=control
                end
                control.player=player;control:SetHidden(false);control:ClearAnchors()
                local ownerWidth=(columnWidth-26)/2
                control:SetWidth(ownerWidth);control:SetAnchor(TOPLEFT,row,TOPLEFT,9+((index-1)%2)*(ownerWidth+8),81+math.floor((index-1)/2)*25)
                control.label:SetText(AlphaSquadUI.Theme.PlayerName and AlphaSquadUI.Theme.PlayerName(player.displayName) or UI.Text(player.displayName));UI.Color(control.label,duplicate and C.gold or C.green)
            end
            for index=#data.owners+1,#row.owners do row.owners[index]:SetHidden(true);row.owners[index].player=nil end
            local column=categoryIndex[Catalog:GetDisplayCategory(key)] or 1
            local height=81+math.ceil(#data.owners/2)*25
            row:ClearAnchors();row:SetAnchor(TOPLEFT,win.list.content,TOPLEFT,(column-1)*(columnWidth+10),offsets[column]);row:SetDimensions(columnWidth,height)
            offsets[column]=offsets[column]+height+8
        end
    end
    for index=count+1,#win.list.rows do win.list.rows[index]:SetHidden(true);win.list.rows[index].data=nil end
    UI.FinishScroll(win.list,math.max(offsets[1],offsets[2],offsets[3],offsets[4]),contentWidth)
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("supportcoverage",function(page,ui) SC:BuildIntegratedSettingsPage(page,ui) end)
end
