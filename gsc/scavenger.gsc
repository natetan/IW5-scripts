#include maps\mp\_utility;

/*
    Expanded Scavenger - IW5 / Plutonium

    Preserves stock primary-ammo refills while optionally replenishing
    secondaries, equipment, standalone launchers, and underbarrel launchers.
    It also keeps bags collectible when only an extra category needs ammo.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_scavenger_enable", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_secondary", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_lethal", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_tactical", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_launchers", 0);
    SetDvarIfNotInitialized("fun_mode_scavenger_noobtubes", 1);
    SetDvarIfNotInitialized("fun_mode_scavenger_noobtubes_max", 2);
    SetDvarIfNotInitialized("fun_mode_scavenger_debug", 0);

    ReplaceFunc(
        maps\mp\gametypes\_weapons::handleScavengerBagPickup,
        ::HandleScavengerBagPickupCustom
    );
}

OnPlayerConnected()
{
    self thread WatchScavengerPickupEligibility();
    self thread WatchScavengerLoadoutChanges();
}

WatchScavengerLoadoutChanges()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("changed_kit");
        self.fun_mode_scavenger_ammo_reserved = false;
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
        if (knifeRunner && scripts\knife_runner::IsKnifeRunnerWeapon(weapon))
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

IsNoobTube(weapon)
{
    // Public classifier used by damage and kill-refill systems.
    return IsScavengerNoobTube(weapon);
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

