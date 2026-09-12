# Support Coverage

**Support Coverage** is the Ąlpha Şquad UI raidlead planning, capability scanning and live coverage module.

Development branch: `support-coverage`

Current development version: `2.7.0-support-coverage-test`

## Purpose

Support Coverage helps a raidlead understand whether a 12-player trial group has the important offensive, defensive, sustain, penetration, critical-damage and unique support coverage required by the selected profile.

The module is designed to answer:

- What is covered?
- What is missing?
- Who can provide it?
- Who is assigned to provide it?
- Is there unnecessary duplication?
- Is the group ready for the pull?

## Components

- `SupportCoverage.lua` — lifecycle, events, SavedVariables and slash commands
- `SupportCoverageCatalog.lua` — U50 support catalog and profiles
- `SupportCoverageScanner.lua` — local build/capability scanner
- `SupportCoverageShare.lua` — group capability/plan/live sharing
- `SupportCoverageEngine.lua` — roster, evaluation and assignment engine
- `SupportCoverageUI.lua` — compact raidlead HUD
- `SupportCoverageSettings.lua` — settings page and detailed coverage matrix

## Profiles

- Full
- Progression
- Damage
- Trash
- Boss
- Custom

## Roles

- MT
- OT
- H1
- H2
- DD PARSE
- DD SUPPORT
- UNKNOWN

## Scanning

The local scanner can inspect:

- worn sets
- item/set data
- armor enchants/glyphs
- slotted skills
- food
- potion
- inferred support capabilities
- support score / role hint

## Persistent settings

Support Coverage uses:

`AlphaSquadSupportCoverageSavedVariables`

Settings include visibility, locking, geometry, problems-only mode, auto assignment, sharing, active profile, role overrides, assignment locks, backups, manual capabilities, custom requirements/catalog and context profiles.

## Optional libraries

- LibGroupCombatStats
- LibGroupBroadcast
- LibFoodDrinkBuff

The module must fail gracefully when optional libraries are unavailable.

## Important sharing warning

The current development sharing implementation uses provisional LibGroupBroadcast protocol IDs:

- 510 — build/capability sharing
- 509 — plan sharing
- 508 — live coverage sharing

These IDs must be formally reserved/verified before a stable public release.

## Performance

Support Coverage should remain raid-safe:

- event-driven updates where possible;
- coalesced refreshes;
- slow safety checks only;
- compact payloads;
- reusable controls;
- no unnecessary combat-log parsing;
- no fast hidden loops.

## Release status

This module is active feature work and must not be described as released on `main` until its PR has been tested and merged.
