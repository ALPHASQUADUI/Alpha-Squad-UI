-- Curated raid support Ultimates. These are slotted ability IDs, not effect IDs.
-- Family order is the versioned synchronization bit order: never reorder v1.
-- Sources: m00nyONE/HodorReflexes modules/ult/main.lua; LibGroupCombatStats
-- SPECIAL_ULTIMATE_ABILITY_IDS; DakJaniels/LuiExtended LuiData/Effects and
-- BarHighlight tables. Native progression data resolves rank variants without
-- guessing identities from translated names, class or equipped set hints.
local ULT=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.ULTTracker
local Group=ULT and ULT.Group
if not Group then return end

Group.catalogVersion=1
Group.catalogFamilies={
    {key="war_horn",id=38563,ids={38563,40223,40220},default=true},
    {key="colossus",id=122174,ids={122174,122388,122395},default=true},
    {key="storm_atronach",id=23634,ids={23634,23492,23495},default=true},
    {key="barrier",id=38573,ids={38573,40237,40239},default=true},
    {key="cryptcanon",id=195031,ids={195031},setId=691,default=true},
    -- The U49 group buff belongs to the base and Standard of Might only.
    -- Shifting Standard and Major Defile effect IDs do not prove this buff.
    {key="standard",id=32947,ids={32947,28988},default=true},
    {key="glyphic",id=183709,ids={183709,193794,193558},default=true},
    {key="consuming_darkness",id=25411,ids={25411,36493,36485},default=false},
    {key="negate_magic",id=27706,ids={27706,28341,28348},default=false},
    {key="nova",id=21752,ids={21752,21755,21758},default=false},
    {key="rite_of_passage",id=22223,ids={22223,22229,22226},default=false},
    {key="secluded_grove",id=85532,ids={85532,85804,85807},default=false},
    {key="sleet_storm",id=86109,ids={86109,86113,86117},default=false},
    {key="panacea",id=83552,ids={83552,83850,85132},default=false},
    {key="reanimate",id=115410,ids={115410,118367,118379},default=false},
    -- These morphs support allies; their self-only siblings are not included.
    {key="soul_siphon",id=35508,ids={35508},default=false},
    {key="gibbering_shelter",id=192380,ids={192380},default=false},
    {key="magma_shell",id=17874,ids={17874},default=false},
    {key="pack_leader",id=39075,ids={39075},default=false},
}
local byKey,byId={},{}
for _,family in ipairs(Group.catalogFamilies) do
    byKey[family.key]=family
    for _,id in ipairs(family.ids) do byId[id]=family end
end

function Group:GetAbilityFamily(value)
    if type(value)=="string" and byKey[value] then return byKey[value] end
    local id=tonumber(value)
    if not id or id~=id or id<1 or id>2147483647 or id%1~=0 then return nil end
    if byId[id] then return byId[id] end
    -- LGCS already sends canonical morph IDs. This bounded native lookup also
    -- accepts a rank variant without ever broadening to sibling morphs.
    local manager=SKILLS_DATA_MANAGER
    if manager and type(manager.GetProgressionDataByAbilityId)=="function" then
        local ok,progression=pcall(manager.GetProgressionDataByAbilityId,manager,id)
        if ok and type(progression)=="table" then return byId[progression.abilityId] end
    end
end

function Group:NormalizeTrackedFamilies()
    if not self.sv then return end
    local existing=self.sv.trackedFamilies
    local migrating=type(existing)~="table"
    local legacy=self.sv.trackedAbilities
    local enabledLegacy={}
    if migrating and type(legacy)=="table" then
        for id,enabled in pairs(legacy) do
            local family=enabled==true and self:GetAbilityFamily(id)
            if family then enabledLegacy[family.key]=true end
        end
    end
    local hasLegacy=next(enabledLegacy)~=nil
    local result={}
    for _,family in ipairs(self.catalogFamilies) do
        if migrating then
            result[family.key]=hasLegacy and enabledLegacy[family.key]==true or not hasLegacy and family.default==true
        else
            result[family.key]=existing[family.key]==true
        end
    end
    self.sv.trackedFamilies=result
    self.sv.trackedAbilities=nil
    self.sv.catalogVersion=self.catalogVersion
end

local function Effective(self)
    return (self.GetEffectiveTrackedFamilies and self:GetEffectiveTrackedFamilies()) or self.sv and self.sv.trackedFamilies or {}
end
function Group:IsAbilityTracked(id)
    local family=self:GetAbilityFamily(id)
    return family~=nil and Effective(self)[family.key]==true
end
function Group:GetTrackedAbilityCount()
    local count,selected=0,Effective(self)
    for _,family in ipairs(self.catalogFamilies) do if selected[family.key]==true then count=count+1 end end
    return count
end
function Group:SetAbilityTracked(value,enabled)
    if not self.sv then return false end
    local family=self:GetAbilityFamily(value)
    if not family then return false end
    if self.CanEditFilters then
        local allowed,reason=self:CanEditFilters()
        if not allowed then return false,reason end
    end
    if type(self.sv.trackedFamilies)~="table" then self:NormalizeTrackedFamilies() end
    enabled=enabled==true
    self.sv.trackedFamilies[family.key]=enabled
    if self.OnFiltersChanged then self:OnFiltersChanged(family.key,enabled) end
    self:Refresh("tracked family changed")
    return true
end
function Group:SetAllTracked(enabled)
    if not self.sv then return false end
    if self.CanEditFilters then
        local allowed,reason=self:CanEditFilters()
        if not allowed then return false,reason end
    end
    enabled=enabled==true
    self.sv.trackedFamilies=self.sv.trackedFamilies or {}
    for _,family in ipairs(self.catalogFamilies) do self.sv.trackedFamilies[family.key]=enabled end
    if self.OnFiltersChanged then self:OnFiltersChanged(nil,enabled) end
    self:Refresh("all tracked families changed")
    return true
end
function Group:GetAvailableAbilities()
    local result,counts={},{}
    local selected=Effective(self)
    -- A player counts once per family, including identical front/back morphs.
    for _,entry in ipairs(self.roster or {}) do
        if entry.shared then
            local first=self:GetAbilityFamily(entry.ult1ID)
            local second=self:GetAbilityFamily(entry.ult2ID)
            if first then counts[first.key]=(counts[first.key] or 0)+1 end
            if second and second~=first then counts[second.key]=(counts[second.key] or 0)+1 end
        end
    end
    for _,family in ipairs(self.catalogFamilies) do
        local name,icon=self:GetAbilityMeta(family.id)
        -- The selector identifies the mythic family by its official set name;
        -- live skill metadata, tooltips and readiness still use ability 195031.
        local locale=AlphaSquadUI.Localization
        if family.setId and locale and locale.GetNativeName then
            name=locale.GetNativeName("set",family.setId,name)
        end
        result[#result+1]={key=family.key,id=family.id,ids=family.ids,name=name,icon=icon,
            users=counts[family.key] or 0,tracked=selected[family.key]==true}
    end
    return result
end
