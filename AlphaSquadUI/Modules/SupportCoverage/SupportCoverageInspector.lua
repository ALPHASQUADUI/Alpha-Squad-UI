-- One-page character sheet with group food status alongside player selection.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,C=SC.UI,SC.UI.colors
local function L(text,...)
    if AlphaSquadUI.L then return AlphaSquadUI.L(text,...) end
    return select("#",...)>0 and string.format(text,...) or text
end
local function Text(value,fallback)
    if type(value)=="string" and value~="" then return (value:gsub("%^.*$","")) end
    return L(fallback or "Unknown")
end
local function ClassIcon(player)
    local id=player and player.classId
    if type(id)~="number" or id~=id or id<1 or id>255 or id%1~=0 or type(ZO_GetClassIcon)~="function" then return nil end
    local ok,icon=pcall(ZO_GetClassIcon,id)
    return ok and type(icon)=="string" and icon~="" and icon or nil
end
local function PlayerKey(player) return player and (player.key or player.displayName) end
local function FoodText(food)
    if not food or not food.verified then return L("FOOD UNKNOWN"),C.muted,L("Food information is unavailable.") end
    if not food.active then return L("NO FOOD"),C.red,L("No active food or drink detected.") end
    return L("FOOD ACTIVE"),C.green,Text(food.name,"Food or drink active")
end
local function ClassName(player)
    if player and type(player.className)=="string" and player.className~="" then return Text(player.className) end
    if player and player.classId and GetClassName then
        local ok,name=pcall(GetClassName,GENDER_MALE or 0,player.classId)
        if ok and name and name~="" then return Text(name) end
    end
    return L("Class unavailable")
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
    if self.loading or self.inCombat then return false end
    self.inspectorTab="BUILD"
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
function SC:OpenFoodCheck() return self:OpenInspector("BUILD") end
function SC:CreateInspectorWindow()
    local win=UI.Window("AlphaSquadSupportInspector","Builds",function()
        UI.CloseWindow("supportBuilds",function() SC:CloseInspector() end)
    end)
    win.hasContentLayout=true
    self.inspectorWindow=win;UI.RegisterWindow("supportBuilds",win,function()SC:CloseInspector()end,function()SC:RefreshInspector()end)
    win.coverage=UI.Button(win,"AlphaSquadInspectorCoverage","COVERAGE",124,30,function()SC:OpenMatrix()end)
    win.coverage:SetAnchor(TOPRIGHT,win,TOPRIGHT,-104,14)
    win.title:ClearAnchors();win.title:SetAnchor(TOPLEFT,win,TOPLEFT,18,12);win.title:SetHeight(32)
    win.request=UI.Button(win,"AlphaSquadInspectorRequest","REFRESH BUILD",144,30,function()
        if SC.inspectorPlayerKey then SC:RequestInspectedBuild(SC.inspectorPlayerKey);SC:RefreshInspector() end
    end)
    win.request:SetAnchor(TOPRIGHT,win.coverage,TOPLEFT,-8,0)
    win.title:SetAnchor(TOPRIGHT,win.request,TOPLEFT,-12,0)
    win.playerHeader=UI.Label(win,"AlphaSquadInspectorGroupHeader","GROUP","ZoFontGameBold",C.white)
    win.playerHeader:SetAnchor(TOPLEFT,win,TOPLEFT,18,92);win.playerHeader:SetDimensions(176,24)
    win.playerPanel=WINDOW_MANAGER:CreateControl("AlphaSquadInspectorPlayerPanel",win,CT_CONTROL)
    win.playerPanel:SetAnchor(TOPLEFT,win,TOPLEFT,18,120);win.playerPanel:SetDimensions(180,492)
    win.playerBG=UI.Solid(win.playerPanel,"AlphaSquadInspectorPlayerBG",C.surface or C.panel)
    if UI.Surface then UI.Surface(win.playerPanel,win.playerBG,"card") end
    win.playerList=UI.Scroll(win.playerPanel,"AlphaSquadInspectorPlayers")
    win.playerList:SetAnchor(TOPLEFT,win.playerPanel,TOPLEFT,0,0);win.playerList:SetDimensions(180,492)
    win.buildSheet=self.BuildView.Create(win);win.buildSheet:SetAnchor(TOPLEFT,win,TOPLEFT,212,92)
    win.footer:SetText(L("Hover for details • ? unavailable • — empty"))
end
function SC:RefreshInspectorRoster()
    local win=self.inspectorWindow;local roster=self.roster or {}
    for index,player in ipairs(roster) do
        local row=win.playerList.rows[index]
        if not row then
            row=UI.Button(win.playerList.content,"AlphaSquadInspectorPlayer"..index,"",158,38,function(button)
                UI.ClearTooltip();SC.inspectorPlayerKey=PlayerKey(button.player)
                SC:RequestInspectedBuild(SC.inspectorPlayerKey);SC:RefreshInspector()
            end)
            row.label:ClearAnchors();row.label:SetAnchor(TOPLEFT,row,TOPLEFT,37,0);row.label:SetDimensions(117,21)
            row.label:SetFont("ZoFontGameBold");row.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
            if row.label.SetWrapMode then row.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
            row.detail=UI.Label(row,"AlphaSquadInspectorPlayerDetail"..index,"","ZoFontGameSmall",C.muted)
            row.detail:SetAnchor(TOPLEFT,row,TOPLEFT,37,20);row.detail:SetDimensions(117,18)
            row.classIcon=WINDOW_MANAGER:CreateControl("AlphaSquadInspectorPlayerClass"..index,row,CT_TEXTURE)
            row.classIcon:SetAnchor(TOPLEFT,row,TOPLEFT,7,7);row.classIcon:SetDimensions(24,24)
            row.marker=WINDOW_MANAGER:CreateControl("AlphaSquadInspectorPlayerMarker"..index,row,CT_TEXTURE)
            row.marker:SetAnchor(TOPLEFT,row,TOPLEFT,0,0);row.marker:SetDimensions(3,38)
            if UI.BindColor then UI.BindColor(row.marker,C.white) else UI.Color(row.marker,C.white) end
            row:SetHandler("OnMouseEnter",function()
                local p=row.player;if not p then return end
                row.hovered=true
                if UI.SetButtonSelected then UI.SetButtonSelected(row,row.selected) else UI.Color(row.bg,C.hover or C.panelActive or C.panel) end
                UI.Tooltip(row,Text(p.displayName).."\n"..Text(p.characterName,p.name or "").."\n"..ClassName(p).."\n\n"..L("Click to inspect this player's shared build."))
            end)
            win.playerList.rows[index]=row
        end
        row.player=player;row:SetHidden(false);row:ClearAnchors();row:SetAnchor(TOPLEFT,win.playerList.content,TOPLEFT,0,(index-1)*40)
        local selected=PlayerKey(player)==self.inspectorPlayerKey
        row.label:SetText(AlphaSquadUI.Theme.PlayerName and AlphaSquadUI.Theme.PlayerName(player.displayName) or UI.Text(Text(player.displayName,"Unknown player")));UI.Color(row.label,C.white)
        row.marker:SetHidden(not selected)
        if UI.SetButtonSelected then UI.SetButtonSelected(row,selected) end
        local icon=ClassIcon(player)
        row.classIcon:SetTexture(icon or "");row.classIcon:SetHidden(not icon)
        local status,color=FoodText(player.food)
        row.detail:SetText(player.connected==false and L("OFFLINE") or player.dead and L("DEAD") or status)
        UI.Color(row.detail,player.connected==false and C.muted or player.dead and C.gold or color)
    end
    for index=#roster+1,#win.playerList.rows do win.playerList.rows[index]:SetHidden(true);win.playerList.rows[index].player=nil end
    win.playerHeader:SetText(L("GROUP  •  %d",#roster))
    UI.FinishScroll(win.playerList,#roster*40,158)
end
function SC:RefreshInspector()
    local win=self.inspectorWindow;if not win or win:IsHidden() then return end
    -- Bind once, then fit the complete logical sheet. Rendered child dimensions
    -- already include parent scale and must never feed back into this calculation.
    win.title:SetText(L("Builds"))
    local player=self:GetInspectedPlayer()
    win.request:SetHidden(not player)
    win.buildSheet:SetHidden(false)
    self:RefreshInspectorRoster()
    local details,status
    if player and self.GetPlayerBuildDetails then details,status=self:GetPlayerBuildDetails(PlayerKey(player))
    elseif player and player.unitTag=="player" then details=self.localSnapshot end
    local requestError=self.inspectorRequestKey==PlayerKey(player) and self.inspectorRequestError or nil
    if requestError then status=requestError end
    local subtitle=player and (Text(player.displayName).."  •  "..ClassName(player)..(player.connected==false and "  •  "..L("Offline") or "")) or L("Select a player from the group list.")
    if details then subtitle=subtitle.."\n"..L(requestError or (player and player.unitTag=="player" and "Your equipped build" or "Shared build snapshot • refresh after changes"))
    elseif player then
        -- Keep transfer progress and failures visible even when another library
        -- already supplies set rows, which hide the sheet's empty-state label.
        subtitle=subtitle.."\n"..L(Text(status,"Partial information • request a compatible shared build for exact equipment and skill slots"))
    end
    win.subtitle:SetText((UI.Text(subtitle):gsub("@SeRuM1",function() return AlphaSquadUI.Theme.authorText or "@SeRuM1" end)))
    win.footer:SetText(L("Hover for details • ? unavailable • — empty"))
    self.BuildView.Bind(win.buildSheet,player,details,status)
    local _,sheetHeight=self.BuildView.GetDimensions(win.buildSheet)
    local height=math.max(660,sheetHeight+144)
    win.playerPanel:SetHeight(height-168)
    win.playerList:SetHeight(height-168)
    UI.FinishScroll(win.playerList,#(self.roster or {})*40,158)
    win:SetDimensions(1060,height)
    win:SetScale(math.max(0.1,math.min(1,(GuiRoot:GetWidth()-24)/1060,(GuiRoot:GetHeight()-24)/height)))
end
-- Harmless migration aliases for windows that no longer exist.
function SC:ClosePullReport() if self.reportWindow then self.reportWindow:SetHidden(true) end end
function SC:OpenPullReport() return false end
function SC:RefreshPullReport() end
