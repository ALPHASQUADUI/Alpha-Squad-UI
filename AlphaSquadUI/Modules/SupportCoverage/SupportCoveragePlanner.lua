-- Bounded, out-of-combat planner. One observed/saved loadout per player; no invented inventory.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Planner={MAX_CANDIDATES=5, BEAM_WIDTH=48}
SC.Planner=Planner

function SC:RememberLoadout(player, label)
    if not player or not player.displayName then return end
    local sets=self.Audit.Value(player,"sets")
    local skills=self.Audit.Value(player,"skills")
    if sets==nil or skills==nil then return end
    self.sv.loadoutLibrary=self.sv.loadoutLibrary or {}
    local key=player.key or player.displayName
    local choices=self.sv.loadoutLibrary[key] or {}
    self.sv.loadoutLibrary[key]=choices
    local capabilities={}
    for effect, data in pairs(player.capabilities or {}) do
        local sourced=false
        for source in pairs(data.sources or {}) do if source~="Manual" then sourced=true end end
        if sourced and self.Catalog.effects[effect] then capabilities[effect]=true end
    end
    local signature=sets.."|"..skills.."|"..tostring(self.Audit.Value(player,"masteries"))
    for _,candidate in ipairs(choices) do
        if candidate.signature==signature then
            candidate.label=label or candidate.label
            candidate.character, candidate.classId, candidate.role = player.characterName, player.classId, player.role
            candidate.capabilities, candidate.savedAt, candidate.evidence = capabilities, self.Try(GetTimeStamp), "RECORDED_BUILD"
            return true
        end
    end
    choices[#choices+1]={label=label or ("Saved loadout "..(#choices+1)),signature=signature,
        character=player.characterName,classId=player.classId,role=player.role,capabilities=capabilities,
        savedAt=self.Try(GetTimeStamp),evidence="RECORDED_BUILD"}
    -- The current observed build plus four saved alternatives keeps each beam
    -- expansion at MAX_CANDIDATES choices.
    while #choices>Planner.MAX_CANDIDATES-1 do table.remove(choices,1) end
    -- Bound saved owners independently of raid session history.
    local owners={};for owner in pairs(self.sv.loadoutLibrary) do owners[#owners+1]=owner end
    if #owners>36 then
        table.sort(owners,function(a,b)
            local aa=self.sv.loadoutLibrary[a];local bb=self.sv.loadoutLibrary[b]
            return ((aa[#aa] or {}).savedAt or 0)<((bb[#bb] or {}).savedAt or 0)
        end)
        for i=1,#owners-36 do self.sv.loadoutLibrary[owners[i]]=nil end
    end
    return true
end

function SC:GetPlannerCandidates(player)
    local current={label="Current observed build",current=true,capabilities={},character=player.characterName,role=player.role}
    if player.connected~=false then
        for effect,data in pairs(player.capabilities or {}) do
            local observed=false
            for source in pairs(data.sources or {}) do if source~="Manual" then observed=true end end
            if observed and self.Catalog.effects[effect] then current.capabilities[effect]=true end
        end
    end
    local result={current}
    local saved=self.sv.loadoutLibrary and self.sv.loadoutLibrary[player.key] or {}
    for index=math.max(1,#saved-(Planner.MAX_CANDIDATES-2)),#saved do
        local candidate=saved[index]
        -- A saved build from a different character is not proof that this character can equip it.
        if candidate.character and candidate.character==player.characterName and candidate.classId==player.classId
            and candidate.role==player.role and player.connected~=false then result[#result+1]=candidate end
    end
    return result
end

local function Score(sc,state,requirements)
    local missing,core=0,0
    for _,key in ipairs(requirements) do
        if not state.covered[key] then
            missing=missing+1
            if sc.Catalog.effects[key].priority=="core" then core=core+1 end
        end
    end
    return core*10000+missing*1000+(state.lockFailures or 0)*100000+state.changes*10
end

function SC:ComputeBuildPlan()
    if self.inCombat then return nil,"Planning is available out of combat only." end
    local requirements=self.Catalog:GetRequirements(self.sv.activeProfile,self.sv)
    local required={};for _,key in ipairs(requirements) do required[key]=true end
    local players={};for _,p in ipairs(self.roster or {}) do players[#players+1]=p end
    if #players==0 then return nil,"No roster data." end
    table.sort(players,function(a,b) return a.key<b.key end)
    local beam={{covered={},choices={},changes=0,lockFailures=0,signature=""}}
    for index=1,math.min(12,#players) do
        local player=players[index]
        local nextBeam={}
        for _,state in ipairs(beam) do
            for candidateIndex,candidate in ipairs(self:GetPlannerCandidates(player)) do
                local nextState={covered=self.Audit.Copy(state.covered),choices={},changes=state.changes+(candidate.current and 0 or 1),lockFailures=state.lockFailures,
                    signature=state.signature..":"..candidateIndex}
                for i,choice in ipairs(state.choices) do nextState.choices[i]=choice end
                nextState.choices[index]={player=player.key,role=player.role,candidate=candidate}
                for key in pairs(candidate.capabilities) do nextState.covered[key]=true end
                for key,owner in pairs(self.sv.assignmentLocks) do
                    if required[key] and owner==player.key and not candidate.capabilities[key] then
                        nextState.lockFailures=nextState.lockFailures+1
                    end
                end
                nextState.score=Score(self,nextState,requirements)
                nextBeam[#nextBeam+1]=nextState
            end
        end
        table.sort(nextBeam,function(a,b)
            if a.lockFailures~=b.lockFailures then return a.lockFailures<b.lockFailures end
            return a.score==b.score and a.signature<b.signature or a.score<b.score
        end)
        beam={};for i=1,math.min(#nextBeam,Planner.BEAM_WIDTH) do beam[i]=nextBeam[i] end
    end
    local best=beam[1]
    if not best then return nil,"No roster data." end
    best.missing={}
    for _,key in ipairs(requirements) do if not best.covered[key] then best.missing[#best.missing+1]=self.Catalog.effects[key].label end end
    for key,owner in pairs(self.sv.assignmentLocks) do
        if required[key] and not self.byKey[owner] then best.lockFailures=best.lockFailures+1 end
    end
    best.createdAt=self.NowMs();best.profile=self.sv.activeProfile
    best.notice="Snapshot suggestion; recalculate after build or roster changes. Suggestion only: one whole recorded loadout per player. Saved gear ownership/current availability must be confirmed; no equipment is changed. Bounded beam search is not a proof of a global optimum."
    self.buildPlan=best
    return best
end
