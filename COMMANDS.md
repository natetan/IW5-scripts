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
| `!killmode <chain\|virus\|aoe\|splash\|vamp\|off>` | 3 | Sets the issuing player's non-killstreak weapon effect for the current map. `chain` spreads final killing-hit damage to the nearest unvisited eligible player; `virus` lethally headshots targets within 1,000 units instead of copying the original damage; `aoe` repeats final damage against every eligible player in range; `splash` divides half of every hit's final damage among nearby eligible players; `vamp` converts hostile bullet damage into uncapped health; `off` restores normal weapon behavior. |

## Kill Modes

`!killmode` affects only the issuing player and resets to `off` when the next
map loads. It applies to primary and secondary weapons, their attachment
modes, launchers, carried equipment, melee, and Throwing Knives. Killstreak
weapons are excluded. Knife and Throwing Knife kills have no inherent area
effect while the mode is `off`.

The `chain`, `aoe`, and `splash` modes use a **382-unit** range. The sandbox
`virus` mode uses a **1,000-unit** hop radius and lethally damages each selected
target with headshot attribution instead of repeating the initiating weapon's
damage. For weapon types that can normally trigger it, the headshot bypasses
Final Stand through IW5's stock death logic. All modes ignore intervening
cover and preserve the weapon's attribution, killfeed icon, normal scoring,
friendly-fire rules, and target defenses. Synthetic damage cannot recursively
start another effect.

- `!killmode aoe` damages all eligible players around the original victim at
  once.
- `!killmode chain` selects the nearest unvisited player, waits **0.15
  seconds**, repeats the original final damage, and continues from each
  confirmed death. It stops when a target survives, no target remains in
  range, or it reaches **17 secondary hops**.
- `!killmode virus` follows the same nearest-target selection, delay, and hop
  limit, but each hop is a lethal headshot and searches within **1,000 units**
  for broad map testing. It does not inherit the initiating weapon's damage
  value.
- `!killmode splash` leaves the directly hit target's damage unchanged and
  divides a secondary pool equal to **50%** of that final hit damage among all
  other eligible players in range. Integer remainders are distributed one
  point at a time so the complete pool is preserved.
- `!killmode vamp` restores health equal to **100%** of the actual damage dealt
  by every non-killstreak bullet against a hostile player. Excess healing
  raises maximum health with no script-side cap and is consumed normally by
  incoming damage. Overkill damage, teammate damage, synthetic kill-mode
  damage, explosives, melee, and Throwing Knives do not grant health.
- `!killmode off` disables the effect immediately.

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
| Care Package | `care` or `package` | `airdrop_assault` |
| I.M.S. | `ims` | `ims` |
| Predator Missile | `pred` or `predator` | `predator_missile` |
| Sentry Gun | `sentry` | `airdrop_sentry_minigun` |
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
| Support UAV | `uav_s` | `uav_support` |
| Counter-UAV | `cuav` | `counter_uav` |
| Ballistic Vests / Team Armor Pulse | `vest` | `deployable_vest` |
| SAM Turret | `sam` | `sam_turret` |
| Recon Drone / Recon Pulse | `recon` | `remote_uav` |
| Airdrop Trap | `trap` | `airdrop_trap` |
| Advanced UAV | `auav` | `triple_uav` |
| Remote Sentry / Guardian Sentry | `sentry_s` | `remote_mg_turret` |
| EMP | `emp` | `emp` |
| Stealth Bomber | `stealth` | `stealth_airstrike` |
| Recon Juggernaut / Death's Dance | `dance` or `deaths_dance` | `airdrop_juggernaut_recon` |
| Escort Airdrop | `osprey_s` | `escort_airdrop` |

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
| `fun_mode_kill_mode_radius` | `382` | Range used by `chain`, `aoe`, and `splash` modes. |
| `fun_mode_kill_mode_virus_radius` | `1000` | Per-hop search radius used only by `virus` mode. |
| `fun_mode_kill_mode_splash_fraction` | `0.50` | Fraction of each direct hit's final damage divided among eligible secondary targets in `splash` mode. |
| `fun_mode_kill_mode_vamp_fraction` | `1.00` | Fraction of actual hostile bullet damage restored as uncapped health in `vamp` mode. |
| `fun_mode_kill_mode_chain_delay` | `0.15` | Seconds between chained kills. Values below `0.05` are clamped. |
| `fun_mode_kill_mode_chain_max_hops` | `17` | Maximum secondary kills attempted by one chain. |

Command registration, aliases, validation, and authorization are implemented
in [`gsc/admin_chat_commands.gsc`](./gsc/admin_chat_commands.gsc).
