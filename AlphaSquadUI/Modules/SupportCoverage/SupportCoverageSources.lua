-- Native API adapters. Source capability, observed effect and inferred identity stay separate.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Catalog=SC.Catalog
local Try=SC.Try
local function Normalize(value)
    return tostring(value or ""):gsub("%^.*$",""):gsub("’","'"):lower()
end

local nativeBuffs={
    major_courage="MAJOR_COURAGE",minor_courage="MINOR_COURAGE",
    major_slayer="MAJOR_SLAYER",minor_slayer="MINOR_SLAYER",
    major_force="MAJOR_FORCE",minor_force="MINOR_FORCE",
    major_berserk="MAJOR_BERSERK",minor_berserk="MINOR_BERSERK",
    major_vulnerability="MAJOR_VULNERABILITY",minor_vulnerability="MINOR_VULNERABILITY",
    major_brittle="MAJOR_BRITTLE",minor_brittle="MINOR_BRITTLE",
    major_breach="MAJOR_BREACH",minor_breach="MINOR_BREACH",
    major_heroism="MAJOR_HEROISM",minor_heroism="MINOR_HEROISM",
    minor_magickasteal="MINOR_MAGICKASTEAL",minor_lifesteal="MINOR_LIFESTEAL",
    major_intellect="MAJOR_INTELLECT",minor_intellect="MINOR_INTELLECT",
    major_endurance="MAJOR_ENDURANCE",minor_endurance="MINOR_ENDURANCE",
    major_fortitude="MAJOR_FORTITUDE",minor_fortitude="MINOR_FORTITUDE",
    major_resolve="MAJOR_RESOLVE",minor_resolve="MINOR_RESOLVE",
    major_protection="MAJOR_PROTECTION",minor_protection="MINOR_PROTECTION",
    major_evasion="MAJOR_EVASION",minor_evasion="MINOR_EVASION",
    major_vitality="MAJOR_VITALITY",minor_vitality="MINOR_VITALITY",
    major_mending="MAJOR_MENDING",minor_mending="MINOR_MENDING",
    minor_toughness="MINOR_TOUGHNESS",major_aegis="MAJOR_AEGIS",minor_aegis="MINOR_AEGIS",
    major_maim="MAJOR_MAIM",minor_maim="MINOR_MAIM",
    major_cowardice="MAJOR_COWARDICE",minor_cowardice="MINOR_COWARDICE",
}
local pairedBuffs={
    major_brutality_sorcery={"MAJOR_BRUTALITY","MAJOR_SORCERY"},
    minor_brutality_sorcery={"MINOR_BRUTALITY","MINOR_SORCERY"},
    major_savagery_prophecy={"MAJOR_SAVAGERY","MAJOR_PROPHECY"},
    minor_savagery_prophecy={"MINOR_SAVAGERY","MINOR_PROPHECY"},
}
local originalIndex=SC.RebuildEffectIndex
function SC:RebuildEffectIndex()
    originalIndex(self)
    self.nativeBuffIndex={}
    local function Add(key,suffix)
        local enum=rawget(_G,"BUFF_TYPE_"..suffix)
        if enum~=nil then self.nativeBuffIndex[enum]=key end
    end
    for key,suffix in pairs(nativeBuffs) do Add(key,suffix) end
    for key,suffixes in pairs(pairedBuffs) do for _,suffix in ipairs(suffixes) do Add(key,suffix) end end
end

function SC:ObserveEffectsOnUnit(tag)
    local observed,raw={},{}
    if not tag or type(GetNumBuffs)~="function" or type(GetUnitBuffInfo)~="function" then return observed,false,raw end
    if not self.effectIdIndex then self:RebuildEffectIndex() end
    local count=Try(GetNumBuffs,tag)
    if type(count)~="number" then return observed,false,raw end
    local complete=true
    local nativeComplete=type(GetAbilityBuffType)=="function"
    local now=self.NowMs()
    self.observerHasData=self.observerHasData or {}
    local subject=self:GetObservationSubject(tag)
    if count>0 then self.observerHasData[subject]=true end
    for index=1,math.min(count,self.History.MAX_EFFECTS_PER_UNIT) do
        local ok,name,started,ending,slot,stacks,icon,_,effectType,_,statusType,id,_,castByPlayer=pcall(GetUnitBuffInfo,tag,index)
        if not ok or type(id)~="number" or id<=0 then complete=false
        else
            local key=self.effectIdIndex[id]
            local source=key and "ABILITY_ID" or nil
            if GetAbilityBuffType then
                local validCall,buffType,valid=pcall(GetAbilityBuffType,id,tag)
                if not validCall or valid==false then nativeComplete=false end
                if validCall and valid~=false and self.nativeBuffIndex[buffType] then
                    key=self.nativeBuffIndex[buffType];source="NATIVE_BUFF_TYPE"
                end
            end
            if not key then key=self.effectNameIndex[Normalize(name)];source="OBSERVED_NAME" end
            local value={name=name,abilityId=id,started=started,ending=ending,slot=slot,
                stacks=tonumber(stacks),icon=icon,effectType=effectType,statusEffectType=statusType,
                castByPlayer=castByPlayer,observedAt=now,evidence=source or "RAW_ABILITY_ID"}
            if key then
                self.effectIdIndex[id]=key;self.effectReadableKeys[key]=true
                if not observed[key] or (value.stacks or 0)>(observed[key].stacks or 0) then observed[key]=value end
            end
            if self.sv.collectAllEffects then raw[id]=value end
        end
    end
    if count>self.History.MAX_EFFECTS_PER_UNIT then complete=false;if self.pull then self.pull.truncated=true end end
    -- Only a successful complete LOCAL scan can establish an absent native buff type.
    if complete and nativeComplete and self:IsSelf(tag) then
        for _,key in pairs(self.nativeBuffIndex) do self.effectReadableKeys[key]=true end
    end
    return observed,complete,raw
end

function SC:ScanMundus()
    local result={known=false,ids={},names={}}
    if type(GetUnitActiveMundusStoneBuffIndices)~="function" or type(GetUnitBuffInfo)~="function" then return result end
    local success,indices=pcall(function() return {GetUnitActiveMundusStoneBuffIndices("player")} end)
    if not success then return result end
    result.known=true
    for _,index in ipairs(indices) do
        if type(index)=="number" and index>0 then
            local ok,name,_,_,_,_,_,_,_,_,_,id=pcall(GetUnitBuffInfo,"player",index)
            if not ok or type(id)~="number" or id<=0 then result.known=false
            else result.ids[#result.ids+1]=id;result.names[#result.names+1]=name end
        end
    end
    table.sort(result.ids)
    return result
end

local equipmentScan=SC.ScanEquipment
function SC:ScanEquipment()
    local result=equipmentScan(self)
    local families={}
    for _,set in ipairs(result.setList or {}) do
        local base=Try(GetItemSetUnperfectedSetId,set.id)
        local familyId=tonumber(base) and base>0 and base or set.id
        local family=families[familyId]
        if not family then
            family={id=familyId,name=set.name,mainCount=0,backCount=0,variants={},names={},
                equipped=set.equipped,perfected=set.perfected,maxEquipped=set.maxEquipped}
            families[familyId]=family
        end
        family.mainCount=family.mainCount+(set.mainCount or 0)
        family.backCount=family.backCount+(set.backCount or 0)
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
                        cap.sources[family.name]=true
                        cap.mainBar=cap.mainBar or main;cap.backBar=cap.backBar or back
                        cap.evidence=source.setId and "SET_ID" or "SET_NAME_HINT"
                        capabilities[key]=cap
                    end
                end
            end
        end
        result.sets[tostring(family.id)]=family;result.setList[#result.setList+1]=family
    end
    table.sort(result.setList,function(a,b) return a.id<b.id end)
    result.capabilities=capabilities
    for _,item in ipairs(result.items or {}) do
        if item.isWeapon and item.weaponType==nil then result.complete=false end
        if item.hasEnchant and (not item.enchantId or item.enchantId==0) then
            item.enchantId=Try(GetItemLinkDefaultEnchantId,item.link)
        end
    end
    if not result.complete then result.capabilities={} end
    return result
end

local potionScan=SC.ScanPotion
function SC:ScanPotion()
    local potion=potionScan(self)
    if potion.known then
        potion.count=Try(GetSlotItemCount,potion.slot,HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
        potion.evidence="SELECTED_QUICKSLOT"
        -- Selection is not a cast event, including when the stack becomes empty.
    end
    return potion
end

local bossObservations=SC.GetBossObservations
function SC:GetBossObservations()
    local result=bossObservations(self)
    -- Untargetable boss phases are observation gaps, not proven debuff downtime.
    for _,entry in ipairs(result) do
        for index=1,6 do
            local tag="boss"..index
            if Try(DoesUnitExist,tag)==true and self:GetObservationSubject(tag)==entry.subject
                and Try(IsUnitAttackable,tag)==false then
                entry.effects={};entry.raw={};entry.complete=false
            end
        end
    end
    return result
end
