# Performance Guidelines

Performance is a design constraint for every Ąlpha Şquad UI module.

## Rules

1. Prefer ESO events over frequent polling.
2. Poll only as a fallback when the ESO API cannot guarantee a transition.
3. Dormant or disabled modules should not run fast update callbacks.
4. Fast animation callbacks must exist only while the animation is visible.
5. Reuse controls instead of recreating combat UI trees.
6. Avoid repeated scans of unrelated action slots.
7. Filter ESO events as narrowly as the API allows.
8. Avoid copying data structures that are not used.
9. Avoid automatic gameplay chat formatting unless debug/status output was requested.
10. Document every persistent heartbeat.

## Overload

Primary tracking uses effect, power, slot, hotbar and player-activation events.

A 1-second safety sync runs only while Overload Tracker is enabled, visible, unobscured, not PvP-suppressed and not dormant. Hidden and dormant states rely on native events and register no recovery polling update.

Emergency and Ready Reminder animation loops register only while their alert is active.

## Personal ULT Tracker

Primary tracking is event-driven.

A 1.5-second safety refresh remains for rare missed slot/resource transitions only while the personal tracker is enabled, visible and unobscured.

The 80 ms READY animation update is registered only while a tracked Ultimate is READY and flash is enabled.

## Group Ultimate Tracker

AlphaSquadUI registers with LibGroupCombatStats for **ULT only**.

Incoming ULT callbacks update the cached entry for the affected unit instead of rebuilding and re-querying the whole raid roster.

Full roster scans are reserved for:

- initialization
- member join/leave/update events
- connectivity changes
- the 2-second safety sync while Group Tracking and its parent module are enabled, visible and unobscured

The raidlead UI reuses a fixed pool of 12 rows.

The READY pulse exists only while at least one visible tracked player is READY.

## Support Coverage

Build scans are invalidated by equipment, skill and Champion events. Active-quickslot changes refresh only lightweight food/potion/Mundus readiness facts. The slower 2.5-second recovery sync runs only while the module is enabled and its HUD or settings are relevant.

Combat observation uses one active 1.5-second update only during a pull, plus coalesced local effect events. Disconnected group members cannot prolong the quiet-period check with stale combat state. Pull identity, unchanged potion evidence and leader plans use bounded heartbeats; build and live messages also have minimum send intervals. Peer caches, history, effects, subjects, tracked IDs, context templates and planner candidates all have absolute limits.

Hidden report/settings windows reuse controls and do not require continuous rebuilding. Disabling the module stops combat and recovery updates and clears transient sharing state.

## Validation

The GitHub workflows validate Lua 5.1/5.4 syntax, deterministic Support Coverage, ULT Tracker and Overload lifecycle behavior, manifest integrity and release-version consistency, then verify a ZIP artifact.

In-game validation remains mandatory because `luac` cannot verify ESO API semantics, scene behavior, protected-function rules or actual combat timing.
