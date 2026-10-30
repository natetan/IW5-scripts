# IW5 Gameplay Modifications

This document tracks cross-cutting gameplay changes made by this repository.
Weapon-specific balance belongs in [`WEAPONS.md`](./WEAPONS.md), perk and
Specialist behavior belongs in [`PERKS.md`](./PERKS.md), and killstreak changes
belong in [`KILLSTREAKS.md`](./KILLSTREAKS.md). Maps, Bot Warfare, and server
operations are documented separately.

## Player Systems

| System | Current behavior | Default tuning |
|---|---|---|
| Quick Fix | Every player heals after a kill. Damage below normal health is restored first; further kills grant non-regenerating overhealth. Damage consumes that overhealth permanently, a real Ballistic Vest takes ownership when collected, and a yellow overlay communicates the remaining bonus. The three map-vote recipes—Domination, Drop Zone, and Kill Confirmed—disable passive health regeneration, making kills and armor the intended recovery paths. | Restores **25%** of base health below full health, adds **10%** overhealth per kill at or above full health, and caps health at **200%** of the mode's normal maximum. Recipe health regeneration is **0**. |
| Kill momentum | Every kill grants a brief movement-speed burst. Consecutive kills refresh the timer and add stacks; expired momentum falls one stack at a time rather than vanishing immediately. Death or a new spawn clears it. | Starts at **1.20x**, adds **0.025x** per stack, caps at **1.30x / 5 stacks**, and loses one stack every **1.5 seconds** without another kill. |
| Full-lobby team-switch assist | Opening the team-change menu in a full 9v9 bot lobby temporarily removes one bot from the destination team. The normal fill target is restored after the human switches so Bot Warfare replaces the bot on the vacated team. | Enabled with an **18-player** fill target and restored after **10 seconds**. |
| Drawn-handgun mobility | Drawing a standard handgun removes the carried primary weapon's mobility penalty, so an LMG, launcher, or other heavy primary no longer slows the player while the pistol is in hand. Existing perk, deathstreak, sprint, and momentum bonuses continue to compose. Juggernauts are excluded. | Targets the normal **1.0x** weapon-mobility tier while the handgun is equipped. Does not change sprint duration or recovery. |
| Drawn-sniper mobility | Drawing any standard or custom sniper rifle raises its weapon mobility to the SMG-like maximum tier. Existing perk, deathstreak, sprint, and momentum bonuses continue to compose. Juggernauts are excluded. | Targets **1.0x** weapon mobility while the sniper is equipped. Does not change sprint duration or recovery. |
| Match stats HUD | Displays the local player's kills, stock current killstreak, and deaths in green at the top center of the screen. A separate bottom-right HUD tracks MOAB-eligible weapon kills and actual current health, including Quick Fix overhealth and Ballistic Vest armor. The Striker's independent Bloodshield appears on its own row beneath health with a red `BLOODSHIELD` label and disappears when depleted. The `Health` label is green at **75% or more** of base health, yellow **above 40% but below 75%**, and red at **40% or less**; both numeric values remain blue. | Human players only. Health color thresholds use actual health rather than Bloodshield and scale from the game mode's unarmored base health, so overhealth remains green and durability modes retain meaningful warning states. Disable the top-center panel before map load with `fun_mode_player_stats_hud_enable 0`, the MOAB counter with `fun_mode_killstreak_counter_enable 0`, or the health counter with `fun_mode_health_counter_enable 0`. |
| Knife Runner | A human loadout must originally select Extreme Conditioning, Quickdraw, Dead Silence, Throwing Knife, Tactical Insertion, Juiced, and either a Tactical Knife handgun or Akimbo USP .45s. When detected, the build removes the primary weapon, empties the eligible sidearm's magazine and reserve, and disables battlefield weapon pickup interactions so it remains committed to melee and Throwing Knife play. The build remains eligible after throwing the knife or placing the insertion, but its movement and protection benefits apply only while the eligible sidearm is drawn. Walking speed remains unchanged, sprint speed composes with existing movement systems, and a confirmed melee or Throwing Knife kill while active briefly blocks incoming damage. Granted perks cannot activate the build, and Juggernauts are excluded. A centered activation notice appears only the first time the eligible sidearm is drawn during each life. Each qualifying kill also displays an `INVULNERABLE` HUD with a native tenths-of-a-second countdown; another qualifying kill refreshes both immunity and the timer. Juiced only needs to be selected; its stock deathstreak effect does not need to be currently active. | **1.50×** active-sprint multiplier and **2.00 seconds** of post-kill damage immunity. |
| Explosive spawn protection | Enemy grenades and projectiles can damage players immediately after spawning. This removes both the nearby-explosive protection after an ordinary spawn and the separate opening-match damage reduction. Blast Shield, Juggernaut resistance, bullet damage, and spawn selection are unchanged. | Per-spawn protection defaults to **0 ms** instead of **3500 ms** and is configurable with `fun_mode_explosive_spawn_protection_ms`. The stock opening **10-second / 8% damage** protection is disabled by default; set `fun_mode_match_start_explosive_protection_enable 1` before map load to restore it. |
| Death-loop command | A human player can type `!death` to toggle a personal loop that suicides them shortly after every spawn. Typing it again disables the loop. It is intended for rapid death/statistics testing and never targets bots or other players. | Enabled by default; set `fun_mode_death_loop_command_enable 0` before loading the map to remove the command. |
| Permissioned testing commands | A reusable chat-command registry provides permission levels **0–3**, aliases, command discovery, help text, and GUID-based authorization. The host of a non-dedicated session automatically receives level 3. `!give <killstreak> [player] [quantity]` grants one or more validated killstreaks through IW5's native extra-reward queue; quantity defaults to one and the queue is capped at ten entries per player. `!random` changes to a random configured map, while `!killmode <chain\|virus\|aoe\|splash\|vamp\|off>` controls the issuing player's temporary non-killstreak weapon effect. `!commands`, `!help`, and `!permission` expose the available interface. | Enabled by default with public players at level **0** and gameplay-changing commands restricted to level **3**. Dedicated-server GUIDs are configured outside Git with `fun_mode_chat_permission_1_guids`, `fun_mode_chat_permission_2_guids`, and `fun_mode_chat_permission_3_guids`. Existing `fun_mode_super_class_guids` entries also receive level 3. |
| Fun Mode super-class damage resistance | Authorized classes 13–15 take half damage from ordinary melee attacks and direct projectile collisions. The rule reuses the existing super-class class/GUID eligibility check and runs after normal game-mode and offensive damage modifiers. | **0.50× melee damage** and **0.50× `MOD_PROJECTILE` damage**. Projectile splash, bullets, explosives, and other damage types remain unchanged. Tunable with `fun_mode_super_class_melee_damage_multiplier` and `fun_mode_super_class_direct_projectile_damage_multiplier`. |
| Permissioned non-killstreak weapon modes | A level-3 player can enable a map-scoped effect for primary and secondary weapons, attachment modes such as underbarrel grenade launchers, standalone launchers, carried equipment, melee, and Throwing Knives. `aoe` repeats final killing-hit damage against every eligible player near the victim; `chain` repeatedly selects the nearest unvisited player and repeats the initiating damage; `virus` instead applies a lethal headshot at every hop across a much wider sandbox-testing radius, bypassing Final Stand through stock IW5 headshot rules where applicable; `splash` leaves the direct hit unchanged and divides a shared secondary pool among other eligible players on every hit; `vamp` instead applies only to hostile non-killstreak bullet hits and converts actual damage into uncapped health. Area modes ignore cover and route synthetic damage through IW5's native callback. Stock and repository-registered killstreak weapons are excluded. | AoE, chain, and splash use a **382-unit** range; virus uses **1,000 units per hop**. Splash distributes **50%** of each final hit's damage across eligible secondary targets. Vamp restores **100%** of actual bullet damage, excludes overkill and teammate damage, and has no script-side health cap. A Ballistic Vest can raise a low Vamp pool to its normal armored minimum but never reduces a higher existing pool when granted or broken. Chain and virus wait **0.15 seconds** between kills and stop after **17 secondary hops** or when no target is nearby; chain also stops when its copied damage fails to kill. The mode defaults to `off`, is controlled with `!killmode <chain\|virus\|aoe\|splash\|vamp\|off>`, and resets on map change. |

Quick Fix and kill momentum are independent of the selected class, perk
package, and strike package. Their values are controlled by the corresponding
`fun_mode_quick_fix_*` and `fun_mode_kill_momentum_*` dvars. Quick Fix is
implemented in [`gsc/quick_fix.gsc`](../gsc/quick_fix.gsc), while kill momentum
is implemented in [`gsc/player_movement.gsc`](../gsc/player_movement.gsc).

## Stability and Compatibility Fixes

| Fix | Purpose |
|---|---|
| Drop Zone tracking guards | Prevents undefined team, HUD, or zone state during team changes from producing permanent runtime-error loops. |
| Destructible sound guard | Prevents missing destruction sound aliases from producing script runtime errors. |
| Animated-model metadata guard | Prevents malformed custom-map animated props—such as an unregistered model on Western Paradise—from producing a map-load runtime error. Valid animated props retain stock behavior; invalid props remain static. |

## Source of Truth

[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc) is the deterministic coordinator for
global combat and player systems. Extracted features live in named files under
[`gsc/`](../gsc/): Quick Fix in
[`gsc/quick_fix.gsc`](../gsc/quick_fix.gsc), full-lobby team switching in
[`gsc/team_switch_assist.gsc`](../gsc/team_switch_assist.gsc), Recon Drone
range protection in
[`gsc/remote_uav_tracking_fix.gsc`](../gsc/remote_uav_tracking_fix.gsc), and
destructible sound protection in
[`gsc/destructible_sound_fix.gsc`](../gsc/destructible_sound_fix.gsc), and
custom-map animated-model protection in
[`gsc/animated_models_fix.gsc`](../gsc/animated_models_fix.gsc).
Permissioned AoE, chain, virus, and splash behavior lives in
[`gsc/kill_modes.gsc`](../gsc/kill_modes.gsc), while the coordinator retains
the authoritative damage-pipeline ordering. Cross-cutting incoming and
outgoing damage rules live in
[`gsc/combat_damage_modifiers.gsc`](../gsc/combat_damage_modifiers.gsc).
Fun Mode super-class eligibility and full Specialist grants live in
[`gsc/specialist_system.gsc`](../gsc/specialist_system.gsc).
Loadout processing, weapon mobility, sprint composition, and kill momentum
live in [`gsc/player_movement.gsc`](../gsc/player_movement.gsc). Knife Runner
qualification, restrictions, immunity, and HUD feedback live in
[`gsc/knife_runner.gsc`](../gsc/knife_runner.gsc).
Other gametype and engine stability hooks include explosive spawn protection in
[`gsc/spawn_protection_tuning.gsc`](../gsc/spawn_protection_tuning.gsc) and the
testing-only death loop in
[`gsc/death_loop_command.gsc`](../gsc/death_loop_command.gsc). Permissioned
testing commands live in
[`gsc/admin_chat_commands.gsc`](../gsc/admin_chat_commands.gsc). When
gameplay behavior or a default value changes, update this document in the same
commit.
