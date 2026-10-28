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
| Striker | Stock (1×) unsilenced; **3×** silenced | Only silenced variants receive a script multiplier. |
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
| Five Seven | Stock (1×) | Recon Juggernaut uses the Tactical Knife variant. |
| Desert Eagle | **2×** | Each kill restores 50% of the equipped magazine; odd capacities round up. |

The MP412 and Desert Eagle refill uses the equipped weapon's actual clip size,
so Akimbo and extended-mag variants scale automatically. If another refill
rule also applies, the strongest percentage is used instead of stacking the
percentages.

## Launchers and Grenade Launchers

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| SMAW | Stock (1×) | None. |
| Javelin | **10×** | A player kill restores one Javelin missile. |
| Stinger | Stock (1×) | None. |
| XM25 | Stock (1×) | None. |
| M320 GL | Stock (1×) | None. This is the standalone secondary, not an underbarrel tube. |
| RPG-7 | Stock (1×) | None. |
| Underbarrel M320 / GP25 / grenade launcher | **3×** | A kill restores one loaded tube round. Supported alternate-mode variants inherit the rule. |

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

## Temporary In-Match Presets

Human players can queue a match-temporary loadout with chat commands. The
choice reapplies on every spawn until `!default` is entered, which restores the
selected saved class on the following spawn. Sniper, Gunner, SMG, and Boom
preserve the saved class's lethal, tactical, deathstreak, and complete strike
package. Knife preserves its strike package but explicitly selects Throwing
Knife, Tactical Insertion, and Juiced so it qualifies for Knife Runner.

| Command | Primary | Secondary | Perks | Other behavior |
|---|---|---|---|---|
| `!sniper` | Barrett .50cal with Impact and Heartbeat Sensor | MP9 with Silencer | Scavenger, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!gunner` | ACR 6.8 with Impact and Red Dot Sight | MP412 with Tactical Knife | Scavenger, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!smg` | MP7 with Focus and Silencer | MP9 with Silencer | Extreme Conditioning, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!boom` | ACR 6.8 with Focus and M320 Grenade Launcher | Javelin | Sleight of Hand, Quickdraw, SitRep | Preserves equipment and streak configuration. |
| `!knife` | MSR, used to select the sniper character model before Knife Runner removes it | Randomized on every spawn between Tactical Knife variants of the USP .45, P99, MP412, .44 Magnum, Five Seven, and Desert Eagle, plus Akimbo USP .45s | Extreme Conditioning, Quickdraw, Dead Silence | Selects Throwing Knife, Tactical Insertion, and Juiced; Knife Runner then enforces its normal weapon and ammo restrictions. |

The presets use the standard loadout pipeline, so their primaries receive the
repository's applicable automatic attachment. Every preset primary uses Gold
camo; secondaries retain no camo. After the swap, the stock killstreak
reconciler restores activation weapons, action slots, queued extra rewards,
selection state, and HUD data without re-awarding or consuming a reward. The
presets do not rewrite saved custom classes and reset with the match.

## Source of Truth

Weapon-specific script damage multipliers are defined in
[`gsc/weapon_damage_multipliers.gsc`](../gsc/weapon_damage_multipliers.gsc).
Proficiency and movement rules remain in [`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc).
Kill-triggered ammunition restoration is defined in
[`gsc/kill_ammo_refills.gsc`](../gsc/kill_ammo_refills.gsc).
Blast Shield's outgoing Danger Close-style multiplier is defined in
[`gsc/combat_damage_modifiers.gsc`](../gsc/combat_damage_modifiers.gsc).
Expanded Scavenger classification and refill behavior are defined in
[`gsc/scavenger.gsc`](../gsc/scavenger.gsc). Temporary presets are defined in
[`gsc/temporary_loadouts.gsc`](../gsc/temporary_loadouts.gsc). When behavior
changes, update this document in the same commit.
