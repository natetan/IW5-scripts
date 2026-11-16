/*
    Underbarrel Shotgun Javelin - IW5 / Plutonium

    Replaces the underbarrel shotgun attachment's pellet damage with a real
    Javelin projectile forced into direct flight along the user's aim. The
    attachment still owns selection, firing input, animation, and ammunition.
    Regular shotguns and the standalone Javelin are unaffected.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_underbarrel_javelin_enable", 1);
    SetDvarIfNotInitialized("fun_mode_underbarrel_javelin_range", 12000);
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
            !GetDvarInt("fun_mode_underbarrel_javelin_enable") ||
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

        self FireDirectUnderbarrelJavelin();
    }
}

FireDirectUnderbarrelJavelin()
{
    direction = anglestoforward(self getplayerangles());
    launchOrigin = self geteye() + direction * 32;
    range = GetDvarFloat("fun_mode_underbarrel_javelin_range");

    if (range < 512)
    {
        range = 512;
    }

    targetOrigin = launchOrigin + direction * range;
    missile = magicbullet(
        "javelin_mp",
        launchOrigin,
        targetOrigin,
        self
    );

    if (!IsDefined(missile))
    {
        return;
    }

    if (IsDefined(self.primaryWeapon))
    {
        // Preserve the complete carried primary identity so the stock death,
        // obituary, challenge, and progression paths treat missile kills like
        // ordinary attachment kills from that weapon.
        missile.fun_mode_underbarrel_source_weapon = self.primaryWeapon;
    }

    missile missile_setflightmodedirect();
    missile thread CleanUpDirectUnderbarrelJavelin();
}

CleanUpDirectUnderbarrelJavelin()
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
        GetDvarInt("fun_mode_underbarrel_javelin_enable") &&
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
