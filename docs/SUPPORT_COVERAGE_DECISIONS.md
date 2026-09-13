# Support Coverage — current approved direction

The active branch is **support-coverage**. Version **2.7.0-support-coverage-test.5** (`20705`) replaces the previous candidate's report/planning workflow with precombat build and group support checks. The maintainer authorized implementation, visual/performance improvements, audit and publication to this branch. No PR, merge or changes to `main` are authorized.

## User-facing scope

- One consolidated **Trial** list and one **Dungeon** list of useful group support effects and sources.
- Individual ON/OFF tracking with persistent preferences.
- Clear effect explanations and known source/proc/recipient conditions in information tooltips.
- Multiple known providers listed by `@UserID`; hover for the specific skill, set or mastery producing the duplicate.
- A **Builds** button leading to the group roster, then each player's available equipment, skill bars, Champion slottables, masteries, food, potion and glyph details.
- A **Food** group check, distinguishing verified absence from unknown state.
- Scrolling lists and responsive, readable windows with persistent geometry.
- **Ąlpha Şquad UI** branding, preserving the accented letters and ESO's standard UI font.
- Visible library/setup guidance within the addon and repository.

Pull reports, history, uptime, expected-role loadout templates and whole-loadout proposals are retired from the active workflow. Existing settings namespaces and relevant preferences must survive the migration. There is no mandatory MT/OT/healer assignment workflow.

## Evidence rules

A source is counted only when the available evidence establishes the corresponding equipment/skill/mastery requirement. One-bar set activation is valid if the required pieces are active on that bar. Class identity alone does not establish skill, passive or mastery selection.

Source availability and live application are different facts. The UI must not promise twelve recipients for a six-player effect, proc activation, maintained duration or stacking merely because it identifies multiple providers.

Native group data is partial. Remote gear, full skill bars, CP and mastery inspection require a compatible sender. LibGroupCombatStats provides compatible Ultimate/active-line data, not a full remote build API or mastery/passive proof. LibSetDetection v5 adds reported set identities and per-bar activation without the full suite, while respecting hidden/partial data. A small **AlphaSquadBuildShare** companion offers an alternative to installing the full suite, but still requires explicit installation/opt-in and LibGroupBroadcast.

Unsupported, stale, malformed or incomplete data remains `UNKNOWN`. Missing observations are not automatically proof of missing food or missing equipment. No packet or manual claim should silently become stronger evidence than it provides.

## Performance and release boundaries

Use cached snapshots, coalesced build events and bounded sharing. Do not reintroduce a combat sampler or report history for these checks. Hidden views must not continually rebuild controls; disabled modules must stop unnecessary callbacks.

Experimental sharing defaults OFF and uses provisional protocol IDs. Formal reservation and coexistence tests are required before a public sharing release. Deterministic tests, syntax success and a clean audit do not establish in-game acceptance or authorize a PR.
