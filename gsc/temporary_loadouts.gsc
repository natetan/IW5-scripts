/*
    Temporary Loadout Presets - IW5 / Plutonium

    Lets human players select a match-temporary preset through chat. The
    selected preset is rebuilt from the currently selected custom class on
    every spawn, preserving that class's lethal/tactical equipment and strike
    package unless the preset explicitly replaces them.

    Commands:
        !preset sniper   Barrett / MP9 long-range preset
        !preset gunner   ACR / MP412 general-purpose preset
        !preset smg      MP7 / MP9 mobile preset
        !preset boom     ACR grenade-launcher / Javelin explosive preset
        !preset knife    Knife Runner preset
        !preset random   Reroll weapons and equipment on every spawn
        !preset default  Return to the selected saved class on next spawn

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

    level thread WatchTemporaryLoadoutConnections();
}

temporaryLoadoutPresetCommand(args)
{
    if (
        !getdvarint("fun_mode_temporary_loadouts_enable") ||
        !IsEligibleTemporaryLoadoutPlayer(self)
    )
    {
        return;
    }

    if (!args.size)
    {
        self tell(
            "^3Usage:^7 !preset <sniper|gunner|smg|boom|knife|random|default>"
        );
        return;
    }

    preset = tolower(args[0]);

    if (preset == "sniper")
    {
        self SetTemporaryLoadoutPreset("sniper", "Sniper");
        return;
    }

    if (preset == "gunner")
    {
        self SetTemporaryLoadoutPreset("gunner", "Gunner");
        return;
    }

    if (preset == "smg")
    {
        self SetTemporaryLoadoutPreset("smg", "SMG");
        return;
    }

    if (preset == "boom")
    {
        self SetTemporaryLoadoutPreset("boom", "Boom");
        return;
    }

    if (preset == "knife")
    {
        self SetTemporaryLoadoutPreset("knife", "Knife Runner");
        return;
    }

    if (preset == "random")
    {
        self SetTemporaryLoadoutPreset("random", "Random");
        return;
    }

    if (preset == "default")
    {
        self ClearTemporaryLoadoutPreset();
        return;
    }

    self tell(
        "^1Unknown preset:^7 " + args[0] +
        ". ^3Options:^7 sniper, gunner, smg, boom, knife, random, default"
    );
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

        if (scripts\gun_game::IsEnabled())
        {
            continue;
        }

        if (!IsDefined(self.pers["fun_mode_temporary_loadout_preset"]))
        {
            continue;
        }

        // Let the selected saved class finish loading before cloning it.
        wait 0.1;

        if (scripts\gun_game::IsEnabled())
        {
            continue;
        }

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

    if (preset == "random")
    {
        return ApplyRandomTemporaryLoadoutPreset(loadout);
    }

    return undefined;
}

ApplyRandomTemporaryLoadoutPreset(loadout)
{
    loadout = RandomizePrimaryLoadout(loadout);

    if (!IsDefined(loadout))
    {
        return undefined;
    }

    secondary = GetRandomPresetSecondary();

    loadout["loadoutPrimaryBuff"] = GetRandomPresetProficiency(
        loadout["loadoutPrimary"]
    );

    loadout["loadoutSecondary"] = secondary;
    loadout["loadoutSecondaryAttachment"] = GetRandomPresetAttachment(secondary);
    loadout["loadoutSecondaryAttachment2"] = "none";
    loadout["loadoutSecondaryBuff"] = "specialty_null";

    lethals = [];
    lethals[lethals.size] = "frag_grenade_mp";
    lethals[lethals.size] = "throwingknife_mp";
    lethals[lethals.size] = "claymore_mp";
    lethals[lethals.size] = "semtex_mp";
    lethals[lethals.size] = "c4_mp";
    lethals[lethals.size] = "bouncingbetty_mp";
    loadout["loadoutEquipment"] = GetRandomPresetValue(lethals);

    tacticals = [];
    tacticals[tacticals.size] = "trophy_mp";
    tacticals[tacticals.size] = "smoke_grenade_mp";
    tacticals[tacticals.size] = "specialty_portable_radar";
    tacticals[tacticals.size] = "flash_grenade_mp";
    tacticals[tacticals.size] = "concussion_grenade_mp";
    tacticals[tacticals.size] = "specialty_scrambler";
    tacticals[tacticals.size] = "specialty_tacticalinsertion";
    tacticals[tacticals.size] = "emp_grenade_mp";
    loadout["loadoutOffhand"] = GetRandomPresetValue(tacticals);

    return loadout;
}

RandomizePrimaryLoadout(loadout, previousPrimary, weaponPool)
{
    if (IsDefined(weaponPool))
    {
        primary = GetRandomPresetValue(weaponPool);
    }
    else
    {
        primary = GetRandomPresetPrimary(previousPrimary);
    }
    loadout["loadoutPrimary"] = primary;

    if (!IsDefined(primary))
    {
        PrintLn("Random loadout: no eligible weapons were found.");
        return undefined;
    }

    loadout["loadoutPrimaryAttachment"] = GetRandomPresetAttachment(primary);
    loadout["loadoutPrimaryAttachment2"] = "none";
    return loadout;
}

GetRandomPresetPrimary(previousPrimary)
{
    weapons = [];

    for (row = 0; row < 160; row++)
    {
        weapon = TableLookupByRow("mp/statStable.csv", row, 4);

        if (
            weapon == "" ||
            IsSubStr(weapon, "jugg") ||
            (IsDefined(previousPrimary) && weapon == previousPrimary) ||
            !maps\mp\gametypes\_class::isValidPrimary(weapon, false)
        )
        {
            continue;
        }

        weapons[weapons.size] = weapon;
    }

    return GetRandomPresetValue(weapons);
}

GetRandomPresetSecondary()
{
    weapons = [];

    for (row = 0; row < 160; row++)
    {
        weapon = TableLookupByRow("mp/statStable.csv", row, 4);

        if (
            weapon == "" ||
            IsSubStr(weapon, "jugg") ||
            !maps\mp\gametypes\_class::isValidSecondary(
                weapon,
                "specialty_quickdraw",
                "specialty_null",
                false
            )
        )
        {
            continue;
        }

        weapons[weapons.size] = weapon;
    }

    return GetRandomPresetValue(weapons);
}

GetRandomPresetAttachment(weapon)
{
    row = TableLookupRowNum("mp/statStable.csv", 4, weapon);
    attachments = [];

    if (row < 0)
    {
        return "none";
    }

    for (column = 11; column < 21; column++)
    {
        attachment = TableLookupByRow("mp/statStable.csv", row, column);

        if (attachment == "")
        {
            break;
        }

        if (
            attachment == "none" ||
            !maps\mp\gametypes\_class::isValidAttachment(attachment, false) ||
            !maps\mp\gametypes\_class::isValidCombination(weapon, attachment)
        )
        {
            continue;
        }

        attachments[attachments.size] = attachment;
    }

    if (!attachments.size)
    {
        return "none";
    }

    return GetRandomPresetValue(attachments);
}

GetRandomPresetProficiency(weapon)
{
    proficiencies = [];
    weaponRow = TableLookupRowNum("mp/statStable.csv", 4, weapon);

    if (weaponRow < 0)
    {
        return "specialty_null";
    }

    weaponClass = TableLookupByRow(
        "mp/statStable.csv",
        weaponRow,
        2
    );

    if (weaponClass == "weapon_assault")
    {
        proficiencies[proficiencies.size] = "specialty_bling";
        proficiencies[proficiencies.size] = "specialty_bulletpenetration";
        proficiencies[proficiencies.size] = "specialty_marksman";
        proficiencies[proficiencies.size] = "specialty_sharp_focus";
        proficiencies[proficiencies.size] = "specialty_holdbreathwhileads";
        proficiencies[proficiencies.size] = "specialty_reducedsway";
    }
    else if (weaponClass == "weapon_smg")
    {
        proficiencies[proficiencies.size] = "specialty_bling";
        proficiencies[proficiencies.size] = "specialty_marksman";
        proficiencies[proficiencies.size] = "specialty_sharp_focus";
        proficiencies[proficiencies.size] = "specialty_reducedsway";
        proficiencies[proficiencies.size] = "specialty_longerrange";
        proficiencies[proficiencies.size] = "specialty_fastermelee";
    }
    else if (weaponClass == "weapon_lmg" || weaponClass == "weapon_sniper")
    {
        proficiencies[proficiencies.size] = "specialty_bling";
        proficiencies[proficiencies.size] = "specialty_bulletpenetration";
        proficiencies[proficiencies.size] = "specialty_marksman";
        proficiencies[proficiencies.size] = "specialty_sharp_focus";
        proficiencies[proficiencies.size] = "specialty_reducedsway";
        proficiencies[proficiencies.size] = "specialty_lightweight";
    }
    else if (weaponClass == "weapon_shotgun")
    {
        proficiencies[proficiencies.size] = "specialty_bling";
        proficiencies[proficiencies.size] = "specialty_marksman";
        proficiencies[proficiencies.size] = "specialty_sharp_focus";
        proficiencies[proficiencies.size] = "specialty_longerrange";
        proficiencies[proficiencies.size] = "specialty_fastermelee";
        proficiencies[proficiencies.size] = "specialty_moredamage";
    }
    else if (weaponClass == "weapon_riot")
    {
        proficiencies[proficiencies.size] = "specialty_fastermelee";
        proficiencies[proficiencies.size] = "specialty_lightweight";
    }

    if (!proficiencies.size)
    {
        return "specialty_null";
    }

    return GetRandomPresetValue(proficiencies);
}

GetRandomPresetValue(values)
{
    if (!IsDefined(values) || !values.size)
    {
        return undefined;
    }

    return values[RandomInt(values.size)];
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

    if (scripts\gun_game::IsEnabled())
    {
        self IPrintLnBold(displayName + " preset queued until Gun Game is disabled");
        return;
    }

    self IPrintLnBold(displayName + " preset queued for next spawn");
}

ClearTemporaryLoadoutPreset()
{
    self.pers["fun_mode_temporary_loadout_preset"] = undefined;
    self.pers["fun_mode_temporary_loadout_active"] = undefined;
    self.pers["gamemodeLoadout"] = undefined;
    if (scripts\gun_game::IsEnabled())
    {
        self IPrintLnBold("Saved class queued until Gun Game is disabled");
    }
    else
    {
        self IPrintLnBold("Saved class queued for next spawn");
    }
}

IsEligibleTemporaryLoadoutPlayer(player)
{
    return (
        IsDefined(player) &&
        IsPlayer(player) &&
        (!IsDefined(player.pers["isBot"]) || !player.pers["isBot"])
    );
}
