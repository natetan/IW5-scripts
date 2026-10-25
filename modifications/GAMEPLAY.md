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
| Match stats HUD | Displays the local player's kills, stock current killstreak, and deaths in green at the top center of the screen. | Human players only. Disable before map load with `fun_mode_player_stats_hud_enable 0`. The separate bottom-right MOAB Streak counter tracks only MOAB-eligible weapon kills. |
| Knife Runner | A human loadout must originally select Extreme Conditioning, Quickdraw, Dead Silence, Throwing Knife, Tactical Insertion, Juiced, and either a Tactical Knife handgun or Akimbo USP .45s. When detected, the build removes the primary weapon, empties the eligible sidearm's magazine and reserve, and disables battlefield weapon pickup interactions so it remains committed to melee and Throwing Knife play. The build remains eligible after throwing the knife or placing the insertion, but its movement and protection benefits apply only while the eligible sidearm is drawn. Walking speed remains unchanged, sprint speed composes with existing movement systems, and a confirmed melee or Throwing Knife kill while active briefly blocks incoming damage. Granted perks cannot activate the build, and Juggernauts are excluded. A centered activation notice appears only the first time the eligible sidearm is drawn during each life. Each qualifying kill also displays an `INVULNERABLE` HUD with a native tenths-of-a-second countdown; another qualifying kill refreshes both immunity and the timer. Juiced only needs to be selected; its stock deathstreak effect does not need to be currently active. | **1.50×** active-sprint multiplier and **2.00 seconds** of post-kill damage immunity. |
| Explosive spawn protection | Enemy grenades and projectiles can damage players immediately after spawning. This removes both the nearby-explosive protection after an ordinary spawn and the separate opening-match damage reduction. Blast Shield, Juggernaut resistance, bullet damage, and spawn selection are unchanged. | Per-spawn protection defaults to **0 ms** instead of **3500 ms** and is configurable with `fun_mode_explosive_spawn_protection_ms`. The stock opening **10-second / 8% damage** protection is disabled by default; set `fun_mode_match_start_explosive_protection_enable 1` before map load to restore it. |
| Death-loop command | A human player can type `!death` to toggle a personal loop that suicides them shortly after every spawn. Typing it again disables the loop. It is intended for rapid death/statistics testing and never targets bots or other players. | Enabled by default; set `fun_mode_death_loop_command_enable 0` before loading the map to remove the command. |
| Permissioned testing commands | A reusable chat-command registry provides permission levels **0–3**, aliases, command discovery, help text, and GUID-based authorization. The host of a non-dedicated session automatically receives level 3. `!give <killstreak> [player]` grants a validated killstreak through IW5's native extra-reward slot; `!random` immediately changes to a random configured map while preserving the current supported mode and applying mapvote's Drop Zone safety fallbacks. `!commands`, `!help`, and `!permission` expose the available interface. | Enabled by default with public players at level **0** and gameplay-changing commands restricted to level **3**. Dedicated-server GUIDs are configured outside Git with `fun_mode_chat_permission_1_guids`, `fun_mode_chat_permission_2_guids`, and `fun_mode_chat_permission_3_guids`. Existing `fun_mode_super_class_guids` entries also receive level 3. |
| Fun Mode super-class damage resistance | Authorized classes 13–15 take half damage from ordinary melee attacks and direct projectile collisions. The rule reuses the existing super-class class/GUID eligibility check and runs after normal game-mode and offensive damage modifiers. | **0.50× melee damage** and **0.50× `MOD_PROJECTILE` damage**. Projectile splash, bullets, explosives, and other damage types remain unchanged. Tunable with `fun_mode_super_class_melee_damage_multiplier` and `fun_mode_super_class_direct_projectile_damage_multiplier`. |
| Fun Mode melee cleave | A successful melee hit by an authorized class 13–15 player repeats the knife's normal base damage against every other living player in a small radius with line of sight. The original victim and attacker are excluded, synthetic hits cannot recursively cleave, and each secondary hit uses IW5's normal damage callback so friendly-fire mode, attribution, killfeed, scoring, and target-specific defenses remain authoritative. | Enabled by default with a **192-unit** radius and **1.00×** damage. Configure with `fun_mode_super_class_melee_cleave_enable`, `fun_mode_super_class_melee_cleave_radius`, and `fun_mode_super_class_melee_cleave_damage_multiplier`. |
| Fun Mode Throwing Knife AoE | A Throwing Knife must damage another player before the pulse can occur. An authorized class 13–15 hit repeats the Throwing Knife's normal base damage against every other visible player around the struck victim. It shares the melee cleave's native callback, friendly-fire, attribution, scoring, target-defense, and recursion protections while retaining Throwing Knife killfeed attribution. | Enabled by default with a **382-unit** radius and **1.00×** damage. Configure with `fun_mode_super_class_throwing_knife_aoe_enable`, `fun_mode_super_class_throwing_knife_aoe_radius`, and `fun_mode_super_class_throwing_knife_aoe_damage_multiplier`. |
| Fun Mode Model 1887 kill AoE | A lethal Model 1887 hit by an authorized class 13–15 player is verified after IW5 resolves the damage, then creates a damage pulse centered on the dead victim. It repeats the killing hit's final post-modifier damage against nearby players regardless of intervening cover, using the native callback to preserve friendly-fire rules, attribution, scoring, defenses, and Model killfeed credit. Teammates therefore take damage only when the active recipe permits it, and the shared recursion guard prevents chain explosions. | Enabled by default with a **382-unit** radius and **1.00×** damage. Configure with `fun_mode_super_class_model_1887_kill_aoe_enable`, `fun_mode_super_class_model_1887_kill_aoe_radius`, and `fun_mode_super_class_model_1887_kill_aoe_damage_multiplier`. |
| Fun Mode Desert Eagle kill AoE | A lethal Desert Eagle hit by an authorized class 13–15 player creates the same cover-ignoring damage pulse after IW5 confirms the victim's death. The pulse repeats the killing hit's final post-modifier damage through the native callback, preserving friendly-fire rules, attribution, scoring, defenses, and Desert Eagle killfeed credit without recursively chaining. | Enabled by default with a **382-unit** radius and **1.00×** damage. Configure with `fun_mode_super_class_deagle_kill_aoe_enable`, `fun_mode_super_class_deagle_kill_aoe_radius`, and `fun_mode_super_class_deagle_kill_aoe_damage_multiplier`. |

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
live in their named files under [`gsc/`](../gsc/), including explosive spawn
protection in
[`gsc/spawn_protection_tuning.gsc`](../gsc/spawn_protection_tuning.gsc) and the
testing-only death loop in
[`gsc/death_loop_command.gsc`](../gsc/death_loop_command.gsc). Permissioned
testing commands live in
[`gsc/admin_chat_commands.gsc`](../gsc/admin_chat_commands.gsc). When
gameplay behavior or a default value changes, update this document in the same
commit.
