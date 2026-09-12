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

The gameplay implementation intentionally remains consolidated in `Overload.lua`
to minimize regression risk. Any future file split should preserve gameplay
behavior and SavedVariables exactly.
