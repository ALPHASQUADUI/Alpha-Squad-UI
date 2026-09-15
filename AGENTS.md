# Engineering guidelines

## Project

**Ąlpha Şquad UI**, maintained by **@SeRuM1**, is a modular ESO addon. The package folder is `AlphaSquadUI/`. Runtime modules are ULT Tracker (personal/group, with optional Overload behavior) and Support Coverage. `companion/` contains the optional sharing-only sender.

Read the existing implementation and the maintainer's current request before editing. Work only within the explicitly authorized Git scope. Preserve unrelated changes. Do not create a pull request, merge, tag or public release until requested and the required client validation is complete. Do not update a protected release ref as part of development.

## Product and evidence

- Keep the interface and public documentation in English, concise and understandable.
- Module switches belong to Dashboard; sharing belongs to Libraries. Disabling tracking must not revoke sharing consent.
- Native group membership is not permission or an API for arbitrary remote inventory inspection. Missing or stale data remains Unknown.
- Item links and effective morph IDs are authoritative. Never substitute another item's trait/enchant or the viewer's build for a peer.
- Class identity alone does not prove learned passives, eligible masteries or slotted abilities.
- Count front/back set pieces separately. Two-handed weapons contribute two pieces but remain one physical item. Set headlines use the highest known bar count; only native bonus thresholds may produce an excess warning.
- Keep HUD placement centralized. Corners scale proportionally, edges reshape/reflow content, and the toolbar owns background opacity, scale, fit and reset. Preserve disabled modules and normal visibility choices; save/lock on completion and stop placement during combat/loading.
- Preserve existing Ultimate display choices, especially BOTH. AUTO is the fresh-install default. Overload uses the same personal HUD and an independent behavior toggle.
- Apply saved Ember Classic, Tactical Compact and Obsidian Studio themes across the suite; Obsidian is the default. Preserve semantic readiness, quality and Champion colors.
- The About page opens the verified Discord invitation through ESO's native URL confirmation. Do not embed HTML, use a widget as an invitation, fabricate live member counts or send build data through community links.
- Champion visuals use native discipline stars; descriptions use the inspected player's allocated points.
- Keep native tooltips in front of addon windows and restore their original draw state afterward.
- Group readiness is a precombat availability check. Do not reintroduce uptime, pull history or a combat-log sampler.

## Architecture and performance

Register settings pages through `AlphaSquadUI.Settings.RegisterPage(id, builder)`. `Core/Shell.lua` owns the settings shell independently of gameplay modules and remains accessible when all tracking is disabled. Do not restore a standalone Overload HUD, timer or bootstrap; `ULTOverload.lua` contributes optional behavior to the personal Ultimate tracker.

Use Core event scopes to suspend module subscriptions. Preserve activation events, filter high-volume events, coalesce invalidations, reuse controls and stop animation timers when hidden. A disabled Support module may retain the minimum grouped sender work required by explicit Libraries consent. Pause scans and detail traffic during loading and combat.

Preserve the existing SavedVariables namespaces. Cross-sync defaults to existing account/server settings. Character profiles must be deep copies, retain the current layout on a switch and keep Group ULT's settings reference current. Sharing preferences remain account-wide. Remote snapshots are transient, bounded data, never persistent history.

Use optional libraries defensively. Verify the native option section and protocol identity before changing matching library settings; reject ambiguous duplicate sections or controls. Never modify unrelated protocols, force-enable installed addon files or unregister another library's shared callbacks. A missing/incompatible library must degrade safely without a retry storm.

Active build transport IDs **507/510** are provisional. Initialize supported sharing ON once for a fresh installation; preserve existing OFF choices, show actual native library state and mark missing/incompatible controls unavailable. Do not publish stable public sharing with these IDs until formally reserved and coexistence-validated. Legacy **508/509** are retired.

## Validation and delivery

Run `python3 tooling/validate.py`, inspect the CI result and validate the two installable packages. Add meaningful regressions for changed data/lifecycle boundaries. Do not claim runtime rendering, zero FPS impact or zero disconnects from synthetic checks.

Follow the real-client checklist in `docs/SUPPORT_COVERAGE_TESTING.md`. Update README, module docs, CHANGELOG and architecture/performance notes for user-visible changes. Keep personal data, private conversations and credentials out of the repository and deliverables.
