-- Compact character sheet. Every tile is rebound from one immutable build snapshot.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local UI,C=SC.UI,SC.UI.colors
local View={};SC.BuildView=View
local WIDTH,HEIGHT=830,502
local function Text(value,fallback)
    if type(value)=="string" and value~="" then return (value:gsub("%^.*$","")) end
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
    if UI.Surface then UI.Surface(panel,panel.bg,"card") end
    panel.title=Label(panel,name.."Title",title,12,5,w-24,22,"ZoFontGameBold",C.orange)
    return panel
end
local function Icon(parent,name,x,y,size,label)
    local tile=WINDOW_MANAGER:CreateControl(name,parent,CT_CONTROL);At(tile,parent,x,y,size,size)
    tile.frame=UI.Solid(tile,name.."Frame",C.muted,true)
    tile.inner=WINDOW_MANAGER:CreateControl(name.."Inner",tile,CT_TEXTURE)
    At(tile.inner,tile,2,2,size-4,size-4)
    if UI.BindColor then UI.BindColor(tile.inner,C.surface or C.bg or C.panel) else UI.Color(tile.inner,C.panel) end
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
    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(tile,{kind="inspect",label=label}) end
    return tile
end
local function Bind(tile,kind,value,tooltip,empty,color,badge)
    tile.data={kind=kind,value=value,tooltip=tooltip}
    local texture=value and value.icon
    if (not texture or texture=="") and kind=="item" and value and value.link then texture=Try(GetItemLinkIcon,value.link) end
    if (not texture or texture=="") and kind=="skill" and value then texture=Try(GetAbilityIcon,value.abilityId or value.id or 0) end
    if kind=="champion" and value and SC.DescribeChampionSkill then
        local native=SC:DescribeChampionSkill(value.id,value.slot,value.points,value.pointsKnown)
        texture=native and native.icon or ""
    end
    if kind=="champion" and value and texture and texture~="" and ZO_ChampionStarVisuals and WINDOW_MANAGER.CreateControlFromVirtual then
        if not tile.star then
            tile.star=WINDOW_MANAGER:CreateControlFromVirtual(tile:GetName().."NativeStar",tile,"ZO_ChampionStarVisuals")
            tile.star:SetAnchorFill(tile.icon);tile.star:SetMouseEnabled(false)
            tile.starVisuals=ZO_ChampionStarVisuals:New(tile.star)
        end
        local discipline=SC.GetChampionDiscipline and SC:GetChampionDiscipline(value.id)
        local kindId=discipline and rawget(_G,"CHAMPION_DISCIPLINE_TYPE_"..discipline)
        if kindId then
            tile.starVisuals:Setup(ZO_CHAMPION_STAR_VISUAL_TYPE.SLOTTABLE,ZO_CHAMPION_STAR_STATE.PURCHASED,kindId,false)
            tile.starVisuals:Update(0)
            -- Preserve the real star artwork at a static frame; never animate 12 CP tiles.
            tile.starVisuals.interpolators={}
            tile.star:SetHidden(false)
        else tile.star:SetHidden(true) end
    elseif tile.star then tile.star:SetHidden(true) end
    local hasTexture=type(texture)=="string" and texture~=""
    tile.icon:SetHidden(not hasTexture);tile.icon:SetTexture(hasTexture and texture or "")
    tile.icon:SetColor(1,1,1,1);tile.empty:SetHidden(hasTexture);tile.empty:SetText(empty or "?")
    tile.badge:SetText(badge or "");UI.Color(tile.frame,color or (value and C.gold or C.muted))
end
local EQUIPMENT={
    {"HEAD","Head",111,30},
    {"SHOULDERS","Shoulders",14,98},{"CHEST","Chest",208,98},
    {"HAND","Hands",14,164},{"WAIST","Waist",208,164},
    {"LEGS","Legs",14,230},{"FEET","Feet",208,230},
    {"NECK","Necklace",34,326},{"RING1","Ring 1",101,326},{"RING2","Ring 2",168,326},
    {"MAIN_HAND","Main hand",18,421},{"OFF_HAND","Off hand",76,421},
    {"BACKUP_MAIN","Main hand",145,421},{"BACKUP_OFF","Off hand",203,421},
}
View.EquipmentPositions=EQUIPMENT
function View.GetDimensions(canvas)
    -- ESO reports rendered dimensions on a scaled control; fitting uses the logical canvas.
    return WIDTH,canvas and canvas.logicalHeight or HEIGHT
end
local DISCIPLINES={{"COMBAT","Warfare",{0.32,0.66,1,1}},{"CONDITIONING","Fitness",{1,0.38,0.35,1}},{"WORLD","Craft",{0.40,0.80,0.45,1}}}
local function SourceAge(updatedAt)
    if not Number(updatedAt) or not SC.NowMs then return "Report age unavailable" end
    local age=math.max(0,SC.NowMs()-updatedAt)
    if age<10000 then return "Last reported just now" end
    if age<60000 then return "Last reported "..math.floor(age/1000).."s ago" end
    return "Last reported "..math.floor(age/60000).."m ago"
end
local function ValidLibraryReport(updatedAt)
    if not Number(updatedAt) or updatedAt<=0 or not SC.NowMs then return false end
    -- LGCS sends changes, not a heartbeat for unchanged slots or class lines.
    -- The adapter validates current membership and cache identity; presentation
    -- must not erase those facts merely because the last change was a while ago.
    return updatedAt<=SC.NowMs()
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
-- Native bonus requirements, cached per set; never assume that an unknown set is a five-piece set.
local requirementCache={}
local requirementCount=0
function View.SetRequirement(set,item)
    local id=Number(set.id or set.setId)
    local key=id and id>0 and id or item and item.link
    if key and requirementCache[key] then return requirementCache[key] end
    local bonusCount,bonusGetter,bonusContext
    if item and type(item.link)=="string" and item.link~="" and type(GetItemLinkSetInfo)=="function" and type(GetItemLinkSetBonusInfo)=="function" then
        local ok,hasSet,_,count=pcall(GetItemLinkSetInfo,item.link,false)
        if ok and hasSet==true then
            bonusCount=count;bonusContext=item.link
            bonusGetter=function(link,index)return GetItemLinkSetBonusInfo(link,false,index)end
        end
    elseif id and id>0 and type(GetItemSetInfo)=="function" and type(GetItemSetBonusInfo)=="function" then
        local ok,hasSet,_,count=pcall(GetItemSetInfo,id)
        if ok and hasSet==true then bonusCount=count;bonusContext=id;bonusGetter=GetItemSetBonusInfo end
    end
    local maximum=0
    if Number(bonusCount) and bonusCount%1==0 and bonusCount>0 and bonusCount<=16 then
        for index=1,bonusCount do
            local required=Try(bonusGetter,bonusContext,index)
            if not Number(required) or required%1~=0 or required<1 or required>12 then return nil end
            maximum=math.max(maximum,required)
        end
    end
    if maximum>0 then
        if key then
            if requirementCount>=256 then requirementCache={};requirementCount=0 end
            requirementCache[key]=maximum;requirementCount=requirementCount+1
        end
        return maximum
    end
end
function View.SetRows(equipment,external)
    local rows={}
    for _,set in ipairs(equipment and equipment.setList or external and external.setList or {}) do
        local mainKnown=external and set.frontKnown==true or not external and equipment and equipment.complete==true
        local backKnown=external and set.backKnown==true or not external and equipment and equipment.complete==true
        local front=mainKnown and Number(set.mainCount) or nil
        local back=backKnown and Number(set.backCount) or nil
        local physical=not external and set.physicalCountKnown==true and Number(set.physicalCount) or nil
        local effective=(front or back) and math.max(front or 0,back or 0) or nil
        local name=Text(set.name,"Set name unavailable")
        local count=effective and ((front and back and "" or "≥")..tostring(effective).."× ") or ""
        local tooltip=name.."\n\nFront bar: "..(front and tostring(front) or "unknown").." set pieces\nBack bar: "..(back and tostring(back) or "unknown").." set pieces\n\nThe headline shows the highest known bar total. Body and jewelry count on both bars; only the weapons on that bar count. A two-handed weapon contributes two set pieces. A proc is not guaranteed active."
        if physical then tooltip=tooltip.."\n\n"..physical.." physical item"..(physical==1 and "" or "s").." equipped across both bars." end
        if external then tooltip=tooltip.."\n\nLibSetDetection • "..SourceAge(external.updatedAt)..". This report is retained for the current uninterrupted group session. The player may withhold sets." end
        local item
        for _,candidate in ipairs(equipment and equipment.items or {}) do
            if ((set.id or set.setId) and (set.id or set.setId)>0 and (candidate.setId==set.id or candidate.setId==set.setId)) or candidate.setName==set.name then item=candidate;break end
        end
        if not item and SC.Catalog and SC.Catalog.GetSetPreview then item=SC.Catalog:GetSetPreview(set.id or set.setId) end
        local required=View.SetRequirement(set,item)
        local frontExtra=front and required and math.max(0,front-required) or 0
        local backExtra=back and required and math.max(0,back-required) or 0
        local extra=math.max(frontExtra,backExtra)
        local warning
        if extra>0 then
            local bar=frontExtra>0 and backExtra>0 and "both bars" or frontExtra>0 and "front bar" or "back bar"
            warning=extra.." extra piece"..(extra==1 and "" or "s").." • "..bar
            tooltip=tooltip.."\n\n"..warning..". This set's last native bonus requires "..required.." pieces; additional pieces on that bar add no further set bonus. Check whether the extra piece is intentional."
        end
        rows[#rows+1]={name=count..name,front=front,back=back,tooltip=tooltip,physical=physical,effective=effective,item=item,warning=warning,required=required}
    end
    table.sort(rows,function(a,b)
        local ac,bc=a.effective or 0,b.effective or 0
        if ac~=bc then return ac>bc end
        return a.name<b.name
    end)
    return rows
end
function View.Create(parent)
    local canvas=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSheet",parent,CT_CONTROL)
    canvas:SetDimensions(WIDTH,HEIGHT);canvas.logicalHeight=HEIGHT;canvas.isBuildSheet=true
    canvas.equipment=Panel(canvas,"AlphaSquadBuildEquipment",0,0,266,HEIGHT,"EQUIPPED")
    local gear=canvas.equipment
    gear.silhouette=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSilhouette",gear,CT_TEXTURE)
    -- Native characterwindow_keyboard.xml uses a 64:256 paper doll. Preserve its
    -- aspect ratio, centered between equal-distance armor columns above jewelry.
    At(gear.silhouette,gear,102.5,48,61,244);gear.silhouette:SetColor(0.76,0.72,0.57,0.88)
    gear.slots={}
    for index,def in ipairs(EQUIPMENT) do
        local caption=index>10 and (index%2==1 and "Main" or "Off") or def[2]
        gear.slots[def[1]]=Icon(gear,"AlphaSquadBuildSlot"..def[1],def[3],def[4],44,caption)
    end
    if UI.Separator then
        UI.Separator(gear,"AlphaSquadBuildJewelryDivider",12,296,242)
        UI.Separator(gear,"AlphaSquadBuildWeaponsDivider",12,384,242)
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
    for i=1,14 do
        local row=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSetRow"..i,canvas.sets,CT_CONTROL)
        At(row,canvas.sets,12,27+(i-1)*22,526,22)
        row.bg=UI.Solid(row,"AlphaSquadBuildSetRowBG"..i,C.surface or C.panel)
        if UI.Separator then row.divider=UI.Separator(row,"AlphaSquadBuildSetRowDivider"..i,0,21,526) end
        row.name=Label(row,"AlphaSquadBuildSetName"..i,"",0,0,374,22)
        row.warning=Label(row,"AlphaSquadBuildSetWarning"..i,"",24,19,350,18,"ZoFontGameSmall",C.gold)
        UI.Hover(row.name,function()return row.tooltip end)
        UI.Hover(row.warning,function()return row.tooltip end)
        row.front=Label(row,"AlphaSquadBuildSetFront"..i,"",386,0,60,22,"ZoFontGameBold",C.gold)
        row.back=Label(row,"AlphaSquadBuildSetBack"..i,"",466,0,60,22,"ZoFontGameBold",C.gold)
        row.icon=WINDOW_MANAGER:CreateControl("AlphaSquadBuildSetIcon"..i,row,CT_TEXTURE)
        row:SetMouseEnabled(true)
        row:SetHandler("OnMouseEnter",function()
            if row.item then UI.ItemTooltip(row,row.item,canvas.isRemote)
            else UI.Tooltip(row,row.tooltip) end
        end)
        row:SetHandler("OnMouseExit",UI.ClearTooltip)
        if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(row,{kind="inspect"}) end
        canvas.sets.rows[i]=row
    end
    canvas.skills=Panel(canvas,"AlphaSquadBuildSkills",278,136,552,150,"SKILL BARS")
    canvas.skills.bars={}
    for row,bar in ipairs({{"primary","FRONT"},{"backup","BACK"},{"werewolf","WEREWOLF"}}) do
        local group=WINDOW_MANAGER:CreateControl("AlphaSquadBuildBar"..row,canvas.skills,CT_CONTROL)
        At(group,canvas.skills,12,30+(row-1)*62,526,60)
        group.title=Label(group,"AlphaSquadBuildBarTitle"..row,bar[2],0,0,92,44,nil,C.muted)
        if UI.Separator and row>1 then group.divider=UI.Separator(group,"AlphaSquadBuildBarDivider"..row,0,-3,526) end
        group.icons={}
        for i=1,6 do group.icons[i]=Icon(group,"AlphaSquadBuildSkill"..row.."_"..i,98+(i-1)*68,0,44)
            group.icons[i].slotNumber=Label(group,"AlphaSquadBuildSkillSlot"..row.."_"..i,i==6 and "ULT" or tostring(i),98+(i-1)*68,44,44,16,nil,i==6 and C.orange or C.muted)
            group.icons[i].slotNumber:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
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
local function PlayerEvidenceKey(player)
    if not player then return "" end
    -- BuildRoster replaces its lightweight wrappers on every refresh. Compare
    -- the inspected identity and displayed partial data, not wrapper identity.
    local parts={}
    local function Value(value)
        local text=tostring(value);parts[#parts+1]=#text..":"..text
    end
    local function Fields(data,fields)
        for _,field in ipairs(fields) do Value(data and data[field]) end
    end
    Fields(player,{"key","displayName","characterName","connected","dead"})
    Fields(player.food,{"verified","active","abilityId","name","icon"})
    Fields(player.potion,{"known","selectionKnown","link","name","count"})
    for _,entry in ipairs(player.externalUltimates or {}) do Fields(entry,{"abilityId","name","bar","updatedAt"}) end
    local lines=player.externalSkillLines
    Fields(lines,{"updatedAt"})
    for _,name in ipairs(lines and lines.names or {}) do Value(name) end
    local sets=player.externalSets
    Fields(sets,{"updatedAt","fresh","sessionValid","complete","incognito"})
    for _,entry in ipairs(sets and sets.setList or {}) do
        Fields(entry,{"id","name","mainCount","backCount","frontKnown","backKnown","activeOnMain","activeOnBack"})
    end
    return table.concat(parts,"|")
end
function View.Bind(canvas,player,details,status)
    local playerEvidenceKey=PlayerEvidenceKey(player)
    if canvas.snapshot~=details or canvas.playerEvidenceKey~=playerEvidenceKey then UI.ClearTooltip() end
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
    canvas.sets.title:SetText(external and "SETS • LAST REPORTED" or "SETS • EQUIPPED")
    local columns=#rows>6 and 2 or 1
    local rowCount=math.max(3,math.ceil(#rows/columns))
    local columnHeights={0,0}
    for i,data in ipairs(rows) do
        local column=math.floor((i-1)/rowCount)+1
        data.y=columnHeights[column];data.height=data.warning and 42 or 22
        columnHeights[column]=columnHeights[column]+data.height
    end
    local setHeight=32+math.max(66,columnHeights[1],columnHeights[2])
    canvas.sets:SetHeight(setHeight)
    canvas.sets.front:SetHidden(columns==2);canvas.sets.back:SetHidden(columns==2)
    for i,row in ipairs(canvas.sets.rows) do
        local data=rows[i];row:SetHidden(not data);row.item=data and data.item;row.tooltip=data and data.tooltip
        if data then
            local col=math.floor((i-1)/rowCount)
            local width=columns==2 and 258 or 526
            At(row,canvas.sets,12+col*270,29+data.y,width,data.height)
            if row.divider then row.divider:ClearAnchors();row.divider:SetAnchor(BOTTOMLEFT,row,BOTTOMLEFT,0,0);row.divider:SetWidth(width) end
            At(row.icon,row,1,1,20,20)
            local icon=data.item and (data.item.icon or Try(GetItemLinkIcon,data.item.link))
            if (not icon or icon=="") and SC.Catalog and SC.Catalog.GetCategoryIcon then
                icon=SC.Catalog:GetCategoryIcon("sets")
                row.tooltip=(row.tooltip or "").."\n\nCategory symbol: no verified item preview is available for this set."
            end
            row.icon:SetTexture(icon or "");row.icon:SetHidden(not icon or icon=="")
            At(row.name,row,24,0,width-(columns==2 and 120 or 164),22)
            At(row.front,row,width-(columns==2 and 92 or 140),0,columns==2 and 46 or 60,22)
            At(row.back,row,width-(columns==2 and 46 or 60),0,columns==2 and 46 or 60,22)
            row.name:SetText(UI.Text(data.name))
            row.warning:SetHidden(not data.warning);row.warning:SetText(data.warning or "")
            At(row.warning,row,24,21,width-26,18)
            UI.Color(row.front,data.required and data.front and data.front>data.required and C.orange or C.gold)
            UI.Color(row.back,data.required and data.back and data.back>data.required and C.orange or C.gold)
            row.front:SetText((columns==2 and "F " or "")..(data.front and tostring(data.front).."×" or "?"))
            row.back:SetText((columns==2 and "B " or "")..(data.back and tostring(data.back).."×" or "?"))
        end
    end
    canvas.state:SetHidden(#rows>0)
    local setState=details and (equipment and equipment.complete and "No equipped set items." or "Set information is incomplete.") or Text(status,"Request a shared build to inspect equipment, skills and Champion Points.")
    if external and #rows==0 then setState=external.incognito and "The player has kept their set information private." or "No named sets were disclosed." end
    canvas.state:SetText(UI.Text(setState))
    local externalUlts={}
    if not details and player and player.connected~=false then
        for _,ultimate in ipairs(player.externalUltimates or {}) do
            if ValidLibraryReport(ultimate.updatedAt) then externalUlts[ultimate.bar=="front" and "primary" or ultimate.bar=="back" and "backup" or "invalid"]=ultimate end
        end
    end
    local curse=details and details.curse or {}
    local showWerewolf=(skills.werewolfKnown==true and #(skills.werewolf or {})>0) or curse.kind=="WEREWOLF"
    local skillsY=setHeight+12
    local skillsHeight=showWerewolf and 216 or 154
    At(canvas.skills,canvas,278,skillsY,552,skillsHeight)
    local cpY=skillsY+skillsHeight+12
    At(canvas.champion,canvas,278,cpY,552,84)
    At(canvas.masteries,canvas,278,cpY+96,552,48)
    At(canvas.consumables,canvas,278,cpY+156,552,48)
    canvas.logicalHeight=math.max(HEIGHT,cpY+204)
    canvas:SetHeight(canvas.logicalHeight)
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
    local externalLines=not details and player and player.connected~=false and player.externalSkillLines
    if externalLines and ValidLibraryReport(externalLines.updatedAt) then for _,name in ipairs(externalLines.names or {}) do lineNames[#lineNames+1]=Text(name) end end
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
    canvas.player=player;canvas.snapshot=details;canvas.playerEvidenceKey=playerEvidenceKey
end
