# Support Coverage test checklist

Version: 2.7.0-support-coverage-test.4. Existing SavedVariables namespace/version are retained. Overload gameplay behavior is preserved while its hidden/dormant heartbeat and malformed SavedVariables handling are hardened. ULT Tracker lifecycle and defensive handling were also hardened and therefore require regression testing below.

## Automated checks

The deterministic suites are `tests/support_coverage.lua`, `tests/ult_tracker.lua` and `tests/overload.lua`. They exercise initialization without libraries, partial protocol failures, optional modes, native buff/set/skill/mastery identities, Mundus, missing data, lightweight quickslot refresh, elapsed-time uptime and gaps, separate targets, Champion comparisons, stable wire masks, malformed/non-member messages, transport throttles, corrupt and bounded persistence, profile-isolated context restore, UI pagination/geometry, report reopen/reset behavior, active-bar set thresholds, two-handed weapons, localized and mixed Perfected families, unknown set IDs, monster sets, encounter pull labels, joining a formed group, combat already in progress, disconnected combat-state recovery, ULT lifecycle behavior and Overload heartbeat lifecycle. Both Lua 5.1 and Lua 5.4 are used by the branch workflow. A successful test result is not an ESO-runtime certification.

Run the suites from the repository root:

```sh
lua5.1 tests/support_coverage.lua
lua5.4 tests/support_coverage.lua
lua5.1 tests/ult_tracker.lua
lua5.4 tests/ult_tracker.lua
lua5.1 tests/overload.lua
lua5.4 tests/overload.lua
```

For `test.4`, each runtime should pass 226 Support Coverage assertions, 38 ULT Tracker assertions and 9 Overload assertions (273 total). The branch workflow also validates all addon Lua syntax, manifest paths, version consistency and ZIP integrity before uploading the installable test artifact.

## In-game acceptance

Download the installable branch artifact using [these instructions](../releases/README.md#support-coverage-test-candidate). Record the commit SHA and client/library versions with any test result. Back up the existing addon and SavedVariables before installation. Start with experimental sharing disabled; do not treat the checklist below as completed until it has actually been exercised in ESO.

1. Fresh and migrated SavedVariables; no optional libraries; disable/re-enable; no unsolicited chat output.
2. One/four/five-piece sets, main-only/back-only, two-handed weapons, monster/mythic/arena sets, normal/Perfected/mixed families. Check against native tooltips.
3. Four expected Warfare stars; change ID, order and committed points; test Fitness/Craft/ALL and an uncommitted respec.
4. Purchased/unpurchased Class Masteries, rank-two prerequisites, subclassing and native-line eligibility. Verify the live U50 mastery names/IDs and confirm no fabricated selection when data is unavailable.
5. Correct/wrong/expired food; no food library; selected non-potion; potion stack/cooldown; potion-category evidence; pre-pots, death, empty stack, poisons disabled and Mundus.
6. Matching ASUI clients, old ASUI, no ASUI, joining an already formed group, late join, reconnect, character changes, stale details and experimental sharing OFF. Native set sharing must work on clients using different languages. Unknown must never become a false PASS.
7. Multiple bosses with different debuffs and stack counts, untargetable phases, recipient limits and partial group observations. Check current target labels and gaps.
8. Wipe, local death while group continues fighting, group formation after local combat has begun, transient combat exit, late combat entry, clock skew and late packets from the previous pull.
9. Close/reopen reports, automatic close, new combat, maximum history, manual reset, disband, leave/rejoin and reload with the same/different group. Verify encounter names and numbering.
10. HUD movement/scale/row height at 720p, 1080p and ultrawide. Matrix and inspector pagination must retain all requirements and settings.
11. Recorded-loadout proposals must choose one complete build per player, preserve manual choices and never equip anything. Save/load boss and trash contexts after capturing templates in multiple profiles; loading one profile must preserve the others. Recalculate after build changes.
12. Measure actual frame time, memory and group-broadcast queue behavior with twelve players and existing raid addons.
13. Personal ULT: MAIN/BACK/BOTH, bar swap, spend, READY sound/pulse, hidden/disabled/menu states and `/reloadui` persistence.
14. Group ULT: late join, leave/rejoin, dead/offline/revived players, empty tracked list, 24-entry limit and missing LibGroupCombatStats. DEAD/OFF players must remain visible but never sort as actionable READY.
15. Overload: enable/disable, unlock-and-move from a disabled state, dormant wake-up, reserve warning/cancel behavior and malformed migrated settings. Disabled, hidden, obscured, PvP-suppressed and dormant states must leave no health-sync update registered.

## Evidence and release boundaries

There is no unfiltered combat-log parser, per-frame sample archive or automatic equipment/potion activation. The user-configurable history has additional absolute metric/subject bounds. Combat collection can continue while the HUD is hidden; hidden settings do not require repeated full UI rebuilding.

Native Major/Minor buff classification and exact observed IDs improve recognition without fabricating an exhaustive ability catalog. Shipped set mappings and known skill/Class Mastery mappings use native IDs; localized runtime names and labelled English hints remain conservative fallbacks for identities the API does not expose reliably. Potion category classification is still a name-based hint when no stronger native fact is available. Observed effects do not identify an unreported caster. A potion-category event proves its category, not the exact item; potion-related buffs can have other sources. Shared facts and sample timings require real-client validation.

Experimental protocols 507–510 are unreserved. Public release requires reservation and coexistence validation. The live semantic catalog is bounded; raw local collection is not equivalent to sharing every possible effect. Unknown HM state, absent curated HM presets and incomplete per-player final-cap optimization are not presented as verified results.

## Primary API references

- ESO skill/mastery data: https://github.com/esoui/esoui/blob/live/esoui/ingame/skills/playerskillsdata.lua
- ESO Champion data: https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championdatamanager.lua
- Native Mundus UI: https://github.com/esoui/esoui/blob/live/esoui/ingame/stats/keyboard/zo_statentry_keyboard.lua
- Native potion category event: https://github.com/esoui/esoui/blob/live/esoui/ingame/inventory/sharedinventory.lua
- Native buff-type usage and API notes: https://github.com/DakJaniels/LuiExtended/blob/master/LuiExtended/modules/SpellCastBuffs/_EffectDebugMeta.lua
- LibGroupBroadcast: https://github.com/sirinsidiator/ESO-LibGroupBroadcast

These references document API shapes, not the outcome of testing this addon in ESO.
