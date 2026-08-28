# MW3 Plutonium - Enhancements

A collection of scripts, DSRs, and tools that improve the MW3 Plutonium experience. This can be done on your own hosted server or private matches.

The goal of this project is to make Bot Warfare matches feel as close as possible to a real public lobby by improving gameplay, bot behavior, map rotation, and overall immersion.

## Features

### 🤖 Better Bots
- Realistic randomly generated bot names
- Improved bot behavior tweaks
- Smarter anti-air weapon selection
- Community waypoint support for additional maps

### 🎮 Custom Game Modes
Custom DSR files for:

- Hardcore Domination (HUD enabled)
- Hardcore Drop Zone (HUD enabled)

Designed to play like traditional MW3 Hardcore while keeping the HUD and removing unnecessary delays.

### 🗺️ Improved Map Rotation
- Map voting support
- Modernized map pool
- Custom MW2 / CoD4 remastered maps
- Support for Domination and Drop Zone rotation

### ⚙️ Fun Mode
Optional gameplay enhancements for custom classes, including:

- Permanent Specialist perks on selected classes
- Additional hidden Specialist bonuses
- Experimental gameplay features

### 🛠️ In-Match Class Editing

[LastDemon99's IW5 EditClassMenu](https://github.com/LastDemon99/IW5-Mods/tree/main/EditClassMenu) adds a full class editor to the in-game menu. It can edit weapons, compatible attachments, proficiencies, perks, equipment, streaks, camos, and reticles without returning to the main multiplayer menus.

This is especially useful while prestiging for fun: attachments and camos can be selected without waiting for their normal progression unlocks, while weapon levels can still be earned naturally.

### 🏷️ Bot Name Generator
PowerShell script that automatically:

- Generates realistic bot names
- Creates a local `bots.txt`
- Updates `z_svr_bots.iwd`

See [BOTNAMES.md](./BOTNAMES.md) for details.

## Repository Structure

```text
.
├── dsr/                         Custom game mode recipes
├── gsc/                         Gameplay and bot modifications
│   └── bots/                    Modified Bot Warfare scripts
├── players/                     Player configuration files (.cfg)
├── BOTNAMES.md                  Bot name generator documentation
├── generate_iw5_bot_names.ps1
├── install_bot_scripts.ps1
├── install_game_scripts.ps1
└── README.md
```
## Installation

### Bot Warfare Scripts

Updates the modified Bot Warfare GSC files inside `z_svr_bots.iwd`.

Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\install_bot_scripts.ps1"
```

This automatically copies all modified `.gsc` files from:

```text
gsc/bots/
```

into:

```text
%LOCALAPPDATA%\Plutonium\storage\iw5\z_svr_bots.iwd
└── maps/
    └── mp/
        └── bots/
```

A backup of the original `z_svr_bots.iwd` is created automatically the first time the script is run.

---

### Game Scripts

Installs all custom gameplay scripts and player configuration files.

Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\install_game_scripts.ps1"
```

This automatically copies:

```text
gsc/     -> %LOCALAPPDATA%\Plutonium\storage\iw5\scripts\
players/ -> %LOCALAPPDATA%\Plutonium\storage\iw5\players\
admin/   -> %LOCALAPPDATA%\Plutonium\storage\iw5\admin\
```

This includes:

- Custom gameplay scripts (`fun_mode.gsc`, `mapvotes.gsc`, etc.)
- Additional script folders (such as `bots/waypoints/`)
- Player configuration files (`normal.cfg`, `hard.cfg`, etc.)

---

### Manual Bot Warfare Installation

Bot behavior changes belong inside `z_svr_bots.iwd`.

Open the archive with **WinRAR** and replace the corresponding `.gsc` files under:

```text
z_svr_bots.iwd
└── maps/
    └── mp/
        └── bots/
```

Do **not** extract and recompress the archive—edit it directly with WinRAR.

---

### EditClassMenu Mod

Download EditClassMenu from the official project:

- [Source and documentation](https://github.com/LastDemon99/IW5-Mods/tree/main/EditClassMenu)
- [Packaged EditClassMenu v1.0 download](https://github.com/LastDemon99/IW5-Mods/releases/download/edit-class-v1.0/EditClassMenu.rar)

Extract the downloaded archive into:

```text
%LOCALAPPDATA%\Plutonium\storage\iw5\
```

The resulting layout should include:

```text
storage\iw5\
├── mods\
│   └── lb_server\
└── z_editClassMenu.iwd
```

Launch Plutonium IW5 and enter this in the console:

```text
loadmod lb_server
```

After the mod reloads the game, start a normal private match. The in-game menu will contain an **EDIT CLASS** option. Changes are written to the saved custom classes, allowing them to persist outside the current life or match.

Back up the following directory before initially testing the mod because it modifies persistent class data:

```text
%LOCALAPPDATA%\Plutonium\storage\iw5\players\
```

EditClassMenu and Survival Reimagined are separate `fs_game` mods. Use `loadmod lb_server` for regular multiplayer with the class editor and `loadmod survival` when playing Survival Reimagined; they are not loaded simultaneously.

## Game Load

For a regular game without EditClassMenu, hit the \` (~) key and, depending on the config you want, type:

```
exec normal.cfg
```

When using EditClassMenu, load the mod first. After the game reloads, execute the desired configuration:

```text
loadmod lb_server
exec normal.cfg
```

## Philosophy

Rather than turning MW3 into a heavily modded experience, this project focuses on preserving the original feel of Modern Warfare 3 while making offline play feel believable.

Examples include:

- Bots that use more realistic gamertags
- Bots making smarter gameplay decisions
- Better map rotations
- Authentic Hardcore settings
- Cleaner private match quality-of-life improvements

Most changes are designed so that, if you didn't know they were modded, they would simply feel like MW3.
