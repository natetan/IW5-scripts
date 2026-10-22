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
    - Guards Recon Drone range checks against maps with missing or malformed
      remote-UAV height metadata, preventing a per-frame runtime-error loop.
    - Guards destructible map objects against missing sound aliases so a
      broken destruction sound cannot generate a script runtime error.
    - Restores stock missile-attractor defaults when helicopter initialization
      leaves them undefined, preventing Osprey creation runtime errors.
    - Globally strengthens Blast Shield so its users take 25 percent of normal
      explosive damage instead of the stock 45 percent.
    - Multiplies Javelin damage by ten against players while preserving its
      stock blast radius and earlier damage modifiers. Also doubles damage
      from bolt-action sniper rifles, the Barrett, the AS50, the CM901, and
      the Desert Eagle, and triples MP412 damage.
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
    - Disables MW3's post-spawn killstreak damage cap for more lethal,
      MW2-style player-controlled streaks.
    - Tunes automated Reaper missile damage so the autonomous aircraft remains
      worthy of the nine-kill slot.
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
    SetDvarIfNotInitialized("fun_mode_specialist_class_index", 14);
    SetDvarIfNotInitialized("fun_mode_super_class_guids", "");
    SetDvarIfNotInitialized("fun_mode_survival_specialist_bonus", 1);
    SetDvarIfNotInitialized("fun_mode_team_switch_assist", 1);
    SetDvarIfNotInitialized("fun_mode_team_switch_fill", 18);
    SetDvarIfNotInitialized("fun_mode_blast_shield_damage", 0.25);
    SetDvarIfNotInitialized("fun_mode_javelin_damage_multiplier", 10.0);
    SetDvarIfNotInitialized("fun_mode_noobtube_damage_multiplier", 3.0);
    SetDvarIfNotInitialized("fun_mode_reaper_damage_multiplier", 1.5);
    SetDvarIfNotInitialized("fun_mode_shotgun_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_1887_damage_multiplier", 5.0);
    SetDvarIfNotInitialized("fun_mode_usas_damage_multiplier", 1.5);
    SetDvarIfNotInitialized("fun_mode_silenced_shotgun_damage_multiplier", 5.0);
    SetDvarIfNotInitialized("fun_mode_silenced_auto_shotgun_damage_multiplier", 3.0);
    SetDvarIfNotInitialized("fun_mode_silenced_striker_damage_multiplier", 3.0);
    SetDvarIfNotInitialized("fun_mode_bolt_sniper_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_heavy_sniper_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_mp412_damage_multiplier", 3.0);
    SetDvarIfNotInitialized("fun_mode_cm901_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_desert_eagle_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_pistol_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_javelin_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_noobtube_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_mag_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_mag_refill_percent", 0.25);
    SetDvarIfNotInitialized("fun_mode_specialist_multishot_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_multishot_chance", 0.20);
    SetDvarIfNotInitialized("fun_mode_aa12_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_quick_fix_enable", 1);
    SetDvarIfNotInitialized("fun_mode_quick_fix_heal_percent", 0.25);
    SetDvarIfNotInitialized("fun_mode_quick_fix_overheal_percent", 0.10);
    SetDvarIfNotInitialized("fun_mode_quick_fix_max_percent", 2.00);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_enable", 1);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_duration", 1.50);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_start", 1.20);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_step", 0.025);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_max", 1.30);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_max_stacks", 5);
    SetDvarIfNotInitialized("fun_mode_sniper_mobility_enable", 1);
    SetDvarIfNotInitialized("fun_mode_sniper_mobility_target", 1.0);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_sprint_speed_enable", 1);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_sprint_speed_multiplier", 1.10);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_marathon_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_sprint_speed_multiplier", 1.50);
    SetDvarIfNotInitialized("fun_mode_knife_runner_invulnerability_seconds", 2.00);
    SetDvarIfNotInitialized("fun_mode_knife_runner_invulnerability_hud_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_message_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_message", "Knife Runner Enabled: 1.5x speed");
    SetDvarIfNotInitialized("fun_mode_pistol_mobility_enable", 1);
    SetDvarIfNotInitialized("fun_mode_pistol_mobility_target", 1.0);
    SetDvarIfNotInitialized("fun_mode_post_specialist_enable", 1);
    SetDvarIfNotInitialized("fun_mode_post_specialist_kills", 3);
    SetDvarIfNotInitialized("fun_mode_post_specialist_uav_duration", 5);
    SetDvarIfNotInitialized("fun_mode_post_specialist_random_streak_enable", 1);

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

    /*
        Configurable Scavenger behavior.

        These defaults keep the extra behavior conservative. Override them
        from normal.cfg / hard.cfg as desired.
    */
    SetDvarIfNotInitialized("fun_mode_scavenger_enable", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_secondary", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_lethal", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_tactical", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_launchers", 0);
    SetDvarIfNotInitialized("fun_mode_scavenger_noobtubes", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_noobtubes_max", 2);
    SetDvarIfNotInitialized("fun_mode_scavenger_debug", 0);

    /*
        Replace IW5's stock Scavenger pickup handler instead of trying to
        modify ammo after the stock handler has already completed.
    */
    ReplaceFunc(
        maps\mp\gametypes\_weapons::handleScavengerBagPickup,
        ::HandleScavengerBagPickupCustom
    );

	ReplaceFunc(
		maps\mp\killstreaks\_remoteuav::remoteuav_in_range,
		::RemoteUavInRangeGuarded
	);

    ReplaceFunc(
        common_scripts\_destructible::play_sound,
        ::DestructiblePlaySoundGuarded
    );
}

/*
    Some map destructible definitions reference an undefined, empty, or
    unavailable sound alias. The stock helper passes it directly to
    PlaySound(), which raises a runtime error. Preserve its positioned sound
    entity and cleanup behavior, but ignore aliases the current map did not
    load.
*/
DestructiblePlaySoundGuarded(soundAlias, tagName)
{
    if (
        !IsDefined(soundAlias) ||
        soundAlias == "" ||
        !SoundExists(soundAlias)
    )
    {
        return;
    }

    if (IsDefined(tagName))
    {
        soundOrigin = Spawn("script_origin", self GetTagOrigin(tagName));
        soundOrigin Hide();
        soundOrigin LinkTo(
            self,
            tagName,
            (0.0, 0.0, 0.0),
            (0.0, 0.0, 0.0)
        );
    }
    else
    {
        soundOrigin = Spawn("script_origin", (0.0, 0.0, 0.0));
        soundOrigin Hide();
        soundOrigin.origin = self.origin;
        soundOrigin.angles = self.angles;
        soundOrigin LinkTo(self);
    }

    soundOrigin PlaySound(soundAlias);
    wait 5.0;

    if (IsDefined(soundOrigin))
    {
        soundOrigin Delete();
    }
}

/*
	Preserve IW5's stock Recon Drone range behavior while tolerating maps that
	do not provide a usable remote_uav_range or airstrikeheight value.
*/
RemoteUavInRangeGuarded()
{
	inHeliProximity = (
		IsDefined(self.inheliproximity) &&
		self.inheliproximity
	);

	if (IsDefined(self.rangetrigger))
	{
		if (!self IsTouching(self.rangetrigger) && !inHeliProximity)
		{
			return 1;
		}

		return 0;
	}

	maxDistance = 12800;

	if (IsDefined(self.maxdistance))
	{
		maxDistance = self.maxdistance;
	}

	withinHeight = true;

	if (IsDefined(self.maxheight))
	{
		withinHeight = self.origin[2] < self.maxheight;
	}

	if (
		Distance2D(self.origin, level.mapcenter) < maxDistance &&
		withinHeight &&
		!inHeliProximity
	)
	{
		return 1;
	}

	return 0;
}

Init()
{
    if (!GetDvarInt("fun_mode_enable"))
    {
        return;
    }

    // Global Blast Shield resistance; IW5's stock value is 0.45.
    level.blastShieldMod = GetDvarFloat("fun_mode_blast_shield_damage");

    /*
        Disable MW3's post-spawn killstreak damage cap. This restores the
        more lethal MW2-style experience for player-controlled streaks such
        as the Reaper and Osprey Gunner. Temporary targeting protection from
        spawn Blind Eye remains handled separately by the stock game.
    */
    level.killstreakSpawnShield = 0;

    /*
        Chain IW5's game-mode damage modifier instead of replacing the full
        player-damage callback. This remains compatible with Bot Warfare and
        preserves stock match-rule damage scaling and vampirism behavior.
    */
    level.fun_mode_previous_modify_player_damage = level.modifyPlayerDamage;
    level.modifyPlayerDamage = ::ModifyPlayerDamageForFunMode;

    level.fun_mode_temporary_uav_expires = [];
    level.fun_mode_temporary_uav_running = [];

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
        IsDefined(victim.fun_mode_knife_runner_invulnerable_until) &&
        victim.fun_mode_knife_runner_invulnerable_until > GetTime()
    )
    {
        return 0;
    }

    damage = RestoreMatchStartExplosiveDamage(damage, meansOfDeath);

    weaponDamageMultiplier = GetFunModeWeaponDamageMultiplier(
        weapon,
        meansOfDeath
    );

    if (weaponDamageMultiplier != 1.0)
    {
        damage = Int(damage * weaponDamageMultiplier);
    }

    multishotDamageMultiplier = GetSpecialistMultishotDamageMultiplier(
        attacker,
        weapon,
        meansOfDeath
    );

    if (multishotDamageMultiplier != 1.0)
    {
        damage = Int(damage * multishotDamageMultiplier);
    }

    return damage;
}

/*
    Stock IW5 applies level.armorVestMod (0.08) to every explosive hit during
    the first 10 seconds after the opening countdown. Undo only that second,
    match-start application. Any earlier Blast Shield or Juggernaut reduction
    remains in the damage value and therefore stays effective.
*/
RestoreMatchStartExplosiveDamage(damage, meansOfDeath)
{
    if (GetDvarInt("fun_mode_match_start_explosive_protection_enable"))
    {
        return damage;
    }

    if (!IsExplosiveDamageMod(meansOfDeath))
    {
        return damage;
    }

    if (
        !IsDefined(level.gracePeriod) ||
        !IsDefined(level.inGracePeriod) ||
        10 - (level.gracePeriod - level.inGracePeriod) <= 0
    )
    {
        return damage;
    }

    if (!IsDefined(level.armorVestMod) || level.armorVestMod <= 0.0)
    {
        return damage;
    }

    return Int(damage / level.armorVestMod);
}

/*
    Model Specialist multishot as a duplicate of the bullet damage that IW5
    already resolved. This preserves the original shot's weapon attribution,
    hit location, penetration loss, and ammo use without asking MagicBullet()
    to synthesize unsupported hitscan weapon fire.

    A shotgun reports several pellet hits in one server frame. Cache the roll
    by attacker, weapon, and frame so the blast receives one decision instead
    of an independent roll for every pellet. The same behavior also preserves
    a proc across multiple victims hit by one penetrating bullet.
*/
GetSpecialistMultishotDamageMultiplier(attacker, weapon, meansOfDeath)
{
    if (
        !GetDvarInt("fun_mode_specialist_multishot_enable") ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsDefined(weapon) ||
        !IsSubStr(weapon, "iw5_") ||
        (
            meansOfDeath != "MOD_PISTOL_BULLET" &&
            meansOfDeath != "MOD_RIFLE_BULLET"
        ) ||
        !attacker HasEarnedFullSpecialistBonus()
    )
    {
        return 1.0;
    }

    currentFrame = GetTime();

    if (
        !IsDefined(attacker.fun_mode_multishot_frame) ||
        attacker.fun_mode_multishot_frame != currentFrame ||
        !IsDefined(attacker.fun_mode_multishot_weapon) ||
        attacker.fun_mode_multishot_weapon != weapon
    )
    {
        chance = GetDvarFloat("fun_mode_specialist_multishot_chance");

        if (chance < 0.0)
        {
            chance = 0.0;
        }
        else if (chance > 1.0)
        {
            chance = 1.0;
        }

        attacker.fun_mode_multishot_frame = currentFrame;
        attacker.fun_mode_multishot_weapon = weapon;
        attacker.fun_mode_multishot_proc = RandomFloat(1.0) < chance;
    }

    if (
        IsDefined(attacker.fun_mode_multishot_proc) &&
        attacker.fun_mode_multishot_proc
    )
    {
        return 2.0;
    }

    return 1.0;
}

/*
    Central registry for Fun Mode's weapon-specific damage buffs. Return 1.0
    for normal damage so new weapon rules can be added here without expanding
    the player-damage callback itself.
*/
GetFunModeWeaponDamageMultiplier(weapon, meansOfDeath)
{
    if (!IsDefined(weapon))
    {
        return 1.0;
    }

    if (weapon == "javelin_mp")
    {
        return GetDvarFloat("fun_mode_javelin_damage_multiplier");
    }

    if (weapon == "remote_mortar_missile_mp")
        return GetDvarFloat("fun_mode_reaper_damage_multiplier");

    if (IsScavengerNoobTube(weapon))
    {
        return GetDvarFloat("fun_mode_noobtube_damage_multiplier");
    }

    isBulletDamage = (
        meansOfDeath == "MOD_PISTOL_BULLET" ||
        meansOfDeath == "MOD_RIFLE_BULLET"
    );

    if (
        isBulletDamage &&
        (
            IsSubStr(weapon, "iw5_cheytac_mp") ||
            IsSubStr(weapon, "iw5_l96a1_mp") ||
            IsSubStr(weapon, "iw5_msr_mp")
        )
    )
    {
        return GetDvarFloat("fun_mode_bolt_sniper_damage_multiplier");
    }

    if (
        isBulletDamage &&
        (
            IsSubStr(weapon, "iw5_barrett_mp") ||
            IsSubStr(weapon, "iw5_as50_mp")
        )
    )
    {
        return GetDvarFloat("fun_mode_heavy_sniper_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsSubStr(weapon, "iw5_mp412_mp")
    )
    {
        return GetDvarFloat("fun_mode_mp412_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsSubStr(weapon, "iw5_cm901_mp")
    )
    {
        return GetDvarFloat("fun_mode_cm901_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsSubStr(weapon, "iw5_deserteagle_mp")
    )
    {
        return GetDvarFloat("fun_mode_desert_eagle_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsFunModeShotgun(weapon) &&
        IsSubStr(weapon, "_silencer")
    )
    {
        if (IsSubStr(weapon, "iw5_striker_mp"))
        {
            return GetDvarFloat("fun_mode_silenced_striker_damage_multiplier");
        }

        if (
            IsSubStr(weapon, "iw5_aa12_mp") ||
            IsSubStr(weapon, "iw5_usas12_mp")
        )
        {
            return GetDvarFloat("fun_mode_silenced_auto_shotgun_damage_multiplier");
        }

        return GetDvarFloat("fun_mode_silenced_shotgun_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsSubStr(weapon, "iw5_1887_mp")
    )
    {
        return GetDvarFloat("fun_mode_1887_damage_multiplier");
    }

    if (
        isBulletDamage &&
        IsSubStr(weapon, "iw5_usas12_mp")
    )
    {
        return GetDvarFloat("fun_mode_usas_damage_multiplier");
    }

    if (
        isBulletDamage &&
        (
            IsSubStr(weapon, "iw5_spas12_mp") ||
            IsSubStr(weapon, "iw5_ksg_mp") ||
            IsSubStr(weapon, "iw5_aa12_mp")
        )
    )
    {
        return GetDvarFloat("fun_mode_shotgun_damage_multiplier");
    }

    return 1.0;
}

IsFunModeShotgun(weapon)
{
    return (
        IsSubStr(weapon, "iw5_spas12_mp") ||
        IsSubStr(weapon, "iw5_aa12_mp") ||
        IsSubStr(weapon, "iw5_striker_mp") ||
        IsSubStr(weapon, "iw5_usas12_mp") ||
        IsSubStr(weapon, "iw5_ksg_mp")
    );
}

OnPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);

        player thread WatchQuickFix();
        player thread WatchQuickFixSpawns();
        player thread WatchKillMomentum();
        player thread WatchKillMomentumSpawns();
        player thread WatchExtremeConditioningSprintSpawns();
        player thread WatchWeaponMobilitySpawns();
        player thread WatchKillAmmoRefills();
        player thread WatchKnifeRunnerKills();

        if (player IsBotPlayer())
        {
            continue;
        }

        player thread WatchPlayerLoadout();
        player thread WatchKnifeRunnerInvulnerabilityHudDeaths();
        player thread WatchSurvivalFunModeSpawns();
        player thread WatchScavengerPickupEligibility();
        player thread WatchTeamSwitchMenu();
        player thread WatchPostSpecialistRewards();
        player thread WatchPostSpecialistSpawns();
    }
}

WatchKillAmmoRefills()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (!IsAlive(self) || !IsDefined(self.fun_mode_last_damage_weapon))
        {
            continue;
        }

        weapon = self.fun_mode_last_damage_weapon;

        if (
            GetDvarInt("fun_mode_javelin_kill_refill_enable") &&
            weapon == "javelin_mp"
        )
        {
            self RefillWeaponClipByRounds(weapon, 1);
        }

        if (
            GetDvarInt("fun_mode_noobtube_kill_refill_enable") &&
            IsScavengerNoobTube(weapon)
        )
        {
            // Underbarrel launchers consume their loaded clip directly. The
            // reserve-stock path used by Scavenger does not immediately make
            // another shot available, while the Specialist magazine-refill
            // path proves that restoring the tube clip does.
            self RefillWeaponClipByRounds(weapon, 1);
        }

        if (!IsSubStr(weapon, "iw5_"))
        {
            continue;
        }

        refillPercent = self GetKillRefillPercent(weapon);

        if (refillPercent > 0.0)
        {
            self RefillWeaponClipByPercent(weapon, refillPercent);
        }
    }
}

GetKillRefillPercent(weapon)
{
    refillPercent = 0.0;

    if (
        IsDefined(self.fun_mode_knife_runner_loadout) &&
        self.fun_mode_knife_runner_loadout &&
        IsKnifeRunnerWeapon(weapon)
    )
    {
        return refillPercent;
    }

    if (
        GetDvarInt("fun_mode_pistol_kill_refill_enable") &&
        IsHighPoweredPistol(weapon)
    )
    {
        refillPercent = 0.50;
    }

    standardRefillApplies = (
        (
            GetDvarInt("fun_mode_aa12_kill_refill_enable") &&
            IsSubStr(weapon, "iw5_aa12_mp")
        ) ||
        (
            GetDvarInt("fun_mode_specialist_mag_refill_enable") &&
            self HasEarnedFullSpecialistBonus()
        )
    );

    if (standardRefillApplies)
    {
        standardRefillPercent = GetDvarFloat(
            "fun_mode_specialist_mag_refill_percent"
        );

        if (standardRefillPercent > refillPercent)
        {
            refillPercent = standardRefillPercent;
        }
    }

    return refillPercent;
}

IsHighPoweredPistol(weapon)
{
    return (
        IsDefined(weapon) &&
        (
            IsSubStr(weapon, "iw5_mp412_mp") ||
            IsSubStr(weapon, "iw5_deserteagle_mp")
        )
    );
}

RefillWeaponClipByPercent(weapon, refillPercent)
{
    clipSize = WeaponClipSize(weapon);

    if (clipSize <= 0 || refillPercent <= 0)
    {
        return;
    }

    refillAmount = Int((clipSize * refillPercent) + 0.5);

    if (refillAmount < 1)
    {
        refillAmount = 1;
    }

    self RefillWeaponClipByRounds(weapon, refillAmount);
}

RefillWeaponClipByRounds(weapon, refillAmount)
{
    if (refillAmount <= 0)
    {
        return;
    }

    clipSize = WeaponClipSize(weapon);

    if (clipSize <= 0)
    {
        return;
    }

    clipAmmo = self GetWeaponAmmoClip(weapon);
    newClipAmmo = clipAmmo + refillAmount;

    if (newClipAmmo > clipSize)
    {
        newClipAmmo = clipSize;
    }

    if (newClipAmmo > clipAmmo)
    {
        self SetWeaponAmmoClip(weapon, newClipAmmo);
    }
}

RefillOwnedNoobTubeAmmo(refillAmount)
{
    if (refillAmount <= 0)
    {
        return;
    }

    maxAmmo = GetDvarInt("fun_mode_scavenger_noobtubes_max");
    allWeapons = self GetWeaponsListAll();

    foreach (weapon in allWeapons)
    {
        if (!IsScavengerNoobTube(weapon))
        {
            continue;
        }

        currentAmmo = self GetAmmoCount(weapon);

        if (currentAmmo >= maxAmmo)
        {
            return;
        }

        ammoToAdd = refillAmount;

        if (currentAmmo + ammoToAdd > maxAmmo)
        {
            ammoToAdd = maxAmmo - currentAmmo;
        }

        stockAmmo = self GetWeaponAmmoStock(weapon);
        self SetWeaponAmmoStock(weapon, stockAmmo + ammoToAdd);
        return;
    }
}

HasEarnedFullSpecialistBonus()
{
    if (
        !IsDefined(self.streaktype) ||
        self.streaktype != "specialist" ||
        !IsDefined(self.adrenaline) ||
        !IsDefined(self.pers["killstreaks"]) ||
        !IsDefined(self.pers["killstreaks"][4]) ||
        !IsDefined(self.pers["killstreaks"][4].streakname) ||
        self.pers["killstreaks"][4].streakname != "all_perks_bonus" ||
        !IsDefined(self.pers["killstreaks"][4].available) ||
        !self.pers["killstreaks"][4].available
    )
    {
        return false;
    }

    bonusCost = 8;

    if (self maps\mp\_utility::_hasperk("specialty_hardline"))
    {
        bonusCost--;
    }

    return self.adrenaline >= bonusCost;
}

IsSurvivalMode()
{
    return IsDefined(level.gameType) && level.gameType == "survival";
}

IsFunModeSuperClass()
{
    return (
        IsDefined(self.class_num) &&
        (
            self.class_num == 12 ||
            self.class_num == 13 ||
            self.class_num == 14
        )
    );
}

IsFunModeSuperClassOwner()
{
    if (!self IsFunModeSuperClass())
    {
        return false;
    }

    // Private matches retain the original Fun Mode behavior. Only dedicated
    // servers require an explicit player allowlist.
    if (!GetDvarInt("dedicated"))
    {
        return true;
    }

    playerGuid = self GetGuid() + "";
    allowedGuids = StrTok(GetDvar("fun_mode_super_class_guids"), ",");

    foreach (allowedGuid in allowedGuids)
    {
        if (allowedGuid == playerGuid)
        {
            return true;
        }
    }

    return false;
}

/*
    Survival Reimagined disables custom classes and replaces the stock class
    initializer. Its survivor handler clears and rebuilds perks on every spawn,
    so apply the Fun Mode bundle afterward instead of waiting for changed_kit.
*/
WatchSurvivalFunModeSpawns()
{
    self endon("disconnect");

    if (!IsSurvivalMode())
    {
        return;
    }

    for (;;)
    {
        self waittill("spawned_player");
        wait 0.25;

        if (
            !GetDvarInt("fun_mode_survival_specialist_bonus") ||
            !IsAlive(self) ||
            !IsDefined(self.pers["team"]) ||
            self.pers["team"] != "allies"
        )
        {
            continue;
        }

        self GiveFullSpecialistBonus();
        self RestoreJuicedMovementAfterSpecialist();
        self ApplyActiveKillMomentumSpeed();
        self thread RestoreFunModeBlindEyeAfterSpawnProtection();
    }
}

WatchPostSpecialistSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_real_specialist_bonus_seen = false;
        self.fun_mode_post_specialist_kills = 0;
    }
}

HasEarnedRealSpecialistBonus()
{
    if (
        !IsDefined(self.class_num) ||
        (
            self.class_num != 12 &&
            self.class_num != 13 &&
            self.class_num != 14
        ) ||
        !IsDefined(self.streaktype) ||
        self.streaktype != "specialist" ||
        !IsDefined(self.adrenaline) ||
        !IsDefined(self.pers["killstreaks"]) ||
        !IsDefined(self.pers["killstreaks"][4]) ||
        !IsDefined(self.pers["killstreaks"][4].streakname) ||
        self.pers["killstreaks"][4].streakname != "all_perks_bonus" ||
        !IsDefined(self.pers["killstreaks"][4].available) ||
        !self.pers["killstreaks"][4].available
    )
    {
        return false;
    }

    bonusCost = 8;

    if (self maps\mp\_utility::_hasperk("specialty_hardline"))
    {
        bonusCost--;
    }

    return self.adrenaline >= bonusCost;
}

GrantTemporaryTeamUAV(duration)
{
    if (
        !IsDefined(self.pers["team"]) ||
        (self.pers["team"] != "allies" && self.pers["team"] != "axis")
    )
    {
        return;
    }

    team = self.pers["team"];
    expiresAt = GetTime() + Int(duration * 1000);

    if (
        !IsDefined(level.fun_mode_temporary_uav_expires[team]) ||
        expiresAt > level.fun_mode_temporary_uav_expires[team]
    )
    {
        level.fun_mode_temporary_uav_expires[team] = expiresAt;
    }

    if (
        IsDefined(level.fun_mode_temporary_uav_running[team]) &&
        level.fun_mode_temporary_uav_running[team]
    )
    {
        return;
    }

    level.fun_mode_temporary_uav_running[team] = true;
    level thread RunTemporaryTeamUAV(team);
}

/*
    Register a hidden model as a real standard UAV. The stock UAV tracker then
    owns radar visibility, sweep timing, Counter-UAV interaction, and stacking
    with earned UAVs. Only this model and its active-UAV count are removed.
*/
RunTemporaryTeamUAV(team)
{
    level endon("game_ended");

    uav = Spawn("script_model", (0, 0, 0));
    uav.team = team;
    uav.value = 1;
    uav.uavtype = "standard";
    // Stock launchUAV() adds five seconds to every active same-team UAV.
    // Keep this synthetic model compatible with that stacking path.
    uav.timetoadd = 0;
    uav maps\mp\killstreaks\_uav::addUAVModel();
    uav maps\mp\killstreaks\_uav::addActiveUAV();
    level notify("uav_update");

    while (
        IsDefined(level.fun_mode_temporary_uav_expires[team]) &&
        GetTime() < level.fun_mode_temporary_uav_expires[team]
    )
    {
        wait 0.05;
    }

    uav maps\mp\killstreaks\_uav::removeActiveUAV();

    remainingModels = [];

    foreach (model in level.uavmodels[team])
    {
        if (!IsDefined(model) || model == uav)
        {
            continue;
        }

        remainingModels[remainingModels.size] = model;
    }

    level.uavmodels[team] = remainingModels;
    uav Delete();
    level.fun_mode_temporary_uav_running[team] = false;
    level notify("uav_update");
}

WatchPostSpecialistRewards()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        uavEligible = self HasEarnedRealSpecialistBonus();
        randomStreakEligible = (
            GetDvarInt("fun_mode_post_specialist_random_streak_enable") &&
            self CanReceiveRandomPostSpecialistKillstreak()
        );

        if (
            !GetDvarInt("fun_mode_post_specialist_enable") ||
            !IsAlive(self) ||
            (!uavEligible && !randomStreakEligible)
        )
        {
            self.fun_mode_real_specialist_bonus_seen = false;
            self.fun_mode_post_specialist_kills = 0;
            continue;
        }

        if (
            !IsDefined(self.fun_mode_real_specialist_bonus_seen) ||
            !self.fun_mode_real_specialist_bonus_seen
        )
        {
            self.fun_mode_real_specialist_bonus_seen = true;
            self.fun_mode_post_specialist_kills = 0;
            continue;
        }

        self.fun_mode_post_specialist_kills++;
        killsRequired = GetDvarInt("fun_mode_post_specialist_kills");

        if (killsRequired < 1)
        {
            killsRequired = 1;
        }

        if (self.fun_mode_post_specialist_kills < killsRequired)
        {
            continue;
        }

        self.fun_mode_post_specialist_kills = 0;

        if (uavEligible)
        {
            duration = GetDvarFloat("fun_mode_post_specialist_uav_duration");

            if (duration > 0)
            {
                self GrantTemporaryTeamUAV(duration);
            }
        }

        if (randomStreakEligible)
        {
            self GrantRandomPostSpecialistKillstreak();
        }
    }
}

CanReceiveRandomPostSpecialistKillstreak()
{
    if (!self HasEarnedFullSpecialistBonus())
    {
        return false;
    }

    // Bots may use any class, but still have to run Specialist and genuinely
    // earn its full bonus before post-bonus kills can grant random streaks.
    if (self IsBotPlayer())
    {
        return true;
    }

    // Reuse the established Fun Mode policy: classes 13-15 are unrestricted
    // in private matches and require the configured GUID on dedicated servers.
    return self IsFunModeSuperClassOwner();
}

GrantRandomPostSpecialistKillstreak()
{
    /*
        Use the stock gimme-reward path so the reward occupies slot zero and
        additional rewards queue behind it. Avoid MOAB, Specialist perks, and
        Juggernauts that would replace the player's active Specialist loadout.
    */
    rewardPool = [];
    rewardPool[rewardPool.size] = "uav";
    rewardPool[rewardPool.size] = "uav_support";
    rewardPool[rewardPool.size] = "counter_uav";
    rewardPool[rewardPool.size] = "deployable_vest";
    rewardPool[rewardPool.size] = "airdrop_trap";
    rewardPool[rewardPool.size] = "predator_missile";
    rewardPool[rewardPool.size] = "ims";
    rewardPool[rewardPool.size] = "precision_airstrike";
    rewardPool[rewardPool.size] = "helicopter";
    rewardPool[rewardPool.size] = "sam_turret";
    rewardPool[rewardPool.size] = "littlebird_flock";
    rewardPool[rewardPool.size] = "littlebird_support";
    rewardPool[rewardPool.size] = "remote_mortar";
    rewardPool[rewardPool.size] = "remote_uav";
    rewardPool[rewardPool.size] = "remote_tank";
    rewardPool[rewardPool.size] = "triple_uav";
    rewardPool[rewardPool.size] = "remote_mg_turret";
    rewardPool[rewardPool.size] = "ac130";
    rewardPool[rewardPool.size] = "helicopter_flares";
    rewardPool[rewardPool.size] = "stealth_airstrike";
    rewardPool[rewardPool.size] = "emp";
    rewardPool[rewardPool.size] = "escort_airdrop";
    rewardPool[rewardPool.size] = "osprey_gunner";

    availableRewards = [];

    foreach (reward in rewardPool)
    {
        if (
            IsDefined(level.killstreakfuncs) &&
            IsDefined(level.killstreakfuncs[reward])
        )
        {
            availableRewards[availableRewards.size] = reward;
        }
    }

    if (!availableRewards.size)
    {
        return;
    }

    reward = availableRewards[RandomInt(availableRewards.size)];
    self thread maps\mp\killstreaks\_killstreaks::givekillstreak(
        reward,
        0,
        0,
        self,
        0
    );
}

/*
    Capture the game mode's real health setting on every spawn. Overhealth
    temporarily raises maxHealth, so this stored value remains the authoritative
    base until death resets the player.
*/
WatchQuickFixSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        wait 0.05;

        self.fun_mode_quick_fix_base_health = self.maxHealth;
        self.fun_mode_quick_fix_overhealth_ceiling = undefined;
        self ClearQuickFixOverhealthOverlay();

        self thread WatchQuickFixOverhealth();
        self thread ClearQuickFixOverlayOnDeath();
    }
}

ClearQuickFixOverlayOnDeath()
{
    self endon("disconnect");
    self waittill("death");
    self ClearQuickFixOverhealthOverlay();
}

ClearQuickFixOverhealthOverlay()
{
    if (IsDefined(self.fun_mode_quick_fix_overlay))
    {
        self.fun_mode_quick_fix_overlay Destroy();
        self.fun_mode_quick_fix_overlay = undefined;
    }
}

UpdateQuickFixOverhealthOverlay()
{
    if (self IsBotPlayer())
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    if (
        !IsDefined(self.fun_mode_quick_fix_base_health) ||
        self.health <= self.fun_mode_quick_fix_base_health ||
        (IsDefined(self.haslightarmor) && self.haslightarmor)
    )
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    if (!IsDefined(self.fun_mode_quick_fix_overlay))
    {
        self.fun_mode_quick_fix_overlay = NewClientHudElem(self);
        self.fun_mode_quick_fix_overlay.x = 0;
        self.fun_mode_quick_fix_overlay.y = 0;
        self.fun_mode_quick_fix_overlay.alignX = "left";
        self.fun_mode_quick_fix_overlay.alignY = "top";
        self.fun_mode_quick_fix_overlay.horzAlign = "fullscreen";
        self.fun_mode_quick_fix_overlay.vertAlign = "fullscreen";
        self.fun_mode_quick_fix_overlay.sort = -10;
        self.fun_mode_quick_fix_overlay.archived = 1;
        self.fun_mode_quick_fix_overlay SetShader(
            "combathigh_overlay",
            640,
            480
        );
    }

    maximumHealth = Int(
        self.fun_mode_quick_fix_base_health *
        GetDvarFloat("fun_mode_quick_fix_max_percent")
    );
    maximumOverhealth = maximumHealth - self.fun_mode_quick_fix_base_health;

    if (maximumOverhealth <= 0)
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    overhealth = self.health - self.fun_mode_quick_fix_base_health;
    overhealthFraction = overhealth / maximumOverhealth;

    if (overhealthFraction > 1)
    {
        overhealthFraction = 1;
    }

    // Keep the first overhealth step visible, then reach stock intensity at cap.
    self.fun_mode_quick_fix_overlay.alpha = 0.15 + (0.85 * overhealthFraction);
}

/*
    Overhealth behaves like a consumable shield rather than ordinary maximum
    health. Damage lowers its ceiling, preventing IW5's normal regeneration
    from restoring health above the remaining overhealth amount.
*/
WatchQuickFixOverhealth()
{
    self endon("disconnect");
    self endon("death");

    previousHealth = self.health;

    for (;;)
    {
        wait 0.05;

        if (!IsDefined(self.fun_mode_quick_fix_overhealth_ceiling))
        {
            previousHealth = self.health;
            continue;
        }

        baseHealth = self.fun_mode_quick_fix_base_health;

        // Hand control back to IW5 if a real Ballistic Vest is collected.
        if (IsDefined(self.haslightarmor) && self.haslightarmor)
        {
            self.previousmaxhealth = baseHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = undefined;
            self ClearQuickFixOverhealthOverlay();
            previousHealth = self.health;
            continue;
        }

        if (self.health < previousHealth)
        {
            self.fun_mode_quick_fix_overhealth_ceiling = self.health;
        }

        if (self.fun_mode_quick_fix_overhealth_ceiling <= baseHealth)
        {
            self.maxHealth = baseHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = undefined;
        }
        else
        {
            self.maxHealth = self.fun_mode_quick_fix_overhealth_ceiling;

            if (self.health > self.fun_mode_quick_fix_overhealth_ceiling)
            {
                self.health = self.fun_mode_quick_fix_overhealth_ceiling;
            }
        }

        self UpdateQuickFixOverhealthOverlay();

        previousHealth = self.health;
    }
}

/*
    Below base health, kills restore a large burst and carry any excess across
    the base-health boundary. At or above base health, kills add smaller
    overhealth steps. Ten full-health kills reach the default 200-percent cap.
*/
WatchQuickFix()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (
            !GetDvarInt("fun_mode_quick_fix_enable") ||
            !IsAlive(self) ||
            !IsDefined(self.fun_mode_quick_fix_base_health) ||
            (IsDefined(self.haslightarmor) && self.haslightarmor)
        )
        {
            continue;
        }

        baseHealth = self.fun_mode_quick_fix_base_health;
        oldHealth = self.health;

        if (oldHealth < baseHealth)
        {
            healthToRestore = Int(
                baseHealth * GetDvarFloat("fun_mode_quick_fix_heal_percent")
            );
        }
        else
        {
            healthToRestore = Int(
                baseHealth * GetDvarFloat("fun_mode_quick_fix_overheal_percent")
            );
        }

        if (healthToRestore < 1)
        {
            healthToRestore = 1;
        }

        maximumHealth = Int(
            baseHealth * GetDvarFloat("fun_mode_quick_fix_max_percent")
        );

        restoredHealth = self.health + healthToRestore;

        if (restoredHealth > maximumHealth)
        {
            restoredHealth = maximumHealth;
        }

        if (restoredHealth > baseHealth)
        {
            self.maxHealth = restoredHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = restoredHealth;
        }

        self.health = restoredHealth;
        self UpdateQuickFixOverhealthOverlay();
    }
}

/*
    A full 9v9 lobby gives IW5 no free destination-team slot when a human
    tries to switch. When the human opens the team menu, temporarily lower the
    fill target and kick one bot from the opposite team. This creates the
    destination slot. Restoring the fill target after the human switches makes
    Bot Warfare add a replacement bot to the team the human left.
*/
WatchTeamSwitchMenu()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("menuresponse", menu, response);

        if (
            !GetDvarInt("fun_mode_team_switch_assist") ||
            response != "changeteam" ||
            !IsDefined(self.pers["team"]) ||
            (
                IsDefined(level.fun_mode_team_switch_in_progress) &&
                level.fun_mode_team_switch_in_progress
            )
        )
        {
            continue;
        }

        currentTeam = self.pers["team"];

        if (currentTeam != "allies" && currentTeam != "axis")
        {
            continue;
        }

        destinationTeam = "axis";

        if (currentTeam == "axis")
        {
            destinationTeam = "allies";
        }

        foreach (candidate in level.players)
        {
            if (
                !candidate IsBotPlayer() ||
                !IsDefined(candidate.pers["team"]) ||
                candidate.pers["team"] != destinationTeam
            )
            {
                continue;
            }

            fillTarget = GetDvarInt("fun_mode_team_switch_fill");
            previousFillKick = GetDvarInt("bots_manage_fill_kick");

            level.fun_mode_team_switch_in_progress = true;

            // Prevent addBots_loop() from observing 18 clients against the
            // temporary target of 17 and racing us by kicking a second bot.
            SetDvar("bots_manage_fill_kick", 0);
            SetDvar("bots_manage_fill", fillTarget - 1);
            kick(candidate GetEntityNumber(), "EXE_PLAYERKICKED");

            level thread RestoreBotFill(fillTarget, previousFillKick);
            break;
        }
    }
}

RestoreBotFill(fillTarget, fillKickValue)
{
    wait 10;
    SetDvar("bots_manage_fill", fillTarget);
    SetDvar("bots_manage_fill_kick", fillKickValue);
    level.fun_mode_team_switch_in_progress = false;
}

WatchPlayerLoadout()
{
    self endon("disconnect");

    if (IsSurvivalMode())
    {
        return;
    }

    for (;;)
    {
        // Fired after spawning and when changing classes.
        self waittill("changed_kit");

        // A new loadout invalidates any pickup reservation from the old one.
        self.fun_mode_scavenger_ammo_reserved = false;
        self.fun_mode_knife_runner_loadout = false;
        self.fun_mode_knife_runner_invulnerable_until = undefined;
        self.fun_mode_knife_runner_activation_announced = false;
        self InvalidateKnifeRunnerInvulnerabilityHud();

        wait 0.1;

        self ApplyExtremeConditioningMarathon();
        self UpdateKnifeRunnerLoadoutState();
        self ApplyShotgunProficiencies();

        if (self IsFunModeSuperClassOwner())
        {
            // this is the standard give all perks from the game itself
            // self maps\mp\killstreaks\_killstreaks::giveallperks();
            self GiveFullSpecialistBonus();
            self RestoreJuicedMovementAfterSpecialist();
            self ApplyActiveKillMomentumSpeed();
            self thread RestoreFunModeBlindEyeAfterSpawnProtection();
            // self ApplyFullSpecialistState();
        }
    }
}

ApplyExtremeConditioningMarathon()
{
    selectedExtremeConditioning = (
        IsDefined(self.loadoutPerk1) &&
        self.loadoutPerk1 == "specialty_longersprint"
    );

    if (
        !GetDvarInt("fun_mode_extreme_conditioning_marathon_enable") ||
        (!selectedExtremeConditioning && !self IsFunModeSuperClassOwner())
    )
    {
        return;
    }

    // Ordinary Specialist-granted copies still do not activate Marathon.
    self SetPerk("specialty_marathon", true, false);
}

ApplyShotgunProficiencies()
{
    hasShotgun = false;

    if (
        IsDefined(self.primaryWeapon) &&
        WeaponClass(self.primaryWeapon) == "shotgun"
    )
    {
        hasShotgun = true;
    }
    else if (
        IsDefined(self.secondaryWeapon) &&
        WeaponClass(self.secondaryWeapon) == "shotgun"
    )
    {
        hasShotgun = true;
    }

    if (hasShotgun)
    {
        self GivePerk("specialty_longerrange", false);
        self GivePerk("specialty_moredamage", false);
    }
}

WatchKillMomentumSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_kill_momentum_stacks = 0;
        self.fun_mode_kill_momentum_speed = undefined;
        self notify("fun_mode_kill_momentum_refresh");
    }
}

WatchExtremeConditioningSprintSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_extreme_conditioning_sprinting = false;
        self thread WatchExtremeConditioningSprintLife();
    }
}

WatchExtremeConditioningSprintLife()
{
    self endon("disconnect");
    self endon("death");
    self endon("spawned_player");

    for (;;)
    {
        self waittill("sprint_begin");
        self.fun_mode_extreme_conditioning_sprinting = true;
        self RefreshFunModeMovementSpeed();

        self waittill("sprint_end");
        self.fun_mode_extreme_conditioning_sprinting = false;
        self RefreshFunModeMovementSpeed();
    }
}

WatchWeaponMobilitySpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self InvalidateKnifeRunnerInvulnerabilityHud();
        wait 0.1;

        if (!IsAlive(self))
        {
            continue;
        }

        self RefreshFunModeMovementSpeed();
        self thread WatchWeaponMobilityLife();
    }
}

WatchWeaponMobilityLife()
{
    self endon("disconnect");
    self endon("death");
    self endon("spawned_player");

    for (;;)
    {
        self waittill("weapon_change");

        // Let IW5 finish its own weapon-change mobility update first.
        wait 0.05;

        if (IsAlive(self))
        {
            self RefreshFunModeMovementSpeed();
        }
    }
}

GetExtremeConditioningSprintSpeedMultiplier()
{
    if (
        !GetDvarInt("fun_mode_extreme_conditioning_sprint_speed_enable") ||
        !IsDefined(self.fun_mode_extreme_conditioning_sprinting) ||
        !self.fun_mode_extreme_conditioning_sprinting ||
        !self maps\mp\_utility::_hasPerk("specialty_longersprint")
    )
    {
        return 1.0;
    }

    if (self IsKnifeRunnerActive())
    {
        multiplier = GetDvarFloat(
            "fun_mode_knife_runner_sprint_speed_multiplier"
        );
    }
    else
    {
        multiplier = GetDvarFloat(
            "fun_mode_extreme_conditioning_sprint_speed_multiplier"
        );
    }

    if (multiplier < 1.0)
    {
        multiplier = 1.0;
    }

    return multiplier;
}

UpdateKnifeRunnerLoadoutState()
{
    self.fun_mode_knife_runner_class_num = self.class_num;
    self.fun_mode_knife_runner_deathstreak = undefined;

    if (
        IsDefined(self.pers["fun_mode_temporary_loadout_active"]) &&
        self.pers["fun_mode_temporary_loadout_active"] == "knife" &&
        IsDefined(self.pers["gamemodeLoadout"]) &&
        IsDefined(self.pers["gamemodeLoadout"]["loadoutDeathstreak"])
    )
    {
        self.fun_mode_knife_runner_deathstreak =
            self.pers["gamemodeLoadout"]["loadoutDeathstreak"];
    }
    else if (IsDefined(self.class_num))
    {
        self.fun_mode_knife_runner_deathstreak =
            self maps\mp\gametypes\_class::cac_getDeathstreak(self.class_num);
    }

    self.fun_mode_knife_runner_loadout = (
        GetDvarInt("fun_mode_knife_runner_enable") &&
        IsDefined(self.loadoutPerk1) &&
        self.loadoutPerk1 == "specialty_longersprint" &&
        IsDefined(self.loadoutPerk2) &&
        self.loadoutPerk2 == "specialty_quickdraw" &&
        IsDefined(self.loadoutPerk3) &&
        self.loadoutPerk3 == "specialty_quieter" &&
        IsDefined(self.loadoutPerkEquipment) &&
        self.loadoutPerkEquipment == "throwingknife_mp" &&
        IsDefined(self.fun_mode_knife_runner_deathstreak) &&
        self.fun_mode_knife_runner_deathstreak == "specialty_juiced" &&
        self maps\mp\_utility::_hasPerk("specialty_tacticalinsertion") &&
        IsKnifeRunnerWeapon(self.secondaryWeapon)
    );

    self ApplyKnifeRunnerLoadoutRestrictions();
    self UpdateKnifeRunnerActivationFeedback();
}

ApplyKnifeRunnerLoadoutRestrictions()
{
    if (
        !IsDefined(self.fun_mode_knife_runner_loadout) ||
        !self.fun_mode_knife_runner_loadout
    )
    {
        if (
            IsDefined(self.fun_mode_knife_runner_pickup_disabled) &&
            self.fun_mode_knife_runner_pickup_disabled
        )
        {
            self EnableWeaponPickup();
            self.fun_mode_knife_runner_pickup_disabled = false;
        }

        return;
    }

    self DisableWeaponPickup();
    self.fun_mode_knife_runner_pickup_disabled = true;

    if (
        IsDefined(self.primaryWeapon) &&
        self.primaryWeapon != "none" &&
        self HasWeapon(self.primaryWeapon)
    )
    {
        self TakeWeapon(self.primaryWeapon);
    }

    if (
        IsDefined(self.secondaryWeapon) &&
        self.secondaryWeapon != "none" &&
        self HasWeapon(self.secondaryWeapon)
    )
    {
        self SetWeaponAmmoClip(self.secondaryWeapon, 0);
        self SetWeaponAmmoStock(self.secondaryWeapon, 0);
        self SwitchToWeapon(self.secondaryWeapon);
    }
}

IsKnifeRunnerActive()
{
    if (
        !GetDvarInt("fun_mode_knife_runner_enable") ||
        !IsAlive(self) ||
        !IsDefined(self.fun_mode_knife_runner_loadout) ||
        !self.fun_mode_knife_runner_loadout ||
        !IsDefined(self.fun_mode_knife_runner_class_num) ||
        !IsDefined(self.class_num) ||
        self.fun_mode_knife_runner_class_num != self.class_num ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut)
    )
    {
        return false;
    }

    return IsKnifeRunnerWeapon(self GetCurrentWeapon());
}

IsKnifeRunnerWeapon(weapon)
{
    if (!IsDefined(weapon) || weapon == "none")
    {
        return false;
    }

    if (IsSubStr(weapon, "iw5_") && IsSubStr(weapon, "_tactical"))
    {
        return true;
    }

    return (
        IsSubStr(weapon, "iw5_usp45_mp") &&
        IsSubStr(weapon, "_akimbo")
    );
}

UpdateKnifeRunnerActivationFeedback()
{
    if (
        self IsBotPlayer() ||
        !GetDvarInt("fun_mode_knife_runner_message_enable") ||
        !self IsKnifeRunnerActive() ||
        (
            IsDefined(self.fun_mode_knife_runner_activation_announced) &&
            self.fun_mode_knife_runner_activation_announced
        )
    )
    {
        return;
    }

    self.fun_mode_knife_runner_activation_announced = true;
    self ShowFunModeCenterMessage(GetDvar("fun_mode_knife_runner_message"));
}

ShowFunModeCenterMessage(message)
{
    if (!IsDefined(message) || message == "")
    {
        return;
    }

    self IPrintLnBold(message);
}

WatchKnifeRunnerKills()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (
            !IsAlive(self) ||
            !self IsKnifeRunnerInvulnerabilityKill() ||
            !self IsKnifeRunnerActive()
        )
        {
            continue;
        }

        duration = GetDvarFloat(
            "fun_mode_knife_runner_invulnerability_seconds"
        );

        if (duration <= 0)
        {
            continue;
        }

        self.fun_mode_knife_runner_invulnerable_until = GetTime() + Int(duration * 1000);
        self ShowKnifeRunnerInvulnerabilityHud(duration);
    }
}

IsKnifeRunnerInvulnerabilityKill()
{
    if (
        IsDefined(self.fun_mode_last_damage_means) &&
        self.fun_mode_last_damage_means == "MOD_MELEE"
    )
    {
        return true;
    }

    return (
        IsDefined(self.fun_mode_last_damage_weapon) &&
        IsSubStr(self.fun_mode_last_damage_weapon, "throwingknife_mp")
    );
}

WatchKnifeRunnerInvulnerabilityHudDeaths()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("death");
        self InvalidateKnifeRunnerInvulnerabilityHud();
    }
}

ShowKnifeRunnerInvulnerabilityHud(duration)
{
    if (
        self IsBotPlayer() ||
        !GetDvarInt("fun_mode_knife_runner_invulnerability_hud_enable") ||
        !IsDefined(duration) ||
        duration <= 0
    )
    {
        return;
    }

    self InvalidateKnifeRunnerInvulnerabilityHud();
    generation = self.fun_mode_knife_runner_invulnerability_hud_generation;

    self.fun_mode_knife_runner_invulnerability_label = NewClientHudElem(self);
    self.fun_mode_knife_runner_invulnerability_label.alignX = "center";
    self.fun_mode_knife_runner_invulnerability_label.alignY = "middle";
    self.fun_mode_knife_runner_invulnerability_label.horzAlign = "center";
    self.fun_mode_knife_runner_invulnerability_label.vertAlign = "middle";
    self.fun_mode_knife_runner_invulnerability_label.x = 0;
    self.fun_mode_knife_runner_invulnerability_label.y = 62;
    self.fun_mode_knife_runner_invulnerability_label.font = "default";
    self.fun_mode_knife_runner_invulnerability_label.fontScale = 1.3;
    self.fun_mode_knife_runner_invulnerability_label SetText("INVULNERABLE");
    self.fun_mode_knife_runner_invulnerability_label.color = (1, 0.75, 0.2);
    self.fun_mode_knife_runner_invulnerability_label.foreground = true;
    self.fun_mode_knife_runner_invulnerability_label.hideWhenInMenu = true;
    self.fun_mode_knife_runner_invulnerability_label.sort = 1000;

    self.fun_mode_knife_runner_invulnerability_timer = NewClientHudElem(self);
    self.fun_mode_knife_runner_invulnerability_timer.alignX = "center";
    self.fun_mode_knife_runner_invulnerability_timer.alignY = "middle";
    self.fun_mode_knife_runner_invulnerability_timer.horzAlign = "center";
    self.fun_mode_knife_runner_invulnerability_timer.vertAlign = "middle";
    self.fun_mode_knife_runner_invulnerability_timer.x = 0;
    self.fun_mode_knife_runner_invulnerability_timer.y = 80;
    self.fun_mode_knife_runner_invulnerability_timer.font = "hudbig";
    self.fun_mode_knife_runner_invulnerability_timer.fontScale = 0.8;
    self.fun_mode_knife_runner_invulnerability_timer.color = (1, 1, 1);
    self.fun_mode_knife_runner_invulnerability_timer.foreground = true;
    self.fun_mode_knife_runner_invulnerability_timer.hideWhenInMenu = true;
    self.fun_mode_knife_runner_invulnerability_timer.sort = 1000;
    self.fun_mode_knife_runner_invulnerability_timer SetTenthsTimer(duration);

    self thread ClearKnifeRunnerInvulnerabilityHudAfterDelay(
        duration,
        generation
    );
}

ClearKnifeRunnerInvulnerabilityHudAfterDelay(duration, generation)
{
    self endon("disconnect");

    wait duration + 0.05;

    if (
        !IsDefined(self.fun_mode_knife_runner_invulnerability_hud_generation) ||
        self.fun_mode_knife_runner_invulnerability_hud_generation != generation
    )
    {
        return;
    }

    self DestroyKnifeRunnerInvulnerabilityHud();
}

InvalidateKnifeRunnerInvulnerabilityHud()
{
    if (!IsDefined(self.fun_mode_knife_runner_invulnerability_hud_generation))
    {
        self.fun_mode_knife_runner_invulnerability_hud_generation = 0;
    }

    self.fun_mode_knife_runner_invulnerability_hud_generation++;
    self DestroyKnifeRunnerInvulnerabilityHud();
}

DestroyKnifeRunnerInvulnerabilityHud()
{
    if (IsDefined(self.fun_mode_knife_runner_invulnerability_label))
    {
        self.fun_mode_knife_runner_invulnerability_label Destroy();
        self.fun_mode_knife_runner_invulnerability_label = undefined;
    }

    if (IsDefined(self.fun_mode_knife_runner_invulnerability_timer))
    {
        self.fun_mode_knife_runner_invulnerability_timer Destroy();
        self.fun_mode_knife_runner_invulnerability_timer = undefined;
    }
}

GetFunModeBaseMoveSpeed()
{
    speed = 1.0;

    if (IsDefined(self.isjuiced) && self.isjuiced)
    {
        speed = 1.25;
    }
    else if (
        IsDefined(self.isJuggernaut) &&
        self.isJuggernaut &&
        IsDefined(self.juggMoveSpeedScaler)
    )
    {
        speed = self.juggMoveSpeedScaler;
    }
    else if (self maps\mp\_utility::_hasPerk("specialty_lightweight"))
    {
        speed = maps\mp\_utility::lightweightScalar();
    }

    return speed *
        (self GetCurrentWeaponMobilityMultiplier()) *
        (self GetExtremeConditioningSprintSpeedMultiplier());
}

GetCurrentWeaponMobilityMultiplier()
{
    sniperMultiplier = self GetSniperDrawnMobilityMultiplier();

    if (sniperMultiplier > 1.0)
    {
        return sniperMultiplier;
    }

    pistolMultiplier = self GetPistolDrawnMobilityMultiplier();

    if (pistolMultiplier > 1.0)
    {
        return pistolMultiplier;
    }

    return 1.0;
}

GetSniperDrawnMobilityMultiplier()
{
    if (
        !GetDvarInt("fun_mode_sniper_mobility_enable") ||
        !IsAlive(self) ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut) ||
        !IsDefined(self.weaponSpeed) ||
        self.weaponSpeed <= 0
    )
    {
        return 1.0;
    }

    weapon = self GetCurrentWeapon();

    if (!IsDefined(weapon) || weapon == "none" || WeaponClass(weapon) != "sniper")
    {
        return 1.0;
    }

    targetMobility = GetDvarFloat("fun_mode_sniper_mobility_target");

    if (targetMobility <= self.weaponSpeed)
    {
        return 1.0;
    }

    return targetMobility / self.weaponSpeed;
}

GetPistolDrawnMobilityMultiplier()
{
    if (
        !GetDvarInt("fun_mode_pistol_mobility_enable") ||
        !IsAlive(self) ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut) ||
        !IsDefined(self.weaponSpeed) ||
        self.weaponSpeed <= 0
    )
    {
        return 1.0;
    }

    weapon = self GetCurrentWeapon();

    if (!IsFunModeHandgun(weapon))
    {
        return 1.0;
    }

    targetMobility = GetDvarFloat("fun_mode_pistol_mobility_target");

    if (targetMobility <= self.weaponSpeed)
    {
        return 1.0;
    }

    return targetMobility / self.weaponSpeed;
}

IsFunModeHandgun(weapon)
{
    if (!IsDefined(weapon) || weapon == "none")
    {
        return false;
    }

    return (
        IsSubStr(weapon, "iw5_usp45_mp") ||
        IsSubStr(weapon, "iw5_p99_mp") ||
        IsSubStr(weapon, "iw5_mp412_mp") ||
        IsSubStr(weapon, "iw5_44magnum_mp") ||
        IsSubStr(weapon, "iw5_fnfiveseven_mp") ||
        IsSubStr(weapon, "iw5_deserteagle_mp")
    );
}

RestoreFunModeBaseMoveSpeed()
{
    self.moveSpeedScaler = self GetFunModeBaseMoveSpeed();
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

ApplyActiveKillMomentumSpeed()
{
    if (!IsDefined(self.fun_mode_kill_momentum_speed))
    {
        return;
    }

    speed = self.fun_mode_kill_momentum_speed *
        (self GetCurrentWeaponMobilityMultiplier()) *
        (self GetExtremeConditioningSprintSpeedMultiplier());
    baseSpeed = self GetFunModeBaseMoveSpeed();

    if (speed < baseSpeed)
    {
        speed = baseSpeed;
    }

    self.moveSpeedScaler = speed;
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

RefreshFunModeMovementSpeed()
{
    self RestoreFunModeBaseMoveSpeed();
    self ApplyActiveKillMomentumSpeed();
    self UpdateKnifeRunnerActivationFeedback();
}

WatchKillMomentum()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (!GetDvarInt("fun_mode_kill_momentum_enable") || !IsAlive(self))
        {
            continue;
        }

        if (!IsDefined(self.fun_mode_kill_momentum_stacks))
        {
            self.fun_mode_kill_momentum_stacks = 0;
        }

        self.fun_mode_kill_momentum_stacks++;

        maximumStacks = GetDvarInt("fun_mode_kill_momentum_max_stacks");

        if (maximumStacks < 1)
        {
            maximumStacks = 1;
        }

        if (self.fun_mode_kill_momentum_stacks > maximumStacks)
        {
            self.fun_mode_kill_momentum_stacks = maximumStacks;
        }

        self UpdateKillMomentumSpeedFromStacks();
        self ApplyActiveKillMomentumSpeed();
        self notify("fun_mode_kill_momentum_refresh");
        self thread DecayKillMomentumAfterDelay();
    }
}

UpdateKillMomentumSpeedFromStacks()
{
    speed = GetDvarFloat("fun_mode_kill_momentum_start") +
        (
            (self.fun_mode_kill_momentum_stacks - 1) *
            GetDvarFloat("fun_mode_kill_momentum_step")
        );
    maximumSpeed = GetDvarFloat("fun_mode_kill_momentum_max");

    if (speed > maximumSpeed)
    {
        speed = maximumSpeed;
    }

    self.fun_mode_kill_momentum_speed = speed;
}

DecayKillMomentumAfterDelay()
{
    self endon("disconnect");
    self endon("death");
    self endon("fun_mode_kill_momentum_refresh");

    duration = GetDvarFloat("fun_mode_kill_momentum_duration");

    if (duration < 0.05)
    {
        duration = 0.05;
    }

    for (;;)
    {
        wait duration;

        self.fun_mode_kill_momentum_stacks--;

        if (self.fun_mode_kill_momentum_stacks <= 0)
        {
            self.fun_mode_kill_momentum_stacks = 0;
            self.fun_mode_kill_momentum_speed = undefined;
            self RestoreFunModeBaseMoveSpeed();
            return;
        }

        self UpdateKillMomentumSpeedFromStacks();
        self ApplyActiveKillMomentumSpeed();
    }
}

/*
    Lightweight and Juiced both assign moveSpeedScaler rather than composing
    their bonuses. Fun Mode grants Lightweight after changed_kit, which can
    overwrite an already-active Juiced deathstreak from 1.25 back to 1.10.
*/
RestoreJuicedMovementAfterSpecialist()
{
    if (!IsDefined(self.isjuiced) || !self.isjuiced)
    {
        return;
    }

    self.moveSpeedScaler = self GetFunModeBaseMoveSpeed();
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

/*
    Classes without Blind Eye receive it temporarily during IW5's spawn
    protection. When that timer expires, giveBlindEyeAfterSpawn() unsets the
    perk without knowing that fun mode also granted it permanently. Wait for
    that cleanup, then restore Blind Eye if it was removed.
*/
RestoreFunModeBlindEyeAfterSpawnProtection()
{
    self endon("death");
    self endon("disconnect");

    // Yield once so the stock spawn-protection thread can publish its state.
    wait 0.05;

    while (
        (
            IsDefined(self.spawnPerk) &&
            self.spawnPerk
        ) ||
        (
            IsDefined(self.avoidKillstreakOnSpawnTimer) &&
            self.avoidKillstreakOnSpawnTimer > 0
        )
    )
    {
        wait 0.05;
    }

    // Let giveBlindEyeAfterSpawn() finish its final _unsetPerk() call.
    wait 0.1;

    if (
        self IsFunModeSuperClassOwner() &&
        !self maps\mp\_utility::_hasperk("specialty_blindeye")
    )
    {
        self GivePerk("specialty_blindeye", false);
    }
}

// Custom function for just perks. The giveallperks() one gives full proficiencies too
GiveFullSpecialistBonus()
{
    perks = [];

    /*
        Standard perks. Each base perk is granted, then its Pro mapping is
        read directly from mp/perktable.csv. This bypasses progression locks
        for the current life only; it does not permanently unlock anything.
    */

    // Tier 1
    perks[0]  = "specialty_fastreload";        // Sleight of Hand
    perks[1]  = "specialty_scavenger";         // Scavenger
    perks[2]  = "specialty_blindeye";          // Blind Eye
    perks[3]  = "specialty_longersprint";      // Extreme Conditioning
    perks[4]  = "specialty_paint";             // Recon

    // Tier 2
    perks[5]  = "specialty_quickdraw";         // Quickdraw
    perks[6]  = "specialty_hardline";          // Hardline
    perks[7]  = "specialty_coldblooded";       // Assassin
    perks[8]  = "_specialty_blastshield";      // Blast Shield

    // Tier 3
    perks[9]  = "specialty_stalker";           // Stalker
    perks[10] = "specialty_bulletaccuracy";    // Steady Aim
    perks[11] = "specialty_detectexplosive";   // SitRep
    perks[12] = "specialty_autospot";          // Marksman
    perks[13] = "specialty_quieter";           // Dead Silence

    foreach (perk in perks)
    {
        self GivePerk(perk, false);

        proPerk = GetProPerkName(perk);

        if (
            IsDefined(proPerk) &&
            proPerk != "" &&
            proPerk != "specialty_null"
        )
        {
            self GivePerk(proPerk, false);
        }
    }

    /*
        Extra bonuses granted by MW3's actual Specialist Bonus.
        These are not ordinary selectable perks.
    */

    self GivePerk("specialty_marksman", false);
    self GivePerk("specialty_sharp_focus", false);
    self GivePerk("specialty_fastermelee", false);
    self GivePerk("specialty_reducedsway", false);
    self GivePerk("specialty_lightweight", false); // Movement-speed boost

    // Fun-mode addition: stack Impact with the class's selected proficiency.
    // Unsupported weapon classes ignore this flag.
    self GivePerk("specialty_bulletpenetration", false);
}

/*
    Marks the player as having earned MW3's full Specialist Bonus.

    Granting the perk flags alone is not sufficient for every system.
    Some killstreak targeting and challenge logic also appears to rely on
    the fourth Specialist reward slot being active.
*/
ApplyFullSpecialistState()
{
    self setplayerdata("killstreaksState", "hasStreak", 4, 1);

    if (
        IsDefined(self.pers["killstreaks"]) &&
        IsDefined(self.pers["killstreaks"][4])
    )
    {
        self.pers["killstreaks"][4].available = 1;
    }
}


/*
    MW3 normally refuses to collect a Scavenger bag when normal firearm ammo
    is already full, even if one of our optional refill categories still needs
    ammo (grenades, tacticals, launchers, noob tubes, etc.).

    The bag's pickup eligibility is handled before handleScavengerBagPickup()
    runs, so the custom refill handler cannot change that decision directly.

    When an enabled extra category needs ammo but all normal primary ammo is
    full, this watcher leaves one reserve round missing from a primary weapon.
    That makes the stock Scavenger pickup test consider the player eligible.
    The next bag immediately restores that round through the normal refill
    path along with the configured extra ammo.

    This avoids replacing the engine-side bag trigger itself.
*/
WatchScavengerPickupEligibility()
{
    self endon("disconnect");

    for (;;)
    {
        wait 0.25;

        if (!GetDvarInt("fun_mode_scavenger_enable"))
        {
            continue;
        }

        if (!self maps\mp\_utility::_hasperk("specialty_scavenger"))
        {
            continue;
        }

        if (!self NeedsExtraScavengerAmmo())
        {
            self.fun_mode_scavenger_ammo_reserved = false;
            continue;
        }

        self EnsureScavengerBagCanBePickedUp();
    }
}

/*
    Returns true when at least one enabled non-standard Scavenger category
    is below its refillable amount.
*/
NeedsExtraScavengerAmmo()
{
    if (
        GetDvarInt("fun_mode_scavenger_lethal") ||
        GetDvarInt("fun_mode_scavenger_tactical")
    )
    {
        offhands = self GetWeaponsListOffhands();

        foreach (offhand in offhands)
        {
            if (
                GetDvarInt("fun_mode_scavenger_lethal") &&
                IsScavengerLethal(offhand) &&
                self GetAmmoCount(offhand) < 1
            )
            {
                return true;
            }

            if (
                GetDvarInt("fun_mode_scavenger_tactical") &&
                IsScavengerTactical(offhand) &&
                self GetAmmoCount(offhand) <
                    GetScavengerTacticalMaxAmmo(offhand)
            )
            {
                return true;
            }
        }
    }

    if (GetDvarInt("fun_mode_scavenger_noobtubes"))
    {
        allWeapons = self GetWeaponsListAll();

        foreach (weapon in allWeapons)
        {
            if (
                IsScavengerNoobTube(weapon) &&
                self GetAmmoCount(weapon) <
                    GetDvarInt("fun_mode_scavenger_noobtubes_max")
            )
            {
                return true;
            }
        }
    }

    weapons = self GetWeaponsListPrimaries();

    foreach (weapon in weapons)
    {
        stockAmmo = self GetWeaponAmmoStock(weapon);

        maxAmmo = WeaponMaxAmmo(weapon);

        if (maxAmmo <= 0)
        {
            continue;
        }

        if (
            GetDvarInt("fun_mode_scavenger_launchers") &&
            IsScavengerLauncher(weapon) &&
            stockAmmo < maxAmmo
        )
        {
            return true;
        }

        if (
            GetDvarInt("fun_mode_scavenger_secondary") &&
            !maps\mp\_utility::IsCACPrimaryWeapon(weapon) &&
            !IsScavengerNoobTube(weapon) &&
            !IsScavengerLauncher(weapon) &&
            stockAmmo < maxAmmo
        )
        {
            return true;
        }
    }

    return false;
}

/*
    Remove exactly one reserve round from an ordinary firearm so the engine's
    stock bag trigger sees room for ammo. Prefer a normal Create-a-Class
    primary, then fall back to special firearms such as the Recon
    Juggernaut's USP when its Riot Shield has no reserve ammunition. Track the
    reservation explicitly: WeaponMaxAmmo()/stock comparisons do not reliably
    mirror the native pickup test for every weapon/attachment combination.
*/
EnsureScavengerBagCanBePickedUp()
{
    if (
        IsDefined(self.fun_mode_scavenger_ammo_reserved) &&
        self.fun_mode_scavenger_ammo_reserved
    )
    {
        return;
    }

    weapons = self GetWeaponsListPrimaries();

    // Preserve the established behavior for normal multiplayer loadouts.
    foreach (weapon in weapons)
    {
        if (!maps\mp\_utility::IsCACPrimaryWeapon(weapon))
        {
            continue;
        }

        maxAmmo = WeaponMaxAmmo(weapon);

        if (maxAmmo <= 0)
        {
            continue;
        }

        stockAmmo = self GetWeaponAmmoStock(weapon);

        if (stockAmmo > 0)
        {
            self SetWeaponAmmoStock(weapon, stockAmmo - 1);
            self.fun_mode_scavenger_ammo_reserved = true;

            if (GetDvarInt("fun_mode_scavenger_debug"))
            {
                Print(
                    "[FUN_MODE] Reserved Scavenger pickup by reducing " +
                    weapon +
                    " reserve ammo by 1."
                );
            }

            return;
        }
    }

    /*
        Juggernaut weapon variants are not classified as CAC primaries. The
        Recon loadout therefore reaches this fallback with a shield and its
        special USP; skip inventory items without conventional firearm ammo
        and reserve one pistol round for the native bag trigger.
    */
    foreach (weapon in weapons)
    {
        if (
            IsScavengerNoobTube(weapon) ||
            IsScavengerLauncher(weapon)
        )
        {
            continue;
        }

        maxAmmo = WeaponMaxAmmo(weapon);

        if (maxAmmo <= 0)
        {
            continue;
        }

        stockAmmo = self GetWeaponAmmoStock(weapon);

        if (stockAmmo <= 0)
        {
            continue;
        }

        self SetWeaponAmmoStock(weapon, stockAmmo - 1);
        self.fun_mode_scavenger_ammo_reserved = true;

        if (GetDvarInt("fun_mode_scavenger_debug"))
        {
            Print(
                "[FUN_MODE] Reserved Scavenger pickup using special weapon " +
                weapon +
                " reserve ammo."
            );
        }

        return;
    }
}


/*
    Configurable replacement for IW5's stock Scavenger bag pickup handler.

    This is based on the game's normal pickup flow instead of listening for
    "scavenger_pickup" afterward. That lets us modify the ammo/equipment
    grant at the exact point the bag is collected.

    Dvars:
      fun_mode_scavenger_enable      - Enable the extra MW2-style behavior
      fun_mode_scavenger_secondary   - Refill secondary firearm ammo
      fun_mode_scavenger_lethal      - Refill lethal equipment
      fun_mode_scavenger_tactical    - Refill tactical equipment
      fun_mode_scavenger_launchers   - Refill launcher ammo
      fun_mode_scavenger_noobtubes   - Refill underbarrel grenade launchers
      fun_mode_scavenger_noobtubes_max - Tube reserve capacity (default 2)
      fun_mode_scavenger_debug       - Print pickup/refill diagnostics

    Primary firearm ammo keeps the normal MW3 Scavenger behavior.
*/
HandleScavengerBagPickupCustom(scrPlayer)
{
    self endon("death");
    level endon("game_ended");

    assert(IsDefined(scrPlayer));

    // Wait for a player to collect this specific Scavenger bag.
    self waittill("scavenger", player);

    assert(IsDefined(player));

    player notify("scavenger_pickup");
    player PlayLocalSound("scavenger_pack_pickup");

    // The normal primary refill below pays back the reserved round. Clearing
    // this lets another reservation be made if an extra category is still low.
    player.fun_mode_scavenger_ammo_reserved = false;

    extraScavenger = GetDvarInt("fun_mode_scavenger_enable");
    knifeRunner = (
        IsDefined(player.fun_mode_knife_runner_loadout) &&
        player.fun_mode_knife_runner_loadout
    );

    if (GetDvarInt("fun_mode_scavenger_debug"))
    {
        Print("[FUN_MODE] Scavenger bag collected by " + player.name);
    }

    /*
        Offhand ammo is where grenades/equipment live in IW5.

        The stock MW2-style implementation increments the offhand clip by
        one. We keep that behavior, but allow lethal and tactical equipment
        to be toggled independently.
    */
    offhands = player GetWeaponsListOffhands();

    foreach (offhand in offhands)
    {
        shouldRefill = false;

        if (extraScavenger)
        {
            if (
                GetDvarInt("fun_mode_scavenger_lethal") &&
                IsScavengerLethal(offhand)
            )
            {
                shouldRefill = true;
            }

            if (
                GetDvarInt("fun_mode_scavenger_tactical") &&
                IsScavengerTactical(offhand)
            )
            {
                shouldRefill = true;
            }
        }

        if (!shouldRefill)
        {
            continue;
        }

        oldAmmo = player GetWeaponAmmoClip(offhand);

		/*
			C4 is not handled like an ordinary grenade after it is thrown. IW5's
			stock weapon script registers the new missile in player.c4array and
			attaches its activation, bullet-damage, and detonation threads when the
			offhand weapon fires. Re-giving the valid C4 weapon before restoring its
			clip refreshes that offhand state instead of only changing an ammo count.
		*/
		if (offhand == "c4_mp" && oldAmmo <= 0)
		{
			player GiveWeapon(offhand);
		}

        player SetWeaponAmmoClip(offhand, oldAmmo + 1);

        if (GetDvarInt("fun_mode_scavenger_debug"))
        {
            Print(
                "[FUN_MODE] Refilled offhand " +
                offhand +
                " from " +
                oldAmmo +
                " to " +
                (oldAmmo + 1)
            );
        }
    }

    /*
    Primary/secondary/launcher reserve ammunition.

        Normal MW3 primary ammo always refills. Extra categories are enabled
        only through the configurable dvars above.
    */
    if (extraScavenger && GetDvarInt("fun_mode_scavenger_noobtubes"))
    {
        allWeapons = player GetWeaponsListAll();

        foreach (weapon in allWeapons)
        {
            if (!IsScavengerNoobTube(weapon))
            {
                continue;
            }

            oldStock = player GetWeaponAmmoStock(weapon);
            addAmmo = WeaponClipSize(weapon);
            player SetWeaponAmmoStock(weapon, oldStock + addAmmo);

            if (GetDvarInt("fun_mode_scavenger_debug"))
            {
                Print(
                    "[FUN_MODE] Refilled noob tube " +
                    weapon +
                    " +" +
                    addAmmo +
                    " reserve ammo"
                );
            }
        }
    }

    weapons = player GetWeaponsListPrimaries();

    foreach (weapon in weapons)
    {
        if (knifeRunner && IsKnifeRunnerWeapon(weapon))
        {
            continue;
        }

        refillWeapon = false;

        if (IsScavengerNoobTube(weapon))
        {
            // Alternate-mode tube weapons were already handled via the full
            // inventory list above.
            continue;
        }
        else if (maps\mp\_utility::IsCACPrimaryWeapon(weapon))
        {
            // Preserve normal MW3 Scavenger behavior for primary firearms.
            refillWeapon = true;
        }
        else if (IsScavengerLauncher(weapon))
        {
            if (
                extraScavenger &&
                GetDvarInt("fun_mode_scavenger_launchers")
            )
            {
                refillWeapon = true;
            }
        }
        else
        {
            /*
                The stock script can optionally scavenge secondaries through
                level.scavenger_secondary. Our dvar can explicitly enable it
                even when that stock setting is disabled.
            */
            if (
                (IsDefined(level.scavenger_secondary) && level.scavenger_secondary) ||
                (extraScavenger && GetDvarInt("fun_mode_scavenger_secondary"))
            )
            {
                refillWeapon = true;
            }
        }

        if (!refillWeapon)
        {
            continue;
        }

        oldStock = player GetWeaponAmmoStock(weapon);
        addAmmo = WeaponClipSize(weapon);
        player SetWeaponAmmoStock(weapon, oldStock + addAmmo);

        if (GetDvarInt("fun_mode_scavenger_debug"))
        {
            Print(
                "[FUN_MODE] Refilled weapon " +
                weapon +
                " +" +
                addAmmo +
                " reserve ammo"
            );
        }
    }

    player maps\mp\gametypes\_damagefeedback::UpdateDamageFeedback("scavenger");
}

/*
    Lethal equipment recognized by IW5 Create-a-Class.
*/
IsScavengerLethal(weapon)
{
    return (
        weapon == "frag_grenade_mp" ||
        weapon == "semtex_mp" ||
        weapon == "throwingknife_mp" ||
        weapon == "bouncingbetty_mp" ||
        weapon == "claymore_mp" ||
        weapon == "c4_mp"
    );
}

/*
    Tactical equipment recognized by IW5 Create-a-Class.

    Tactical Insertion is intentionally not replenished here.
*/
IsScavengerTactical(weapon)
{
    return (
        weapon == "flash_grenade_mp" ||
        weapon == "concussion_grenade_mp" ||
        weapon == "smoke_grenade_mp" ||
        weapon == "emp_grenade_mp" ||
        weapon == "trophy_mp" ||
        weapon == "scrambler_mp" ||
        weapon == "portable_radar_mp"
    );
}

/*
    Flashbangs and concussion grenades spawn with a two-item capacity. Other
    supported tactical equipment is single-use and should not be overfilled.
*/
GetScavengerTacticalMaxAmmo(weapon)
{
    if (
        weapon == "flash_grenade_mp" ||
        weapon == "concussion_grenade_mp"
    )
    {
        return 2;
    }

    return 1;
}

/*
    Launcher weapon names used by IW5's runtime weapon inventory.
*/
/*
    Underbarrel grenade launchers ("noob tubes") can be configured
    independently from standalone launcher weapons.
*/
IsScavengerNoobTube(weapon)
{
    return (
        weapon == "gl_mp" ||
        weapon == "gp25_mp" ||
        (
            IsSubStr(weapon, "alt_") &&
            (
                IsSubStr(weapon, "_m320") ||
                IsSubStr(weapon, "_gl") ||
                IsSubStr(weapon, "_gp25")
            )
        )
    );
}

IsScavengerLauncher(weapon)
{
    return (
        weapon == "m320_mp" ||
        weapon == "rpg_mp" ||
        weapon == "iw5_smaw_mp" ||
        weapon == "smaw_mp" ||
        weapon == "stinger_mp" ||
        weapon == "xm25_mp" ||
        weapon == "javelin_mp"
    );
}

GetProPerkName(perkName)
{
    // Column 1 is the base perk name; column 8 is its Pro perk mapping.
    return TableLookup("mp/perktable.csv", 1, perkName, 8);
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
