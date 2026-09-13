# Ąlpha Şquad UI — Architecture

## Packages and Core

`AlphaSquadUI/` is the full ESO suite. The **AlphaSquadBuildShare** companion is a separate sharing-only installation for group members who do not want the UI suite; it uses the same compatible build format.

Core owns identity/version (`Core.lua`), theme tokens (`Theme.lua`), shared helpers (`Utils.lua`), event namespaces (`Events.lua`) and the settings-page bridge (`Settings.lua`). New pages register through:

```lua
AlphaSquadUI.Settings.RegisterPage(id, builder)
```

The settings shell implementation is hosted by Overload. Other modules use the Core bridge rather than relying on that ownership detail. The shared product label is **Ąlpha Şquad UI**, rendered with ESO's standard UI font.

## Module boundaries

| Component | Responsibility |
| --- | --- |
| Overload | Overload/morph state, reserve warnings, optional cancellation, ready reminder and HUD |
| Personal ULT | Actual MAIN/BACK slot data, charge/readiness, HUD and settings |
| Group ULT | LibGroupCombatStats ULT-only integration, ability filters, cached player state and compact HUD |
| Support catalog/sources | Patch-specific effects, source identities, descriptions and build-source matching |
| Support scanner/build | Local equipment, separate skill bars, Champion/mastery and consumable evidence |
| Support engine/lifecycle | Cached roster, precombat capability evaluation, context toggles, duplicate providers and event invalidation |
| Support external adapters | Optional LibSetDetection group set facts and compatible LibGroupCombatStats information with explicit data limits |
| Support share/details/codec | Bounded compatible snapshot transport and validation |
| Support UI/settings/inspector | Coverage list, Builds, Food, information tooltips and dependency guidance |

Some audit helpers remain for scanner/evidence compatibility. Their presence does not expose the old expected-build template workflow. Pull history, combat observation, live-report transport and recorded-build planner modules are retired from the runtime.

## Support Coverage data flow

Equipment, skill, Champion and mastery changes invalidate the local snapshot. Coalesced scans refresh supported local evidence outside combat. Validated compatible peer snapshots populate a bounded transient group cache. The engine evaluates enabled Trial/Dungeon requirements against that evidence, and reused controls render coverage, providers and detailed builds.

A five-second lightweight recovery refresh is limited to a relevant visible or grouped precombat state. Quickslot/readiness changes do not require rescanning every unrelated equipment slot. Support Coverage does not scan or send build data during combat; pending state is refreshed when combat ends. There is no pull sampler, report archive or uptime computation in this workflow.

## Evidence and transport boundaries

- Native ESO grouping supplies partial identity/class/visible-effect data, not arbitrary remote inventory or CP access.
- LibGroupCombatStats supplies compatible Ultimate/active-line facts; it is not the full-build transport and does not verify purchased passives or masteries.
- LibSetDetection v5 supplies reported sets and per-bar activation through its own registered transport. Hidden and unavailable sets are not proof of absence. Its public API has no timestamp: the adapter accepts update events received in the currently observed group session and records their local receipt time. It labels the data as last reported, without a short arbitrary TTL because this library sends changes rather than a heartbeat. Membership, identity, disconnect and deactivation events invalidate inappropriate records. Polling does not refresh evidence age.
- The full suite or companion supplies compatible build snapshots through LibGroupBroadcast.
- A snapshot must be complete, current and valid for its claimed fields; missing or stale data remains `UNKNOWN`.
- Internal set/ability identities must resolve to useful display names where available.
- One-bar source activation is valid when that bar reaches the required set threshold; proc and recipient conditions remain distinct.

Build-summary protocol **510** and detailed-build protocol **507** are provisional; the current wire version is **3**. The expanded capability bitmap is bound to the catalog schema. Full details are request-only, use acknowledged chunks and replace a receiver snapshot only after complete validation. Transfer limits are 64 chunks of at most 56 bytes, a minimum 1.2-second response gap and a 20-second inactivity timeout. Completed detail caches expire after 120 seconds and are invalidated on summary fingerprint changes or group reset.

Both active protocol IDs remain provisional. Legacy plan/live protocols **509/508** are retired. Active IDs must be reserved before a normal public sharing release. Experimental sharing remains disabled by default.

## Persistence

The suite preserves its established account/server SavedVariables names:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
AlphaSquadSupportCoverageSavedVariables
```

Group Ultimate settings remain inside the ULT Tracker namespace. Relevant Support Coverage visibility, geometry and effect preferences migrate conservatively. Retired workflow fields are not revived as current UI or an active report collector. Peer build snapshots are transient group data.

## Design constraints

Prefer events, coalescing, bounded caches and reused controls. Do not keep animation callbacks alive when hidden. Keep optional-library failures local to their integration. Preserve working module behavior and user preferences; avoid a broad rewrite where a targeted change is sufficient.

Development remains on `support-coverage`. In-game tests and an explicit maintainer PR request are required before proposing changes to stable `main`.
