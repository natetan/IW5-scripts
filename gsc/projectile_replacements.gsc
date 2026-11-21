/*
    Underbarrel Shotgun Projectile Selections - IW5 / Plutonium

    The attachment owns selection, firing input, animation, and ammunition.
    Native AC-130 rounds and launcher rockets are supported. The 25 mm mode
    fires a short native burst; no scripted damage or turret emulation.
    Regular shotguns and the standalone Javelin are unaffected.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    // Existing server settings seed the renamed dvars unless explicitly set.
    SetDvarIfNotInitialized("fun_mode_underbarrel_javelin_enable", 1);
    SetDvarIfNotInitialized("fun_mode_underbarrel_javelin_range", 12000);
    SetDvarIfNotInitialized(
        "fun_mode_underbarrel_cannon_enable",
        GetDvarInt("fun_mode_underbarrel_javelin_enable")
    );
    SetDvarIfNotInitialized(
        "fun_mode_underbarrel_cannon_range",
        GetDvarFloat("fun_mode_underbarrel_javelin_range")
    );
    SetDvarIfNotInitialized("fun_mode_projectile_25mm_burst_rounds", 5);
    SetDvarIfNotInitialized("fun_mode_projectile_25mm_burst_interval_ms", 75);

    modes = StrTok("105,40,25,javelin,rpg,smaw", ",");
    foreach (mode in modes)
    {
        PrecacheItem(GetModeWeapon(mode));
    }
}

ResolveMode(requestedMode)
{
    mode = ToLower(requestedMode);
    if (mode == "jav")
    {
        mode = "javelin";
    }

    if (GetModeWeapon(mode) == "")
    {
        return undefined;
    }

    return mode;
}

GetModeWeapon(mode)
{
    switch (mode)
    {
        case "105": return "ac130_105mm_mp";
        case "40": return "ac130_40mm_mp";
        case "25": return "ac130_25mm_mp";
        case "javelin": return "javelin_mp";
        case "rpg": return "rpg_mp";
        case "smaw": return "iw5_smaw_mp";
    }

    return "";
}

GetPlayerMode()
{
    if (IsDefined(self.fun_mode_projectile_mode))
    {
        return ResolveMode(self.fun_mode_projectile_mode);
    }

    return undefined;
}

HasValidSelection(player)
{
    if (
        !IsDefined(player) ||
        !IsPlayer(player) ||
        !IsDefined(player.fun_mode_projectile_mode)
    )
    {
        return false;
    }

    return IsDefined(player GetPlayerMode());
}

OnPlayerConnected()
{
    self thread WatchUnderbarrelShotgunFire();
}

WatchUnderbarrelShotgunFire()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_fired");

        if (
            !GetDvarInt("fun_mode_underbarrel_cannon_enable") ||
            !IsAlive(self)
        )
        {
            continue;
        }

        firedWeapon = self GetCurrentWeapon();

        if (!IsUnderbarrelShotgunWeapon(firedWeapon))
        {
            continue;
        }

        if (IsDefined(self.fun_mode_projectile_mode))
        {
            self thread FireUnderbarrelReplacement();
        }
    }
}

FireUnderbarrelReplacement()
{
    if (!IsDefined(self.fun_mode_projectile_mode))
    {
        return;
    }

    self notify("projectile_burst");
    self endon("projectile_burst");
    self endon("projectile_selection_changed");
    self endon("weapon_change");
    self endon("changed_kit");
    self endon("spawned_player");
    self endon("gun_game_changed");
    self endon("death");
    self endon("disconnect");
    self endon("joined_team");
    self endon("joined_spectators");
    level endon("game_ended");

    sourceWeapon = self GetCurrentPrimaryWeapon();

    if (!IsDefined(sourceWeapon) || sourceWeapon == "" || sourceWeapon == "none")
    {
        PrintLn("Projectile replacement: firing weapon has no parent weapon.");
        return;
    }

    mode = self GetPlayerMode();
    if (!IsDefined(mode))
    {
        self IPrintLn("^1Unsupported stored projectile selection. Choose !projectile <105|40|25|javelin|jav|rpg|smaw>.^7");
        PrintLn("Projectile replacement: stored selection is no longer supported.");
        return;
    }

    weapon = GetModeWeapon(mode);
    firedWeapon = self GetCurrentWeapon();
    rounds = GetBurstRounds(mode);
    interval = GetBurstInterval();

    for (round = 0; round < rounds; round++)
    {
        if (!self CanContinueBurst(mode, sourceWeapon, firedWeapon))
        {
            return;
        }

        if (!self FireProjectileRound(weapon, sourceWeapon, mode))
        {
            return;
        }

        if (round + 1 < rounds)
        {
            wait interval;
        }
    }
}

CanContinueBurst(mode, sourceWeapon, firedWeapon)
{
    return (
        GetDvarInt("fun_mode_underbarrel_cannon_enable") &&
        IsAlive(self) &&
        self GetPlayerMode() == mode &&
        self GetCurrentPrimaryWeapon() == sourceWeapon &&
        self GetCurrentWeapon() == firedWeapon &&
        IsUnderbarrelShotgunWeapon(firedWeapon)
    );
}

GetBurstRounds(mode)
{
    if (mode != "25")
    {
        return 1;
    }

    rounds = GetDvarInt("fun_mode_projectile_25mm_burst_rounds");
    if (rounds < 1)
    {
        return 1;
    }
    if (rounds > 10)
    {
        return 10;
    }

    return rounds;
}

GetBurstInterval()
{
    interval = GetDvarFloat("fun_mode_projectile_25mm_burst_interval_ms");
    if (interval < 50)
    {
        interval = 50;
    }
    if (interval > 250)
    {
        interval = 250;
    }

    return interval / 1000.0;
}

FireProjectileRound(weapon, sourceWeapon, mode, range, sourceMeansOfDeath, direction, launchOrigin)
{
    if (!IsDefined(direction))
    {
        direction = anglestoforward(self getplayerangles());
    }
    if (!IsDefined(launchOrigin))
    {
        launchOrigin = self geteye() + direction * 32;
    }
    if (!IsDefined(range))
    {
        range = GetDvarFloat("fun_mode_underbarrel_cannon_range");
    }

    if (range < 512)
    {
        range = 512;
    }

    targetOrigin = launchOrigin + direction * range;
    projectile = magicbullet(
        weapon,
        launchOrigin,
        targetOrigin,
        self
    );

    if (!IsDefined(projectile))
    {
        self IPrintLn("^1Projectile could not be created:^7 " + mode);
        PrintLn("Projectile replacement: no entity created for " + weapon);
        return false;
    }

    // Capture the firing gun now, not whichever gun is held at impact.
    projectile.fun_mode_underbarrel_source_weapon = sourceWeapon;
    if (IsDefined(sourceMeansOfDeath))
    {
        projectile.fun_mode_firemode_source_means = sourceMeansOfDeath;
    }
    if (mode == "javelin")
    {
        // Restore the earlier working attachment's direct-flight setup.
        projectile missile_setflightmodedirect();
    }
    projectile thread CleanUpReplacement();
    return true;
}

CleanUpReplacement()
{
    self endon("death");
    level endon("game_ended");

    wait 12;

    if (IsDefined(self))
    {
        self Delete();
    }
}

SuppressPelletDamage(damage, weapon, attacker)
{
    if (
        GetDvarInt("fun_mode_underbarrel_cannon_enable") &&
        HasValidSelection(attacker) &&
        IsUnderbarrelShotgunWeapon(weapon)
    )
    {
        return 0;
    }

    return damage;
}

GetKillAttributionWeapon(inflictor, reportedWeapon)
{
    if (
        IsDefined(inflictor) &&
        IsDefined(inflictor.fun_mode_underbarrel_source_weapon)
    )
    {
        return inflictor.fun_mode_underbarrel_source_weapon;
    }

    return reportedWeapon;
}

GetDamageAttributionWeapon(inflictor, reportedWeapon)
{
    if (!GetDvarInt("fun_mode_enable") || reportedWeapon != "javelin_mp")
    {
        return reportedWeapon;
    }

    // The damage modifier has no inflictor parameter. Resolve only marked
    // Javelins before that callback, not by guessing from the attacker's gun.
    return GetKillAttributionWeapon(inflictor, reportedWeapon);
}

GetKillAttributionMeansOfDeath(inflictor, reportedMeansOfDeath)
{
    if (
        IsDefined(inflictor) &&
        IsDefined(inflictor.fun_mode_firemode_source_means)
    )
    {
        return inflictor.fun_mode_firemode_source_means;
    }

    return reportedMeansOfDeath;
}

IsUnderbarrelShotgunWeapon(weapon)
{
    if (!IsDefined(weapon))
    {
        return false;
    }

    normalizedWeapon = tolower(weapon);

    return (
        normalizedWeapon.size >= 4 &&
        getsubstr(normalizedWeapon, 0, 4) == "alt_" &&
        issubstr(normalizedWeapon, "_shotgun")
    );
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
