-- Native API adapters. Source capability, observed effect and inferred identity stay separate.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Catalog=SC.Catalog
local Try=SC.Try
local function Normalize(value)
    return tostring(value or ""):gsub("%^.*$",""):gsub("’","'"):lower()
end
local function FiniteNumber(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end
local function AbilityId(value)
    value=FiniteNumber(value)
    if not value or value<=0 or value>2147483647 or value%1~=0 then return nil end
    return value
end

function SC:ScanMundus()
    local result={known=false,ids={},types={},names={}}
    if type(GetUnitActiveMundusStoneBuffIndices)~="function" or type(GetUnitBuffInfo)~="function" then return result end
    local success,indices=pcall(function() return {GetUnitActiveMundusStoneBuffIndices("player")} end)
    if not success then return result end
    result.known=true
    for _,index in ipairs(indices) do
        index=FiniteNumber(index)
        if index and index>0 and index%1==0 and index<=256 then
            local ok,name,timeStarted,timeEnding,buffSlot,stackCount,iconFilename,
                deprecatedBuffType,effectType,abilityType,statusEffectType,abilityId=
                pcall(GetUnitBuffInfo,"player",index)
            abilityId=AbilityId(abilityId)
            if not ok or not abilityId then result.known=false
            else
                result.ids[#result.ids+1]=abilityId
                result.names[#result.names+1]=tostring(name or "")
                local mundusType=FiniteNumber(Try(GetAbilityMundusStoneType,abilityId))
                if mundusType and mundusType>=0 and mundusType%1==0 then result.types[#result.types+1]=mundusType end
            end
        elseif index~=0 then result.known=false end
    end
    table.sort(result.ids)
    table.sort(result.types)
    table.sort(result.names)
    return result
end

-- Physical objects and set-bonus weights are different: an arena staff is one
-- item but contributes two pieces on its equipped weapon bar. Reuse this for
-- received item links so summaries never infer item counts from set weights.
function SC:RefreshEquipmentPhysicalCounts(equipment)
    if type(equipment) ~= "table" then return end
    local byFamily = {}
    for _, set in ipairs(equipment.setList or {}) do
        local id = AbilityId(set.id)
        local familyId = id and AbilityId(Try(GetItemSetUnperfectedSetId, id)) or nil
        local key = tostring(familyId or id or ("name:" .. Normalize(set.name)))
        byFamily[key] = set
        set.physicalCount, set.bodyItemCount, set.primaryItemCount, set.backupItemCount = 0, 0, 0, 0
        set.physicalCountKnown = equipment.complete == true
    end
    for _, item in ipairs(equipment.items or {}) do
        local id = AbilityId(item.setId)
        local familyId = id and AbilityId(Try(GetItemSetUnperfectedSetId, id)) or nil
        local key = tostring(familyId or id or ("name:" .. Normalize(item.setName)))
        local set = byFamily[key]
        if set and item.hasSet ~= false then
            set.physicalCount = set.physicalCount + 1
            if item.bar == "PRIMARY" then set.primaryItemCount = set.primaryItemCount + 1
            elseif item.bar == "BACKUP" then set.backupItemCount = set.backupItemCount + 1
            else set.bodyItemCount = set.bodyItemCount + 1 end
        end
    end
end

local equipmentScan=SC.ScanEquipment
function SC:ScanEquipment()
    local result=equipmentScan(self)
    local families={}
    for _,set in ipairs(result.setList or {}) do
        local base=AbilityId(Try(GetItemSetUnperfectedSetId,set.id))
        local familyId=base or AbilityId(set.id) or 0
        local familyKey=familyId>0 and tostring(familyId) or "name:"..Normalize(set.name)
        local family=families[familyKey]
        if not family then
            family={key=familyKey,id=familyId,name=set.name,mainCount=0,backCount=0,variants={},names={},
                physicalCount=0,bodyItemCount=0,primaryItemCount=0,backupItemCount=0,
                equipped=set.equipped,perfected=set.perfected,maxEquipped=set.maxEquipped}
            families[familyKey]=family
        end
        family.mainCount=family.mainCount+(FiniteNumber(set.mainCount) or 0)
        family.backCount=family.backCount+(FiniteNumber(set.backCount) or 0)
        for _, field in ipairs({"physicalCount", "bodyItemCount", "primaryItemCount", "backupItemCount"}) do
            family[field] = family[field] + (FiniteNumber(set[field]) or 0)
        end
        family.variants[#family.variants+1]={id=set.id,mainCount=set.mainCount,backCount=set.backCount}
        family.names[#family.names+1]=set.name
    end
    result.setList={};result.sets={}
    -- Discard set-derived claims from the permissive legacy scan, keeping equipment enchant hints.
    local capabilities={}
    if result.capabilities.crusher then capabilities.crusher=result.capabilities.crusher end
    for _,family in pairs(families) do
        for _,source in ipairs(Catalog.setSources or {}) do
            local match=source.setId and source.setId==family.id
            if not source.setId then
                for _,name in ipairs(family.names) do
                    if Normalize(name):find(Normalize(source.token),1,true) then match=true;break end
                end
            end
            if match then
                local required=source.requiredPieces or 5
                local main,back=family.mainCount>=required,family.backCount>=required
                family.activeOnMain=family.activeOnMain or main
                family.activeOnBack=family.activeOnBack or back
                if result.complete and (main or back) then
                    for _,key in ipairs(source.provides) do
                        local cap=capabilities[key] or {sources={},mainBar=false,backBar=false}
                        local sourceName=source.label or family.name
                        cap.sources[sourceName]=true
                        cap.groupSource=true
                        cap.sourceDetails=cap.sourceDetails or {}
                        cap.sourceDetails[sourceName]={name=sourceName,kind="set",conditions=source.conditions,mainBar=main,backBar=back,evidence="SET_ID"}
                        cap.mainBar=cap.mainBar or main;cap.backBar=cap.backBar or back
                        cap.evidence=source.setId and "SET_ID" or "SET_NAME_HINT"
                        capabilities[key]=cap
                    end
                end
            end
        end
        result.sets[family.key]=family;result.setList[#result.setList+1]=family
    end
    table.sort(result.setList,function(a,b)
        if a.id~=b.id then return a.id<b.id end
        return Normalize(a.name)<Normalize(b.name)
    end)
    result.capabilities=capabilities
    for _,item in ipairs(result.items or {}) do
        if item.equipSlotValid==false or (item.isWeapon and item.weaponType==nil) then result.complete=false end
    end
    if not result.complete then result.capabilities={} end
    self:RefreshEquipmentPhysicalCounts(result)
    return result
end

local potionScan=SC.ScanPotion
function SC:ScanPotion()
    local potion=potionScan(self)
    if potion.known then
        local count=FiniteNumber(Try(GetSlotItemCount,potion.slot,HOTBAR_CATEGORY_QUICKSLOT_WHEEL))
        potion.count=count and math.floor(math.max(0,math.min(65535,count))) or nil
        potion.evidence="SELECTED_QUICKSLOT"
        -- Selection is not a cast event, including when the stack becomes empty.
    end
    return potion
end

local function NativeIconName(value)
    if type(value)~="string" then return nil end
    local path=value:lower():gsub("\\","/")
    if not path:match("^/?esoui/art/icons/") then return nil end
    return path:match("([^/]+)$")
end

-- Validate the reported recipe against public, character-independent definition APIs.
-- Do not use the viewer's unlocked scripts, active recipe or crafted effective ability ID.
function SC:DeriveScribingCapabilities(skill)
    local result={}
    if type(skill)~="table" or skill.scriptsKnown~=true or type(skill.scripts)~="table" or #skill.scripts~=3 then return result end
    local craftedId=AbilityId(skill.craftedAbilityId)
    if not craftedId or skill.ultimate==true then return result end
    local slots={SCRIBING_SLOT_PRIMARY,SCRIBING_SLOT_SECONDARY,SCRIBING_SLOT_TERTIARY}
    if #slots~=3 then return result end
    local ids,icons,seen={},{},{}
    for index,script in ipairs(skill.scripts) do
        local id=type(script)=="table" and AbilityId(script.id)
        if not id or seen[id] or Try(GetCraftedAbilityScriptScribingSlot,id)~=slots[index] then return result end
        local count=FiniteNumber(Try(GetNumScriptsInSlotForCraftedAbility,craftedId,slots[index]))
        if not count or count<1 or count>128 or count%1~=0 then return result end
        local allowed=false
        for i=1,count do
            if Try(GetScriptIdAtSlotIndexForCraftedAbility,craftedId,slots[index],i)==id then allowed=true;break end
        end
        if not allowed or Try(IsCraftedAbilityScriptDisabled,id)==true then return result end
        ids[index],icons[index],seen[id]=id,NativeIconName(Try(GetCraftedAbilityScriptIcon,id)),true
    end
    if Try(IsCraftedAbilityDisabled,craftedId)==true
        or Try(IsScribableScriptCombinationForCraftedAbility,craftedId,ids[1],ids[2],ids[3])~=true then return result end
    local textures=Catalog.scribingTextures
    if not textures or NativeIconName(Try(GetCraftedAbilityIcon,craftedId))~=textures.banner then return result end
    local focusKey=textures.bannerFocus[icons[1]]
    -- Immobilize is a personal cleanse; it is deliberately not a group-cleanse provider.
    if focusKey then
        result[focusKey]={name="Banner Bearer - "..Catalog.effects[focusKey].label:gsub("^Banner Bearer %- ",""),
            conditions="The exact Focus is equipped in a valid recipe. Toggle the banner on and keep intended allies in its aura."}
    end
    for _,key in ipairs(textures.bannerAffix[icons[3]] or {}) do
        result[key]={name="Banner Bearer - "..Catalog.effects[key].label,
            conditions="The exact Affix is equipped in a valid Banner recipe. Its recipients must be in the active aura; the same named buff does not stack."}
    end
    return result
end

-- Use the same conservative capability derivation for local scans and received full builds.
-- Remote booleans are not expanded into invented skill, set, passive or potion providers.
function SC:DeriveBuildCapabilities(snapshot)
    local result={}
    if type(snapshot)~="table" then return result end
    local function Add(key, name, kind, conditions, mainBar, backBar, evidence, extra)
        if not Catalog.effects[key] then return end
        local cap=result[key]
        if not cap then
            cap={sources={},sourceDetails={},mainBar=false,backBar=false,conditional=true,groupSource=true}
            result[key]=cap
        end
        cap.sources[name]=true
        cap.mainBar=cap.mainBar or mainBar==true
        cap.backBar=cap.backBar or backBar==true
        cap.evidence=cap.evidence or evidence
        local detail=cap.sourceDetails[name] or {name=name,kind=kind,conditions=conditions,evidence=evidence}
        detail.mainBar=detail.mainBar or mainBar==true
        detail.backBar=detail.backBar or backBar==true
        if extra then for field,value in pairs(extra) do detail[field]=value end end
        cap.sourceDetails[name]=detail
    end
    local equipment=type(snapshot.equipment)=="table" and snapshot.equipment or {}
    if equipment.complete==true then
        for _,set in ipairs(equipment.setList or {}) do
            local id=AbilityId(set.id)
            local base=id and AbilityId(Try(GetItemSetUnperfectedSetId,id))
            id=base or id
            for _,source in ipairs(Catalog.setSources or {}) do
                local matched=id and source.setId==id
                if not id and source.setId==nil then matched=Normalize(set.name)==Normalize(source.token) end
                if matched then
                    local needed=source.requiredPieces or 5
                    local main=(FiniteNumber(set.mainCount) or 0)>=needed
                    local back=(FiniteNumber(set.backCount) or 0)>=needed
                    if main or back then
                        local name=source.label or set.name or "Equipped set"
                        for _,key in ipairs(source.provides or {}) do
                            Add(key,name,"set",source.conditions,main,back,"SET_ID",{
                                requiredPieces=needed,mainCount=set.mainCount,backCount=set.backCount,recipientLimit=source.recipientLimit})
                        end
                    end
                end
            end
        end
        for _,item in ipairs(equipment.items or {}) do
            if item.isWeapon and item.hasEnchant~=false and item.enchantHasCharges~=false
                and item.enchantSuppressedByPoison~=true then
                local key=item.enchant=="crusher" and "crusher" or (item.enchant=="weakening" and "weakening" or nil)
                if key then
                    local name=(key=="crusher" and "Crusher" or "Weakening") .. " Enchantment (" .. tostring(item.slotName or "Weapon") .. ")"
                    Add(key,name,"enchant","Requires a charged weapon enchantment without paired poison.",
                        item.bar=="PRIMARY",item.bar=="BACKUP","EQUIPPED_ENCHANT",{slotName=item.slotName})
                end
            end
        end
    end
    local skills=type(snapshot.skills)=="table" and snapshot.skills or {}
    if skills.known==true then
        local usableBars={"primary","backup"}
        local curse=type(snapshot.curse)=="table" and snapshot.curse or {}
        if skills.werewolfKnown==true and curse.known==true and curse.kind=="WEREWOLF" and curse.transformed==true then
            usableBars[#usableBars+1]="werewolf"
        end
        for _,bar in ipairs(usableBars) do
            for _,skill in ipairs(skills[bar] or {}) do
                local seen={}
                local function AddMatches(id)
                    for _,source in ipairs(Catalog:FindSkillSources(id,skill.name)) do
                        if not seen[source] then
                            seen[source]=true
                            for _,key in ipairs(source.provides or {}) do
                                if source.personal~=true then
                                    Add(key,source.label or skill.name,"skill",source.conditions,
                                        bar=="primary",bar=="backup","SLOTTED_SKILL",{slot=skill.slot,alternateBar=bar=="werewolf" and "WEREWOLF" or nil})
                                end
                            end
                        end
                    end
                end
                -- A grimoire without its exact scripts does not establish a buff recipient.
                if not skill.craftedAbilityId then
                    AddMatches(AbilityId(skill.abilityId))
                    if skill.boundAbilityId~=skill.abilityId then AddMatches(AbilityId(skill.boundAbilityId)) end
                elseif skill.scriptsKnown and self.DeriveScribingCapabilities then
                    for key,detail in pairs(self:DeriveScribingCapabilities(skill) or {}) do
                        Add(key,detail.name or skill.name,"scribing",detail.conditions,bar=="primary",bar=="backup","SCRIBING_SCRIPTS")
                    end
                end
            end
        end
    end
    local masteries=type(snapshot.masteries)=="table" and snapshot.masteries or {}
    if masteries.known and masteries.eligible then
        for _,selected in ipairs(masteries.selected or {}) do
            for _,source in ipairs(Catalog.masterySources or {}) do
                local nativeName=Try(GetAbilityName,selected.id)
                local name=type(nativeName)=="string" and nativeName~="" and nativeName or selected.name
                local matches=(source.abilityId and selected.id==source.abilityId) or Normalize(name)==Normalize(source.name)
                if not matches then
                    for _,alias in ipairs(source.aliases or {}) do if Normalize(name)==Normalize(alias) then matches=true;break end end
                end
                local prerequisite=not source.requires
                for _,id in ipairs(source.requiresIds or {}) do
                    if ((masteries.learnedIds or {})[id] or 0)>=(source.rank or 1) then prerequisite=true;break end
                end
                if not prerequisite and source.requires then
                    prerequisite=((masteries.learned or {})[Normalize(source.requires)] or 0)>=(source.rank or 1)
                end
                if prerequisite and (source.requiredSkillLineIds or source.requiredSlottedIds) then
                    local slotted=false
                    if skills.known then
                        for _,bar in ipairs({"primary","backup"}) do
                            for _,skill in ipairs(skills[bar] or {}) do
                                for _,lineId in ipairs(source.requiredSkillLineIds or {}) do
                                    if skill.lineId==lineId then slotted=true end
                                end
                                for _,id in ipairs(source.requiredSlottedIds or {}) do
                                    if skill.abilityId==id or (not skill.craftedAbilityId and skill.boundAbilityId==id) then slotted=true end
                                end
                            end
                        end
                    end
                    prerequisite=slotted
                end
                if matches and prerequisite then
                    for _,key in ipairs(source.provides or {}) do
                        Add(key,source.name,"mastery",source.conditions,true,true,"SELECTED_MASTERY")
                    end
                end
            end
        end
    end
    if self.ScanClassPassives and skills.known then
        for key,cap in pairs(self:ScanClassPassives(skills,masteries)) do
            for name,detail in pairs(cap.sourceDetails or {}) do
                Add(key,name,"passive",detail.conditions,detail.mainBar,detail.backBar,detail.evidence)
            end
        end
    end
    if skills.championKnown then
        for _,star in ipairs(skills.champion or {}) do
            for _,source in ipairs(Catalog.championSources or {}) do
                local ids=source.championIds or {}
                local matched=#ids==0 and Normalize(star.name)==Normalize(source.name)
                for _,id in ipairs(ids) do if star.id==id then matched=true end end
                if matched and self.IsChampionStarActive and self:IsChampionStarActive(star) then
                    for _,key in ipairs(source.provides) do
                        Add(key,source.name,"champion",source.conditions,true,true,"ALLOCATED_CHAMPION",{points=star.points,slot=star.slot})
                    end
                end
            end
        end
    end
    return result
end
