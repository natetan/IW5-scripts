# IW5 Weapon Modifications

This document tracks player-weapon balance changes made by this repository.
It includes the full standard multiplayer weapon roster so unchanged weapons
and under-served categories remain visible during future balance passes.

The damage column describes the additional script multiplier applied to player
damage after IW5 has resolved the weapon's ordinary damage, range falloff, hit
location, penetration, attachment, and proficiency behavior. **Stock (1×)**
means this repository does not currently add a weapon-specific multiplier.

Unless noted otherwise, attachment, camo, reticle, Akimbo, and extended-mag
variants inherit the rule associated with their base weapon.

## Assault Rifles

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| M4A1 | Stock (1×) | None. |
| M16A4 | Stock (1×) | None. |
| SCAR-L | Stock (1×) | None. |
| CM901 | **2×** | Multiplier applies to rifle-bullet damage. |
| Type 95 | Stock (1×) | None. |
| G36C | Stock (1×) | None. |
| ACR 6.8 | Stock (1×) | None. |
| MK14 | Stock (1×) | None. |
| AK-47 | Stock (1×) | None. |
| FAD | Stock (1×) | None. |

## Submachine Guns

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| MP5 | Stock (1×) | None. |
| UMP45 | Stock (1×) | None. |
| PP90M1 | Stock (1×) | None. |
| P90 | Stock (1×) | None. |
| PM-9 | Stock (1×) | None. |
| MP7 | Stock (1×) | None. |

## Light Machine Guns

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| L86 LSW | Stock (1×) | None. |
| MG36 | Stock (1×) | None. |
| PKP Pecheneg | Stock (1×) | None. |
| MK46 | Stock (1×) | None. |
| M60E4 | Stock (1×) | None. |

## Sniper Rifles

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| Barrett .50cal | **2×** | Multiplier applies to rifle-bullet damage. Receives 100% mobility while drawn. |
| L118A | **2×** | Multiplier applies to rifle-bullet damage. Receives 100% mobility while drawn. |
| Dragunov | Stock (1×) | Receives 100% mobility while drawn. |
| AS50 | **2×** | Multiplier applies to rifle-bullet damage. Receives 100% mobility while drawn. |
| RSASS | Stock (1×) | Receives 100% mobility while drawn. |
| MSR | **2×** | Multiplier applies to rifle-bullet damage. Receives 100% mobility while drawn. |
| Intervention *(Plutonium custom weapon)* | **2×** | Covered through its `iw5_cheytac` runtime weapon name. Receives 100% mobility while drawn. |

## Shotguns

Every human loadout containing a shotgun receives both the **Range** and
**Damage** proficiencies, including a shotgun carried as an Overkill
secondary. The script multipliers below compose with those engine-managed
proficiencies.

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| USAS-12 | **1.5×** unsilenced; **3×** silenced | Silencer combinations retain the stronger multiplier even with a second attachment. |
| KSG 12 | **2×** unsilenced; **5×** silenced | Silencer combinations retain the stronger multiplier even with a second attachment. |
| SPAS-12 | **2×** unsilenced; **5×** silenced | Silencer combinations retain the stronger multiplier even with a second attachment. |
| AA-12 | **2×** unsilenced; **3×** silenced | Each kill restores 25% of the equipped magazine, rounded to a whole round and capped at its clip size. |
| Striker | Stock (1×) unsilenced; **3×** silenced | Bloodthirster restores **50%** of final player damage. Healing first fills the player's current Quick Fix or Ballistic Vest health allowance; overflow becomes an independent consumable Bloodshield capped at an additional **150% of the mode's base health**, allowing 200 vested health plus 150 shield in a 100-HP mode. While Bloodshield is active, Striker bullet damage scales linearly with its remaining capacity, from no bonus near zero to **+50% damage** at maximum shield. Firing the final shell emits a **600-unit**, distance-only Pressure Release EMP pulse through walls against hostile equipment; it cannot damage players and currently has no cooldown. |
| Model 1887 | **5×** | The weapon has no attachment variants; its base damage receives the multiplier. |

## Machine Pistols

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| FMG9 | Stock (1×) | None. |
| MP9 | Stock (1×) | None. |
| Skorpion | Stock (1×) | None. |
| G18 | Stock (1×) | None. |

## Handguns

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| USP .45 | Stock (1×) | None. |
| P99 | Stock (1×) | None. |
| MP412 | **3×** | Each kill restores 50% of the equipped magazine; odd capacities round up. |
| .44 Magnum | **2×** | None. |
| Five Seven | Stock (1×) | No additional modifications. |
| Desert Eagle | **2×** | Each kill restores 50% of the equipped magazine; odd capacities round up. |

The MP412 and Desert Eagle refill uses the equipped weapon's actual clip size,
so Akimbo and extended-mag variants scale automatically. If another refill
rule also applies, the strongest percentage is used instead of stacking the
percentages.

## Launchers and Grenade Launchers

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| SMAW | Stock (1×) | A hostile direct impact against a player with damage reflection is suppressed and lethally reflected to the shooter. The direct victim ignores that impact's paired splash callback; ordinary nearby splash is unchanged. |
| Javelin | **10×** | A player kill restores one Javelin missile. Standalone targeting uses a **575 ms** nominal lock delay (stock **1,150 ms**) and **550-unit** ground minimum distance (stock **1,100**); see below. |
| Stinger | Stock (1×) | None. |
| XM25 | Stock (1×) | None. |
| M320 GL | Stock (1×) | None. This is the standalone secondary, not an underbarrel tube. |
| RPG-7 | Stock (1×) | A hostile direct impact against a player with damage reflection is suppressed and lethally reflected to the shooter. The direct victim ignores that impact's paired splash callback; ordinary nearby splash is unchanged. |
| Underbarrel M320 / GP25 / grenade launcher | **3×** | A kill restores one loaded tube round. Supported alternate-mode variants inherit the rule. |

Standalone Javelin targeting is tuned by
[`gsc/javelin_targeting_tuning.gsc`](../gsc/javelin_targeting_tuning.gsc).
`fun_mode_javelin_lock_time_ms` defaults to **575** for both ground and vehicle
locks; the stock Faster Lock-On perk still halves vehicle lock time.
`fun_mode_javelin_min_target_distance` defaults to **550 units** for ground
targets, including Bot Warfare's existing ground-target validation. The distance
test is strict: a target exactly 550 units away is allowed. This is not a new
minimum-distance check for vehicle locks.

The stock **12 ground samples**, **100 ms ADS gate**, **400-unit aim-point
spread limit**, and **50 ms loop polling** remain unchanged. Consequently 575 ms
is the final lock phase, not total time from pressing ADS; ground acquisition
also needs stable samples, and lock completion is quantized to polling frames.
Vehicle line-of-sight, reticle checks, EMP handling, and existing overhead /
top-attack clearance checks are not bypassed. Native firing animation, missile
launch/flight, Stinger targeting, and the underbarrel AC-130 cannon are
unchanged.

Set `fun_mode_javelin_targeting_enable 0` **before loading a map** to keep stock
targeting. Set the two tuning dvars before map load for a new lock duration and
range; they do not require changes to weapon assets.

## Riot Shield

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| Riot Shield | Stock (1×) | None. |

## Global Weapon Systems

These systems apply across categories and therefore are not included in each
individual weapon's multiplier cell.

Specialist-wide weapon effects are documented in
[`PERKS.md`](./PERKS.md) instead of being duplicated
here.

| System | Eligible weapons | Behavior |
|---|---|---|
| Blast Shield Danger Close | Non-killstreak explosive weapons and equipment | A player carrying Blast Shield deals **1.50×** outgoing explosive damage with launchers, attachment modes, grenades, C4, Claymores, and other explosive equipment. It excludes killstreak weapons and self-damage and composes multiplicatively with weapon-specific damage rules. |
| Automatic primary attachment | Human primary weapons | Non-LMG primaries automatically receive Extended Mags as a compatible second attachment. LMGs receive Thermal instead and never receive automatic Extended Mags. An explicitly selected Red Dot or Holographic sight suppresses automatic Thermal; explicit two-attachment setups are preserved. Every automatic attachment is checked against the weapon's supported attachments and the selected attachment's compatibility. Bot primaries are unchanged. |
| Shotgun proficiencies | Human loadouts containing any shotgun | Grants both Range and Damage, including when the shotgun is an Overkill secondary. |
| Extended Scavenger | Configured secondary weapons, equipment, launchers, and underbarrel tubes | Expands stock Scavenger resupply behavior. The repository's normal and hardcore configurations enable every supported category. |
| Drawn-handgun mobility | USP .45, P99, MP412, .44 Magnum, Five Seven, and Desert Eagle | While a standard handgun is drawn, removes the slowest carried primary weapon's mobility penalty and targets the normal **100%** weapon-mobility tier. Walking and sprinting both benefit; Lightweight, Juiced, Extreme Conditioning, and kill momentum still compose normally. Juggernauts are excluded. |
| Knife Runner | Handguns equipped with Tactical Knife, plus Akimbo USP .45s | Requires an original loadout containing Extreme Conditioning, Quickdraw, Dead Silence, Throwing Knife, Tactical Insertion, and the Juiced deathstreak. The primary is removed, the eligible sidearm's magazine and reserve are forced to zero, firearm ammo refills are suppressed, and battlefield weapon pickup interactions are disabled. The sidearm receives **1.50×** sprint speed while drawn, and a confirmed melee or Throwing Knife kill while active grants **2.00 seconds** of damage immunity with a visible tenths-of-a-second HUD countdown. Throwing the knife or placing the insertion does not disable future activation. Juiced only needs to be selected, not currently active. Juggernauts are excluded. |
| Throwing Knife kill refill | Throwing Knife used by any player or bot | A Throwing Knife kill immediately restores one Throwing Knife, capped at the normal one-knife capacity. This does not require Scavenger, Specialist, Knife Runner, an authorized class, or a configured GUID. Enabled by `fun_mode_throwing_knife_kill_refill_enable`. |
| Lethal Throwing Knife | Throwing Knife used by any player or bot | Every physical hit is lethal to players regardless of current health, overhealth, armor, resistance, or fatal-damage prevention. IW5 does not expose Throwing Knife collisions against aircraft to loose GSC, so killstreak vehicles retain their native immunity. Enabled by `fun_mode_throwing_knife_lethal_enable`. |
| Selectable underbarrel ordnance | Underbarrel Shotgun attachment | `!projectile <105\|40\|25\|javelin\|jav\|rpg\|smaw>` selects the caller's native cannon/rocket replacement for the current map, surviving death and class changes. Default `105` retains the heavy 105 mm shell; `40` fires one 40 mm round; `25` fires a bounded native 25 mm burst. `javelin`/`jav`, `rpg`, and `smaw` each fire one rocket. Attachment selection, animation, and ammunition remain unchanged. Killfeed, weapon progression callbacks, and Gun Game use the firing parent gun's captured full identity for every round. |
| Fire mode 25 | Owned, drawn primary/secondary bullet-firing guns | Level-3 `!firemode 25` launches one native AC-130 25 mm round per actual `weapon_fired` notification for the caller. Normal weapon cadence/ammo/animation remain; no five-round expansion or added cooldown. Original player/standard-vehicle bullet damage is intercepted, but native traces/effects and out-of-scope prop damage cannot be universally cancelled by loose GSC. |

### Fire Mode 25

[`gsc/fire_mode.gsc`](../gsc/fire_mode.gsc) owns the caller's map-scoped setting,
firearm eligibility, native event listener, and original-bullet suppression
decision. `fun_mode` configures it and starts one persistent listener per
connection, so the choice survives death/class changes without multiplying
listeners. Only `!firemode 25` is accepted; a new map resets the choice.

Actual weapon metadata must report inventory type `primary` (both carried
firearm slots in IW5), type `bullet`, and class `rifle`, `smg`, `mg`, `pistol`,
`sniper`, or `spread`. A bullet `altmode` such as a hybrid-sight toggle qualifies
only when `WeaponAltWeaponName` links it to that held eligible gun. The player
must own the parent gun and currently hold the supplied fired mode;
remote-control and turret use is excluded. Projectile launchers,
offhands/melee, killstreak weapons, underbarrel grenades and Underbarrel Shotgun
pellets do not qualify.
The Underbarrel Shotgun remains on the independent `!projectile` path.

Stock [`_weapons::watchweaponusage`](https://github.com/plutoniummod/iw5-scripts/blob/master/maps/mp/gametypes/_weapons.gsc)
uses `weapon_fired` with the fired weapon argument and increments native shot
statistics once per notification. Fire Mode consumes the same notifications
without synthesizing `WeaponBurstCount` rounds or scheduling timer-based fire.
Each native shot, including a miss or final magazine round, creates one
`ac130_25mm_mp` round. M16/Type 95 bursts, automatic fire, pistols/Akimbo and slow
snipers retain their native event cadence. A shotgun shell gets one round per
shot notification, not per pellet. An interrupted burst/reload, dry trigger,
death, loadout change, or weapon switch cannot leave queued shots behind.

The shared native projectile helper captures the complete fired gun identity.
Its range override uses `fun_mode_firemode_range` (default **12,000 units**,
minimum **512**) without changing `!projectile` range/burst settings. Each round
keeps native 25 mm flight/damage and the shared **12-second** cleanup cap.
No ammo is granted or manually consumed, and source-gun damage buffs are not
applied to the shell.

The existing player-killed wrapper resolves the captured gun for killfeed and
Gun Game, and reports a firearm death classification (pistol or rifle) only for
marked Fire Mode ordnance when calling stock progression. This lets non-assault
guns such as snipers/pistols follow ordinary firearm weapon-XP eligibility while
damage, perks and defenses still see the native shell. Other projectiles retain
their original classification. Normal unlock, ownership, and challenge rules
still apply; no headshot/accuracy/attachment-hit events are manufactured.

**User-approved loose-GSC scope:** the existing code callback overlay blocks the
original bullet's player damage and standard vehicle damage before forwarding
to stock handlers; marked ordnance and repository synthetic damage are exempt.
Native traces and audiovisual impacts, plus damage to map props/scripted entities
outside those callbacks, can remain. This is not a universal pre-fire engine
hook. A failed native launch logs/displays an error rather than stacking or
silently restoring the original player/vehicle damage. The new fire-mode
integration, especially live M16/Type 95/Akimbo notification cadence, needs an
in-game test; source/fixture checks do not prove runtime cadence.

### Underbarrel Projectile Selections

Underbarrel selections are implemented in
[`gsc/projectile_replacements.gsc`](../gsc/projectile_replacements.gsc).
The command requires permission level 3 and does not change anyone else's
selection or grant a weapon/attachment. Exact asset mappings are
`ac130_105mm_mp`, `ac130_40mm_mp`, `ac130_25mm_mp`, `javelin_mp`, `rpg_mp`,
and `iw5_smaw_mp`, respectively. `jav` normalizes to `javelin`.
They retain native flight/explosion/damage behavior, with a **12-second** cleanup
cap per round. There is no scripted hitscan/damage approximation.

Underbarrel Javelin restores the earlier direct-fire attachment setup:
`MagicBullet` along current aim followed by `Missile_SetFlightModeDirect`,
without stock launcher lock-on/top-attack acquisition. RPG and SMAW use their
native aimed rocket launches without adding homing, camera control, or
speculative velocity overrides. The new rocket integration still needs in-game
testing, especially near-cover collisions and native launch behavior.

The existing damage entry overlay
[`maps/mp/gametypes/_callbacksetup.gsc`](../maps/mp/gametypes/_callbacksetup.gsc)
resolves **only marked underbarrel Javelin** hits to the captured parent gun
before forwarding to the normal player-damage callback. This preserves incoming
native damage and all callback arguments other than weapon identity, prevents the
standalone Javelin's **10x** script multiplier from applying, and needs no shared
attacker/victim context or damage-division workaround. Unmarked standalone
Javelin hits retain their original weapon identity and multiplier. Cannon,
RPG, and SMAW damage identities remain native until the existing death-callback
attribution step; ordinary perk/match/defensive damage handling remains active.

The 25 mm mode fires **5 rounds at 75 ms spacing** per original attachment shot,
without consuming additional attachment ammunition. Each round tracks current
aim but retains the original full parent-gun identity. Named tunables
`fun_mode_projectile_25mm_burst_rounds` (default **5**, clamped **1–10**) and
`fun_mode_projectile_25mm_burst_interval_ms` (default **75**, clamped **50–250**)
bound the burst. Death, disconnect, team/spectator change, weapon switch, a new
attachment shot, selection change, and map end cancel pending rounds. The next
burst step also checks that replacements remain enabled and the original parent
and attachment are still held, preventing a loadout rebuild from continuing an
old burst. Already-fired native shells retain their normal independent lifetime.

Throwing Knife, Predator/`predator`, Reaper, and Osprey underbarrel modes are
removed from selection, precaching, and launch paths. The user reported a native
knife launch error, hovering/arcing missiles, and an Osprey crash. Stock sources
show native offhand knife handling and remote/designated-target missile
lifecycles, but no reliable owner-correct standalone knife launch or forward-only
missile fix was verified. This is not a claim that such behavior is impossible
with engine/asset changes. Unsupported stored selections are rejected at firing,
not silently mapped to a working cannon. The obsolete
`fun_mode_projectile_hitscan_damage` dvar is no longer read.
Regular shotguns, standalone Javelin targeting, actual Throwing Knives, and real
killstreaks are unchanged.

For compatibility, the existing dvar names remain supported.
`fun_mode_underbarrel_cannon_range` controls the aim-point distance, not a forced
explosion radius; it defaults to **12,000 units**, clamped to at least **512**.
The old
`fun_mode_underbarrel_javelin_enable` / `fun_mode_underbarrel_javelin_range`
settings seed the corresponding cannon dvars on startup only when the new dvar
is unset; explicit cannon settings take precedence. Set
`fun_mode_underbarrel_cannon_enable 0` to restore ordinary attachment pellets.
Physical ordnance supplies its own stock damage and does not inherit the
standalone Javelin's 10x multiplier. Native weapon progression/unlock rules still
apply; parent-gun attribution does not synthesize native accuracy or
attachment-hit events.

## Temporary In-Match Presets

Human players can queue a match-temporary loadout with `!preset <name>`. The
choice reapplies on every spawn until `!preset default` is entered, which
restores the selected saved class on the following spawn. Sniper, Gunner, SMG, and Boom
preserve the saved class's lethal, tactical, deathstreak, and complete strike
package. Knife preserves its strike package but explicitly selects Throwing
Knife, Tactical Insertion, and Juiced so it qualifies for Knife Runner.

| Command | Primary | Secondary | Perks | Other behavior |
|---|---|---|---|---|
| `!preset sniper` | Barrett .50cal with Impact and Heartbeat Sensor | MP9 with Silencer | Scavenger, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!preset gunner` | ACR 6.8 with Impact and Red Dot Sight | MP412 with Tactical Knife | Scavenger, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!preset smg` | MP7 with Focus and Silencer | MP9 with Silencer | Extreme Conditioning, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!preset boom` | ACR 6.8 with Focus and M320 Grenade Launcher | Javelin | Sleight of Hand, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!preset knife` | MSR, used to select the sniper character model before Knife Runner removes it | Randomized on every spawn between Tactical Knife variants of the USP .45, P99, MP412, .44 Magnum, Five Seven, and Desert Eagle, plus Akimbo USP .45s | Extreme Conditioning, Quickdraw, Dead Silence | Selects Throwing Knife, Tactical Insertion, and Juiced; Knife Runner then enforces its normal weapon and ammo restrictions. |
| `!preset random` | Rerolls across the complete valid primary pool with a valid random proficiency and one weapon-supported random attachment | Rerolls across the complete valid secondary pool with one weapon-supported random attachment | Preserves all three perks from the selected saved class | Rerolls lethal and tactical equipment on every spawn. Preserves deathstreak and the complete strike package. The normal automatic Extended Mags/Thermal attachment logic still runs after the explicit attachment is selected. |

The presets use the standard loadout pipeline, so their primaries receive the
repository's applicable automatic attachment. Every preset primary uses Gold
camo; secondaries retain no camo. After the swap, the stock killstreak
reconciler restores activation weapons, action slots, queued extra rewards,
selection state, and HUD data without re-awarding or consuming a reward. The
presets do not rewrite saved custom classes and reset with the match.

## Match-Wide Gun Game Overlay

An administrator can toggle `!gungame` for all humans and bots without changing
the current gametype, or use `!gungame on` / `!gungame off` for explicit control.
Repeating the current state leaves assignments unchanged.
Players carry only one randomized weapon. Gun Game supplies an expanded pool to
the shared random-weapon/attachment helper; `!preset random` retains its existing
separate primary/secondary pools and still rerolls both weapons, proficiency,
and equipment on every spawn as before.

The pool includes the normal primary firearms, all six pistols and four machine
pistols, plus SMAW (`iw5_smaw`), RPG (`rpg`), Javelin (`javelin`), M320 GLM
(`m320`), and XM25 (`xm25`). Riot Shield, Stinger, and Juggernaut weapons are
excluded from both selection and assignment restoration.

Only the killer advances after a hostile kill with the assigned weapon or its
attachment mode. Each advancement selects a different weapon and supplies fresh
weapon ammunition. Assigned launcher projectile, splash, and direct-impact kills
qualify. Melee, equipment, killstreaks, suicides, teamkills, and synthetic
kill-mode damage do not qualify.
The assignment and random attachment survive death, respawn, and class changes.
Secondary-class weapons use the sole primary slot with their normal attachment
rules and no camo; no separate secondary or Overkill weapon is retained.
Battlefield weapon pickup is disabled while the overlay is enabled.
Live swaps follow stock IW5 Gun Game's native weapon-switch/raise path rather
than instant spawn selection, so ADS transitions out before the new weapon is
ready. Respawn/loadout rebuilds retain instant spawn weapon selection.
Only the latest pending swap applies. Removal rechecks live weapon ownership
for every snapshot entry and preserves killstreak activation items and offhands.

The normal human-primary automatic attachment bonus still applies to eligible
primary-class weapons, not the added secondary-class weapons. Gun Game
does not reroll class perks or proficiencies, replenish equipment, rebuild
health, or consume/re-award earned streaks. It waits out remote-control streak
use before equipping the pending primary. Personal presets and Knife Runner
restrictions pause, and resume on the next spawn after `!gungame` is toggled off.
Disabling does not rebuild the current life; the overlay resets off on map change.

## Source of Truth

Weapon-specific script damage multipliers are defined in
[`gsc/weapon_damage_multipliers.gsc`](../gsc/weapon_damage_multipliers.gsc).
Proficiency and movement rules are defined in
[`gsc/player_movement.gsc`](../gsc/player_movement.gsc), while Knife Runner's
eligible weapon rules are defined in [`gsc/knife_runner.gsc`](../gsc/knife_runner.gsc).
Kill-triggered ammunition restoration is defined in
[`gsc/kill_ammo_refills.gsc`](../gsc/kill_ammo_refills.gsc).
Blast Shield's outgoing Danger Close-style multiplier is defined in
[`gsc/combat_damage_modifiers.gsc`](../gsc/combat_damage_modifiers.gsc).
Expanded Scavenger classification and refill behavior are defined in
[`gsc/scavenger.gsc`](../gsc/scavenger.gsc). Temporary presets are defined in
[`gsc/temporary_loadouts.gsc`](../gsc/temporary_loadouts.gsc), including the shared
random weapon/attachment construction. The Gun Game overlay and expanded pool
are implemented in [`gsc/gun_game.gsc`](../gsc/gun_game.gsc). When behavior changes,
update this document in the same commit.
