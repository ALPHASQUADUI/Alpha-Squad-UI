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
    page.contentHeight=710
    local title=ui.CreateLabel(page,"AlphaSquadSupportPageTitle","ZoFontWinH2","SUPPORT COVERAGE",C.orange)
    title:SetAnchor(TOPLEFT,page,TOPLEFT,8,2); title:SetDimensions(648,36)
    local sub=ui.CreateLabel(page,"AlphaSquadSupportPageSub","ZoFontGameSmall","Check group support, inspect builds and see who needs food before you start.",C.muted)
    sub:SetAnchor(TOPLEFT,page,TOPLEFT,8,38); sub:SetDimensions(650,26)
    local overview=ui.CreateCard(page,"AlphaSquadSupportOverview",8,76,658,130,"GROUP PREPARATION",C.orange)
    local status=ui.CreateLabel(overview,"AlphaSquadSupportOverviewStatus","ZoFontGameBold","",C.white)
    status:SetAnchor(TOPLEFT,overview,TOPLEFT,14,34); status:SetDimensions(630,38)
    ui.CreateButton(overview,"AlphaSquadSupportSettingsCoverage","COVERAGE",14,82,190,32,function() SC:OpenMatrix() end)
    ui.CreateButton(overview,"AlphaSquadSupportSettingsBuilds","BUILDS",216,82,190,32,function() SC:OpenInspector("BUILD") end)
    ui.CreateButton(overview,"AlphaSquadSupportSettingsFood","FOOD CHECK",418,82,220,32,function() SC:OpenFoodCheck() end)
    local module=ui.CreateCard(page,"AlphaSquadSupportModule",8,218,322,354,"MODULE & SHARING",C.orange)
    local function Toggle(id,label,y,get,set,help) return ui.AddToggleRow(module,"AlphaSquadSupport"..id,label,y,get,set,help) end
    Toggle("Enabled","Enable module",40,function() return SC.sv.enabled end,function(v) SC:SetEnabled(v) end,
        "Turn group preparation on or off. Coverage, food checks and shared builds are available before combat.")
    Toggle("Visible","Show preparation HUD",78,function() return SC.sv.visible end,function(v) SC:SetVisible(v) end,
        "Show the compact group checklist on your screen. You can still open Coverage, Builds and Food Check from settings when the HUD is hidden.")
    Toggle("Problems","Show issues only",116,function() return SC.sv.problemsOnly end,function(v) SC.sv.problemsOnly=v; SC:RefreshHUD() end,
        "Keep the HUD focused on missing support, duplicate sources and checks that need attention. The full Coverage window remains available.")
    Toggle("Share","Share my build",154,function() return SC.sv.shareData end,function(v) SC:SetShareData(v) end,
        "Allow compatible group members to receive your equipment, skill bars, Champion slottables and other supported build details. Enable build exchange must also be on. Sharing stops when you leave the group.")
    Toggle("FoodRequired","Check food",192,function() return SC.sv.checkFoodPresence end,function(v) SC.sv.checkFoodPresence=v; SC:Refresh("food setting") end,
        "Include food and drink in the preparation check. Unknown means the current data cannot confirm whether that player has food; it does not mean food is missing.")
    Toggle("GlyphRequired","Check armor glyphs",230,function() return SC.sv.checkMissingGlyphs end,function(v) SC.sv.checkMissingGlyphs=v; SC:Refresh("glyph setting") end,
        "Flag known missing armor enchantments. Open Builds and hover an item to inspect its exact enchantment and trait. Unavailable equipment data remains Unknown.")
    Toggle("HideMenus","Hide HUD in menus",268,function() return SC.sv.hideInMenus end,function(v) SC.sv.hideInMenus=v; SC:ApplyVisibility() end,
        "Hide the preparation HUD while inventory, Champion Points and other ESO menus are open.")
    Toggle("Experimental","Enable build exchange",306,function() return SC.sv.experimentalSharing end,function(v) SC:SetExperimentalSharing(v); SC:RefreshSettings() end,
        "Enable compatible build exchange through LibGroupBroadcast. Transport IDs are not yet reserved; keep this off outside coordinated groups. Both clients need compatible software. Share my build separately controls your outgoing data.")
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
    local dependencies=ui.CreateCard(page,"AlphaSquadSupportLibraryCard",8,584,658,110,"LIBRARIES & DATA ACCESS",C.gold)
    local help=ui.CreateLabel(dependencies,"AlphaSquadSupportLibraryHelp","ZoFontGameSmall","",C.muted)
    help:SetAnchor(TOPLEFT,dependencies,TOPLEFT,14,32); help:SetDimensions(432,62)
    ui.CreateButton(dependencies,"AlphaSquadSupportLibraries","LIBRARIES",464,48,178,32,function()
        AlphaSquadUI.Settings.OpenPage("libraries")
    end)
    ui.RegisterRefresher(function()
        local coverage=SC.coverage or {}
        status:SetText(string.format("%d / %d covered  •  %d missing  •  %d players with limited data",coverage.coveredCount or 0,coverage.requiredCount or 0,coverage.missingCount or 0,coverage.limitedPlayers or 0))
        UI.Color(status,coverage.ready and C.green or C.gold)
        help:SetText("Other players choose what to share. Install compatible libraries for group data, or the Build Share companion for full supported builds. Open Libraries for setup.")
    end)
end

function SC:CloseMatrix()
    if self.matrixWindow then self.matrixWindow:SetHidden(true) end
    UI.ClearTooltip()
    if AlphaSquadUI.Settings.RefreshModuleVisibility then AlphaSquadUI.Settings.RefreshModuleVisibility() else self:ApplyVisibility() end
end
function SC:OpenMatrix()
    if self.inCombat then return false end
    if not self.matrixWindow then self:CreateMatrixWindow() end
    UI.ShowWindow("supportCoverage",self.matrixWindow)
    self:RefreshMatrix(); return true
end
function SC:CreateMatrixWindow()
    local win=UI.Window("AlphaSquadSupportCoverageMatrix","Ąlpha Şquad UI  •  Coverage",function() SC:CloseMatrix() end)
    self.matrixWindow=win; UI.RegisterWindow("supportCoverage",win,function() SC:CloseMatrix() end)
    local trial=UI.Button(win,"AlphaSquadSupportTrial","TRIAL",105,30,function() SC:SetActiveProfile("trial") end)
    trial:SetAnchor(TOPLEFT,win,TOPLEFT,18,96); win.trial=trial
    local dungeon=UI.Button(win,"AlphaSquadSupportDungeon","DUNGEON",105,30,function() SC:SetActiveProfile("dungeon") end)
    dungeon:SetAnchor(TOPLEFT,win,TOPLEFT,131,96); win.dungeon=dungeon
    win.filterButtons={}
    for index,filter in ipairs({"ALL","MISSING","DUPLICATES"}) do
        local key=filter
        local b=UI.Button(win,"AlphaSquadSupportFilter"..key,key,index==3 and 124 or 95,30,function()
            SC.matrixFilter=key; SC:RefreshMatrix()
        end)
        b:SetAnchor(TOPLEFT,win,TOPLEFT,254+(index-1)*103,96); win.filterButtons[key]=b
    end
    win.builds=UI.Button(win,"AlphaSquadMatrixBuilds","BUILDS",106,30,function() SC:OpenInspector("BUILD") end)
    win.builds:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,138)
    win.food=UI.Button(win,"AlphaSquadMatrixFood","FOOD CHECK",116,30,function() SC:OpenFoodCheck() end)
    win.food:SetAnchor(TOPRIGHT,win.builds,TOPLEFT,-8,0)
    win.legend=UI.Label(win,"AlphaSquadSupportMatrixLegend","Choose what matters. Hover (i) for sources or a player for their build.","ZoFontGameSmall",C.muted)
    win.legend:SetAnchor(TOPLEFT,win,TOPLEFT,18,137); win.legend:SetHeight(30)
    win.list=UI.Scroll(win,"AlphaSquadSupportCoverageList")
    win.list:SetAnchor(TOPLEFT,win,TOPLEFT,18,178); win.list:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-14,-62)
    win.footer:SetText("COVERED means a qualifying build source is available. Trigger, range, target limits and group data still matter. Unknown data never proves an effect is missing.")
end
function SC:RefreshMatrix()
    local win=self.matrixWindow
    if not win or win:IsHidden() then return end
    local width=UI.FitWindow(win); local contentWidth=width-66
    local coverage=self.coverage or {}
    win.subtitle:SetText(string.format("%s  •  %d / %d covered  •  %d missing  •  %d players with limited data",coverage.profileLabel or "Group preparation",coverage.coveredCount or 0,coverage.requiredCount or 0,coverage.missingCount or 0,coverage.limitedPlayers or 0))
    win.legend:SetWidth(math.max(180,width-300))
    UI.Color(win.trial.label,self.sv.activeProfile=="trial" and C.orange or C.muted)
    UI.Color(win.dungeon.label,self.sv.activeProfile=="dungeon" and C.orange or C.muted)
    for key,b in pairs(win.filterButtons) do UI.Color(b.label,(self.matrixFilter or "ALL")==key and C.orange or C.muted) end
    local byKey={}; for _,row in ipairs(coverage.entries or {}) do byKey[row.key]=row end
    local selected={}; for _,key in ipairs(Catalog:GetRequirements(self.sv.activeProfile,self.sv)) do selected[key]=true end
    local keys=Catalog:GetAllEffectKeys(); local offset,count=0,0
    for _,key in ipairs(keys) do
        local effect=Catalog.effects[key]
        local tracked=selected[key]==true
        local data=byKey[key]
        if not data then
            local owners=self:GetCapabilityOwners(key)
            data={key=key,effect=effect,owners=owners,status=#owners>0 and "covered" or "missing",unverified=(coverage.limitedPlayers or 0)>0,duplicatePlayers={}}
        end
        local filter=self.matrixFilter or "ALL"
        local show=filter=="ALL" or (filter=="MISSING" and tracked and data.status~="covered") or (filter=="DUPLICATES" and tracked and #(data.duplicatePlayers or {})>1)
        if show then
            count=count+1; local row=win.list.rows[count]
            if not row then
                local name="AlphaSquadSupportCoverageEntry"..count
                row=WINDOW_MANAGER:CreateControl(name,win.list.content,CT_CONTROL)
                row.bg=UI.Solid(row,name.."BG",C.panel)
                row.name=UI.Label(row,name.."Name","","ZoFontGameBold")
                row.name:SetAnchor(TOPLEFT,row,TOPLEFT,12,5); row.name:SetHeight(26)
                row.info=UI.Button(row,name.."Info","i",26,24,function() if row.data then UI.Tooltip(row.info,Catalog:GetEffectTooltip(row.data.key)) end end)
                UI.Hover(row.info,function() return row.data and Catalog:GetEffectTooltip(row.data.key) end)
                row.toggle=UI.Button(row,name.."Toggle","",58,26,function()
                    if row.data then SC:SetEffectTracking(row.data.key,not SC:IsEffectTracked(row.data.key)); SC:RefreshMatrix() end
                end)
                row.toggle:SetAnchor(TOPRIGHT,row,TOPRIGHT,-8,5)
                row.status=UI.Label(row,name.."Status","","ZoFontGameBold")
                row.status:SetAnchor(TOPRIGHT,row.toggle,TOPLEFT,-12,0); row.status:SetDimensions(126,26); row.status:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
                row.reason=UI.Label(row,name.."Reason","","ZoFontGameSmall",C.muted)
                row.reason:SetAnchor(TOPLEFT,row,TOPLEFT,12,34); row.reason:SetHeight(24)
                row.owners={}; win.list.rows[count]=row
            end
            row.data=data; row:SetHidden(false)
            row.name:SetWidth(math.max(100,contentWidth-265)); row.name:SetText(UI.Text(effect.label))
            row.info:ClearAnchors(); row.info:SetAnchor(TOPLEFT,row,TOPLEFT,contentWidth-251,6)
            row.toggle.label:SetText(tracked and "ON" or "OFF"); UI.Color(row.toggle.label,tracked and C.green or C.muted)
            local status,color=UI.Status(data)
            if not tracked then status="OPTIONAL"; color=C.muted elseif #(data.duplicatePlayers or {})>1 then status="DUPLICATE"; color=C.gold end
            row.status:SetText(status); UI.Color(row.status,color); UI.Color(row.name,tracked and C.white or C.muted)
            row.reason:SetWidth(contentWidth-24)
            if #data.owners>0 then
                row.reason:SetText(#(data.duplicatePlayers or {})>1 and (tostring(#data.owners).." source carriers • review duplicate conditions") or "Source carrier • hover for skills, sets and conditions")
            else row.reason:SetText(data.unverified and "Source information unavailable from one or more players." or "No qualifying source found in the available build data.") end
            for ownerIndex,player in ipairs(data.owners) do
                local control=row.owners[ownerIndex]
                if not control then
                    control=UI.Button(row,"AlphaSquadSupportCoverageEntry"..count.."Owner"..ownerIndex,"",200,26,function(button)
                        SC.inspectorPlayerKey=button.player.key or button.player.displayName; SC:OpenInspector("BUILD")
                    end)
                    UI.Hover(control,function() return control.player and row.data and UI.PlayerSources(control.player,row.data.key) end)
                    row.owners[ownerIndex]=control
                end
                control.player=player; control:SetHidden(false); control:ClearAnchors()
                control:SetWidth((contentWidth-32)/2); control:SetAnchor(TOPLEFT,row,TOPLEFT,12+((ownerIndex-1)%2)*((contentWidth-32)/2+8),64+math.floor((ownerIndex-1)/2)*30)
                control.label:SetText(UI.Text(player.displayName or "Unknown player")); UI.Color(control.label,#(data.duplicatePlayers or {})>1 and C.gold or C.green)
            end
            for n=#data.owners+1,#row.owners do row.owners[n]:SetHidden(true); row.owners[n].player=nil end
            local height=math.max(68,68+math.ceil(#data.owners/2)*30)
            row:ClearAnchors(); row:SetAnchor(TOPLEFT,win.list.content,TOPLEFT,0,offset); row:SetDimensions(contentWidth,height)
            offset=offset+height+7
        end
    end
    for n=count+1,#win.list.rows do win.list.rows[n]:SetHidden(true); win.list.rows[n].data=nil end
    UI.FinishScroll(win.list,offset,contentWidth)
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("supportcoverage",function(page,ui) SC:BuildIntegratedSettingsPage(page,ui) end)
end
