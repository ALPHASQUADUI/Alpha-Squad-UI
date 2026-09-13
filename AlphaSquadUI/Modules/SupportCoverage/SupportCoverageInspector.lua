-- One-page character sheet and a separate, reusable group food list.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,C=SC.UI,SC.UI.colors
local function Text(value,fallback)
    if type(value)=="string" and value~="" then return value:gsub("%^.*$","") end
    return fallback or "Unknown"
end
local function PlayerKey(player) return player and (player.key or player.displayName) end
local function FoodText(food)
    if not food or not food.verified then return "FOOD UNKNOWN",C.muted,"Food information is unavailable." end
    if not food.active then return "NO FOOD",C.red,"No active food or drink detected." end
    return "FOOD ACTIVE",C.green,Text(food.name,"Food or drink active")
end
local function PotionText(potion)
    if potion and potion.known then
        local stock=potion.stack or potion.count
        return Text(potion.name,"Potion selected")..(type(stock)=="number" and (" • "..stock.." available") or "")
    end
    if potion and potion.selectionKnown then return "No potion selected" end
    return "Selected potion unavailable"
end
local function ClassName(player)
    if player and type(player.className)=="string" and player.className~="" then return Text(player.className) end
    if player and player.classId and GetClassName then
        local ok,name=pcall(GetClassName,GENDER_MALE or 0,player.classId)
        if ok and name and name~="" then return Text(name) end
    end
    return "Class unavailable"
end
function SC:GetInspectedPlayer()
    local key=self.inspectorPlayerKey
    for _,player in ipairs(self.roster or {}) do if PlayerKey(player)==key then return player end end
end
function SC:ResizeInspector()
    if self.matrixWindow and not self.matrixWindow:IsHidden() then self:RefreshMatrix() end
    if self.inspectorWindow and not self.inspectorWindow:IsHidden() then self:RefreshInspector() end
end
function SC:CloseInspector()
    if self.inspectorWindow then self.inspectorWindow:SetHidden(true) end
    UI.ClearTooltip()
    if AlphaSquadUI.Settings.RefreshModuleVisibility then AlphaSquadUI.Settings.RefreshModuleVisibility() else self:ApplyVisibility() end
end
function SC:RequestInspectedBuild(key)
    if not key or not self.RequestPlayerBuild then return false end
    local ok,message=self:RequestPlayerBuild(key)
    self.inspectorRequestError=not ok and message or nil;self.inspectorRequestKey=key
    return ok
end
function SC:OpenInspector(tab)
    if self.inCombat then return false end
    self.inspectorTab=tab=="FOOD" and "FOOD" or "BUILD"
    if not self.inspectorWindow then self:CreateInspectorWindow() end
    if not self:GetInspectedPlayer() then
        local first=(self.roster or {})[1]
        for _,player in ipairs(self.roster or {}) do if player.unitTag=="player" or player.isSelf then first=player;break end end
        self.inspectorPlayerKey=PlayerKey(first)
    end
    UI.ShowWindow("supportBuilds",self.inspectorWindow)
    if self.inspectorTab=="BUILD" and self.inspectorPlayerKey then self:RequestInspectedBuild(self.inspectorPlayerKey) end
    self:RefreshInspector();return true
end
function SC:OpenFoodCheck() return self:OpenInspector("FOOD") end
function SC:CreateInspectorWindow()
    local win=UI.Window("AlphaSquadSupportInspector","Ąlpha Şquad UI  •  Builds",function()SC:CloseInspector()end)
    self.inspectorWindow=win;UI.RegisterWindow("supportBuilds",win,function()SC:CloseInspector()end)
    win.buildTab=UI.Button(win,"AlphaSquadInspectorBuildTab","BUILDS",112,30,function()SC.inspectorTab="BUILD";UI.ClearTooltip();SC:RefreshInspector()end)
    win.buildTab:SetAnchor(TOPLEFT,win,TOPLEFT,18,96)
    win.foodTab=UI.Button(win,"AlphaSquadInspectorFoodTab","FOOD CHECK",130,30,function()SC.inspectorTab="FOOD";UI.ClearTooltip();SC:RefreshInspector()end)
    win.foodTab:SetAnchor(TOPLEFT,win,TOPLEFT,138,96)
    win.coverage=UI.Button(win,"AlphaSquadInspectorCoverage","COVERAGE",124,30,function()SC:OpenMatrix()end)
    win.coverage:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,96)
    win.request=UI.Button(win,"AlphaSquadInspectorRequest","REFRESH BUILD",144,30,function()
        if SC.inspectorPlayerKey then SC:RequestInspectedBuild(SC.inspectorPlayerKey);SC:RefreshInspector() end
    end)
    win.request:SetAnchor(TOPRIGHT,win.coverage,TOPLEFT,-8,0)
    win.playerHeader=UI.Label(win,"AlphaSquadInspectorGroupHeader","GROUP","ZoFontGameBold",C.orange)
    win.playerHeader:SetAnchor(TOPLEFT,win,TOPLEFT,18,146);win.playerHeader:SetDimensions(176,24)
    win.playerList=UI.Scroll(win,"AlphaSquadInspectorPlayers")
    win.playerList:SetAnchor(TOPLEFT,win,TOPLEFT,18,174);win.playerList:SetDimensions(180,474)
    win.detailList=UI.Scroll(win,"AlphaSquadInspectorDetails")
    win.detailList:SetAnchor(TOPLEFT,win,TOPLEFT,18,146);win.detailList:SetDimensions(1024,502)
    win.buildSheet=self.BuildView.Create(win);win.buildSheet:SetAnchor(TOPLEFT,win,TOPLEFT,212,146)
    win.footer:SetText("Hover any item, skill or Champion star for details. ? means unavailable; an empty slot is shown as —. Front and back set totals are counted separately.")
end
function SC:GetInspectorRows()
    local rows={}
    if self.inspectorTab~="FOOD" then return rows end
    for _,player in ipairs(self.roster or {}) do
        local status,color,food=FoodText(player.food)
        local unavailable=player.connected==false and "OFFLINE • " or player.dead and "DEAD • " or ""
        rows[#rows+1]={title=unavailable..Text(player.displayName,"Unknown player"),status=status,color=color,
            detail=food,subdetail=PotionText(player.potion),player=player,
            tooltip="Food presence can be verified independently of a full build. A selected potion is preparation evidence only. An unavailable reading does not mean this player has no food."}
    end
    if #rows==0 then rows[1]={title="No group members",status="",color=C.muted,detail="Join a group to check food and selected potions.",subdetail=""} end
    return rows
end
function SC:RefreshInspectorRoster()
    local win=self.inspectorWindow;local roster=self.roster or {}
    for index,player in ipairs(roster) do
        local row=win.playerList.rows[index]
        if not row then
            row=UI.Button(win.playerList.content,"AlphaSquadInspectorPlayer"..index,"",158,58,function(button)
                UI.ClearTooltip();SC.inspectorPlayerKey=PlayerKey(button.player)
                SC:RequestInspectedBuild(SC.inspectorPlayerKey);SC:RefreshInspector()
            end)
            row.label:ClearAnchors();row.label:SetAnchor(TOPLEFT,row,TOPLEFT,7,4);row.label:SetDimensions(146,24)
            row.label:SetFont("ZoFontGameBold");row.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
            if row.label.SetWrapMode then row.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
            row.detail=UI.Label(row,"AlphaSquadInspectorPlayerDetail"..index,"","ZoFontGameSmall",C.muted)
            row.detail:SetAnchor(TOPLEFT,row,TOPLEFT,7,30);row.detail:SetDimensions(146,22)
            row.marker=WINDOW_MANAGER:CreateControl("AlphaSquadInspectorPlayerMarker"..index,row,CT_TEXTURE)
            row.marker:SetAnchor(TOPLEFT,row,TOPLEFT,0,0);row.marker:SetDimensions(3,58);UI.Color(row.marker,C.orange)
            row:SetHandler("OnMouseEnter",function()
                local p=row.player;if not p then return end
                row.bg:SetColor(0.16,0.10,0.045,1)
                UI.Tooltip(row,Text(p.displayName).."\n"..Text(p.characterName,p.name or "").."\n"..ClassName(p).."\n\nClick to inspect this player's shared build.")
            end)
            win.playerList.rows[index]=row
        end
        row.player=player;row:SetHidden(false);row:ClearAnchors();row:SetAnchor(TOPLEFT,win.playerList.content,TOPLEFT,0,(index-1)*63)
        local selected=PlayerKey(player)==self.inspectorPlayerKey
        row.label:SetText(UI.Text(Text(player.displayName,"Unknown player")));UI.Color(row.label,selected and C.orange or C.white)
        row.marker:SetHidden(not selected)
        local status,color=FoodText(player.food)
        row.detail:SetText(player.connected==false and "OFFLINE" or player.dead and "DEAD" or status)
        UI.Color(row.detail,player.connected==false and C.muted or player.dead and C.gold or color)
    end
    for index=#roster+1,#win.playerList.rows do win.playerList.rows[index]:SetHidden(true);win.playerList.rows[index].player=nil end
    win.playerHeader:SetText("GROUP  •  "..#roster)
    UI.FinishScroll(win.playerList,#roster*63,158)
end
function SC:RefreshInspectorFood()
    local win=self.inspectorWindow;local rows=self:GetInspectorRows()
    for index,data in ipairs(rows) do
        local row=win.detailList.rows[index]
        if not row then
            local name="AlphaSquadInspectorFoodRow"..index
            row=WINDOW_MANAGER:CreateControl(name,win.detailList.content,CT_CONTROL)
            row.bg=UI.Solid(row,name.."BG",C.panel)
            row.title=UI.Label(row,name.."Title","","ZoFontGameBold")
            row.title:SetAnchor(TOPLEFT,row,TOPLEFT,14,8);row.title:SetDimensions(310,27)
            row.status=UI.Label(row,name.."Status","","ZoFontGameBold")
            row.status:SetAnchor(TOPRIGHT,row,TOPRIGHT,-14,8);row.status:SetDimensions(180,27);row.status:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
            row.detail=UI.Label(row,name.."Detail","","ZoFontGameSmall",C.muted)
            row.detail:SetAnchor(TOPLEFT,row,TOPLEFT,14,39);row.detail:SetDimensions(472,23)
            row.potion=UI.Label(row,name.."Potion","","ZoFontGameSmall",C.muted)
            row.potion:SetAnchor(TOPLEFT,row,TOPLEFT,512,39);row.potion:SetDimensions(472,23)
            UI.Hover(row,function()return row.data and row.data.tooltip end)
            win.detailList.rows[index]=row
        end
        row.data=data;row:SetHidden(false);row:ClearAnchors();row:SetAnchor(TOPLEFT,win.detailList.content,TOPLEFT,0,(index-1)*78);row:SetDimensions(1002,72)
        row.title:SetText(UI.Text(data.title));row.status:SetText(data.status or "");UI.Color(row.status,data.color)
        row.detail:SetText(UI.Text(data.detail));row.potion:SetText(UI.Text(data.subdetail))
    end
    for index=#rows+1,#win.detailList.rows do win.detailList.rows[index]:SetHidden(true);win.detailList.rows[index].data=nil end
    UI.FinishScroll(win.detailList,#rows*78,1002)
end
function SC:RefreshInspector()
    local win=self.inspectorWindow;if not win or win:IsHidden() then return end
    -- A stable logical canvas keeps the complete character sheet on one page at all UI scales.
    win:SetDimensions(1060,700);win:SetScale(math.max(0.1,math.min(1,(GuiRoot:GetWidth()-24)/1060,(GuiRoot:GetHeight()-24)/700)))
    local foodMode=self.inspectorTab=="FOOD"
    win.title:SetText("Ąlpha Şquad UI  •  "..(foodMode and "Food check" or "Builds"))
    UI.Color(win.buildTab.label,not foodMode and C.orange or C.muted);UI.Color(win.foodTab.label,foodMode and C.orange or C.muted)
    win.playerList:SetHidden(foodMode);win.playerHeader:SetHidden(foodMode);win.detailList:SetHidden(not foodMode);win.buildSheet:SetHidden(foodMode)
    local player=self:GetInspectedPlayer()
    win.request:SetHidden(foodMode or not player)
    if foodMode then
        win.subtitle:SetText("Check food presence and the selected potion for every player before combat.")
        win.footer:SetText("Food active confirms a detected buff. Unknown means the information is unavailable; it does not mean no food. Selected potions do not prove use.")
        self:RefreshInspectorFood();return
    end
    self:RefreshInspectorRoster()
    local details,status
    if player and self.GetPlayerBuildDetails then details,status=self:GetPlayerBuildDetails(PlayerKey(player))
    elseif player and player.unitTag=="player" then details=self.localSnapshot end
    if self.inspectorRequestKey==PlayerKey(player) and self.inspectorRequestError and not details then status=self.inspectorRequestError end
    local subtitle=player and (Text(player.displayName).."  •  "..ClassName(player)..(player.connected==false and "  •  Offline" or "")) or "Select a player from the group list."
    if details then subtitle=subtitle.."\n"..(player and player.unitTag=="player" and "Your equipped build" or "Shared build snapshot • refresh after changes")
    elseif player then subtitle=subtitle.."\nPartial information • request a compatible shared build for exact equipment and skill slots" end
    win.subtitle:SetText(UI.Text(subtitle))
    win.footer:SetText("Hover equipment, skills and Champion stars for their details. ? = unavailable • — = empty. Set names show equipped items; FRONT / BACK show set pieces.")
    self.BuildView.Bind(win.buildSheet,player,details,status)
end
-- Harmless migration aliases for windows that no longer exist.
function SC:ClosePullReport() if self.reportWindow then self.reportWindow:SetHidden(true) end end
function SC:OpenPullReport() return false end
function SC:RefreshPullReport() end
