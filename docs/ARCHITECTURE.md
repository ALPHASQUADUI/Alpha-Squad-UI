# Ąlpha Şquad UI — Architecture

## Packages and Core

`AlphaSquadUI/` is the full ESO suite. The **AlphaSquadBuildShare** companion is a separate sharing-only installation for group members who do not want the UI suite; it uses the same compatible build format.

Core owns identity/version (`Core.lua`), saved theme presets (`Theme.lua`), shared helpers (`Utils.lua`), module event scopes (`Events.lua`), account/character preferences (`Preferences.lua`), the settings-page bridge (`Settings.lua`), the standalone settings shell (`Shell.lua`), library preferences (`Sharing.lua`), global placement/resizing (`Layout.lua`) and foreground tooltip routing (`Tooltips.lua`). New pages register through:

```lua
AlphaSquadUI.Settings.RegisterPage(id, builder)
```

`Core/Shell.lua` creates and registers the settings shell independently of gameplay tracking. It remains accessible when ULT Tracker and Support Coverage are both disabled. The shared product label is **Ąlpha Şquad UI**, rendered with ESO's standard UI font.

`Core/AddOnMenu.lua` post-hooks the native Add-Ons manager's `BuildMasterList` once and augments only the suite's entry before native row sizing. Library availability uses the selected character's native addon records and dependency/version API, not Lua globals that remain loaded after a checkbox changes. Libraries remain optional at load time; missing group integrations do not disable local tracking. Compact Title/Author metadata stays within a 64-byte compatibility budget, including color codes. The static description is the fallback before the suite's Lua is loaded.

## Module boundaries

| Component | Responsibility |
| --- | --- |
| Personal ULT | Actual slot data, AUTO/FRONT/BACK/BOTH display, charge/readiness and the shared personal HUD |
| Integrated Overload | `ULTOverload.lua`: optional morph state, reserve warnings, native cancellation and ready reminder within the personal ULT lifecycle |
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

Dashboard invokes each module's lifecycle setter and hides disabled navigation entries. Core event scopes unregister gameplay callbacks and restore their exact filters on enable. The settings shell stays accessible when every gameplay module is disabled. Loading transitions stop local timers and defer scan/transfer work until activation.

Support Coverage runs its scanner and sender without HUD/coverage evaluation when sharing is enabled and the player is grouped. That mode uses a sixty-second recovery check; relevant local build changes still coalesce through native events. Library preferences remain separate from module activation. Group Ultimate reception and sending have separate LibGroupCombatStats registrations.

The Libraries bridge verifies the matching protocol identity and uses the library's native setting getters/setters. Supported option data can be read without opening or switching settings pages. First-install defaults are applied once; afterward, actual native settings and saved OFF choices are respected. Missing or incompatible controls remain unavailable. Only matching disabled messages are pruned; unrelated transports, incognito choices and shared library event registrations are preserved.

Core Preferences opens existing account namespaces by default and native character-ID namespaces when Cross-sync is off. Switching deep-copies the current values into the selected destination and updates the live module/Group ULT references. Core sharing choices remain account/server scoped. The settings shell also retains its position. Appearance is stored in the shared preferences system and follows Cross-sync. Ember Classic, Tactical Compact and default Obsidian Studio repaint registered native controls when selected or when the profile changes; they preserve fonts, geometry, icon identities, branding and semantic status/quality/discipline colors.


## Placement, compact grids and foreground dialogs

Core Layout opens a temporary placement state for enabled modules only. It closes suite configuration windows, returns to the native base game scene and temporarily shows eligible HUD panels without changing their normal visibility preference. Completion saves positions and restores locked interaction. Combat, loading and non-gameplay scene transitions end placement. It owns no recurring idle heartbeat. While an edge or corner is actively dragged, a temporary mouse-position callback applies the resize and is removed on completion/cancellation.

The personal ULT view owns a single HUD and shared resource state. AUTO follows the active weapon bar; optional Overload behavior uses cached slotted-morph state to take priority outside BOTH mode. BOTH preserves both cards. Existing display modes are retained, and supported legacy Overload options migrate into the personal ULT settings. No skill scan runs from layout checks or rendering. Group ULT remains independent.

Core Layout distinguishes corner scaling from edge reshaping. Corners preserve proportions; edges change saved logical width/height and invoke each panel's layout function. The shared toolbar owns scale, background opacity, reset and fitting to screen. Personal BOTH cards can stack, Group ULT rows adapt to the panel, and Support HUD elements reflow without stretching icons. Placement preserves module activation and normal visibility.

Coverage groups the current catalog into four categories and gives dense categories additional compact lanes. Layout is computed from category counts and the viewport; controls are pooled and filtering reuses them. Native icons, switches and contributor counts remain on one page. Effect hover explains conditions; contributor hover lists every available provider with source names and bar availability.

Native item, skill and Champion tooltips stay above the suite. External links use ESO's own confirmation dialog, with suite layering managed so the confirmation is visible. Sharing switches never navigate to another addon's configuration. The Website & About/Discord pages contain native ESO controls; Discord opens the configured widget URL through the native external-link confirmation. No HTML browser, member-count polling or generated invitation endpoint is embedded in the addon.

Incoming build data must satisfy both structural limits and consistency checks. Claimed complete equipment is reconciled with native slot identities and linked items, including two-handed weights and set-family totals. Contradictions cannot certify completeness. A consistent report remains sender-supplied information, not protection against a modified client deliberately reporting a different build.
