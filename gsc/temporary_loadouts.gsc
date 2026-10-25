/*
    Temporary Loadout Presets - IW5 / Plutonium

    Lets human players select a match-temporary preset through chat. The
    selected preset is rebuilt from the currently selected custom class on
    every spawn, preserving that class's lethal/tactical equipment and strike
    package unless the preset explicitly replaces them.

    Commands:
        !sniper  Barrett / MP9 long-range preset
        !gunner  ACR / MP412 general-purpose preset
        !smg     MP7 / MP9 mobile preset
        !boom    ACR grenade-launcher / Javelin explosive preset
        !knife   Knife Runner preset
        !default Return to the selected saved class on the next spawn

    Presets intentionally pass through the stock giveLoadout path so the
    repository's automatic extended-mag and post-loadout systems still run.
*/

#include maps\mp\gametypes\_class;

main()
{
    setdvarifuninitialized("fun_mode_temporary_loadouts_enable", 1);

    if (!getdvarint("fun_mode_temporary_loadouts_enable"))
    {
        return;
    }

    level thread WatchTemporaryLoadoutCommands();
    level thread WatchTemporaryLoadoutConnections();
}

WatchTemporaryLoadoutCommands()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("say", message, player, isHidden);

        if (!IsEligibleTemporaryLoadoutPlayer(player))
        {
            continue;
        }

        if (message == "!sniper")
        {
            player SetTemporaryLoadoutPreset("sniper", "Sniper");
        }
        else if (message == "!gunner")
        {
            player SetTemporaryLoadoutPreset("gunner", "Gunner");
        }
        else if (message == "!smg")
        {
            player SetTemporaryLoadoutPreset("smg", "SMG");
        }
        else if (message == "!boom")
        {
            player SetTemporaryLoadoutPreset("boom", "Boom");
        }
        else if (message == "!knife")
        {
            player SetTemporaryLoadoutPreset("knife", "Knife Runner");
        }
        else if (message == "!default")
        {
            player ClearTemporaryLoadoutPreset();
        }
    }
}

WatchTemporaryLoadoutConnections()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (IsEligibleTemporaryLoadoutPlayer(player))
        {
            player EnsureTemporaryLoadoutSpawnWatcher();
        }
    }
}

EnsureTemporaryLoadoutSpawnWatcher()
{
    if (
        IsDefined(self.pers["fun_mode_temporary_loadout_watcher"]) &&
        self.pers["fun_mode_temporary_loadout_watcher"]
    )
    {
        return;
    }

    self.pers["fun_mode_temporary_loadout_watcher"] = true;
    self thread WatchTemporaryLoadoutSpawns();
}

WatchTemporaryLoadoutSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");

        if (!IsDefined(self.pers["fun_mode_temporary_loadout_preset"]))
        {
            continue;
        }

        // Let the selected saved class finish loading before cloning it.
        wait 0.1;

        if (
            !IsDefined(self.curClass) ||
            !IsSubStr(self.curClass, "custom") ||
            self.sessionstate != "playing"
        )
        {
            self IPrintLnBold("Temporary presets require a custom class");
            continue;
        }

        loadout = self maps\mp\gametypes\_class::cloneLoadout();

        if (!IsDefined(loadout))
        {
            continue;
        }

        preset = self.pers["fun_mode_temporary_loadout_preset"];

        loadout = self ApplyTemporaryLoadoutPreset(loadout, preset);

        if (!IsDefined(loadout))
        {
            continue;
        }

        loadout["loadoutJuggernaut"] = false;
        self.pers["gamemodeLoadout"] = loadout;
        self.pers["fun_mode_temporary_loadout_active"] = preset;
        self maps\mp\gametypes\_class::giveLoadout(
            self.pers["team"],
            "gamemode",
            false,
            true
        );
        // giveLoadout removes all inventory items, including activation
        // weapons. Ask the stock streak system to reconstruct those weapons,
        // action slots, queue selection, and HUD from its untouched state.
        // Passing keepCurrent prevents it from consuming the selected reward.
        self maps\mp\killstreaks\_killstreaks::updateKillstreaks(true);
    }
}

ApplyTemporaryLoadoutPreset(loadout, preset)
{
    if (preset == "sniper")
    {
        loadout = SetTemporaryPrimary(
            loadout,
            "iw5_barrett",
            "heartbeat",
            "specialty_bulletpenetration"
        );
        loadout = SetTemporarySecondary(
            loadout,
            "iw5_mp9",
            "silencer02"
        );
        loadout = SetTemporaryCorePerks(
            loadout,
            "specialty_detectexplosive"
        );
        return loadout;
    }

    if (preset == "gunner")
    {
        loadout = SetTemporaryPrimary(
            loadout,
            "iw5_acr",
            "reflex",
            "specialty_bulletpenetration"
        );
        loadout = SetTemporarySecondary(
            loadout,
            "iw5_mp412",
            "tactical"
        );
        loadout = SetTemporaryCorePerks(
            loadout,
            "specialty_detectexplosive"
        );
        return loadout;
    }

    if (preset == "smg")
    {
        loadout = SetTemporaryPrimary(
            loadout,
            "iw5_mp7",
            "silencer",
            "specialty_sharp_focus"
        );
        loadout = SetTemporarySecondary(
            loadout,
            "iw5_mp9",
            "silencer02"
        );
        loadout["loadoutPerk1"] = "specialty_longersprint";
        loadout["loadoutPerk2"] = "specialty_quickdraw";
        loadout["loadoutPerk3"] = "specialty_detectexplosive";
        return loadout;
    }

    if (preset == "boom")
    {
        loadout = SetTemporaryPrimary(
            loadout,
            "iw5_acr",
            "m320",
            "specialty_sharp_focus"
        );
        loadout = SetTemporarySecondary(loadout, "javelin", "none");
        loadout["loadoutPerk1"] = "specialty_fastreload";
        loadout["loadoutPerk2"] = "specialty_quickdraw";
        loadout["loadoutPerk3"] = "specialty_detectexplosive";
        return loadout;
    }

    if (preset == "knife")
    {
        loadout = SetTemporaryPrimary(
            loadout,
            "iw5_msr",
            "none",
            "specialty_null"
        );
        loadout = self SetRandomKnifeRunnerSecondary(loadout);
        loadout["loadoutPerk1"] = "specialty_longersprint";
        loadout["loadoutPerk2"] = "specialty_quickdraw";
        loadout["loadoutPerk3"] = "specialty_quieter";
        loadout["loadoutEquipment"] = "throwingknife_mp";
        loadout["loadoutOffhand"] = "specialty_tacticalinsertion";
        loadout["loadoutDeathstreak"] = "specialty_juiced";
        return loadout;
    }

    return undefined;
}

SetRandomKnifeRunnerSecondary(loadout)
{
    if (!IsDefined(self.pers["fun_mode_last_knife_secondary_choice"]))
    {
        choice = RandomInt(7);
    }
    else
    {
        // Pick from the six entries other than the previous spawn's result.
        choice = RandomInt(6);

        if (choice >= self.pers["fun_mode_last_knife_secondary_choice"])
        {
            choice++;
        }
    }

    self.pers["fun_mode_last_knife_secondary_choice"] = choice;

    if (choice == 0)
    {
        return SetTemporarySecondary(loadout, "iw5_usp45", "tactical");
    }

    if (choice == 1)
    {
        return SetTemporarySecondary(loadout, "iw5_p99", "tactical");
    }

    if (choice == 2)
    {
        return SetTemporarySecondary(loadout, "iw5_mp412", "tactical");
    }

    if (choice == 3)
    {
        return SetTemporarySecondary(loadout, "iw5_44magnum", "tactical");
    }

    if (choice == 4)
    {
        return SetTemporarySecondary(loadout, "iw5_fnfiveseven", "tactical");
    }

    if (choice == 5)
    {
        return SetTemporarySecondary(loadout, "iw5_deserteagle", "tactical");
    }

    return SetTemporarySecondary(loadout, "iw5_usp45", "akimbo");
}

SetTemporaryPrimary(loadout, weapon, attachment, proficiency)
{
    loadout["loadoutPrimary"] = weapon;
    loadout["loadoutPrimaryAttachment"] = attachment;
    loadout["loadoutPrimaryAttachment2"] = "none";
    loadout["loadoutPrimaryBuff"] = proficiency;
    loadout["loadoutPrimaryCamo"] = "gold";
    loadout["loadoutPrimaryReticle"] = "none";
    return loadout;
}

SetTemporarySecondary(loadout, weapon, attachment)
{
    loadout["loadoutSecondary"] = weapon;
    loadout["loadoutSecondaryAttachment"] = attachment;
    loadout["loadoutSecondaryAttachment2"] = "none";
    loadout["loadoutSecondaryBuff"] = "specialty_null";
    loadout["loadoutSecondaryCamo"] = "none";
    loadout["loadoutSecondaryReticle"] = "none";
    return loadout;
}

SetTemporaryCorePerks(loadout, perk3)
{
    loadout["loadoutPerk1"] = "specialty_scavenger";
    loadout["loadoutPerk2"] = "specialty_quickdraw";
    loadout["loadoutPerk3"] = perk3;
    return loadout;
}

SetTemporaryLoadoutPreset(preset, displayName)
{
    // A player can already exist when this loose script begins listening,
    // especially across private-match map restarts. Arming the watcher from
    // the command guarantees that the next spawn cannot be missed merely
    // because this script did not observe the original connected event.
    self EnsureTemporaryLoadoutSpawnWatcher();
    self.pers["fun_mode_temporary_loadout_preset"] = preset;
    self IPrintLnBold(displayName + " preset queued for next spawn");
}

ClearTemporaryLoadoutPreset()
{
    self.pers["fun_mode_temporary_loadout_preset"] = undefined;
    self.pers["fun_mode_temporary_loadout_active"] = undefined;
    self.pers["gamemodeLoadout"] = undefined;
    self IPrintLnBold("Saved class queued for next spawn");
}

IsEligibleTemporaryLoadoutPlayer(player)
{
    return (
        IsDefined(player) &&
        IsPlayer(player) &&
        (!IsDefined(player.pers["isBot"]) || !player.pers["isBot"])
    );
}
