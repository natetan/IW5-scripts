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
├── admin/                       Custom game mode recipes
├── gsc/                         Gameplay and bot modifications
│   └── bots/                    Modified Bot Warfare scripts
├── players/                     Player configuration files (.cfg)
├── BOTNAMES.md                  Bot name generator documentation
├── generate_iw5_bot_names.ps1
├── iw5_targets.ps1              Shared client/server target configuration
├── install_bot_scripts.ps1
├── install_game_scripts.ps1
└── README.md
```
## Installation

### Bot Warfare Scripts

Updates the modified Bot Warfare GSC files inside `z_svr_bots.iwd` for both
the local client and dedicated server.

Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\install_bot_scripts.ps1"
```

By default this updates both:

```text
gsc/bots/
```

```text
%LOCALAPPDATA%\Plutonium\storage\iw5\z_svr_bots.iwd
C:\gameserver\IW5\z_svr_bots.iwd
```

The dedicated-server archive is seeded from the client archive when necessary.
A backup is created beside each archive the first time it is updated.

Use `-ClientOnly`, `-ServerOnly`, or `-ServerRoot` when needed:

```powershell
.\install_bot_scripts.ps1 -ServerOnly
.\install_bot_scripts.ps1 -ServerOnly -ServerRoot "D:\servers\IW5"
```

---

### Game Scripts

Installs all custom gameplay scripts and player configuration files to both
the local client and dedicated server by default.

Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\install_game_scripts.ps1"
```

This automatically copies the same source overlay to each target:

```text
gsc/     -> <target>\scripts\
players/ -> <target>\players\
admin/   -> <target>\admin\
maps/    -> <target>\maps\
```

The targets are `%LOCALAPPDATA%\Plutonium\storage\iw5` and
`C:\gameserver\IW5`. Existing stock server files are preserved; matching
overlay files are replaced. The same `-ClientOnly`, `-ServerOnly`, and
`-ServerRoot` options shown above are supported.

For the dedicated target, the installer also merges `players\normal.cfg` into
the existing `admin\server.cfg` immediately before `sv_maprotation`. The block
is surrounded by managed markers, so subsequent installs replace that block
instead of duplicating it. A one-time
`server.cfg.pre-custom-scripts.backup` is retained beside the original config.

This includes:

- Custom gameplay scripts (`fun_mode.gsc`, `mapvote.gsc`, etc.)
- Additional script folders (such as `bots/waypoints/`)
- Player configuration files (`normal.cfg`, `hard.cfg`, etc.)

### Dedicated Server Layout

Keep the Steam/Plutonium server installation outside this repository. The
default expected path is:

```text
C:\gameserver\IW5\
├── !start_mp_server.bat       Local launcher; keep its key out of Git
├── admin\                     Stock configs plus this repo's custom DSRs
├── main\                      Steam game data
├── maps\                      Deployed rawfile overrides
├── players\                   Deployed player configs
├── scripts\                   Deployed GSC scripts
└── z_svr_bots.iwd             Deployed Bot Warfare archive
```

The repository is the editable source overlay; `C:\gameserver\IW5` and the
Plutonium storage folder are deployment targets. Do not copy the Steam game
binaries into Git. Keep the server key and RCON password only in ignored local
files or environment variables.

### Starting a Dedicated Server

When the client and dedicated server run on the same computer, use separate
copies of the base game files. A working layout is:

```text
C:\gameserver\IW5-client\    Client game directory selected in the launcher
C:\gameserver\IW5\           Dedicated server game directory
```

Both instances still load shared custom content from:

```text
%LOCALAPPDATA%\Plutonium\storage\iw5\
```

The installation scripts deploy to that shared client storage and to the
dedicated server directory. They do not need to copy custom files into
`IW5-client`.

Configure the local server launcher with the dedicated directory and a port
that differs from the client. For example, in `!start_mp_server.bat`:

```bat
set gamepath=%~dp0
set port=27017
```

Keep the server key in this local launcher and never commit it. Leave the mod
empty for the normal server, or use `set mod="mods/lb_server"` after installing
EditClassMenu as described below.

Start everything in this order:

1. Close all Plutonium client and server processes.
2. Launch the IW5 client using `C:\gameserver\IW5-client` and wait at the menu.
3. Run `C:\gameserver\IW5\!start_mp_server.bat`.
4. Wait for `Heartbeat successful` and game initialization in the server console.
5. Open the in-game client console and run `connect 127.0.0.1:27017`.

Enter server commands such as `status` or `map_rotate` in the dedicated server
console. Enter `connect` in the in-game client console. The normal configuration
uses an inline `sv_maprotation`; Plutonium IW5 does not use a `.dspl` playlist
for this rotation.

For internet players, allow and forward UDP port `27017` to the server
computer's LAN address. Port forwarding is not required for the local
`127.0.0.1` connection. A server may also be absent from its own browser due to
router NAT loopback behavior even when outside players can see it.

The public server name is managed with the Plutonium server key configuration,
not `normal.cfg`. Restart the dedicated server after changing it. If the browser
still shows an older name, allow a few minutes for the listing to refresh.

### Restricting Fun Mode Super Classes

In private matches, custom classes 13–15 always receive their automatic Fun
Mode bonuses. Dedicated servers instead use a GUID allowlist. The allowlist is
empty by default, so nobody receives those bonuses on a dedicated server until
the server owner is configured. While connected, run `status` in the dedicated
server console and copy the GUID shown for your player. Add this outside the
installer-managed block in the server's local `admin\server.cfg`:

```cfg
set fun_mode_super_class_guids "YOUR_GUID"
```

Restart the server afterward. For multiple trusted players, separate GUIDs
with commas and no spaces. Keep the actual GUID in the local server config
rather than committing it to the repository. On a dedicated server, unlisted
players may select classes 13–15, but they receive only their ordinary class
loadout.

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
storage\iw5\mods\lb_server\
├── mod.ff
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

To use EditClassMenu on the dedicated server, copy the entire `lb_server`
directory to:

```text
C:\gameserver\IW5\mods\lb_server\
```

Then set `mod="mods/lb_server"` in the server launcher. On the client, run
`loadmod lb_server` before connecting. Public players also need the mod; hosting
it for automatic download requires a separate FastDL setup.

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
