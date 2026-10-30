# IW5 Killstreak Modifications

This document tracks killstreak changes made by this repository. Rewards are
separated by strike package and ordered by their stock kill or point cost.
Rewards absent from these tables retain their stock behavior.

## Assault Strike Package

| Killstreak | Mod | Notes |
|---|---|---|
| UAV — 3 kills | Stock | Radar behavior remains stock. See [Fast Activation](#fast-activation). |
| Predator Missile — 5 kills | Stock | Player-controlled missile behavior remains stock. |
| Sentry Gun — 5 kills | Persistent direct-deploy hybrid Sentry | Removes the stealable care-package delivery and immediately opens the stock carried-Sentry placement preview. The Sentry has no duration timeout and remains until destroyed or removed by normal ownership or match cleanup. Its normal minigun, health, pickup, EMP, and destruction behavior remain intact. While tracking a visible target at least **512 units** away, it can supplement its minigun with one grenade every **8 seconds**. Cancelling or failing placement preserves the reward. Set `fun_mode_sentry_persistent_lifetime_enable 0` before map load to restore the stock 90-second timeout. |
| Precision Airstrike — 6 kills | Harrier Strike replacement | Uses IW5's dormant Harrier path while retaining the Precision Airstrike slot, icon, cost, and location-selection controls. Both the opening airstrike and Harrier cannon kills extend the owner's same-life Assault streak. The Harrier can engage hostile aircraft and is destroyed by EMP effects. |
| Attack Helicopter — 7 kills | Ground-targeting rockets | Preserves the cannon and anti-Harrier behavior. With no hostile Harrier, it can fire at its current player target when line of sight, firing angle, and minimum range are valid. Ground rockets have unlimited ammunition and a nine-second cooldown. See [Fast Activation](#fast-activation). |
| Strafe Run — 9 kills | AA Strike replacement | Harrier flybys attack hostile aircraft, UAVs, and AC-130s, temporarily deny enemy airspace, and launch two spaced guided attacks against ground targets. See [Fast Activation](#fast-activation). |
| AH-6 Overwatch — 9 kills | Rocket support | Preserves stock flight, dual miniguns, health, duration, and counters. Adds one alternating FFAR against its current minigun target every eight seconds. See [Fast Activation](#fast-activation). |
| Reaper — 9 kills | Automated Reaper | Preserves the stock Reaper aircraft, health, flare, anti-air counters, destruction credit, 40-second timeout, and **14 missiles**, but removes player control. Fast activation launches the aircraft while its owner remains mobile. It randomly targets living, visible enemies from the aircraft's position, respects Blind Eye, and fires at a **2.25-second** interval. Missile damage remains **1.5x**. The behavior is identical on every map. Set `fun_mode_automated_reaper_enable 0` before map load to restore the player-controlled Reaper. See [Fast Activation](#fast-activation). |
| Assault Drone — 10 kills | A-10 support replacement | Removes the care-package delivery and player-controlled drone. Calls two autonomous attack passes that use shipped Harrier presentation assets, paired FFARs, and the stock A-10 cannon sweep. |
| AC-130 — 12 kills | Automated gunship | Fast activation launches an autonomous AC-130 while its owner remains mobile. The gunship selects visible non-Blind Eye enemies and cycles through its 105 mm, 40 mm, and 25 mm weapons. Its **40-second** duration, weapon damage, health, two flares, AA vulnerability, and owner attribution remain stock. Existing reload tuning remains **2.5 seconds** for the 105 mm, **1.5 seconds** for the 40 mm, and **0.5 seconds** for the 25 mm. Set `fun_mode_automated_ac130_enable 0` before map load to restore the player-controlled AC-130. See [Fast Activation](#fast-activation). |
| Pave Low — 12 kills | Rocket salvos | Preserves stock flight, health, flares, and dual miniguns. Adds a three-rocket ground-suppression salvo against visible enemy clusters every ten seconds. See [Fast Activation](#fast-activation). |
| Assault Juggernaut — 15 kills | Predator Swarm replacement | Removes the care package and Juggernaut loadout. Fast activation starts **seven three-missile salvos** at **four-second intervals** using autonomous Reaper-guided missiles in a Predator-style top-down barrage. Missiles select living enemies with a clear overhead approach and respect Blind Eye. The replacement also applies when this reward is granted randomly after Specialist Bonus. Set `fun_mode_assault_juggernaut_swarm_enable 0` before map load to restore the stock Assault Juggernaut package. See [Fast Activation](#fast-activation). |
| Osprey Gunner — 17 kills | Automated Assault Osprey | Preserves the stock laptop drop-location selection while omitting the unnecessary ride-camera fade, then retains the three Assault care packages, flight route, **75-second** lifetime, health, flares, and AA counters. After the location is confirmed, the owner immediately resumes normal play while the Osprey autonomously operates its stock minigun. It prioritizes visible hostile helicopters, Pave Lows, and AH-6s before visible non-Blind Eye infantry. Minigun fire uses **12-shot bursts**, **0.10 seconds** between shots, and **0.50 seconds** between bursts. Missing missile-attractor defaults are also restored before aircraft creation. Set `fun_mode_automated_osprey_gunner_enable 0` before map load to restore player control. |

## Support Strike Package

| Killstreak | Mod | Notes |
|---|---|---|
| UAV — 4 points | Stock | Radar behavior remains stock. See [Fast Activation](#fast-activation). |
| Ballistic Vests — 5 points | Team armor pulse | Replaces the deployable vest bag with an immediate pulse centered on the user. The user and every living teammate within **1,200 units** receive armor through IW5's Ballistic Vest callback, with the stock grant monitor adjusted to target **2× the game mode's base health**: 100→200 HP or 200→400 HP. Current Quick Fix overhealth and repeated pulses cannot compound that ceiling. The native armor overlay, 50-damage armor-state duration, and return to the pre-vest base maximum are preserved with proportional thresholds. Each recipient sees a centered `Received Ballistic Vest` confirmation, and each armored teammate awards the stock **50 Support XP** to the user. Configure the multiplier with `fun_mode_ballistic_vest_health_multiplier`. See [Fast Activation](#fast-activation). |
| Counter-UAV — 5 points | Stock | Duration and radar-jamming behavior remain stock. See [Fast Activation](#fast-activation). |
| Recon Drone — 10 points | Recon Pulse replacement | Replaces manual flight with a pulse centered on the user. Enemies within **2,400 units** receive the genuine Recon Drone tag for ten seconds, including tagged-kill assists, without flash or damage. Maps with malformed remote-UAV height metadata are also guarded against runtime loops. See [Fast Activation](#fast-activation). |
| Advanced UAV — 12 points | Longer duration and Assassin reveal | Extends the actual reward from 30 to **40 seconds**. Assassin users appear globally as ordinary red dots but retain protection from directional arrows. Naturally stacked UAVs remain stock. See [Fast Activation](#fast-activation). |
| Remote Sentry — 12 points | Persistent Guardian Sentry | Removes remote control and converts the reward into a place-and-forget autonomous minigun. It prioritizes visible hostile helicopters, AH-6s, Pave Lows, and Harriers before falling back to infantry. Each owner may maintain **two** Support Sentries; placing a third destroys the oldest. Turrets remain until destroyed, replaced, their owner leaves or changes teams, or the match ends. Stock weapon damage, health, EMP behavior, minimap presence, attribution, and destruction rewards remain intact. Set `fun_mode_support_guardian_sentry_enable 0` before map load to restore the stock Remote Sentry. |
| EMP — 18 points | Harrier destruction and countdown feedback | System chat reports the effective EMP duration every ten seconds, then every second from five through one. It also clears custom Harriers and preserves normal destruction credit and feedback. See [Fast Activation](#fast-activation). |
| Recon Juggernaut — 18 points | Death's Dance replacement | Removes the care package and Juggernaut loadout. Fast activation grants one permanent, stackable Death's Dance charge. A fatal hit consumes one charge, leaves the player at **1 HP**, and grants **3 seconds** of invulnerability. The first kill during that window triggers a native **384-unit**, **200-to-25 damage** explosion around the player and grants a full scaled Ballistic Vest; the owner is immune to the explosion, allies follow the match's friendly-fire rules, and invulnerability continues for the remainder of the original three seconds. Failing to earn a kill simply ends the invulnerability. Set `fun_mode_deaths_dance_enable 0` before map load to restore the stock Recon Juggernaut package. See [Fast Activation](#fast-activation). |
| Escort Airdrop — 18 points | Support Osprey tuning | Expands its defensive radius by **1.25x**, removes trapped crates, reduces UAV and Counter-UAV odds, and shifts drops toward useful mid-tier support rewards. Missing missile-attractor defaults are restored before aircraft creation. |

## Special Streak

| Killstreak | Mod | Notes |
|---|---|---|
| MOAB — 25 weapon kills | Presentation, EMP integration, countdown feedback, and repeat awards | Removes the stock vision, slow-motion, and miscellaneous presentation effects while retaining the EMP. Its EMP clears custom Harriers and shares the same effective-duration countdown logic as Support EMP, so overlapping effects announce only the longer timer. Additional MOABs are awarded at the same per-cycle cost. Normal milestones are 25, 50, and 75; Hardline milestones are 24, 48, and 72. |

## Fast Activation

Fast activation is normally a quality-of-life change rather than a killstreak
balance mod. The Assault Juggernaut's Predator Swarm replacement also uses it
because that streak no longer deploys a package. It replaces the slow stock
radio-device animation with a quick marker-weapon draw for these rewards:

| Strike package | Killstreaks |
|---|---|
| Assault | UAV, Attack Helicopter, Strafe Run / AA Strike, AH-6 Overwatch, Reaper, AC-130, Pave Low, Assault Juggernaut / Predator Swarm |
| Support | UAV, Ballistic Vests / Team Armor Pulse, Counter-UAV, Recon Drone / Recon Pulse, Advanced UAV, EMP |

Except for the explicitly documented Predator Swarm replacement, only the draw
animation changes. Reward validation, consumption, callbacks, audio, and
effects remain intact. Each reward has its own `fun_mode_fast_*` enable dvar,
allowing its stock animation to be restored independently.

## MOAB Counter

A small `MOAB STREAK` value above the bottom-right ammunition HUD displays IW5's
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
with the Reaper missile's shared damage multiplier in
[`gsc/weapon_damage_multipliers.gsc`](../gsc/weapon_damage_multipliers.gsc)
and player-controlled streak spawn-damage handling in
[`gsc/combat_damage_modifiers.gsc`](../gsc/combat_damage_modifiers.gsc).
Other shared compatibility behavior remains coordinated by
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc). Update this document whenever a
killstreak's behavior or default value changes.
