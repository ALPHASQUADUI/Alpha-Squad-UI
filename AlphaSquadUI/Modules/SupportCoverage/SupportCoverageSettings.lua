-- Preparation settings and a pooled, single-page coverage grid.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,Catalog=SC.UI,SC.Catalog
local C=UI.colors
local function EffectTooltip(key)
    return UI.EffectTooltip and UI.EffectTooltip(key) or Catalog:GetEffectTooltip(key)
end

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
    local appearance=ui.CreateCard(page,"AlphaSquadSupportAppearance",344,218,322,354,"YOUR HUD",C.accent or C.gold)
    local help=ui.CreateLabel(appearance,"AlphaSquadSupportLayoutHelp","ZoFontGameSmall",
        "Arrange and resize every enabled panel in Move HUD. Drag an edge to change its space, or a corner to scale the whole panel.",C.muted)
    help:SetAnchor(TOPLEFT,appearance,TOPLEFT,14,42);help:SetDimensions(294,66)
    ui.CreateButton(appearance,"AlphaSquadSupportGlobalMove","MOVE HUD",14,122,190,32,function()
        if AlphaSquadUI.Layout and AlphaSquadUI.Layout.Start then AlphaSquadUI.Layout.Start() end
    end)
    local placement=ui.CreateLabel(appearance,"AlphaSquadSupportPlacementNote","ZoFontGameSmall",
        "Use Preview for sample ready, missing and optional sources. Done saves and locks your panels; previews never change group data.",C.muted)
    placement:SetAnchor(TOPLEFT,appearance,TOPLEFT,14,170);placement:SetDimensions(294,76)
    local native=ui.CreateLabel(appearance,"AlphaSquadSupportNativeNote","ZoFontGameSmall",
        "Equipment, skills and Champion stars use the game's own icons. Choose the suite design in Dashboard.",C.muted)
    native:SetAnchor(TOPLEFT,appearance,TOPLEFT,14,258);native:SetDimensions(294,70)
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
local categoryIndex={buffs=1,debuffs=2,sets=3,mythics=4}
local categoryNames={"BUFFS","DEBUFFS","GROUP SETS","GROUP MYTHICS"}
-- A single logical page: dense categories receive additional lanes, not a scrollbar.
function SC:GetCoverageGridLayout(counts)
    local width=math.max(1248,math.min(1600,GuiRoot:GetWidth()-24))
    local height=math.max(720,math.min(840,GuiRoot:GetHeight()-24))
    local layout={width=width,height=height,lanes={},rows={},starts={}}
    local lanes,maxRows=0,1
    for index=1,4 do
        layout.lanes[index]=math.max(1,math.ceil((counts[index] or 0)/30))
        layout.rows[index]=math.max(1,math.ceil((counts[index] or 0)/layout.lanes[index]))
        maxRows=math.max(maxRows,layout.rows[index]);lanes=lanes+layout.lanes[index]
    end
    layout.height=math.max(height,maxRows*18+198)
    layout.pitch=math.max(18,math.min(24,math.floor((layout.height-198)/maxRows)))
    layout.laneWidth=(width-36-18*3-5*(lanes-4))/lanes
    local x=0
    for index=1,4 do
        layout.starts[index]=x
        x=x+layout.lanes[index]*layout.laneWidth+(layout.lanes[index]-1)*5+18
    end
    return layout
end
local function ContributorTooltip(data)
    if not data then return "No group information is available." end
    local owners=data.owners or {}
    local lines={data.effect and data.effect.label or Catalog.effects[data.key].label}
    local status=UI.Status(data)
    lines[#lines+1]=status.." • "..#owners.." known contributor"..(#owners==1 and "" or "s")
    -- Every contributor remains visible on hover even when twelve players duplicate a source.
    for _,player in ipairs(owners) do
        local capability=player.capabilities and player.capabilities[data.key]
        local sources={}
        for name,active in pairs(capability and capability.sources or {}) do
            if active and type(name)=="string" and name~="Shared build" and name~="ASUI peer" then sources[#sources+1]=name end
        end
        table.sort(sources)
        local bars=capability and (capability.mainBar and capability.backBar and " • both bars" or capability.mainBar and " • front bar" or capability.backBar and " • back bar" or "") or ""
        lines[#lines+1]=tostring(player.displayName or "Unknown player")..bars.."\n"..(#sources>0 and table.concat(sources,", ") or "Detailed sources unavailable • inspect build")
    end
    if #owners==0 then lines[#lines+1]="No verified source in the current group. Unknown builds may contain a source." end
    if #owners>0 then lines[#lines+1]="Click to inspect "..tostring(owners[1].displayName or "this player")..". Select any group member in Builds." end
    return table.concat(lines,"\n\n")
end
function SC:GetCoverageContributorTooltip(data)return ContributorTooltip(data)end
function SC:CreateMatrixWindow()
    local win=UI.Window("AlphaSquadSupportCoverageMatrix","Ąlpha Şquad UI  •  Coverage",function()
        UI.CloseWindow("supportCoverage",function() SC:CloseMatrix() end)
    end)
    win.hasContentLayout=true
    self.matrixWindow=win;UI.RegisterWindow("supportCoverage",win,function() SC:CloseMatrix() end,function() SC:RefreshMatrix() end)
    win.trial=UI.Button(win,"AlphaSquadSupportTrial","TRIAL",90,28,function() SC:SetActiveProfile("trial") end)
    win.trial:SetAnchor(TOPLEFT,win,TOPLEFT,18,82)
    win.dungeon=UI.Button(win,"AlphaSquadSupportDungeon","DUNGEON",104,28,function() SC:SetActiveProfile("dungeon") end)
    win.dungeon:SetAnchor(TOPLEFT,win,TOPLEFT,116,82)
    win.filterButtons={}
    for index,filter in ipairs({"ALL","MISSING","DUPLICATES"}) do
        local key=filter
        local b=UI.Button(win,"AlphaSquadSupportFilter"..key,key,116,28,function() SC.matrixFilter=key;SC:RefreshMatrix() end)
        b:SetAnchor(TOPLEFT,win,TOPLEFT,246+(index-1)*124,82);win.filterButtons[key]=b
    end
    win.builds=UI.Button(win,"AlphaSquadMatrixBuilds","BUILDS",106,28,function() SC:OpenInspector("BUILD") end)
    win.builds:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,82)
    win.columns={};win.categoryPanels={}
    for index,label in ipairs(categoryNames) do
        local panel=WINDOW_MANAGER:CreateControl("AlphaSquadCoverageCategory"..index,win,CT_CONTROL)
        panel.bg=UI.Solid(panel,"AlphaSquadCoverageCategoryBG"..index,C.surface or C.panel)
        if UI.Surface then UI.Surface(panel,panel.bg,"card") end
        win.categoryPanels[index]=panel
        win.columns[index]=UI.Label(win,"AlphaSquadCoverageColumn"..index,label,"ZoFontGameBold",C.orange)
    end
    win.list=WINDOW_MANAGER:CreateControl("AlphaSquadSupportCoverageGrid",win,CT_CONTROL)
    win.list:SetAnchor(TOPLEFT,win,TOPLEFT,18,144);win.list.rows={}
    win.legend=WINDOW_MANAGER:CreateControl("AlphaSquadCoverageLegend",win,CT_CONTROL)
    win.legend.bg=UI.Solid(win.legend,"AlphaSquadCoverageLegendBG",C.surface or C.panel)
    if UI.Surface then UI.Surface(win.legend,win.legend.bg,"card") end
    win.legend.title=UI.Label(win.legend,"AlphaSquadCoverageLegendTitle","STATUS","ZoFontGameBold",C.accent or C.orange)
    win.legend.title:SetAnchor(TOPLEFT,win.legend,TOPLEFT,10,5);win.legend.title:SetHeight(24)
    win.legend.rows={}
    for index,data in ipairs({{"Covered",C.green},{"Missing",C.red},{"Unknown / duplicate",C.gold},{"Optional",C.muted}}) do
        local marker=WINDOW_MANAGER:CreateControl("AlphaSquadCoverageLegendMarker"..index,win.legend,CT_TEXTURE)
        marker:SetAnchor(TOPLEFT,win.legend,TOPLEFT,10,36+(index-1)*32);marker:SetDimensions(12,12);UI.Color(marker,data[2])
        local label=UI.Label(win.legend,"AlphaSquadCoverageLegendLabel"..index,data[1],"ZoFontGameSmall",C.white)
        label:SetAnchor(TOPLEFT,win.legend,TOPLEFT,30,29+(index-1)*32);win.legend.rows[index]=label
    end
    win.footer:SetText("Hover names for sources and conditions • Hover counts for every contributor • Click a count to inspect its named build")
end
function SC:RefreshMatrix()
    local win=self.matrixWindow;if not win or win:IsHidden() then return end
    local keys=Catalog:GetAllEffectKeys();local counts={0,0,0,0}
    for _,key in ipairs(keys) do local i=categoryIndex[Catalog:GetDisplayCategory(key)] or 1;counts[i]=counts[i]+1 end
    local layout=self:GetCoverageGridLayout(counts);win.gridLayout=layout
    win:SetDimensions(layout.width,layout.height);win:SetScale(math.max(0.1,math.min(1,(GuiRoot:GetWidth()-24)/layout.width,(GuiRoot:GetHeight()-24)/layout.height)))
    win.list:SetDimensions(layout.width-36,layout.height-198)
    local coverage=self.coverage or {}
    win.subtitle:SetText(string.format("%s  •  %d / %d covered  •  %d missing  •  %d players with limited data",coverage.profileLabel or "Group preparation",coverage.coveredCount or 0,coverage.requiredCount or 0,coverage.missingCount or 0,coverage.limitedPlayers or 0))
    if UI.SetButtonSelected then
        UI.SetButtonSelected(win.trial,self.sv.activeProfile=="trial");UI.SetButtonSelected(win.dungeon,self.sv.activeProfile=="dungeon")
        for key,button in pairs(win.filterButtons) do UI.SetButtonSelected(button,(self.matrixFilter or "ALL")==key) end
    end
    UI.Color(win.trial.label,self.sv.activeProfile=="trial" and C.orange or C.muted)
    UI.Color(win.dungeon.label,self.sv.activeProfile=="dungeon" and C.orange or C.muted)
    for key,b in pairs(win.filterButtons) do UI.Color(b.label,(self.matrixFilter or "ALL")==key and C.orange or C.muted) end
    for index,label in ipairs(win.columns) do
        label:ClearAnchors();label:SetAnchor(TOPLEFT,win,TOPLEFT,18+layout.starts[index],116)
        local width=layout.lanes[index]*layout.laneWidth+(layout.lanes[index]-1)*5
        label:SetDimensions(width,24)
        local panel=win.categoryPanels[index]
        panel:ClearAnchors();panel:SetAnchor(TOPLEFT,win,TOPLEFT,14+layout.starts[index],112)
        panel:SetDimensions(width+8,layout.height-160)
    end
    local legendY=144+layout.rows[4]*layout.pitch+18
    local legendWidth=layout.lanes[4]*layout.laneWidth+(layout.lanes[4]-1)*5
    win.legend:SetHidden(layout.height-48-legendY<168)
    win.legend:ClearAnchors();win.legend:SetAnchor(TOPLEFT,win,TOPLEFT,18+layout.starts[4],legendY);win.legend:SetDimensions(legendWidth,166)
    for _,label in ipairs(win.legend.rows) do label:SetDimensions(legendWidth-38,32) end
    local byKey={};for _,row in ipairs(coverage.entries or {}) do byKey[row.key]=row end
    local selected={};for _,key in ipairs(Catalog:GetRequirements(self.sv.activeProfile,self.sv)) do selected[key]=true end
    local positions={0,0,0,0};local count=0
    for _,key in ipairs(keys) do
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
                row=WINDOW_MANAGER:CreateControl(name,win.list,CT_CONTROL)
                row.bg=UI.Solid(row,name.."BG",C.surface or C.panel)
                if UI.Separator then row.divider=UI.Separator(row,name.."Divider",0,0,1) end
                row.marker=WINDOW_MANAGER:CreateControl(name.."Marker",row,CT_TEXTURE)
                row.marker:SetAnchor(TOPLEFT,row,TOPLEFT,0,0)
                row.icon=WINDOW_MANAGER:CreateControl(name.."Icon",row,CT_TEXTURE)
                row.icon:SetAnchor(TOPLEFT,row,TOPLEFT,5,1);row.icon:SetDimensions(18,18)
                row.name=UI.Label(row,name.."Name","","ZoFontGameSmall")
                row.name:SetAnchor(TOPLEFT,row,TOPLEFT,27,0)
                if row.name.SetWrapMode then row.name:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
                UI.Hover(row.name,function() return row.data and EffectTooltip(row.data.key) end)
                row.toggle=UI.Button(row,name.."Toggle","",31,20,function()
                    if row.data then SC:SetEffectTracking(row.data.key,not SC:IsEffectTracked(row.data.key));SC:RefreshMatrix() end
                end)
                row.toggle.label:SetFont("ZoFontGameSmall")
                row.toggle:SetAnchor(TOPRIGHT,row,TOPRIGHT,0,0)
                UI.Hover(row.toggle,function()return row.data and (SC:IsEffectTracked(row.data.key) and "Tracking is on. Click to make this effect optional for " or "Tracking is off. Click to require this effect for ")..SC.sv.activeProfile.."." end)
                row.contributors=UI.Button(row,name.."Contributors","",26,20,function()
                    local player=row.data and (row.data.owners or {})[1]
                    if player then SC.inspectorPlayerKey=player.key or player.displayName;SC:OpenInspector("BUILD") end
                end)
                row.contributors.label:SetFont("ZoFontGameSmall")
                row.contributors:SetAnchor(TOPRIGHT,row.toggle,TOPLEFT,-1,0)
                UI.Hover(row.contributors,function()return ContributorTooltip(row.data) end)
                UI.Hover(row.icon,function() return row.data and EffectTooltip(row.data.key) end)
                win.list.rows[count]=row
            end
            row.data=data;row:SetHidden(false)
            local visual=Catalog:GetEffectVisual(key)
            row.icon:SetTexture(visual and visual.icon or "");row.icon:SetHidden(not visual or not visual.icon or visual.icon=="")
            if visual and visual.reference then row.icon:SetHandler("OnMouseEnter",function() UI.ItemTooltip(row.icon,visual,true) end)
            else row.icon:SetHandler("OnMouseEnter",function() UI.Tooltip(row.icon,EffectTooltip(row.data.key)) end) end
            row.name:SetText(UI.Text(effect.label));UI.Color(row.name,tracked and C.white or C.muted)
            row.toggle.label:SetText(tracked and "ON" or "OFF");UI.Color(row.toggle.label,tracked and C.green or C.muted)
            if UI.SetButtonSelected then UI.SetButtonSelected(row.toggle,tracked) end
            local status,color=UI.Status(data)
            if not tracked then status="OPTIONAL";color=C.muted elseif duplicate then status="DUPLICATE";color=C.gold end
            row.status=status;UI.Color(row.marker,color)
            row.contributors.label:SetText(#(data.owners or {})>0 and (duplicate and "×" or "")..#data.owners or "—")
            UI.Color(row.contributors.label,color)
            local category=categoryIndex[Catalog:GetDisplayCategory(key)] or 1
            local index=positions[category];positions[category]=index+1
            local lane=math.floor(index/layout.rows[category]);local y=(index%layout.rows[category])*layout.pitch
            row:ClearAnchors();row:SetAnchor(TOPLEFT,win.list,TOPLEFT,layout.starts[category]+lane*(layout.laneWidth+5),y)
            row:SetDimensions(layout.laneWidth,layout.pitch-1)
            if row.divider then row.divider:ClearAnchors();row.divider:SetAnchor(BOTTOMLEFT,row,BOTTOMLEFT,0,0);row.divider:SetWidth(layout.laneWidth) end
            row.marker:SetDimensions(2,layout.pitch-1)
            -- A dense row can be shorter than the default icon; keep its artwork
            -- inside its own hit area and away from the following source.
            local iconSize=math.min(18,layout.pitch-3)
            row.icon:SetDimensions(iconSize,iconSize)
            row.icon:ClearAnchors();row.icon:SetAnchor(TOPLEFT,row,TOPLEFT,5,(layout.pitch-1-iconSize)/2)
            row.name:SetDimensions(layout.laneWidth-87,layout.pitch-1)
            row.toggle:SetHeight(layout.pitch-1);row.contributors:SetHeight(layout.pitch-1)
        end
    end
    for index=count+1,#win.list.rows do win.list.rows[index]:SetHidden(true);win.list.rows[index].data=nil end
end
if AlphaSquadUI.Settings and AlphaSquadUI.Settings.RegisterPage then
    AlphaSquadUI.Settings.RegisterPage("supportcoverage",function(page,ui) SC:BuildIntegratedSettingsPage(page,ui) end)
end
