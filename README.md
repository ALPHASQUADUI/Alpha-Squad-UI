# Ąlpha Şquad UI

A modular **The Elder Scrolls Online** UI suite by **SeRuM1**, focused on endgame PvE, raidlead visibility and low-overhead combat information.

Website: https://alphasquadeso.com/

## Current modules

### Overload Tracker

Tracks Overload, Energy Overload and Power Overload on either weapon bar, including subclassing use cases.

Key features:

- active/inactive Overload state
- current Ultimate counter
- configurable reserve warning
- optional public `CancelBuff` auto-stop when ESO exposes the effect as click-off cancellable
- Ready Reminder
- movable/lockable HUD
- scale and background opacity controls
- optional PvP suppression
- event-first tracking with a slow safety sync only while the HUD can be seen

### ULT Tracker

Generic personal Ultimate tracker for MAIN, BACK or BOTH bars.

It reads the actual slotted Ultimate from the ESO API, so it supports classes, morphs, guild Ultimates, weapon Ultimates and subclassing without a hard-coded ability list.

Key features:

- exact Ultimate icon/name/cost
- READY / CHARGING / USED / ACTIVE states
- active-bar indicator
- optional READY sound
- subtle READY pulse
- movable/lockable responsive HUD
- persistent scale, opacity and position

### Group Ultimate Tracker

Optional raidlead tool inside ULT Tracker.

The raidlead selects the **Ultimate abilities** to monitor. Any group member sharing Ultimate data and currently slotting one of those abilities is added automatically.

The compact group HUD shows:

- `@UserID`
- tracked Ultimate icon
- charge percentage based on the real Ultimate cost
- READY players sorted to the top
- charging players sorted by percentage
- recently spent Ultimates strongly dimmed
- dead and disconnected players retained for context but never shown as actionable READY

HUD geometry is persistent and configurable:

- Overall Scale: 60–180%
- List Width: 240–520 px
- Row Height: 28–56 px
- Background Opacity: 30–100%
- position / lock state / visibility

### Support Coverage (development candidate)

The `support-coverage` branch adds a raidlead readiness and analysis module. Version `2.7.0-support-coverage-test.4` is intentionally not presented as a stable release until its UI, ESO API behavior, combat timing and group sharing have been tested in game.

It provides evidence-aware support coverage, optional expected-build checks, per-recipient and per-boss live observations, whole-loadout planning and bounded pull reports. Missing or stale information remains `UNKNOWN`; it is never converted into a successful check.

Saved encounter contexts restore only their active profile's expected templates. Loading one context therefore cannot overwrite templates captured later for other profiles.

Experimental LibGroupBroadcast sharing is off by default. Protocol IDs 507–510 are provisional and must be reserved and coexistence-tested before any public release with sharing enabled.

## Group tracking dependency

The personal Overload, ULT and local Support Coverage features work without external libraries.

Live group Ultimate sharing requires **LibGroupCombatStats**. That library in turn requires its own dependencies, including LibGroupBroadcast and the appropriate LibCombat package.

If LibGroupCombatStats is unavailable, Group Ultimate Tracker stays offline without breaking the personal modules.

Support Coverage optionally uses **LibFoodDrinkBuff** for verified food state and **LibGroupBroadcast** for controlled multi-client tests. Their absence leaves the relevant fields local or unknown without breaking the addon.

## Installation

Copy the folder:

```text
AlphaSquadUI
```

to:

```text
Documents/Elder Scrolls Online/live/AddOns/
```

The final path must be:

```text
Documents/Elder Scrolls Online/live/AddOns/AlphaSquadUI/AlphaSquadUI.txt
```

Then restart ESO or use `/reloadui`.

### Testing the `support-coverage` branch

The current test candidate is `2.7.0-support-coverage-test.4`; stable `main` remains `2.6.0`.

1. Open [Support Coverage branch tests](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/actions/workflows/support-coverage.yml) and select the successful run for the commit you want to test.
2. Download the `AlphaSquadUI-support-coverage-test` artifact. GitHub artifact downloads require a signed-in account.
3. Close ESO and back up your existing addon folder and the three SavedVariables files listed below before replacing addon files. Do not delete your SavedVariables to upgrade.
4. Extract the artifact, then extract the enclosed `AlphaSquadUI-2.7.0-support-coverage-test.4.zip`. Install only its `AlphaSquadUI` folder at the path above, not the repository or review-source archive.
5. Follow the [in-game acceptance checklist](docs/SUPPORT_COVERAGE_TESTING.md), including personal ULT, Group ULT and Overload regressions.

Keep experimental sharing disabled for initial local tests. Enable it only for a controlled multi-client test with matching versions. Automated checks do not certify ESO behavior, and no PR or merge to `main` is planned before the maintainer's in-game validation.

## Settings

Open:

```text
ESC → Settings → Ąlpha Şquad
```

The shared settings shell contains:

```text
Ąlpha Şquad
├── Overload
├── ULT Tracker
│   └── Group Ultimate Config
├── Support Coverage
└── Website & About
```

`/asult` opens the shared ULT Tracker page.

`/asoverload` opens the shared settings shell for Overload.

`/assupport` opens Support Coverage; `/assupport matrix`, `/assupport history` and `/assupport report` open its focused views.

## SavedVariables

The suite preserves separate SavedVariables namespaces for compatibility:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
AlphaSquadSupportCoverageSavedVariables
```

ULT Group settings are stored inside the ULT Tracker SavedVariables and persist per account/server.

## Performance principles

- prefer ESO events to polling
- use slow safety syncs only as recovery paths
- do not keep fast animation callbacks alive when hidden
- reuse controls instead of rebuilding combat UI trees
- keep group updates incremental where possible
- request only ULT data from LibGroupCombatStats
- avoid automatic gameplay chat spam

See [Performance Guidelines](docs/PERFORMANCE.md).

## Repository layout

```text
AlphaSquadUI/
├── AlphaSquadUI.txt
├── Core/
│   ├── Core.lua
│   ├── Events.lua
│   ├── Settings.lua
│   ├── Theme.lua
│   └── Utils.lua
├── Modules/
│   ├── Overload/
│   │   ├── Overload.lua
│   │   └── README.md
│   ├── ULTTracker/
│   │   ├── ULTTracker.lua
│   │   ├── ULTTrackerUI.lua
│   │   ├── ULTTrackerSettings.lua
│   │   ├── ULTGroup.lua
│   │   ├── ULTGroupUI.lua
│   │   ├── ULTGroupSettings.lua
│   │   └── README.md
│   └── SupportCoverage/
│       ├── SupportCoverage.lua
│       ├── SupportCoverageCatalog.lua
│       ├── SupportCoverageAudit.lua
│       ├── SupportCoverageScanner.lua
│       ├── SupportCoverageBuild.lua
│       ├── SupportCoverageHistory.lua
│       ├── SupportCoverageShare.lua
│       ├── SupportCoverageDetails.lua
│       ├── SupportCoverageLiveShare.lua
│       ├── SupportCoverageEngine.lua
│       ├── SupportCoverageTracking.lua
│       ├── SupportCoverageUI.lua
│       ├── SupportCoveragePlanner.lua
│       ├── SupportCoverageInspector.lua
│       ├── SupportCoverageSettings.lua
│       ├── SupportCoverageSources.lua
│       ├── SupportCoverageIntegration.lua
│       └── README.md
└── Media/
```

See [Architecture](docs/ARCHITECTURE.md).

## Development / validation

Pushes to `support-coverage` run the branch validation workflow and generate a test ZIP without requiring a PR. Pull requests targeting `main` run the repository validation workflow.

It checks:

- Lua syntax
- manifest file paths
- required addon metadata
- deterministic Support Coverage, ULT Tracker and Overload lifecycle tests on Lua 5.1 and 5.4
- release ZIP packaging

Syntax validation does not replace in-game ESO testing.

See [test commands and acceptance criteria](docs/SUPPORT_COVERAGE_TESTING.md) and [build download details](releases/README.md).

## Author

**SeRuM1**

Project: **Ąlpha Şquad UI**

Parts of the implementation and documentation were developed with assistance from OpenAI ChatGPT under the direction of the project author.

## Disclaimer

Unofficial community addon for The Elder Scrolls Online. This project is not affiliated with or endorsed by ZeniMax Online Studios or Bethesda Softworks.
