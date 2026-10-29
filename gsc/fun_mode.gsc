#include maps\mp\_utility;

/*
    Fun Mode - IW5 / Plutonium

    Features:
    - Human players using custom classes 13-15 receive the full Specialist
      perk set, its Pro perk mappings, the extra Specialist bonuses, and the
      Impact weapon proficiency.
    - Gives every human player the Range and Damage proficiencies whenever
      either loadout weapon is a shotgun, including Overkill secondaries.
    - In Survival Reimagined, where custom classes and changed-kit events are
      disabled, human survivors receive that same Fun Mode bonus after the
      Survival mod finishes rebuilding their spawn loadout.
    - Replaces the stock Scavenger handler with configurable MW2-style
      resupply for secondary weapons, lethal equipment, tactical equipment,
      standalone launchers, and underbarrel grenade launchers.
    - Makes Scavenger bags collectible when only equipment or launcher ammo
      needs replenishing, including two-item tactical and tube capacities.
	- Re-arms the C4 offhand weapon before a Scavenger refill so newly thrown
	  charges enter IW5's normal ownership, damage, and detonator tracking.
    - Restores one Throwing Knife after a Throwing Knife kill for every player.
    - Guards Recon Drone range checks against maps with missing or malformed
      remote-UAV height metadata, preventing a per-frame runtime-error loop.
    - Guards destructible map objects against missing sound aliases so a
      broken destruction sound cannot generate a script runtime error.
    - Leaves malformed custom-map animated props static when their model has
      no registered animation metadata, while preserving valid animations.
    - Restores stock missile-attractor defaults when helicopter initialization
      leaves them undefined, preventing Osprey creation runtime errors.
    - Globally strengthens Blast Shield so its users take 25 percent of normal
      explosive damage instead of the stock 45 percent. It also acts like
      MW2 Danger Close, multiplying the user's outgoing non-killstreak
      explosive damage by 1.5.
    - Multiplies Javelin damage by ten against players while preserving its
      stock blast radius and earlier damage modifiers. Also doubles damage
      from bolt-action sniper rifles, the Barrett, the AS50, the CM901, the
      Desert Eagle, and the .44 Magnum, and triples MP412 damage.
    - Restores half of the equipped magazine after an MP412 or Desert Eagle
      kill, rounding odd capacities up and respecting the normal clip cap.
    - Reloads one Javelin missile after a Javelin kill, including delayed kills
      that occur after the player has switched back to another weapon.
    - Triples underbarrel grenade-launcher damage and restores one loaded tube
      round after a kill, capped by the launcher's clip capacity.
    - After genuinely earning the full Specialist Bonus, every firearm kill
      restores 25 percent of that weapon's magazine, rounded to the nearest
      whole round and capped at its normal clip capacity.
    - After genuinely earning the full Specialist Bonus, firearm shots have a
      configurable chance to deal a second copy of their final bullet damage
      without consuming another round. All pellets and penetrations resolved
      in the same server frame share one roll so shotguns do not roll once per
      pellet.
    - Gives the AA-12 that same 25-percent magazine refill on every kill even
      without the full Specialist Bonus.
    - Doubles player damage from the SPAS-12, KSG 12, and AA-12, gives the
      USAS-12 a 1.5 multiplier, and gives the attachment-free Model 1887
      quintuple damage.
      Silenced shotguns instead receive dedicated multipliers: quintuple damage
      for the SPAS-12 and KSG 12 and triple damage for the AA-12, USAS-12, and
      Striker. Attachment combinations, camos, and reticles remain supported.
    - Gives all players two-stage Quick Fix healing: a strong recovery burst
      below normal health, followed by non-regenerating overhealth up to a
      configurable percentage of their normal maximum. A progressively
      stronger yellow Ballistic Vest-style vignette indicates overhealth.
    - Preserves Juiced's movement boost when Fun Mode grants Specialist
      Lightweight during the same spawn sequence.
    - Restores 100-percent weapon mobility while any sniper rifle is drawn,
      matching the normal SMG mobility tier while preserving other bonuses.
    - Gives Extreme Conditioning a configurable sprint-only speed multiplier
      that composes with other movement effects without changing walking speed.
      Players who originally select Extreme Conditioning and authorized Fun
      Mode super classes also receive IW5's hidden Marathon perk, registered
      by the repository's perk-table overlay.
    - Activates Knife Runner when a human loadout combines Extreme
      Conditioning, Quickdraw, Dead Silence, Throwing Knife, Tactical
      Insertion, Juiced, and either a Tactical Knife handgun or Akimbo USP
      .45s. Drawing that sidearm raises active sprint speed to 1.5. Melee and
      Throwing Knife kills grant two seconds of damage immunity. A
      tenths-of-a-second HUD countdown shows the remaining protected time and
      refreshes after another qualifying kill. A centered activation message
      is shown at most once per life. The build removes its primary, empties
      its sidearm, and disables battlefield weapon pickup interactions.
    - Restores 100-percent weapon mobility while a standard handgun is drawn,
      instead of retaining the slowest carried primary weapon's movement
      penalty. Other movement bonuses continue to compose normally.
    - Gives all players brief, escalating kill momentum: consecutive kills
      refresh the timer and raise movement speed to a conservative cap, then
      momentum decays one stack at a time instead of disappearing at once.
    - Rewards every third kill after genuinely earning Specialist on Fun Mode
      classes with a refreshable five-second UAV for the player's team. The
      random normal killstreak reward is GUID-restricted for human classes
      13-15 on dedicated servers, while Specialist bots receive it without a
      class or GUID restriction.
    - Gives authorized Fun Mode super classes 50 percent resistance to melee
      damage and direct projectile impacts. Rocket splash remains unchanged.
    - Supports permissioned per-player non-killstreak weapon modes: a lethal
      simultaneous pulse, a nearest-target sequential kill chain, or an
      on-hit splash pool divided among nearby secondary targets. Melee and
      Throwing Knives use the same selected mode as other eligible weapons.
    - Disables MW3's post-spawn killstreak damage cap for more lethal,
      MW2-style player-controlled streaks.
    - Tunes automated Reaper missile damage so the autonomous aircraft remains
      worthy of the nine-kill slot.
    - Replaces the Recon Juggernaut package with stackable Death's Dance
      charges that prevent one fatal hit and reward a recovery kill with an
      owner-safe explosion and full Ballistic Vest.
    - Assists team changes in full 9v9 bot lobbies by temporarily removing a
      destination-team bot, then restoring the configured fill target so Bot
      Warfare replaces it on the team the human left.

    MW3 custom-class numbers shown in the UI are 1-based.
    Classes 13-15 map to internal class indices 12-14.
    In private matches, classes 13-15 always receive their automatic
    super-class bonuses. On dedicated servers, those bonuses are restricted
    to GUIDs listed in fun_mode_super_class_guids; an empty allowlist grants
    them to nobody.
    Most optional behavior is controlled through the fun_mode_* dvars below.
*/

Main()
{
    SetDvarIfNotInitialized("fun_mode_enable", 1);

    // Keep startup deterministic: feature modules register hooks and dvars here.
    scripts\quick_fix::Configure();
    scripts\team_switch_assist::Configure();
    scripts\remote_uav_tracking_fix::Configure();
    scripts\destructible_sound_fix::Configure();
    scripts\animated_models_fix::Configure();
    scripts\scavenger::Configure();
    scripts\kill_ammo_refills::Configure();
    scripts\weapon_damage_multipliers::Configure();
    scripts\kill_modes::Configure();
    scripts\combat_damage_modifiers::Configure();
    scripts\specialist_system::Configure();
    scripts\knife_runner::Configure();
    scripts\player_movement::Configure();

    /*
        _escortairdrop::createAirship passes these values directly to
        Missile_CreateAttractorEnt(). Some map or mod initialization paths
        leave them undefined even though an Osprey can still be requested.
    */
    if (!IsDefined(level.heli_attract_strength))
    {
        level.heli_attract_strength = 1000.0;
    }

    if (!IsDefined(level.heli_attract_range))
    {
        level.heli_attract_range = 4096.0;
    }

}

Init()
{
    if (!GetDvarInt("fun_mode_enable"))
    {
        return;
    }

    scripts\combat_damage_modifiers::Initialize();
    scripts\specialist_system::Initialize();

    /*
        Chain IW5's game-mode damage modifier instead of replacing the full
        player-damage callback. This remains compatible with Bot Warfare and
        preserves stock match-rule damage scaling and vampirism behavior.
    */
    level.fun_mode_previous_modify_player_damage = level.modifyPlayerDamage;
    level.modifyPlayerDamage = ::ModifyPlayerDamageForFunMode;

    level thread OnPlayerConnect();
}

ModifyPlayerDamageForFunMode(
    victim,
    attacker,
    damage,
    meansOfDeath,
    weapon,
    point,
    direction,
    hitLocation
)
{
    if (
        IsDefined(attacker) &&
        IsPlayer(attacker) &&
        attacker != victim &&
        IsDefined(weapon)
    )
    {
        attacker.fun_mode_last_damage_weapon = weapon;
        attacker.fun_mode_last_damage_means = meansOfDeath;
    }

    if (IsDefined(level.fun_mode_previous_modify_player_damage))
    {
        damage = [[level.fun_mode_previous_modify_player_damage]](
            victim,
            attacker,
            damage,
            meansOfDeath,
            weapon,
            point,
            direction,
            hitLocation
        );
    }

    if (
        IsDefined(victim) &&
        IsPlayer(victim) &&
        IsDefined(victim.fun_mode_deaths_dance_explosion_active) &&
        victim.fun_mode_deaths_dance_explosion_active
    )
    {
        return 0;
    }

    if (
        IsDefined(victim) &&
        IsPlayer(victim) &&
        IsDefined(victim.fun_mode_knife_runner_invulnerable_until) &&
        victim.fun_mode_knife_runner_invulnerable_until > GetTime()
    )
    {
        return 0;
    }

    // Synthetic kill-mode hops provide their final damage directly. Skip Fun
    // Mode's offensive multipliers so chain damage is not scaled twice and
    // virus lethality is not weapon-dependent; native target defenses remain.
    isKillModeDamage = (
        IsDefined(attacker) &&
        IsPlayer(attacker) &&
        IsDefined(attacker.fun_mode_kill_mode_damage_active) &&
        attacker.fun_mode_kill_mode_damage_active
    );

    damage = scripts\combat_damage_modifiers::RestoreMatchStartExplosiveDamage(
        damage,
        meansOfDeath
    );

    weaponDamageMultiplier = 1.0;

    if (!isKillModeDamage)
    {
        weaponDamageMultiplier = scripts\weapon_damage_multipliers::GetMultiplier(
            weapon,
            meansOfDeath
        );
    }

    if (weaponDamageMultiplier != 1.0)
    {
        damage = Int(damage * weaponDamageMultiplier);
    }

    dangerCloseDamageMultiplier = 1.0;

    if (!isKillModeDamage)
    {
        dangerCloseDamageMultiplier = scripts\combat_damage_modifiers::GetDangerCloseMultiplier(
            victim,
            attacker,
            weapon,
            meansOfDeath
        );
    }

    if (dangerCloseDamageMultiplier != 1.0)
    {
        damage = Int(damage * dangerCloseDamageMultiplier);
    }

    multishotDamageMultiplier = 1.0;

    if (!isKillModeDamage)
    {
        multishotDamageMultiplier = scripts\combat_damage_modifiers::GetMultishotMultiplier(
            attacker,
            weapon,
            meansOfDeath
        );
    }

    if (multishotDamageMultiplier != 1.0)
    {
        damage = Int(damage * multishotDamageMultiplier);
    }

    incomingDamageMultiplier = scripts\combat_damage_modifiers::GetIncomingMultiplier(
        victim,
        meansOfDeath
    );

    if (incomingDamageMultiplier != 1.0)
    {
        damage = Int(damage * incomingDamageMultiplier);
    }

    damage = scripts\deaths_dance::PreventFatalDamage(victim, damage);

    if (
        scripts\kill_modes::ShouldTrigger(
            victim,
            attacker,
            damage,
            weapon,
            meansOfDeath
        )
    )
    {
        killModeOrigin = victim.origin + (0, 0, 40);

        if (attacker.fun_mode_kill_mode == "splash")
        {
            attacker thread scripts\kill_modes::ApplySplash(
                victim,
                killModeOrigin,
                damage,
                weapon,
                meansOfDeath
            );
        }
        else
        {
            attacker thread scripts\kill_modes::ApplyAfterDamage(
                victim,
                killModeOrigin,
                damage,
                weapon,
                meansOfDeath,
                attacker.fun_mode_kill_mode
            );
        }
    }

    return damage;
}

OnPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);

        player scripts\quick_fix::OnPlayerConnected();
        player scripts\player_movement::OnPlayerConnected();
        player scripts\kill_ammo_refills::OnPlayerConnected();
        player scripts\knife_runner::OnPlayerConnected();
        player scripts\deaths_dance::OnPlayerConnected();

        if (player IsBotPlayer())
        {
            continue;
        }

        player scripts\player_movement::OnHumanPlayerConnected();
        player scripts\knife_runner::OnHumanPlayerConnected();
        player scripts\scavenger::OnPlayerConnected();
        player scripts\team_switch_assist::OnPlayerConnected();
        player scripts\specialist_system::OnHumanPlayerConnected();
    }
}

IsBotPlayer()
{
    return IsDefined(self.pers["isBot"]) && self.pers["isBot"];
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
