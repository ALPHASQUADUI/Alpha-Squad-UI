# Ąlpha Şquad UI Architecture

## Goal

Build one lightweight ESO UI suite with a single **Ąlpha Şquad** settings entry and independent feature modules.

## Current state

The production Overload tracker is intentionally kept in its existing addon folder and SavedVariables namespace for compatibility.

```text
AlphaSquadOverloadTracker/
├── AlphaSquadOverloadTracker.txt
├── AlphaSquadOverloadTracker.lua
└── README.txt
```

## Target modular direction

As the suite grows, shared services should move into a small core layer while gameplay features remain isolated modules.

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
│   ├── RaidTools/
│   └── ...
└── Media/
```

Migration should happen incrementally so working releases and SavedVariables are not broken.

## Performance principles

### Event first
Use ESO events for state changes. Polling is a fallback, not the primary engine.

### Dormant modules
A module that has no relevant skill/context should perform no UI animations, sounds or rapid update callbacks.

### Conditional animations
Register fast update callbacks only while animation is visible. Unregister immediately afterward.

### No redundant UI writes
Do not repeatedly call `SetText`, color, texture, alpha or anchor setters when the value has not changed.

### Central settings suite
All future modules should register into the internal Ąlpha Şquad module navigation instead of creating separate ESO Settings entries.
