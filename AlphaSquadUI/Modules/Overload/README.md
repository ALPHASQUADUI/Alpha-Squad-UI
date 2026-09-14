# Overload behavior

Overload is an optional part of the **ULT Tracker** personal HUD. It follows Overload, Energy Overload and Power Overload, including a morph available through subclassing, using the actual slotted ability identity.

## Settings

Open **ULT Tracker → OVERLOAD SETTINGS**, or `/asoverload settings`.

- **Use Overload behavior** enables the specialized reserve and ready-reminder behavior. OFF retains the standard personal Ultimate tracker.
- **Disable specialized behavior in PvP** uses normal Ultimate tracking there while retaining the Overload options for PvE.
- **Reserve alerts and auto-stop**, enabled by default, controls reserve warnings and native cancellation together. Threshold and sound options refine that behavior.
- Ready-reminder options control the reminder threshold and sound while Overload is off.

Overload and normal Ultimates share one panel, position, scale and background opacity. In AUTO, FRONT or BACK mode, an applicable Overload morph can take priority even on the other weapon bar. **BOTH** retains both cards. All display modes preserve the actual ability icons and morphs.

Automatic cancellation calls ESO's native cancellation only when the active effect is marked removable. It does not simulate an Ultimate key press. If cancellation is unavailable, use your normal Ultimate key. Placement previews do not play alerts or cancel effects.

## Migration and runtime

Existing supported Overload options migrate into the personal ULT settings. An applicable previously enabled Overload HUD can provide the shared panel's previous position and scale. Existing ULT display modes, including BOTH, are preserved; new installations use AUTO. Old SavedVariables are retained for migration.

The implementation is `../ULTTracker/ULTOverload.lua`. It uses the personal Ultimate tracker's events, resource state, safety update and animation lifecycle. There is no separate Overload HUD or standalone recovery timer. Disabling ULT Tracker stops its specialized Overload work too; changing library sharing remains independent.

Use **MOVE HUD** or `/asmove` to move and resize the shared panel. Corners scale it proportionally, edges rearrange its contents, and the toolbar controls background opacity and reset. The three Dashboard interface styles apply to this same HUD.

## Commands

| Command | Action |
| --- | --- |
| `/asui` or `/alphasquad` | Main settings |
| `/asoverload` | Legacy alias for main settings |
| `/asoverload settings` | Overload behavior options |
| `/asoverload on` or `/asoverload off` | Enable or disable specialized behavior |
| `/asoverload cancel` | Request safe native cancellation of an active removable effect |
| `/asmove` | Arrange enabled HUD panels |

Personal Ultimate and Overload tracking do not require sharing libraries. See the shared **Libraries** page for optional group integrations.
