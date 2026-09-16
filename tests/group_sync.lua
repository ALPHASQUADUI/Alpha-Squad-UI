-- Independent clients exercise the real settings authority and untrusted wire boundary.
local assertions = 0
local function check(value, message) assertions = assertions + 1; assert(value, message) end
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function Load(path, env)
    if setfenv then local chunk = assert(loadfile(path)); setfenv(chunk, env); chunk()
    else assert(loadfile(path, "t", env))() end
end
local now, timers, frames, members, crown, clients
local function Reset()
    now, timers, frames, clients = 10000, {}, {}, {}
    members, crown = {"@Alice", "@Bob", "@Carol"}, "@Alice"
end
local function Advance(ms)
    local untilTime = now + ms
    while true do
        local found, time
        for index, timer in ipairs(timers) do
            if timer.at <= untilTime and (not time or timer.at < time) then found, time = index, timer.at end
        end
        if not found then break end
        now = time; local timer = table.remove(timers, found); timer.fn()
    end
    now = untilTime
end
local function Tag(key)
    for index, member in ipairs(members) do if member == key then return "group" .. index end end
end
local function Client(key, options)
    options = options or {}
    local env = setmetatable({}, {__index=_G}); env._G = env
    local client = {key=key, env=env, events={}, options=options, registrations=0}
    clients[key] = client
    local function Account(tag)
        if tag == "player" then return key end
        local index = type(tag) == "string" and tonumber(tag:match("^group(%d+)$"))
        return index and members[index] or ""
    end
    env.GetUnitDisplayName, env.GetGroupLeaderUnitTag = Account, function() return Tag(crown) end
    env.GetGroupSize = function() client.rosterScans = (client.rosterScans or 0) + 1; return #members end
    env.GetGroupUnitTagByIndex = function(index) return "group" .. index end
    env.IsUnitGrouped = function() return #members > 0 end
    env.DoesUnitExist = function(tag) return Account(tag) ~= "" end
    env.IsUnitOnline = function() return not client.offline end
    env.IsUnitInCombat = function() return client.combat == true end
    env.GetWorldName = function() return "Test Realm" end
    env.GetGameTimeMilliseconds = function() return now end
    env.GetTimeStamp = function() return 1234567890 end
    env.zo_callLater = function(fn, delay) timers[#timers + 1] = {fn=fn, at=now + delay} end
    for index, name in ipairs({"EVENT_GROUP_MEMBER_JOINED", "EVENT_GROUP_MEMBER_LEFT", "EVENT_GROUP_UPDATE",
        "EVENT_LEADER_UPDATE", "EVENT_PLAYER_DEACTIVATED", "EVENT_PLAYER_ACTIVATED", "EVENT_PLAYER_COMBAT_STATE"}) do env[name] = index end
    env.EVENT_MANAGER = {RegisterForEvent=function(_, name, event, callback) client.events[event] = callback end}
    local Group = {sv={enabled=true,trackedFamilies={horn=true,barrier=true,cryptcanon=false}}, catalogVersion=1,
        catalogFamilies={{key="horn"},{key="barrier"},{key="cryptcanon"}},
        ScheduleRefresh=function() client.refreshes = (client.refreshes or 0) + 1 end,
        RefreshIntegratedSettings=function() client.settingsRefreshes = (client.settingsRefreshes or 0) + 1 end}
    local ULT = {sv={enabled=true}, Group=Group}
    env.AlphaSquadUI = {Modules={ULTTracker=ULT}}
    local library = {CreateNumericField=function(name, bounds) return {name=name,bounds=bounds} end}
    function library:RegisterHandler(addonName, handlerName)
        client.registrations = client.registrations + 1
        check(addonName == "AlphaSquadUIRaidSettings" and handlerName == "ASUIRaidSettings", "Independent settings handler cannot replace build sharing")
        return {SetDisplayName=function() end, SetDescription=function() end, DeclareProtocol=function(_, id, name)
            check(id == 511 and name == "AlphaSquadRaidSettings", "Only provisional settings protocol 511 is declared")
            if options.collision then error("already registered") end
            local protocol = {id=id,name=name,enabled=not options.nativeOff,fields={}}
            function protocol:GetId() return options.wrongId and 507 or self.id end
            function protocol:GetName() return options.wrongName and "OtherAddon" or self.name end
            function protocol:IsEnabled() if options.enabledError then error("unavailable") end; return self.enabled end
            function protocol:AddField(field) self.fields[#self.fields + 1] = field end
            function protocol:OnData(callback) self.receive = callback end
            function protocol:Finalize(config) self.config = config; return not options.badFinalize end
            function protocol:Send(data, config)
                client.sendAttempts = (client.sendAttempts or 0) + 1
                if options.sendError then error("unavailable") end
                if options.rejectSend then return false end
                frames[#frames + 1] = {sender=key,data=copy(data),at=now,config=copy(config)}
                return true
            end
            client.protocol = protocol
            return protocol
        end}
    end
    if not options.missingLibrary then env.LibGroupBroadcast = library end
    Load("AlphaSquadUI/Modules/ULTTracker/ULTGroupSync.lua", env)
    client.Group, client.ULT, client.Sync = Group, ULT, Group.Sync
    client.Sync:Initialize()
    return client
end
local function Deliver(frame, client)
    return client.Sync:OnData(Tag(frame.sender) or "group24", copy(frame.data))
end
local function Broadcast()
    local batch = frames; frames = {}
    for _, frame in ipairs(batch) do for key, client in pairs(clients) do if key ~= frame.sender then Deliver(frame, client) end end end
    return batch
end
local function Settle()
    for _ = 1, 7 do Advance(1600); Broadcast() end
end
local function Edit(client, key, value)
    if not client.Group:CanEditFilters() then return false end
    client.Group.sv.trackedFamilies[key] = value
    client.Group:OnFiltersChanged(key, value)
    return true
end

Reset()
local alice, bob, carol = Client("@Alice"), Client("@Bob"), Client("@Carol")
check(alice.Sync:CanAssignLeader() and not bob.Sync:CanAssignLeader(), "Only the native crown can designate an RL")
check(alice.Group:CanEditFilters() and not bob.Group:CanEditFilters(), "Native crown is the default editor")
check(not alice.Sync:SetLeader("@Outside"), "Nonmembers cannot be nominated")
check(not bob.Sync:SetLeader("@Bob"), "A member cannot self-nominate")
local initial = alice.Sync:Payload(1)
check(not Deliver({sender="@Alice",data=initial}, bob), "Unsolicited initial state is not trusted without a fresh challenge")
Settle()
check(bob.Sync.confirmed and carol.Sync.confirmed, "Joining peers converge after bounded crown challenge responses")
check(bob.Sync:GetLeader() == "@Alice" and bob.Sync:GetStatus() == "Raid settings follow the selected raid leader", "Confirmed state exposes actual authority")
check(#alice.Sync:GetMembers() == 3 and alice.Sync:GetMembers()[1].isCrown, "Dropdown has bounded native accounts and crown identity")
check(alice.protocol.config.isRelevantInCombat == false and alice.protocol.config.replaceQueuedMessages == true, "Settings traffic is precombat and replaces queued stale state")
local bits = 0
for _, field in ipairs(alice.protocol.fields) do
    local n = field.bounds.maxValue; local count = 0
    repeat count = count + 1; n = math.floor(n / 2) until n == 0
    bits = bits + count
    check(field.name ~= "account" and field.name ~= "build", "Frames contain no account or build fields")
end
check(bits == 166, "A complete settings frame uses 166 payload bits")
local untouchedLocal = copy(bob.Group.sv.trackedFamilies)
check(Edit(alice, "cryptcanon", true), "Crown changes a filter")
Settle()
check(bob.Group:GetEffectiveTrackedFamilies().cryptcanon and bob.Group.sv.trackedFamilies.cryptcanon == untouchedLocal.cryptcanon,
    "Remote shared filters are transient and do not overwrite persistent preferences")
check(alice.Sync:SetLeader("@Bob"), "Crown can nominate a grouped delegate")
Settle()
check(bob.Group:CanEditFilters() and not alice.Group:CanEditFilters() and not carol.Group:CanEditFilters(), "Only designated RL edits after delegation")
check(Edit(bob, "barrier", false), "Designated RL changes a filter")
Settle()
check(not alice.Group:GetEffectiveTrackedFamilies().barrier and not carol.Group:GetEffectiveTrackedFamilies().barrier,
    "Delegate settings are relayed by the verified crown")
check(carol.Group:GetEffectiveTrackedFamilies().cryptcanon, "Delegate's differing local defaults cannot reset unrelated shared filters")
local accepted = alice.Sync:Payload(1)
local wrongSender = copy(accepted); wrongSender.revision = wrongSender.revision + 1; wrongSender.mask = 0
check(not Deliver({sender="@Carol",data=wrongSender}, bob), "A peer cannot impersonate crown by copying its fields")
check(not alice.Sync:OnData("target", bob.Sync:Payload(2)), "Only native group/player sender tags are accepted")
local wrongRole = carol.Sync:Payload(2); wrongRole.revision = wrongRole.revision + 1
check(not Deliver({sender="@Carol",data=wrongRole}, alice), "Crown rejects unauthorized peer filter proposals")
local stale = copy(accepted); stale.revision = math.max(0, stale.revision - 1)
check(not Deliver({sender="@Alice",data=stale}, carol), "Older revisions cannot roll shared filters back")
for _, field in ipairs({"version","catalog","kind","roster","epoch","term","revision","leader","mask","challenge"}) do
    local malformed = copy(accepted); malformed[field] = 0 / 0
    check(not Deliver({sender="@Alice",data=malformed}, carol), "NaN rejected for " .. field)
    malformed[field] = "1"
    check(not Deliver({sender="@Alice",data=malformed}, carol), "String coercion rejected for " .. field)
end
local extra = copy(accepted); extra.mask = 2 ^ #alice.Group.catalogFamilies
check(not Deliver({sender="@Alice",data=extra}, carol), "Unknown family bits fail closed")
extra = copy(accepted); extra.catalog = 2
check(not Deliver({sender="@Alice",data=extra}, carol), "Unknown catalog versions cannot invert family filters")
local oldTerm = bob.Sync:Payload(2); oldTerm.revision = oldTerm.revision + 1
check(alice.Sync:SetLeader("@Alice"), "Crown can reclaim RL authority")
Settle()
check(not Deliver({sender="@Bob",data=oldTerm}, alice), "Previous delegate packets are invalid after the crown changes term")
check(alice.Group:CanEditFilters() and not bob.Group:CanEditFilters(), "Reclaimed authority is reflected by every client")
alice.Group:OnFiltersChanged(nil, false)
Settle()
check(not bob.Group:GetEffectiveTrackedFamilies().horn and not bob.Group:GetEffectiveTrackedFamilies().cryptcanon, "Clear all shares one coherent full mask")
alice.Group:OnFiltersChanged(nil, true)
Settle()
check(bob.Group:GetEffectiveTrackedFamilies().horn and bob.Group:GetEffectiveTrackedFamilies().cryptcanon, "Track all shares one coherent full mask")

frames = {}
for index = 1, 30 do Edit(alice, "horn", index % 2 == 0) end
Advance(149); check(#frames == 0, "Rapid UI edits are coalesced before sending")
Advance(1); check(#frames == 1 and frames[1].data.mask == 7, "One initial frame carries the final rapid-edit state")
Advance(5000)
check(#frames == 3 and frames[2].data.revision == frames[1].data.revision and frames[3].data.mask == 7,
    "Two bounded repeat frames improve delivery without repeating obsolete edits")
check(frames[2].at - frames[1].at >= 1500 and frames[3].at - frames[2].at >= 1500, "Snapshot repeats respect the traffic cap")
Broadcast()
local request = bob.Sync:Payload(0, 1234)
check(Deliver({sender="@Bob",data=request}, alice), "Known member can request a bounded snapshot")
check(not Deliver({sender="@Bob",data=request}, alice), "Repeated member requests are rate limited")
alice.combat = true; frames = {}; Advance(2000)
check(#frames == 0 and not Edit(alice, "horn", false), "Combat suspends sends and edits")
check(not Deliver({sender="@Bob",data=request}, alice), "Combat receive path performs no settings work")
alice.combat = false; alice.events[alice.env.EVENT_PLAYER_COMBAT_STATE](0, false); Settle()
check(bob.Group:GetEffectiveTrackedFamilies().horn, "Pending work resumes out of combat")

local beforeReload = alice.Sync.epoch
alice.events[alice.env.EVENT_PLAYER_DEACTIVATED]()
check(not alice.Sync.context, "Loading invalidates pending sessions")
alice.events[alice.env.EVENT_PLAYER_ACTIVATED]()
check(alice.Sync.epoch ~= beforeReload, "Crown resumes with a new session epoch")
Settle()
check(bob.Sync.confirmed and bob.Sync.epoch == alice.Sync.epoch, "Crown reload causes a new challenge instead of accepting an unsolicited epoch")

local oldRosterPacket = alice.Sync:Payload(1)
members = {"@Carol", "@Alice", "@Bob"}
for _, client in pairs(clients) do client.events[client.env.EVENT_GROUP_UPDATE]() end
check(bob.Sync.confirmed, "Reordering native group tags preserves sorted account identity")
members = {"@Alice", "@Bob"}
for _, client in pairs(clients) do client.events[client.env.EVENT_GROUP_MEMBER_LEFT]() end
check(not Deliver({sender="@Alice",data=oldRosterPacket}, bob), "A prior roster frame cannot affect a changed group")
Settle()
crown = "@Bob"
for _, client in pairs(clients) do client.Sync:RefreshContext() end
Settle()
check(bob.Group:CanEditFilters() and not alice.Group:CanEditFilters() and alice.Sync:GetLeader() == "@Bob", "Native crown transfer discards former authority")
check(not Deliver({sender="@Alice",data=oldRosterPacket}, bob), "Former native crown loses all packet authority")
members = {}
for _, client in pairs(clients) do client.Sync:RefreshContext() end
check(alice.Group:CanEditFilters() and alice.Group:GetEffectiveTrackedFamilies() == alice.Group.sv.trackedFamilies,
    "Leaving the group restores local preferences without persistent remote history")

for _, options in ipairs({{missingLibrary=true},{collision=true},{wrongId=true},{wrongName=true},{badFinalize=true},{nativeOff=true},{enabledError=true}}) do
    Reset(); local client = Client("@Alice", options); Advance(100000)
    check(#frames == 0 and not client.Sync:CanAssignLeader(), "Missing, conflicting or disabled native transport never sends")
    if client.protocol then check(client.protocol.enabled == not options.nativeOff, "Existing native OFF is never overridden") end
    client.Sync:InitializeTransport()
    check(client.registrations <= 1, "Incompatible registration cannot enter a retry storm")
end
Reset(); alice, bob = Client("@Alice"), Client("@Bob")
Settle(); bob.protocol.enabled = false
local disabledFrame = alice.Sync:Payload(1); disabledFrame.revision = disabledFrame.revision + 1
check(not Deliver({sender="@Alice",data=disabledFrame}, bob), "Native OFF also blocks accepting shared settings")
check(bob.Group:GetEffectiveTrackedFamilies() == bob.Group.sv.trackedFamilies, "Native OFF displays local filters instead of stale synchronized claims")
check(bob.Sync:GetStatus() == "Raid settings sending is disabled in LibGroupBroadcast.", "Native OFF has an explicit status")
alice.Group.sv.enabled = false; alice.Sync:RefreshContext(); frames = {}; Advance(100000)
check(#frames <= 3 and not alice.Sync.context, "Disabled group module invalidates its queued callbacks")
Reset(); bob = Client("@Bob"); Advance(1000000)
check(#frames == 3 and not bob.Sync.confirmed and #timers == 0, "Absent crown addon produces at most three requests and no permanent polling")
check(not bob.Group:CanEditFilters(), "Missing authority never grants a peer edit privileges")
Reset(); alice = Client("@Alice", {rejectSend=true}); Advance(1000000)
check(#timers == 0 and #frames == 0 and alice.sendAttempts == 3, "Rejected library sends stop after three attempts")
check(alice.Sync:GetStatus() == "Raid settings update could not be sent.", "Exhausted retries never claim successful synchronization")

Reset(); alice, bob = Client("@Alice"), Client("@Bob"); Settle()
local scans = bob.rosterScans
bob.Sync:GetMembers(); bob.Sync:GetLeader(); bob.Sync:CanAssignLeader()
for _ = 1, 24 do bob.Group:CanEditFilters() end
check(bob.rosterScans <= scans + 1, "Settings controls share at most one native roster scan per frame")
check(alice.Sync:SetLeader("@Bob"), "Delegate established for lost-proposal recovery")
Settle(); frames = {}
check(Edit(bob, "cryptcanon", true), "Delegate issues a new filter proposal")
Advance(6000); frames = {}
check(bob.Sync.awaitingAck and bob.Sync:GetStatus() == "Raid settings update pending", "Lost proposals remain pending until crown acknowledgment")
check(not alice.Group:GetEffectiveTrackedFamilies().cryptcanon, "Dropping all proposals cannot modify crown state")
check(bob.Sync:RequestRefresh() and not bob.Sync:RequestRefresh(), "Opening settings requests bounded repair once per ten seconds")
Settle()
check(alice.Group:GetEffectiveTrackedFamilies().cryptcanon and not bob.Sync.awaitingAck,
    "Fresh crown state on reopening repairs a lost delegate proposal without overriding newer authority")
Advance(10000); frames = {}; check(bob.Sync:RequestRefresh(), "A later settings open may request current state")
check(Deliver({sender="@Alice",data=alice.Sync:Payload(1)}, bob), "A same-state crown broadcast reconfirms the settings before request flush")
Advance(1600)
check(#frames == 0 and not bob.Sync.pendingRequest, "Reconfirmation cancels the pending request rather than sending a zero challenge")
local changed = alice.Sync:Payload(1); changed.mask = 0
check(not Deliver({sender="@Alice",data=changed}, bob), "Conflicting equal-revision snapshots cannot rewrite confirmed values")
frames = {}; alice.combat = true; alice.events[alice.env.EVENT_PLAYER_COMBAT_STATE](0, true)
check(#frames == 1 and frames[1].data.version == 0 and frames[1].data.mask == 0, "Combat replaces potentially queued settings with an owned neutral frame")
Advance(100000); check(#frames == 1, "No settings snapshots are queued during combat")
check(not Deliver(frames[1], bob), "Neutral queue revocation is always ignored by receivers")
alice.combat = false; alice.events[alice.env.EVENT_PLAYER_COMBAT_STATE](0, false)
bob.protocol.enabled = false; frames = {}; bob.ULT.loading = true; bob.Sync:RefreshContext()
check(#frames == 0 and bob.protocol.enabled == false, "Queue cleanup never enables or sends through native OFF")

Reset(); alice = Client("@Alice", {rejectSend=true}); Advance(150)
alice.options.rejectSend = false; Advance(1700)
check(#frames > 0 and not alice.Sync.sendFailed, "Transient native send failure recovers within the bounded retry window")
Reset(); bob = Client("@Bob")
crown = "@Outside"; bob.Sync:RefreshContext()
check(not bob.Group:CanEditFilters() and not bob.Sync:CanAssignLeader(), "An unresolved native crown cannot grant local edit authority")
check(bob.Sync:GetStatus() == "Waiting for the group leader's raid settings.", "Unknown grouped authority is presented as waiting, never solo")
Reset(); bob = Client("@Bob")
members = {"@Alice", "@Bob", "@Bob"}; bob.events[bob.env.EVENT_GROUP_MEMBER_JOINED]()
check(not bob.Group:CanEditFilters() and not bob.Sync.context, "Duplicate native accounts fail closed")
Reset(); bob = Client("@Bob"); bob.Group.sv.enabled = false; bob.Sync:RefreshContext()
check(not bob.Group:CanEditFilters(), "A disabled grouped module cannot bypass the native RL restriction")
Reset(); alice = Client("@Alice"); alice.env.IsUnitInCombat = false; frames = {}; Advance(100000)
check(#frames == 0 and not alice.Group:CanEditFilters(), "Unavailable native combat state fails closed")
Reset(); alice = Client("@Alice"); alice.protocol.id = 507; frames = {}; Advance(100000)
check(#frames == 0, "A changed protocol identity never sends to a build or unrelated protocol")

print("Group settings sync: " .. assertions .. " assertions passed")
