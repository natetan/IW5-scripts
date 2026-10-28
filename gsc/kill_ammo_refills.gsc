/*
    Kill-Triggered Ammo Refills - IW5 / Plutonium

    Restores ammunition after qualifying kills for Throwing Knives, Javelins,
    underbarrel launchers, high-powered pistols, the AA-12, and firearms used
    after genuinely earning the full Specialist Bonus.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_pistol_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_javelin_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_noobtube_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_throwing_knife_kill_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_mag_refill_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_mag_refill_percent", 0.25);
    SetDvarIfNotInitialized("fun_mode_aa12_kill_refill_enable", 1);
}

OnPlayerConnected()
{
    self thread WatchKillAmmoRefills();
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
            GetDvarInt("fun_mode_throwing_knife_kill_refill_enable") &&
            IsSubStr(weapon, "throwingknife_mp")
        )
        {
            self RefillThrowingKnifeAfterKill();
        }

        if (
            GetDvarInt("fun_mode_javelin_kill_refill_enable") &&
            weapon == "javelin_mp"
        )
        {
            self RefillWeaponClipByRounds(weapon, 1);
        }

        if (
            GetDvarInt("fun_mode_noobtube_kill_refill_enable") &&
            scripts\scavenger::IsNoobTube(weapon)
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

RefillThrowingKnifeAfterKill()
{
    offhands = self GetWeaponsListOffhands();

    foreach (offhand in offhands)
    {
        if (offhand != "throwingknife_mp")
        {
            continue;
        }

        currentAmmo = self GetWeaponAmmoClip(offhand);

        if (currentAmmo < 1)
        {
            self SetWeaponAmmoClip(offhand, 1);
        }

        return;
    }
}

GetKillRefillPercent(weapon)
{
    refillPercent = 0.0;

    if (
        IsDefined(self.fun_mode_knife_runner_loadout) &&
        self.fun_mode_knife_runner_loadout &&
        scripts\fun_mode::IsKnifeRunnerWeapon(weapon)
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
            self scripts\fun_mode::HasEarnedFullSpecialistBonus()
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

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

