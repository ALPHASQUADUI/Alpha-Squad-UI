# Engineering guidelines

## Project

**Ąlpha Şquad UI**, maintained by **@SeRuM1**, is a modular ESO addon. The package folder is `AlphaSquadUI/`. Runtime modules are ULT Tracker (personal/group, with optional Overload behavior) and Support Coverage. `companion/` contains the optional sharing-only sender.

Read the existing implementation and the maintainer's current request before editing. Work only within the explicitly authorized Git scope. Preserve unrelated changes. All development and documentation changes belong on dev. Create dev-to-main pull requests only after the maintainer has tested and explicitly approved that development cycle and requested the PR. Never approve or merge a PR, enable auto-merge, push directly to main, or move main to simulate a merge: approval and merging are exclusively human actions. Generic finalization or release requests do not override this rule. Tags and GitHub Releases require separate authorization after a verified human merge. ESOUI and website publication are separate scopes.

Use `SeRuM1 <info@alphasquadeso.com>` for new maintainer commits. This public project mailbox is explicitly authorized; noreply is not mandatory. Verify author and committer before publication and do not substitute a personal address.

## Product and evidence

- Keep code, identifiers, comments, commits and public documentation in English. The interface supports English and French through the localization layer; use the game language by default, with a persistent Dashboard override. Translate addon-owned presentation, never protocol keys, native item links or player names. Keep French and English layouts readable and bounded.
- Module switches belong to Dashboard; sharing belongs to Libraries. Disabling tracking must not revoke sharing consent.
- Native group membership is not permission or an API for arbitrary remote inventory inspection. Missing or stale data remains Unknown.
- Item links and effective morph IDs are authoritative. Never substitute another item's trait/enchant or the viewer's build for a peer.
- Class identity alone does not prove learned passives, eligible masteries or slotted abilities.
- Count front/back set pieces separately. Two-handed weapons contribute two pieces but remain one physical item. Set headlines use the highest known bar count; only native bonus thresholds may produce an excess warning.
- Keep HUD placement centralized. Corners scale proportionally, edges reshape/reflow content, and the toolbar owns background opacity, scale, fit and reset. Preserve disabled modules and normal visibility choices; save/lock on completion and stop placement during combat/loading.
- Personal Ultimate uses the selected transparent design 2: native icon, actual points/native cost, thin progress bar and concise localized state, with both normal weapon slots. Do not restore AUTO/FRONT/BACK/BOTH selectors. Show the green left-side marker only for the verified active bar, dim the inactive slot, and preserve unknown costs and special-bar uncertainty. Overload shares this HUD with actual remaining points and a reserve marker; its reminder threshold is not a cost. Use neutral inactive, gold active, green ready pulse and red stop pulse. Hide only the native Ultimate button presentation while the enabled personal replacement is visible; restore it when disabled, hidden, in menus/loading or in placement. Preserve casting, other action buttons, group tracking and sharing.
- Apply saved Ember Classic, Tactical Compact and Obsidian Studio themes to the settings shell; Obsidian is the default. Gameplay windows use quiet neutral surfaces, transparent Ultimate HUDs and no orange branding. Preserve semantic readiness, quality, class and Champion colors.
- The About page opens the verified Discord invitation through ESO's native URL confirmation. Do not embed HTML, use a widget as an invitation, fabricate live member counts or send build data through community links.
- Champion visuals use native discipline stars; descriptions use the inspected player's allocated points.
- Keep native tooltips in front of addon windows and restore their original draw state afterward.
- Group readiness is a precombat availability check. Do not reintroduce uptime, pull history or a combat-log sampler.

## Architecture and performance

Register settings pages through `AlphaSquadUI.Settings.RegisterPage(id, builder)`. `Core/Shell.lua` owns the settings shell independently of gameplay modules and remains accessible when all tracking is disabled. Do not restore a standalone Overload HUD, timer or bootstrap; `ULTOverload.lua` contributes optional behavior to the personal Ultimate tracker.

Use Core event scopes to suspend module subscriptions. Preserve activation events, filter high-volume events, coalesce invalidations, reuse controls and stop animation timers when hidden. A disabled Support module may retain the minimum grouped sender work required by explicit Libraries consent. Pause scans and detail traffic during loading and combat.

Preserve the existing SavedVariables namespaces. Cross-sync defaults to existing account/server settings. Character profiles must be deep copies, retain the current layout on a switch and keep Group ULT's settings reference current. Sharing preferences remain account-wide. Remote snapshots are transient, bounded data, never persistent history.

Use optional libraries defensively. Verify the native option section and protocol identity before changing matching library settings; reject ambiguous duplicate sections or controls. Never modify unrelated protocols, force-enable installed addon files or unregister another library's shared callbacks. A missing/incompatible library must degrade safely without a retry storm.

Active build transport IDs **507/510** are provisional. New installations require an explicit sharing choice and start OFF; preserve existing saved choices and native OFF states, show actual native library state and mark missing/incompatible controls unavailable. Do not publish stable public sharing with these IDs until formally reserved and coexistence-validated. Legacy **508/509** are retired.

Development uses `dev`; never infer release authorization from a development push. Public release requires a separately authorized manual operation from reviewed `main`, completed native acceptance and reserved/coexistence-validated transport IDs. Versioned policy files describe required administration work; they do not apply GitHub settings by themselves.

## Validation and delivery

Run `python3 tooling/validate.py`, inspect the CI result and validate the two installable packages. Add meaningful regressions for changed data/lifecycle boundaries. Do not claim runtime rendering, zero FPS impact or zero disconnects from synthetic checks.

Follow the real-client checklist in `docs/SUPPORT_COVERAGE_TESTING.md`. Update README, module docs, CHANGELOG and architecture/performance notes for user-visible changes. Keep personal data, private conversations and credentials out of the repository and deliverables.
