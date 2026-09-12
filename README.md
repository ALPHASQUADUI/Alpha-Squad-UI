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
- event-first tracking with a slow safety sync

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

HUD geometry is persistent and configurable:

- Overall Scale: 60–180%
- List Width: 240–520 px
- Row Height: 28–56 px
- Background Opacity: 30–100%
- position / lock state / visibility

## Group tracking dependency

The personal Overload and ULT trackers work without external libraries.

Live group Ultimate sharing requires **LibGroupCombatStats**. That library in turn requires its own dependencies, including LibGroupBroadcast and the appropriate LibCombat package.

If LibGroupCombatStats is unavailable, Group Ultimate Tracker stays offline without breaking the personal modules.

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
└── Website & About
```

`/asult` opens the shared ULT Tracker page.

`/asoverload` opens the shared settings shell for Overload.

## SavedVariables

The suite preserves separate SavedVariables namespaces for compatibility:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
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
│   └── ULTTracker/
│       ├── ULTTracker.lua
│       ├── ULTTrackerUI.lua
│       ├── ULTTrackerSettings.lua
│       ├── ULTGroup.lua
│       ├── ULTGroupUI.lua
│       ├── ULTGroupSettings.lua
│       └── README.md
└── Media/
```

See [Architecture](docs/ARCHITECTURE.md).

## Development / validation

Pull requests targeting `main` run the repository validation workflow.

It checks:

- Lua syntax
- manifest file paths
- required addon metadata
- test ZIP packaging

Syntax validation does not replace in-game ESO testing.

## Release status

The `alpha-squad-ui-audit` branch is an integration/test branch for the 2.6.0 cleanup. `main` remains the stable branch until the audit build has been validated in game and merged by pull request.

## Author

**SeRuM1**

Project: **Ąlpha Şquad UI**

Parts of the implementation and documentation were developed with assistance from OpenAI ChatGPT under the direction of the project author.

## Disclaimer

Unofficial community addon for The Elder Scrolls Online. This project is not affiliated with or endorsed by ZeniMax Online Studios or Bethesda Softworks.
