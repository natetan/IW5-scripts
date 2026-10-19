# IW5 Killstreak Modifications

This document tracks killstreak changes made by this repository. Rewards are
separated by strike package and ordered by their stock kill or point cost.
Rewards absent from these tables retain their stock behavior.

## Assault Strike Package

| Killstreak | Mod | Notes |
|---|---|---|
| UAV — 3 kills | Stock | Radar behavior remains stock. See [Fast Activation](#fast-activation). |
| Predator Missile — 5 kills | Stock | Player-controlled missile behavior remains stock. |
| Precision Airstrike — 6 kills | Harrier Strike replacement | Uses IW5's dormant Harrier path while retaining the Precision Airstrike slot, icon, cost, and location-selection controls. Both the opening airstrike and Harrier cannon kills extend the owner's same-life Assault streak. The Harrier can engage hostile aircraft and is destroyed by EMP effects. |
| Attack Helicopter — 7 kills | Ground-targeting rockets | Preserves the cannon and anti-Harrier behavior. With no hostile Harrier, it can fire at its current player target when line of sight, firing angle, and minimum range are valid. Ground rockets have unlimited ammunition and a nine-second cooldown. See [Fast Activation](#fast-activation). |
| Strafe Run — 9 kills | AA Strike replacement | Harrier flybys attack hostile aircraft, UAVs, and AC-130s, temporarily deny enemy airspace, and launch two spaced guided attacks against ground targets. See [Fast Activation](#fast-activation). |
| AH-6 Overwatch — 9 kills | Rocket support | Preserves stock flight, dual miniguns, health, duration, and counters. Adds one alternating FFAR against its current minigun target every eight seconds. See [Fast Activation](#fast-activation). |
| Reaper — 9 kills | Bradley Artillery replacement on supported maps | Replaces the player-controlled Reaper with IW5's dormant Mobile Mortar Bradley. The player selects one of three entrance lanes, then the vehicle autonomously launches a **three-missile salvo every five seconds** for **30 seconds**. Bradley missiles have **2x damage**, 0.35-second spacing, and a modest 160-unit impact spread around the selected enemy area. Because the referenced Bradley model is absent from the shipped MP assets, the entity assembles the shipped Assault Drone/UGV chassis and turret instead of displaying a red missing-model proxy. The selector and world effects use shipped assets, activation explicitly restores the player's weapon, and a Carbon-only guard suppresses invalid stock destructible-part transitions while the vehicle is active. Only one vehicle may be active at once. Authored lanes exist for Lockdown, Bootleg, Mission, Carbon, Dome, Hardhat, Interchange, Fallen, Sanctuary, Resistance, Arkaden, Outpost, and Seatown. Maps without authored entrances—including Scrapyard, Rust, and Shipment variants—skip all Bradley initialization and assets, then use the tuned player-controlled Reaper: **1.5x missile damage** and a **2.25-second** firing interval instead of the stock three seconds. Set `fun_mode_bradley_artillery_enable 0` before map load to use the tuned Reaper everywhere. |
| Assault Drone — 10 kills | A-10 support replacement | Removes the care-package delivery and player-controlled drone. Calls two autonomous attack passes that use shipped Harrier presentation assets, paired FFARs, and the stock A-10 cannon sweep. |
| AC-130 — 12 kills | Faster cannon reloads | Reloads are **2.5 seconds** for the 105 mm, **1.5 seconds** for the 40 mm, and **0.5 seconds** for the 25 mm. Damage, duration, flares, and vulnerability remain stock. |
| Pave Low — 12 kills | Rocket salvos | Preserves stock flight, health, flares, and dual miniguns. Adds a three-rocket ground-suppression salvo against visible enemy clusters every ten seconds. See [Fast Activation](#fast-activation). |
| Assault Juggernaut — 15 kills | Custom loadout | Replaces the stock loadout with a silenced extended-mag KSG 12, Desert Eagle with Tactical Knife, Semtex, and Concussion Grenades. Weapon balance is detailed in [`WEAPONS.md`](./WEAPONS.md). |
| Osprey Gunner — 17 kills | Safe aircraft initialization | Restores missing missile-attractor defaults on affected maps. Its balance and player-controlled gunner behavior remain stock. |

## Support Strike Package

| Killstreak | Mod | Notes |
|---|---|---|
| UAV — 4 points | Stock | Radar behavior remains stock. See [Fast Activation](#fast-activation). |
| Ballistic Vests — 5 points | Team armor pulse | Replaces the deployable vest bag with an immediate pulse centered on the user. The user and every living teammate within **1,200 units** receive armor through IW5's native Ballistic Vest callback, preserving its normal health, HUD, and damage behavior. Each recipient sees a centered `Received Ballistic Vest` confirmation, and each armored teammate awards the stock **50 Support XP** to the user. See [Fast Activation](#fast-activation). |
| Counter-UAV — 5 points | Stock | Duration and radar-jamming behavior remain stock. See [Fast Activation](#fast-activation). |
| Recon Drone — 10 points | Recon Pulse replacement | Replaces manual flight with a pulse centered on the user. Enemies within **2,400 units** receive the genuine Recon Drone tag for ten seconds, including tagged-kill assists, without flash or damage. Maps with malformed remote-UAV height metadata are also guarded against runtime loops. See [Fast Activation](#fast-activation). |
| Advanced UAV — 12 points | Longer duration and Assassin reveal | Extends the actual reward from 30 to **40 seconds**. Assassin users appear globally as ordinary red dots but retain protection from directional arrows. Naturally stacked UAVs remain stock. See [Fast Activation](#fast-activation). |
| EMP — 18 points | Harrier destruction and countdown feedback | System chat reports the effective EMP duration every ten seconds, then every second from five through one. It also clears custom Harriers and preserves normal destruction credit and feedback. See [Fast Activation](#fast-activation). |
| Recon Juggernaut — 18 points | Equipment and sidearm tuning | Retains the Riot Shield and moving radar, and uses a Five Seven with Tactical Knife and Extended Mags, Semtex, and Concussion Grenades. Weapon details are tracked in [`WEAPONS.md`](./WEAPONS.md). |
| Escort Airdrop — 18 points | Support Osprey tuning | Expands its defensive radius by **1.25x**, removes trapped crates, reduces UAV and Counter-UAV odds, and shifts drops toward useful mid-tier support rewards. Missing missile-attractor defaults are restored before aircraft creation. |

## Special Streak

| Killstreak | Mod | Notes |
|---|---|---|
| MOAB — 25 weapon kills | Presentation, EMP integration, countdown feedback, and repeat awards | Removes the stock vision, slow-motion, and miscellaneous presentation effects while retaining the EMP. Its EMP clears custom Harriers and shares the same effective-duration countdown logic as Support EMP, so overlapping effects announce only the longer timer. Additional MOABs are awarded at the same per-cycle cost. Normal milestones are 25, 50, and 75; Hardline milestones are 24, 48, and 72. |

## Fast Activation

Fast activation is a quality-of-life change, not a killstreak balance mod. It
replaces the slow stock radio-device animation with a quick marker-weapon draw
for these rewards:

| Strike package | Killstreaks |
|---|---|
| Assault | UAV, Attack Helicopter, Strafe Run / AA Strike, AH-6 Overwatch, Pave Low |
| Support | UAV, Ballistic Vests / Team Armor Pulse, Counter-UAV, Recon Drone / Recon Pulse, Advanced UAV, EMP |

Only the draw animation changes. Reward validation, consumption, callbacks,
audio, and effects remain intact. Each reward has its own `fun_mode_fast_*`
enable dvar, allowing its stock animation to be restored independently.

## MOAB Counter

A small `STREAK` value above the bottom-right ammunition HUD displays IW5's
authoritative `cur_kill_streak_for_nuke` value. It counts qualifying
non-killstreak-weapon kills toward the MOAB and resets on death, independently
of Assault reward cycling and Support point persistence. It remains cumulative
after a MOAB is earned, so a player on their second cycle sees the complete gun
streak rather than a counter reset to zero.

Each award requires 25 qualifying kills, or 24 with Hardline. Repeat behavior
can be disabled before loading a map with
`fun_mode_repeat_moabs_enable 0`.

The counter can be disabled before loading a map with
`fun_mode_killstreak_counter_enable 0`. Its default position is
`BOTTOMRIGHT -92 -82`; the `fun_mode_killstreak_counter_x`,
`fun_mode_killstreak_counter_y`, and `fun_mode_killstreak_counter_scale` dvars
allow visual adjustment without editing the script.

## Shared Behavior

Player-controlled streaks are exempt from MW3's temporary post-spawn damage
cap, allowing their normal damage to resolve immediately after an enemy
spawns.

Most optional changes have a matching `fun_mode_*` enable dvar. Exact tuning
and implementation details live in the named scripts under [`gsc/`](../gsc/),
with shared damage and compatibility behavior in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc). Update this document whenever a
killstreak's behavior or default value changes.
