-- On-demand group build and food inspection. Controls are reused and scroll naturally.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI=SC.UI
local C=UI.colors
local function Text(value,fallback)
    if type(value)=="string" and value~="" then return value:gsub("%^.*$", "") end
    return fallback or "Unknown"
end
local function FoodText(food)
    if not food or not food.verified then return "UNKNOWN",C.gold,"Food information is not available." end
    if not food.active then return "NO FOOD",C.red,"No active food or drink was detected." end
    return "FOOD ACTIVE",C.green,Text(food.name,"Food or drink active")
end
local function PotionText(potion)
    if potion and potion.known then
        local name=Text(potion.name,"Potion selected")
        local stock=potion.stack or potion.count
        return name .. (stock and (" • " .. tostring(stock) .. " available") or ""),C.white
    elseif potion and potion.selectionKnown then return "No potion selected",C.gold end
    return "Selected potion unavailable",C.muted
end
local function PlayerKey(player) return player and (player.key or player.displayName) end
local function FreshSharedSample(updatedAt,maxAge)
    if type(updatedAt)~="number" or updatedAt~=updatedAt or not SC.NowMs then return false end
    local age=SC.NowMs()-updatedAt
    return age>=0 and age<=(maxAge or 75000)
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
    return nil
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
    self.inspectorRequestError=not ok and message or nil
    self.inspectorRequestKey=key
    return ok
end
function SC:OpenInspector(tab)
    if self.inCombat then return false end
    self.inspectorTab=tab=="FOOD" and "FOOD" or "BUILD"
    if not self.inspectorWindow then self:CreateInspectorWindow() end
    UI.ShowWindow("supportBuilds",self.inspectorWindow)
    if self.inspectorTab=="BUILD" and self.inspectorPlayerKey and self.RequestPlayerBuild then self:RequestInspectedBuild(self.inspectorPlayerKey) end
    self:RefreshInspector(); return true
end
function SC:OpenFoodCheck() return self:OpenInspector("FOOD") end
function SC:CreateInspectorWindow()
    local win=UI.Window("AlphaSquadSupportInspector","Ąlpha Şquad UI  •  Builds",function() SC:CloseInspector() end)
    self.inspectorWindow=win; UI.RegisterWindow("supportBuilds",win,function() SC:CloseInspector() end)
    win.buildTab=UI.Button(win,"AlphaSquadInspectorBuildTab","BUILDS",112,30,function() SC.inspectorTab="BUILD"; SC:RefreshInspector() end)
    win.buildTab:SetAnchor(TOPLEFT,win,TOPLEFT,18,96)
    win.foodTab=UI.Button(win,"AlphaSquadInspectorFoodTab","FOOD CHECK",130,30,function() SC.inspectorTab="FOOD"; SC:RefreshInspector() end)
    win.foodTab:SetAnchor(TOPLEFT,win,TOPLEFT,138,96)
    win.coverage=UI.Button(win,"AlphaSquadInspectorCoverage","COVERAGE",124,30,function() SC:OpenMatrix() end)
    win.coverage:SetAnchor(TOPRIGHT,win,TOPRIGHT,-18,96)
    win.request=UI.Button(win,"AlphaSquadInspectorRequest","REFRESH BUILD",144,30,function()
        if SC.inspectorPlayerKey and SC.RequestPlayerBuild then
            SC:RequestInspectedBuild(SC.inspectorPlayerKey); SC:RefreshInspector()
        end
    end)
    win.request:SetAnchor(TOPRIGHT,win.coverage,TOPLEFT,-8,0)
    win.playerList=UI.Scroll(win,"AlphaSquadInspectorPlayers")
    win.playerList:SetAnchor(TOPLEFT,win,TOPLEFT,18,146); win.playerList:SetAnchor(BOTTOMLEFT,win,BOTTOMLEFT,18,-64)
    win.detailList=UI.Scroll(win,"AlphaSquadInspectorDetails")
    win.detailList:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-16,-64)
    win.footer:SetText("Select a player to request their build. Equipment, skill bars and Champion Points require a compatible sender. Unknown means unavailable or incomplete data.")
end

function SC:GetInspectorRows()
    local rows={}
    local function Add(title,detail,color,link,tooltip,section)
        rows[#rows+1]={title=title,detail=detail or "",color=color or C.white,link=link,tooltip=tooltip,section=section}
    end
    local function Section(title) Add(title,"",C.orange,nil,nil,true) end
    if self.inspectorTab=="FOOD" then
        Section("GROUP FOOD & POTION CHECK")
        for _,player in ipairs(self.roster or {}) do
            local status,color,food=FoodText(player.food)
            local unavailable=player.connected==false and "OFFLINE • " or player.dead and "DEAD • " or ""
            Add(unavailable..Text(player.displayName,"Unknown player").."  •  "..status,food.."\n"..PotionText(player.potion),color,nil,
                "Food presence can be verified independently of a full build. A selected potion is preparation evidence only.")
        end
        if #(self.roster or {})==0 then Add("No group members", "Join a group to review its preparation.",C.muted) end
        return rows
    end
    local player=self:GetInspectedPlayer()
    if not player then
        Add("Choose a player from the group list","Select an @UserID to inspect equipment, both skill bars, Champion Points, Class Masteries and consumables.",C.gold)
        return rows
    end
    local details,status
    if self.GetPlayerBuildDetails then details,status=self:GetPlayerBuildDetails(PlayerKey(player))
    elseif player.unitTag=="player" then details=self.localSnapshot end
    Add(Text(player.displayName,"Unknown player"),ClassName(player)..(player.connected==false and " • Offline" or ""),C.orange)
    if not details then
        Add("Detailed build unavailable",(self.inspectorRequestKey==PlayerKey(player) and self.inspectorRequestError) or status or "This player has not shared a compatible build snapshot. ESO does not expose their equipment or skill bars to other group members.",C.gold)
        local foodStatus,color,food=FoodText(player.food); Add("Food • "..foodStatus,food,color)
        Add("Potion",PotionText(player.potion),C.muted)
        if player.connected~=false then
            local sharedSets=player.externalSets
            if sharedSets and sharedSets.sessionValid==true and sharedSets.fresh==true then
                Section("SHARED SET COUNTS • LAST REPORTED")
                do
                    local knownBars=sharedSets.knownBars or {}
                    local function Count(value,known)
                        return known==true and type(value)=="number" and tostring(value) or "unknown"
                    end
                    local barStatus={}
                    for _,bar in ipairs({{"body","Body & jewelry"},{"front","Front bar"},{"back","Back bar"}}) do
                        barStatus[#barStatus+1]=bar[2]..": "..(knownBars[bar[1]] and "reported" or "unknown")
                    end
                    local ageText="Report age unavailable"
                    if SC.NowMs and type(sharedSets.updatedAt)=="number" then
                        local age=math.max(0,SC.NowMs()-sharedSets.updatedAt)
                        if age==age and age<math.huge then
                            if age<10000 then ageText="Last report: just now"
                            elseif age<60000 then ageText="Last report: "..math.floor(age/1000).." seconds ago"
                            elseif age<3600000 then ageText="Last report: "..math.floor(age/60000).." minutes ago"
                            else ageText="Last report: "..math.floor(age/3600000).." hours ago" end
                        end
                    end
                    Add("LibSetDetection • "..ageText,table.concat(barStatus," • ").."\nThis library reports changes during the current group session. Set counts do not prove an active proc or reveal equipment slots, traits or glyphs.",C.muted)
                    if sharedSets.incognito then
                        Add("Some set information is private","Only sets explicitly disclosed by this player are shown. Other set names or counts are unavailable.",C.gold)
                    end
                    for _,set in ipairs(sharedSets.setList or {}) do
                        local counts="Body & jewelry: "..Count(set.bodyCount,knownBars.body)
                            .." • Front weapon pieces: "..Count(set.frontWeaponCount,knownBars.front)
                            .." • Back weapon pieces: "..Count(set.backWeaponCount,knownBars.back)
                        counts=counts.."\nFront total: "..Count(set.mainCount,set.frontKnown).." • Back total: "..Count(set.backCount,set.backKnown)
                        local active={}
                        if set.frontKnown and set.activeOnMain then active[#active+1]="front" end
                        if set.backKnown and set.activeOnBack then active[#active+1]="back" end
                        if #active>0 then counts=counts.."\nQualifying set bonus reported on "..table.concat(active," + ").." bar." end
                        Add(Text(set.name,"Set name unavailable"),counts,C.white)
                    end
                    if #(sharedSets.setList or {})==0 then
                        Add("No disclosed set counts",sharedSets.complete and "The complete report contains no named set bonuses." or "The available report is incomplete or private; missing sets cannot be ruled out.",C.muted)
                    end
                end
            end
            local ultimates={}
            for _,ultimate in ipairs(player.externalUltimates or {}) do
                if (ultimate.bar=="front" or ultimate.bar=="back") and FreshSharedSample(ultimate.updatedAt) then
                    ultimates[ultimate.bar]=ultimate
                end
            end
            if next(ultimates) then
                Section("SHARED ULTIMATES • PARTIAL")
                for _,bar in ipairs({{"front","Front bar ultimate"},{"back","Back bar ultimate"}}) do
                    local ultimate=ultimates[bar[1]]
                    Add(bar[2],ultimate and (Text(ultimate.name,"Ultimate name unavailable").."\nLibGroupCombatStats • reported ultimate slot")
                        or "UNKNOWN • no fresh ultimate slot was reported for this bar.",ultimate and C.white or C.muted)
                end
            end
            local lines=player.externalSkillLines
            if lines and FreshSharedSample(lines.updatedAt) and #(lines.names or {})>0 then
                Section("SHARED CLASS SKILL LINES • PARTIAL")
                local names={};for _,name in ipairs(lines.names) do names[#names+1]=Text(name,"Skill line name unavailable") end
                Add(table.concat(names," • "),"LibGroupCombatStats • reported class skill lines only. This does not reveal slotted skills, learned passives or Class Mastery selections.",C.white)
            end
        end
        Section("AVAILABLE SUPPORT SOURCES")
        for _,key in ipairs(self.Catalog:GetAllEffectKeys()) do
            if player.capabilities and player.capabilities[key] then
                Add(self.Catalog.effects[key].label,UI.PlayerSources(player,key),C.white,nil,self.Catalog:GetEffectTooltip(key))
            end
        end
        return rows
    end
    if status and status~="" then Add("Build snapshot",status,C.muted) end
    Section("EQUIPMENT • FEET TO HEAD")
    local equipment=details.equipment or {}
    local slots=equipment.slots
    if not slots or #slots==0 then
        if #(equipment.items or {})==0 then Add("Equipment unavailable","No detailed equipment was shared.",C.muted) end
        slots={}
        for _,item in ipairs(equipment.items or {}) do slots[#slots+1]={item=item,slotName=item.slotName or "Equipment",known=true} end
    end
    for _,slot in ipairs(slots) do
        local item=slot.item
        local label=Text(slot.slotName,"Equipment")
        if slot.known==false then Add(label,"UNKNOWN • this slot could not be read.",C.muted)
        elseif slot.empty or not item then Add(label,"Empty",C.gold)
        else
            local name=Text(item.name,"Item name unavailable")
            local parts={Text(item.setName,"No set bonus"),"Trait: "..Text(item.traitName)}
            if item.hasEnchant==false then parts[#parts+1]="Glyph: missing"
            elseif item.hasEnchant==true then parts[#parts+1]="Glyph: "..Text(item.enchantName,Text(item.enchant,"Present"))
            else parts[#parts+1]="Glyph: unknown" end
            Add(label.." • "..name,table.concat(parts,"  •  "),item.hasEnchant==false and C.gold or C.white,item.link,
                item.enchantDescription and item.enchantDescription~="" and item.enchantDescription or nil)
        end
    end
    Section("SET BONUSES • FRONT / BACK")
    for _,set in ipairs(equipment.setList or {}) do
        local main,back=tonumber(set.mainCount),tonumber(set.backCount)
        local count="Front: "..(main and tostring(main) or "unknown").." pieces  •  Back: "..(back and tostring(back) or "unknown").." pieces"
        local active={}; if set.activeOnMain then active[#active+1]="front" end; if set.activeOnBack then active[#active+1]="back" end
        Add(Text(set.name,"Set name unavailable"),count..(#active>0 and ("\nQualifying bonus available on "..table.concat(active," + ").." bar.") or "\nPiece counts do not prove a proc is active."))
    end
    local skills=details.skills or {}
    for _,bar in ipairs({{"primary","FRONT BAR SKILLS"},{"backup","BACK BAR SKILLS"}}) do
        Section(bar[2])
        local entries=skills[bar[1]] or {}
        if #entries==0 then Add("Skill bar unavailable",skills.known and "No skills are slotted." or "Skill slots were not shared or could not be read.",C.muted) end
        for index,skill in ipairs(entries) do
            local position=tonumber(skill.slot)
            position=position and position>=3 and position<=7 and position-2 or index
            local scripts={}
            for _,script in ipairs(skill.scripts or {}) do scripts[#scripts+1]=Text(script.name,"Script unavailable") end
            local detail=Text(skill.lineName,"Skill line unavailable")
            if #scripts>0 then detail=detail.."\nScripts: "..table.concat(scripts," • ") end
            Add((skill.ultimate and "Ultimate • " or "Skill "..position.." • ")..Text(skill.name,"Skill name unavailable"),detail,C.white,nil,skill.description)
        end
    end
    Section("CHAMPION SLOTTABLES")
    local disciplineNames={COMBAT="Warfare",CONDITIONING="Fitness",WORLD="Craft"}
    local stars=skills.champion or {}
    if #stars==0 then Add("Champion Points unavailable",skills.championKnown and "No Champion stars are slotted." or "Champion selections were not shared or could not be read.",C.muted) end
    for _,star in ipairs(stars) do
        Add(Text(star.name,"Champion star name unavailable"),(disciplineNames[star.discipline] or "Discipline unavailable").." • "..(star.points and tostring(star.points).." committed points" or "Points unavailable"),C.white,nil,star.description)
    end
    Section("CLASS MASTERIES & SKILL LINES")
    local masteries=details.masteries or {}
    if masteries.known~=true then Add("Class Masteries incomplete","Some committed mastery or prerequisite information is unavailable.",C.gold)
    elseif masteries.eligible==false then Add("Class Masteries inactive","The current class skill line selection does not meet mastery eligibility.",C.gold) end
    if #(masteries.selected or {})==0 then Add("No selected masteries",masteries.known and "No committed Class Mastery selection was detected." or "Mastery selections have not been verified.",C.muted) end
    for _,mastery in ipairs(masteries.selected or {}) do Add(Text(mastery.name,"Mastery name unavailable"),masteries.eligible and "Committed selection • eligibility met" or "Committed selection • eligibility not confirmed",C.white,nil,mastery.description) end
    for _,line in ipairs(masteries.skillLines or {}) do
        if not line.mastery then Add(Text(line.name,"Skill line unavailable"),line.active==false and "Inactive skill line" or (line.native==false and "Active subclass skill line" or "Active class skill line"),C.muted) end
    end
    if #(masteries.passives or {})>0 then
        Section("COMMITTED CLASS PASSIVES")
        for _,passive in ipairs(masteries.passives) do Add(Text(passive.name,"Passive name unavailable"),Text(passive.lineName,"Purchased class passive"),C.white,nil,passive.description) end
    end
    Section("CONSUMABLES & MUNDUS")
    local foodStatus,color,food=FoodText(player.food or details.food); Add("Food • "..foodStatus,food,color)
    local currentPotion=player.potion or details.potion
    local potion,potionColor=PotionText(currentPotion); Add("Selected potion",potion,potionColor,currentPotion and currentPotion.link)
    local mundus=details.mundus or {}
    Add("Mundus",#(mundus.names or {})>0 and table.concat(mundus.names," • ") or (mundus.known and "No Mundus detected" or "Mundus unavailable"),C.muted)
    return rows
end

function SC:RefreshInspector()
    local win=self.inspectorWindow
    if not win or win:IsHidden() then return end
    local width=UI.FitWindow(win); local foodMode=self.inspectorTab=="FOOD"
    win.title:SetText("Ąlpha Şquad UI  •  "..(foodMode and "Food check" or "Builds"))
    win.subtitle:SetText(foodMode and "Check food presence and the selected potion for every player before combat." or "Select an @UserID • inspect an on-demand snapshot • hover items, skills and stars for details")
    UI.Color(win.buildTab.label,not foodMode and C.orange or C.muted); UI.Color(win.foodTab.label,foodMode and C.orange or C.muted)
    win.request:SetHidden(foodMode or not self:GetInspectedPlayer())
    local playerWidth=width<850 and 178 or 226
    win.playerList:SetWidth(playerWidth)
    win.playerList:SetHidden(foodMode)
    win.detailList:ClearAnchors(); win.detailList:SetAnchor(TOPLEFT,win,TOPLEFT,foodMode and 18 or playerWidth+32,146)
    win.detailList:SetAnchor(BOTTOMRIGHT,win,BOTTOMRIGHT,-16,-64)
    local detailWidth=width-(foodMode and 64 or playerWidth+78)
    local roster=self.roster or {}
    if not foodMode then
        for index,player in ipairs(roster) do
            local row=win.playerList.rows[index]
            if not row then
                row=UI.Button(win.playerList.content,"AlphaSquadInspectorPlayer"..index,"",playerWidth-22,54,function(button)
                    SC.inspectorPlayerKey=PlayerKey(button.player)
                    if SC.RequestPlayerBuild then SC:RequestInspectedBuild(SC.inspectorPlayerKey) end
                    local scroll=win.detailList.viewport
                    if scroll then scroll.offset=0; scroll.UpdateBounds() end
                    SC:RefreshInspector()
                end)
                row.label:ClearAnchors(); row.label:SetAnchor(TOPLEFT,row,TOPLEFT,6,2); row.label:SetHeight(27)
                row.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
                row.detail=UI.Label(row,"AlphaSquadInspectorPlayerDetail"..index,"","ZoFontGameSmall",C.muted)
                row.detail:SetAnchor(TOPLEFT,row,TOPLEFT,6,29); row.detail:SetHeight(22)
                win.playerList.rows[index]=row
            end
            row.player=player; row:SetHidden(false); row:ClearAnchors(); row:SetAnchor(TOPLEFT,win.playerList.content,TOPLEFT,0,(index-1)*59)
            row:SetWidth(playerWidth-22); row.label:SetWidth(playerWidth-34); row.detail:SetWidth(playerWidth-34)
            row.label:SetText(UI.Text(player.displayName or "Unknown player"))
            UI.Color(row.label,PlayerKey(player)==self.inspectorPlayerKey and C.orange or C.white)
            local foodStatus,foodColor=FoodText(player.food)
            row.detail:SetText(player.connected==false and "OFFLINE" or foodStatus); UI.Color(row.detail,player.connected==false and C.muted or foodColor)
        end
        for index=#roster+1,#win.playerList.rows do win.playerList.rows[index]:SetHidden(true); win.playerList.rows[index].player=nil end
        UI.FinishScroll(win.playerList,#roster*59,playerWidth-22)
    end
    local rows=self:GetInspectorRows(); local offset=0
    for index,data in ipairs(rows) do
        local row=win.detailList.rows[index]
        if not row then
            local name="AlphaSquadInspectorDetail"..index
            row=WINDOW_MANAGER:CreateControl(name,win.detailList.content,CT_CONTROL)
            row.bg=UI.Solid(row,name.."BG",C.panel)
            row.title=UI.Label(row,name.."Title","","ZoFontGameBold")
            row.title:SetAnchor(TOPLEFT,row,TOPLEFT,10,4); row.title:SetVerticalAlignment(TEXT_ALIGN_TOP)
            row.detail=UI.Label(row,name.."Detail","","ZoFontGameSmall",C.muted)
            row.detail:SetVerticalAlignment(TEXT_ALIGN_TOP)
            row:SetMouseEnabled(true)
            row:SetHandler("OnMouseWheel",UI.ForwardWheel)
            row:SetHandler("OnMouseEnter",function()
                local d=row.data
                if not d then return end
                if d.link and d.link~="" and ItemTooltip and InitializeTooltip then
                    InitializeTooltip(ItemTooltip,row,TOPLEFT,8,0,TOPRIGHT)
                    if ItemTooltip.SetLink then ItemTooltip:SetLink(d.link) end
                elseif d.tooltip and d.tooltip~="" then UI.Tooltip(row,d.tooltip)
                elseif d.detail and d.detail~="" then UI.Tooltip(row,d.title.."\n\n"..d.detail) end
            end)
            row:SetHandler("OnMouseExit",UI.ClearTooltip); win.detailList.rows[index]=row
        end
        row.data=data; row:SetHidden(false); row.title:SetWidth(detailWidth-20); row.detail:SetWidth(detailWidth-20)
        row.title:SetText(UI.Text(data.title)); row.detail:SetText(UI.Text(data.detail)); UI.Color(row.title,data.color)
        local titleHeight=math.max(25,row.title:GetTextHeight() or 25)
        row.title:SetHeight(titleHeight)
        row.detail:ClearAnchors(); row.detail:SetAnchor(TOPLEFT,row,TOPLEFT,10,titleHeight+5)
        local detailHeight=data.section and 0 or math.max(23,row.detail:GetTextHeight() or 23)
        row.detail:SetHeight(detailHeight); row.detail:SetHidden(data.section==true)
        local height=titleHeight+detailHeight+12
        row:ClearAnchors(); row:SetAnchor(TOPLEFT,win.detailList.content,TOPLEFT,0,offset); row:SetDimensions(detailWidth,height)
        offset=offset+height+6
    end
    for index=#rows+1,#win.detailList.rows do win.detailList.rows[index]:SetHidden(true); win.detailList.rows[index].data=nil end
    UI.FinishScroll(win.detailList,offset,detailWidth)
end
-- Legacy callers may close an old view during migration; reports are no longer created.
function SC:ClosePullReport() if self.reportWindow then self.reportWindow:SetHidden(true) end end
function SC:OpenPullReport() return false end
function SC:RefreshPullReport() end
