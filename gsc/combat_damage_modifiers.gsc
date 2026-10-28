#include maps\mp\_utility;

/*
    Combat Damage Modifiers - IW5 / Plutonium

    Owns cross-cutting outgoing and incoming damage rules while fun_mode keeps
    the authoritative callback chain and modifier ordering.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_super_class_melee_damage_multiplier", 0.50);
    SetDvarIfNotInitialized("fun_mode_super_class_direct_projectile_damage_multiplier", 0.50);
    SetDvarIfNotInitialized("fun_mode_blast_shield_damage", 0.25);
    SetDvarIfNotInitialized("fun_mode_blast_shield_explosive_damage_multiplier", 1.5);
    SetDvarIfNotInitialized("fun_mode_specialist_multishot_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_multishot_chance", 0.20);
}

Initialize()
{
    // IW5's stock Blast Shield scalar is 0.45.
    level.blastShieldMod = GetDvarFloat("fun_mode_blast_shield_damage");

    // Remove MW3's temporary post-spawn cap for player-controlled streaks.
    level.killstreakSpawnShield = 0;
}

/*
    Keep these defensive bonuses on the same eligibility path as the rest of
    the classes 13-15 package. Non-dedicated sessions allow all three classes;
    dedicated servers additionally require fun_mode_super_class_guids.

    IW5 reports a projectile's physical collision as MOD_PROJECTILE and its
    surrounding explosion separately as MOD_PROJECTILE_SPLASH. Reducing only
    the former preserves normal Blast Shield and splash-damage behavior.
*/
GetIncomingMultiplier(victim, meansOfDeath)
{
    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !victim scripts\specialist_system::IsFunModeSuperClassOwner()
    )
    {
        return 1.0;
    }

    if (meansOfDeath == "MOD_MELEE")
    {
        return GetDvarFloat(
            "fun_mode_super_class_melee_damage_multiplier"
        );
    }

    if (meansOfDeath == "MOD_PROJECTILE")
    {
        return GetDvarFloat(
            "fun_mode_super_class_direct_projectile_damage_multiplier"
        );
    }

    return 1.0;
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
    Blast Shield doubles as an unrestricted Danger Close-style offensive
    perk. Apply it only to damage attributed to another player, and use IW5's
    native explosive and killstreak classifiers so launchers, underbarrel
    grenades, thrown explosives, C4, and Claymores qualify while streak damage
    does not. Kill-mode callbacks already carry final damage and must not be
    multiplied a second time.
*/
GetDangerCloseMultiplier(
    victim,
    attacker,
    weapon,
    meansOfDeath
)
{
    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        attacker == victim ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        !IsDefined(meansOfDeath) ||
        !IsExplosiveDamageMod(meansOfDeath) ||
        maps\mp\_utility::IsKillstreakWeapon(weapon) ||
        !attacker maps\mp\_utility::_HasPerk("_specialty_blastshield")
    )
    {
        return 1.0;
    }

    return GetDvarFloat(
        "fun_mode_blast_shield_explosive_damage_multiplier"
    );
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
GetMultishotMultiplier(attacker, weapon, meansOfDeath)
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
        !attacker scripts\specialist_system::HasEarnedFullSpecialistBonus()
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

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

