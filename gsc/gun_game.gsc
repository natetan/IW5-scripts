/*
    Match-wide single-weapon overlay, independent of the selected gametype.
    Personal presets pause while enabled. Only weapons change: class perks,
    proficiencies, equipment, health, and earned streaks remain untouched.
*/

main()
{
    level.fun_mode_gun_game_enabled = false;
    level thread WatchConnections();
    level thread InstallKilledHook();
}

IsEnabled()
{
    return (
        IsDefined(level.fun_mode_gun_game_enabled) &&
        level.fun_mode_gun_game_enabled
    );
}

Toggle(enabled)
{
    if (!IsDefined(enabled))
    {
        enabled = !IsEnabled();
    }

    if (enabled == IsEnabled())
    {
        if (enabled)
        {
            self IPrintLnBold("Gun Game is already enabled");
        }
        else
        {
            self IPrintLnBold("Gun Game is already disabled");
        }
        return;
    }

    if (
        enabled &&
        IsDefined(level.fun_mode_gun_game_hook_failed) &&
        level.fun_mode_gun_game_hook_failed
    )
    {
        self IPrintLnBold("Gun Game unavailable: check the server log");
        return;
    }

    level.fun_mode_gun_game_enabled = enabled;

    if (IsDefined(level.players))
    {
        foreach (player in level.players)
        {
            if (!IsDefined(player) || !IsPlayer(player))
            {
                continue;
            }

            player EnsureLoadoutWatcher();
            player notify("gun_game_changed");
            player.fun_mode_gun_game_primary = undefined;
            player.fun_mode_gun_game_weapon = undefined;

            if (IsEnabled())
            {
                player thread ApplyAfterLoadout();
            }
            else
            {
                player RestoreWeaponPickup();
            }
        }
    }

    if (IsEnabled())
    {
        IPrintLn("^2Gun Game enabled:^7 everyone gets one random weapon; weapon kills reroll only the killer.");
    }
    else
    {
        IPrintLn("^3Gun Game disabled.^7 Normal loadouts resume on the next spawn.");
    }
}

WatchConnections()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (IsDefined(player) && IsPlayer(player))
        {
            player EnsureLoadoutWatcher();
        }
    }
}

EnsureLoadoutWatcher()
{
    if (IsDefined(self.fun_mode_gun_game_watcher))
    {
        return;
    }

    self.fun_mode_gun_game_watcher = true;
    self thread WatchLoadouts();
}

WatchLoadouts()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("changed_kit");
        self.fun_mode_gun_game_weapon = undefined;
        self thread ApplyAfterLoadout(true);
    }
}

ApplyAfterLoadout(spawnLoadout)
{
    self notify("gun_game_apply");
    self endon("gun_game_apply");
    self endon("disconnect");
    self endon("death");
    self endon("changed_kit");
    self endon("gun_game_changed");
    level endon("game_ended");

    // Bot Warfare rebuilds the kit after giveLoadout and fires changed_kit
    // again. Cancel the earlier application and use only the completed kit.
    wait 0.05;

    while (
        IsEnabled() &&
        IsAlive(self) &&
        self maps\mp\_utility::IsUsingRemote()
    )
    {
        wait 0.05;
    }

    if (IsEnabled())
    {
        self ApplyPrimary(spawnLoadout);
    }
}

ApplyPrimary(spawnLoadout)
{
    if (
        !IsEnabled() ||
        !IsAlive(self) ||
        !IsDefined(self.sessionstate) ||
        self.sessionstate != "playing"
    )
    {
        return;
    }

    if (
        (
            !IsDefined(self.fun_mode_gun_game_primary) ||
            !IsEligibleWeapon(self.fun_mode_gun_game_primary["loadoutPrimary"])
        ) &&
        !self RollPrimary()
    )
    {
        self IPrintLnBold("Gun Game could not select a weapon; check the server log");
        return;
    }

    loadout = self.fun_mode_gun_game_primary;
    primary = loadout["loadoutPrimary"];
    attachment = loadout["loadoutPrimaryAttachment"];
    attachment2 = "none";
    camo = 0;

    // Secondary-class weapons keep their normal attachment/camo rules even
    // though Gun Game equips them as the sole weapon in the primary slot.
    if (maps\mp\gametypes\_class::isValidPrimary(primary, false))
    {
        attachment2 = self maps\mp\gametypes\_class::addAutomaticAttachmentToHumanPrimary(
            primary,
            attachment,
            "none"
        );

        if (IsSubStr(primary, "iw5_"))
        {
            camo = Int(TableLookup("mp/camoTable.csv", 1, "gold", 0));
        }
    }

    weapon = maps\mp\gametypes\_class::buildWeaponName(
        primary,
        attachment,
        attachment2,
        camo,
        0
    );

    self RemoveLoadoutWeapons();

    self maps\mp\_utility::_giveWeapon(weapon);
    self GiveMaxAmmo(weapon);
    self.primaryWeapon = weapon;
    self.secondaryWeapon = "none";
    self.loadoutPrimary = primary;
    self.loadoutSecondary = "none";
    self.loadoutPrimaryCamo = camo;
    self.loadoutPrimaryReticle = 0;
    self.pers["primaryWeapon"] = primary;
    self.isSniper = (WeaponClass(weapon) == "sniper");
    self.fun_mode_gun_game_weapon = weapon;
    // Stock Gun Game uses instant spawn selection only for a rebuilt loadout.
    // Live swaps must use the native switch/raise path, including leaving ADS.
    if (IsDefined(spawnLoadout) && spawnLoadout)
    {
        self SetSpawnWeapon(weapon);
    }
    self SwitchToWeapon(weapon);
    self DisableWeaponPickup();
    self.fun_mode_gun_game_pickup_disabled = true;

    self scripts\knife_runner::ResetLoadoutState();
    self maps\mp\gametypes\_weapons::UpdateMoveSpeedScale();
}

RemoveLoadoutWeapons()
{
    weapons = self GetWeaponsListPrimaries();

    foreach (carriedWeapon in weapons)
    {
        if (maps\mp\_utility::IsKillstreakWeapon(carriedWeapon))
        {
            continue;
        }

        // Removing a weapon can also remove linked inventory entries.
        // Recheck the live inventory rather than trusting the original list.
        if (self HasWeapon(carriedWeapon))
        {
            self TakeWeapon(carriedWeapon);
        }
    }
}

RollPrimary()
{
    previousPrimary = undefined;

    if (IsDefined(self.fun_mode_gun_game_primary))
    {
        previousPrimary = self.fun_mode_gun_game_primary["loadoutPrimary"];
    }

    primary = scripts\temporary_loadouts::RandomizePrimaryLoadout(
        [],
        previousPrimary,
        GetWeaponPool(previousPrimary)
    );

    if (!IsDefined(primary))
    {
        return false;
    }

    self.fun_mode_gun_game_primary = primary;
    self.fun_mode_gun_game_weapon = undefined;
    return true;
}

GetWeaponPool(previousWeapon)
{
    weapons = [];

    for (row = 0; row < 160; row++)
    {
        weapon = TableLookupByRow("mp/statStable.csv", row, 4);

        if (
            (IsDefined(previousWeapon) && weapon == previousWeapon) ||
            !IsEligibleWeapon(weapon)
        )
        {
            continue;
        }

        weapons[weapons.size] = weapon;
    }

    return weapons;
}

IsEligibleWeapon(weapon)
{
    if (
        !IsDefined(weapon) ||
        weapon == "" ||
        weapon == "riotshield" ||
        weapon == "stinger" ||
        IsSubStr(weapon, "jugg")
    )
    {
        return false;
    }

    return (
        maps\mp\gametypes\_class::isValidPrimary(weapon, false) ||
        maps\mp\gametypes\_class::isValidSecondary(
            weapon,
            "specialty_quickdraw",
            "specialty_null",
            false
        )
    );
}

RestoreWeaponPickup()
{
    if (IsDefined(self.fun_mode_gun_game_pickup_disabled))
    {
        self EnableWeaponPickup();
        self.fun_mode_gun_game_pickup_disabled = undefined;
    }
}

InstallKilledHook()
{
    level endon("game_ended");
    level waittill("prematch_over");

    // Bot Warfare wraps at 0.05 seconds and impersonation at 0.10. Stay
    // outside both so qualification sees the real weapon, not its proxy.
    wait 0.15;

    if (!IsDefined(level.callbackPlayerKilled))
    {
        level.fun_mode_gun_game_hook_failed = true;
        PrintLn("Gun Game: player-killed callback is unavailable.");
        return;
    }

    level.fun_mode_gun_game_previous_killed = level.callbackPlayerKilled;
    level.callbackPlayerKilled = ::PlayerKilled;
}

PlayerKilled(
    inflictor,
    attacker,
    damage,
    meansOfDeath,
    weapon,
    direction,
    hitLocation,
    timeOffset,
    deathAnimDuration
)
{
    sourceWeapon = scripts\underbarrel_shotgun_javelin::GetKillAttributionWeapon(
        inflictor,
        weapon
    );

    if (ShouldAdvance(self, attacker, sourceWeapon, meansOfDeath))
    {
        // The native callback waits through killcam/respawn, so confirmation
        // must run alongside it rather than after it returns.
        attacker thread ConfirmKill(self, attacker.fun_mode_gun_game_weapon);
    }

    self [[level.fun_mode_gun_game_previous_killed]](
        inflictor, attacker, damage, meansOfDeath, weapon,
        direction, hitLocation, timeOffset, deathAnimDuration
    );
}

ConfirmKill(victim, assignedWeapon)
{
    self endon("disconnect");
    self endon("gun_game_changed");
    victim endon("disconnect");
    victim endon("spawned_player");
    level endon("game_ended");

    wait 0.05;

    if (
        IsEnabled() &&
        !IsAlive(victim) &&
        IsDefined(victim.sessionstate) &&
        victim.sessionstate == "dead" &&
        IsDefined(self.fun_mode_gun_game_weapon) &&
        self.fun_mode_gun_game_weapon == assignedWeapon
    )
    {
        if (self RollPrimary())
        {
            self thread ApplyAfterLoadout();
        }
    }
}

ShouldAdvance(victim, attacker, weapon, meansOfDeath)
{
    if (
        !IsEnabled() ||
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        attacker == victim ||
        !IsDefined(weapon) ||
        !IsDefined(meansOfDeath) ||
        !IsDefined(attacker.fun_mode_gun_game_weapon) ||
        !IsDefined(attacker.fun_mode_gun_game_primary) ||
        IsDefined(victim.switching_teams) ||
        (IsDefined(attacker.fun_mode_kill_mode_damage_active) &&
            attacker.fun_mode_kill_mode_damage_active)
    )
    {
        return false;
    }

    if (
        IsDefined(level.teamBased) &&
        level.teamBased &&
        (
            !IsDefined(victim.team) ||
            !IsDefined(attacker.team) ||
            victim.team == attacker.team
        )
    )
    {
        return false;
    }

    primary = attacker.fun_mode_gun_game_primary["loadoutPrimary"];

    if (!IsEligibleWeapon(primary))
    {
        return false;
    }

    if (
        meansOfDeath != "MOD_RIFLE_BULLET" &&
        meansOfDeath != "MOD_PISTOL_BULLET" &&
        meansOfDeath != "MOD_HEAD_SHOT" &&
        meansOfDeath != "MOD_IMPACT" &&
        meansOfDeath != "MOD_PROJECTILE" &&
        meansOfDeath != "MOD_PROJECTILE_SPLASH" &&
        meansOfDeath != "MOD_GRENADE" &&
        meansOfDeath != "MOD_GRENADE_SPLASH" &&
        meansOfDeath != "MOD_EXPLOSIVE_BULLET"
    )
    {
        return false;
    }

    prefix = primary + "_mp";
    alternate = WeaponAltWeaponName(attacker.fun_mode_gun_game_weapon);
    return (
        weapon == prefix ||
        (IsDefined(alternate) && alternate != "none" && weapon == alternate) ||
        (weapon.size > prefix.size &&
            GetSubStr(weapon, 0, prefix.size + 1) == prefix + "_")
    );
}
