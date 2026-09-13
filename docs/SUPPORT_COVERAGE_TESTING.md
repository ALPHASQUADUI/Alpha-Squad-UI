# Support Coverage test checklist

Version: **2.7.0** / **20710** on **support-coverage**. This checklist is not a record of completed ESO tests.

## Local and CI checks

From the repository root, run the deterministic suites with both supported validation interpreters:

```sh
for test in tests/*.lua; do
    lua5.1 "$test"
    lua5.4 "$test"
done
python3 tooling/build_companion.py AlphaSquadBuildShare.zip
mkdir -p build/companion
unzip -oq AlphaSquadBuildShare.zip -d build/companion
lua5.1 tests/companion_package.lua build/companion/AlphaSquadBuildShare
lua5.4 tests/companion_package.lua build/companion/AlphaSquadBuildShare
```

Also validate every packaged Lua file, manifest paths/order/metadata, Core/manifest version consistency and both full-suite/companion package contents. Use current test output for assertion counts; earlier revisions' counts are not acceptance results for this version.

## In-game acceptance

Download the addon from the [branch build instructions](../releases/README.md). Record the commit, ESO API version, addon/library versions and relevant screenshots with each finding. Close ESO and back up existing addon folders and SavedVariables before installation. Start with sharing OFF.

| Check | Required outcome |
| --- | --- |
| Fresh and migrated settings | Clean load, preserved existing tracker preferences, no chat spam or Lua errors |
| Trial/Dungeon lists | Correct context list; ON/OFF settings persist independently; disabled effects stop contributing to that checklist |
| Information/provider hovers | Readable effect/source names, conditions and duplicate providers; tooltips appear above every addon window without raw-ID clutter |
| One-bar set coverage | Main-only and back-only threshold qualify; one/four pieces do not falsely become a five-piece source; two-handed weapons and normal/Perfected families count correctly |
| Skill bars | Front/back skills and Ultimates match native tooltips; subclassed skills work without guessing from class |
| Champion and masteries | Only committed supported selections are shown; missing APIs, absent fields and uncommitted respec choices remain appropriately unknown |
| Build inspector | Every selected account shows its own supported snapshot in a compact character view; body-positioned armor, jewelry, both weapon bars, set summaries and missing slots are clear |
| Item accuracy | Compare every item tooltip with the native inventory tooltip for the same link: quality, item name, armor/weapon/jewelry trait, enchantment and missing enchantment; repeat after changing trait/enchantment and after switching inspected players |
| Set summaries | Front/back counts match the inspected player's actual equipped slots; native item tooltips clearly identify their viewer-based counters; a two-handed arena weapon counts as two bonus pieces while occupying one item slot; no combined total falsely enables a bonus |
| Champion icons | Every star icon and tooltip matches its slotted Champion identity; unallocated, empty and unavailable data remain distinguishable |
| Transformations | Werewolf transformation preserves separate normal bars; transformed bar and Vampire/Werewolf indicators show only supported current evidence; morph icons match the actual ability |
| Food and potion | Known present/expired/absent food is distinguished from unknown; selected non-potion and empty quickslots are not invented potions; selection is not reported as proof of use |
| Native-only peer | Identity/class/role are usable; unsupported gear/CP/mastery/food remain unknown, not empty/pass |
| Full-suite sharing | Matching clients, installed LibGroupBroadcast and explicit sharing opt-in populate details before combat |
| LibSetDetection peer | A player with LSD v5/LGB but no Alpha Squad contributes reported qualifying sets; front/back thresholds, incognito-hidden sets, report age and disconnect/rejoin remain correct. Old library cache from before the observed group session is not new evidence; idle change-only reports do not expire on an invented heartbeat |
| LibGroupCombatStats peer | Fresh known Ultimate identities can contribute positive source hints; active class lines never imply purchased passives/masteries; old/missing records remain limited |
| Companion sharing | Sharing-only peer populates the receiver without the full UI; disabling sharing removes actionable stale data after expiry |
| Missing libraries / sharing OFF | Personal modules continue; remote unsupported fields stay unknown; setup guidance names the missing package |
| Stale/partial data | A build change, delayed fragment, disconnect or old sender cannot mix old items into a new complete build |
| Group lifecycle | Late join, leave/rejoin, disband, reconnect and character change invalidate inappropriate cached data |
| Combat boundary | No Support scans, report/history collection or build sends during combat; pending precombat state refreshes after combat ends |
| Layout | At 720p, 1080p and ultrawide with UI scaling, the selected build remains compact and readable; roster/coverage lists scroll; item, skill, Champion and information tooltips stay in the foreground and on screen |
| Settings branding | **Ąlpha Şquad UI** appears in the intended settings location with ESO's standard font; Libraries is accessible |
| Personal ULT | MAIN/BACK/BOTH, swap, spend, readiness sound/pulse, hide/disable and saved geometry behave correctly |
| Group ULT | Selected abilities, dead/offline members, rejoin, missing LibGroupCombatStats and charge sorting remain correct |
| Overload | All morphs, dormant wake-up, reserve behavior, PvP suppression and unlock/move from disabled state still work |
| Performance/coexistence | Measure frame time/memory and broadcast behavior with four and twelve players plus the group's existing addons |

## Release gate

Source availability is not live application or guaranteed recipient coverage. No measured combat uptime is claimed. Automated tests do not prove runtime behavior, protected API permissions or visual correctness.

The active build protocols **507/510** remain provisional; legacy **508/509** are retired. Public build sharing requires formal ID reservation and coexistence validation. No PR, merge, tag or stable release is authorized by completing this checklist alone; wait for the maintainer's explicit request.

## API and transport references

- [ESO native UI source](https://github.com/esoui/esoui)
- [ESO skill/mastery data](https://github.com/esoui/esoui/blob/live/esoui/ingame/skills/playerskillsdata.lua)
- [ESO Champion data](https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championdatamanager.lua)
- [LibSetDetection author source](https://github.com/exoy94/LibSetDetection)
- [LibGroupCombatStats author source](https://github.com/m00nyONE/LibGroupCombatStats)
- [LibGroupBroadcast source and protocol documentation](https://github.com/sirinsidiator/ESO-LibGroupBroadcast)

These describe API/transport behavior; they are not results from running this addon in ESO.
