# Ąlpha Şquad UI — Architecture

## Installable addon

The repository contains one ESO addon suite under `AlphaSquadUI/`.

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

## Core responsibilities

### Core.lua
Owns suite identity, version, author, website and shared namespaces.

### Theme.lua
Owns shared Ąlpha Şquad color tokens. Modules may add module-specific visual tokens, but should reuse Core colors where practical.

### Utils.lua
Owns small reusable helpers such as numeric clamping and normalized paths.

### Events.lua
Owns common event namespace helpers. Gameplay event subscriptions remain inside each module.

### Settings.lua
Owns the settings page registry and the bridge to the shared settings shell.

Modules register page builders through:

```lua
AlphaSquadUI.Settings.RegisterPage(id, builder)
```

The visual shell is still created by the proven Overload implementation during this audit cycle. Modules no longer need to know that ownership detail; they interact through the Core settings bridge. Moving the visual shell itself out of Overload is a future isolated refactor, not part of runtime behavior changes.

## Module boundaries

### Overload
Owns Sorcerer Overload detection, reserve logic, alerts, HUD and existing settings shell implementation.

The file remains intentionally monolithic during the audit because splitting a proven 2,000+ line gameplay module purely for aesthetics would create unnecessary regression risk. A future split should preserve behavior and SavedVariables exactly.

### ULT Tracker
Owns the player's generic MAIN/BACK Ultimate tracking, HUD, events and integrated settings page.

The old standalone ULT settings implementation is retained only as a defensive fallback for unusual partial development installs. Normal runtime uses the shared Ąlpha Şquad settings shell.

### Group Ultimate Tracker
Lives under ULT Tracker and owns optional group Ultimate sharing, ability filters, raidlead HUD and group configuration.

The current workflow is **ability-driven**, not player-assignment driven. SavedVariables store tracked ability IDs, not persistent player assignments.

## SavedVariables

Existing namespaces are preserved:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
```

Group tracker preferences live inside the ULT Tracker SavedVariables.

## Group data flow

```text
LibGroupCombatStats ULT event
        ↓
update one cached roster entry
        ↓
recompute READY / percentage / ordering
        ↓
refresh compact raidlead HUD
```

A full roster rebuild is reserved for roster changes, initialization and the low-frequency safety sync.

## Design rules

1. One addon suite, independent gameplay modules.
2. Core owns shared infrastructure, not gameplay logic.
3. Prefer event-driven updates.
4. Fast updates exist only while an animation is visible.
5. Reuse UI controls.
6. Preserve SavedVariables compatibility.
7. Avoid hidden dependencies between modules.
8. New settings pages register through Core.
9. Public release changes must update documentation and changelog.
10. Development changes must go through a non-main branch and PR.
