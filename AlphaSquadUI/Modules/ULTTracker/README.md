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
- effective ability ID
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

A 1.5 second safety refresh is retained only as a fallback. The fast animation
update exists only while a tracked Ultimate is actually READY.

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

The personal MAIN/BACK tracker does not require this library.

When LibGroupCombatStats is available, AlphaSquadUI registers for **ULT only**.
No DPS or HPS data is requested.

Compatible group data can come from AlphaSquadUI, Hodor Reflexes, or another
addon registered with LibGroupCombatStats.

### Raidlead configuration

Open:

`Settings > Ąlpha Şquad > ULT Tracker > CONFIGURE GROUP`

or:

`/asult group`

The configuration shows up to 24 unique Ultimates from the current 12-player
group in a compact two-column list.

For each Ultimate:

- icon
- exact localized Ultimate name
- number of group members currently slotting it
- ON/OFF tracking state

`SELECT ALL` and `CLEAR ALL` are available.

### Group HUD

The raidlead HUD is a compact vertical list with **one @UserID per line**.

Each line can show:

- @UserID
- matching selected Ultimate icon(s)
- exact matching Ultimate name(s)
- current Ultimate points / relevant cost
- READY state

READY players are visually prioritized and receive a subtle pulse.

When a tracked player spends an Ultimate after being ready, that row is strongly
dimmed for a short period so the raidlead can immediately distinguish spent
Ultimates from players who are ready.

### Performance

Group tracking remains event-driven through LibGroupCombatStats Ultimate events.

- incoming updates are coalesced
- hidden settings panels are not refreshed
- disabled group HUDs do not rebuild rows
- only READY rows use a lightweight pulse update
- one 2-second safety refresh runs only while Group Tracking is enabled
- row controls are created once and reused
- no combat-log parsing is required

### Commands

- `/asult group` — open Group Ultimate configuration
- `/asult group show`
- `/asult group hide`
- `/asult group lock`
- `/asult group unlock`
- `/asult group reset`
