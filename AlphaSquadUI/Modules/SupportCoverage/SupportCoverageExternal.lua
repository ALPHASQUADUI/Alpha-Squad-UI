-- Optional compatible-library evidence. No extra broadcasts or full-build claims.
-- LGCS timestamps describe its last update, not a separate slot confirmation.
-- LibSetDetection is change-driven: receipts stay valid only in this group session.
local SC=AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end
local Catalog=SC.Catalog
local LGCS_MAX_AGE_MS=75000
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c=pcall(fn,...)
    if ok then return a,b,c end
end
local function Number(value,min,max)
    if type(value)~="number" or value~=value or value==math.huge or value==-math.huge
        or value<min or value>max then return nil end
    return value
end
local function Integer(value,min,max)
    value=Number(value,min,max)
    return value and value%1==0 and value or nil
end
local function Now() return Number(Call(SC.NowMs),0,9007199254740991) end
local function MemberIdentity(tag,allowDead)
    if type(tag)~="string" or not tag:match("^group%d+$") or Call(DoesUnitExist,tag)~=true
        or Call(IsUnitGrouped,tag)~=true or Call(IsUnitOnline,tag)~=true
        or Call(AreUnitsEqual,tag,"player")==true then return nil end
    if not allowDead and Call(IsUnitDead,tag)~=false then return nil end
    local displayName,characterName=Call(GetUnitDisplayName,tag),Call(GetUnitName,tag)
    if type(displayName)~="string" or displayName:sub(1,1)~="@" or #displayName>128
        or type(characterName)~="string" or characterName=="" or #characterName>200 then return nil end
    return displayName.."\031"..characterName,displayName,characterName
end
local function Fresh(data,now)
    if type(data)~="table" or not now then return false end
    local updated=Number(data._lastUpdated,1,now)
    return updated and now-updated<=LGCS_MAX_AGE_MS and updated or false
end
local function CloneCapabilities(capabilities)
    local out={}
    for key,cap in pairs(type(capabilities)=="table" and capabilities or {}) do
        if type(cap)=="table" then
            local copy={}
            for field,value in pairs(cap) do copy[field]=value end
            copy.sources,copy.sourceDetails={},{}
            for name,enabled in pairs(type(cap.sources)=="table" and cap.sources or {}) do
                local detail=type(cap.sourceDetails)=="table" and cap.sourceDetails[name]
                if not (type(detail)=="table" and detail.external==true) then
                    copy.sources[name]=enabled
                    if type(detail)=="table" then
                        local d={};for field,value in pairs(detail) do d[field]=value end
                        copy.sourceDetails[name]=d
                    end
                end
            end
            if next(copy.sources) then
                out[key]=copy
                if next(copy.sourceDetails) then
                    copy.mainBar,copy.backBar=false,false
                    for _,detail in pairs(copy.sourceDetails) do
                        copy.mainBar=copy.mainBar or detail.mainBar==true
                        copy.backBar=copy.backBar or detail.backBar==true
                    end
                end
            end
        end
    end
    return out
end
local function Add(entry,key,name,kind,conditions,front,back,evidence,updatedAt)
    local effect=Catalog.effects[key]
    if not effect or effect.personal==true then return end
    local cap=entry.capabilities[key]
    if not cap then
        cap={sources={},sourceDetails={},mainBar=false,backBar=false,conditional=true,groupSource=true}
        entry.capabilities[key]=cap
    end
    cap.sources=cap.sources or {};cap.sourceDetails=cap.sourceDetails or {}
    cap.sources[name]=true;cap.groupSource=true;cap.conditional=true
    cap.mainBar=cap.mainBar or front;cap.backBar=cap.backBar or back
    cap.evidence=cap.evidence or evidence
    cap.sourceDetails[name]={name=name,kind=kind,conditions=conditions,mainBar=front,backBar=back,
        evidence=evidence,external=true,updatedAt=updatedAt}
end
local skillIndex,setIndex,indexedSkills,indexedSets={},{},nil,nil
local function RebuildSourceIndexes()
    if indexedSkills~=Catalog.skillSources then
        skillIndex={};indexedSkills=Catalog.skillSources
        for _,source in ipairs(Catalog.skillSources or {}) do
            if source.groupSource==true and source.personal~=true then
                for _,id in ipairs(source.abilityIds or {}) do
                    if Integer(id,1,2147483647) then
                        skillIndex[id]=skillIndex[id] or {};skillIndex[id][#skillIndex[id]+1]=source
                    end
                end
            end
        end
    end
    if indexedSets~=Catalog.setSources then
        setIndex={};indexedSets=Catalog.setSources
        for _,source in ipairs(Catalog.setSources or {}) do
            local id=Integer(source.setId,2,2147483647)
            if id and source.groupSource==true and source.personal~=true then
                setIndex[id]=setIndex[id] or {};setIndex[id][#setIndex[id]+1]=source
            end
        end
    end
end
local function MergeCombatStats(entry,now,skillsAuthoritative)
    if skillsAuthoritative then return end
    local ult=AlphaSquadUI.Modules.ULTTracker
    local consumer=ult and ult.Group and ult.Group.lgcs
    if not consumer then return end
    local data=Call(consumer.GetUnitULT,consumer,entry.unitTag)
    local updated=Fresh(data,now)
    if updated then
        local list={}
        for index,field in ipairs({"ult1ID","ult2ID"}) do
            local id=Integer(data[field],1,2147483647)
            if id and Call(IsAbilityUltimate,id)==true then
                local name=Call(GetAbilityName,id)
                if type(name)~="string" or name=="" then name="Unknown Ultimate" end
                local bar=index==1 and "front" or "back"
                list[#list+1]={abilityId=id,name=name,bar=bar,updatedAt=updated,evidence="LGCS_ULTIMATE_SLOT"}
                local label="Shared ultimate: "..name.." ("..bar..")"
                for _,source in ipairs(skillIndex[id] or {}) do
                    for _,key in ipairs(source.provides or {}) do
                        Add(entry,key,label,"skill",(source.conditions or "Meet the skill's cast and recipient conditions.")
                            .." Last reported Ultimate slot; casting has not been observed.",index==1,index==2,"LGCS_ULTIMATE_SLOT",updated)
                    end
                end
            end
        end
        if #list>0 then entry.externalUltimates=list end
    end
    local lines=Call(consumer.GetUnitSkillLines,consumer,entry.unitTag)
    local linesUpdated=Fresh(lines,now)
    if linesUpdated then
        local result={ids={},names={},updatedAt=linesUpdated,evidence="LGCS_SKILL_LINES"}
        local seen={}
        for _,field in ipairs({"first","second","third"}) do
            local id=Integer(lines[field],1,2147483647)
            local name=id and Call(GetSkillLineNameById,id)
            if id and not seen[id] and type(name)=="string" and name~="" then
                seen[id]=true;result.ids[#result.ids+1]=id;result.names[#result.names+1]=name
            end
        end
        if #result.ids>0 then entry.externalSkillLines=result end
    end
end

local function ReadSetReport(lib,tag,updatedAt)
    if Call(lib.IsUnitDataAvailable,tag)~=true then return nil end
    local data=Call(lib.GetUnitSetData,tag)
    if type(data)~="table" or type(lib.constants)~="table" then return nil end
    local constants=lib.constants
    if constants.active_type_none~=0 or constants.active_type_dual~=1
        or constants.active_type_front~=2 or constants.active_type_back~=3 then return nil end
    local out={source="LibSetDetection — last reported",updatedAt=updatedAt,fresh=true,sessionValid=true,
        complete=true,incognito=false,knownBars={body=true,front=true,back=true},setList={}}
    local count,totalBody,totalFront,totalBack=0,0,0,0
    for rawId,value in pairs(data) do
        count=count+1;if count>16 then return nil end
        local id=Integer(rawId,0,2147483647)
        if not id or type(value)~="table" or type(value.numEquip)~="table" then return nil end
        local body=Integer(value.numEquip.body,0,10)
        local front=Integer(value.numEquip.front,0,2)
        local back=Integer(value.numEquip.back,0,2)
        if not body or not front or not back then return nil end
        totalBody,totalFront,totalBack=totalBody+body,totalFront+front,totalBack+back
        if totalBody>10 or totalFront>2 or totalBack>2 then return nil end
        if id==1 then out.incognito=true;out.complete=false
        elseif id>1 then
            local active=value.activeType
            if active~=constants.active_type_none and active~=constants.active_type_dual
                and active~=constants.active_type_front and active~=constants.active_type_back then return nil end
            local name=value.setName
            if type(name)~="string" or name=="" then name=Call(lib.GetSetName,id) end
            if type(name)~="string" or name=="" then name=Catalog.setNameById and Catalog.setNameById[id] or "Unknown set" end
            out.setList[#out.setList+1]={id=id,name=name,bodyCount=body,frontWeaponCount=front,backWeaponCount=back,
                mainCount=body+front,backCount=body+back,frontKnown=true,backKnown=true,
                activeOnMain=active==constants.active_type_dual or active==constants.active_type_front,
                activeOnBack=active==constants.active_type_dual or active==constants.active_type_back}
        end
    end
    table.sort(out.setList,function(a,b) return a.id<b.id end)
    return out
end

function SC:ResetExternalSources()
    self.externalSetReceipts={}
end
function SC:PruneExternalSources()
    local active={}
    local size=Integer(Call(GetGroupSize),0,12) or 0
    for index=1,size do
        local tag=Call(GetGroupUnitTagByIndex,index)
        local key=tag and MemberIdentity(tag,true)
        if key then active[key]=true end
    end
    for key in pairs(self.externalSetReceipts or {}) do
        if not active[key] then self.externalSetReceipts[key]=nil end
    end
end
function SC:InitializeExternalSources()
    local lib=rawget(_G,"LibSetDetection")
    if type(lib)~="table" or type(lib.constants)~="table" or type(lib.RegisterEvent)~="function"
        or type(lib.GetUnitSetData)~="function" or type(lib.IsUnitDataAvailable)~="function" then return false end
    if self.externalSetLibrary==lib then return true end
    self.externalSetReceipts={}
    local event,unitType=lib.constants.event_data_update,lib.constants.unit_type_group
    if not Integer(event,1,100) or not Integer(unitType,1,100) then return false end
    local result=Call(lib.RegisterEvent,event,"AlphaSquadSupportCoverageExternal",function(tag,localPlayer)
        if localPlayer==true or not SC.sv or not SC.sv.enabled then return end
        SC:PruneExternalSources()
        local key=MemberIdentity(tag,true)
        local now=Now()
        if not key or not now then return end
        SC.externalSetReceipts[key]=ReadSetReport(lib,tag,now)
        if SC.ScheduleRefresh then SC:ScheduleRefresh("shared set data",150) end
    end,unitType)
    if result~=0 then return false end
    self.externalSetLibrary=lib
    return true
end

function SC:MergeExternalCapabilities(entry,rosterAlreadyPruned)
    if type(entry)~="table" then return false end
    entry.capabilities=CloneCapabilities(entry.capabilities)
    entry.externalUltimates,entry.externalSkillLines,entry.externalSets=nil,nil,nil
    if not self.sv or not self.sv.enabled then return false end
    self:InitializeExternalSources()
    if not rosterAlreadyPruned then self:PruneExternalSources() end
    RebuildSourceIndexes()
    if entry.buildVerified==true and entry.capabilitiesComplete==true then return false end
    local key,displayName=MemberIdentity(entry.unitTag,false)
    if not key or entry.connected==false or entry.dead==true
        or (entry.displayName and entry.displayName~=displayName) then return false end
    -- Overall capability completeness stays conservative because not every passive
    -- is inspectable. Exact sections of a verified build are still authoritative.
    local fingerprint=Integer(entry.fullBuildFingerprint,1,2147483647)
    local confirmedDetail=type(entry.fullBuild)=="table" and fingerprint
        and fingerprint==Integer(entry.buildDetailFingerprint,1,2147483647)
    local verified=entry.dataQuality~="STALE" and (entry.buildVerified==true or confirmedDetail)
    local equipmentAuthoritative=verified and type(entry.equipment)=="table" and entry.equipment.complete==true
    local skillsAuthoritative=verified and type(entry.skills)=="table" and entry.skills.known==true
    MergeCombatStats(entry,Now(),skillsAuthoritative)
    local report=self.externalSetReceipts and self.externalSetReceipts[key]
    local lib=self.externalSetLibrary
    if equipmentAuthoritative then
        local scannedAt=Number(entry.scannedAt,0,9007199254740991)
        if report and (not scannedAt or report.updatedAt<=scannedAt) then
            -- An older session report must not resurrect an already superseded set
            -- after the exact build later expires.
            self.externalSetReceipts[key]=nil
        end
    elseif report and lib and Call(lib.IsUnitDataAvailable,entry.unitTag)==true then
        -- The adapter owns this snapshot; never expose mutable library-owned numEquip tables.
        local view={};for field,value in pairs(report) do view[field]=value end
        view.setList={};for index,set in ipairs(report.setList) do
            local copy={};for field,value in pairs(set) do copy[field]=value end;view.setList[index]=copy
        end
        view.knownBars={body=true,front=true,back=true};entry.externalSets=view
        for _,set in ipairs(view.setList) do
            for _,source in ipairs(setIndex[set.id] or {}) do
                local required=Integer(source.requiredPieces or 5,1,12)
                local front=required and set.activeOnMain and set.mainCount>=required or false
                local back=required and set.activeOnBack and set.backCount>=required or false
                if front or back then
                    local bar=front and back and "both bars" or (front and "front" or "back")
                    local label="Shared set: "..(source.label or set.name).." ("..bar..")"
                    for _,effectKey in ipairs(source.provides or {}) do
                        Add(entry,effectKey,label,"set",(source.conditions or "Meet the set's activation and recipient conditions.")
                            .." Last reported this group session; the library sends changes without a heartbeat.",
                            front,back,"LIBSETDETECTION",report.updatedAt)
                    end
                end
            end
        end
    elseif report then self.externalSetReceipts[key]=nil end
    return entry.externalUltimates~=nil or entry.externalSkillLines~=nil or entry.externalSets~=nil
end
