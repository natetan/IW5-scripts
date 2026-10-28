#include maps\mp\_utility;

/*
    Knife Runner - IW5 / Plutonium

    Owns loadout qualification, weapon restrictions, active-state detection,
    post-kill immunity, activation feedback, and the immunity countdown HUD.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_knife_runner_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_sprint_speed_multiplier", 1.50);
    SetDvarIfNotInitialized("fun_mode_knife_runner_invulnerability_seconds", 2.00);
    SetDvarIfNotInitialized("fun_mode_knife_runner_invulnerability_hud_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_message_enable", 1);
    SetDvarIfNotInitialized("fun_mode_knife_runner_message", "Knife Runner Enabled: 1.5x speed");
}

OnPlayerConnected()
{
    self thread WatchKnifeRunnerKills();
}

OnHumanPlayerConnected()
{
    self thread WatchKnifeRunnerInvulnerabilityHudDeaths();
}

ResetLoadoutState()
{
    self.fun_mode_knife_runner_loadout = false;
    self.fun_mode_knife_runner_invulnerable_until = undefined;
    self.fun_mode_knife_runner_activation_announced = false;
    self InvalidateKnifeRunnerInvulnerabilityHud();
}

UpdateKnifeRunnerLoadoutState()
{
    self.fun_mode_knife_runner_class_num = self.class_num;
    self.fun_mode_knife_runner_deathstreak = undefined;

    if (
        IsDefined(self.pers["fun_mode_temporary_loadout_active"]) &&
        self.pers["fun_mode_temporary_loadout_active"] == "knife" &&
        IsDefined(self.pers["gamemodeLoadout"]) &&
        IsDefined(self.pers["gamemodeLoadout"]["loadoutDeathstreak"])
    )
    {
        self.fun_mode_knife_runner_deathstreak =
            self.pers["gamemodeLoadout"]["loadoutDeathstreak"];
    }
    else if (IsDefined(self.class_num))
    {
        self.fun_mode_knife_runner_deathstreak =
            self maps\mp\gametypes\_class::cac_getDeathstreak(self.class_num);
    }

    self.fun_mode_knife_runner_loadout = (
        GetDvarInt("fun_mode_knife_runner_enable") &&
        IsDefined(self.loadoutPerk1) &&
        self.loadoutPerk1 == "specialty_longersprint" &&
        IsDefined(self.loadoutPerk2) &&
        self.loadoutPerk2 == "specialty_quickdraw" &&
        IsDefined(self.loadoutPerk3) &&
        self.loadoutPerk3 == "specialty_quieter" &&
        IsDefined(self.loadoutPerkEquipment) &&
        self.loadoutPerkEquipment == "throwingknife_mp" &&
        IsDefined(self.fun_mode_knife_runner_deathstreak) &&
        self.fun_mode_knife_runner_deathstreak == "specialty_juiced" &&
        self maps\mp\_utility::_hasPerk("specialty_tacticalinsertion") &&
        IsKnifeRunnerWeapon(self.secondaryWeapon)
    );

    self ApplyKnifeRunnerLoadoutRestrictions();
    self UpdateKnifeRunnerActivationFeedback();
}

ApplyKnifeRunnerLoadoutRestrictions()
{
    if (
        !IsDefined(self.fun_mode_knife_runner_loadout) ||
        !self.fun_mode_knife_runner_loadout
    )
    {
        if (
            IsDefined(self.fun_mode_knife_runner_pickup_disabled) &&
            self.fun_mode_knife_runner_pickup_disabled
        )
        {
            self EnableWeaponPickup();
            self.fun_mode_knife_runner_pickup_disabled = false;
        }

        return;
    }

    self DisableWeaponPickup();
    self.fun_mode_knife_runner_pickup_disabled = true;

    if (
        IsDefined(self.primaryWeapon) &&
        self.primaryWeapon != "none" &&
        self HasWeapon(self.primaryWeapon)
    )
    {
        self TakeWeapon(self.primaryWeapon);
    }

    if (
        IsDefined(self.secondaryWeapon) &&
        self.secondaryWeapon != "none" &&
        self HasWeapon(self.secondaryWeapon)
    )
    {
        self SetWeaponAmmoClip(self.secondaryWeapon, 0);
        self SetWeaponAmmoStock(self.secondaryWeapon, 0);
        self SwitchToWeapon(self.secondaryWeapon);
    }
}

IsKnifeRunnerActive()
{
    if (
        !GetDvarInt("fun_mode_knife_runner_enable") ||
        !IsAlive(self) ||
        !IsDefined(self.fun_mode_knife_runner_loadout) ||
        !self.fun_mode_knife_runner_loadout ||
        !IsDefined(self.fun_mode_knife_runner_class_num) ||
        !IsDefined(self.class_num) ||
        self.fun_mode_knife_runner_class_num != self.class_num ||
        (IsDefined(self.isJuggernaut) && self.isJuggernaut)
    )
    {
        return false;
    }

    return IsKnifeRunnerWeapon(self GetCurrentWeapon());
}

IsKnifeRunnerWeapon(weapon)
{
    if (!IsDefined(weapon) || weapon == "none")
    {
        return false;
    }

    if (IsSubStr(weapon, "iw5_") && IsSubStr(weapon, "_tactical"))
    {
        return true;
    }

    return (
        IsSubStr(weapon, "iw5_usp45_mp") &&
        IsSubStr(weapon, "_akimbo")
    );
}

UpdateKnifeRunnerActivationFeedback()
{
    if (
        self IsBotPlayer() ||
        !GetDvarInt("fun_mode_knife_runner_message_enable") ||
        !self IsKnifeRunnerActive() ||
        (
            IsDefined(self.fun_mode_knife_runner_activation_announced) &&
            self.fun_mode_knife_runner_activation_announced
        )
    )
    {
        return;
    }

    self.fun_mode_knife_runner_activation_announced = true;
    self ShowFunModeCenterMessage(GetDvar("fun_mode_knife_runner_message"));
}

ShowFunModeCenterMessage(message)
{
    if (!IsDefined(message) || message == "")
    {
        return;
    }

    self IPrintLnBold(message);
}

WatchKnifeRunnerKills()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (
            !IsAlive(self) ||
            !self IsKnifeRunnerInvulnerabilityKill() ||
            !self IsKnifeRunnerActive()
        )
        {
            continue;
        }

        duration = GetDvarFloat(
            "fun_mode_knife_runner_invulnerability_seconds"
        );

        if (duration <= 0)
        {
            continue;
        }

        self.fun_mode_knife_runner_invulnerable_until = GetTime() + Int(duration * 1000);
        self ShowKnifeRunnerInvulnerabilityHud(duration);
    }
}

IsKnifeRunnerInvulnerabilityKill()
{
    if (
        IsDefined(self.fun_mode_last_damage_means) &&
        self.fun_mode_last_damage_means == "MOD_MELEE"
    )
    {
        return true;
    }

    return (
        IsDefined(self.fun_mode_last_damage_weapon) &&
        IsSubStr(self.fun_mode_last_damage_weapon, "throwingknife_mp")
    );
}

WatchKnifeRunnerInvulnerabilityHudDeaths()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("death");
        self InvalidateKnifeRunnerInvulnerabilityHud();
    }
}

ShowKnifeRunnerInvulnerabilityHud(duration)
{
    if (
        self IsBotPlayer() ||
        !GetDvarInt("fun_mode_knife_runner_invulnerability_hud_enable") ||
        !IsDefined(duration) ||
        duration <= 0
    )
    {
        return;
    }

    self InvalidateKnifeRunnerInvulnerabilityHud();
    generation = self.fun_mode_knife_runner_invulnerability_hud_generation;

    self.fun_mode_knife_runner_invulnerability_label = NewClientHudElem(self);
    self.fun_mode_knife_runner_invulnerability_label.alignX = "center";
    self.fun_mode_knife_runner_invulnerability_label.alignY = "middle";
    self.fun_mode_knife_runner_invulnerability_label.horzAlign = "center";
    self.fun_mode_knife_runner_invulnerability_label.vertAlign = "middle";
    self.fun_mode_knife_runner_invulnerability_label.x = 0;
    self.fun_mode_knife_runner_invulnerability_label.y = 62;
    self.fun_mode_knife_runner_invulnerability_label.font = "default";
    self.fun_mode_knife_runner_invulnerability_label.fontScale = 1.3;
    self.fun_mode_knife_runner_invulnerability_label SetText("INVULNERABLE");
    self.fun_mode_knife_runner_invulnerability_label.color = (1, 0.75, 0.2);
    self.fun_mode_knife_runner_invulnerability_label.foreground = true;
    self.fun_mode_knife_runner_invulnerability_label.hideWhenInMenu = true;
    self.fun_mode_knife_runner_invulnerability_label.sort = 1000;

    self.fun_mode_knife_runner_invulnerability_timer = NewClientHudElem(self);
    self.fun_mode_knife_runner_invulnerability_timer.alignX = "center";
    self.fun_mode_knife_runner_invulnerability_timer.alignY = "middle";
    self.fun_mode_knife_runner_invulnerability_timer.horzAlign = "center";
    self.fun_mode_knife_runner_invulnerability_timer.vertAlign = "middle";
    self.fun_mode_knife_runner_invulnerability_timer.x = 0;
    self.fun_mode_knife_runner_invulnerability_timer.y = 80;
    self.fun_mode_knife_runner_invulnerability_timer.font = "hudbig";
    self.fun_mode_knife_runner_invulnerability_timer.fontScale = 0.8;
    self.fun_mode_knife_runner_invulnerability_timer.color = (1, 1, 1);
    self.fun_mode_knife_runner_invulnerability_timer.foreground = true;
    self.fun_mode_knife_runner_invulnerability_timer.hideWhenInMenu = true;
    self.fun_mode_knife_runner_invulnerability_timer.sort = 1000;
    self.fun_mode_knife_runner_invulnerability_timer SetTenthsTimer(duration);

    self thread ClearKnifeRunnerInvulnerabilityHudAfterDelay(
        duration,
        generation
    );
}

ClearKnifeRunnerInvulnerabilityHudAfterDelay(duration, generation)
{
    self endon("disconnect");

    wait duration + 0.05;

    if (
        !IsDefined(self.fun_mode_knife_runner_invulnerability_hud_generation) ||
        self.fun_mode_knife_runner_invulnerability_hud_generation != generation
    )
    {
        return;
    }

    self DestroyKnifeRunnerInvulnerabilityHud();
}

InvalidateKnifeRunnerInvulnerabilityHud()
{
    if (!IsDefined(self.fun_mode_knife_runner_invulnerability_hud_generation))
    {
        self.fun_mode_knife_runner_invulnerability_hud_generation = 0;
    }

    self.fun_mode_knife_runner_invulnerability_hud_generation++;
    self DestroyKnifeRunnerInvulnerabilityHud();
}

DestroyKnifeRunnerInvulnerabilityHud()
{
    if (IsDefined(self.fun_mode_knife_runner_invulnerability_label))
    {
        self.fun_mode_knife_runner_invulnerability_label Destroy();
        self.fun_mode_knife_runner_invulnerability_label = undefined;
    }

    if (IsDefined(self.fun_mode_knife_runner_invulnerability_timer))
    {
        self.fun_mode_knife_runner_invulnerability_timer Destroy();
        self.fun_mode_knife_runner_invulnerability_timer = undefined;
    }
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

