# Project context

Ąlpha Şquad UI 3.5.0 is a development candidate implementing the selected personal Ultimate design 2 and reversible native Ultimate-slot replacement. It combines precombat Support Coverage, visual build inspection and personal/group Ultimate tracking with optional integrated Overload behavior. Public maintainer: **@SeRuM1**; Git identity: **SeRuM1 <info@alphasquadeso.com>**.

## Git workflow

All changes stay on `dev`. The maintainer tests the exact build in ESO and approves the cycle before a requested `dev` → `main` PR. The assistant never approves or merges a PR, enables auto-merge or directly updates `main`. Human approval and merging are mandatory. This cycle authorizes development only: no PR, tag, GitHub Release, ESOUI or website publication.

## Current interface direction

Dashboard owns tracking switches, Cross-sync, language and settings style; Libraries owns voluntary sharing. The Core shell remains accessible with all tracking disabled. English and French are supported; automatic mode follows the game language, falling back to English for other locales. An explicit choice is saved account-wide. Code, public documentation, commits and PRs stay English; translation resources contain the requested French text.

Gameplay windows favor compact native icons, neutral surfaces and concise text. Settings retain the orange accent. Personal Ultimate design 2 displays both normal weapon slots with native icons, actual points/native costs, thin progress bars and concise localized states, without background, Ultimate names or repeated branding. A green marker immediately left of the active slot identifies the actual bar; the other slot is dimmed. Horizontal/vertical placement stays explicit. Overload shows actual remaining points and a reserve marker; its reminder is not a cost. Its mechanics remain manual: neutral inactive, gold active, green ready pulse and red stop pulse.

Only an enabled, visible personal replacement suppresses the native Ultimate button visually. Personal visibility OFF, module OFF, menus, loading and placement restore it. Ultimate casting remains native, and group tracking can continue when personal visibility is OFF. Language changes preserve placement and use cached presentation data.

MOVE HUD actions are available in each movable module. Orientation controls sit beside the relevant HUD. Done/Escape saves and locks placement, then selects Alpha Squad in native settings; combat/loading dismiss safely without reopening menus. Main Close returns to gameplay.

## Data and consent

Support Coverage is a precombat availability check with Trial/Dungeon contexts and configurable Buffs, Debuffs, Group Sets and Group Mythics. It never claims buff uptime, current recipient coverage or remote inventory access from group membership alone. Detailed builds are voluntary, requested on demand and transient. Item links, skill morphs, allocated CP and per-bar set thresholds remain authoritative.

Existing account/server preferences and SavedVariables namespaces are preserved; character profiles retain current placement. New sharing starts OFF until an explicit choice. Native OFF states and existing choices remain respected, independently of tracking and visibility. Protocol IDs remain provisional until actual reservation and coexistence evidence is recorded.

## Acceptance

The maintainer reported native duplicate `BG` and `Scroll` errors when the 3.4.0 Dashboard created its language dropdown. Version 3.4.1 gives each private native dropdown a distinct addon-prefixed root and retains per-combo reuse. Automated regression coverage now models native child-name collisions; no native retest has been reported. Version 3.5.0 retains this fix and awaits acceptance of both dropdowns, the selected HUD and native-slot restoration in keyboard/gamepad modes and alongside other action-bar addons.

Automated validation does not establish native rendering, translated text fit, frame time or multiplayer coexistence. See the changelog, current development audit and client checklist. A screenshot of the previous UI is design input, not evidence that the new build has passed ESO testing.
