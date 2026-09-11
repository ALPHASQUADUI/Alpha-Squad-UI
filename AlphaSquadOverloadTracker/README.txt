ĄLPHA ŞQUAD - OVERLOAD TRACKER v2.5.0

NEW IN 2.5.0 - MODULAR / PERFORMANCE EDITION
- Rebuilt Settings as a single modular Ąlpha Şquad shell with an internal sidebar.
- Current module: Overload. Future Ąlpha Şquad features can be added as new sidebar modules without adding extra ESO Settings entries.
- Added a separate Website & About page with a clean clickable alphasquadeso.com promotion.
- Settings UI is static/event-driven: no permanent animation or OnUpdate loop.
- Core tracking remains event-driven (effect, slot, hotbar and Ultimate events).
- Reduced the old 150 ms fallback sync to a lightweight 1000 ms safety heartbeat; while no Overload is slotted, the fallback check is effectively only once every 3 seconds.
- Unrelated skill-slot updates are ignored when ESO provides the changed slot number.
- Emergency/READY animation loops only exist while their corresponding alert is actually active.
- Removed unused LibAddonMenu settings code. The addon uses only the native Settings > Ąlpha Şquad entry.
- Existing SavedVariables and all v2.4 tracker behavior are preserved.

ĄLPHA ŞQUAD - OVERLOAD TRACKER v2.4.0

NEW IN 2.4.0
- Background opacity now affects ONLY the HUD background. Text, icons, borders and status remain fully visible.
- The tracker automatically hides when ESO opens full UI scenes such as Inventory, Champion, Settings, Crown Store and similar menus, then returns automatically to the gameplay HUD.
- Added a native direct Settings menu entry named Ąlpha Şquad with an orange-to-white branded text treatment. The addon is no longer registered under Settings > AddOns.
- Added "Disable tracker in PvP" (default OFF). When enabled, the HUD, sounds, reserve alarm and READY reminder are suppressed in PvP contexts such as Cyrodiil/Imperial City and Battlegrounds.
- Existing no-Overload dormancy remains unchanged: no slotted Overload on Primary/Backup means no HUD and no alerts.

ĄLPHA ŞQUAD - OVERLOAD TRACKER v2.3.0

NEW IN 2.3.0
- Fixed false-active dormancy detection: only the real PRIMARY and BACKUP Ultimate slots can wake the addon.
- Temporary/active/Overload hotbars no longer count as a slotted Overload.
- If no Overload / Energy Overload / Power Overload is equipped on either weapon bar, the HUD is fully hidden and all ready/reserve visual and audio systems are dormant.
- Added a permanent current Ultimate counter (ULT xxx) in the normal HUD state while Overload is ON or OFF.
- The numeric Ultimate counter is intentionally hidden during READY TO ACTIVATE and reserve alarm modes.
- During the red reserve alarm, the right-side area shows TURN OFF! instead of the numeric counter.

ĄLPHA ŞQUAD - OVERLOAD TRACKER v2.2.0

NEW IN 2.2.0
- Automatic context mode: if Overload, Energy Overload or Power Overload is not slotted on either weapon bar, the combat HUD hides and all alert/reminder activity goes dormant automatically.
- Equipping any tracked Overload morph wakes the tracker back up automatically.
- No Sorcerer-class restriction: works with subclassing as long as a tracked Overload morph is actually equipped.
- Removed automatic Ultimate/recharge/reserve chat spam. Visual and audio alerts remain active when relevant.
- User Show/Hide and Enable/Disable preferences are preserved while context dormancy is active.

COMMUNITY WEBSITE UPDATE
=====================================

v2.1.0:
- Added a dedicated Ąlpha Şquad Community card inside the built-in addon settings.
- Added a clickable https://alphasquadeso.com/ link and VISIT WEBSITE button.
- Added the official website field to LibAddonMenu so its website shortcut is available when LAM is installed.
- Added an Ąlpha Şquad Community section and clickable website button in LibAddonMenu settings.
- Added /asoverload website (aliases: /asoverload site, /asoverload community).
- No website link or advertisement is shown on the combat HUD.

ĄLPHA ŞQUAD - OVERLOAD TRACKER v2.0.0
READY REMINDER HOTFIX
=====================================

v2.0.0 FIX:
- Fixed the Ultimate action-slot index used by slot scanning. ESO's UI base constant must be offset by +1 for the actual player Ultimate action slot (normally slot 8).
- READY reminder now reliably scans Primary + Backup for Overload / Energy Overload / Power Overload.
- Added /asoverload readytest to force the READY visual + sound for 6 seconds.
- Added clearer diagnostics showing the Ultimate action-slot index.
- EVENT_POWER_UPDATE is filtered to the player's Ultimate resource.

ĄLPHA ŞQUAD - OVERLOAD TRACKER
Version 1.9.0
Author: SeRuM1
Language: English

INSTALLATION
1. Replace the old "AlphaSquadOverloadTracker" folder with this one.
2. Put it in:
   Documents\Elder Scrolls Online\live\AddOns\
3. Start ESO or run /reloadui.

TRACKED ULTIMATES
- Overload
- Energy Overload
- Power Overload

The HUD automatically changes its title and icon to the detected base skill/morph.
It scans the Ultimate slot on BOTH Primary and Backup weapon bars.

HUD STATE
- OVERLOAD ON = green text, green icon border and green left status bar.
- OVERLOAD OFF = red text, red icon border and red left status bar.
- While locked and Overload is active, the right side shows current Ultimate only.
- While unlocked, it shows CLICK + DRAG.

MOVEMENT
- Lock position OFF: ANY mouse button + drag moves the HUD.
- Lock position ON: the HUD cannot be moved.
- Locking saves the exact position to SavedVariables.

EMERGENCY RESERVE SYSTEM
Default: ON.
- Emergency alert starts at 160 Ultimate.
- Auto-stop reserve threshold remains 130 Ultimate.

When Overload is active and Ultimate reaches 160 or lower:
1. The entire HUD begins a rapid red/white strobe.
2. The HUD pulses in size; the emergency background becomes fully opaque while text/icon readability stays independent of the normal background-opacity setting.
3. The icon, left/right edge bars, top/bottom lines, title and status rapidly alternate red/white.
4. The right-side text alternates between the current Ultimate value and TURN OFF!
5. A layered rapid alert-sound burst repeats while Overload stays active.

At 130 Ultimate or lower:
1. The visual strobe becomes even faster and stronger.
2. The sound burst repeats faster.
3. The addon checks the active Overload player effect.
4. If ESO reports canClickOff=true, it requests CancelBuff automatically.
5. The addon verifies that Overload really turned off.
6. If ESO refuses cancellation or does not expose the effect as click-off capable, the emergency continues and the player must press the Ultimate key manually.

ESO does not expose a per-addon volume multiplier. The addon therefore makes the alarm more attention-grabbing by layering several UI alert sounds in rapid bursts. Final loudness still follows the player's ESO UI/SFX audio settings.

IMPORTANT ESO API LIMITATION
ESO marks the functions that actually press/use an action-bar ability (OnSlotDown,
OnSlotUp and OnSlotDownAndUp) as PRIVATE. An addon cannot simulate an Ultimate
keypress from Lua. This addon therefore does not fake a macro or call private combat
functions. It uses the public CancelBuff API only when ESO explicitly exposes the
active Overload effect as click-off cancellable.

SETTINGS
Type /asoverload to open the built-in settings window.
The addon also appears directly in the native ESC > Settings list as:
Ąlpha Şquad

It is intentionally NOT registered under Settings > AddOns.

Settings include:
- Enable addon tracking
- Show tracker HUD
- Lock position
- Emergency reserve system ON/OFF
- Emergency alert start threshold (25-500, default 160)
- Auto-stop reserve threshold (25-500, default 130)
- Emergency alert sounds ON/OFF
- Overload ready reminder ON/OFF
- Ready reminder threshold (100-500, default 400)
- Ready reminder sound ON/OFF
- Tracker scale
- Background opacity (background only; text/icon stay fully visible)
- Disable tracker in PvP (default OFF)
- Reset position
- Unlock & move
- Chat command explanations

CHAT COMMANDS
/asoverload
  Open or close settings.

/asoverload toggle
  Toggle HUD visibility.

/asoverload show
  Show the HUD.

/asoverload hide
  Hide only the HUD; tracking remains enabled.

/asoverload enable
  Enable tracking and show the HUD.

/asoverload disable
  Disable tracking and hide the HUD.

/asoverload lock
  Save the current HUD position and lock movement.

/asoverload unlock
  Unlock movement. Any mouse button + drag moves the HUD.

/asoverload reserve on
/asoverload reserve off
  Enable or disable the emergency reserve system.

/asoverload warning 160
  Set the emergency alert start threshold. Allowed range: 25-500.

/asoverload threshold 130
  Set the auto-stop reserve threshold. Allowed range: 25-500.

/asoverload ready on
/asoverload ready off
  Enable or disable the Overload-ready reminder.

/asoverload ready 400
  Set the ready reminder threshold. Allowed range: 100-500.

/asoverload ready sound on
/asoverload ready sound off
  Enable or disable the gentle ready reminder sound.

/asoverload cancel
  Manually request click-off cancellation of the active Overload effect.

/asoverload status
  Print addon state, detected morph, ON/OFF state, Ultimate and reserve settings.

/asoverload inspect
  Print live Primary/Backup slot IDs, names, morphs, toggle flags, active effect,
  canClickOff status and Ultimate value.

/asoverload debug
  Toggle extra debug messages.

/asoverload reset
  Reset HUD position.

/asoverload help
  Print all commands.

TECHNICAL
- Known Power Overload ability ID: 30366.
- Known Energy Overload ability ID: 30381.
- Base Overload is also detected by slot/effect name and icon, so a hard-coded base ID is not required.
- Primary active-state signal: EVENT_EFFECT_CHANGED / active player buff.
- Secondary signal: IsSlotToggled on either weapon bar.
- Immediate UI feedback: EVENT_ACTION_SLOT_ABILITY_USED with a short API resync grace period.
- Ultimate reserve monitoring: EVENT_POWER_UPDATE + periodic resync.
- Ultimate power uses COMBAT_MECHANIC_FLAGS_ULTIMATE on current API versions.
- Saved variables are account-wide and namespaced by megaserver.

COMPATIBILITY
- ESO API 101050
- ESO API 101051

AI DISCLOSURE
Implementation was assisted by OpenAI ChatGPT.


V1.8 EMERGENCY ALERTS
- Emergency strobe begins at 160 Ultimate by default.
- 160 to 131: rapid red/white full-HUD strobe, size pulse, forced 100% opacity and repeating layered alarm bursts.
- 130 and below: faster strobe, stronger pulse, faster alarm repetition and automatic CancelBuff attempt when ESO permits it.
- The HUD alternates current Ultimate with TURN OFF! during the emergency.
- No LIMIT text is displayed.
- Alert start can be changed with /asoverload warning 160 or the in-game settings.


V1.9 OVERLOAD READY REMINDER
- Default: enabled at 400 Ultimate.
- Only activates while Overload is OFF and Overload / Energy Overload / Power Overload is actually slotted on Primary or Backup.
- The HUD changes to a gentle gold/cyan pulse and displays READY TO ACTIVATE.
- Current Ultimate remains visible while the HUD is locked.
- A soft two-tone reminder plays when crossing the threshold and repeats approximately every 12 seconds while the condition remains true.
- The reminder stops immediately when Overload is activated, Ultimate falls below the threshold, the skill is no longer slotted, or the feature is disabled.
- Settings: Overload ready reminder, Ready reminder starts at, Ready reminder sound.
- Commands: /asoverload ready on|off, /asoverload ready 400, /asoverload ready sound on|off.
