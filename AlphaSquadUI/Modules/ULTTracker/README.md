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

ULT Tracker also contains an optional raidlead-oriented group window.

### Data source

ESO does not expose another player's live Ultimate resource directly to arbitrary
addons. Group tracking therefore integrates with **LibGroupCombatStats**, which
shares Ultimate data through the official ZOS group broadcast API.

The personal MAIN/BACK tracker does not require this library.

When LibGroupCombatStats is available, AlphaSquadUI registers for **ULT only**.
No DPS or HPS data is requested.

Compatible group data can come from:

- another AlphaSquadUI user with LibGroupCombatStats installed
- Hodor Reflexes
- another addon registered with LibGroupCombatStats

### Raidlead configuration

Open:

`Settings > Ąlpha Şquad > ULT Tracker > CONFIGURE GROUP`

or:

`/asult group`

Each current group member can be configured independently:

- **TRACK** — show this player
- **HIDE** — exclude this player
- **FRONT** — track the Ultimate currently shared from the player's front bar
- **BACK** — track the Ultimate currently shared from the player's back bar
- **BOTH** — display and track both shared bar Ultimates independently

The selector uses the actual shared ability IDs, localized names, icons and
costs. This means any Ultimate or morph can be displayed without maintaining a
hard-coded ability list.

### Group HUD

The dedicated group window is a compact 3×4 raid grid for up to 12 players.

Each player card displays:

- character name
- exact selected Ultimate name(s)
- FRONT/BACK source
- live Ultimate points and cost
- independent READY state for each tracked Ultimate
- subtle READY pulse only on the Ultimate line that is ready
- NO DATA / EMPTY states when appropriate

The group window is:

- movable
- lockable
- position-persistent
- scalable
- background-opacity configurable
- screen-clamped and responsive
- automatically hidden with major UI menus when configured

Group READY sound is optional and disabled by default. The group configuration uses an internal selector panel; no external ESO popup menu is used.

### Performance

Group tracking is event-driven through LibGroupCombatStats Ultimate events.

- incoming updates are coalesced
- hidden settings panels are not refreshed
- disabled group HUDs do not rebuild rows
- no permanent READY animation loop is used for the group list
- one 2-second safety refresh runs only while Group Tracking is enabled
- row controls are pooled instead of recreated during combat

### Commands

- `/asult group` — open Group Ultimate configuration
- `/asult group show`
- `/asult group hide`
- `/asult group lock`
- `/asult group unlock`
- `/asult group reset`
