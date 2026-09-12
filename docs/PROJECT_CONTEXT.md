# Ąlpha Şquad UI — Project Context

Last updated: **2026-09-12**

This file stores project-relevant conversation context so work remains understandable across ChatGPT mobile/desktop sessions and coding agents.

## Repository

Canonical repository:
`ALPHASQUADUI/Alpha-Squad-UI`

Maintainer:
**SeRuM1**

Website:
https://alphasquadeso.com/

## Stable main

Stable `main` was finalized as **2.6.0** after the audit/release-cleanup work.

Stable feature set:
- Overload Tracker
- personal ULT Tracker
- Group ULT Tracker

The 2.6 cleanup:
- centralized more settings infrastructure in Core;
- optimized Group ULT updates;
- removed retired player FRONT/BACK group assignments;
- switched group ULT reads to `GetUnitULT()`;
- improved CI/version validation;
- aligned documentation and release metadata.

## Important conversation lesson

A later audit looked only at `main` and therefore did **not** include Support Coverage.

The user correctly pointed out that Support Coverage and additional instructions had been created from the PC session.

The missing context was not missing from GitHub: it existed on the feature branch:

`support-coverage`

Therefore future audits must inspect active feature branches, not only `main`.

## Support Coverage branch

At the time this context was written, `support-coverage` was ahead of `main` and contained the full development module.

Development version:
`2.7.0-support-coverage-test`

AddOnVersion:
`20700`

New SavedVariables:
`AlphaSquadSupportCoverageSavedVariables`

Manifest optional dependencies:
- LibGroupCombatStats
- LibGroupBroadcast
- LibFoodDrinkBuff

## Support Coverage intent

Support Coverage is not just another buff tracker.

It is intended as a **raidlead planning and readiness system** for endgame ESO trials.

Core responsibilities:
- scan player support capabilities;
- build a group capability roster;
- evaluate required buffs/debuffs/support sets;
- identify missing/duplicate coverage;
- auto-assign sensible owners when enabled;
- preserve manual raidlead overrides;
- provide profiles for different encounter goals;
- show a compact readiness HUD;
- provide a deeper coverage matrix for planning;
- share compact build/plan/live information when supported libraries are present.

## Current Support Coverage files

```text
AlphaSquadUI/Modules/SupportCoverage/
├── SupportCoverage.lua
├── SupportCoverageCatalog.lua
├── SupportCoverageScanner.lua
├── SupportCoverageShare.lua
├── SupportCoverageEngine.lua
├── SupportCoverageUI.lua
└── SupportCoverageSettings.lua
```

## Current profiles

- Full
- Progression
- Damage
- Trash
- Boss
- Custom

## Current roles

- MT
- OT
- H1
- H2
- DD PARSE
- DD SUPPORT
- UNKNOWN

## Current scanner scope

The scanner currently works with:
- equipment and sets;
- armor glyph/enchant classification;
- skills;
- food;
- potions;
- support capabilities;
- support score;
- role hints.

## Current UI philosophy

Combat HUD:
- compact;
- problems-first;
- readiness-focused;
- responsive;
- draggable/lockable;
- low visual noise.

Deep planning:
- coverage matrix/settings window;
- role/owner overrides;
- assignment locks;
- duplicate backups;
- custom requirements/catalog/profile overrides.

## Sharing caution

`SupportCoverageShare.lua` currently declares provisional LibGroupBroadcast protocol IDs:

- 510 — AlphaSquadSupportCoverage
- 509 — AlphaSquadSupportPlan
- 508 — AlphaSquadSupportLive

The source itself explicitly states that these must be formally reserved before public release.

This is a **release blocker** for stable public sharing unless verified/reserved.

## Branch / PR rule

The user requires:
- no direct development pushes to `main`;
- work on non-main branches;
- PR before merge;
- no automatic merge unless explicitly requested.

## User preference for project work

The user expects:
- direct execution rather than plan-only answers;
- finished GitHub changes;
- concise French communication;
- addon UI/code/docs in English;
- modern polished endgame UI;
- performance-focused implementation;
- actual validation and test ZIPs when relevant.

## Cross-device continuity

The user reported that PC instructions were not visible from the phone session.

To prevent future context loss:
- `AGENTS.md` is the canonical prompt/instruction file for coding agents;
- this file is the canonical project-conversation summary;
- feature branches must be inspected whenever the user references work done elsewhere.

Do not rely only on visible ChatGPT chat history to determine project state.
