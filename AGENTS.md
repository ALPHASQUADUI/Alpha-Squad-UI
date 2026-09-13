# Ąlpha Şquad UI — Agent Instructions

These instructions are the persistent operating context for ChatGPT, Codex and other coding agents working on this repository.

## Project identity

- Repository: `ALPHASQUADUI/Alpha-Squad-UI`
- Product: **Ąlpha Şquad UI**
- Author / maintainer: **SeRuM1**
- Website: https://alphasquadeso.com/
- Game: **The Elder Scrolls Online — PC EU**
- Primary use case: endgame PvE, raidlead tooling, HM / trifecta progression
- UI language / code / documentation: **English**
- User communication: **French**
- Design language: modern dark raid UI with Ąlpha Şquad orange/gold accents, compact and readable in combat
- Performance is a hard requirement: event-driven where possible, no unnecessary combat-log parsing, no permanent fast loops when hidden/dormant

## Mandatory Git workflow

`main` is stable/release.

**Never push development changes directly to `main`.**

Required workflow:
1. Read the current `main`.
2. Read the active feature branch.
3. Work only on a non-main branch.
4. Run validation.
5. Test in ESO when gameplay/UI behavior changes.
6. Open a PR to `main` only after validation/testing.
7. Never merge automatically unless the user explicitly asks.

The repository ruleset requires PRs for `main`, blocks deletion and non-fast-forward updates.

## Critical context rule

Before auditing or modifying the project, **do not assume that `main` contains all work**.

Always inspect relevant active branches named or implied by the user. A previous audit missed the Support Coverage module because it existed on `support-coverage` while `main` was still 2.6.0.

For feature questions:
- compare the feature branch against `main`;
- include unmerged feature work in the analysis;
- never describe an absent-on-main feature as missing if it already exists on an active branch.

## Stable baseline

Stable `main`: **2.6.0**.

Stable modules:
- Overload Tracker
- personal ULT Tracker
- Group ULT Tracker

Preserve existing SavedVariables:
- `AlphaSquadOverloadTrackerSavedVariables`
- `AlphaSquadULTTrackerSavedVariables`

Do not break existing settings, positions, filters or player preferences during migrations.

## Active development: Support Coverage

Primary active branch: **`support-coverage`**

Development version:
- `2.7.0-support-coverage-test.4`
- `AddOnVersion 20704`

Support Coverage is a **raidlead support-planning, capability-scanning and live-coverage module**.

Namespace:
`AlphaSquadUI.Modules.SupportCoverage`

SavedVariables:
`AlphaSquadSupportCoverageSavedVariables`

### Support Coverage goals

The module should help a raidlead answer:
- Which important buffs/debuffs/support sets are covered?
- Who is responsible for each effect?
- What is missing?
- What is duplicated?
- Which player/build is best suited to cover a missing requirement?
- Is the group ready before a pull?
- What changed after roster/build changes?

It must be useful for 12-player endgame trial groups without becoming a combat-overlay performance problem.

### Support Coverage architecture

Files:
- `SupportCoverage.lua` — lifecycle, SavedVariables, events, slash commands
- `SupportCoverageCatalog.lua` — patch-specific support catalog and profiles
- `SupportCoverageAudit.lua` — expected-build comparisons and evidence-aware readiness
- `SupportCoverageScanner.lua` — local equipment/skill/food/potion capability scanner
- `SupportCoverageBuild.lua` — Champion, mastery and build evidence helpers
- `SupportCoverageHistory.lua` — bounded pull history and report snapshots
- `SupportCoverageShare.lua` — compact group sharing and plan/live protocols
- `SupportCoverageDetails.lua` — build-bound signature/detail transport
- `SupportCoverageLiveShare.lua` — bounded observed-coverage transport
- `SupportCoverageEngine.lua` — roster building, coverage evaluation, assignment planning
- `SupportCoverageTracking.lua` — local live observations and pull timing
- `SupportCoverageUI.lua` — responsive raidlead HUD / readiness presentation
- `SupportCoveragePlanner.lua` — whole-loadout proposals with manual-choice preservation
- `SupportCoverageInspector.lua` — detailed build, readiness and history views
- `SupportCoverageSettings.lua` — integrated settings and coverage matrix
- `SupportCoverageSources.lua` — native set and skill identities with conservative fallbacks
- `SupportCoverageIntegration.lua` — group bonuses, saved contexts and bounded persistence

Keep patch data separated from evaluation logic so future ESO updates can be audited safely.

### U50 catalog

The current catalog is tagged **U50** and includes coverage concepts such as:
- Major / Minor Courage
- Major / Minor Slayer
- Major / Minor Force
- Major / Minor Berserk
- Major / Minor Vulnerability
- Major / Minor Brittle
- Elemental Catalyst
- Z'en's Redress
- Martial Knowledge
- Heat Shock (stable compatibility key: `stagger`)
- Major / Minor Breach
- Crusher
- Alkosh
- Crimson Oath
- Tremorscale
- Powerful Assault
- Pearlescent Ward
- Pillager's Profit
- Spaulder of Ruin
- Nazaray
- Symphony of Blades
- Yolnahkriin
- sustain / defense / status-effect coverage
- penetration and critical-damage budgets

Do not silently remove catalog coverage without a clear reason and changelog note.

### Planner profiles

Current profiles:
- `full`
- `progression`
- `damage`
- `trash`
- `boss`
- `custom`

Current support role vocabulary:
- `MT`
- `OT`
- `H1`
- `H2`
- `DD PARSE`
- `DD SUPPORT`
- `UNKNOWN`

The raidlead must be able to override roles/assignments and preserve those choices.

### Scanner behavior

Local player scanning currently covers:
- equipped sets
- item links / set information
- armor glyph/enchant classification
- slotted skills
- Champion slottables
- committed Class Masteries and prerequisites
- food
- selected potion, stack and cooldown evidence
- optional poisons and Mundus
- inferred support capabilities
- support score / role hint

Prefer exact IDs/API data where reliable. Name matching is a fallback and should remain localization-aware.

### Sharing

Optional dependencies used by Support Coverage:
- `LibGroupCombatStats`
- `LibGroupBroadcast`
- `LibFoodDrinkBuff`

The current Support Coverage sharing code uses **provisional development protocol IDs**:
- build protocol: 510
- plan protocol: 509
- live protocol: 508
- signature/detail protocol: 507

**Do not publish a stable public release with IDs 507–510 unless they have been formally reserved/verified against LibGroupBroadcast IDs.**

Sharing must fail gracefully when libraries are missing.

Never expose private or unnecessary data. Share only compact capability/plan/live information required by the feature.

### Support Coverage UX

The module should remain:
- raidlead-first;
- compact;
- responsive;
- movable and lockable;
- account/server persistent;
- readable at common ESO resolutions;
- usable with `problemsOnly` mode;
- able to show readiness/missing coverage clearly.

Current configurable geometry:
- scale: 60–180%
- opacity: 30–100%
- width: 300–680 px
- row height: 24–48 px

Do not turn the combat HUD into a giant spreadsheet. Deep configuration belongs in the coverage matrix/settings.

### Saved settings

Support Coverage currently persists:
- enabled / visible / locked
- hide in menus
- problems only
- auto assign
- sharing
- unknown visibility
- ready banner
- optional sounds
- scale / opacity / width / row height
- position
- active profile
- role overrides
- assignment locks
- duplicate backups
- manual capabilities
- custom requirements
- custom catalog
- profile overrides
- context profiles

Migrations must preserve user settings wherever possible.

## Existing module rules

### Overload Tracker
Preserve behavior unless explicitly requested. It is proven gameplay code and intentionally remains largely monolithic to reduce regression risk.

### Personal ULT Tracker
Generic MAIN/BACK/BOTH tracking. No hard-coded Ultimate catalog. Use actual slot/API data.

### Group ULT Tracker
Raidlead selects Ultimate abilities, not players or FRONT/BACK assignments.
Display:
- @UserID
- one large relevant Ultimate icon
- charge percentage
- READY players first
- recently spent rows dimmed

Group ULT sharing uses LibGroupCombatStats ULT data.

## Settings architecture

New module settings pages must register through:
`AlphaSquadUI.Settings.RegisterPage(id, builder)`

The visual settings shell is currently created by Overload, but other modules must interact through the Core bridge rather than directly depending on Overload internals.

## Performance rules

1. Prefer ESO events.
2. Coalesce bursty events.
3. Keep safety polling slow.
4. Do not keep fast animation callbacks active when hidden.
5. Reuse controls.
6. Avoid rebuilding full rosters on single-player data updates when incremental updates are possible.
7. Avoid unnecessary DPS/HPS/combat-log processing.
8. Keep sharing payloads compact.
9. Guard optional-library APIs.
10. Any new recurring update loop must be documented.

## Validation expectations

Before proposing a PR:
- validate every Lua file with `luac`;
- validate manifest file paths;
- validate manifest/Core version consistency;
- build an installable `AlphaSquadUI.zip`;
- inspect GitHub Actions result;
- test in ESO for runtime/API/UI changes.

Syntax success does **not** prove ESO runtime correctness.

The current authorization is to push validated changes to `support-coverage` only. Do not create a PR, merge, tag or public release before the maintainer has tested this candidate in ESO and explicitly asks for the next step.

## Documentation rules

For user-facing features, update:
- root README when the stable feature set changes;
- module README;
- `CHANGELOG.md`;
- architecture/performance docs when relevant.

Do not describe feature-branch work as already released on `main`.

## Conversation continuity

Project-relevant decisions from ChatGPT conversations are summarized in `docs/PROJECT_CONTEXT.md`.

When a user says “we already did this on PC” or references prior work not visible in the current chat:
1. inspect `docs/PROJECT_CONTEXT.md`;
2. inspect relevant GitHub branches;
3. recover prior project state before asking the user to repeat it.

This repository context is the source of truth for cross-device continuity.
