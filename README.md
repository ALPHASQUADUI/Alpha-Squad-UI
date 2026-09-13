# Ąlpha Şquad UI

A modular **The Elder Scrolls Online** addon by **SeRuM1**, built for endgame PvE groups. [Website](https://alphasquadeso.com/).

The `support-coverage` branch contains **2.7.0-support-coverage-test.5** (`20705`). This is an in-game test candidate; stable `main` remains separate. Do not treat automated validation as proof of ESO runtime behavior or measured frame time.

## Support Coverage: check the group before combat

Support Coverage checks which support sources the group has available before a trial or dungeon. Choose **Trial** or **Dungeon**, then turn individual effects **ON/OFF** for your group's needs. The catalog combines important buffs, debuffs, group sets, monster sets, mythics and class sources in one list per context.

- See missing coverage, known providers and duplicate providers by `@UserID`.
- Hover the information icon beside an effect to read what it does and which sources can cover it.
- Hover a provider to see the skill, set or mastery behind its contribution.
- Open **Builds**, select an account to request its snapshot, then inspect available equipment, front/back skills, Champion slottables, committed Class Masteries, food, potion and enchantment details. **REFRESH BUILD** requests current data.
- Open **Food** to check known food/drink state across the group. Missing data stays unknown.
- Filter Coverage by **ALL**, **MISSING** or **DUPLICATES**. Use scrolling lists, persistent position/size settings and the shared settings shell.

**COVERED means a compatible source was identified in the available build evidence.** It does not prove the effect is active, in range, applied to every group member or maintained in combat. Proc conditions, target limits, duration, stacking rules and bar requirements still matter. A duplicate is information for the raidlead; some effects deliberately need multiple providers or cover only part of a trial group.

Set counts are calculated independently for the two weapon bars. An eligible set on either bar can establish its source: a five-piece set does not need to be active on both bars. Two-handed weapons count as two set pieces. A one-piece splash does not establish a five-piece bonus. Bar-specific source presence does not promise the effect remains active after a bar swap.

This version focuses on preparation. Pull reports, combat uptime, history and loadout proposals are retired from the Support Coverage workflow. Roster role labels are context, not mandatory MT/OT/healer assignments.

## What can be known about another player?

ESO's native group APIs do **not** provide unrestricted inspection of another player's equipment, both full skill bars, Champion selections or Class Masteries. Being grouped alone is insufficient.

| Data source | Available information | Important limit |
| --- | --- | --- |
| Native ESO group APIs | Account/character identity, class, connectivity, selected group role and visible effects where exposed | An observed effect does not reveal a complete build or reliably identify its source; unobserved food is not proof of no food |
| This player's local scan | Equipment, both bars, slottables, committed masteries and consumables where APIs provide them | An unavailable API or incomplete scan remains `UNKNOWN` |
| LibSetDetection v5 | Reported set identities and activation on front/back bars | Last reported sets in the current observed session; hidden/missing data stays unknown. No item links, glyphs, CP or skill bars |
| Compatible Support Coverage sharing | The sender's supported build fields | Every sender must explicitly enable a compatible addon and the transport; stale/incomplete fields remain `UNKNOWN` |
| LibGroupCombatStats | Compatible Ultimate information and supported shared active class lines | It does not prove full equipment, skill bars, purchased passives, CP or mastery selections |

Compatible clients publish a compact capability summary. Detailed builds are requested on demand from the selected player and can take time to arrive over ESO's shared group channel. A completed detail snapshot is cached briefly (120 seconds), then requires fresh evidence; changing builds invalidates old details.

**LibSetDetection v5** is recommended for players who only want to share their sets. The receiver can read those reported set sources without Alpha Squad on that player. LibSetDetection reports changes rather than a heartbeat: the view labels the last report and its age, and does not claim a new verification on every refresh. Session/identity/disconnect changes invalidate inappropriate records. For full supported build details, group members can use the small **AlphaSquadBuildShare** companion instead of installing the full UI suite. It shares the supported build snapshot; it does not provide the tracking HUDs. Installing a transport library alone does not make an unrelated addon publish these build fields.

## Libraries and setup

Install libraries as separate addon folders and enable them in ESO's Add-Ons list. Use each library's current package/dependency list; do not manually edit library source or invent extra protocol settings.

| Package | Required for | Setup |
| --- | --- | --- |
| [**LibSetDetection v5**](https://www.esoui.com/downloads/info3338-LibSetDetection.html) | Recommended optional group set detection without Alpha Squad on the sender | Install on both ends with LibGroupBroadcast. Allow its set-sharing protocol in LGB. `/lsd incognito` explains selective sharing; hidden sets remain unknown. |
| [**LibGroupBroadcast**](https://www.esoui.com/downloads/info1337-LibGroupBroadcast.html) | Experimental Support Coverage build sharing and the companion | Install on senders and receiver with LibAddonMenu-2.0 (at least 38) and LibDebugLogger. In Support Coverage enable both **Share my build** and **Experimental sharing** for the controlled full-build test. The library is transport, not an inventory scanner. |
| [**LibAddonMenu-2.0**](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html) | Required dependency of LibGroupBroadcast | Install a current version (the inspected LGB manifest requires at least 38); no Alpha Squad specific configuration. |
| [**LibDebugLogger**](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) | Required dependency of LibGroupBroadcast | Install and enable. It does not require debug logging to be turned on for normal sharing. |
| [**LibFoodDrinkBuff**](https://www.esoui.com/downloads/info1902-LibFoodDrinkBuff.html) | Optional food/drink buff identification | Install and enable; no Alpha Squad specific configuration is needed. It can identify observable food buffs on supported unit tags, including group members. It does not expose an unavailable remote inventory; absent observations remain conservative. |
| [**LibGroupCombatStats**](https://www.esoui.com/downloads/info4024-LibGroupCombatStats.html) | Optional Group Ultimate Tracker | Install and enable with all dependencies declared by its current package, currently LibGroupBroadcast and LibCombat. Alpha Squad requests ULT data only; Support Coverage reuses that integration and reads already-shared active-line data when available. |
| [**LibCombat**](https://www.esoui.com/downloads/info2528-LibCombat.html) | Dependency of LibGroupCombatStats | Follow the installing package's dependency list. It is not needed for the personal trackers or local Support Coverage scan. |
| **AlphaSquadBuildShare** | A group member who wants to share builds without the full UI | Install the companion plus LibGroupBroadcast, then use `/asbuildshare on` for this controlled test. `/asbuildshare off` stops sharing; `/asbuildshare status` shows its state. The companion defaults OFF and yields to the full suite if both are installed. |

LibFoodDrinkBuff lists LibAsync, LibChatMessage and LibDebugLogger as optional; LibCombat also lists LibDebugLogger as optional. **LibGroupBroadcast itself requires LibAddonMenu-2.0 and LibDebugLogger**, so those are mandatory whenever LGB is installed. Follow the current package manifests if requirements change. LibSets is a separate database and is not needed for this integration.

The personal Overload and ULT trackers and local Support Coverage scan work without these optional libraries. Missing packages disable only the data paths that need them. Open the addon's **Libraries** settings page for installed/missing status and setup guidance.

Experimental build sharing is **OFF by default**. The branch uses provisional LibGroupBroadcast protocol IDs. Active IDs 507/510 are not claimed as registered; legacy plan/live IDs 509/508 are retired. A public build-sharing release requires formal reservation of the final active IDs and coexistence testing. This branch is for matching-version, controlled group tests.

## Existing trackers

**Overload Tracker** tracks Overload and its morphs on either bar, with an Ultimate counter, configurable reserve warnings, optional public `CancelBuff` cancellation when the effect is cancellable, a ready reminder and persistent movable HUD. Its recovery update stops while hidden or dormant.

**Personal ULT Tracker** reads the actual slotted Ultimate for MAIN, BACK or BOTH bars. It shows charge, readiness, active bar and optional sound/pulse. It supports morphs, guild/weapon Ultimates and subclassing through native slot data.

**Group Ultimate Tracker** lets the raidlead select Ultimate abilities. Compatible sharing players appear automatically with `@UserID`, icon and charge percentage. READY players sort first; dead/offline players are never actionable READY. It uses LibGroupCombatStats independently from Support Coverage build sharing.

## Installation and branch test download

1. Open [Support Coverage branch tests](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/actions/workflows/support-coverage.yml) and select the successful run for the intended `support-coverage` commit.
2. Download the `AlphaSquadUI-support-coverage-test` artifact while signed in to GitHub.
3. Close ESO. Back up the existing addon folders and SavedVariables before updating. Do not delete SavedVariables to upgrade.
4. Extract the artifact and its enclosed versioned ZIP. Copy `AlphaSquadUI` into `Documents/Elder Scrolls Online/live/AddOns/`.
5. For a sharing-only group member, download the separate **AlphaSquadBuildShare** artifact from the same run and install its enclosed companion ZIP plus required libraries instead of the full suite.
6. Restart ESO or run `/reloadui`. Enable the installed libraries and addons in the Add-Ons list.
7. Complete the [in-game checklist](docs/SUPPORT_COVERAGE_TESTING.md). Start with sharing OFF, then test with matching opt-in clients.

The full suite's final manifest path must be:

```text
Documents/Elder Scrolls Online/live/AddOns/AlphaSquadUI/AlphaSquadUI.txt
```

See [build download details](releases/README.md) for artifact distinctions. Do not install the source-review archive as an addon.

## Settings and commands

Open **ESC → Settings → Ąlpha Şquad UI**. The shared shell provides Overload, ULT Tracker, Support Coverage and library/setup information. It uses ESO's standard interface font.

- `/asoverload` — Overload settings.
- `/asult` — personal Ultimate settings; `/asult group` opens Group Ultimate configuration.
- `/assupport` — Support Coverage settings.
- `/assupport builds` and `/assupport food` — group build and food views.
- `/assupport trial` and `/assupport dungeon` — select the coverage context.
- `/assupport matrix` — effect list; use `/assupport scan` for a manual precombat refresh.

## Saved settings and compatibility

Existing account/server settings use these unchanged namespaces:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
AlphaSquadSupportCoverageSavedVariables
```

Group Ultimate preferences remain in the ULT Tracker namespace. Position, scale, visibility, locks and supported settings migrate without requiring a reset. Retired report/planner data is not part of the current user workflow. Remote build inspection uses temporary group data, not a persistent combat report archive. Support scans and build sends pause during combat and refresh deferred changes afterward.

## Development and validation

All development stays on `support-coverage`. Publishing this branch does not authorize a PR, merge, tag or stable release. The maintainer tests it in ESO before explicitly requesting any PR.

The workflows run deterministic module tests, Lua 5.1/5.4 syntax checks, manifest/version checks and ZIP validation. Actual ESO API behavior, window layout, sharing coexistence and performance with twelve players require in-game testing.

- [Trial/Dungeon catalog and sources](docs/SUPPORT_COVERAGE_CATALOG.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Performance](docs/PERFORMANCE.md)
- [Current decisions](docs/SUPPORT_COVERAGE_DECISIONS.md)
- [Test checklist](docs/SUPPORT_COVERAGE_TESTING.md)
- [Support Coverage module](AlphaSquadUI/Modules/SupportCoverage/README.md)

## Author

**SeRuM1** — **Ąlpha Şquad UI**. Developed with assistance from OpenAI ChatGPT under the author's direction.

Unofficial community addon; not affiliated with ZeniMax Online Studios or Bethesda Softworks.
