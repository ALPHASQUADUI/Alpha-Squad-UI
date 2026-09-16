# 3.3.1 remediation and acceptance

This maintenance candidate addresses the reviewed data, presentation and packaging boundaries. Development publication to `dev` is authorized. A merge, tag, public release, account-setting change or historical rewrite remains a separate operation. The development branch is `dev`; `main` remains the reviewed release base.

## Code changes

| Area | Intended behavior | Validation boundary |
| --- | --- | --- |
| Sharing consent | Fresh installations require an explicit ON; stored choices and native OFF are preserved | Fresh/migrated settings, missing libraries and later native changes |
| Build transport | Pause and revoke only owned pending frames; expire abandoned transfers without a visible inspector | Combat/loading/group transitions, queue failures and interrupted transfers |
| Skill evidence | Reject explicit native-definition contradictions; do not substitute the viewer's learned build | Known/missing native resolution, cross-class client acceptance |
| Settings input | Apply one opening policy; invalidate suspended input when another scene takes over | Slash/direct entry, combat, loading, native menus and dialogs |
| Build status | Preserve progress and failure feedback alongside partial equipment evidence | Existing set data with pending/failed detail requests |
| Readiness | Keep food, glyph and unknown-state issues visible independently of effect-source totals | All selected sources present with an incomplete preparation check |
| Recipient limits | Surface limited source reach without promising recipients or uptime | Dungeon/trial contexts and conditional source limits |
| Presentation work | Defer hidden HUD painting and refresh active settings pages | Cached updates while hidden, visibility restoration and editor previews |
| Readiness work | Avoid coverage reconstruction for unchanged readiness-only events | Effect bursts, expiring food, Mundus, quickslots and fresh peer evidence |
| Package inventory | Build only reviewed files and scan final package content | Ignored files, private-data paths, malformed archives and provenance |
| Publication | Require a separate manual operation and explicit release gates | Validation-only development pushes and publication rejection tests |

Full equipment/skill changes can affect native descriptions, passives and derived stats. Full build invalidation remains available for those changes; performance work must not cache stale native values. Lua tests establish these logical boundaries, not measured ESO frame time.

## Automated validation

Local validation on 2026-09-16 passed all 33 Lua suites under both Lua 5.1 and Lua 5.4: 2,888 assertions per runtime, 5,776 total. All 20 Python security/publication tests passed, including the narrowly scoped Dependabot sign-off and authorized public project mailbox policies. The validator tested the files extracted from both installable ZIPs, checked manifests and versions, and scanned the final payloads. An independent reload probe confirmed that failed queue recovery cannot silently restore a native OFF to ON.

Those initial results describe local development sources. Each published development commit must also pass its own GitHub CI run, and retained provenance records the exact source commit and clean/modified state. Native acceptance remains unrecorded. The public publisher rejects modified source bundles.

## External actions still required

1. Apply and re-read the reviewed branch rule so the exact GitHub Actions `validate-and-package` check is required. Resolve review conversations before merge. Configuration files alone have no effect on GitHub.
2. Apply appropriate version-tag protection and configure the release environment's required approval with the repository administrator connection. Do not weaken current protections or add an administrator credential to the addon or workflow.
3. Reserve protocol IDs through the library's official process and record coexistence results. IDs 507/510 remain unchanged and provisional. No automatic public publication is enabled by this candidate.
4. Record the exact ESO/API and library versions for the native acceptance scenarios, including mouse/controller, loading/combat, group churn and another class's skill definitions.
5. Measure frame-time distribution, memory and traffic in solo, four-player and twelve-player conditions. No synthetic check establishes a performance gain percentage.
6. Handle any historical metadata remediation as a separate reviewed operation with explicit authorization for affected refs. Never put sensitive historical values into reports, commits or test fixtures.

## Delivery and recovery

Validate both installable packages with `python3 tooling/validate.py`. The retained bundle records the source commit, whether local source changes exist, and archive hashes. A modified working-tree package is suitable for controlled acceptance testing, not for the public publisher's clean-source gate.

Retain the previous package and a private SavedVariables backup before client acceptance. Existing preference namespaces are preserved. Do not reset settings or overwrite a previously published release as a recovery shortcut. Fixes should remain separately reviewable from any future publication.
