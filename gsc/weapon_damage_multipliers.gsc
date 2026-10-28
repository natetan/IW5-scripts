/*
    Weapon Damage Multipliers - IW5 / Plutonium

    Central registry for script-level weapon damage tuning after IW5 resolves
    normal range, hit-location, penetration, attachment, and proficiency rules.
    The automated Reaper missile remains here because it uses the same final
    weapon-attribution multiplier path.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
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
    SetDvarIfNotInitialized("fun_mode_44magnum_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_cm901_damage_multiplier", 2.0);
    SetDvarIfNotInitialized("fun_mode_desert_eagle_damage_multiplier", 2.0);
}

/*
    Central registry for Fun Mode's weapon-specific damage buffs. Return 1.0
    for normal damage so new weapon rules can be added here without expanding
    the player-damage callback itself.
*/
GetMultiplier(weapon, meansOfDeath)
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

    if (scripts\scavenger::IsNoobTube(weapon))
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
        IsSubStr(weapon, "iw5_44magnum_mp")
    )
    {
        return GetDvarFloat("fun_mode_44magnum_damage_multiplier");
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

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

