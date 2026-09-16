# Contributing

Ąlpha Şquad UI is maintained by **@SeRuM1**. Contributions should make the addon clearer, more reliable and cheaper to run.

## Changes and review

Keep each change focused, explain the user problem and document the resulting behavior. Preserve existing gameplay features and SavedVariables. Follow the maintainer's requested Git scope, use reviewable commits and never merge or publish a release without approval. Interface and gameplay changes require a real ESO check before release; automated checks alone cannot establish rendering, FPS or network coexistence.

Update the README, module documentation and changelog when behavior changes. Use English in the addon and public documentation. Keep personal identities, private conversations, credentials and player snapshots out of commits and screenshots.

Use an approved public identity for both author and committer metadata. Maintainer commits prefer the public project address `info@alphasquadeso.com` with the approved aliases `SeRuM1` or `adi684`; the matching GitHub-provided `noreply` identity is also authorized, including when selected automatically by a connector. A `noreply` address is not mandatory. The project-mailbox approval covers only that exact address, not other addresses on the same domain or private identities. Report historical exposures privately using [SECURITY.md](SECURITY.md); do not repeat sensitive values in a public issue or rewrite history as part of an unrelated change. Contributions to the addon are under its [MIT license](LICENSE); native game resources and external libraries retain their respective licenses.

## Engineering rules

- Prefer filtered events, coalesced work and bounded caches to frequent polling.
- Keep fresh-install sharing OFF until an explicit choice, preserve saved choices and native OFF, and display the actual native setting. Switches must not open another addon page.
- Keep module tracking independent of library sharing. Disabled modules must release their subscriptions and timers; shared library events belong to their library.
- Keep Cross-sync account and character settings separate, preserve existing namespaces and use deep copies for nested settings.
- Use real ESO item links, skill/morph IDs, Champion allocation and native visual resources. Do not invent missing remote data or substitute the viewer's equipment for a sender's.
- Validate incoming sizes, identities, versions, ranges and freshness before mutation. Keep network payloads and retry state bounded.
- Keep native tooltips and link-confirmation dialogs above addon windows and restore their state when closed.
- Keep HUD placement centralized: preserve disabled modules and normal visibility, save on completion, and stop placement at combat/loading/menu boundaries.
- Count set pieces per weapon bar, using two-handed weights and native bonus thresholds. Unknown data must not create an excess warning.
- Register pages through Core and reuse controls. `Core/Shell.lua` owns the shell independently of tracking modules. Put module switches in Dashboard and sharing switches in Libraries.
- Keep Overload inside the shared personal ULT lifecycle and HUD. Preserve existing FRONT/BACK/BOTH modes; fresh installations use AUTO.
- Resize through Core Layout: corners preserve proportions, edges reflow contents, and opacity affects background surfaces only. Stop the temporary resize callback on every completion or cancellation path.
- Native `GetWidth`/`GetHeight` return dimensions with inherited scale. Convert once to logical layout units; never write a rendered dimension back as an unscaled SavedVariables size. Orientation is an explicit saved choice. Automatic viewport fitting must not overwrite requested geometry.
- Editor examples are presentation-only. Never put fictional accounts, effects or skills into the live roster, coverage engine, network payloads or saved build data.
- Register interactive controls with Core Input. Scope navigation to visible addon windows, release input before native dialogs/combat/loading, and leave gameplay bindings unchanged. Use native gamepad settings/action APIs and platform-appropriate hints.
- Repaint themes only on selection/profile changes; preserve semantic status, quality and discipline colors. Community links use native URL confirmation; no embedded HTML or invented Discord data.
- Use only the targeted native library protocol settings after verifying their option section and identity; reject ambiguous duplicate controls. An unsupported integration must degrade safely.

## Local validation

From the repository root:

```sh
python3 tooling/validate.py
```

The validator builds both archives once, extracts them, then runs every regression suite with Lua 5.1 and 5.4 against the shipped runtime files. It checks Lua/XML syntax, manifest inventory, numeric/string version correspondence, incoming whitespace and redacted security/privacy patterns. Use `LUA51` and `LUA54` when runtimes have different executable names, and `--output-dir` to select the artifact directory. Use `--base` and `--head` to check an explicit change range; CI derives the range from its event. Exact ZIPs, checksums, release notes and source provenance are retained in `dist/`, which is not committed.

Meaningful regressions should cover the affected boundary: exact item traits/enchantments, CP allocation, profile isolation, module lifecycle, tooltip ownership or malformed/stale packets. Avoid tests that only duplicate implementation details.

For client validation, record results in the [acceptance matrix](docs/CLIENT_ACCEPTANCE.md) and use the detailed [ESO checklist](docs/SUPPORT_COVERAGE_TESTING.md). Include enabled/disabled states, initial sharing setup, later OFF choices, global placement/resizing, all three themes, unified Ultimate/Overload migration, both weapon bars, character changes, `/reloadui`, travel and instance transitions. Reproduce a defect with the smallest relevant addon/library combination and attach the exact error and steps. Leave unperformed native checks explicitly unrecorded.

## Release preparation

Keep manifest/Core versions aligned and increment the numeric AddOnVersion. Build installable full-suite and companion archives, inspect the CI result and publish concise notes describing the user-visible changes. Reserve the active LibGroupBroadcast protocol identifiers before a public full-build-sharing release. Preserve the maintainer's final approval step.

Publication requires a separate manual operation from reviewed main, an explicit version policy, recorded native acceptance and reserved transport identifiers. It uses the exact artifacts from the successful validation job; an ordinary development push never authorizes publication. The publish job alone receives repository-content write permission; pull-request validation does not. Existing releases and tags are never overwritten. An interrupted unpublished draft may resume only with matching source and asset digests. A correction after publication receives a new version.

See [repository operations](docs/REPOSITORY_OPERATIONS.md) for required-check configuration, About metadata, private reporting and historical privacy. Committed configuration is not proof that administrator-only settings have been enabled.
