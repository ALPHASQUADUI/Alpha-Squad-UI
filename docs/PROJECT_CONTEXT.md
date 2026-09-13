# Ąlpha Şquad UI — Project Context

Last updated: **2026-09-13**

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
`2.7.0-support-coverage-test.4`

AddOnVersion:
`20704`

New SavedVariables:
`AlphaSquadSupportCoverageSavedVariables`

Manifest optional dependencies:
- LibGroupCombatStats
- LibGroupBroadcast
- LibFoodDrinkBuff

## Current test-candidate handoff

The `test.4` audit includes Support Coverage scanner/sharing/planner/history fixes, defensive SavedVariables handling and hidden/dormant lifecycle fixes for personal ULT, Group ULT and Overload. Detailed changes are in `CHANGELOG.md`.

The deterministic suites contain 226 Support Coverage assertions, 38 ULT Tracker assertions and 9 Overload assertions: 273 per Lua runtime. Run all three suites on both Lua 5.1 and 5.4; syntax and packaging checks remain separate. No in-game ESO acceptance has been completed in this environment.

The maintainer explicitly authorized publishing these code and documentation changes on `support-coverage`, but **no PR, merge, tag or public release**. In-game testing comes first. Branch GitHub Actions builds provide the installable test artifact; see `releases/README.md` for the download steps.

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
├── SupportCoverageAudit.lua
├── SupportCoverageScanner.lua
├── SupportCoverageBuild.lua
├── SupportCoverageHistory.lua
├── SupportCoverageShare.lua
├── SupportCoverageDetails.lua
├── SupportCoverageLiveShare.lua
├── SupportCoverageEngine.lua
├── SupportCoverageTracking.lua
├── SupportCoverageUI.lua
├── SupportCoveragePlanner.lua
├── SupportCoverageInspector.lua
├── SupportCoverageSettings.lua
├── SupportCoverageSources.lua
└── SupportCoverageIntegration.lua
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
- Champion slottables;
- committed Class Masteries and prerequisites;
- food;
- selected potion, stack and cooldown evidence;
- optional poisons and Mundus;
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
- 507 — AlphaSquadSupportDetailsTest

The source itself explicitly states that these must be formally reserved before public release.

This is a **release blocker** for stable public sharing unless verified/reserved.

## Branch / PR rule

The user requires:
- no direct development pushes to `main`;
- work on non-main branches;
- publish the current validated candidate on `support-coverage` without creating a PR;
- PR before merge;
- wait for the maintainer's ESO tests and explicit request before opening that PR;
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
