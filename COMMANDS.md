# IW5 Chat Commands

This document describes the in-game chat commands provided by this repository.
Commands are typed into ordinary game chat and begin with `!`. The available
commands depend on the issuing player's permission level.

## Permissions

| Level | Intended access | Current capabilities |
|---:|---|---|
| 0 | Public player | Command discovery, help, and permission lookup |
| 1 | Trusted helper | Reserved for future low-risk commands |
| 2 | Moderator or tester | Reserved for future testing commands |
| 3 | Owner or administrator | All commands, including killstreak grants |

The host of a non-dedicated private session automatically receives level 3.
On a dedicated server, GUIDs listed in `fun_mode_super_class_guids` also
receive level 3.
Command-only access can be configured outside Git in the server's local
`admin\server.cfg`:

```cfg
set fun_mode_chat_permission_1_guids ""
set fun_mode_chat_permission_2_guids ""
set fun_mode_chat_permission_3_guids "YOUR_GUID"
```

Separate multiple GUIDs with commas and no spaces. Never commit real player
GUIDs to this repository.

## General Commands

| Command | Minimum level | Description |
|---|---:|---|
| `!commands` | 0 | Lists the commands available at the issuing player's current permission level. Alias: `!cmds`. |
| `!help <command>` | 0 | Displays the command's usage and required permission level. |
| `!permission` | 0 | Displays the issuing player's current command permission. Alias: `!perm`. |
| `!random` | 3 | Immediately loads a random map from the complete configured mapvote pool while retaining the current Domination, Drop Zone, or Kill Confirmed recipe. Alias: `!randommap`. The current map is excluded when alternatives exist. Unsafe Drop Zone combinations use the same fallback rules as normal map voting. |

## Give Killstreak

```text
!give <killstreak> [player]
```

`!give` requires level 3. It grants a validated IW5 killstreak through the
target player's native extra-reward slot. The optional player defaults to the
issuer and may be `me`, an exact player name, or a unique beginning of a player
name. Aliases for the command itself are `!giveks` and `!givekillstreak`.

Examples:

```text
!give pred
!give swarm me
!give emp Aero
```

The repository's killstreak replacements still apply. For example, `harrier`
grants the Precision Airstrike slot that runs the Harrier replacement, while
`swarm` grants the Assault Juggernaut slot that runs Predator Swarm.

### Assault rewards

| Displayed reward | Preferred name or alias | Canonical name |
|---|---|---|
| UAV | `uav` | `uav` |
| Care Package | `airdrop_assault` | `airdrop_assault` |
| I.M.S. | `ims` | `ims` |
| Predator Missile | `pred` or `predator` | `predator_missile` |
| Sentry Gun | `airdrop_sentry_minigun` | `airdrop_sentry_minigun` |
| Precision Airstrike / Harrier | `harrier` | `precision_airstrike` |
| Attack Helicopter | `heli` | `helicopter` |
| Strafe Run / AA Strike | `strafe` or `aa` | `littlebird_flock` |
| AH-6 Overwatch | `ah6` | `littlebird_support` |
| Reaper | `reaper` | `remote_mortar` |
| Assault Drone / A-10 Support | `assaultdrone` or `a10` | `airdrop_remote_tank` |
| AC-130 | `ac130` | `ac130` |
| Pave Low | `pavelow` | `helicopter_flares` |
| Assault Juggernaut / Predator Swarm | `jugg` or `swarm` | `airdrop_juggernaut` |
| Osprey Gunner | `osprey` | `osprey_gunner` |

### Support rewards

| Displayed reward | Preferred name or alias | Canonical name |
|---|---|---|
| Support UAV | `uav_support` | `uav_support` |
| Counter-UAV | `cuav` | `counter_uav` |
| Ballistic Vests / Team Armor Pulse | `vest` | `deployable_vest` |
| SAM Turret | `sam_turret` | `sam_turret` |
| Recon Drone / Recon Pulse | `recon` | `remote_uav` |
| Airdrop Trap | `airdrop_trap` | `airdrop_trap` |
| Advanced UAV | `auav` | `triple_uav` |
| Remote Sentry / Guardian Sentry | `support_sentry` | `remote_mg_turret` |
| EMP | `emp` | `emp` |
| Stealth Bomber | `stealth_airstrike` | `stealth_airstrike` |
| Recon Juggernaut | `airdrop_juggernaut_recon` | `airdrop_juggernaut_recon` |
| Escort Airdrop | `escort_airdrop` | `escort_airdrop` |

### Special reward

| Displayed reward | Preferred name or alias | Canonical name |
|---|---|---|
| MOAB | `moab` | `nuke` |

Both the preferred name and canonical name are accepted. Names are
case-insensitive, but they cannot contain spaces.

## Configuration

| Dvar | Default | Purpose |
|---|---:|---|
| `fun_mode_chat_commands_enable` | `1` | Enables the command dispatcher. Set to `0` before map load to disable it. |
| `fun_mode_chat_permission_default` | `0` | Permission assigned to players not found in an allowlist. Values are clamped from 0 through 3. |
| `fun_mode_chat_permission_1_guids` | Empty | Comma-delimited level 1 allowlist. |
| `fun_mode_chat_permission_2_guids` | Empty | Comma-delimited level 2 allowlist. |
| `fun_mode_chat_permission_3_guids` | Empty | Comma-delimited level 3 allowlist. |

Command registration, aliases, validation, and authorization are implemented
in [`gsc/admin_chat_commands.gsc`](./gsc/admin_chat_commands.gsc).
