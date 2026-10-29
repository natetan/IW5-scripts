# IW5 Perk Modifications

This document tracks perk balance changes and perk-related interactions made
by this repository. It lists every standard base perk so unchanged perks and
under-served tiers remain visible during future balance passes.

Pro variants do not receive separate rows. When Fun Mode grants a base perk as
part of its complete Specialist package, it also resolves and grants that
perk's Pro mapping from `mp/perktable.csv`.

## Tier One

| Perk | Modification | Notes |
|---|---|---|
| Recon | Stock | No direct change to the selectable perk. The custom Recon Pulse is a Support streak replacement, not a Recon perk modification. |
| Sleight of Hand | Stock | No direct changes. |
| Blind Eye | Stock | No direct effect change. Fun Mode super classes restore their granted Blind Eye after the stock temporary spawn-protection cleanup finishes. |
| Extreme Conditioning | **Unlimited sprint; 1.10× sprint-speed multiplier** | Originally selecting Extreme Conditioning grants IW5's hidden `specialty_marathon` perk through the repository's `mp/perkTable.csv` overlay. Authorized Fun Mode super classes also receive Marathon; ordinary Specialist-granted copies do not qualify. The speed multiplier applies only while actively sprinting and composes with other movement effects without changing walking speed. A qualifying Knife Runner loadout replaces it with **1.50×** while its eligible sidearm is drawn. |
| Scavenger | **Expanded resupply** | Bags can replenish secondary ammunition, lethal equipment, tactical equipment, underbarrel grenade launchers, and standalone launchers. C4 is re-armed correctly before its charge is restored. |

The repository's `normal.cfg` and `hard.cfg` enable every expanded Scavenger
category, including standalone launchers. Flashbangs and concussion grenades
retain a two-item cap; supported underbarrel tubes retain a two-round reserve
cap. Primary-weapon ammunition still follows the normal MW3 Scavenger path.

## Registered Hidden Perks

| Perk | Status | Notes |
|---|---|---|
| Dolphin Dive (`specialty_jumpdive`) | **Registered but not granted** | The repository perk-table overlay retains the hidden perk for bookkeeping and future experiments. It is not applied because IW5 binds it to sprint-jump, replacing normal corner jump shots rather than requiring a Black Ops-style sprint-crouch input. |

## Tier Two

| Perk | Modification | Notes |
|---|---|---|
| Quickdraw | **Knife Runner component** | Retains its stock behavior. It must be originally selected alongside the other Knife Runner requirements; receiving Quickdraw later cannot activate the build. |
| Blast Shield | **Takes 25% explosive damage; deals 1.50× non-killstreak explosive damage** | Replaces IW5's stock `0.45` incoming-damage scalar with `0.25`. Its Danger Close-style outgoing multiplier applies globally to launchers, underbarrel grenade launchers, grenades, C4, Claymores, and other explosive equipment while excluding killstreak weapons and self-damage. Existing weapon-specific multipliers compose multiplicatively. Configure the offensive scalar with `fun_mode_blast_shield_explosive_damage_multiplier`. |
| Hardline | Stock | No direct changes. Its normal one-point Specialist cost reduction is respected by the custom Specialist checks. |
| Assassin | **Partially countered by custom intelligence streaks** | The actual Advanced UAV reveals Assassin users globally as ordinary red dots while preserving protection from directional arrows. Recon Pulse can apply the real Recon Drone tag to Assassin users within its radius. Ordinary and naturally stacked UAVs remain stock. |
| Overkill | **Shotgun proficiency interaction** | If either equipped weapon is a shotgun, the human player's loadout receives both Range and Damage proficiencies. This includes an Overkill secondary shotgun. |

## Tier Three

| Perk | Modification | Notes |
|---|---|---|
| Marksman | Stock | No direct changes. |
| Stalker | Stock | No direct changes. |
| SitRep | Stock | No direct changes. |
| Steady Aim | Stock | No direct changes. |
| Dead Silence | **Knife Runner component** | Retains its stock behavior, including suppressing Bot Warfare's movement-hearing detection. It must be originally selected alongside the other Knife Runner requirements. |

## Deathstreak Interactions

| Deathstreak | Modification | Notes |
|---|---|---|
| Juiced | **10-second duration; Knife Runner component** | Extends the stock seven-second effect to **10 seconds** while retaining its **1.25×** movement scalar, timer HUD, and normal early cancellation. Juiced must also be selected on the original loadout alongside the other Knife Runner requirements, although its effect does not need to be active for that build. |

## Specialist Bonus Systems

These are Specialist-wide rewards rather than modifications to one selectable
perk. They are kept here because they determine how the complete perk package
behaves after it is granted or genuinely earned.

| Perk / system | Modification | Notes |
|---|---|---|
| Fun Mode super-class package | **Grants every base perk, its Pro mapping, Marathon, and defensive resistances** | Human custom classes 13–15 receive the package and unlimited sprint in private matches. Dedicated servers restrict all package benefits to GUIDs configured outside the repository. Incoming melee and `MOD_PROJECTILE` damage are multiplied by **0.50** after normal damage processing; rocket splash remains unchanged. The package also grants the stock hidden Specialist bonuses and Impact proficiency. Permissioned non-killstreak weapon kill modes are separate from this package and can apply their selected effect to melee and Throwing Knife kills. |
| Survival Reimagined Specialist package | **Reapplies the Fun Mode package** | Human survivors receive the same package after Survival finishes rebuilding their spawn loadout. |
| Specialist multishot | **20% chance to duplicate final firearm damage** | Consumes no additional ammunition. Shotgun pellets and same-frame penetration hits share one roll. |
| Specialist magazine refill | **Restores 25% of the killing firearm's magazine** | Rounds to a whole round and respects clip capacity. If another percentage refill applies, the strongest rule wins instead of stacking. |
| Post-Specialist rewards | **Five-second team UAV and one random killstreak every third additional kill** | The UAV retains its supported Fun Mode class requirement. Human random-streak recipients must use classes 13-15 and pass the existing Fun Mode GUID rule on dedicated servers; bots bypass class and GUID restrictions. Every recipient must run Specialist and genuinely earn its full bonus. The random streak enters IW5's native extra-reward queue and excludes MOAB and Specialist perks. Assault and Recon Juggernaut rewards activate their Predator Swarm and Death's Dance replacements respectively. Additional kills reset on death. Set `fun_mode_post_specialist_random_streak_enable 0` before map load to retain only the UAV reward. |
| Specialist movement composition | **Preserves stronger active movement effects** | Applying Specialist Lightweight does not overwrite an active Juiced 1.25× movement scalar. Extreme Conditioning and other custom movement modifiers continue composing through the central movement calculation. |

## Source of Truth

Specialist eligibility, full-perk grants, Survival reapplication, and
post-Specialist rewards are defined in
[`gsc/specialist_system.gsc`](../gsc/specialist_system.gsc). Movement
composition and loadout-driven perk application are defined in
[`gsc/player_movement.gsc`](../gsc/player_movement.gsc), while Knife Runner's
loadout state and protection are defined in
[`gsc/knife_runner.gsc`](../gsc/knife_runner.gsc). Expanded Scavenger behavior is
defined in [`gsc/scavenger.gsc`](../gsc/scavenger.gsc), while Specialist
magazine restoration is defined in
[`gsc/kill_ammo_refills.gsc`](../gsc/kill_ammo_refills.gsc). Blast Shield
damage rules, Specialist multishot, and super-class damage resistance live in
[`gsc/combat_damage_modifiers.gsc`](../gsc/combat_damage_modifiers.gsc).
Assassin
interactions with the actual Advanced UAV and Recon Pulse are defined in
[`gsc/advanced_uav_tuning.gsc`](../gsc/advanced_uav_tuning.gsc) and
[`gsc/recon_drone_pulse.gsc`](../gsc/recon_drone_pulse.gsc). Active Scavenger
configuration overrides are stored in [`players/normal.cfg`](../players/normal.cfg) and
[`players/hard.cfg`](../players/hard.cfg). When perk behavior changes, update
this document in the same commit.
