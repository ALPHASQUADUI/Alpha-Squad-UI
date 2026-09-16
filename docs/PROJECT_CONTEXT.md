# Project context

Ąlpha Şquad UI 3.4.0 is a development candidate for a compact bilingual interface. It combines precombat Support Coverage, visual build inspection and personal/group Ultimate tracking with optional integrated Overload behavior. Public maintainer: **@SeRuM1**; Git identity: **SeRuM1 <info@alphasquadeso.com>**.

## Git workflow

All changes stay on `dev`. The maintainer tests the exact build in ESO and approves the cycle before a requested `dev` → `main` PR. The assistant never approves or merges a PR, enables auto-merge or directly updates `main`. Human approval and merging are mandatory. This cycle authorizes development only: no PR, tag, GitHub Release, ESOUI or website publication.

## Current interface direction

Dashboard owns tracking switches, Cross-sync, language and settings style; Libraries owns voluntary sharing. The Core shell remains accessible with all tracking disabled. English and French are supported; automatic mode follows the game language, falling back to English for other locales. An explicit choice is saved account-wide. Code, public documentation, commits and PRs stay English; translation resources contain the requested French text.

Gameplay windows favor compact native icons, neutral surfaces and concise text. Settings retain the orange accent. Personal Ultimate always displays both weapon bars, without background, Ultimate names or repeated branding. A green marker immediately left of the active slot identifies the actual bar; the other icon is dimmed. Horizontal/vertical placement stays explicit and progress remains visible. Overload keeps its mechanics: gold active state, green ready pulse and red stop pulse.

MOVE HUD actions are available in each movable module. Orientation controls sit beside the relevant HUD. Done/Escape saves and locks placement, then selects Alpha Squad in native settings; combat/loading dismiss safely without reopening menus. Main Close returns to gameplay.

## Data and consent

Support Coverage is a precombat availability check with Trial/Dungeon contexts and configurable Buffs, Debuffs, Group Sets and Group Mythics. It never claims buff uptime, current recipient coverage or remote inventory access from group membership alone. Detailed builds are voluntary, requested on demand and transient. Item links, skill morphs, allocated CP and per-bar set thresholds remain authoritative.

Existing account/server preferences and SavedVariables namespaces are preserved; character profiles retain current placement. New sharing starts OFF until an explicit choice. Native OFF states and existing choices remain respected, independently of tracking and visibility. Protocol IDs remain provisional until actual reservation and coexistence evidence is recorded.

## Acceptance

Automated validation does not establish native rendering, translated text fit, frame time or multiplayer coexistence. See the changelog, current development audit and client checklist. A screenshot of the previous UI is design input, not evidence that the new build has passed ESO testing.
