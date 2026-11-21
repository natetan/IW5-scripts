/*
    Fire Mode - IW5 / Plutonium

    Adds native AC-130 25 mm ordnance per eligible weapon_fired notification.
    Shotguns emit a configurable cone volley, not native pellet trajectories.
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

    if (GetDvar("fun_mode_firemode_shotgun_rounds") == "")
    {
        SetDvar("fun_mode_firemode_shotgun_rounds", 6);
    }
    if (GetDvar("fun_mode_firemode_shotgun_hip_degrees") == "")
    {
        SetDvar("fun_mode_firemode_shotgun_hip_degrees", 4);
    }
    if (GetDvar("fun_mode_firemode_shotgun_ads_degrees") == "")
    {
        SetDvar("fun_mode_firemode_shotgun_ads_degrees", 2);
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
        self FireReplacementShot(firedWeapon);
    }
}

FireReplacementShot(firedWeapon)
{
    sourceWeapon = self GetSourceWeapon(firedWeapon);
    sourceMeansOfDeath = "MOD_RIFLE_BULLET";
    if (WeaponClass(firedWeapon) == "pistol")
    {
        sourceMeansOfDeath = "MOD_PISTOL_BULLET";
    }

    range = GetDvarFloat("fun_mode_firemode_range");
    if (WeaponClass(firedWeapon) != "spread")
    {
        self scripts\projectile_replacements::FireProjectileRound(
            "ac130_25mm_mp",
            sourceWeapon,
            "firemode 25",
            range,
            sourceMeansOfDeath
        );
        return;
    }

    // Snapshot the entire shell before an impact can trigger a Gun Game swap.
    angles = self getplayerangles();
    forward = anglestoforward(angles);
    right = anglestoright(angles);
    up = anglestoup(angles);
    launchOrigin = self geteye() + forward * 32;
    spread = GetShotgunSpread(self playerads());
    rounds = GetShotgunRounds();

    for (i = 0; i < rounds; i++)
    {
        direction = GetConeDirection(forward, right, up, spread);
        if (!self scripts\projectile_replacements::FireProjectileRound(
            "ac130_25mm_mp",
            sourceWeapon,
            "firemode 25",
            range,
            sourceMeansOfDeath,
            direction,
            launchOrigin
        ))
        {
            return;
        }
    }
}

GetShotgunRounds()
{
    return int(ClampShotgunValue(GetDvarInt("fun_mode_firemode_shotgun_rounds"), 1, 16));
}

GetShotgunSpread(ads)
{
    hip = ClampShotgunValue(GetDvarFloat("fun_mode_firemode_shotgun_hip_degrees"), 0, 15);
    aimed = ClampShotgunValue(GetDvarFloat("fun_mode_firemode_shotgun_ads_degrees"), 0, 15);
    return hip + (aimed - hip) * ClampShotgunValue(ads, 0, 1);
}

ClampShotgunValue(value, minimum, maximum)
{
    if (value < minimum)
    {
        return minimum;
    }
    if (value > maximum)
    {
        return maximum;
    }
    return value;
}

GetConeDirection(forward, right, up, degrees)
{
    // Uniform disk sampling in the aim plane; degrees is the cone half-angle.
    radius = sqrt(randomfloat(1)) * sin(degrees) / cos(degrees);
    azimuth = randomfloat(360);
    return vectornormalize(
        forward + right * (radius * cos(azimuth)) + up * (radius * sin(azimuth))
    );
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
