#include maps\mp\_utility;

/*
    Fun Mode - IW5 / Plutonium

    Features:
    - Human players using custom classes 13-15 receive the full Specialist
      perk set, its Pro perk mappings, the extra Specialist bonuses, and the
      Impact and shotgun Damage weapon proficiencies.
    - Replaces the stock Scavenger handler with configurable MW2-style
      resupply for secondary weapons, lethal equipment, tactical equipment,
      standalone launchers, and underbarrel grenade launchers.
    - Makes Scavenger bags collectible when only equipment or launcher ammo
      needs replenishing, including two-item tactical and tube capacities.
    - Globally strengthens Blast Shield so its users take 25 percent of normal
      explosive damage instead of the stock 45 percent.
    - Disables MW3's post-spawn killstreak damage cap for more lethal,
      MW2-style player-controlled streaks.
    - Assists team changes in full 9v9 bot lobbies by temporarily removing a
      destination-team bot, then restoring the configured fill target so Bot
      Warfare replaces it on the team the human left.

    MW3 custom-class numbers shown in the UI are 1-based.
    Classes 13-15 map to internal class indices 12-14.
    Most optional behavior is controlled through the fun_mode_* dvars below.
*/

Main()
{
    SetDvarIfNotInitialized("fun_mode_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_class_index", 14);
    SetDvarIfNotInitialized("fun_mode_team_switch_assist", 1);
    SetDvarIfNotInitialized("fun_mode_team_switch_fill", 18);
    SetDvarIfNotInitialized("fun_mode_blast_shield_damage", 0.25);

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

    level thread OnPlayerConnect();
}

OnPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);

        if (player IsBotPlayer())
        {
            continue;
        }

        player thread WatchPlayerLoadout();
        player thread WatchScavengerPickupEligibility();
        player thread WatchTeamSwitchMenu();
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

    for (;;)
    {
        // Fired after spawning and when changing classes.
        self waittill("changed_kit");

        // A new loadout invalidates any pickup reservation from the old one.
        self.fun_mode_scavenger_ammo_reserved = false;

        wait 0.1;

        if (
            IsDefined(self.class_num) &&
            (
                self.class_num == 12 ||
                self.class_num == 13 || 
                self.class_num == 14
            )
        )
        {
            // this is the standard give all perks from the game itself
            // self maps\mp\killstreaks\_killstreaks::giveallperks();
            self GiveFullSpecialistBonus();
            self thread RestoreFunModeBlindEyeAfterSpawnProtection();
            // self ApplyFullSpecialistState();
        }
    }
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
        IsDefined(self.class_num) &&
        (
            self.class_num == 12 ||
            self.class_num == 13 ||
            self.class_num == 14
        ) &&
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
    self GivePerk("specialty_longerrange", false);
    self GivePerk("specialty_fastermelee", false);
    self GivePerk("specialty_reducedsway", false);
    self GivePerk("specialty_lightweight", false); // Movement-speed boost

    // Fun-mode additions: stack Impact and shotgun Damage with the class's
    // selected proficiency. Unsupported weapon classes ignore these flags.
    self GivePerk("specialty_bulletpenetration", false);
    self GivePerk("specialty_moredamage", false);
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
    Remove exactly one reserve round from an ordinary primary so the engine's
    stock bag trigger sees room for firearm ammo. Track the reservation
    explicitly: WeaponMaxAmmo()/stock comparisons do not reliably mirror the
    native pickup test for every weapon/attachment combination.
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
