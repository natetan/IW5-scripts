# Survival Reimagined

This document records how [LastDemon99's IW5 Survival Reimagined](https://github.com/LastDemon99/IW5-Survival-Reimagined) fits into this custom-script repository. Survival Reimagined is an external mod and is not vendored here.

## References

- [Official GitHub repository](https://github.com/LastDemon99/IW5-Survival-Reimagined)
- [Upstream README and installation instructions](https://github.com/LastDemon99/IW5-Survival-Reimagined/blob/main/README.md)
- [Releases and downloads](https://github.com/LastDemon99/IW5-Survival-Reimagined/releases)
- [IW5 Bot Warfare prerequisite](https://github.com/ineedbots/iw5_bot_warfare)
- [Original Plutonium forum post](https://forum.plutonium.pw/topic/32159/pre-release-iw5-survival-reimagined)

## What the mod does

Survival Reimagined recreates the MW3 Spec Ops Survival experience for Plutonium IW5. Its notable features include:

- unlimited enemy waves;
- support for multiplayer maps rather than only the original Survival maps;
- configurable human-survivor slots through `survival_survivors_limit`;
- weapon, equipment, and air-support armories;
- custom enemy types, enemy killstreaks, difficulty scaling, armor, money, and wave logic;
- ammunition that is tracked independently of weapon attachments;
- dropped weapons that retain their upgrades;
- the ability to drop a weapon for an ally with `H`;
- cooperative play, with five survivors recommended by the upstream project.

IW5 Bot Warfare is a prerequisite, but Survival Reimagined supplies substantial Survival-specific bot, damage, loadout, armory, and gametype logic of its own.

## Important implementation details

The mod identifies itself with the custom gametype name `survival`, so scripts can detect it with:

```c
level.gameType == "survival"
```

Survival is not a normal multiplayer match with waves placed on top. Its recipe disables the ordinary custom-class, perk, and killstreak-package systems, while the mod rebuilds player loadouts and perks through its own survivor handler after each spawn. It also replaces or bypasses a number of stock multiplayer functions.

This distinction matters when extending it: a feature that only runs while selecting or spawning with an ordinary multiplayer class may never run in Survival, and a perk granted too early can be removed when the Survival handler rebuilds the survivor's loadout.

## Interaction with `fun_mode.gsc`

The local [`fun_mode.gsc`](../gsc/fun_mode.gsc) detects the `survival` gametype and waits briefly after the mod's spawn processing before applying the Fun Mode Specialist bundle to living human survivors on the Allies team. The delay lets Survival finish rebuilding the player's loadout first.

The Survival branch currently provides:

- the full standard and pro-perk Fun Mode bundle;
- Specialist-only bonuses used by Fun Mode;
- the added Impact proficiency and shotgun Damage proficiency;
- restoration of Juiced movement when applicable;
- restoration of active kill-momentum movement stacks after the spawn setup;
- Fun Mode's delayed Blind Eye handling after spawn protection.

The branch is controlled by this dvar, which defaults to enabled:

```text
fun_mode_survival_specialist_bonus 1
```

Set it to `0` before loading the match if the intended Survival perk and armory progression should remain untouched. Because the bundle grants perks for free, leaving it enabled makes perk purchases in the Survival armory largely redundant.

Other globally registered Fun Mode systems can also execute in Survival:

- Quick Fix healing and overhealth;
- kill-momentum movement speed;
- the global Blast Shield explosive-damage adjustment;
- the disabled killstreak spawn shield;
- general safety guards and callbacks installed by Fun Mode.

Quick Fix and kill momentum are registered for players generally, so Survival AI that emits the same kill notifications can also receive those effects. The Survival-only Specialist bundle itself is deliberately restricted to human Allied survivors.

Some Fun Mode features should not be assumed to transfer:

- The post-Specialist UAV reward requires a genuine multiplayer Specialist package, its adrenaline threshold, and the normal `all_perks_bonus` state. Survival disables that package system, so the synthetic Survival bundle does not qualify.
- Survival has its own ammunition and equipment systems, so the multiplayer Scavenger replacement may be irrelevant or may not behave identically there.
- The synthetic bundle grants perk effects but does not recreate every piece of the stock Specialist presentation, such as the normal earned-bonus HUD state.
- Survival or a future mod update may replace the same stock callbacks as a local script. Re-test these integrations after updating the mod.

## Local private-match quickstart

These steps follow the upstream README's private-match flow, with the local paths made explicit.

1. Download a release from the [Survival Reimagined releases page](https://github.com/LastDemon99/IW5-Survival-Reimagined/releases).
2. Press `Windows+R`, enter `%LOCALAPPDATA%\Plutonium\storage\iw5`, and extract the downloaded archive there. The installed mod should end up at `%LOCALAPPDATA%\Plutonium\storage\iw5\mods\survival`.
3. Install the latest scripts from this repository before launching the match:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File ".\install_game_scripts.ps1"
   ```

4. Launch Plutonium IW5 and enter this in the console:

   ```text
   loadmod survival
   ```

5. Open **Private Match**, then **Game Setup**.
6. Choose **Load Recipe From Disk**, select `survival_normal`, and confirm with **OK**.
7. Press `Esc` to return to the lobby and choose **Start Game**.

The installation also supplies `survival_easy` and `survival_hard` recipes when a different difficulty is wanted.

## Playing with friends

Every player needs Survival Reimagined installed. Host a private match, then have friends connect through the console with:

```text
connect YOUR_IP
```

If direct connectivity is unavailable, the upstream README suggests using Radmin VPN and connecting through the host's Radmin address. Treat it as an optional networking workaround, not as part of the mod itself.

## Dedicated-server notes

The upstream README describes dedicated-server setup as an advanced path:

1. Extract the mod into the server's IW5 storage layout.
2. Copy the required `.ff` files from `mods\survival` into the relevant storage and server `zone` directories, backing up `localized_code_post_gfx_mp.ff` before replacing it.
3. Configure the server to load a Survival recipe and map, for example:

   ```text
   set sv_maprotation "dsr survival map mp_dome"
   seta fs_game "mods/survival"
   ```

Consult the current [upstream README](https://github.com/LastDemon99/IW5-Survival-Reimagined/blob/main/README.md) before doing this because release packaging and required fastfiles can change.
