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

## Tier Two

| Perk | Modification | Notes |
|---|---|---|
| Quickdraw | **Knife Runner component** | Retains its stock behavior. It must be originally selected alongside the other Knife Runner requirements; receiving Quickdraw later cannot activate the build. |
| Blast Shield | **Takes 25% of normal explosive damage** | Replaces IW5's stock `0.45` damage scalar with `0.25`, increasing explosive resistance while the perk is active. |
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
| Fun Mode super-class package | **Grants every base perk, its Pro mapping, and Marathon** | Human custom classes 13–15 receive the package and unlimited sprint in private matches. Dedicated servers restrict both to GUIDs configured outside the repository. The package also grants the stock hidden Specialist bonuses and Impact proficiency. |
| Survival Reimagined Specialist package | **Reapplies the Fun Mode package** | Human survivors receive the same package after Survival finishes rebuilding their spawn loadout. |
| Specialist multishot | **20% chance to duplicate final firearm damage** | Consumes no additional ammunition. Shotgun pellets and same-frame penetration hits share one roll. |
| Specialist magazine refill | **Restores 25% of the killing firearm's magazine** | Rounds to a whole round and respects clip capacity. If another percentage refill applies, the strongest rule wins instead of stacking. |
| Post-Specialist rewards | **Five-second team UAV and one random killstreak every third additional kill** | The UAV retains its supported Fun Mode class requirement. Human random-streak recipients must use classes 13-15 and pass the existing Fun Mode GUID rule on dedicated servers; bots bypass class and GUID restrictions. Every recipient must run Specialist and genuinely earn its full bonus. The random streak enters IW5's native extra-reward queue and excludes MOAB and Specialist perks. An Assault Juggernaut reward activates its Predator Swarm replacement; Recon Juggernaut retains its claimable care package. Additional kills reset on death. Set `fun_mode_post_specialist_random_streak_enable 0` before map load to retain only the UAV reward. |
| Specialist movement composition | **Preserves stronger active movement effects** | Applying Specialist Lightweight does not overwrite an active Juiced 1.25× movement scalar. Extreme Conditioning and other custom movement modifiers continue composing through the central movement calculation. |

## Source of Truth

Most perk changes and Specialist behavior are defined in
[`gsc/fun_mode.gsc`](../gsc/fun_mode.gsc). Assassin interactions with the
actual Advanced UAV and Recon Pulse are defined in
[`gsc/advanced_uav_tuning.gsc`](../gsc/advanced_uav_tuning.gsc) and
[`gsc/recon_drone_pulse.gsc`](../gsc/recon_drone_pulse.gsc). Active Scavenger
configuration is stored in [`players/normal.cfg`](../players/normal.cfg) and
[`players/hard.cfg`](../players/hard.cfg). When perk behavior changes, update
this document in the same commit.
