# Ąlpha Şquad UI — Architecture

## Packages and Core

`AlphaSquadUI/` is the full ESO suite. The **AlphaSquadBuildShare** companion is a separate sharing-only installation for group members who do not want the UI suite; it uses the same compatible build format.

Core owns identity/version (`Core.lua`), live English/French presentation (`Localization.lua` and `Localization/fr.lua`), saved settings theme presets (`Theme.lua`), shared helpers (`Utils.lua`), module event scopes (`Events.lua`), account/character preferences (`Preferences.lua`), the settings-page bridge (`Settings.lua`), the standalone settings shell (`Shell.lua`), library preferences (`Sharing.lua`), global placement/resizing (`Layout.lua`), temporary presentation samples (`Preview.lua`), scoped keyboard/controller navigation (`Input.lua`) and foreground tooltip routing (`Tooltips.lua`). New pages register through:

```lua
AlphaSquadUI.Settings.RegisterPage(id, builder)
```

`Core/Shell.lua` creates and registers the settings shell independently of gameplay tracking. It remains accessible when ULT Tracker and Support Coverage are both disabled. The shared product label is **Ąlpha Şquad UI**, rendered with ESO's standard UI font.

The shell fits its actual dimensions to the viewport while retaining native text size. Pages register `ui.RegisterLayout(page, callback)` to reflow cards and controls using the available width and height. Narrow layouts replace the side navigation with a wrapped horizontal strip. Pages that cannot fit at a readable size use native scrolling rather than globally shrinking every label.

Theme and language selectors each own a private native dropdown, cached on the combo box. `Theme.dropdownSerial` supplies distinct `AlphaSquadPrivateDropdown{n}` roots: ESO derives its `BG`, `Scroll` and nested control names from that root. Anonymous roots collide in the global control registry. The opaque fill and scale adjustment remain instance-local; ESO's shared dropdown and other addons' controls are untouched.

`Core/AddOnMenu.lua` post-hooks the native Add-Ons manager's `BuildMasterList` once and augments only the suite's entry before native row sizing. Library availability uses the selected character's native addon records and dependency/version API, not Lua globals that remain loaded after a checkbox changes. Libraries remain optional at load time; missing group integrations do not disable local tracking. Compact Title/Author metadata stays within a 64-byte compatibility budget, including color codes. The static description is the fallback before the suite's Lua is loaded.

## Module boundaries

| Component | Responsibility |
| --- | --- |
| Personal ULT | Actual slot data, always-visible front/back slots, charge/readiness and the shared personal HUD |
| Integrated Overload | `ULTOverload.lua`: optional morph state, reserve warnings and ready reminder within the personal ULT lifecycle |
| Group ULT | LibGroupCombatStats ULT-only integration, teammate-only ability filters, cached player state and compact HUD |
| Support catalog/sources | Patch-specific effects, source identities, descriptions and build-source matching |
| Support scanner/build | Local equipment, separate skill bars, Champion/mastery and consumable evidence |
| Support engine/lifecycle | Cached roster, precombat capability evaluation, context toggles, duplicate providers and event invalidation |
| Support external adapters | Optional LibSetDetection group set facts and compatible LibGroupCombatStats information with explicit data limits |
| Support share/details/codec | Bounded compatible snapshot transport and validation |
| Support UI/settings/inspector | Categorized Coverage, build selection and integrated consumable readiness |
| Support BuildView | Compact equipment silhouette, set summaries, skill/Ultimate and Champion icons |
| Core Preview | Temporary sample states consumed only by participating Move HUD renderers |
| Core Input | Focus, activation, adjustments and placement input within registered suite windows |
| Core tooltip routing | Native item/ability details and readable custom descriptions above addon windows |

Some audit helpers remain for scanner/evidence compatibility. Their presence does not expose the old expected-build template workflow. Pull history, combat observation, live-report transport and recorded-build planner modules are retired from the runtime.

## Personal Ultimate presentation

The design 2 renderer presents current points/native cost for ordinary slots, with clamped progress and explicit unknown or empty states. Overload shares the same controls and lifecycle but presents remaining points and a reserve marker; its reminder threshold does not become a native ability cost. Resource changes update cached presentation without reanchoring unchanged geometry. Language changes refresh addon-owned state labels from existing data and preserve placement. Special native hotbars remain distinct from the normal front/back pair.

Native Ultimate-button replacement follows personal visibility rather than group tracking or library sharing. It suppresses only the button presentation while the enabled personal HUD is visible in gameplay and releases it on hide, disable, menus, loading or placement. Native slot data and casting remain owned by ESO. Unsupported native controls are left untouched. Saved presentation state is restored only while the replacement still owns it, preserving later external changes. Restoration and coexistence with other action-bar addons require native acceptance in both keyboard and gamepad modes.

## Support Coverage data flow

Equipment, skill, Champion and mastery changes invalidate the local snapshot. Coalesced scans refresh supported local evidence outside combat. Validated compatible peer snapshots populate a bounded transient group cache. The engine evaluates enabled Trial/Dungeon requirements against that evidence, and reused controls render coverage, providers and detailed builds.

A five-second lightweight recovery refresh is limited to a relevant visible or grouped precombat state. Quickslot/readiness changes do not require rescanning every unrelated equipment slot. Support Coverage does not scan or send build data during combat; pending state is refreshed when combat ends. There is no pull sampler, report archive or uptime computation in this workflow.

## Build presentation

`SupportCoverageBuildView.lua` renders the selected build as a compact character view. Equipment placement represents body slots, jewelry and each weapon bar. It is not a native remote-character inventory API or a 3D character renderer. Set-summary headlines use the highest known per-bar piece total, preserve separate FRONT/BACK values and apply two-handed weights. Physical item counts remain explanatory data instead of being summed across bars. Native set-bonus requirements determine excess warnings; a bounded positive cache avoids repeated requirement reads. Partial bar evidence produces a lower bound and never guesses the missing total. The normal weapon bars remain separate from a reported Werewolf bar. Twelve Champion positions, mastery icons and compact consumable/character cards complete the view.

`Core/Tooltips.lua` centralizes foreground layering and native/custom tooltip routing. Item details are tied to the actual item link; ability details are tied to the selected skill or morph. Native item-tooltip set counters still refer to the viewing player, so the tooltip directs the user to the inspected build's own per-bar summary. Native descriptions on a receiving client do not establish the remote player's stat-scaled combat values. Champion descriptions use the sender's verified allocated points; missing allocations are not substituted with the viewer's values. Missing snapshot fields remain unknown, including unsupported transformation details and Vampire stage.

The armor columns are mirrored around the native paper doll, which retains its original 64:256 proportions. BuildView retains its logical canvas height separately from rendered control dimensions. The inspector binds the complete sheet before fitting it once to the viewport, so repeated refreshes under a scaled parent cannot shrink the layout or clip its footer. Where exact effect or item artwork cannot be verified, the catalog supplies a native category symbol and the tooltip identifies that limitation; a named source icon is not presented as a unique picture of the effect itself.

## Evidence and transport boundaries

- Native ESO grouping supplies partial identity/class/visible-effect data, not arbitrary remote inventory or CP access.
- LibGroupCombatStats supplies compatible Ultimate/active-line facts; it is not the full-build transport and does not verify purchased passives or masteries.
- LibSetDetection v5 supplies reported sets and per-bar activation through its own registered transport. Hidden and unavailable sets are not proof of absence. Its public API has no timestamp: the adapter accepts update events received in the currently observed group session and records their local receipt time. It labels the data as last reported, without a short arbitrary TTL because this library sends changes rather than a heartbeat. Membership, identity, disconnect and deactivation events invalidate inappropriate records. Polling does not refresh evidence age.
- The full suite or companion supplies compatible build snapshots through LibGroupBroadcast. Builds follows the LibGroupCombatStats adapter's valid change-driven reports without adding a separate short presentation timeout. Membership, identity, connection and native timestamp validity still limit availability.
- A snapshot must be complete, current and valid for its claimed fields; missing or stale data remains `UNKNOWN`.
- Internal set/ability identities must resolve to useful display names where available.
- One-bar source activation is valid when that bar reaches the required set threshold; proc and recipient conditions remain distinct.

Build-summary protocol **510** and detailed-build protocol **507** are provisional; the current wire version is **3**. The binary build schema is **2**, with a compatibility reader for schema **1**. The newer snapshot carries separate Werewolf-bar data, verified curse/form state, ability ranks and verified Champion allocations. Older snapshots do not acquire these facts by default; ambiguous old Champion points remain unknown. The expanded capability bitmap is bound to the catalog schema. Full details are request-only, use acknowledged chunks and replace a receiver snapshot only after complete validation. Transfer limits are 64 chunks of at most 56 bytes, a minimum 1.2-second response gap, a 20-second inactivity timeout and a 180-second total lifetime. A transfer-owned watchdog follows progress without depending on an open inspector; a single compatible request retry can recover a lost initial request or response. Completed detail caches expire after 120 seconds and are invalidated on summary fingerprint changes or group reset.

Both active protocol IDs remain provisional. Legacy plan/live protocols **509/508** are retired. Active IDs must be reserved before a normal public sharing release. New installations keep supported sharing OFF until an explicit choice; existing saved choices and native OFF states remain authoritative. Enabling sharing does not establish formal protocol registration or public coexistence validation.

## Persistence

The suite preserves its established account/server SavedVariables names:

```text
AlphaSquadOverloadTrackerSavedVariables
AlphaSquadULTTrackerSavedVariables
AlphaSquadSupportCoverageSavedVariables
```

Group Ultimate settings remain inside the ULT Tracker namespace. Personal and group ULT each save an explicit `hudOrientation` and per-orientation dimensions in `hudLayouts`; selecting the other orientation does not discard its previous size. Relevant Support Coverage visibility, geometry and effect preferences migrate conservatively. Retired workflow fields are not revived as current UI or an active report collector. Peer build snapshots and Move HUD samples are transient data; previews never enter SavedVariables or transport payloads.

## Design constraints

Prefer events, coalescing, bounded caches and reused controls. Do not keep animation callbacks alive when hidden. Keep optional-library failures local to their integration. Preserve working module behavior and user preferences; avoid a broad rewrite where a targeted change is sufficient.

Maintainer review and the ESO acceptance checklist are required before release.

## Independent tracking, sharing and profiles

Dashboard invokes each module's lifecycle setter and hides disabled navigation entries. Core event scopes unregister gameplay callbacks and restore their exact filters on enable. The settings shell stays accessible when every gameplay module is disabled. Loading transitions stop local timers and defer scan/transfer work until activation.

Support Coverage runs its scanner and sender without HUD/coverage evaluation when sharing is enabled and the player is grouped. That mode uses a sixty-second recovery check; relevant local build changes still coalesce through native events. Library preferences remain separate from module activation. Group Ultimate reception and sending have separate LibGroupCombatStats registrations.

The Libraries bridge verifies the matching protocol identity and uses the library's native setting getters/setters. Supported option data can be read without opening or switching settings pages. New sharing categories default OFF and require an explicit ON. Existing saved choices and native OFF are respected; missing controls never start an unverified Ultimate sender. Missing or incompatible controls remain unavailable. The companion packages this same bridge. Before disabling native build protocols, public per-message replacement removes potentially queued personal frames for those protocols only. Combat, loading and group transitions also revoke pending owned frames. If revocation fails, the bridge attempts to disable only its own native build protocols. Their old ON cannot be restored automatically because a later native OFF cannot be distinguished through the supported API; an explicit ON is required after recovery, and this requirement survives reloads. A failed native deactivation is reported with a reload instruction because queued data cannot otherwise be reliably revoked. Unrelated transports, incognito choices and shared library event registrations are preserved.

Core Preferences opens existing account namespaces by default and native character-ID namespaces when Cross-sync is off. Switching deep-copies the current values into the selected destination and updates the live module/Group ULT references. Core sharing choices remain account/server scoped. The settings shell also retains its position. Appearance is stored in the shared preferences system and follows Cross-sync. Ember Classic, Tactical Compact and default Obsidian Studio repaint registered native controls when selected or when the profile changes; they preserve fonts, geometry, icon identities, branding and semantic status/quality/discipline colors.


## Placement, compact grids and foreground dialogs

Core Layout opens a temporary placement state for enabled modules only. It closes suite configuration windows, returns to the native base game scene and temporarily shows eligible HUD panels without changing their normal visibility preference. Entry remains pending until the native base gameplay scene is shown; it does not reveal a registered top-level while Settings is still hiding. A single scene callback resolves the pending request, without polling or repeated callback registration. Completion saves positions and restores locked interaction. Normal `hud`/`hudui` transitions remain valid during placement. Combat, loading and non-gameplay scene transitions cancel pending or active placement. It owns no recurring idle heartbeat. While an edge or corner is actively dragged, a temporary mouse-position callback applies the resize and is removed on completion/cancellation.

The personal ULT view owns one transparent HUD and resource lifecycle. Both weapon slots are always present; the actual active slot gets a green left-side marker and the inactive icon is dimmed. Native icon/cost/identity remain separate from addon-localized status text. Optional Overload uses the same state, with gold active, green ready and red stop indicators. Retired display-mode selectors do not return through profile migration. Special-bar handling reads actual native slots without falsely marking an ordinary bar active. Group ULT cannot infer a remote transformed bar from a transformation skill merely being slotted.

Core Layout distinguishes corner scaling from edge reshaping. Corners update the native parent scale continuously without rebuilding the panel; edges change saved logical width/height and invoke each panel's layout function. The opposite edge remains fixed during dragging. Rendered `GetWidth`/`GetHeight` values already include effective scale and must not be multiplied by it again. Shared logical-dimension helpers divide rendered sizes by effective scale when a logical cache is unavailable. Screen fitting is temporary and preserves the requested dimensions and scale.

The shared toolbar owns size, background opacity, reset and fitting, with one contextual input hint. It reflows without reducing native text size. Personal and group ULT have explicit Horizontal/Vertical layouts; dragging an edge does not cross an implicit orientation threshold. Both personal slots sit side by side or stack according to the explicit orientation. An orientation control is attached to each relevant HUD during placement. Group row height derives from the saved twelve-player layout and remains constant when the live roster shrinks; the visible panel contracts around its rows. Geometry signatures avoid reanchoring unchanged personal/group layouts while charge, order and readiness update. Support HUD elements reflow without stretching icons. Placement preserves module activation and normal visibility.

`Core/Preview.lua` holds Mixed, Ready, Missing, Overload and Live modes for the current session. Renderers check `Layout.IsMoving(module)` before using any samples. Group ULT offers twelve fictional players with representative readiness, missing, sharing-off, used and unavailable states; Support Coverage offers sample covered, missing, unknown, duplicate and optional sources. Overload mode uses the integrated personal view and falls back to mixed support samples. Native icons and names come from verified game identities. Preview tables are separate from live player records, coverage evaluation, inspected builds and senders; stopping placement restores live presentation without publishing sample data.

Coverage groups the current catalog into four categories and gives dense categories additional compact lanes. Layout is computed from category counts and the viewport; controls are pooled and filtering reuses them. Native icons, switches and contributor counts remain on one page. Effect hover explains conditions; contributor hover lists every available provider with source names and bar availability.

Native item, skill and Champion tooltips stay above the suite. Build refresh signatures retain tooltips for unchanged account, character and evidence; changed identities or snapshots invalidate old details. Multiple Coverage contributors open a bounded chooser, with current membership rechecked before inspection. External links use ESO's own confirmation dialog, with suite layering managed so the confirmation is visible. Sharing switches never navigate to another addon's configuration. About contains static native ESO controls and opens the verified Discord invitation directly through native external-link confirmation. There is no separate Discord page, embedded HTML browser or member-count polling. The style dropdown uses its own native opaque backdrop; it does not reskin another addon's shared popup.

Incoming build data must satisfy both structural limits and consistency checks. Claimed complete equipment is reconciled with native slot identities and linked items, including two-handed weights and set-family totals. Contradictions cannot certify completeness. A consistent report remains sender-supplied information, not protection against a modified client deliberately reporting a different build.

## Window return navigation

Core Settings owns a transient history for exclusive suite windows. Opening Group configuration, Coverage or Builds records the current addon destination; revisiting a destination removes the loop instead of accumulating duplicate history. History is bounded to eight entries and is not persisted. X/CLOSE and keyboard/controller Back restore the preceding addon window and its page, with a suitable settings page as fallback. These explicit actions differ from lifecycle cleanup: combat, loading, scene replacement and forced hiding do not reopen a window.

MOVE HUD captures its originating destination before hiding the configuration windows. Done/Back restores that destination after saving and locking placement. Safety termination clears the request and return target without displaying settings. Input ownership follows the visible destination and releases during native dialog or non-gameplay takeover.

The one Group tracking switch controls reception/display work for teammates; the local player is excluded by identity. Personal Ultimate remains its own view. Removed group visibility/self/ready-sound options and Overload cancellation fields are retired during settings normalization rather than left as invisible active controls. A previously hidden group HUD migrates to Group tracking OFF once; supported filters and geometry remain. Existing explicit reserve-warning OFF choices are preserved. Repeated reports of the same Ultimate use the lower verified cost once, and a changed identity cannot inherit the old ability's cost. Display percentage remains below 100 until actual readiness. Library sharing preferences remain separate.

## Keyboard and controller scope

`Core/Input.lua` registers existing suite controls and reads their current handlers when focus or activation changes. Buttons, toggles, sliders, dropdowns and inspectable icons share their mouse actions and tooltip content with keyboard/controller focus. Exclusive settings, Coverage and Builds windows register as input roots; the Move HUD toolbar is the placement root. Always-visible combat HUDs do not register as navigation windows, so their presence alone cannot capture gameplay input.

The custom action layer and ESO directional-input owner are active only while an eligible suite window is open. Native dialogs suspend suite navigation; combat, loading and scene transitions release it. Tab/Shift-Tab or directional navigation selects controls, and activation uses the registered action. Placement additionally supports panel cycling and separate move, scale, width, height and toolbar-control modes. Its controller movement uses native directional input and frame delta only during the open placement session. The addon does not reassign gameplay bindings. The native gamepad settings entry opens the same suite settings, rather than maintaining a second configuration state.

Automated input and geometry checks exercise these boundaries with native API contracts. Actual controller focus, native dialog behavior, font rendering and interaction across client UI scales still require the ESO acceptance checklist.

## Localization boundaries

Addon-owned English source keys resolve through a French dictionary when selected. Static native controls are bound once and refreshed only on language changes; dynamic renderers refresh their existing cached presentation. Language changes do not rescan equipment, send builds or change sharing consent. Protocol tokens, saved keys, item links and player names remain untouched. Native tooltips still use the client language. Text controls constrain wrapping/ellipsis and layouts reflow; real-client checks are required for font metrics and UI scales.
