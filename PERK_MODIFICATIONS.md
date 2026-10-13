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
| Extreme Conditioning | **1.10× sprint-speed multiplier** | Applies only while actively sprinting with Extreme Conditioning. It composes with other movement effects and does not change walking speed or the underlying stamina duration. |
| Scavenger | **Expanded resupply** | Bags can replenish secondary ammunition, lethal equipment, tactical equipment, underbarrel grenade launchers, and standalone launchers. C4 is re-armed correctly before its charge is restored. |

The repository's `normal.cfg` and `hard.cfg` enable every expanded Scavenger
category, including standalone launchers. Flashbangs and concussion grenades
retain a two-item cap; supported underbarrel tubes retain a two-round reserve
cap. Primary-weapon ammunition still follows the normal MW3 Scavenger path.

## Tier Two

| Perk | Modification | Notes |
|---|---|---|
| Quickdraw | Stock | No direct changes. |
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
| Dead Silence | Stock | No direct changes. |

## Specialist Bonus Systems

These are Specialist-wide rewards rather than modifications to one selectable
perk. They are kept here because they determine how the complete perk package
behaves after it is granted or genuinely earned.

| Perk / system | Modification | Notes |
|---|---|---|
| Fun Mode super-class package | **Grants every base perk and its Pro mapping** | Human custom classes 13–15 receive the package in private matches. Dedicated servers restrict it to GUIDs configured outside the repository. The package also grants the stock hidden Specialist bonuses and Impact proficiency. |
| Survival Reimagined Specialist package | **Reapplies the Fun Mode package** | Human survivors receive the same package after Survival finishes rebuilding their spawn loadout. |
| Specialist multishot | **20% chance to duplicate final firearm damage** | Consumes no additional ammunition. Shotgun pellets and same-frame penetration hits share one roll. |
| Specialist magazine refill | **Restores 25% of the killing firearm's magazine** | Rounds to a whole round and respects clip capacity. If another percentage refill applies, the strongest rule wins instead of stacking. |
| Post-Specialist UAV reward | **Five-second team UAV every third additional kill** | Requires genuinely earning the full Specialist Bonus on a supported Fun Mode class. Additional kills reset on death. |
| Specialist movement composition | **Preserves stronger active movement effects** | Applying Specialist Lightweight does not overwrite an active Juiced 1.25× movement scalar. Extreme Conditioning and other custom movement modifiers continue composing through the central movement calculation. |

## Related Systems That Are Not Perks

Quick Fix healing, kill momentum, weapon-specific damage multipliers, and
heavy-sniper movement normalization apply independently of a player's chosen
perk package. They are intentionally excluded from the tier tables. See
[`WEAPON_MODIFICATIONS.md`](./WEAPON_MODIFICATIONS.md) for weapon-specific
rules.

## Source of Truth

Most perk changes and Specialist behavior are defined in
[`gsc/fun_mode.gsc`](./gsc/fun_mode.gsc). Assassin interactions with the
actual Advanced UAV and Recon Pulse are defined in
[`gsc/advanced_uav_tuning.gsc`](./gsc/advanced_uav_tuning.gsc) and
[`gsc/recon_drone_pulse.gsc`](./gsc/recon_drone_pulse.gsc). Active Scavenger
configuration is stored in [`players/normal.cfg`](./players/normal.cfg) and
[`players/hard.cfg`](./players/hard.cfg). When perk behavior changes, update
this document in the same commit.
