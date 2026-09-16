# Project context

Ąlpha Şquad UI 3.6.0 is a development candidate improving HUD placement, language selection and raid Ultimate coordination. It combines precombat Support Coverage, visual build inspection and personal/group Ultimate tracking with optional integrated Overload behavior. Public maintainer: **@SeRuM1**; Git identity: **SeRuM1 <info@alphasquadeso.com>**.

## Git workflow

All changes stay on `dev`. The maintainer tests the exact build in ESO and approves the cycle before a requested `dev` → `main` PR. The assistant never approves or merges a PR, enables auto-merge or directly updates `main`. Human approval and merging are mandatory. This cycle authorizes development only: no PR, tag, GitHub Release, ESOUI or website publication.

## Current interface direction

Dashboard owns tracking switches, Cross-sync, language and settings style; Libraries owns voluntary build/Ultimate/set sharing. The Core shell remains accessible with all tracking disabled. Only English and French appear in the language selector. A supported game locale seeds the saved choice once, otherwise English; later client-language changes do not override it. Verified ID-based catalog names follow this choice, while unresolved names and complete native tooltips retain client text. Code, public documentation, commits and PRs stay English; translation resources contain the requested French text.

Gameplay windows favor compact native icons, neutral surfaces and concise text. Settings retain the orange accent. Personal Ultimate design 2 displays both normal weapon slots with native icons, actual points/native costs, thin progress bars and concise localized states, without background, Ultimate names or repeated branding. A green marker immediately left of the active slot identifies the actual bar; the other slot is dimmed. Horizontal/vertical placement stays explicit. Overload shows actual remaining points and a reserve marker; its reminder is not a cost. Its mechanics remain manual: neutral inactive, gold active, green ready pulse and red stop pulse.

The former native Ultimate-button suppression is removed. Personal tracking never changes native Ultimate visibility, alpha, mouse input or handlers. ESO and other action-bar addons retain control. Group tracking can continue when personal visibility is OFF; language changes preserve placement and use cached presentation data.

MOVE HUD actions are available in each movable module. The selected panel's entire body can be dragged over its rows/icons without a frame poll; unsupported background controls are hidden. Orientation controls sit beside the relevant HUD. Done/Escape saves and locks placement, then selects Alpha Squad in native settings; combat/loading dismiss safely without reopening menus. Main Close returns to gameplay.

Group Ultimate filters use nineteen curated support families with verified morphs and seven defaults. Cryptcanon requires the actual dedicated slotted Ultimate and cost, never a gear guess. The crown assigns the raid leader; only that player edits the group's shared filters. Dedicated provisional protocol 511 carries settings metadata and respects native OFF. Food markers reuse fresh, matching Support evidence and distinguish active, absent and unknown without new scans or sends.

## Data and consent

Support Coverage is a precombat availability check with Trial/Dungeon contexts and configurable Buffs, Debuffs, Group Sets and Group Mythics. It never claims buff uptime, current recipient coverage or remote inventory access from group membership alone. Detailed builds are voluntary, requested on demand and transient. Item links, skill morphs, allocated CP and per-bar set thresholds remain authoritative.

Existing account/server preferences and SavedVariables namespaces are preserved; character profiles retain current placement. New sharing starts OFF until an explicit choice. Native OFF states and existing choices remain respected, independently of tracking and visibility. Protocol IDs remain provisional until actual reservation and coexistence evidence is recorded.

## Acceptance

The maintainer reported native duplicate `BG` and `Scroll` errors in the 3.4.0 Dashboard. Version 3.4.1 gave private dropdowns distinct roots and added collision regressions. The subsequent gameplay recording provides design and interaction evidence, not a complete versioned retest record. The 3.5.0 native-slot replacement was rejected and is removed in 3.6.0. Current acceptance must cover dropdowns, drag interactions, language fit, food uncertainty and multi-client leader/filter synchronization against the delivered commit.

Automated validation does not establish native rendering, translated text fit, frame time or multiplayer coexistence. See the changelog, current development audit and client checklist. A screenshot of the previous UI is design input, not evidence that the new build has passed ESO testing.
