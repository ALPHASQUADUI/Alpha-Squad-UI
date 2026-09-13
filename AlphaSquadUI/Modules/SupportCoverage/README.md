# Support Coverage — controlled branch test

Version: **2.7.0-support-coverage-test.4**. Development target: **support-coverage**. This is not an in-game-certified release.

## Open the module

Settings > Alpha Squad > Support Coverage > **DETAILS / HISTORY**, or `/assupport audit`.

The paginated inspector contains CHECKS, BUILD, EXPECTED, EFFECTS, PLANNER and HISTORY. `/assupport matrix` opens the planning matrix; `/assupport history` reopens stored pulls; `/assupport report` opens the latest stored report.

## Optional build checks

Sets, weapons, traits, enchantments, armor weights, Champion slottables, Class Masteries, skills, food, potion, poisons and Mundus each have OFF / WARN / REQUIRED modes. The detailed expectation checks default to OFF. No poison or meta loadout is mandatory.

Capture a verified build as the expected reference for a role/profile or a particular player. The Champion comparison defaults to the four Warfare slottables, ignores slot order and checks committed points. Fitness, Craft and all-discipline scopes are optional. An incomplete four-star reference is not accepted as a complete Champion expectation.

Sets are counted separately on each weapon bar; two-handed weapons count as two pieces and native normal/Perfected family mappings are used where available. Merely wearing one piece does not establish a five-piece capability. Set sharing uses native set IDs and normal/Perfected family normalization before any labelled name fallback. Skill and Class Mastery mappings use native ability IDs where known; runtime-localized names and labelled English hints are conservative fallbacks.

Class Masteries are read from committed skill data and eligibility, not searched for in action slots. Mundus uses the native active-buff index API. Missing APIs or missing peer fields produce UNKNOWN, not invented selections.

## Live coverage

Observable effects are collected by ID, with native buff-type classification for supported Major/Minor effects, session indexes and explicit custom IDs for other effects. Raw observations can be collected independently of the raid-focused display; retaining raw IDs in history is optional and off by default.

Metrics distinguish individual recipients, individual boss targets and group recipient coverage. Six-target effects are not automatically required on twelve players. Required stacks, target roles, recipient counts and uptime goals are configurable. Unknown time is shown separately and excluded from uptime; a minimum measured-data threshold prevents sparse observations from passing an uptime goal.

Boss targets are not OR-merged. Untargetable phases are observation gaps rather than proven downtime. The combat HUD prioritizes problems and shows UNVERIFIED when no reliable live conclusion is available.

## Potions and food

Expected food/potion selection can be compared with actual available fields. Food expiry, selected potion stack and cooldown are visible when available. Combat reports separate potion-category use events from inferred cooldown starts. Buffs also supplied by skills or allies are not automatically attributed to a potion. Exact consumed-item attribution remains unverified where the API does not provide it.

## Pull reports and history

Reports are named using observed encounter names, for example `Lokkestiiz - Pull 1`, and retain raid/zone, duration, profile and per-subject metrics. Closing a report does not delete it. It can be reopened in HISTORY. Automatic closing is configurable (20 seconds by default), and a new fight closes report/planning windows.

History is capped at 20 pulls by default (5–50 configurable), 1,024 metrics per pull, 20 subjects and 6,000 retained metrics overall. The tighter cap wins. Manual reset preserves settings. Leaving/disbanding the group clears reports and persisted session history; solo history is not retained. Optional reload recovery requires the same group fingerprint and expires after six hours.

## Sharing and non-ASUI players

Native group observations and the existing optional group Ultimate integration remain best-effort evidence. Without ASUI, unavailable equipment/CP/mastery/potion fields are clearly labelled `UNKNOWN`. A witnessed positive buff does not establish a complete remote inventory or its caster.

Experimental sharing is OFF by default. Enable it on matching test clients in CHECKS only for controlled group tests. Protocol IDs 507–510 remain unreserved and must not be publicly released as registered IDs. Signature-only build details, schema-checked live observations and potion evidence are bounded. Detail message kinds do not replace one another in the transport queue. Plan, pull-identity and unchanged potion heartbeats are rate-limited. Queuing/transit delays can make a field UNKNOWN; missing information is never replaced with a guessed value. Legacy wire positions are frozen; old clients cannot supply the new detailed fields.

## Planning and profiles

The planner selects whole current or recorded loadouts, not incompatible sets assembled independently. It prefers fewer changes, respects assignment constraints and never changes equipment. Recorded inventory availability still requires confirmation. Saved raid/boss context profiles include expectations, roles, locks and effect targets; optional auto-loading uses the observed context. Each context stores at most 32 expected templates for its active profile, and loading it preserves every other profile. Curated, patch-verified HM meta presets and a complete target-aware per-player penetration/critical-cap optimizer are not supplied by this test build. No guessed HM state or misleading final-cap number is displayed.

## Validation

Run `tests/support_coverage.lua`, `tests/ult_tracker.lua` and `tests/overload.lua` with Lua 5.1 and Lua 5.4 from the repository root. The GitHub workflow also validates syntax, manifest paths, version consistency and the installable ZIP. These deterministic tests do not establish ESO runtime/API behavior, real frame times, network throughput or visual correctness. Use the in-game test checklist before requesting any PR.
