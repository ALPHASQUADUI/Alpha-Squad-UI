# Ąlpha Şquad UI

> **A lightweight, modular UI toolkit for The Elder Scrolls Online, built for endgame players and the Ąlpha Şquad community.**

**Created by SeRuM1** · ESO PC/EU · Endgame PvE · HM · Trifectas · Raid utilities

[Website](https://alphasquadeso.com/) · [Architecture](docs/ARCHITECTURE.md) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)

---

## About the project

**Ąlpha Şquad UI** is a modular addon suite for **The Elder Scrolls Online** designed around three priorities:

1. **Performance** — event-driven logic, minimal polling, no unnecessary permanent animations.
2. **Clarity** — compact, readable combat information without cluttering the default ESO interface.
3. **Modularity** — one Ąlpha Şquad settings suite capable of hosting multiple independent modules over time.

The project starts with the **Overload Tracker** module and is intentionally structured so future tools can be added without turning the addon into a heavy monolithic UI replacement.

The long-term goal is a focused endgame toolkit for players who want useful combat information, raid utilities and encounter helpers while keeping ESO responsive.

---

## Current release

### Overload Tracker — v2.5.0

The first production module tracks every Sorcerer Overload variant:

- **Overload**
- **Energy Overload**
- **Power Overload**

It also supports **subclassing**. The module does not assume the player is a Sorcerer: it activates only when a supported Overload skill is actually equipped on the player's Primary or Backup Ultimate slot.

### Main HUD states

| State | Behaviour |
| --- | --- |
| Overload OFF | Red status treatment with current Ultimate counter |
| Overload ON | Green status treatment with current Ultimate counter |
| Ready reminder | Gentle gold/cyan reminder when enough Ultimate is available to reactivate Overload |
| Reserve warning | Strong red/white emergency warning when active Overload approaches the configured reserve threshold |
| No Overload slotted | Module becomes dormant and the HUD disappears automatically |
| Full-screen ESO UI open | HUD hides automatically and returns when gameplay HUD is restored |
| PvP suppression enabled | HUD, sounds and reminders remain disabled in PvP contexts |

---

## Overload Tracker features

### Accurate Overload detection

- Detects **Overload, Energy Overload and Power Overload**.
- Scans both **Primary** and **Backup** Ultimate slots.
- Tracks the actual active player effect rather than relying on obsolete Overload hotbar behaviour.
- Uses slot toggle state as an additional signal.
- Reacts immediately to ability-use events, then resynchronizes with the ESO API.
- Displays the detected morph name and corresponding ability icon.
- Compatible with subclassed builds because detection is based on equipped abilities.

### Ultimate counter

A permanent `ULT xxx` counter is displayed during the normal HUD state whether Overload is ON or OFF.

The counter is intentionally hidden during dedicated alert states so warning information remains visually dominant.

### Ready reminder

Default threshold: **400 Ultimate**.

When a supported Overload morph is equipped but currently OFF and the player's Ultimate reaches the configured value:

- the HUD enters a gentle ready state;
- `READY TO ACTIVATE` is displayed;
- a subtle visual pulse is shown;
- an optional reminder sound is played;
- the reminder repeats periodically until Overload is activated or the condition ends.

The feature can be disabled independently.

### Emergency reserve system

Default warning threshold: **160 Ultimate**.

Default auto-stop reserve threshold: **130 Ultimate**.

When Overload is active and reserve falls to the warning threshold:

- the full HUD enters a high-visibility red/white alert state;
- borders, status elements and icon treatment flash;
- the panel pulses for immediate visibility;
- `TURN OFF!` is displayed;
- optional layered warning sounds repeat while the condition remains active.

At the auto-stop threshold, the addon attempts to cancel Overload only when the ESO API exposes the active effect as publicly click-off cancellable.

> ESO does **not** allow normal addons to simulate protected action-bar key presses. Ąlpha Şquad UI does not call private combat functions or pretend to provide an impossible combat macro.

### Context-aware dormancy

The Overload module automatically becomes dormant when neither weapon bar contains a supported Overload Ultimate.

Dormant mode means:

- no combat HUD;
- no Ready Reminder;
- no reserve alarm;
- no alert sound;
- no fast animation loop;
- only a low-frequency safety check remains.

This is especially useful for subclassing and characters/builds that do not use Overload.

### Automatic menu hiding

The combat HUD automatically hides while ESO leaves its normal HUD scenes for full-screen interfaces such as:

- Inventory
- Champion Points
- Settings
- Crown Store
- and similar native menu scenes

It reappears automatically when gameplay resumes.

### Optional PvP suppression

`Disable tracker in PvP` is **OFF by default**.

Players who enable it can automatically suppress the module in PvP contexts such as Cyrodiil / Imperial City and Battlegrounds.

When suppressed, the module produces no HUD, sound, Ready Reminder or reserve warning.

### Movable HUD

- Any mouse button can drag the HUD while movement is unlocked.
- Locking the HUD saves the exact position.
- Locked position persists through `/reloadui`, zone changes and game restarts.
- Scale is configurable.
- Background opacity is configurable independently from text and icon visibility.

---

## Performance philosophy

Performance is a core design requirement for Ąlpha Şquad UI.

### Event-first architecture

Gameplay state changes are handled primarily through ESO events rather than high-frequency polling.

Examples include:

- effect changes;
- Ultimate power updates;
- action-slot changes;
- hotbar changes;
- ability use;
- scene / UI state changes.

### Lightweight safety synchronization

A slow fallback synchronization exists only as a safety net:

- approximately **1 second** while the module is relevant;
- effectively around **3 seconds** while no Overload is equipped.

This replaces the much faster fallback loops used in early development builds.

### Conditional animation loops

Fast updates exist only while an alert animation is actually visible.

When no emergency or Ready Reminder is active, those animation callbacks are removed instead of running permanently in the background.

### No redundant UI work

The project aims to avoid unnecessary text, color, texture, alpha and anchor updates when the displayed state has not changed.

Future modules are expected to follow the same rules.

---

## Modular settings suite

Ąlpha Şquad UI uses a single native settings entry:

```text
ESC → Settings → Ąlpha Şquad
```

It is intentionally designed as a suite rather than one settings entry per future addon feature.

The current internal navigation contains:

```text
Ąlpha Şquad
├── Modules
│   └── Overload
└── Community
    └── Website & About
```

Future modules can be added to the same navigation shell.

The settings UI itself is static/event-driven and does not require a permanent animation loop.

---

## Overload settings

The module currently provides settings for:

### General

- Enable / disable tracking
- Show / hide tracker HUD
- Lock / unlock HUD position
- Disable tracker in PvP

### Appearance

- HUD scale
- Background-only opacity
- Reset saved HUD position
- Unlock & move helper

### Emergency reserve

- Enable / disable reserve system
- Emergency alert sound
- Warning threshold
- Auto-stop reserve threshold

### Ready reminder

- Enable / disable Ready Reminder
- Ready Reminder threshold
- Ready Reminder sound

### Community

- Ąlpha Şquad website information
- Clickable website access from settings

No community advertisement is shown over the combat HUD.

---

## Chat commands

All commands use:

```text
/asoverload
```

| Command | Purpose |
| --- | --- |
| `/asoverload` | Open / close settings |
| `/asoverload toggle` | Toggle HUD visibility |
| `/asoverload show` | Show HUD |
| `/asoverload hide` | Hide HUD while keeping tracking enabled |
| `/asoverload enable` | Enable tracking and show HUD |
| `/asoverload disable` | Disable tracking and hide HUD |
| `/asoverload lock` | Save current position and lock movement |
| `/asoverload unlock` | Unlock HUD movement |
| `/asoverload reserve on` | Enable reserve protection |
| `/asoverload reserve off` | Disable reserve protection |
| `/asoverload warning 160` | Set emergency alert threshold |
| `/asoverload threshold 130` | Set auto-stop reserve threshold |
| `/asoverload ready on` | Enable Ready Reminder |
| `/asoverload ready off` | Disable Ready Reminder |
| `/asoverload ready 400` | Set Ready Reminder threshold |
| `/asoverload ready sound on` | Enable Ready Reminder sound |
| `/asoverload ready sound off` | Disable Ready Reminder sound |
| `/asoverload cancel` | Request public click-off cancellation of active Overload |
| `/asoverload status` | Print current module state on demand |
| `/asoverload inspect` | Print detailed slot/effect diagnostic information |
| `/asoverload debug` | Toggle debug messages |
| `/asoverload reset` | Reset HUD position |
| `/asoverload website` | Open the Ąlpha Şquad website confirmation |
| `/asoverload help` | Display command help |

Automatic gameplay chat spam is intentionally avoided. Diagnostic text is printed only when the player explicitly requests it or enables debug mode.

---

## Installation

### Manual installation

1. Download or clone this repository.
2. Copy the folder:

```text
AlphaSquadOverloadTracker
```

into:

```text
Documents/Elder Scrolls Online/live/AddOns/
```

3. The final path should look like:

```text
Documents/Elder Scrolls Online/live/AddOns/AlphaSquadOverloadTracker/
```

4. Launch ESO or run:

```text
/reloadui
```

### Packaged release

A packaged addon archive is tracked in:

```text
releases/AlphaSquad_Overload_Tracker_v2.5.0.zip
```

---

## Repository layout

```text
Alpha-Squad-UI/
├── AlphaSquadOverloadTracker/
│   ├── AlphaSquadOverloadTracker.lua
│   ├── AlphaSquadOverloadTracker.txt
│   └── README.txt
│
├── docs/
│   └── ARCHITECTURE.md
│
├── releases/
│   └── AlphaSquad_Overload_Tracker_v2.5.0.zip
│
├── .github/
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
│
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

The production Overload addon intentionally keeps its existing folder and SavedVariables namespace for backward compatibility.

---

## Architecture direction

The current production module remains self-contained while the suite architecture stabilizes.

The intended long-term structure is:

```text
AlphaSquadUI/
├── AlphaSquadUI.txt
├── Core/
│   ├── Core.lua
│   ├── Events.lua
│   ├── Settings.lua
│   ├── Theme.lua
│   └── Utils.lua
├── Modules/
│   ├── Overload/
│   ├── RaidTools/
│   ├── TrialAssistant/
│   ├── BuffTracker/
│   ├── TankTools/
│   ├── HealerTools/
│   └── DPSUtilities/
└── Media/
```

Migration will be incremental so existing SavedVariables and working releases are not broken unnecessarily.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for architectural rules.

---

## Planned modules

Possible future modules include:

- **Raid Tools** — roster / group combat utilities
- **Trial Assistant** — encounter-specific reminders and raid-lead tools
- **Buff Tracker** — focused endgame buff/debuff monitoring
- **Tank Tools** — taunt, mitigation and support tracking
- **Healer Tools** — group-support visibility and buff utilities
- **DPS Utilities** — compact combat optimization helpers
- **Group Utilities** — reusable group and role information

Every module should remain independently suppressible and should avoid doing work when it is not relevant.

---

## Development principles

New code should follow these rules:

1. Prefer ESO events over frequent polling.
2. Keep modules isolated wherever practical.
3. Stop animation callbacks immediately when their UI is hidden.
4. Avoid automatic gameplay chat spam.
5. Keep combat HUD elements compact and readable.
6. Keep community / website promotion inside settings, not the combat HUD.
7. Preserve SavedVariables compatibility whenever practical.
8. Test both Primary and Backup action bars for slotted abilities.
9. Support subclassing based on equipped skills rather than base-class assumptions.
10. Document user-facing changes in `CHANGELOG.md`.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the contributor workflow.

---

## ESO API notes

Current manifest compatibility:

```text
101050
101051
```

The module uses public ESO addon APIs and deliberately avoids private/protected combat functions.

Known tracked IDs include:

- Power Overload: `30366`
- Energy Overload: `30381`

Base Overload is also detected through slot/effect metadata so the module does not depend exclusively on one hard-coded ID.

---

## Community

**Ąlpha Şquad** is an Elder Scrolls Online endgame PvE community focused on:

- Hard Modes
- Trifectas
- Raid progression
- Endgame builds
- Guides
- Player improvement
- Roster development

### Website

**https://alphasquadeso.com/**

The website link is also available inside the addon settings interface.

---

## Author

**SeRuM1**

Project: **Ąlpha Şquad UI**

---

## AI disclosure

Parts of the implementation and project documentation were developed with assistance from **OpenAI ChatGPT** under the direction of the project author.

---

## Disclaimer

This is an unofficial community addon project for **The Elder Scrolls Online**.

The Elder Scrolls Online, ESO, ZeniMax and related names/assets are property of their respective owners. This project is not affiliated with or endorsed by ZeniMax Online Studios or Bethesda Softworks.

---

## Project status

The repository is currently maintained as a **private development project** while Ąlpha Şquad UI grows beyond its first production module.
