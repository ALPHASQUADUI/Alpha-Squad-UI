# Ąlpha Şquad UI — Project Context

Last updated: **2026-09-13**.

Repository: `ALPHASQUADUI/Alpha-Squad-UI`. Maintainer: **SeRuM1**. [Website](https://alphasquadeso.com/). Project language is English; communication with the maintainer is French.

## Branch state

Stable `main` remains the separate **2.6.0** baseline with Overload, personal ULT and Group Ultimate trackers. Support Coverage is feature-branch work; always inspect **support-coverage** when auditing it. An earlier audit missed the feature by inspecting only `main`.

The current development candidate is **2.7.0-support-coverage-test.5** / **20705**. The maintainer authorized necessary addon changes, documentation, audit and publication to **support-coverage**, with no PR, merge, tag or stable release. Actual ESO testing is still a separate handoff; do not infer in-game acceptance from local tests.

## Latest scope supersedes the previous report workflow

Support Coverage now focuses on preparation before combat:

- consolidated Trial and Dungeon effect lists with per-effect ON/OFF;
- buff/debuff/set/mastery source coverage, explicit conditions and duplicate providers;
- group **Builds** inspection by `@UserID` and a **Food** check;
- separate bar set counts, readable source names, glyphs, CP, skills and masteries where supported;
- responsive scrollable views and library/setup guidance;
- compatible build sharing from the full addon or a lightweight companion.

Pull reports, combat uptime, history and loadout-planner workflows belong to older candidates and are retired from the active interface. Role assignments are not a mandatory readiness workflow. Historical changelog entries remain historical evidence, not current feature claims.

## Technical limits

ESO grouping does not expose arbitrary remote equipment, both skill bars, CP or Class Mastery selections. Native class/identity/visible-effect data is partial. LibGroupCombatStats supplies compatible Ultimate/active-line data, without proving mastery/passive selections. LibSetDetection v5 can share set identities and per-bar activation without Alpha Squad, with selective-sharing limits. Detailed peer builds require an opted-in compatible sender and LibGroupBroadcast. **AlphaSquadBuildShare** avoids requiring the full UI suite; it does not avoid sender installation or consent.

Source coverage is availability, not observed application. One-bar set activation can qualify, but proc conditions and recipient caps still apply. Unknown or stale data must not turn into a successful check. Provisional protocol IDs block a normal public sharing release pending registration and coexistence validation.

## Persistence and performance

Preserve the established SavedVariables names:

- `AlphaSquadOverloadTrackerSavedVariables`
- `AlphaSquadULTTrackerSavedVariables`
- `AlphaSquadSupportCoverageSavedVariables`

Preserve relevant settings, filters and window geometry. Prefer events, bounded caches and coalesced refreshes; no unnecessary combat-log parsing or permanent fast loops while hidden/dormant.

## Handoff

The source of truth is the branch, its versioned files, current test outputs and [in-game checklist](SUPPORT_COVERAGE_TESTING.md). Do not repeat old assertion totals as current results. Branch Actions artifacts provide test packages; see [download instructions](../releases/README.md).

For cross-device continuity, read this file and `AGENTS.md`, inspect the actual branch and continue from the existing changes. Do not ask the maintainer to repeat already documented design decisions.
