# ULT Tracker

ULT Tracker is a generic Ultimate readiness module for **Ąlpha Şquad UI**.

## Purpose

Display the Ultimate equipped on the player's:

- MAIN / PRIMARY bar
- BACK / BACKUP bar
- or both bars simultaneously

The module does **not** maintain a hard-coded list of Ultimate abilities. It reads
the currently slotted action directly from ESO, so class Ultimates, guild
Ultimates, weapon Ultimates, subclassed builds and morphs are automatically
supported.

## Tracked information

For each bar:

- localized Ultimate name
- icon
- current Ultimate cost
- current shared Ultimate resource
- charging / ready / active state
- whether the weapon bar is currently active
- progress toward readiness

## Alerts

When a tracked Ultimate crosses from not-ready to ready:

- the icon/card enters a green READY state
- a lightweight pulse runs while it remains ready
- an optional sound is played once on the ready transition

When the Ultimate is used, the active bar is immediately removed from READY
highlighting while the API/resource state settles.

Toggle Ultimates use `IsSlotToggled()` and show `ACTIVE` rather than continuing
to flash READY while toggled on.

## Performance

ULT Tracker is event-driven:

- `EVENT_POWER_UPDATE`
- hotbar/slot update events
- active hotbar update events
- Ultimate use
- player activation

A 1.5 second safety refresh is retained only as a fallback while the tracker is
enabled, visible and unobscured. The fast animation update exists only while a
visible tracked Ultimate is actually READY.

## Commands

- `/asult` — settings
- `/asult main`
- `/asult back`
- `/asult both`
- `/asult lock`
- `/asult unlock`
- `/asult show`
- `/asult hide`
- `/asult enable`
- `/asult disable`
- `/asult reset`
- `/asult status`


## Group Ultimate Tracking

ULT Tracker includes an optional raidlead-oriented group Ultimate list.

### How tracking works

The raidlead does **not** configure players manually.

The configuration scans the current group and builds a unique list of every
shared Ultimate ability currently slotted by group members. The raidlead then
selects the **Ultimate abilities** to monitor.

Examples:

- Aggressive Horn
- Glacial Colossus
- Reviving Barrier
- Shooting Star

If a player has one of the selected Ultimates slotted on either weapon bar,
their **@UserID** is automatically added to the raidlead list. If the player no
longer has a selected Ultimate slotted, they disappear automatically.

There is no FRONT/BACK distinction in the raidlead workflow.

### Data source

ESO does not expose another player's live Ultimate resource directly to arbitrary
addons. Group tracking therefore integrates with **LibGroupCombatStats**, which
shares Ultimate data through the official ZOS group broadcast API.

Install LibGroupCombatStats with the dependencies declared by its current package. The personal MAIN/BACK tracker does not require this library. See the shared **Libraries** page for setup guidance.

When LibGroupCombatStats is available, AlphaSquadUI registers for **ULT only**.
No DPS or HPS data is requested.

Compatible group Ultimate data can come from Ąlpha Şquad UI or another addon that actively publishes the same LibGroupCombatStats data. Merely installing a library does not guarantee every peer is sharing. This integration does not inspect remote gear, full skill bars, Champion selections or Class Masteries; Support Coverage build sharing is separate.

### Raidlead configuration

Open:

`Settings > Ąlpha Şquad UI > ULT Tracker > CONFIGURE GROUP`

or:

`/asult group`

The configuration shows the group's available Ultimate identities in a compact
scrolling list. Up to 24 Ultimate filters can be retained in the saved selection.

For each Ultimate:

- icon
- exact localized Ultimate name
- number of group members currently slotting it
- ON/OFF tracking state

`SELECT ALL` and `CLEAR ALL` are available.

### Group HUD

The raidlead HUD is a compact vertical list with **one @UserID per line**.

Each line shows:

- @UserID
- one large icon for the most relevant selected Ultimate
- charge percentage calculated against that Ultimate's real cost
- a compact progress bar
- READY visual state

The HUD intentionally does not display Ultimate names or raw Ultimate-point
counts, keeping the raidlead list compact.

If a player matches multiple selected Ultimates, the HUD prioritizes a READY
Ultimate first; otherwise it displays the matching Ultimate closest to READY.

READY players are sorted to the top and receive a high-contrast orange/gold/white
pulse.

When a tracked player's shared Ultimate resource drops after previously being
ready for a selected Ultimate, that row is strongly dimmed for a short period.
Because ESO group sharing exposes resource/slot information rather than a
guaranteed remote cast ID, this spent-Ultimate indicator is an informed visual
signal rather than combat-log proof of which exact remote Ultimate was cast.

### Performance

Group tracking remains event-driven through LibGroupCombatStats Ultimate events.

- incoming updates are coalesced
- hidden settings panels are not refreshed
- disabled group HUDs do not rebuild rows
- only READY rows use a lightweight pulse update
- one 2-second safety refresh runs only while Group Tracking and its parent are enabled, visible and unobscured
- row controls are created once and reused
- no combat-log parsing is required

### Commands

- `/asult group` — open Group Ultimate configuration
- `/asult group show`
- `/asult group hide`
- `/asult group lock`
- `/asult group unlock`
- `/asult group reset`


### Compact percentage HUD

The group HUD is intentionally minimal for raidlead use:

- one @UserID per row
- large tracked Ultimate icon
- charge percentage only
- no Ultimate name in the HUD
- no raw Ultimate point count

Percentage is calculated against the real cost of the tracked Ultimate and is
capped at 100%.

Rows are ordered:

1. READY players first
2. charging players by highest percentage
3. recently spent Ultimates last

READY rows use a high-contrast orange/gold/white pulse. Recently spent rows are
strongly dimmed for a short period.


### Persistent HUD sizing

Group Ultimate Config exposes explicit HUD sizing controls:

- **Overall Scale**: 60%–180%
- **List Width**: 240–520 px
- **Row Height**: 28–56 px
- **Background Opacity**: 30%–100%
- **Reset Size**
- **Reset Position**

Row Height also scales the Ultimate icon automatically, keeping the compact list
balanced and responsive.

All group tracker preferences are stored in account-wide ESO SavedVariables for
the current server/world, including tracked Ultimate filters, HUD scale, width,
row height, opacity, position, lock state, visibility, self inclusion and ready
sound preference. Values survive reloads, zoning and game restarts.
