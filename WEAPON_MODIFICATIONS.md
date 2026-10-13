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
| Barrett .50cal | **2×** | Movement scalar is raised from the stock heavy-sniper 80% tier to the standard sniper 90% tier. |
| L118A | **2×** | Multiplier applies to rifle-bullet damage. |
| Dragunov | Stock (1×) | None. |
| AS50 | **2×** | Movement scalar is raised from the stock heavy-sniper 80% tier to the standard sniper 90% tier. |
| RSASS | Stock (1×) | None. |
| MSR | **2×** | Multiplier applies to rifle-bullet damage. |
| Intervention *(Plutonium custom weapon)* | **2×** | Covered through its `iw5_cheytac` runtime weapon name. |

## Shotguns

Every human loadout containing a shotgun receives both the **Range** and
**Damage** proficiencies, including a shotgun carried as an Overkill
secondary. The script multipliers below compose with those engine-managed
proficiencies.

| Weapon | Player damage multiplier | Other modifications |
|---|---:|---|
| USAS-12 | **1.5×** unsilenced; **3×** silenced | Silencer combinations retain the stronger multiplier even with a second attachment. |
| KSG 12 | **2×** unsilenced; **5×** silenced | Assault Juggernaut uses a silenced, extended-mag KSG. |
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
| .44 Magnum | Stock (1×) | None. |
| Five Seven | Stock (1×) | Recon Juggernaut uses the Tactical Knife variant. |
| Desert Eagle | **2×** | Each kill restores 50% of the equipped magazine; odd capacities round up. Assault Juggernaut carries the Tactical Knife variant. |

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

| System | Eligible weapons | Behavior |
|---|---|---|
| Specialist multishot | Normal firearms after genuinely earning the full Specialist Bonus | Each shot has a 20% chance to deal a second copy of its final bullet damage without consuming ammunition. Shotgun pellets and same-frame penetration hits share one roll. |
| Specialist magazine refill | Normal firearms after genuinely earning the full Specialist Bonus | Each kill restores 25% of the killing weapon's equipped magazine. The strongest applicable percentage refill wins instead of stacking. |
| Specialist Impact | Weapons that support bullet penetration | Fun Mode super classes receive Impact in addition to their selected proficiency. |
| Shotgun proficiencies | Human loadouts containing any shotgun | Grants both Range and Damage, including when the shotgun is an Overkill secondary. |
| Extended Scavenger | Configured secondary weapons, equipment, launchers, and underbarrel tubes | Expands stock Scavenger resupply behavior. Standalone-launcher resupply remains disabled by default; underbarrel-tube resupply is enabled by default. |

## Special Loadout Changes

| Loadout | Modification |
|---|---|
| Assault Juggernaut | Replaces the stock ACR and MP9 with a silenced extended-mag KSG 12 and a Desert Eagle with Tactical Knife. |
| Recon Juggernaut | Retains the Riot Shield and Five Seven loadout. |

## Source of Truth

Most damage, refill, proficiency, movement, and Specialist rules are defined
in [`gsc/fun_mode.gsc`](./gsc/fun_mode.gsc). Assault Juggernaut weapon
selection is defined in [`maps/mp/gametypes/_class.gsc`](./maps/mp/gametypes/_class.gsc).
When behavior changes, update this document in the same commit.
