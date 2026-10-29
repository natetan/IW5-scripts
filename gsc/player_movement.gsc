#include maps\mp\_utility;

/*
    Player Loadout and Movement - IW5 / Plutonium

    Coordinates changed-kit behavior, global Dolphin Dive, Marathon and
    shotgun proficiency grants, weapon mobility, sprint-only speed, Juiced
    composition, and kill momentum.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_kill_momentum_enable", 1);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_duration", 1.50);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_start", 1.20);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_step", 0.025);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_max", 1.30);
    SetDvarIfNotInitialized("fun_mode_kill_momentum_max_stacks", 5);
    SetDvarIfNotInitialized("fun_mode_sniper_mobility_enable", 1);
    SetDvarIfNotInitialized("fun_mode_sniper_mobility_target", 1.0);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_sprint_speed_enable", 1);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_sprint_speed_multiplier", 1.10);
    SetDvarIfNotInitialized("fun_mode_extreme_conditioning_marathon_enable", 1);
    SetDvarIfNotInitialized("fun_mode_pistol_mobility_enable", 1);
    SetDvarIfNotInitialized("fun_mode_pistol_mobility_target", 1.0);
    SetDvarIfNotInitialized("fun_mode_dolphin_dive_enable", 1);
}

OnPlayerConnected()
{
    self thread WatchKillMomentum();
    self thread WatchKillMomentumSpawns();
    self thread WatchExtremeConditioningSprintSpawns();
    self thread WatchWeaponMobilitySpawns();
    self thread WatchDolphinDiveSpawns();
}

WatchDolphinDiveSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self thread ApplyDolphinDiveAfterLoadout();
    }
}

ApplyDolphinDiveAfterLoadout()
{
    self endon("disconnect");
    self endon("death");
    self endon("spawned_player");

    // Let the stock or Bot Warfare loadout finish rebuilding perks first.
    wait 0.25;

    if (
        GetDvarInt("fun_mode_dolphin_dive_enable") &&
        IsAlive(self) &&
        IsDefined(self.sessionState) &&
        self.sessionState == "playing"
    )
    {
        self SetPerk("specialty_jumpdive", true, false);
    }
}

OnHumanPlayerConnected()
{
    self thread WatchPlayerLoadout();
}

WatchPlayerLoadout()
{
    self endon("disconnect");

    if (scripts\specialist_system::IsSurvivalMode())
    {
        return;
    }

    for (;;)
    {
        // Fired after spawning and when changing classes.
        self waittill("changed_kit");

        self scripts\knife_runner::ResetLoadoutState();

        wait 0.1;

        self ApplyExtremeConditioningMarathon();
        self scripts\knife_runner::UpdateKnifeRunnerLoadoutState();
        self ApplyShotgunProficiencies();

        if (self scripts\specialist_system::IsFunModeSuperClassOwner())
        {
            // this is the standard give all perks from the game itself
            // self maps\mp\killstreaks\_killstreaks::giveallperks();
            self scripts\specialist_system::GiveFullSpecialistBonus();
            self RestoreJuicedMovementAfterSpecialist();
            self ApplyActiveKillMomentumSpeed();
            self thread scripts\specialist_system::RestoreFunModeBlindEyeAfterSpawnProtection();
            // self ApplyFullSpecialistState();
        }
    }
}

ApplyExtremeConditioningMarathon()
{
    selectedExtremeConditioning = (
        IsDefined(self.loadoutPerk1) &&
        self.loadoutPerk1 == "specialty_longersprint"
    );

    if (
        !GetDvarInt("fun_mode_extreme_conditioning_marathon_enable") ||
        (
            !selectedExtremeConditioning &&
            !self scripts\specialist_system::IsFunModeSuperClassOwner()
        )
    )
    {
        return;
    }

    // Ordinary Specialist-granted copies still do not activate Marathon.
    self SetPerk("specialty_marathon", true, false);
}

ApplyShotgunProficiencies()
{
    hasShotgun = false;

    if (
        IsDefined(self.primaryWeapon) &&
        WeaponClass(self.primaryWeapon) == "shotgun"
    )
    {
        hasShotgun = true;
    }
    else if (
        IsDefined(self.secondaryWeapon) &&
        WeaponClass(self.secondaryWeapon) == "shotgun"
    )
    {
        hasShotgun = true;
    }

    if (hasShotgun)
    {
        self GivePerk("specialty_longerrange", false);
        self GivePerk("specialty_moredamage", false);
    }
}

WatchKillMomentumSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_kill_momentum_stacks = 0;
        self.fun_mode_kill_momentum_speed = undefined;
        self notify("fun_mode_kill_momentum_refresh");
    }
}

WatchExtremeConditioningSprintSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_extreme_conditioning_sprinting = false;
        self thread WatchExtremeConditioningSprintLife();
    }
}

WatchExtremeConditioningSprintLife()
{
    self endon("disconnect");
    self endon("death");
    self endon("spawned_player");

    for (;;)
    {
        self waittill("sprint_begin");
        self.fun_mode_extreme_conditioning_sprinting = true;
        self RefreshFunModeMovementSpeed();

        self waittill("sprint_end");
        self.fun_mode_extreme_conditioning_sprinting = false;
        self RefreshFunModeMovementSpeed();
    }
}

WatchWeaponMobilitySpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self scripts\knife_runner::InvalidateKnifeRunnerInvulnerabilityHud();
        wait 0.1;

        if (!IsAlive(self))
        {
            continue;
        }

        self RefreshFunModeMovementSpeed();
        self thread WatchWeaponMobilityLife();
    }
}

WatchWeaponMobilityLife()
{
    self endon("disconnect");
    self endon("death");
    self endon("spawned_player");

    for (;;)
    {
        self waittill("weapon_change");

        // Let IW5 finish its own weapon-change mobility update first.
        wait 0.05;

        if (IsAlive(self))
        {
            self RefreshFunModeMovementSpeed();
        }
    }
}

GetExtremeConditioningSprintSpeedMultiplier()
{
    if (
        !GetDvarInt("fun_mode_extreme_conditioning_sprint_speed_enable") ||
        !IsDefined(self.fun_mode_extreme_conditioning_sprinting) ||
        !self.fun_mode_extreme_conditioning_sprinting ||
        !self maps\mp\_utility::_hasPerk("specialty_longersprint")
    )
    {
        return 1.0;
    }

    if (self scripts\knife_runner::IsKnifeRunnerActive())
    {
        multiplier = GetDvarFloat(
            "fun_mode_knife_runner_sprint_speed_multiplier"
        );
    }
    else
    {
        multiplier = GetDvarFloat(
            "fun_mode_extreme_conditioning_sprint_speed_multiplier"
        );
    }

    if (multiplier < 1.0)
    {
        multiplier = 1.0;
    }

    return multiplier;
}

GetFunModeBaseMoveSpeed()
{
    speed = 1.0;

    if (IsDefined(self.isjuiced) && self.isjuiced)
    {
        speed = 1.25;
    }
    else if (
        IsDefined(self.isJuggernaut) &&
        self.isJuggernaut &&
        IsDefined(self.juggMoveSpeedScaler)
    )
    {
        speed = self.juggMoveSpeedScaler;
    }
    else if (self maps\mp\_utility::_hasPerk("specialty_lightweight"))
    {
        speed = maps\mp\_utility::lightweightScalar();
    }

    return speed *
        (self GetCurrentWeaponMobilityMultiplier()) *
        (self GetExtremeConditioningSprintSpeedMultiplier());
}

GetCurrentWeaponMobilityMultiplier()
{
    sniperMultiplier = self GetSniperDrawnMobilityMultiplier();

    if (sniperMultiplier > 1.0)
    {
        return sniperMultiplier;
    }

    pistolMultiplier = self GetPistolDrawnMobilityMultiplier();

    if (pistolMultiplier > 1.0)
    {
        return pistolMultiplier;
    }

    return 1.0;
}

GetSniperDrawnMobilityMultiplier()
{
    if (
        !GetDvarInt("fun_mode_sniper_mobility_enable") ||
        !IsAlive(self) ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut) ||
        !IsDefined(self.weaponSpeed) ||
        self.weaponSpeed <= 0
    )
    {
        return 1.0;
    }

    weapon = self GetCurrentWeapon();

    if (!IsDefined(weapon) || weapon == "none" || WeaponClass(weapon) != "sniper")
    {
        return 1.0;
    }

    targetMobility = GetDvarFloat("fun_mode_sniper_mobility_target");

    if (targetMobility <= self.weaponSpeed)
    {
        return 1.0;
    }

    return targetMobility / self.weaponSpeed;
}

GetPistolDrawnMobilityMultiplier()
{
    if (
        !GetDvarInt("fun_mode_pistol_mobility_enable") ||
        !IsAlive(self) ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut) ||
        !IsDefined(self.weaponSpeed) ||
        self.weaponSpeed <= 0
    )
    {
        return 1.0;
    }

    weapon = self GetCurrentWeapon();

    if (!IsFunModeHandgun(weapon))
    {
        return 1.0;
    }

    targetMobility = GetDvarFloat("fun_mode_pistol_mobility_target");

    if (targetMobility <= self.weaponSpeed)
    {
        return 1.0;
    }

    return targetMobility / self.weaponSpeed;
}

IsFunModeHandgun(weapon)
{
    if (!IsDefined(weapon) || weapon == "none")
    {
        return false;
    }

    return (
        IsSubStr(weapon, "iw5_usp45_mp") ||
        IsSubStr(weapon, "iw5_p99_mp") ||
        IsSubStr(weapon, "iw5_mp412_mp") ||
        IsSubStr(weapon, "iw5_44magnum_mp") ||
        IsSubStr(weapon, "iw5_fnfiveseven_mp") ||
        IsSubStr(weapon, "iw5_deserteagle_mp")
    );
}

RestoreFunModeBaseMoveSpeed()
{
    self.moveSpeedScaler = self GetFunModeBaseMoveSpeed();
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

ApplyActiveKillMomentumSpeed()
{
    if (!IsDefined(self.fun_mode_kill_momentum_speed))
    {
        return;
    }

    speed = self.fun_mode_kill_momentum_speed *
        (self GetCurrentWeaponMobilityMultiplier()) *
        (self GetExtremeConditioningSprintSpeedMultiplier());
    baseSpeed = self GetFunModeBaseMoveSpeed();

    if (speed < baseSpeed)
    {
        speed = baseSpeed;
    }

    self.moveSpeedScaler = speed;
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

RefreshFunModeMovementSpeed()
{
    self RestoreFunModeBaseMoveSpeed();
    self ApplyActiveKillMomentumSpeed();
    self scripts\knife_runner::UpdateKnifeRunnerActivationFeedback();
}

WatchKillMomentum()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (!GetDvarInt("fun_mode_kill_momentum_enable") || !IsAlive(self))
        {
            continue;
        }

        if (!IsDefined(self.fun_mode_kill_momentum_stacks))
        {
            self.fun_mode_kill_momentum_stacks = 0;
        }

        self.fun_mode_kill_momentum_stacks++;

        maximumStacks = GetDvarInt("fun_mode_kill_momentum_max_stacks");

        if (maximumStacks < 1)
        {
            maximumStacks = 1;
        }

        if (self.fun_mode_kill_momentum_stacks > maximumStacks)
        {
            self.fun_mode_kill_momentum_stacks = maximumStacks;
        }

        self UpdateKillMomentumSpeedFromStacks();
        self ApplyActiveKillMomentumSpeed();
        self notify("fun_mode_kill_momentum_refresh");
        self thread DecayKillMomentumAfterDelay();
    }
}

UpdateKillMomentumSpeedFromStacks()
{
    speed = GetDvarFloat("fun_mode_kill_momentum_start") +
        (
            (self.fun_mode_kill_momentum_stacks - 1) *
            GetDvarFloat("fun_mode_kill_momentum_step")
        );
    maximumSpeed = GetDvarFloat("fun_mode_kill_momentum_max");

    if (speed > maximumSpeed)
    {
        speed = maximumSpeed;
    }

    self.fun_mode_kill_momentum_speed = speed;
}

DecayKillMomentumAfterDelay()
{
    self endon("disconnect");
    self endon("death");
    self endon("fun_mode_kill_momentum_refresh");

    duration = GetDvarFloat("fun_mode_kill_momentum_duration");

    if (duration < 0.05)
    {
        duration = 0.05;
    }

    for (;;)
    {
        wait duration;

        self.fun_mode_kill_momentum_stacks--;

        if (self.fun_mode_kill_momentum_stacks <= 0)
        {
            self.fun_mode_kill_momentum_stacks = 0;
            self.fun_mode_kill_momentum_speed = undefined;
            self RestoreFunModeBaseMoveSpeed();
            return;
        }

        self UpdateKillMomentumSpeedFromStacks();
        self ApplyActiveKillMomentumSpeed();
    }
}

/*
    Lightweight and Juiced both assign moveSpeedScaler rather than composing
    their bonuses. Fun Mode grants Lightweight after changed_kit, which can
    overwrite an already-active Juiced deathstreak from 1.25 back to 1.10.
*/
RestoreJuicedMovementAfterSpecialist()
{
    if (!IsDefined(self.isjuiced) || !self.isjuiced)
    {
        return;
    }

    self.moveSpeedScaler = self GetFunModeBaseMoveSpeed();
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

