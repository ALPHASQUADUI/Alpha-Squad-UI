# Engineering audit — 3.1.0

Reviewed on 2026-09-15. This audit covers shared UI infrastructure, personal Ultimate and integrated Overload, Group Ultimate, Support Coverage, build inspection, the companion, preferences, packaging and documentation. It records implemented corrections and their evidence. It is not a certification of an untested game client or a guarantee about future game changes.

## Findings and corrections

| Finding | Impact | Correction and regression evidence |
| --- | --- | --- |
| Scaled native dimensions reused as logical dimensions | Repeated resizing shrank or displaced controls, especially under inherited UI scale | Shared logical-dimension helpers; realistic scaled mocks in settings, placement, Builds and tooltip suites |
| Personal BOTH layout changed orientation at a width threshold | A height jump triggered another screen fit and visibly reduced the panel | Explicit Horizontal/Vertical orientation and independent saved geometry; compact new-install defaults |
| Rounded scaling and repeated layout rebuilding during corner drags | Coarse size changes and unnecessary rebuilding | Fractional proportional scaling, opposite-edge anchoring, unchanged-update guards; corner drags do not rebuild content every frame |
| Viewport changes during a drag | Cursor coordinates and saved panel geometry could disagree | Stop on the native resize-start event, refit after native resize completion, retain requested preferences |
| Solo editing lacked realistic content | Empty panels concealed group row spacing, filters and status states | Editor-only examples for twelve fictional players, with native icons and mixed states; no writes to live roster or transport |
| Mouse-only custom controls | Controller users could not reliably reach the same settings and details | Scoped action layer, directional focus, native tooltip activation, logical value adjustment and gamepad Settings category |
| Mannequin and equipment layout used inconsistent dimensions | Stretched body image and asymmetric spacing | Preserve the native 64:256 texture proportion; centered image and paired equidistant armor columns |
| Tooltip fit mixed parent and local scale | Too-small tooltips or changes to a reused native tooltip | Fit the tooltip's own scale once; restore only properties still owned by this addon |
| Wrong skill/mastery identities | Unrelated abilities could establish group coverage | Corrected native identities and negative cases; patch-specific evidence kept separately |
| Missing or unsuitable artwork | Empty icons or misleading visual associations | Native ability/item/set collection resolution, with explicit native category fallback |
| Structurally plausible but contradictory peer data | Invalid equipment, scripts or allocations could influence coverage | Native slot/type and consistency checks; unknown data cannot certify completeness |
| Late fragments and refreshed fingerprints extended stale data | An expired build could remain usable | Expiry enforced before accepting transfer activity; detail age independent of unchanged summary traffic |
| Companion repeated full scans for readiness updates | Unnecessary work during equipment/effect bursts | Coalesced build captures and separate lightweight consumable updates |

The regressions test outcomes such as preserved requested size, stable card orientation, rejection of the wrong ability, and expiration despite subsequent traffic. They are not screenshots of the native renderer. See the [security review](SECURITY_REVIEW.md) and [catalog evidence](CATALOG_EVIDENCE.md) for exact data boundaries and source mappings.

## Native geometry and input contracts

ESO exposes rendered dimensions that already include effective scale. Its own radial menu divides dimensions by `GetScale()`, and its scroll container converts rendered height back into local units. The addon now makes that conversion at measurement boundaries, keeps requested dimensions in logical units and applies scale only when rendering. It does not overwrite the user's requested size with a temporary smaller-screen fit. These choices follow the [native radial menu](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/zo_radialmenu/zo_radialmenu.lua) and [native scroll container](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/zo_templates/scrollcontainer_shared.lua).

Layout responds to completed GUI screen resizing, with an earlier event cancelling an active drag. This avoids reading the old geometry while native UI scale changes are still pending. Fullscreen, borderless and windowed modes share this viewport contract. This is an implementation basis for adaptation, not proof that every resolution or device has been rendered successfully. Event and local-scale methods were checked against the [native API reference](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/ESOUIDocumentation.txt).

Keyboard/controller focus belongs only to visible registered addon windows. Hiding a window, combat, loading, scene transitions and native dialogs release its action layer and directional listener. Defaults do not remap gameplay keys globally. Device-specific hints use native binding glyphs, and the gamepad options entry uses the native custom-category API. Implementation references are the [directional-input manager](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/zo_directionalinput/zo_directionalinput.lua), [keybinding helpers](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/utility/keybindingutils.lua) and [gamepad options](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/pregameandingame/zo_options/gamepad/zo_options_gamepad.lua).

## Visual hierarchy and terminology

The interface retains three saved styles and semantic colors. The Obsidian palette now uses the near-black surfaces, warm orange accent and neutral text hierarchy of the [Alpha Squad website](https://alphasquadeso.com/). Changing style does not recolor item quality, Champion discipline or readiness states. No website content is fetched by the addon during gameplay.

Personal Ultimate owns integrated Overload; there is one personal placement target. Horizontal and Vertical are deliberate choices instead of a hidden width-dependent switch. Preview and live data are visibly distinct, with preview state held outside SavedVariables and network state. Missing data remains unknown rather than receiving a fabricated skill or empty slot claim.

Builds uses real native item links for equipment details, exact reported ability identities for skills and native Champion artwork. Category artwork is a fallback symbol, not a claim that each effect has a unique native icon. The [catalog evidence](CATALOG_EVIDENCE.md) describes what was checked and which recipes or conditions cannot yet establish coverage. A build source being available before combat does not prove that its proc is active or that every group member receives its effect.

The expanded native Add-Ons entry continues to list the seven libraries used by the complete group feature set. States follow native installed/enabled/dependency information: green when available, red with a reason otherwise. Metadata remains within its compact byte budget so the name and author survive native truncation. Local tracking remains available when group integrations are missing.

## Performance and lifecycle

Placement has no idle polling loop. Continuous input runs while the editor owns input; mouse resizing updates only during a drag. Scale-only changes avoid content rebuilds. Group rows and coverage controls are pooled; skill metadata is cached and invalidated by relevant changes. Preview selection reuses presentation controls and never starts a broadcast or adds a fake live player.

Support scans wait for player activation and coalesce build changes. Loading and combat suspend capture and detailed transfer. The companion separates readiness updates from equipment/skill capture and avoids a solo heartbeat. Disabled tracking retains only the data work permitted by Libraries. Group Ultimate subscriptions remain limited to Ultimate information.

No artificial short timer was added to the Group Ultimate HUD's unchanged library values: LibGroupCombatStats suppresses unchanged broadcasts, so lack of a new message alone does not establish a missing Ultimate. This behavior was checked against the [library implementation](https://github.com/m00nyONE/LibGroupCombatStats/blob/c88f69f7d5b970127dd9355377cad22dd1cc9ac5/LibGroupCombatStats.lua). Availability, membership and connection state remain relevant invalidation signals.

These measures reduce specific redundant work. Real frame time, memory growth, input latency and group-broadcast coexistence have not been measured in this environment. The [performance guide](PERFORMANCE.md) defines client comparisons instead of claiming zero resource cost.

## Security and compatibility

Shared builds are untrusted peer reports. Native resolution can reject malformed IDs, incompatible slots, duplicated allocations and inconsistent set counts; it cannot attest that another player actually wears a plausible reported item. Group broadcasts are not encrypted, and a checksum is not authentication. Shared strings do not provide executable code, URLs or arbitrary texture paths. Peer detail data remains transient. The [security review](SECURITY_REVIEW.md) documents the exact limits and tests.

Saved account/character namespaces remain compatible. Existing OFF preferences take precedence over first-install defaults. Requested geometry survives temporary fitting, orientation settings are explicit, and previews are not persisted. Missing APIs or unsupported recipes leave limited evidence rather than synthesizing facts about future versions.

Active build transport IDs 507 and 510 remain provisional. Reservation and coexistence testing are still required for stable public transport. This audit does not claim otherwise or silently change the wire protocol.

## Validation and outstanding acceptance

`tooling/validate.py` compiles runtime Lua, executes all regression suites under Lua 5.1 and 5.4, checks version/manifest inventory, parses the binding XML and verifies both ZIP layouts. The companion is also exercised after extraction from its installable package. Geometry mocks include inherited effective scale, and input tests cover release and resumption around native UI ownership.

Remaining client acceptance is concrete: install fresh and upgrade with existing SavedVariables; exercise both input modes and native dialogs; resize during resolution/UI-scale changes; configure a twelve-player preview; inspect local and received items/CP/scripts; test transfers with loss and loading; compare performance in actual dungeon and trial groups. Follow the [client checklist](SUPPORT_COVERAGE_TESTING.md). These checks are required to assess native behavior that automated mocks cannot reproduce.
