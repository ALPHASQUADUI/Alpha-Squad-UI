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
