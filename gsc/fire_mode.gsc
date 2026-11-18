/*
    Fire Mode - IW5 / Plutonium

    Adds one native AC-130 25 mm round per eligible weapon_fired notification.
    Original player/vehicle bullet damage is intercepted at the code callbacks;
    loose GSC cannot cancel native traces, effects, or arbitrary prop damage.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    if (GetDvar("fun_mode_firemode_range") == "")
    {
        SetDvar("fun_mode_firemode_range", 12000);
    }

    PrecacheItem("ac130_25mm_mp");
}

OnPlayerConnected()
{
    self thread WatchBulletFire();
}

IsEnabledForPlayer(player)
{
    return (
        GetDvarInt("fun_mode_enable") &&
        IsDefined(player) &&
        IsPlayer(player) &&
        IsDefined(player.fun_mode_firemode_mode) &&
        player.fun_mode_firemode_mode == "25"
    );
}

IsEligibleWeapon(weapon)
{
    if (!IsDefined(weapon) || weapon == "" || weapon == "none")
    {
        return false;
    }

    inventoryType = WeaponInventoryType(weapon);
    if (
        (inventoryType != "primary" && inventoryType != "altmode") ||
        WeaponType(weapon) != "bullet" ||
        scripts\projectile_replacements::IsUnderbarrelShotgunWeapon(weapon)
    )
    {
        return false;
    }

    if (
        IsDefined(level.killstreakweildweapons) &&
        IsDefined(level.killstreakweildweapons[weapon])
    )
    {
        return false;
    }

    switch (WeaponClass(weapon))
    {
        case "rifle":
        case "smg":
        case "mg":
        case "pistol":
        case "sniper":
        case "spread":
            return true;
    }

    return false;
}

CanReplaceShot(weapon)
{
    if (
        !IsEnabledForPlayer(self) ||
        !IsAlive(self) ||
        IsDefined(self.usingremote) ||
        self IsUsingTurret() ||
        self GetCurrentWeapon() != weapon
    )
    {
        return false;
    }

    sourceWeapon = self GetSourceWeapon(weapon);
    return IsDefined(sourceWeapon) && self HasWeapon(sourceWeapon);
}

GetSourceWeapon(weapon)
{
    if (!IsEligibleWeapon(weapon))
    {
        return undefined;
    }

    if (WeaponInventoryType(weapon) == "primary")
    {
        return weapon;
    }

    sourceWeapon = self GetCurrentPrimaryWeapon();
    if (
        IsEligibleWeapon(sourceWeapon) &&
        WeaponInventoryType(sourceWeapon) == "primary" &&
        WeaponAltWeaponName(sourceWeapon) == weapon
    )
    {
        return sourceWeapon;
    }

    return undefined;
}

WatchBulletFire()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_fired", firedWeapon);

        if (!self CanReplaceShot(firedWeapon))
        {
            continue;
        }

        // Stock _weapons::watchweaponusage counts one shot per notify. Do not
        // expand WeaponBurstCount or delay/replay missing native notifications.
        sourceMeansOfDeath = "MOD_RIFLE_BULLET";
        if (WeaponClass(firedWeapon) == "pistol")
        {
            sourceMeansOfDeath = "MOD_PISTOL_BULLET";
        }

        self scripts\projectile_replacements::FireProjectileRound(
            "ac130_25mm_mp",
            self GetSourceWeapon(firedWeapon),
            "firemode 25",
            GetDvarFloat("fun_mode_firemode_range"),
            sourceMeansOfDeath
        );
    }
}

ShouldSuppressOriginalDamage(inflictor, attacker, meansOfDeath, weapon)
{
    if (!IsEnabledForPlayer(attacker) || !IsDefined(meansOfDeath))
    {
        return false;
    }

    if (
        IsDefined(inflictor) &&
        IsDefined(inflictor.fun_mode_underbarrel_source_weapon)
    )
    {
        return false;
    }

    if (
        (IsDefined(attacker.fun_mode_kill_mode_damage_active) &&
            attacker.fun_mode_kill_mode_damage_active) ||
        (IsDefined(attacker.fun_mode_reflection_active) &&
            attacker.fun_mode_reflection_active)
    )
    {
        return false;
    }

    if (
        meansOfDeath != "MOD_RIFLE_BULLET" &&
        meansOfDeath != "MOD_PISTOL_BULLET" &&
        meansOfDeath != "MOD_HEAD_SHOT" &&
        meansOfDeath != "MOD_EXPLOSIVE_BULLET"
    )
    {
        return false;
    }

    return attacker CanReplaceShot(weapon);
}
