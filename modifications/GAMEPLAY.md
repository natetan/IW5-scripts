# IW5 Gameplay Modifications

This document tracks cross-cutting gameplay changes made by this repository.
Weapon-specific balance belongs in [`WEAPONS.md`](./WEAPONS.md), perk and
Specialist behavior belongs in [`PERKS.md`](./PERKS.md), and killstreak changes
belong in [`KILLSTREAKS.md`](./KILLSTREAKS.md). Maps, Bot Warfare, and server
operations are documented separately.

## Player Systems

| System | Current behavior | Default tuning |
|---|---|---|
| Quick Fix | Every player heals after a kill. Damage below normal health is restored first; further kills grant non-regenerating overhealth. Damage consumes that overhealth permanently, a real Ballistic Vest takes ownership when collected, and a yellow overlay communicates the remaining bonus. | Restores **25%** of base health below full health, adds **10%** overhealth per kill at or above full health, and caps health at **200%** of the mode's normal maximum. |
| Kill momentum | Every kill grants a brief movement-speed burst. Consecutive kills refresh the timer and add stacks; expired momentum falls one stack at a time rather than vanishing immediately. Death or a new spawn clears it. | Starts at **1.20x**, adds **0.025x** per stack, caps at **1.30x / 5 stacks**, and loses one stack every **1.5 seconds** without another kill. |
| Full-lobby team-switch assist | Opening the team-change menu in a full 9v9 bot lobby temporarily removes one bot from the destination team. The normal fill target is restored after the human switches so Bot Warfare replaces the bot on the vacated team. | Enabled with an **18-player** fill target and restored after **10 seconds**. |
| Drawn-handgun mobility | Drawing a standard handgun removes the carried primary weapon's mobility penalty, so an LMG, launcher, or other heavy primary no longer slows the player while the pistol is in hand. Existing perk, deathstreak, sprint, and momentum bonuses continue to compose. Juggernauts are excluded. | Targets the normal **1.0x** weapon-mobility tier while the handgun is equipped. Does not change sprint duration or recovery. |
| Drawn-sniper mobility | Drawing any standard or custom sniper rifle raises its weapon mobility to the SMG-like maximum tier. Existing perk, deathstreak, sprint, and momentum bonuses continue to compose. Juggernauts are excluded. | Targets **1.0x** weapon mobility while the sniper is equipped. Does not change sprint duration or recovery. |
| Knife Runner | A human loadout must originally select Extreme Conditioning, Quickdraw, Dead Silence, Throwing Knife, Tactical Insertion, Juiced, and either a Tactical Knife handgun or Akimbo USP .45s. When detected, the build removes the primary weapon, empties the eligible sidearm's magazine and reserve, and disables battlefield weapon pickup interactions so it remains committed to melee and Throwing Knife play. The build remains eligible after throwing the knife or placing the insertion, but its movement and protection benefits apply only while the eligible sidearm is drawn. Walking speed remains unchanged, sprint speed composes with existing movement systems, and a confirmed melee or Throwing Knife kill while active briefly blocks incoming damage. Granted perks cannot activate the build, and Juggernauts are excluded. A centered activation notice appears only the first time the eligible sidearm is drawn during each life. Each qualifying kill also displays an `INVULNERABLE` HUD with a native tenths-of-a-second countdown; another qualifying kill refreshes both immunity and the timer. Juiced only needs to be selected; its stock deathstreak effect does not need to be currently active. | **1.50×** active-sprint multiplier and **2.00 seconds** of post-kill damage immunity. |

Quick Fix and kill momentum are independent of the selected class, perk
package, and strike package. Their values are controlled by the corresponding
`fun_mode_quick_fix_*` and `fun_mode_kill_momentum_*` dvars initialized in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc).

## Stability and Compatibility Fixes

| Fix | Purpose |
|---|---|
| Drop Zone tracking guards | Prevents undefined team, HUD, or zone state during team changes from producing permanent runtime-error loops. |
| Destructible sound guard | Prevents missing destruction sound aliases from producing script runtime errors. |

## Source of Truth

Global combat and player systems are defined primarily in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc). Gametype and engine stability hooks
live in their named files under [`gsc/`](../gsc/). When gameplay behavior or a
default value changes, update this document in the same commit.
