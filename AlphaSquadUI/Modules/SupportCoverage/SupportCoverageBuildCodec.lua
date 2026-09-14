-- Bounded build records. Only native numeric IDs and numeric item-link fields
-- travel over the wire; names and tooltips are resolved by the receiving client.
local SC = AlphaSquadUI.Modules.SupportCoverage
-- Schema 2 adds verified Champion allocations and a separate Werewolf bar.
-- Legacy schema 1 remains readable; fields it cannot prove stay unknown.
local Codec = {VERSION=2, MAX_BYTES=3584, MAX_ITEMS=16, MAX_LINK_FIELDS=40}
SC.BuildCodec = Codec

local function Number(value, maximum)
    value=tonumber(value)
    if not value or value~=value or value%1~=0 or value<0 or value>maximum then error("Invalid build value") end
    return value
end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c,d,e,f=pcall(fn,...)
    if ok then return a,b,c,d,e,f end
end
function Codec.Hash(text)
    local value=17
    for index=1,#text do value=(value*31+text:byte(index))%16777215 end
    return value
end
local function EffectKeys()
    local keys={}
    for key in pairs(SC.Catalog.effects or {}) do keys[#keys+1]=key end
    table.sort(keys)
    return keys
end
local function Writer()
    local w={parts={},size=0}
    function w:uint(value,maximum)
        value=Number(value or 0,maximum or 4294967295)
        repeat
            local byte=value%128
            value=math.floor(value/128)
            self.parts[#self.parts+1]=string.char(byte+(value>0 and 128 or 0))
            self.size=self.size+1
            if self.size>Codec.MAX_BYTES then error("Build exceeds size limit") end
        until value==0
    end
    function w:flag(value) self:uint(value==true and 1 or 0,1) end
    function w:state(value) self:uint(value==true and 2 or value==false and 1 or 0,2) end
    function w:link(link)
        if link==nil or link=="" then self:uint(0);return end
        if type(link)~="string" or #link>1024 then error("Invalid item link") end
        local payload=link:match("|H%d+:item:([%d:%-]+)|h")
        if not payload then error("Unsupported item link") end
        local values={}
        for token in (payload..":"):gmatch("([^:]*):") do
            if not token:match("^%-?%d+$") then error("Invalid item link field") end
            local value=tonumber(token)
            Number(math.abs(value),4294967295)
            values[#values+1]=value<0 and -value*2+1 or value*2
        end
        if #values==0 or #values>Codec.MAX_LINK_FIELDS then error("Unsupported item link length") end
        self:uint(#values)
        for _,value in ipairs(values) do self:uint(value,8589934591) end
    end
    return w
end
local function Reader(body)
    local r={body=body,pos=1}
    function r:uint(maximum)
        local value,multiplier=0,1
        for index=1,5 do
            local byte=self.body:byte(self.pos)
            if not byte then error("Incomplete build") end
            self.pos=self.pos+1
            value=value+(byte%128)*multiplier
            if byte<128 then return Number(value,maximum or 4294967295) end
            multiplier=multiplier*128
        end
        error("Invalid integer length")
    end
    function r:flag() return self:uint(1)==1 end
    function r:state() local value=self:uint(2);if value>0 then return value==2 end end
    function r:link()
        local count=self:uint(Codec.MAX_LINK_FIELDS)
        if count==0 then return "" end
        local values={}
        for index=1,count do
            local value=self:uint(8589934591)
            values[index]=string.format("%.0f",value%2==1 and -math.floor(value/2) or value/2)
        end
        return "|H1:item:"..table.concat(values,":").."|h|h"
    end
    return r
end
local function Count(list,maximum) return Number(#(list or {}),maximum) end

local CURSE_IDS={NONE=1,VAMPIRE=2,WEREWOLF=3}
local CURSE_NAMES={[1]="NONE",[2]="VAMPIRE",[3]="WEREWOLF"}
local function WriteSkills(w,bar)
    w:uint(Count(bar,6))
    for _,skill in ipairs(bar or {}) do
        w:uint(skill.slot,15);w:uint(skill.abilityId,2147483647);w:uint(skill.boundAbilityId or skill.abilityId,2147483647)
        w:uint(skill.rank,4)
        w:uint(skill.craftedAbilityId,2147483647);w:uint(skill.lineId,2147483647)
        w:flag(skill.scriptsKnown);w:uint(Count(skill.scripts,3))
        for _,script in ipairs(skill.scripts or {}) do w:uint(script.id,2147483647) end
    end
end
local function ReadSkills(r,version)
    local bar,seen={},{}
    for index=1,r:uint(6) do
        local slot,id,bound=r:uint(15),r:uint(2147483647),r:uint(2147483647)
        if seen[slot] then error("Duplicate skill slot") end
        seen[slot]=true
        local rank=version>=2 and r:uint(4) or 0
        local skill={slot=slot,abilityId=id,boundAbilityId=bound,rank=rank>0 and rank or nil,name=Call(GetAbilityName,id) or "Unknown skill",
            icon=Call(GetAbilityIcon,id),ultimate=slot==(ACTION_BAR_ULTIMATE_SLOT_INDEX or 7)+1,
            craftedAbilityId=r:uint(2147483647),lineId=r:uint(2147483647),scriptsKnown=r:flag(),scripts={}}
        if skill.craftedAbilityId==0 then skill.craftedAbilityId=nil end
        if skill.lineId==0 then skill.lineId=nil end
        for scriptIndex=1,r:uint(3) do
            local scriptId=r:uint(2147483647)
            skill.scripts[#skill.scripts+1]={id=scriptId,name=Call(GetCraftedAbilityScriptDisplayName,scriptId) or "Scribing script"}
        end
        bar[#bar+1]=skill
    end
    return bar
end

-- A transport checksum proves delivery, not that the sender's section flags and
-- totals agree with its items. Only complete native slot records can establish
-- set coverage. Keep partial items inspectable, but never promote their claims.
local function ValidateEquipment(equipment)
    local descriptors=SC.EquipmentSlotDetails or {}
    local expected,expectedCount={},0
    for _,slot in ipairs(SC.EquipmentSlotOrder or {}) do
        if descriptors[slot] and not expected[slot] then expected[slot]=true;expectedCount=expectedCount+1 end
    end
    local complete=equipment.complete==true and expectedCount>0
    local actual,counts={},{}
    local bodyWeight,frontWeight,backWeight=0,0,0
    local function SetId(id)
        if type(id)~="number" or id<1 or id>2147483647 or id%1~=0 then return nil end
        local base=Call(GetItemSetUnperfectedSetId,id)
        if type(base)=="number" and base>=1 and base<=2147483647 and base%1==0 then return base end
        return id
    end
    for _,slot in ipairs(equipment.slots) do
        local descriptor=descriptors[slot.slot]
        if not expected[slot.slot] or slot.known~=true then complete=false end
        actual[slot.slot]=true
        local item=slot.item
        if item then
            local bar=descriptor and descriptor.bar
            local weapon=bar=="PRIMARY" or bar=="BACKUP"
            if not descriptor or (bar~="BOTH" and not weapon) or item.setVerified~=true
                or type(item.hasSet)~="boolean" or weapon and type(item.twoHanded)~="boolean" then complete=false end
            local weight=weapon and item.twoHanded==true and 2 or 1
            if bar=="PRIMARY" then frontWeight=frontWeight+weight
            elseif bar=="BACKUP" then backWeight=backWeight+weight
            elseif bar=="BOTH" then bodyWeight=bodyWeight+1 end
            if item.hasSet==true then
                local id=SetId(item.setId)
                if not id then complete=false
                else
                    local count=counts[id] or {main=0,back=0};counts[id]=count
                    if bar=="PRIMARY" or bar=="BOTH" then count.main=count.main+weight end
                    if bar=="BACKUP" or bar=="BOTH" then count.back=count.back+weight end
                end
            end
        end
    end
    for slot in pairs(expected) do if not actual[slot] then complete=false end end
    -- Both weapon bars are mutually exclusive, and each has only two hands.
    if bodyWeight>10 or frontWeight>2 or backWeight>2 then complete=false end
    local reported={}
    for _,set in ipairs(equipment.setList) do
        local id=SetId(set.id)
        local count=id and counts[id]
        if not id or reported[id] or not count or set.mainCount~=count.main or set.backCount~=count.back then complete=false end
        if id then reported[id]=true end
    end
    for id in pairs(counts) do if not reported[id] then complete=false end end
    equipment.complete=complete
    equipment.countsVerified=complete
end

function Codec.Encode(snapshot)
    local ok,body=pcall(function()
        local w=Writer()
        local equipment,skills,masteries=snapshot.equipment or {},snapshot.skills or {},snapshot.masteries or {}
        w:uint(Codec.VERSION);w:uint(snapshot.classId,255)
        w:flag(equipment.complete)
        local slots=equipment.slots or equipment.items or {}
        w:uint(Count(slots,Codec.MAX_ITEMS))
        for _,record in ipairs(slots) do
            local item=record.item or record
            w:uint(record.slot,31);w:flag(record.known~=false)
            w:link(item.link)
            w:state(item.enchantHasCharges);w:state(item.enchantSuppressedByPoison)
        end
        w:uint(Count(equipment.setList,16))
        for _,set in ipairs(equipment.setList or {}) do
            w:uint(set.id,2147483647);w:uint(set.mainCount,24);w:uint(set.backCount,24)
        end
        w:flag(skills.known)
        for _,bar in ipairs({"primary","backup"}) do WriteSkills(w,skills[bar]) end
        w:flag(skills.championKnown);w:uint(Count(skills.champion,12))
        for _,star in ipairs(skills.champion or {}) do
            w:uint(star.slot,32);w:uint(star.id,2147483647);w:uint(star.points,3600)
            w:flag(star.pointsKnown~=false and type(star.points)=="number")
        end
        w:flag(masteries.known);w:flag(masteries.eligible)
        w:uint(Count(masteries.selected,8))
        for _,mastery in ipairs(masteries.selected or {}) do w:uint(mastery.id,2147483647);w:uint(mastery.rank,10) end
        local learned={}
        for id in pairs(masteries.learnedIds or {}) do learned[#learned+1]=Number(id,2147483647) end
        table.sort(learned);w:uint(Count(learned,128))
        for _,id in ipairs(learned) do w:uint(id);w:uint(masteries.learnedIds[id],10) end
        w:uint(Count(masteries.skillLines,16))
        for _,line in ipairs(masteries.skillLines or {}) do
            w:uint(line.id,2147483647);w:uint(line.classId,255);w:uint(line.rank,100)
            w:flag(line.active);w:flag(line.mastery);w:flag(line.native)
        end
        w:uint(Count(masteries.passives,64))
        for _,passive in ipairs(masteries.passives or {}) do
            w:uint(passive.id,2147483647);w:uint(passive.rank,10);w:uint(passive.lineId,2147483647)
        end
        local food,potion=snapshot.food or {},snapshot.potion or {}
        w:flag(food.verified);w:flag(food.active);w:uint(food.abilityId,2147483647)
        -- Remaining duration is intentionally omitted: a moving countdown must
        -- not change the build fingerprint. Food presence is refreshed in summaries.
        w:uint(0,86400)
        w:flag(potion.known);w:flag(potion.selectionKnown);w:flag(potion.isPotion)
        w:link(potion.link);w:uint(potion.count,65535)
        local poisons=snapshot.poisons or {}
        w:flag(poisons.known);w:uint(Count(poisons.items,2))
        for _,poison in ipairs(poisons.items or {}) do w:uint(poison.slot,31);w:link(poison.link) end
        local keys=EffectKeys()
        w:uint(Codec.Hash(table.concat(keys,"|")))
        w:uint(#keys,256)
        for _,key in ipairs(keys) do
            local cap=(snapshot.capabilities or {})[key]
            w:uint(cap and (1+(cap.mainBar and 2 or 0)+(cap.backBar and 4 or 0)+(cap.conditional and 8 or 0)) or 0,15)
        end
        local curse=snapshot.curse or {}
        local kind=curse.known==true and CURSE_IDS[curse.kind] or 0
        if curse.known==true and kind==0 then error("Unknown curse identity") end
        w:uint(kind,3)
        -- The form flag refers only to the native Werewolf transformation.
        local transformed
        if kind==CURSE_IDS.WEREWOLF then transformed=curse.transformed end
        w:state(transformed)
        w:uint(kind==CURSE_IDS.VAMPIRE and curse.stage or 0,4)
        w:flag(skills.werewolfKnown);WriteSkills(w,skills.werewolf)
        return table.concat(w.parts)
    end)
    if ok then return body end
    return nil,tostring(body)
end

function Codec.Decode(body)
    if type(body)~="string" or #body<2 or #body>Codec.MAX_BYTES then return nil end
    local ok,snapshot=pcall(function()
        local r=Reader(body)
        local version=r:uint(7)
        if version~=1 and version~=Codec.VERSION then error("Unsupported build version") end
        local result={buildSchemaVersion=version,classId=r:uint(255),equipment={items={},slots={},setList={},sets={},glyphs={}},
            skills={primary={},backup={},champion={},werewolf={},werewolfKnown=false},curse={known=false},
            masteries={selected={},learnedIds={},learned={},skillLines={},capabilities={}},
            capabilities={},capabilitiesComplete=false,detailsEvidence="SHARED_BUILD"}
        local equipment,skills,masteries=result.equipment,result.skills,result.masteries
        equipment.complete=r:flag()
        local seenSlots={}
        for index=1,r:uint(Codec.MAX_ITEMS) do
            local slot,known,link=r:uint(31),r:flag(),r:link()
            if seenSlots[slot] then error("Duplicate equipment slot") end
            seenSlots[slot]=true
            local item=SC.DescribeEquipmentItem and SC:DescribeEquipmentItem(slot,link) or {slot=slot,link=link,name=Call(GetItemLinkName,link) or ""}
            local descriptor=SC.EquipmentSlotDetails and SC.EquipmentSlotDetails[slot] or {}
            item.slotKey=item.slotKey or descriptor.slotKey;item.slotName=item.slotName or descriptor.slotName
            item.order=item.order or descriptor.order;item.bar=item.bar or descriptor.bar
            item.enchantHasCharges=r:state();item.enchantSuppressedByPoison=r:state()
            equipment.slots[#equipment.slots+1]={slot=slot,slotKey=item.slotKey,slotName=item.slotName,order=item.order,bar=item.bar,
                known=known,empty=link=="",item=link~="" and item or nil}
            if link~="" then equipment.items[#equipment.items+1]=item end
        end
        local glyphs={armorTotal=0,armorMissing=0,prismatic=0,magicka=0,stamina=0,health=0,other=0,crusher=0,unknown=0}
        local armorKeys={head=true,chest=true,shoulders=true,waist=true,hands=true,hand=true,legs=true,feet=true}
        for _,slot in ipairs(equipment.slots) do
            local item=slot.item
            if item and item.isArmor or armorKeys[tostring(slot.slotKey or ""):lower()] then
                glyphs.armorTotal=glyphs.armorTotal+1
                if not slot.known or item and item.hasEnchant==nil then glyphs.unknown=glyphs.unknown+1
                elseif slot.empty or item and item.hasEnchant==false then glyphs.armorMissing=glyphs.armorMissing+1
                elseif item then
                    local kind=glyphs[item.enchant]~=nil and item.enchant or "other"
                    glyphs[kind]=glyphs[kind]+1
                end
            end
        end
        glyphs.verified=glyphs.armorTotal==7 and glyphs.unknown==0
        equipment.glyphs=glyphs
        for index=1,r:uint(16) do
            local id,main,back=r:uint(2147483647),r:uint(24),r:uint(24)
            if equipment.sets[tostring(id)] then error("Duplicate set") end
            local name=Call(GetItemSetName,id) or "Unidentified set"
            for _,item in ipairs(equipment.items) do if item.setId==id and item.setName then name=item.setName;break end end
            local set={id=id,name=name,mainCount=main,backCount=back,equipped=math.max(main,back)}
            equipment.setList[#equipment.setList+1]=set;equipment.sets[tostring(id)]=set
        end
        skills.known=r:flag()
        for _,bar in ipairs({"primary","backup"}) do skills[bar]=ReadSkills(r,version) end
        skills.championKnown=r:flag()
        local seenStars={}
        for index=1,r:uint(12) do
            local slot,id,points=r:uint(32),r:uint(2147483647),r:uint(version>=2 and 3600 or 65535)
            if seenStars[slot] then error("Duplicate Champion slot") end
            seenStars[slot]=true
            local pointsKnown=version>=2 and r:flag() or false
            local star=SC.DescribeChampionSkill and SC:DescribeChampionSkill(id,slot,points,pointsKnown)
                or {slot=slot,id=id,points=points,pointsKnown=pointsKnown,name=Call(GetChampionSkillName,id) or "Unknown Champion star",
                    discipline=SC.GetChampionDiscipline and SC:GetChampionDiscipline(id)}
            skills.champion[#skills.champion+1]=star
        end
        masteries.known=r:flag();masteries.eligible=r:flag()
        for index=1,r:uint(8) do
            local id,rank=r:uint(2147483647),r:uint(10)
            masteries.selected[#masteries.selected+1]={id=id,rank=rank,name=Call(GetAbilityName,id) or "Unknown mastery",icon=Call(GetAbilityIcon,id)}
        end
        for index=1,r:uint(128) do
            local id,rank=r:uint(2147483647),r:uint(10)
            if masteries.learnedIds[id] then error("Duplicate learned skill") end
            masteries.learnedIds[id]=rank
        end
        for index=1,r:uint(16) do
            local id,classId,rank=r:uint(2147483647),r:uint(255),r:uint(100)
            masteries.skillLines[#masteries.skillLines+1]={id=id,classId=classId,rank=rank,
                active=r:flag(),mastery=r:flag(),native=r:flag(),name=Call(GetSkillLineNameById,id) or "Class skill line"}
        end
        masteries.passives={}
        for index=1,r:uint(64) do
            local id,rank,lineId=r:uint(2147483647),r:uint(10),r:uint(2147483647)
            masteries.passives[#masteries.passives+1]={id=id,rank=rank,lineId=lineId,name=Call(GetAbilityName,id) or "Class passive"}
        end
        result.food={verified=r:flag(),active=r:flag(),abilityId=r:uint(2147483647)}
        local remaining=r:uint(86400)
        result.food.name=Call(GetAbilityName,result.food.abilityId) or "Unknown food"
        result.food.icon=Call(GetAbilityIcon,result.food.abilityId)
        result.food.timeEnds=remaining>0 and (Call(GetFrameTimeSeconds) or 0)+remaining or nil
        result.food.source="Shared build"
        result.potion={known=r:flag(),selectionKnown=r:flag(),isPotion=r:flag(),link=r:link(),count=r:uint(65535)}
        result.potion.name=Call(GetItemLinkName,result.potion.link) or "Unknown quickslot"
        result.potion.itemId=Call(GetItemLinkItemId,result.potion.link)
        result.poisons={known=r:flag(),items={}}
        for index=1,r:uint(2) do
            local slot,link=r:uint(31),r:link()
            result.poisons.items[#result.poisons.items+1]={slot=slot,link=link,name=Call(GetItemLinkName,link) or ""}
        end
        local schema,count=r:uint(16777214),r:uint(256)
        local keys=EffectKeys()
        local matches=count==#keys and schema==Codec.Hash(table.concat(keys,"|"))
        for index=1,count do
            local flags=r:uint(15)
            if matches and flags%2==1 then
                result.capabilities[keys[index]]={sources={["Shared build"]=true},evidence="PEER_CAPABILITY_HINT",
                    mainBar=math.floor(flags/2)%2==1,backBar=math.floor(flags/4)%2==1,conditional=flags>=8}
            end
        end
        ValidateEquipment(equipment)
        if SC.RefreshEquipmentPhysicalCounts then SC:RefreshEquipmentPhysicalCounts(equipment) end
        result.catalogCompatible=matches
        if version>=2 then
            local kind,transformed,stage=r:uint(3),r:state(),r:uint(4)
            if kind~=CURSE_IDS.WEREWOLF and transformed~=nil or kind~=CURSE_IDS.VAMPIRE and stage~=0 then
                error("Inconsistent curse evidence")
            end
            result.curse={known=kind>0,kind=CURSE_NAMES[kind],transformed=transformed,stage=stage>0 and stage or nil}
            skills.werewolfKnown=r:flag();skills.werewolf=ReadSkills(r,version)
        end
        if r.pos~=#body+1 then error("Unexpected build data") end
        if SC.DeriveBuildCapabilities then result.capabilities=SC:DeriveBuildCapabilities(result) or result.capabilities end
        return result
    end)
    if ok then return snapshot end
    return nil
end
