-- Compact character sheet. Every tile is rebound from one immutable build snapshot.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,C=SC.UI,SC.UI.colors
local View={};SC.BuildView=View
local WIDTH,HEIGHT=830,502
local function Text(value,fallback)
    if type(value)=="string" and value~="" then return value:gsub("%^.*$","") end
    return fallback or "Unknown"
end
local function Try(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function Number(value)
    return type(value)=="number" and value==value and value>=0 and value<math.huge and value or nil
end
local function At(control,parent,x,y,w,h)
    control:ClearAnchors();control:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);control:SetDimensions(w,h)
end
local function Label(parent,name,text,x,y,w,h,font,color)
    local label=UI.Label(parent,name,UI.Text(text),font or "ZoFontGameSmall",color or C.white)
    At(label,parent,x,y,w,h)
    if label.SetWrapMode then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
    return label
end
local function Panel(parent,name,x,y,w,h,title)
    local panel=WINDOW_MANAGER:CreateControl(name,parent,CT_CONTROL);At(panel,parent,x,y,w,h)
    panel.bg=UI.Solid(panel,name.."BG",C.panel)
    panel.title=Label(panel,name.."Title",title,12,5,w-24,22,"ZoFontGameBold",C.orange)
    return panel
end
local function Icon(parent,name,x,y,size,label)
    local tile=WINDOW_MANAGER:CreateControl(name,parent,CT_CONTROL);At(tile,parent,x,y,size,size)
    tile.frame=UI.Solid(tile,name.."Frame",C.muted)
    tile.inner=WINDOW_MANAGER:CreateControl(name.."Inner",tile,CT_TEXTURE)
    At(tile.inner,tile,2,2,size-4,size-4);tile.inner:SetColor(0.035,0.04,0.05,1)
    tile.icon=WINDOW_MANAGER:CreateControl(name.."Icon",tile,CT_TEXTURE)
    At(tile.icon,tile,3,3,size-6,size-6)
    tile.empty=Label(tile,name.."Empty","?",2,2,size-4,size-4,"ZoFontGameBold",C.muted)
    tile.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    tile.badge=Label(tile,name.."Badge","",0,size-17,size-3,17,"ZoFontGameSmall",C.white)
    tile.badge:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    if label then tile.caption=Label(parent,name.."Caption",label,x-13,y+size+1,size+26,19,nil,C.muted);tile.caption:SetHorizontalAlignment(TEXT_ALIGN_CENTER) end
    local sheet=parent
    while sheet and not sheet.isBuildSheet do sheet=sheet:GetParent() end
    tile.ownerSheet=sheet
    tile:SetMouseEnabled(true)
    tile:SetHandler("OnMouseEnter",function()
        local data=tile.data
        if not data then return end
        if data.kind=="item" and data.value and UI.ItemTooltip then UI.ItemTooltip(tile,data.value,tile.ownerSheet and tile.ownerSheet.isRemote)
        elseif data.kind=="skill" and data.value and UI.SkillTooltip then UI.SkillTooltip(tile,data.value,tile.ownerSheet and tile.ownerSheet.isRemote)
        elseif data.kind=="champion" and data.value and UI.ChampionTooltip then UI.ChampionTooltip(tile,data.value)
        else UI.Tooltip(tile,data.tooltip or "Information unavailable") end
    end)
    tile:SetHandler("OnMouseExit",UI.ClearTooltip)
    return tile
end
local function Bind(tile,kind,value,tooltip,empty,color,badge)
    tile.data={kind=kind,value=value,tooltip=tooltip}
    local texture=value and value.icon
    if (not texture or texture=="") and kind=="item" and value and value.link then texture=Try(GetItemLinkIcon,value.link) end
    if (not texture or texture=="") and kind=="skill" and value then texture=Try(GetAbilityIcon,value.abilityId or value.id or 0) end
    if (not texture or texture=="") and kind=="champion" and value then texture=Try(GetAbilityIcon,Try(GetChampionAbilityId,value.id or 0) or 0) end
    local hasTexture=type(texture)=="string" and texture~=""
    tile.icon:SetHidden(not hasTexture);tile.icon:SetTexture(hasTexture and texture or "")
    tile.icon:SetColor(1,1,1,1);tile.empty:SetHidden(hasTexture);tile.empty:SetText(empty or "?")
    tile.badge:SetText(badge or "");UI.Color(tile.frame,color or (value and C.gold or C.muted))
end
local EQUIPMENT={
    {"HEAD","Head",101,32},
    {"SHOULDERS","Shoulders",18,101},{"CHEST","Chest",184,101},
    {"HAND","Hands",18,165},{"WAIST","Waist",184,165},
    {"LEGS","Legs",18,229},{"FEET","Feet",184,229},
    {"NECK","Necklace",34,326},{"RING1","Ring 1",101,326},{"RING2","Ring 2",168,326},
    {"MAIN_HAND","Main hand",18,421},{"OFF_HAND","Off hand",76,421},
    {"BACKUP_MAIN","Main hand",145,421},{"BACKUP_OFF","Off hand",203,421},
}
View.EquipmentPositions=EQUIPMENT
local DISCIPLINES={{"COMBAT","Warfare",{0.32,0.66,1,1}},{"CONDITIONING","Fitness",{1,0.38,0.35,1}},{"WORLD","Craft",{0.40,0.80,0.45,1}}}
local function SourceAge(updatedAt)
    if not Number(updatedAt) or not SC.NowMs then return "Report age unavailable" end
    local age=math.max(0,SC.NowMs()-updatedAt)
    if age<10000 then return "Last reported just now" end
    if age<60000 then return "Last reported "..math.floor(age/1000).."s ago" end
    return "Last reported "..math.floor(age/60000).."m ago"
end
local function Fresh(updatedAt)
    if not Number(updatedAt) or not SC.NowMs then return false end
    local age=SC.NowMs()-updatedAt;return age>=0 and age<=75000
end
function View.EquipmentMap(equipment)
    local map={}
    for _,slot in ipairs(equipment and equipment.slots or {}) do
        local key=slot.slotKey or (SC.EquipmentSlotDetails[slot.slot] or {}).slotKey
        if key then map[key]=slot end
    end
    for _,item in ipairs(equipment and equipment.items or {}) do
        local key=item.slotKey or (SC.EquipmentSlotDetails[item.slot] or {}).slotKey
        if key and not map[key] then map[key]={slotKey=key,item=item,known=true} end
    end
    return map
end
function View.SkillMap(entries)
    local map={}
    for _,skill in ipairs(entries or {}) do
        local slot=Number(skill.slot)
        if skill.ultimate then map[6]=skill
        elseif slot and slot>=3 and slot<=7 and slot%1==0 then map[slot-2]=skill end
    end
    return map
end
function View.ChampionMap(stars)
    local map={COMBAT={},CONDITIONING={},WORLD={}}
    local layout=SC.GetChampionSlotLayout and SC:GetChampionSlotLayout()
    if not layout then return map,false end
    for _,star in ipairs(stars or {}) do
        local position=layout[star.slot]
        local group=position and map[position.discipline]
        if group and position.discipline==star.discipline and position.index>=1 and position.index<=4 then
            group[position.index]=star
        end
    end
    return map,true
end
function View.SetRows(equipment,external)
    local rows={}
    for _,set in ipairs(equipment and equipment.setList or external and external.setList or {}) do
        local mainKnown=external and set.frontKnown==true or not external and equipment and equipment.complete==true
        local backKnown=external and set.backKnown==true or not external and equipment and equipment.complete==true
        local front=mainKnown and Number(set.mainCount) or nil
        local back=backKnown and Number(set.backCount) or nil
        local physical=not external and set.physicalCountKnown==true and Number(set.physicalCount) or nil
        local name=Text(set.name,"Set name unavailable")
        local count=physical and (tostring(physical).."× ") or ""
        local tooltip=name.."\n\n"..(physical and (physical.." equipped item"..(physical==1 and "" or "s").." across body, jewelry and both weapon bars.\n") or "Exact equipment slots and item count were not shared.\n")
            .."Front bar: "..(front and tostring(front) or "unknown").." set pieces\nBack bar: "..(back and tostring(back) or "unknown").." set pieces\n\nTwo-handed weapons are one item and contribute two set pieces. Counts are evaluated separately on each bar; a proc is not guaranteed active."
        if external then tooltip=tooltip.."\n\nLibSetDetection • "..SourceAge(external.updatedAt)..". This report is retained for the current uninterrupted group session. The player may withhold sets." end
        rows[#rows+1]={name=count..name,front=front,back=back,tooltip=tooltip,physical=physical}
    end
    table.sort(rows,function(a,b)
        local ac,bc=math.max(a.front or 0,a.back or 0),math.max(b.front or 0,b.back or 0)
        if ac~=bc then return ac>bc end
        return a.name<b.name
    end)
    return rows
end
function View.Create(parent)
    local canvas=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSheet",parent,CT_CONTROL)
    canvas:SetDimensions(WIDTH,HEIGHT);canvas.isBuildSheet=true
    canvas.equipment=Panel(canvas,"AlphaSquadBuildEquipment",0,0,266,HEIGHT,"EQUIPPED")
    local gear=canvas.equipment
    gear.silhouette=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSilhouette",gear,CT_TEXTURE)
    At(gear.silhouette,gear,99,99,72,195);gear.silhouette:SetColor(0.65,0.61,0.47,0.68)
    gear.slots={}
    for index,def in ipairs(EQUIPMENT) do
        local caption=index>10 and (index%2==1 and "Main" or "Off") or def[2]
        gear.slots[def[1]]=Icon(gear,"AlphaSquadBuildSlot"..def[1],def[3],def[4],44,caption)
    end
    Label(gear,"AlphaSquadBuildJewelry","JEWELRY",12,298,242,24,"ZoFontGameBold",C.orange)
    Label(gear,"AlphaSquadBuildFrontWeapons","FRONT WEAPONS",12,389,121,24,"ZoFontGameSmall",C.orange)
    Label(gear,"AlphaSquadBuildBackWeapons","BACK WEAPONS",142,389,118,24,"ZoFontGameSmall",C.orange)
    gear.glyphs=Label(gear,"AlphaSquadBuildGlyphCheck","",102,5,152,22,"ZoFontGameSmall",C.muted)
    gear.glyphs:SetHorizontalAlignment(TEXT_ALIGN_RIGHT);UI.Hover(gear.glyphs,function()return gear.glyphTooltip end)
    canvas.sets=Panel(canvas,"AlphaSquadBuildSets",278,0,552,124,"SETS")
    canvas.sets.front=Label(canvas.sets,"AlphaSquadBuildSetFront","FRONT",398,5,60,22,nil,C.muted)
    canvas.sets.back=Label(canvas.sets,"AlphaSquadBuildSetBack","BACK",478,5,60,22,nil,C.muted)
    canvas.sets.rows={}
    for i=1,4 do
        local row=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSetRow"..i,canvas.sets,CT_CONTROL)
        At(row,canvas.sets,12,27+(i-1)*22,526,22)
        row.name=Label(row,"AlphaSquadBuildSetName"..i,"",0,0,374,22)
        row.front=Label(row,"AlphaSquadBuildSetFront"..i,"",386,0,60,22,"ZoFontGameBold",C.gold)
        row.back=Label(row,"AlphaSquadBuildSetBack"..i,"",466,0,60,22,"ZoFontGameBold",C.gold)
        UI.Hover(row,function()return row.tooltip end);canvas.sets.rows[i]=row
    end
    canvas.skills=Panel(canvas,"AlphaSquadBuildSkills",278,136,552,150,"SKILL BARS")
    canvas.skills.bars={}
    for row,bar in ipairs({{"primary","FRONT"},{"backup","BACK"},{"werewolf","WEREWOLF"}}) do
        local group=WINDOW_MANAGER:CreateControl("AlphaSquadBuildBar"..row,canvas.skills,CT_CONTROL)
        At(group,canvas.skills,12,30+(row-1)*39,526,38)
        group.title=Label(group,"AlphaSquadBuildBarTitle"..row,bar[2],0,0,92,38,nil,C.muted)
        group.icons={}
        for i=1,6 do group.icons[i]=Icon(group,"AlphaSquadBuildSkill"..row.."_"..i,98+(i-1)*68,0,36)
            group.icons[i].slotNumber=Label(group,"AlphaSquadBuildSkillSlot"..row.."_"..i,i==6 and "ULT" or tostring(i),137+(i-1)*68,8,27,22,nil,i==6 and C.orange or C.muted)
        end
        canvas.skills.bars[bar[1]]=group
    end
    canvas.champion=Panel(canvas,"AlphaSquadBuildChampion",278,298,552,84,"CHAMPION POINTS")
    canvas.champion.rows={}
    for row,discipline in ipairs(DISCIPLINES) do
        local x=12+(row-1)*178
        local group={icons={}}
        group.label=Label(canvas.champion,"AlphaSquadBuildChampionLabel"..row,discipline[2],x,26,160,19,nil,discipline[3])
        for i=1,4 do group.icons[i]=Icon(canvas.champion,"AlphaSquadBuildStar"..row.."_"..i,x+(i-1)*41,46,30) end
        canvas.champion.rows[discipline[1]]=group
    end
    canvas.masteries=Panel(canvas,"AlphaSquadBuildMasteries",278,394,552,48,"MASTERIES")
    canvas.masteries.icons={}
    UI.Hover(canvas.masteries.title,function()return canvas.masteries.eligibilityTooltip end)
    for i=1,7 do canvas.masteries.icons[i]=Icon(canvas.masteries,"AlphaSquadBuildMastery"..i,120+(i-1)*40,8,32) end
    canvas.masteries.passives=Label(canvas.masteries,"AlphaSquadBuildPassives","",411,4,129,21,nil,C.muted)
    canvas.masteries.lines=Label(canvas.masteries,"AlphaSquadBuildClassLines","",411,24,129,21,nil,C.muted)
    UI.Hover(canvas.masteries.passives,function()return canvas.masteries.passiveTooltip end)
    UI.Hover(canvas.masteries.lines,function()return canvas.masteries.lineTooltip end)
    canvas.masteries.empty=Label(canvas.masteries,"AlphaSquadBuildMasteryEmpty","",120,8,274,32,nil,C.muted)
    canvas.consumables=WINDOW_MANAGER:CreateControl("AlphaSquadBuildConsumables",canvas,CT_CONTROL)
    At(canvas.consumables,canvas,278,454,552,48)
    canvas.consumables.tiles={}
    for i,caption in ipairs({"FOOD","POTION","MUNDUS","AFFLICTION"}) do
        local tile=Panel(canvas.consumables,"AlphaSquadBuildReady"..i,(i-1)*140,0,i==4 and 132 or 132,48,caption)
        tile.title:SetFont("ZoFontGameSmall");At(tile.title,tile,7,2,116,18)
        tile.value=Label(tile,"AlphaSquadBuildReadyValue"..i,"Unknown",i<=3 and 39 or 7,21,i<=3 and 85 or 117,22,"ZoFontGameSmall",C.muted)
        if i<=3 then tile.icon=Icon(tile,"AlphaSquadBuildReadyIcon"..i,7,21,22) end
        UI.Hover(tile,function()return tile.tooltip end)
        canvas.consumables.tiles[i]=tile
    end
    canvas.state=Label(canvas,"AlphaSquadBuildUnavailable","",278,45,540,62,"ZoFontGameSmall",C.muted)
    canvas:SetHidden(true)
    return canvas
end
function View.Bind(canvas,player,details,status)
    if canvas.snapshot~=details or canvas.player~=player then UI.ClearTooltip() end
    canvas.isRemote=player~=nil and player.unitTag~="player" and Try(AreUnitsEqual,player.unitTag,"player")~=true
    local equipment=details and details.equipment or nil
    local skills=details and details.skills or {}
    local map=View.EquipmentMap(equipment)
    local silhouette=player and player.unitTag and Try(GetUnitSilhouetteTexture,player.unitTag)
    canvas.equipment.silhouette:SetHidden(not silhouette or silhouette=="")
    canvas.equipment.silhouette:SetTexture(silhouette or "")
    local missingGlyphs,unknownGlyphs=0,0
    for _,def in ipairs(EQUIPMENT) do
        local slot=map[def[1]];local item=slot and slot.known~=false and not slot.empty and slot.item
        local known=slot and slot.known==true
        local tooltip=def[2].."\n\n"..(known and "No item equipped in this slot." or "This equipment slot has not been shared or verified.")
        local color=C.muted
        if item then
            color=C.gold
            if GetItemQualityColor and item.quality then
                local quality=Try(GetItemQualityColor,item.quality)
                if quality and quality.UnpackRGBA then local ok,r,g,b,a=pcall(quality.UnpackRGBA,quality);if ok then color={r,g,b,a or 1} end end
            end
            if item.hasEnchant==false then missingGlyphs=missingGlyphs+1 elseif item.hasEnchant==nil then unknownGlyphs=unknownGlyphs+1 end
        end
        Bind(canvas.equipment.slots[def[1]],"item",item,tooltip,known and "—" or "?",color,item and item.hasEnchant==false and "!" or "")
        if not item then
            local nativeSlot=rawget(_G,"EQUIP_SLOT_"..def[1])
            local texture=nativeSlot and Try(ZO_Character_GetEmptyEquipSlotTexture,nativeSlot)
            if type(texture)=="string" and texture~="" then
                local tile=canvas.equipment.slots[def[1]]
                tile.icon:SetTexture(texture);tile.icon:SetHidden(false);tile.icon:SetColor(0.6,0.6,0.6,0.5)
                tile.empty:SetHidden(known==true)
            end
        end
        local pairedKey=def[1]=="OFF_HAND" and "MAIN_HAND" or def[1]=="BACKUP_OFF" and "BACKUP_MAIN"
        local main=pairedKey and map[pairedKey] and map[pairedKey].item
        if not item and known and main and main.twoHanded==true then
            Bind(canvas.equipment.slots[def[1]],"info",nil,"Two-handed weapon\n\n"..Text(main.name,"Main-hand weapon").." occupies both hands. This is one equipped item, not a second weapon. Hover the main-hand slot for its exact trait and enchantment.","2H",C.muted)
        end
    end
    local glyphVerified=equipment and equipment.glyphs and equipment.glyphs.verified==true
    local glyphText=not equipment and "Glyphs unknown" or missingGlyphs>0 and (missingGlyphs.." missing glyph"..(missingGlyphs==1 and "" or "s")) or glyphVerified and unknownGlyphs==0 and "Glyphs checked" or "Glyphs incomplete"
    canvas.equipment.glyphs:SetText(glyphText);UI.Color(canvas.equipment.glyphs,missingGlyphs>0 and C.gold or glyphVerified and C.green or C.muted)
    canvas.equipment.glyphTooltip="Glyph check\n\n"..glyphText..". Hover an equipment slot for that item's exact trait and enchantment. Poison overrides and remaining weapon charges are shown when available."
    local external=not details and player and player.connected~=false and player.externalSets
    if not (external and external.sessionValid and external.fresh) then external=nil end
    local rows=View.SetRows(equipment,external)
    canvas.sets.title:SetText(external and "SETS • LAST REPORTED" or "SETS • EQUIPPED ITEMS")
    for i,row in ipairs(canvas.sets.rows) do
        local data=rows[i]
        row:SetHidden(not data)
        if data then
            if i==4 and #rows>4 then
                local all={"Additional equipped sets"};for index=4,#rows do
                    local extra=rows[index]
                    all[#all+1]=extra.name.." • Front "..(extra.front and tostring(extra.front) or "?").." / Back "..(extra.back and tostring(extra.back) or "?")
                end
                all[#all+1]="Names count physical items when known; bar totals count set pieces. A two-handed weapon is one item worth two set pieces."
                row.name:SetText(UI.Text("+ "..(#rows-3).." more sets • hover to inspect"));row.front:SetText("");row.back:SetText("");row.tooltip=table.concat(all,"\n\n")
            else row.name:SetText(UI.Text(data.name));row.front:SetText(data.front and tostring(data.front).."×" or "?");row.back:SetText(data.back and tostring(data.back).."×" or "?");row.tooltip=data.tooltip end
        else row.tooltip=nil end
    end
    canvas.state:SetHidden(#rows>0)
    local setState=details and (equipment and equipment.complete and "No equipped set items." or "Set information is incomplete.") or Text(status,"Request a shared build to inspect equipment, skills and Champion Points.")
    if external and #rows==0 then setState=external.incognito and "The player has kept their set information private." or "No named sets were disclosed." end
    canvas.state:SetText(UI.Text(setState))
    local externalUlts={}
    if not details and player and player.connected~=false then
        for _,ultimate in ipairs(player.externalUltimates or {}) do
            if Fresh(ultimate.updatedAt) then externalUlts[ultimate.bar=="front" and "primary" or ultimate.bar=="back" and "backup" or "invalid"]=ultimate end
        end
    end
    local curse=details and details.curse or {}
    local showWerewolf=(skills.werewolfKnown==true and #(skills.werewolf or {})>0) or curse.kind=="WEREWOLF"
    for _,bar in ipairs({"primary","backup","werewolf"}) do
        local group=canvas.skills.bars[bar];local barMap=View.SkillMap(skills[bar])
        if not details and externalUlts[bar] then barMap[6]=externalUlts[bar] end
        local known=bar=="werewolf" and skills.werewolfKnown==true or bar~="werewolf" and skills.known==true
        local highlight=bar=="werewolf" and curse.transformed==true
        group:SetHidden(bar=="werewolf" and not showWerewolf)
        UI.Color(group.title,highlight and C.orange or C.muted)
        for i=1,6 do
            local entry=barMap[i]
            Bind(group.icons[i],"skill",entry,(i==6 and "Ultimate" or "Skill "..i).."\n\n"..(known and "No ability is slotted here." or "This ability slot has not been shared."),known and "—" or "?",entry and (i==6 and C.orange or C.gold) or C.muted)
        end
    end
    local champion,championLayoutKnown=View.ChampionMap(skills.champion)
    local championKnown=skills.championKnown==true and championLayoutKnown
    for _,discipline in ipairs(DISCIPLINES) do
        local group=canvas.champion.rows[discipline[1]]
        for i=1,4 do
            local star=champion[discipline[1]][i]
            Bind(group.icons[i],"champion",star,discipline[2].." Champion slot\n\n"..(championKnown and "No Champion star was reported for this slot." or "Champion selections or their slot positions are unavailable."),championKnown and "—" or "?",star and discipline[3] or C.muted,star and star.pointsKnown==true and Number(star.points) and tostring(star.points) or "")
        end
    end
    local masteries=details and details.masteries or {}
    local selected=masteries.selected or {}
    canvas.masteries.eligibilityTooltip="Class Masteries\n\n"..(masteries.known and (masteries.eligible==true and "The selected masteries meet their class skill-line requirements." or masteries.eligible==false and "These selections are currently inactive: class skill-line requirements are not met." or "Mastery eligibility has not been verified.") or "Mastery selections or eligibility are incomplete.").."\nHover a mastery icon for its ability description."
    canvas.masteries.empty:SetHidden(#selected>0)
    canvas.masteries.empty:SetText(masteries.known and (masteries.eligible==false and "Inactive • class requirements" or "No selected masteries") or "Masteries unavailable")
    for i,tile in ipairs(canvas.masteries.icons) do
        local mastery=selected[i];tile:SetHidden(not mastery)
        if mastery then Bind(tile,"skill",mastery,Text(mastery.name),"?",masteries.eligible==true and C.gold or C.muted) end
    end
    local passiveLines={"Committed class passives"}
    for _,passive in ipairs(masteries.passives or {}) do passiveLines[#passiveLines+1]=Text(passive.name).." • "..Text(passive.lineName,"Class passive")..(Number(passive.rank) and " • rank "..passive.rank or "") end
    canvas.masteries.passiveTooltip=table.concat(passiveLines,"\n\n")
    canvas.masteries.passives:SetText(masteries.known and tostring(#(masteries.passives or {})).." passives • hover" or "Passives unknown")
    local lineNames={}
    for _,line in ipairs(masteries.skillLines or {}) do if not line.mastery and line.active~=false then lineNames[#lineNames+1]=Text(line.name) end end
    local externalLines=not details and player and player.externalSkillLines
    if externalLines and Fresh(externalLines.updatedAt) then for _,name in ipairs(externalLines.names or {}) do lineNames[#lineNames+1]=Text(name) end end
    canvas.masteries.lines:SetText(#lineNames>0 and (#lineNames.." class lines • hover") or "Class lines unknown")
    canvas.masteries.lineTooltip="Active class skill lines\n\n"..(#lineNames>0 and table.concat(lineNames,"\n") or "No verified class skill lines available.")..(externalLines and "\n\nShared class lines do not establish passive or mastery selections." or "")
    local food=details and details.food or player and player.food or {}
    local potion=details and details.potion or player and player.potion or {}
    local mundus=details and details.mundus or {}
    local foodTile,potionTile,mundusTile,curseTile=canvas.consumables.tiles[1],canvas.consumables.tiles[2],canvas.consumables.tiles[3],canvas.consumables.tiles[4]
    foodTile.value:SetText(food.verified and (food.active and "Active" or "No food") or "Unknown")
    UI.Color(foodTile.value,food.verified and (food.active and C.green or C.red) or C.muted)
    Bind(foodTile.icon,"skill",food.verified and food.active and food or nil,"Food information unavailable",food.verified and not food.active and "—" or "?",food.verified and food.active and C.green or C.muted)
    foodTile.tooltip="Food & drink\n\n"..(food.verified and (food.active and Text(food.name,"Food active") or "No active food or drink detected.") or "Food presence has not been verified.")
    potionTile.value:SetText(UI.Text(potion.known and Text(potion.name,"Potion selected") or potion.selectionKnown and "None selected" or "Unknown"))
    UI.Color(potionTile.value,potion.known and C.white or potion.selectionKnown and C.gold or C.muted)
    Bind(potionTile.icon,"item",potion.known and potion or nil,"Selected potion unavailable",potion.selectionKnown and "—" or "?",potion.known and C.gold or C.muted)
    potionTile.tooltip="Selected potion\n\n"..(potion.known and Text(potion.name,"Potion selected")..(Number(potion.count) and "\n"..potion.count.." available" or "") or potion.selectionKnown and "The quickslot does not contain a potion." or "The selected quickslot has not been shared.").."\n\nSelection is preparation evidence, not proof of potion use."
    mundusTile.value:SetText(UI.Text(#(mundus.names or {})>0 and table.concat(mundus.names," + ") or mundus.known and "None" or "Unknown"))
    local mundusId=(mundus.ids or {})[1]
    Bind(mundusTile.icon,"skill",mundusId and {abilityId=mundusId,name=(mundus.names or {})[1],icon=Try(GetAbilityIcon,mundusId)} or nil,"Mundus information unavailable",mundus.known and "—" or "?",mundusId and C.gold or C.muted)
    mundusTile.tooltip="Mundus stones\n\n"..(#(mundus.names or {})>0 and table.concat(mundus.names,"\n") or mundus.known and "No Mundus blessing detected." or "Mundus blessings have not been shared.")
    local curseText=not curse.known and "Unknown" or curse.kind=="VAMPIRE" and ("Vampire"..(Number(curse.stage) and " • "..curse.stage or "")) or curse.kind=="WEREWOLF" and (curse.transformed and "Werewolf • active" or "Werewolf") or "None"
    curseTile.value:SetText(curseText);UI.Color(curseTile.value,curse.transformed and C.orange or C.white)
    curseTile.tooltip="Vampirism & lycanthropy\n\n"..curseText..(curse.kind=="WEREWOLF" and "\nThe werewolf bar is displayed separately; front and back weapon skill bars are preserved." or "")
    canvas.player=player;canvas.snapshot=details
end
