# Overload behavior

Overload is an optional part of the **ULT Tracker** personal HUD. It follows Overload, Energy Overload and Power Overload, including a morph available through subclassing, using the actual slotted ability identity.

## Settings

Open **ULT Tracker → OVERLOAD SETTINGS**, or `/asoverload settings`.

- **Use Overload behavior** enables the specialized reserve and ready-reminder behavior. OFF retains the standard personal Ultimate tracker.
- **Disable specialized behavior in PvP** uses normal Ultimate tracking there while retaining the Overload options for PvE.
- **Reserve warnings**, enabled by default, highlights active Overload when Ultimate reaches **Warning starts**. Warning sounds can be disabled independently.
- Ready-reminder options control the reminder threshold and sound while Overload is off.

Overload and normal Ultimates share one transparent panel, position and scale. Both normal weapon slots remain visible horizontally or vertically, with a smooth green marker beside the actual active bar and a dimmed inactive slot. The old AUTO/FRONT/BACK/BOTH selectors are retired. ESO's native Ultimate button is never hidden or modified by this HUD.

Use your normal Ultimate binding to switch Overload off. The addon only reports its state and resource reserve; automatic stopping and clickable cancellation are removed. Placement previews do not play alerts.

## Migration and runtime

Existing supported Overload options migrate into the personal ULT settings. An applicable previously enabled Overload HUD can provide the shared panel's previous position and scale. Retired display-mode settings do not hide either normal weapon slot. Old SavedVariables are retained for migration. An existing warning OFF choice and its warning threshold survive the removal of the old cutoff setting. A native transformation/temporary hotbar temporarily replaces the weapon display and suppresses unrelated Overload alerts.

The implementation is `../ULTTracker/ULTOverload.lua`. It uses the personal Ultimate tracker's events, resource state, safety update and animation lifecycle. There is no separate Overload HUD or standalone recovery timer. Disabling ULT Tracker stops its specialized Overload work too; changing library sharing remains independent.

Use **MOVE HUD** or `/asmove` to move and resize the shared panel. Drag its body, use corners for proportional scale and edges to rearrange its contents. The toolbar offers fit and reset; transparent panels have no background opacity control. Dashboard styles affect settings while gameplay state colors retain their meaning.

## Commands

| Command | Action |
| --- | --- |
| `/asui` or `/alphasquad` | Main settings |
| `/asoverload` | Legacy alias for main settings |
| `/asoverload settings` | Overload behavior options |
| `/asoverload on` or `/asoverload off` | Enable or disable specialized behavior |
| `/asmove` | Arrange enabled HUD panels |

Personal Ultimate and Overload tracking do not require sharing libraries. See the shared **Libraries** page for optional group integrations.
