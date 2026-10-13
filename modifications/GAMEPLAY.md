# IW5 Gameplay Modifications

This document tracks cross-cutting gameplay changes made by this repository.
Weapon-specific balance belongs in [`WEAPONS.md`](./WEAPONS.md), while perk and
Specialist behavior belongs in [`PERKS.md`](./PERKS.md). Maps, Bot Warfare, and
server operations are documented separately.

## Player Systems

| System | Current behavior | Default tuning |
|---|---|---|
| Quick Fix | Every player heals after a kill. Damage below normal health is restored first; further kills grant non-regenerating overhealth. Damage consumes that overhealth permanently, a real Ballistic Vest takes ownership when collected, and a yellow overlay communicates the remaining bonus. | Restores **25%** of base health below full health, adds **10%** overhealth per kill at or above full health, and caps health at **200%** of the mode's normal maximum. |
| Kill momentum | Every kill grants a brief movement-speed burst. Consecutive kills refresh the timer and add stacks; expired momentum falls one stack at a time rather than vanishing immediately. Death or a new spawn clears it. | Starts at **1.20x**, adds **0.025x** per stack, caps at **1.30x / 5 stacks**, and loses one stack every **1.5 seconds** without another kill. |
| Full-lobby team-switch assist | Opening the team-change menu in a full 9v9 bot lobby temporarily removes one bot from the destination team. The normal fill target is restored after the human switches so Bot Warfare replaces the bot on the vacated team. | Enabled with an **18-player** fill target and restored after **10 seconds**. |
| Player-controlled streak lethality | Removes MW3's temporary post-spawn damage cap for player-controlled killstreaks, allowing their normal damage to resolve immediately after an enemy spawns. | Enabled whenever Fun Mode is enabled. |

Quick Fix and kill momentum are independent of the selected class, perk
package, and strike package. Their values are controlled by the corresponding
`fun_mode_quick_fix_*` and `fun_mode_kill_momentum_*` dvars initialized in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc).

## Killstreak Reworks and Tuning

| Stock reward | Modification |
|---|---|
| Precision Airstrike | Replaced with the dormant Harrier Strike path while retaining the stock reward slot, icon, cost, and targeting controls. |
| Strafe Run | Replaced with AA Strike: Harrier flybys destroy hostile air support, deny enemy airspace temporarily, and launch two spaced attacks against ground targets. |
| Attack Helicopter | Retains its cannon and anti-Harrier rockets, then uses its current cannon target for a safe ground rocket when no hostile Harrier exists. Ground rockets have a nine-second cooldown. |
| AH-6 Overwatch | Retains its stock dual miniguns and adds one alternating FFAR against the current target every eight seconds. |
| Assault Drone | Replaced with two autonomous close-air-support passes using shipped Harrier presentation assets, paired FFARs, and the stock A-10 cannon sweep. |
| Pave Low | Retains its stock flight, health, flares, and dual miniguns, and adds a three-rocket ground-suppression salvo every ten seconds. |
| AC-130 | Reduces cannon reloads to **2.5 seconds** for the 105 mm, **1.5 seconds** for the 40 mm, and **0.5 seconds** for the 25 mm. |
| Reaper | Increases missile damage to **1.5x** and shortens the interval between missiles from three seconds to **2.25 seconds**. |
| Recon Drone | Replaced with a one-time **2,400-unit** Recon Pulse that applies the genuine ten-second Recon Drone tag without flashing or damaging targets. |
| Advanced UAV | Extends the actual reward from 30 to **40 seconds** and reveals Assassin users as ordinary red dots without exposing their facing direction. Naturally stacked UAVs remain stock. |
| Support Osprey | Expands its defensive radius by **1.25x**, removes trapped crates, reduces UAV and Counter-UAV odds, and shifts drops toward useful mid-tier support rewards. Assault Osprey balance remains stock. |

Each rework is isolated behind its own `fun_mode_*` enable dvar. See the
matching script under [`gsc/`](../gsc/) for its exact controls and source of
truth.

## Activation and Feedback

| System | Behavior |
|---|---|
| Fast killstreak activation | UAV, Support UAV, Counter-UAV, Advanced UAV, Recon Pulse, EMP, Attack Helicopter, AH-6, and Pave Low use a quick marker-weapon draw in place of the slower stock radio animation. Their validation, reward consumption, callbacks, audio, and effects remain stock. |
| EMP countdowns | System chat reports the effective EMP or MOAB EMP duration every ten seconds and once per second from five through one. Overlapping effects announce only the longer remaining duration. |
| MOAB presentation | Removes the stock vision, slow-motion, and miscellaneous presentation effects while deliberately retaining the MOAB's EMP. |

## Stability and Compatibility Fixes

| Fix | Purpose |
|---|---|
| Drop Zone tracking guards | Prevents undefined team, HUD, or zone state during team changes from producing permanent runtime-error loops. |
| Recon Drone metadata guard | Safely handles maps with missing or malformed remote-UAV height metadata. |
| Destructible sound guard | Prevents missing destruction sound aliases from producing script runtime errors. |
| Osprey attractor defaults | Restores missing missile-attractor defaults before either Support or Assault Osprey creation. |

## Source of Truth

Global combat and player systems are defined primarily in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc). Isolated killstreak reworks, tuning,
feedback, and stability hooks live in their named files under
[`gsc/`](../gsc/). When gameplay behavior or a default value changes, update
this document in the same commit.
