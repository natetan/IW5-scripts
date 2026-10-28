#include maps\mp\_utility;
#include maps\mp\killstreaks\_uav;

/*
    Specialist and Super-Class Systems - IW5 / Plutonium

    Owns Fun Mode class eligibility, full Specialist perk grants, Survival
    reapplication, post-Specialist UAV/random rewards, and Blind Eye recovery.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_specialist_class_index", 14);
    SetDvarIfNotInitialized("fun_mode_super_class_guids", "");
    SetDvarIfNotInitialized("fun_mode_survival_specialist_bonus", 1);
    SetDvarIfNotInitialized("fun_mode_post_specialist_enable", 1);
    SetDvarIfNotInitialized("fun_mode_post_specialist_kills", 3);
    SetDvarIfNotInitialized("fun_mode_post_specialist_uav_duration", 5);
    SetDvarIfNotInitialized("fun_mode_post_specialist_random_streak_enable", 1);
}

Initialize()
{
    level.fun_mode_temporary_uav_expires = [];
    level.fun_mode_temporary_uav_running = [];
}

OnHumanPlayerConnected()
{
    self thread WatchSurvivalFunModeSpawns();
    self thread WatchPostSpecialistRewards();
    self thread WatchPostSpecialistSpawns();
}

HasEarnedFullSpecialistBonus()
{
    if (
        !IsDefined(self.streaktype) ||
        self.streaktype != "specialist" ||
        !IsDefined(self.adrenaline) ||
        !IsDefined(self.pers["killstreaks"]) ||
        !IsDefined(self.pers["killstreaks"][4]) ||
        !IsDefined(self.pers["killstreaks"][4].streakname) ||
        self.pers["killstreaks"][4].streakname != "all_perks_bonus" ||
        !IsDefined(self.pers["killstreaks"][4].available) ||
        !self.pers["killstreaks"][4].available
    )
    {
        return false;
    }

    bonusCost = 8;

    if (self maps\mp\_utility::_hasperk("specialty_hardline"))
    {
        bonusCost--;
    }

    return self.adrenaline >= bonusCost;
}

IsSurvivalMode()
{
    return IsDefined(level.gameType) && level.gameType == "survival";
}

IsFunModeSuperClass()
{
    return (
        IsDefined(self.class_num) &&
        (
            self.class_num == 12 ||
            self.class_num == 13 ||
            self.class_num == 14
        )
    );
}

IsFunModeSuperClassOwner()
{
    if (!self IsFunModeSuperClass())
    {
        return false;
    }

    // Private matches retain the original Fun Mode behavior. Only dedicated
    // servers require an explicit player allowlist.
    if (!GetDvarInt("dedicated"))
    {
        return true;
    }

    playerGuid = self GetGuid() + "";
    allowedGuids = StrTok(GetDvar("fun_mode_super_class_guids"), ",");

    foreach (allowedGuid in allowedGuids)
    {
        if (allowedGuid == playerGuid)
        {
            return true;
        }
    }

    return false;
}

/*
    Survival Reimagined disables custom classes and replaces the stock class
    initializer. Its survivor handler clears and rebuilds perks on every spawn,
    so apply the Fun Mode bundle afterward instead of waiting for changed_kit.
*/
WatchSurvivalFunModeSpawns()
{
    self endon("disconnect");

    if (!IsSurvivalMode())
    {
        return;
    }

    for (;;)
    {
        self waittill("spawned_player");
        wait 0.25;

        if (
            !GetDvarInt("fun_mode_survival_specialist_bonus") ||
            !IsAlive(self) ||
            !IsDefined(self.pers["team"]) ||
            self.pers["team"] != "allies"
        )
        {
            continue;
        }

        self GiveFullSpecialistBonus();
        self scripts\fun_mode::RestoreJuicedMovementAfterSpecialist();
        self scripts\fun_mode::ApplyActiveKillMomentumSpeed();
        self thread RestoreFunModeBlindEyeAfterSpawnProtection();
    }
}

WatchPostSpecialistSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_real_specialist_bonus_seen = false;
        self.fun_mode_post_specialist_kills = 0;
    }
}

HasEarnedRealSpecialistBonus()
{
    if (
        !IsDefined(self.class_num) ||
        (
            self.class_num != 12 &&
            self.class_num != 13 &&
            self.class_num != 14
        ) ||
        !IsDefined(self.streaktype) ||
        self.streaktype != "specialist" ||
        !IsDefined(self.adrenaline) ||
        !IsDefined(self.pers["killstreaks"]) ||
        !IsDefined(self.pers["killstreaks"][4]) ||
        !IsDefined(self.pers["killstreaks"][4].streakname) ||
        self.pers["killstreaks"][4].streakname != "all_perks_bonus" ||
        !IsDefined(self.pers["killstreaks"][4].available) ||
        !self.pers["killstreaks"][4].available
    )
    {
        return false;
    }

    bonusCost = 8;

    if (self maps\mp\_utility::_hasperk("specialty_hardline"))
    {
        bonusCost--;
    }

    return self.adrenaline >= bonusCost;
}

GrantTemporaryTeamUAV(duration)
{
    if (
        !IsDefined(self.pers["team"]) ||
        (self.pers["team"] != "allies" && self.pers["team"] != "axis")
    )
    {
        return;
    }

    team = self.pers["team"];
    expiresAt = GetTime() + Int(duration * 1000);

    if (
        !IsDefined(level.fun_mode_temporary_uav_expires[team]) ||
        expiresAt > level.fun_mode_temporary_uav_expires[team]
    )
    {
        level.fun_mode_temporary_uav_expires[team] = expiresAt;
    }

    if (
        IsDefined(level.fun_mode_temporary_uav_running[team]) &&
        level.fun_mode_temporary_uav_running[team]
    )
    {
        return;
    }

    level.fun_mode_temporary_uav_running[team] = true;
    level thread RunTemporaryTeamUAV(team);
}

/*
    Register a hidden model as a real standard UAV. The stock UAV tracker then
    owns radar visibility, sweep timing, Counter-UAV interaction, and stacking
    with earned UAVs. Only this model and its active-UAV count are removed.
*/
RunTemporaryTeamUAV(team)
{
    level endon("game_ended");

    uav = Spawn("script_model", (0, 0, 0));
    uav.team = team;
    uav.value = 1;
    uav.uavtype = "standard";
    // Stock launchUAV() adds five seconds to every active same-team UAV.
    // Keep this synthetic model compatible with that stacking path.
    uav.timetoadd = 0;
    uav maps\mp\killstreaks\_uav::addUAVModel();
    uav maps\mp\killstreaks\_uav::addActiveUAV();
    level notify("uav_update");

    while (
        IsDefined(level.fun_mode_temporary_uav_expires[team]) &&
        GetTime() < level.fun_mode_temporary_uav_expires[team]
    )
    {
        wait 0.05;
    }

    uav maps\mp\killstreaks\_uav::removeActiveUAV();

    remainingModels = [];

    foreach (model in level.uavmodels[team])
    {
        if (!IsDefined(model) || model == uav)
        {
            continue;
        }

        remainingModels[remainingModels.size] = model;
    }

    level.uavmodels[team] = remainingModels;
    uav Delete();
    level.fun_mode_temporary_uav_running[team] = false;
    level notify("uav_update");
}

WatchPostSpecialistRewards()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        uavEligible = self HasEarnedRealSpecialistBonus();
        randomStreakEligible = (
            GetDvarInt("fun_mode_post_specialist_random_streak_enable") &&
            self CanReceiveRandomPostSpecialistKillstreak()
        );

        if (
            !GetDvarInt("fun_mode_post_specialist_enable") ||
            !IsAlive(self) ||
            (!uavEligible && !randomStreakEligible)
        )
        {
            self.fun_mode_real_specialist_bonus_seen = false;
            self.fun_mode_post_specialist_kills = 0;
            continue;
        }

        if (
            !IsDefined(self.fun_mode_real_specialist_bonus_seen) ||
            !self.fun_mode_real_specialist_bonus_seen
        )
        {
            self.fun_mode_real_specialist_bonus_seen = true;
            self.fun_mode_post_specialist_kills = 0;
            continue;
        }

        self.fun_mode_post_specialist_kills++;
        killsRequired = GetDvarInt("fun_mode_post_specialist_kills");

        if (killsRequired < 1)
        {
            killsRequired = 1;
        }

        if (self.fun_mode_post_specialist_kills < killsRequired)
        {
            continue;
        }

        self.fun_mode_post_specialist_kills = 0;

        if (uavEligible)
        {
            duration = GetDvarFloat("fun_mode_post_specialist_uav_duration");

            if (duration > 0)
            {
                self GrantTemporaryTeamUAV(duration);
            }
        }

        if (randomStreakEligible)
        {
            self GrantRandomPostSpecialistKillstreak();
        }
    }
}

CanReceiveRandomPostSpecialistKillstreak()
{
    if (!self HasEarnedFullSpecialistBonus())
    {
        return false;
    }

    // Bots may use any class, but still have to run Specialist and genuinely
    // earn its full bonus before post-bonus kills can grant random streaks.
    if (self IsBotPlayer())
    {
        return true;
    }

    // Reuse the established Fun Mode policy: classes 13-15 are unrestricted
    // in private matches and require the configured GUID on dedicated servers.
    return self IsFunModeSuperClassOwner();
}

GrantRandomPostSpecialistKillstreak()
{
    /*
        Use the stock gimme-reward path so the reward occupies slot zero and
        additional rewards queue behind it. Avoid MOAB and Specialist perks.
        Juggernauts remain their native care-package rewards, so the package
        may be claimed by its owner, a teammate, or an enemy.
    */
    rewardPool = [];
    rewardPool[rewardPool.size] = "uav";
    rewardPool[rewardPool.size] = "uav_support";
    rewardPool[rewardPool.size] = "counter_uav";
    rewardPool[rewardPool.size] = "deployable_vest";
    rewardPool[rewardPool.size] = "airdrop_trap";
    rewardPool[rewardPool.size] = "airdrop_juggernaut";
    rewardPool[rewardPool.size] = "airdrop_juggernaut_recon";
    rewardPool[rewardPool.size] = "predator_missile";
    rewardPool[rewardPool.size] = "ims";
    rewardPool[rewardPool.size] = "precision_airstrike";
    rewardPool[rewardPool.size] = "helicopter";
    rewardPool[rewardPool.size] = "sam_turret";
    rewardPool[rewardPool.size] = "littlebird_flock";
    rewardPool[rewardPool.size] = "littlebird_support";
    rewardPool[rewardPool.size] = "remote_mortar";
    rewardPool[rewardPool.size] = "remote_uav";
    rewardPool[rewardPool.size] = "remote_tank";
    rewardPool[rewardPool.size] = "triple_uav";
    rewardPool[rewardPool.size] = "remote_mg_turret";
    rewardPool[rewardPool.size] = "ac130";
    rewardPool[rewardPool.size] = "helicopter_flares";
    rewardPool[rewardPool.size] = "stealth_airstrike";
    rewardPool[rewardPool.size] = "emp";
    rewardPool[rewardPool.size] = "escort_airdrop";
    rewardPool[rewardPool.size] = "osprey_gunner";

    availableRewards = [];

    foreach (reward in rewardPool)
    {
        if (
            IsDefined(level.killstreakfuncs) &&
            IsDefined(level.killstreakfuncs[reward])
        )
        {
            availableRewards[availableRewards.size] = reward;
        }
    }

    if (!availableRewards.size)
    {
        return;
    }

    reward = availableRewards[RandomInt(availableRewards.size)];
    self thread maps\mp\killstreaks\_killstreaks::givekillstreak(
        reward,
        0,
        0,
        self,
        0
    );
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
        self IsFunModeSuperClassOwner() &&
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
    self GivePerk("specialty_fastermelee", false);
    self GivePerk("specialty_reducedsway", false);
    self GivePerk("specialty_lightweight", false); // Movement-speed boost

    // Fun-mode addition: stack Impact with the class's selected proficiency.
    // Unsupported weapon classes ignore this flag.
    self GivePerk("specialty_bulletpenetration", false);
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

