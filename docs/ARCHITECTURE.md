# Ąlpha Şquad UI — Architecture

## Packages and Core

`AlphaSquadUI/` is the full ESO suite. The **AlphaSquadBuildShare** companion is a separate sharing-only installation for group members who do not want the UI suite; it uses the same compatible build format.

Core owns identity/version (`Core.lua`), theme tokens (`Theme.lua`), shared helpers (`Utils.lua`), module event scopes (`Events.lua`) and account/character preferences (`Preferences.lua`), the settings-page bridge (`Settings.lua`) centralized library preferences (`Sharing.lua`), temporary global placement (`Layout.lua`) and shared foreground tooltip routing (`Tooltips.lua`). New pages register through:

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
| Support UI/settings/inspector | Categorized Coverage, build selection and integrated consumable readiness |
| Support BuildView | Compact equipment silhouette, set summaries, skill/Ultimate and Champion icons |
| Core tooltip routing | Native item/ability details and readable custom descriptions above addon windows |

Some audit helpers remain for scanner/evidence compatibility. Their presence does not expose the old expected-build template workflow. Pull history, combat observation, live-report transport and recorded-build planner modules are retired from the runtime.

## Support Coverage data flow

Equipment, skill, Champion and mastery changes invalidate the local snapshot. Coalesced scans refresh supported local evidence outside combat. Validated compatible peer snapshots populate a bounded transient group cache. The engine evaluates enabled Trial/Dungeon requirements against that evidence, and reused controls render coverage, providers and detailed builds.

A five-second lightweight recovery refresh is limited to a relevant visible or grouped precombat state. Quickslot/readiness changes do not require rescanning every unrelated equipment slot. Support Coverage does not scan or send build data during combat; pending state is refreshed when combat ends. There is no pull sampler, report archive or uptime computation in this workflow.

## Build presentation

`SupportCoverageBuildView.lua` renders the selected build as a compact character view. Equipment placement represents body slots, jewelry and each weapon bar. It is not a native remote-character inventory API or a 3D character renderer. Set-summary headlines use the highest known per-bar piece total, preserve separate FRONT/BACK values and apply two-handed weights. Physical item counts remain explanatory data instead of being summed across bars. Native set-bonus requirements determine excess warnings; a bounded positive cache avoids repeated requirement reads. Partial bar evidence produces a lower bound and never guesses the missing total. The normal weapon bars remain separate from a reported Werewolf bar. Twelve Champion positions, mastery icons and compact consumable/character cards complete the view.

`Core/Tooltips.lua` centralizes foreground layering and native/custom tooltip routing. Item details are tied to the actual item link; ability details are tied to the selected skill or morph. Native item-tooltip set counters still refer to the viewing player, so the tooltip directs the user to the inspected build's own per-bar summary. Native descriptions on a receiving client do not establish the remote player's stat-scaled combat values. Champion descriptions use the sender's verified allocated points; missing allocations are not substituted with the viewer's values. Missing snapshot fields remain unknown, including unsupported transformation details and Vampire stage.

## Evidence and transport boundaries

- Native ESO grouping supplies partial identity/class/visible-effect data, not arbitrary remote inventory or CP access.
- LibGroupCombatStats supplies compatible Ultimate/active-line facts; it is not the full-build transport and does not verify purchased passives or masteries.
- LibSetDetection v5 supplies reported sets and per-bar activation through its own registered transport. Hidden and unavailable sets are not proof of absence. Its public API has no timestamp: the adapter accepts update events received in the currently observed group session and records their local receipt time. It labels the data as last reported, without a short arbitrary TTL because this library sends changes rather than a heartbeat. Membership, identity, disconnect and deactivation events invalidate inappropriate records. Polling does not refresh evidence age.
- The full suite or companion supplies compatible build snapshots through LibGroupBroadcast.
- A snapshot must be complete, current and valid for its claimed fields; missing or stale data remains `UNKNOWN`.
- Internal set/ability identities must resolve to useful display names where available.
- One-bar source activation is valid when that bar reaches the required set threshold; proc and recipient conditions remain distinct.

Build-summary protocol **510** and detailed-build protocol **507** are provisional; the current wire version is **3**. The binary build schema is **2**, with a compatibility reader for schema **1**. The newer snapshot carries separate Werewolf-bar data, verified curse/form state, ability ranks and verified Champion allocations. Older snapshots do not acquire these facts by default; ambiguous old Champion points remain unknown. The expanded capability bitmap is bound to the catalog schema. Full details are request-only, use acknowledged chunks and replace a receiver snapshot only after complete validation. Transfer limits are 64 chunks of at most 56 bytes, a minimum 1.2-second response gap and a 20-second inactivity timeout. Completed detail caches expire after 120 seconds and are invalidated on summary fingerprint changes or group reset.

Both active protocol IDs remain provisional. Legacy plan/live protocols **509/508** are retired. Active IDs must be reserved before a normal public sharing release. New installations enable supported sharing once when dependencies are available; existing saved OFF choices remain authoritative. Default activation does not establish formal protocol registration or public coexistence validation.

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

Maintainer review and the ESO acceptance checklist are required before release.

## Independent tracking, sharing and profiles

Dashboard invokes each module's lifecycle setter and hides disabled navigation entries. Core event scopes unregister gameplay callbacks and restore their exact filters on enable. The settings shell stays accessible when Overload is disabled. Loading transitions stop local timers and defer scan/transfer work until activation.

Support Coverage runs its scanner and sender without HUD/coverage evaluation when sharing is enabled and the player is grouped. That mode uses a sixty-second recovery check; relevant local build changes still coalesce through native events. Library preferences remain separate from module activation. Group Ultimate reception and sending have separate LibGroupCombatStats registrations.

The Libraries bridge verifies the matching protocol identity and uses the library's native setting getters/setters. Supported option data can be read without opening or switching settings pages. First-install defaults are applied once; afterward, actual native settings and saved OFF choices are respected. Missing or incompatible controls remain unavailable. Only matching disabled messages are pruned; unrelated transports, incognito choices and shared library event registrations are preserved.

Core Preferences opens existing account namespaces by default and native character-ID namespaces when Cross-sync is off. Switching deep-copies the current values into the selected destination and updates the live module/Group ULT references. Core sharing choices remain account/server scoped. The settings shell also retains its position.


## Placement, compact grids and foreground dialogs

Core Layout opens a temporary placement state for enabled modules only. It closes suite configuration windows, returns to the native base game scene and temporarily shows eligible HUD panels without changing their normal visibility preference. Completion saves positions and restores locked interaction. Combat, loading and non-gameplay scene transitions end placement. It owns no animation or heartbeat loop.

Overload's cached slotted-morph state determines whether the dedicated Overload panel replaces the personal ULT view. No skill scan runs from layout checks or rendering. Group ULT remains independent.

Coverage groups the current catalog into four categories and gives dense categories additional compact lanes. Layout is computed from category counts and the viewport; controls are pooled and filtering reuses them. Native icons, switches and contributor counts remain on one page. Effect hover explains conditions; contributor hover lists every available provider with source names and bar availability.

Native item, skill and Champion tooltips stay above the suite. External links use ESO's own confirmation dialog, with suite layering managed so the confirmation is visible. Sharing switches never navigate to another addon's configuration.

Incoming build data must satisfy both structural limits and consistency checks. Claimed complete equipment is reconciled with native slot identities and linked items, including two-handed weights and set-family totals. Contradictions cannot certify completeness. A consistent report remains sender-supplied information, not protection against a modified client deliberately reporting a different build.
