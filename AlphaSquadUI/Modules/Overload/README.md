# Overload Module

Current gameplay module for Ąlpha Şquad UI.

Tracks:

- Overload
- Energy Overload
- Power Overload
- subclassed builds using an Overload morph

Features include the movable HUD, Ultimate counter, emergency reserve alerts,
ready reminder, PvP suppression option, menu auto-hide and dormant behavior
when no Overload morph is slotted.

Tracking is event-first. Its 1-second recovery sync exists only while the HUD is
enabled, visible, unobscured, not PvP-suppressed and not dormant; hidden and
dormant states keep no polling update alive.

The gameplay implementation intentionally remains consolidated in `Overload.lua`
to minimize regression risk. Any future file split should preserve gameplay
behavior and SavedVariables exactly.

Open **ESC > Settings > Ąlpha Şquad UI > Overload** or `/asoverload`.
Personal Overload tracking does not require LibGroupBroadcast, LibGroupCombatStats
or the build-sharing companion. The shared **Libraries** page explains
optional integrations used by other modules.

## Dashboard and sharing

Enable or disable this module from Dashboard. Disabled tracking removes its own gameplay subscriptions and recovery/animation timers. Libraries remains available and its sharing settings are independent. Cross-sync keeps HUD positions and module settings across characters by default; switch it off for character-specific layouts. Loading transitions pause tracking until activation.
