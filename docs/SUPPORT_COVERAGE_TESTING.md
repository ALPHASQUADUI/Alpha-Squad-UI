# Support Coverage test checklist

Version: 2.7.0-support-coverage-test.2. Existing SavedVariables namespace/version are retained. Overload and ULT Tracker gameplay files are unchanged from the original Support Coverage baseline.

## Automated checks

The deterministic suite is `tests/support_coverage.lua`. It exercises initialization without libraries, optional modes, native buff identities, Mundus, missing data, elapsed-time uptime and gaps, separate targets, Champion comparisons, stable wire masks, malformed/non-member messages, UI pagination/geometry, report reopen/reset behavior, active-bar set thresholds, two-handed weapons, mixed Perfected families, monster sets and encounter pull labels. Both Lua 5.1 and Lua 5.4 are used by the branch workflow. A successful test result is not an ESO-runtime certification.

## In-game acceptance

1. Fresh and migrated SavedVariables; no optional libraries; disable/re-enable; no unsolicited chat output.
2. One/four/five-piece sets, main-only/back-only, two-handed weapons, monster/mythic/arena sets, normal/Perfected/mixed families. Check against native tooltips.
3. Four expected Warfare stars; change ID, order and committed points; test Fitness/Craft/ALL and an uncommitted respec.
4. Purchased/unpurchased Class Masteries, prerequisites, subclassing and native-line eligibility. Confirm no fabricated selection when data is unavailable.
5. Correct/wrong/expired food; no food library; selected non-potion; potion stack/cooldown; potion-category evidence; pre-pots, death, empty stack, poisons disabled and Mundus.
6. Matching ASUI clients, old ASUI, no ASUI, late join, reconnect, character changes, stale details and experimental sharing OFF. Unknown must never become a false PASS.
7. Multiple bosses with different debuffs and stack counts, untargetable phases, recipient limits and partial group observations. Check current target labels and gaps.
8. Wipe, local death while group continues fighting, transient combat exit, late combat entry, clock skew and late packets from the previous pull.
9. Close/reopen reports, automatic close, new combat, maximum history, manual reset, disband, leave/rejoin and reload with the same/different group. Verify encounter names and numbering.
10. HUD movement/scale/row height at 720p, 1080p and ultrawide. Matrix and inspector pagination must retain all requirements and settings.
11. Recorded-loadout proposals must choose one complete build per player, preserve manual choices and never equip anything. Recalculate after build changes.
12. Measure actual frame time, memory and group-broadcast queue behavior with twelve players and existing raid addons.

## Evidence and release boundaries

There is no unfiltered combat-log parser, per-frame sample archive or automatic equipment/potion activation. The user-configurable history has additional absolute metric/subject bounds. Combat collection can continue while the HUD is hidden; hidden settings do not require repeated full UI rebuilding.

Native Major/Minor buff classification and exact observed IDs improve recognition without fabricating an exhaustive ability catalog. Some skill/set/mastery capability mappings remain name-based or conditional. Observed effects do not identify an unreported caster. A potion-category event proves its category, not the exact item; potion-related buffs can have other sources. Shared facts and sample timings require real-client validation.

Experimental protocols 507–510 are unreserved. Public release requires reservation and coexistence validation. The live semantic catalog is bounded; raw local collection is not equivalent to sharing every possible effect. Unknown HM state, absent curated HM presets and incomplete per-player final-cap optimization are not presented as verified results.

## Primary API references

- ESO skill/mastery data: https://github.com/esoui/esoui/blob/live/esoui/ingame/skills/playerskillsdata.lua
- ESO Champion data: https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championdatamanager.lua
- Native Mundus UI: https://github.com/esoui/esoui/blob/live/esoui/ingame/stats/keyboard/zo_statentry_keyboard.lua
- Native potion category event: https://github.com/esoui/esoui/blob/live/esoui/ingame/inventory/sharedinventory.lua
- Native buff-type usage and API notes: https://github.com/DakJaniels/LuiExtended/blob/master/LuiExtended/modules/SpellCastBuffs/_EffectDebugMeta.lua
- LibGroupBroadcast: https://github.com/sirinsidiator/ESO-LibGroupBroadcast

These references document API shapes, not the outcome of testing this addon in ESO.
