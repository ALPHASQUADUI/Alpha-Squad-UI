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

Primary active branch: **`support-coverage`**.

Version on this branch:
- `2.7.0`
- `AddOnVersion 20710`

Support Coverage is a **precombat group capability and readiness module**. The current user-approved scope focuses on precombat readiness and visual build inspection.

Namespace: `AlphaSquadUI.Modules.SupportCoverage`.
SavedVariables: `AlphaSquadSupportCoverageSavedVariables`.

### Current goals and UI

- One **Trial** list and one **Dungeon** list of important group support effects/sources.
- Per-effect ON/OFF tracking with persistent preferences.
- Information tooltips describing effects, sources, proc conditions and recipient limits.
- Known providers and duplicates by `@UserID`, with source details on hover.
- **Builds** opens the roster and a compact character-style view: body-positioned equipment, per-bar set summaries, front/back skill and Ultimate icons, Champion icons, committed Class Masteries and consumables. Exact item-link traits/enchantments and ability identities drive tooltips.
- **Food** checks known group food/drink status without converting missing data into a pass.
- Foreground tooltips, responsive compact builds, scrolling coverage/roster lists and library/setup guidance.
- Product branding **Ąlpha Şquad UI**, preserving the accented A/S and ESO's standard UI font.

There is no active pull history, combat uptime, report or recorded-loadout planner workflow. Role labels provide group context; mandatory MT/OT/healer assignments and role-build templates are not the current interface.

### Runtime architecture

- `SupportCoverage.lua` — precombat lifecycle, SavedVariables, events and commands.
- `SupportCoverageCatalog.lua` / `SupportCoverageSources.lua` — catalog, source identities and build-source matching.
- `SupportCoverageScanner.lua` / `SupportCoverageBuild.lua` — local equipment, skills, CP, mastery and consumable evidence.
- `SupportCoverageAudit.lua` — bounded snapshot copy and readiness settings; no expected-template UI.
- `SupportCoverageShare.lua` / `SupportCoverageDetails.lua` / `SupportCoverageBuildCodec.lua` — bounded compatible build transport.
- `SupportCoverageEngine.lua` — cached roster, selected requirements, source coverage and duplicates.
- `SupportCoverageExternal.lua` — conservative adapters for supported third-party group data.
- `SupportCoverageUI.lua` / `SupportCoverageInspector.lua` / `SupportCoverageBuildView.lua` / `SupportCoverageSettings.lua` — coverage, visual Builds, Food and configuration.
- `Core/Tooltips.lua` — shared foreground tooltip routing for addon controls.

History, Tracking, Planner and LiveShare modules are retired. Keep patch data separated from evaluation logic so future ESO updates can be audited safely.

### Evidence and sources

The catalog covers important Major/Minor effects, group damage/penetration sources, group support sets, monster/mythic effects, class sources and optional sustain/defense effects. Source descriptions retain their activation and recipient limits.

`COVERED` means available build evidence establishes a source, not guaranteed active application. Separate weapon-bar set thresholds apply: a qualifying source on either bar can count, and two-handed weapons count as two set pieces. A one-piece splash does not establish a five-piece bonus.

Local scans include equipment/links, glyphs, slotted skills, Champion slottables, committed eligible Class Masteries, food, selected potion and supported readiness details. Class identity alone does not prove passive/mastery/skill selection. Prefer exact IDs/API data where reliable. Name matching is a fallback and should remain localization-aware.

Native ESO grouping does not expose arbitrary remote equipment, full skill bars, CP or mastery selections. Unsupported, incomplete and stale fields remain UNKNOWN. Never substitute an armor trait description for a jewelry/weapon trait or use an enchantment from a different item. Item links and exact ability IDs are the tooltip source of truth; remote stat-dependent skill values must not be represented as exact remote calculations.

### Sharing and dependencies

- `LibGroupBroadcast`: transport for compatible build sharing.
- `LibFoodDrinkBuff`: optional food/drink buff identification on supported player/group unit tags.
- `LibGroupCombatStats`: compatible Ultimate and supported active-line data, not full-build inspection or mastery/passive proof.
- `LibSetDetection` v5: optional recommended group set identities and per-bar activation, respecting selective sharing.
- `LibAddonMenu-2.0` (at least 38) and `LibDebugLogger`: required dependencies of LibGroupBroadcast.
- `AlphaSquadBuildShare`: optional sharing-only companion instead of the full UI suite.

A sender must install a compatible addon and explicitly enable sharing. A library alone does not publish another player's complete build. Full-suite and companion sending are alternatives on one client.

Active provisional protocols:
- build summary: **510**
- build details: **507**

Legacy plan/live protocols 509/508 are retired. **Do not publish a stable public release with active provisional IDs unless they have been formally reserved/verified against LibGroupBroadcast IDs.** Sharing defaults OFF and must fail gracefully when libraries are missing.

Never expose private or unnecessary data. Share only the bounded group build information required by the feature, after sender opt-in.

### Persistence and performance

Relevant enabled/visible/locked, geometry, context and effect preferences remain in the existing Support Coverage namespace. Remote build snapshots are transient group data. Migrations must preserve user settings wherever possible.

A five-second lightweight recovery refresh is limited to visible or grouped precombat use. Equipment/skill/CP changes invalidate cached evidence through coalesced events. Support scans and build sends pause during combat; deferred changes refresh after combat. There is no active combat sampler or report collector.

The module remains compact, movable, lockable, responsive and account/server persistent. Deep build inspection belongs in the dedicated view rather than enlarging the HUD into a spreadsheet.

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

The current authorization is to push validated changes to `support-coverage` only. Do not create a PR, merge, tag or public release before the maintainer has validated this version in ESO and explicitly asks for the next step.

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
