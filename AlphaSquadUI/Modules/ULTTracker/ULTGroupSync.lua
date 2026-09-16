-- Raid settings only: no builds, inventory, player names or chat transport.
-- Protocol 511 is provisional. Reserve it and validate coexistence before release.
local ASUI = AlphaSquadUI
local ULT = ASUI and ASUI.Modules and ASUI.Modules.ULTTracker
local Group = ULT and ULT.Group
if not Group then return end

Group.Sync = Group.Sync or {}
local Sync = Group.Sync
Sync.PROTOCOL_ID, Sync.PROTOCOL_NAME = 511, "AlphaSquadRaidSettings"
local MAX_MEMBERS, MAX_FAMILIES = 24, 24
local UINT32, UINT16 = 4294967295, 65535
local SEND_INTERVAL, REQUEST_INTERVAL = 1500, 30000
local nonceCounter = 0

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end

local function Integer(value, low, high)
    return type(value) == "number" and value == value and value >= low and value <= high and value % 1 == 0
end

local function Now() return Call(GetGameTimeMilliseconds) or 0 end
local function Key(account)
    if type(account) ~= "string" or #account < 2 or #account > 100 or account:sub(1, 1) ~= "@" then return nil end
    return string.lower(account)
end
local function Account(tag) return Call(GetUnitDisplayName, tag) end
local function Crown() return Key(Account(Call(GetGroupLeaderUnitTag))) end

local function Nonce()
    nonceCounter = (nonceCounter + 1) % 65536
    return ((Call(GetTimeStamp) or 1) * 1009 + Now() * 17 + nonceCounter) % UINT32 + 1
end

local function Fingerprint(text)
    local hash = 5381
    for index = 1, #text do hash = (hash * 33 + string.byte(text, index)) % UINT32 end
    return hash
end

local function Families() return Group.catalogFamilies or {} end
local function CatalogVersion() return Group.catalogVersion or 1 end
local function MaskOf(values)
    local result = 0
    for index, family in ipairs(Families()) do
        if index > MAX_FAMILIES then break end
        if values and values[family.key] == true then result = result + 2 ^ (index - 1) end
    end
    return result
end
local function MapOf(mask)
    local result = {}
    for index, family in ipairs(Families()) do
        if index > MAX_FAMILIES then break end
        result[family.key] = math.floor(mask / 2 ^ (index - 1)) % 2 == 1
    end
    return result
end

function Sync:IsActive()
    return self.initialized == true and ULT.sv and ULT.sv.enabled == true
        and Group.sv and Group.sv.enabled == true and not ULT.loading and not self.loading
end

function Sync:CanRun()
    return self:IsActive() and Call(IsUnitInCombat, "player") == false
end

function Sync:IsTransportReady()
    local protocol = self.protocol
    return self.available == true and protocol ~= nil
        and Call(protocol.GetId, protocol) == self.PROTOCOL_ID
        and Call(protocol.GetName, protocol) == self.PROTOCOL_NAME
        and Call(protocol.IsEnabled, protocol) == true
end

function Sync:Notify()
    if Group.ScheduleRefresh then Group:ScheduleRefresh(false) end
    if Group.RefreshIntegratedSettings then Group:RefreshIntegratedSettings() end
end

function Sync:RevokeQueued()
    if not self.mayHaveQueued or not self.protocol then return end
    if not self:IsTransportReady() or Call(IsUnitGrouped, "player") ~= true then return end
    -- LGB has no public per-protocol cancellation API. Replace only our queue
    -- with a schema-valid neutral frame which every receiver rejects by version.
    local neutral = {version=0,catalog=0,kind=3,roster=0,epoch=0,term=0,revision=0,leader=0,mask=0,challenge=0}
    if Call(self.protocol.Send, self.protocol, neutral, {isRelevantInCombat=false,replaceQueuedMessages=true}) == true then
        self.mayHaveQueued = false
    end
end

function Sync:Invalidate()
    self:RevokeQueued()
    self.generation = (self.generation or 0) + 1
    self.flushPending, self.requestPending = false, false
    self.pendingState, self.pendingFilters, self.pendingRequest = false, false, false
    self.replies, self.requestRates = {}, {}
    self.confirmed, self.shared, self.leader = false, nil, nil
    self.epoch, self.term, self.revision, self.challenge = nil, nil, nil, nil
    self.requestAttempts = 0
    self.sendFailures, self.sendFailed, self.stateRepeats, self.filterRepeats = 0, false, 0, 0
    self.awaitingAck, self.resendOnState = false, false
end

-- Group identity comes from native membership, never from a transmitted account.
-- Sorting also prevents a reordered groupN tag from changing the delegate index.
function Sync:RefreshContext(force)
    if not self:IsActive() then
        if self.context then self:Invalidate() end
        self.context, self.crown, self.own, self.byKey, self.members = nil, nil, nil, {}, {}
        self.lastContextAt = nil
        return
    end
    if Call(IsUnitInCombat, "player") ~= false then return end
    local members, byKey = {}, {}
    local own, crown = Key(Account("player")), Crown()
    local grouped = Call(IsUnitGrouped, "player") == true
    local now = Now()
    if not force and self.lastContextAt == now and self.crown == crown and self.own == own
        and self.wasGrouped == grouped then return end
    self.lastContextAt, self.wasGrouped = now, grouped
    local size = Call(GetGroupSize)
    if grouped and Integer(size, 1, MAX_MEMBERS) then
        for index = 1, size do
            local tag = Call(GetGroupUnitTagByIndex, index)
            local account = Account(tag)
            local key = Key(account)
            if not key or byKey[key] or Call(DoesUnitExist, tag) ~= true then members = {}; byKey = {}; break end
            local member = {account=account, key=key, tag=tag, isCrown=key == crown}
            members[#members + 1], byKey[key] = member, member
        end
    end
    table.sort(members, function(a, b) return a.key < b.key end)
    local signature = {tostring(Call(GetWorldName) or ""), crown or ""}
    for index, member in ipairs(members) do member.index = index; signature[#signature + 1] = member.key end
    local context = #members > 0 and byKey[crown] and byKey[own] and table.concat(signature, "|") or nil
    local oldLeader, oldCrown, oldShared = self.leader, self.crown, self.shared
    self.members, self.byKey, self.own, self.crown = members, byKey, own, crown
    if not force and self.context == context then return end
    self:Invalidate()
    self.context = context
    self.rosterHash = context and Fingerprint(context) or nil
    if context then
        if own == crown then
            self.leader = oldCrown == crown and byKey[oldLeader] and oldLeader or crown
            self.epoch, self.term, self.revision = Nonce(), 1, 0
            self.shared = oldCrown == crown and oldShared or MapOf(MaskOf(Group.sv.trackedFamilies))
            self.confirmed, self.pendingState, self.stateRepeats = true, true, 2
        else
            self.challenge, self.pendingRequest = Nonce(), true
        end
        self:ScheduleFlush()
    end
    self:Notify()
end

function Sync:GetMembers()
    self:RefreshContext()
    local result = {}
    for _, member in ipairs(self.members or {}) do result[#result + 1] = {account=member.account, isCrown=member.isCrown} end
    return result
end

function Sync:GetLeader()
    self:RefreshContext()
    local member = self.byKey and self.byKey[self.leader or self.crown]
    return member and member.account or nil
end

function Sync:CanAssignLeader()
    self:RefreshContext()
    if not self.context then
        if Call(IsUnitGrouped, "player") == true then return false, "Waiting for the group leader's raid settings." end
        return false, "Join a group to choose its raid leader."
    end
    if self.own ~= self.crown then return false, "Only the group leader with the crown can choose the raid leader." end
    if not self:CanRun() then return false, "Raid settings can be changed out of combat." end
    if not self:IsTransportReady() then return false, "Raid settings synchronization is unavailable." end
    return true
end

function Sync:CanEditFilters()
    self:RefreshContext()
    if not self.context then
        if Call(IsUnitGrouped, "player") == false then return true end
        return false, "Waiting for the group leader's raid settings."
    end
    if not self:CanRun() then return false, "Raid settings can be changed out of combat." end
    if self.own ~= (self.leader or self.crown) then return false, "Only the selected raid leader can change shared Ultimate filters." end
    if self.own ~= self.crown and (not self.confirmed or not self:IsTransportReady()) then
        return false, "Waiting for the group leader's raid settings."
    end
    return true
end

function Sync:SetLeader(account)
    local allowed, reason = self:CanAssignLeader()
    if not allowed then return false, reason end
    local key = Key(account)
    if not key or not self.byKey[key] then return false, "Select a current group member." end
    if key == self.leader then return true end
    if self.term >= UINT16 then self:RefreshContext(true) end
    self.leader, self.term, self.revision = key, self.term + 1, 0
    self.pendingState, self.pendingFilters, self.stateRepeats = true, false, 2
    self.sendFailures, self.sendFailed = 0, false
    self:ScheduleFlush(); self:Notify()
    return true
end

function Sync:GetEffectiveTrackedFamilies()
    if self:IsActive() and self.context and self.confirmed and self.shared
        and (self.own == self.crown or self:IsTransportReady()) then return self.shared end
    return Group.sv and Group.sv.trackedFamilies or {}
end

function Sync:OnFiltersChanged(key, enabled)
    if not self:CanEditFilters() or not self.context then return end
    local values = MapOf(MaskOf(self:GetEffectiveTrackedFamilies()))
    if key == nil and type(enabled) == "boolean" then
        for family in pairs(values) do values[family] = enabled end
    elseif type(key) == "string" and values[key] ~= nil then values[key] = enabled == true
    else values = MapOf(MaskOf(Group.sv.trackedFamilies)) end
    if MaskOf(values) == MaskOf(self.shared) then return end
    if self.revision >= UINT16 then
        if self.own ~= self.crown then self.pendingRequest = true; self:ScheduleFlush(); return end
        self:RefreshContext(true)
    end
    self.shared, self.revision = values, self.revision + 1
    if self.own == self.crown then self.pendingState, self.stateRepeats = true, 2
    else self.pendingFilters, self.filterRepeats, self.awaitingAck = true, 2, true end
    self.sendFailures, self.sendFailed = 0, false
    self:ScheduleFlush(); self:Notify()
end

function Sync:GetStatus()
    if not self.context then
        if Call(IsUnitGrouped, "player") == true then return "Waiting for the group leader's raid settings." end
        return "Local raid settings"
    end
    local protocol = self.protocol
    if not self.available or not protocol or Call(protocol.GetId, protocol) ~= self.PROTOCOL_ID
        or Call(protocol.GetName, protocol) ~= self.PROTOCOL_NAME then return "Raid settings synchronization is unavailable." end
    local nativeEnabled = Call(protocol.IsEnabled, protocol)
    if nativeEnabled == false then return "Raid settings sending is disabled in LibGroupBroadcast." end
    if nativeEnabled ~= true then return "Raid settings synchronization is unavailable." end
    if self.sendFailed then return "Raid settings update could not be sent." end
    if not self.confirmed then return "Waiting for the group leader's raid settings." end
    if self.pendingFilters or self.pendingState or self.awaitingAck then return "Raid settings update pending" end
    return "Raid settings follow the selected raid leader"
end

-- Called when the settings page opens. Repair missed broadcasts without an idle
-- heartbeat; no network operation is attached to the per-row refresh path.
function Sync:RequestRefresh()
    self:RefreshContext()
    if not self:CanRun() or not self.context or not self:IsTransportReady()
        or Now() - (self.lastManualRequestAt or -10000) < 10000 then return false end
    self.lastManualRequestAt = Now()
    self.sendFailures, self.sendFailed = 0, false
    if self.own == self.crown then self.pendingState = true
    else
        self.challenge, self.pendingRequest, self.requestAttempts = Nonce(), true, 0
        self.resendOnState = self.awaitingAck == true
    end
    self:ScheduleFlush()
    return true
end

function Sync:ScheduleRequestRetry()
    if self.requestPending or self.confirmed or (self.requestAttempts or 0) >= 3 or not zo_callLater then return end
    self.requestPending = true
    local generation = self.generation
    zo_callLater(function()
        if generation ~= Sync.generation then return end
        Sync.requestPending = false
        if not Sync:CanRun() or Sync.confirmed then return end
        Sync.pendingRequest = true
        Sync:ScheduleFlush()
    end, REQUEST_INTERVAL)
end

function Sync:ScheduleFlush()
    if self.flushPending or not self:CanRun() or not self.context or not self:IsTransportReady() or not zo_callLater then return end
    self.flushPending = true
    local generation = self.generation
    local delay = math.max(150, SEND_INTERVAL - (Now() - (self.lastSendAt or -SEND_INTERVAL)))
    zo_callLater(function()
        if generation ~= Sync.generation then return end
        Sync.flushPending = false
        Sync:Flush()
    end, delay)
end

function Sync:Payload(kind, challenge)
    return {version=1, catalog=CatalogVersion(), kind=kind, roster=self.rosterHash,
        epoch=self.epoch or 0, term=self.term or 0, revision=self.revision or 0,
        leader=(self.byKey[self.leader or self.crown] or {}).index or 0,
        mask=MaskOf(self.shared), challenge=challenge or 0}
end

function Sync:Flush()
    if not self:CanRun() or not self:IsTransportReady() then return end
    self:RefreshContext()
    if not self.context then return end
    local payload, repliedTo
    if self.own == self.crown then
        for key, challenge in pairs(self.replies or {}) do
            if self.byKey[key] then repliedTo = key; payload = self:Payload(1, challenge); break end
        end
        if not payload and self.pendingState then payload = self:Payload(1) end
    elseif self.pendingRequest then payload = self:Payload(0, self.challenge)
    elseif self.pendingFilters and self.confirmed and self.own == self.leader then payload = self:Payload(2) end
    if not payload then return end
    self.lastSendAt = Now()
    local sent = Call(self.protocol.Send, self.protocol, payload, {isRelevantInCombat=false, replaceQueuedMessages=true})
    if sent ~= true then
        self.sendFailures = (self.sendFailures or 0) + 1
        if self.sendFailures < 3 then self:ScheduleFlush()
        else self.sendFailed = true; self:Notify() end
        return
    end
    self.mayHaveQueued, self.sendFailures, self.sendFailed = true, 0, false
    if payload.kind == 0 then
        self.pendingRequest = false
        self.requestAttempts = (self.requestAttempts or 0) + 1
        self:ScheduleRequestRetry()
    elseif payload.kind == 1 then
        if repliedTo then self.replies[repliedTo] = nil end
        if self.pendingState and (self.stateRepeats or 0) > 0 then self.stateRepeats = self.stateRepeats - 1
        else self.pendingState = false end
    else
        if (self.filterRepeats or 0) > 0 then self.filterRepeats = self.filterRepeats - 1
        else self.pendingFilters = false end
    end
    if next(self.replies or {}) or self.pendingState or self.pendingFilters then self:ScheduleFlush() end
    self:Notify()
end

function Sync:Validate(data)
    if type(data) ~= "table" or data.version ~= 1 or data.catalog ~= CatalogVersion() then return false end
    if #Families() < 1 or #Families() > MAX_FAMILIES then return false end
    return Integer(data.kind, 0, 2) and Integer(data.roster, 0, UINT32)
        and Integer(data.epoch, 0, UINT32) and Integer(data.term, 0, UINT16)
        and Integer(data.revision, 0, UINT16) and Integer(data.leader, 1, #(self.members or {}))
        and Integer(data.mask, 0, 2 ^ #Families() - 1) and Integer(data.challenge, 0, UINT32)
end

function Sync:OnData(tag, data)
    if not self:CanRun() or not self:IsTransportReady() then return false end
    if Crown() ~= self.crown then self:RefreshContext() end
    if not self.context or not self:Validate(data) or data.roster ~= self.rosterHash then return false end
    if type(tag) ~= "string" or (tag ~= "player" and not tag:match("^group%d+$")) then return false end
    local sender = Key(Account(tag))
    local member = sender and self.byKey[sender]
    if not member or sender == self.own or Call(DoesUnitExist, tag) ~= true
        or Call(IsUnitOnline, tag) == false or Call(IsUnitGrouped, "player") ~= true then return false end
    if data.kind == 0 then
        if self.own ~= self.crown or data.challenge == 0 then return false end
        if Now() - (self.requestRates[sender] or -5000) < 5000 then return false end
        self.requestRates[sender], self.replies[sender] = Now(), data.challenge
        self:ScheduleFlush()
        return true
    end
    if data.kind == 1 then
        if sender ~= self.crown or data.epoch == 0 or data.term == 0 then return false end
        local challenged = self.challenge and data.challenge == self.challenge
        if not self.confirmed and not challenged then return false end
        if self.confirmed then
            if data.epoch ~= self.epoch and not challenged then
                -- A crown may reload or finish loading without a roster change.
                -- Its new epoch needs a fresh challenge; do not trust that packet.
                if Now() - (self.lastEpochRequestAt or -REQUEST_INTERVAL) >= REQUEST_INTERVAL then
                    self.lastEpochRequestAt = Now()
                    self:Invalidate()
                    self.challenge, self.pendingRequest = Nonce(), true
                    self:ScheduleFlush(); self:Notify()
                end
                return false
            end
            if data.epoch == self.epoch then
                if data.term < self.term then return false end
                if data.term == self.term and data.revision < self.revision then
                    if challenged and self.resendOnState and self.awaitingAck and self.own == self.leader then
                        self.resendOnState, self.pendingFilters, self.filterRepeats = false, true, 2
                        self:ScheduleFlush()
                    end
                    return false
                end
                if data.term == self.term and data.revision == self.revision then
                    local matches = data.mask == MaskOf(self.shared) and self.leader == self.members[data.leader].key
                    if matches then
                        self.pendingFilters, self.filterRepeats, self.challenge, self.pendingRequest = false, 0, nil, false
                        self.awaitingAck, self.resendOnState = false, false
                        self:Notify()
                    end
                    return matches
                end
            end
        end
        self.epoch, self.term, self.revision = data.epoch, data.term, data.revision
        self.leader, self.shared = self.members[data.leader].key, MapOf(data.mask)
        self.confirmed, self.pendingRequest, self.pendingFilters = true, false, false
        self.awaitingAck, self.resendOnState = false, false
        self.challenge = nil
        self:Notify()
        return true
    end
    if self.own ~= self.crown or sender ~= self.leader or data.epoch ~= self.epoch
        or data.term ~= self.term or data.leader ~= self.byKey[self.leader].index
        or data.revision <= self.revision then return false end
    self.revision, self.shared, self.pendingState, self.stateRepeats = data.revision, MapOf(data.mask), true, 2
    self:ScheduleFlush(); self:Notify()
    return true
end

function Sync:InitializeTransport()
    if self.registrationAttempted then return end
    local library = LibGroupBroadcast
    if type(library) ~= "table" or type(library.RegisterHandler) ~= "function"
        or type(library.CreateNumericField) ~= "function" then self.available = false; return end
    self.registrationAttempted = true
    local ok = pcall(function()
        local handler = library:RegisterHandler("AlphaSquadUIRaidSettings", "ASUIRaidSettings")
        assert(handler and type(handler.DeclareProtocol) == "function")
        self.handler = handler
        if handler.SetDisplayName then handler:SetDisplayName("Alpha Squad UI — Raid Settings") end
        if handler.SetDescription then handler:SetDescription("Shared raid leader and Ultimate filters only. Provisional protocol 511; reservation and coexistence validation pending.") end
        local protocol = handler:DeclareProtocol(self.PROTOCOL_ID, self.PROTOCOL_NAME)
        assert(protocol and Call(protocol.GetId, protocol) == self.PROTOCOL_ID
            and Call(protocol.GetName, protocol) == self.PROTOCOL_NAME)
        for _, field in ipairs({{"version",7},{"catalog",15},{"kind",3},{"roster",UINT32},
            {"epoch",UINT32},{"term",UINT16},{"revision",UINT16},{"leader",31},
            {"mask",16777215},{"challenge",UINT32}}) do
            protocol:AddField(library.CreateNumericField(field[1], {minValue=0,maxValue=field[2]}))
        end
        protocol:OnData(function(tag, data) Sync:OnData(tag, data) end)
        assert(protocol:Finalize({isRelevantInCombat=false,replaceQueuedMessages=true}) == true)
        self.protocol = protocol
    end)
    self.available = ok
end

function Sync:Initialize()
    if self.initialized then return end
    self.initialized, self.members, self.byKey = true, {}, {}
    self:InitializeTransport()
    local manager = EVENT_MANAGER
    if manager and manager.RegisterForEvent then
        local events = {EVENT_GROUP_MEMBER_JOINED, EVENT_GROUP_MEMBER_LEFT, EVENT_GROUP_UPDATE, EVENT_LEADER_UPDATE}
        for index = 1, 4 do
            local membershipChanged = index < 3
            if events[index] then manager:RegisterForEvent("AlphaSquadUI_RaidSettings_" .. index, events[index], function()
                Sync.lastContextAt = nil
                Sync:RefreshContext(membershipChanged)
            end) end
        end
        if EVENT_PLAYER_DEACTIVATED then manager:RegisterForEvent("AlphaSquadUI_RaidSettings_Load", EVENT_PLAYER_DEACTIVATED, function()
            Sync.loading = true; Sync:RefreshContext()
        end) end
        if EVENT_PLAYER_ACTIVATED then manager:RegisterForEvent("AlphaSquadUI_RaidSettings_Ready", EVENT_PLAYER_ACTIVATED, function()
            Sync.loading = false; Sync:RefreshContext(); Sync:ScheduleFlush()
        end) end
        if EVENT_PLAYER_COMBAT_STATE then manager:RegisterForEvent("AlphaSquadUI_RaidSettings_Combat", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
            if inCombat then Sync:RevokeQueued()
            else Sync:RefreshContext(); Sync:ScheduleFlush() end
        end) end
    end
    self:RefreshContext()
end

function Group:GetEffectiveTrackedFamilies() return Sync:GetEffectiveTrackedFamilies() end
function Group:CanEditFilters() return Sync:CanEditFilters() end
function Group:OnFiltersChanged(key, enabled) Sync:OnFiltersChanged(key, enabled) end
