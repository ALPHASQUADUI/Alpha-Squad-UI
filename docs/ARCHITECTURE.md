# Ąlpha Şquad UI — Repository Architecture

The repository contains one installable ESO addon suite under `AlphaSquadUI/`.

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
│   └── Overload/
│       ├── Overload.lua
│       └── README.md
└── Media/
    └── .gitkeep
```

## Design principles

- **One addon suite, many modules.**
- **Main manifest stays small and explicit.**
- **Core is shared infrastructure only.**
- **Gameplay logic stays inside its module.**
- **Modules should sleep when irrelevant to minimize CPU usage.**
- **No future module should require another module unless explicitly documented.**
- **SavedVariables remain backward compatible whenever possible.**

## Current module: Overload

The existing v2.5.0 implementation is intentionally kept together in
`Modules/Overload/Overload.lua` for this migration.

This avoids changing thousands of lines at the same time as the filesystem
reorganization. After in-game validation, the Overload module can be split
safely into smaller files such as:

```text
Modules/Overload/
├── Overload.lua
├── Detection.lua
├── Alerts.lua
├── HUD.lua
└── Settings.lua
```

That second-stage refactor should happen only after this directory migration
has been tested successfully in ESO.

## Backward compatibility

The addon folder/manifest identity becomes `AlphaSquadUI`, but the existing
SavedVariables table remains:

`AlphaSquadOverloadTrackerSavedVariables`

This preserves existing Overload settings, position, thresholds and user
preferences.
