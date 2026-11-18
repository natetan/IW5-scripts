/*
    Underbarrel Shotgun AC-130 Cannon - IW5 / Plutonium

    Replaces the underbarrel shotgun attachment's pellet damage with a native
    AC-130 105 mm shell fired along the user's aim. The attachment still owns
    selection, firing input, animation, and ammunition.
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

        self FireUnderbarrelCannon();
    }
}

FireUnderbarrelCannon()
{
    sourceWeapon = self GetCurrentPrimaryWeapon();

    if (!IsDefined(sourceWeapon) || sourceWeapon == "" || sourceWeapon == "none")
    {
        PrintLn("Underbarrel cannon: firing weapon has no parent weapon.");
        return;
    }

    direction = anglestoforward(self getplayerangles());
    launchOrigin = self geteye() + direction * 32;
    range = GetDvarFloat("fun_mode_underbarrel_cannon_range");

    if (range < 512)
    {
        range = 512;
    }

    targetOrigin = launchOrigin + direction * range;
    projectile = magicbullet(
        "ac130_105mm_mp",
        launchOrigin,
        targetOrigin,
        self
    );

    if (!IsDefined(projectile))
    {
        PrintLn("Underbarrel cannon: AC-130 105 mm projectile was not created.");
        return;
    }

    // Capture the firing gun now, not whichever gun is held at impact.
    projectile.fun_mode_underbarrel_source_weapon = sourceWeapon;
    projectile thread CleanUpUnderbarrelCannon();
}

CleanUpUnderbarrelCannon()
{
    self endon("death");
    level endon("game_ended");

    wait 12;

    if (IsDefined(self))
    {
        self Delete();
    }
}

SuppressPelletDamage(damage, weapon)
{
    if (
        GetDvarInt("fun_mode_underbarrel_cannon_enable") &&
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
