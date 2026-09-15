# Video review and corrections — 3.2.0

This review uses the supplied 161-second recording of 3.1.0 at 2560 × 1440, the attached interface crops, current addon code and native ESO source. The recording was inspected sequentially, with closer frame review around interactions. No private screenshots, account lists, chat content or raw group data are included here.

The recording documents the behavior before these changes. It is not a recording of the corrected native interface. Approximate timestamps below refer to the submitted video, not to an automated rendering session.

## Recorded observations

| Time | What the recording shows | Response |
| --- | --- | --- |
| 00:15–02:10 | Workspace labels are clipped, including Support Coverage and Website & About, across themes | Wider navigation; the community destination is named About |
| 00:19, 00:35, 00:42 | Open style choices overlap the descriptive text behind the dropdown | A dedicated native opaque dropdown backdrop |
| 00:46–00:53 | Group configuration presents separate GROUP, HUD, SELF and READY SOUND controls | One Group tracking switch on the parent page; configuration retains ability selection |
| 00:49–00:53 | Empty-group text directs the user to another library's settings | Explanations distinguish no teammates from unavailable sharing and point to Libraries |
| 00:53–00:57 | Closing Group configuration leaves no addon window; reopening requires native Settings navigation | Explicit Close/Back restores the previous addon destination |
| 01:28–01:31 | Closing Coverage similarly leaves the native Settings category without an addon window | The same return-navigation path covers Coverage and Builds |
| 01:39–01:56 | About and Discord form two internal destinations; the About button opens the separate Discord page | About opens the verified Discord invitation directly |
| 02:11–02:15 | The game's FPS counter briefly decreases around opening Builds and then recovers | Retained as a profiling lead; no isolated cause or measured performance gain is claimed |

Tooltips for Coverage and equipment appear above the addon in the recording. The native URL confirmation is also visible in front around 01:41. Those working paths are retained rather than presented as newly repaired failures. No blank catalogue icon was identifiable from the recording; an identified native category symbol is still a fallback, not a unique image for an effect.

The user reports that MOVE HUD does nothing when clicked. The editor never remains visible in this recording, and an actual resize sequence could not be evaluated. The repair below addresses concrete scene-ordering problems found in the implementation; fluid resizing still requires a new client check. Automatic Overload stopping was also reported as ineffective and requested for removal; the recording does not demonstrate an Overload cutoff trial.

## Scene ordering and return navigation

ESO distinguishes a requested scene change from the subsequent shown state. Registered top-level controls can be hidden by native scene cleanup, so opening the placement toolbar while Settings is still hiding can close the new editor immediately. MOVE HUD now stores one pending request, hides configuration, requests the base gameplay scene and activates only after it is shown. Repeated requests reuse this state. The normal `hud`/`hudui` transition is allowed during placement; combat, loading and unrelated menus cancel it. This implementation follows the [native scene lifecycle](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/zo_scene/zo_scene.lua) and [in-game scene manager](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/scenes/ingamescenemanager.lua).

The previous secondary-window close handlers hid their window without restoring an addon destination. Core Settings now keeps bounded transient return history. Explicit X/CLOSE, Back and placement Done restore the preceding window and its page. Revisiting an existing destination removes the loop instead of accumulating duplicate history. Safety cleanup uses dismissal without return navigation, so combat or loading cannot unexpectedly reopen settings. Native keyboard/controller input follows the resulting visible window.

Requested geometry, explicit horizontal/vertical orientation and temporary screen fitting remain separate. Pending placement owns no recurring polling loop; active mouse-resize work exists only during dragging. Automated lifecycle scenarios exercise asynchronous Settings closure, repeated entry, gameplay/cursor transitions, interruption and return navigation. They do not reproduce native font rasterization or every device's timing.

## Readability and community links

Workspace gains enough horizontal space for its navigation text. About replaces the clipped combined label and removes duplicate community navigation. The style selector owns its own native dropdown object and opaque backdrop, leaving shared menus used by other addons alone. Native dropdown ownership was checked against the [ESO ComboBox implementation](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/libraries/zo_combobox/zo_combobox.lua).

The Discord invitation was verified from the public [Alpha Squad website](https://alphasquadeso.com/). About opens [that invitation](https://discord.gg/snDyd23h6N) through ESO's normal external-link confirmation. No iframe, widget, live member polling or build-data transmission is involved.

## Ultimate behavior and truthful state

Automatic effect cancellation is removed from Overload's logic, controls and obsolete actions. Warning starts, optional reserve alerts and the ready reminder remain, with existing supported OFF preferences preserved. The user controls activation and stopping through the normal Ultimate binding.

Group tracking excludes the local player before constructing teammate rows. One enabled state replaces the previous tracking/visibility combination, and an existing hidden group HUD migrates to OFF once. Filters and geometry remain. Group-ready sounds and self controls are retired rather than left hidden but active. Libraries sharing remains independent.

Personal Ultimate tracking resolves `GetActiveHotbarCategory` and actual native slot metadata during a special bar instead of depending on a fixed transformation-ID list. `GetActionSlotEffectTimeRemaining` supplies an available timed ACTIVE state. Normal weapon-bar display preferences return when the special bar ends. The contracts are documented in the [native API reference](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/ESOUIDocumentation.txt). This does not guarantee compatibility with an unreleased bar category or missing future API.

Group Ultimate information remains constrained by LibGroupCombatStats: it reports front/back ability facts, not an independently observed remote transformed bar. Receiving a transformation Ultimate does not prove that player is transformed. Repeated identities use the lower verified bar cost once, changed identities discard stale cost, and a value such as 249/250 cannot display 100% before readiness.

Builds also had a presentation-only short timeout for LibGroupCombatStats reports, despite its adapter accepting valid change-driven reports without artificial expiry. That extra timeout is removed. Existing identity, membership, connection and native timestamp checks remain; polling does not make old evidence newly received. The change-driven contract is visible in the [library source](https://github.com/m00nyONE/LibGroupCombatStats/blob/c88f69f7d5b970127dd9355377cad22dd1cc9ac5/LibGroupCombatStats.lua).

## Resource and security review

Support Coverage previously scheduled a deferred callback for each screen-resize notification. A pending flag now coalesces a burst into one callback that reads current dimensions. A regression sends 200 notifications before dispatch and checks one resulting refresh. This establishes the eliminated duplicate work, not an FPS improvement on the user's machine.

The transport review examined untrusted reports, field/size validation, duplicate state, expiry, native library settings and link handling. No new concrete injection or exfiltration defect was identified in the paths examined. Existing wire/schema identifiers and sharing preferences are unchanged. See the [security review](SECURITY_REVIEW.md) for tested boundaries and remaining limits.

A consistent peer report is not independent proof of another player's build. Group broadcasts are not encrypted, a checksum is not authentication, and unknown fields must remain unknown. Protocol IDs 507/510 still require reservation and coexistence validation. Neither this review nor automated regression checks certify every possible vulnerability or a future game version.

## Required client follow-up

Run the [acceptance checklist](SUPPORT_COVERAGE_TESTING.md) with both fresh and migrated preferences. Priorities are entry from native keyboard/gamepad Settings, Move HUD Done/Back and interruption, secondary-window round trips, viewport/UI-scale changes, dropdown readability, Overload warnings, personal special bars and actual grouped Ultimate reports. Compare frame time and memory with and without the addon in representative dungeon/trial groups.

The validator checks Lua 5.1/5.4 logic and syntax, metadata, XML and installable packages. Current validation output supplies the result; this document does not substitute a count from an earlier release or claim native rendering was tested after the changes.
