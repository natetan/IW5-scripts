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
| `!killmode <chain\|virus\|aoe\|splash\|vamp\|off>` | 3 | Sets the issuing player's non-killstreak weapon effect for the current map. `chain` spreads final killing-hit damage to the nearest unvisited eligible player; `virus` lethally headshots targets within 2,000 units instead of copying the original damage; `aoe` repeats final damage against every eligible player in range; `splash` divides half of every hit's final damage among nearby eligible players; `vamp` converts hostile bullet damage into uncapped health; `off` restores normal weapon behavior. |
| `!possess` | 3 | Toggles the caller-only Possession prototype for the current map. A hostile kill moves the caller into the victim through a short first-person camera transition and grants a fresh copy of the victim's class loadout while preserving the caller's earned streak queue. |
| `!reflect` | 3 | Toggles personal damage reflection for the current map. Hostile melee and direct SMAW/RPG impacts deal no damage to the caller and instead route a lethal hit of the same type back to that attacker with the caller credited for the kill. Authorized Fun Mode classes 13–15 receive reflection automatically. The directly struck player also ignores that impact's paired splash callback; friendly damage and ordinary nearby rocket splash are unchanged. |
| `!super` | 3 | Toggles the complete Fun Mode class 13–15 package for the caller during the current map. While enabled it grants every base and Pro perk, hidden Specialist bonuses, Impact, Marathon/unlimited sprint, movement composition, defensive resistance, reflection, and the other systems that use super-class eligibility. The overlay reapplies after each spawn. Disabling it immediately removes only perks introduced by the command, preserving perks already supplied by the selected class; selecting an authorized class 13–15 still provides its normal package. |
| `!impersonate <weapon\|off>` | 3 | Displays the caller's ordinary primary/secondary firearm kills as another stock weapon and additionally credits that weapon's persistent kills, headshots, and weapon XP without changing the equipped gun. Alias: `!imp`. The setting lasts for the current map. |

## Weapon Impersonation

`!impersonate` is a level-3 progression-testing command. For example,
`!impersonate m4` lets the caller continue using the complete equipped weapon
while qualifying bullet kills display the M4 killfeed icon and credit the M4's
weapon kills, headshots, and weapon XP. Use `!impersonate off` to restore normal
attribution.

The command does not change the current weapon, damage, ammunition,
attachments, handling, or loadout. It does not redirect shots, hits, accuracy,
attachment challenges, equipment, melee, explosives, attachment modes, or
killstreak kills. Weapon XP is credited at **100 XP per qualifying kill**, up
to the target weapon's normal maximum rank. The setting is player-specific and
resets when the map changes. Because IW5 continues tracking the weapon that
actually fired, that source weapon retains its normal stock statistics too.

### Accepted weapon aliases

Every value below is case-insensitive. Any alias in the right column may be
used as the command argument, such as `!impersonate m4a1` or
`!impersonate deagle`.

| Category | Progression weapon | Accepted aliases |
|---|---|---|
| Assault rifle | M4A1 | `m4`, `m4a1` |
| Assault rifle | M16A4 | `m16`, `m16a4` |
| Assault rifle | SCAR-L | `scar`, `scarl` |
| Assault rifle | CM901 | `cm901` |
| Assault rifle | Type 95 | `type95`, `type` |
| Assault rifle | G36C | `g36`, `g36c` |
| Assault rifle | ACR 6.8 | `acr`, `acr68` |
| Assault rifle | MK14 | `mk14` |
| Assault rifle | AK-47 | `ak`, `ak47` |
| Assault rifle | FAD | `fad` |
| Submachine gun | MP5 | `mp5` |
| Submachine gun | UMP45 | `ump`, `ump45` |
| Submachine gun | PP90M1 | `pp90`, `pp90m1` |
| Submachine gun | P90 | `p90` |
| Submachine gun | PM-9 | `pm9` |
| Submachine gun | MP7 | `mp7` |
| Light machine gun | L86 LSW | `l86`, `l86lsw` |
| Light machine gun | MG36 | `mg36` |
| Light machine gun | PKP Pecheneg | `pkp`, `pecheneg` |
| Light machine gun | MK46 | `mk46` |
| Light machine gun | M60E4 | `m60`, `m60e4` |
| Sniper rifle | Barrett .50cal | `barrett`, `barrett50` |
| Sniper rifle | L118A | `l118`, `l118a`, `l96` |
| Sniper rifle | Dragunov | `dragunov` |
| Sniper rifle | AS50 | `as50` |
| Sniper rifle | RSASS | `rsass` |
| Sniper rifle | MSR | `msr` |
| Shotgun | USAS-12 | `usas`, `usas12` |
| Shotgun | KSG 12 | `ksg`, `ksg12` |
| Shotgun | SPAS-12 | `spas`, `spas12` |
| Shotgun | AA-12 | `aa12` |
| Shotgun | Striker | `striker` |
| Shotgun | Model 1887 | `model`, `model1887`, `1887` |
| Machine pistol | FMG9 | `fmg`, `fmg9` |
| Machine pistol | MP9 | `mp9` |
| Machine pistol | Skorpion | `skorpion` |
| Machine pistol | G18 | `g18` |
| Handgun | USP .45 | `usp`, `usp45` |
| Handgun | P99 | `p99` |
| Handgun | MP412 | `mp412` |
| Handgun | .44 Magnum | `magnum`, `44magnum` |
| Handgun | Five Seven | `fiveseven`, `57` |
| Handgun | Desert Eagle | `deagle`, `deserteagle` |

Launchers, equipment, Riot Shield, custom weapons, and killstreak aliases are
not accepted because they do not follow this firearm progression proxy.

## Kill Modes

`!killmode` affects only the issuing player and resets to `off` when the next
map loads. It applies to primary and secondary weapons, their attachment
modes, launchers, carried equipment, melee, and Throwing Knives. Killstreak
weapons are excluded. Knife and Throwing Knife kills have no inherent area
effect while the mode is `off`.

The `chain`, `aoe`, and `splash` modes use a **382-unit** range. The sandbox
`virus` mode uses a **2,000-unit** hop radius and lethally damages each selected
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
- `!killmode virus` follows the same nearest-target selection and delay, but
  each hop is a lethal headshot and searches within **2,000 units** for broad
  map testing. It has no hop cap and continues until no unvisited eligible
  target remains in range. It does not inherit the initiating weapon's damage
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
!give <killstreak> [player] [quantity]
```

`!give` requires level 3. It grants a validated IW5 killstreak through the
target player's native extra-reward queue. The optional player defaults to the
issuer and may be `me`, an exact player name, or a unique beginning of a player
name. Quantity defaults to **1** and must be a positive whole number. For safety,
each player may hold at most **10** queued extra rewards; a request that exceeds
the remaining capacity is reduced to fit. When targeting yourself, quantity can
be supplied directly as the second argument; both `!give sentry 3` and
`!give sentry me 3` are valid. Aliases for the command itself are `!giveks` and
`!givekillstreak`.

Examples:

```text
!give pred
!give swarm me
!give emp Aero
!give sentry 3
!give uav_s Aero 5
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
| `fun_mode_kill_mode_virus_radius` | `2000` | Per-hop search radius used only by `virus` mode. |
| `fun_mode_kill_mode_splash_fraction` | `0.50` | Fraction of each direct hit's final damage divided among eligible secondary targets in `splash` mode. |
| `fun_mode_kill_mode_vamp_fraction` | `1.00` | Fraction of actual hostile bullet damage restored as uncapped health in `vamp` mode. |
| `fun_mode_kill_mode_chain_delay` | `0.15` | Seconds between chained kills. Values below `0.05` are clamped. |
| `fun_mode_kill_mode_chain_max_hops` | `17` | Maximum secondary kills attempted by `chain`; `virus` is uncapped. |

Command registration, aliases, validation, and authorization are implemented
in [`gsc/admin_chat_commands.gsc`](./gsc/admin_chat_commands.gsc).
