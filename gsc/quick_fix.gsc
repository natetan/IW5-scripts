#include maps\mp\_utility;

/*
    Quick Fix - IW5 / Plutonium

    Restores health after every kill, then grants consumable overhealth up to
    the configured cap. A Ballistic Vest-style overlay communicates remaining
    overhealth to human players. Real Ballistic Vests retain ownership of
    max-health behavior while equipped.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_quick_fix_enable", 1);
    SetDvarIfNotInitialized("fun_mode_quick_fix_heal_percent", 0.25);
    SetDvarIfNotInitialized("fun_mode_quick_fix_overheal_percent", 0.10);
    SetDvarIfNotInitialized("fun_mode_quick_fix_max_percent", 2.00);
}

OnPlayerConnected()
{
    self thread WatchQuickFix();
    self thread WatchQuickFixSpawns();
}

/*
    Capture the game mode's real health setting on every spawn. Overhealth
    temporarily raises maxHealth, so this stored value remains the
    authoritative base until death resets the player.
*/
WatchQuickFixSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        wait 0.05;

        self.fun_mode_quick_fix_base_health = self.maxHealth;
        self.fun_mode_quick_fix_overhealth_ceiling = undefined;
        self ClearQuickFixOverhealthOverlay();

        self thread WatchQuickFixOverhealth();
        self thread ClearQuickFixOverlayOnDeath();
    }
}

ClearQuickFixOverlayOnDeath()
{
    self endon("disconnect");
    self waittill("death");
    self ClearQuickFixOverhealthOverlay();
}

ClearQuickFixOverhealthOverlay()
{
    if (IsDefined(self.fun_mode_quick_fix_overlay))
    {
        self.fun_mode_quick_fix_overlay Destroy();
        self.fun_mode_quick_fix_overlay = undefined;
    }
}

UpdateQuickFixOverhealthOverlay()
{
    if (self IsBotPlayer())
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    if (
        !IsDefined(self.fun_mode_quick_fix_base_health) ||
        self.health <= self.fun_mode_quick_fix_base_health ||
        (IsDefined(self.haslightarmor) && self.haslightarmor)
    )
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    if (!IsDefined(self.fun_mode_quick_fix_overlay))
    {
        self.fun_mode_quick_fix_overlay = NewClientHudElem(self);
        self.fun_mode_quick_fix_overlay.x = 0;
        self.fun_mode_quick_fix_overlay.y = 0;
        self.fun_mode_quick_fix_overlay.alignX = "left";
        self.fun_mode_quick_fix_overlay.alignY = "top";
        self.fun_mode_quick_fix_overlay.horzAlign = "fullscreen";
        self.fun_mode_quick_fix_overlay.vertAlign = "fullscreen";
        self.fun_mode_quick_fix_overlay.sort = -10;
        self.fun_mode_quick_fix_overlay.archived = 1;
        self.fun_mode_quick_fix_overlay SetShader(
            "combathigh_overlay",
            640,
            480
        );
    }

    maximumHealth = Int(
        self.fun_mode_quick_fix_base_health *
        GetDvarFloat("fun_mode_quick_fix_max_percent")
    );
    maximumOverhealth = maximumHealth - self.fun_mode_quick_fix_base_health;

    if (maximumOverhealth <= 0)
    {
        self ClearQuickFixOverhealthOverlay();
        return;
    }

    overhealth = self.health - self.fun_mode_quick_fix_base_health;
    overhealthFraction = overhealth / maximumOverhealth;

    if (overhealthFraction > 1)
    {
        overhealthFraction = 1;
    }

    // Keep the first overhealth step visible, then reach stock intensity at cap.
    self.fun_mode_quick_fix_overlay.alpha = 0.15 + (0.85 * overhealthFraction);
}

/*
    Overhealth behaves like a consumable shield rather than ordinary maximum
    health. Damage lowers its ceiling, preventing IW5's normal regeneration
    from restoring health above the remaining overhealth amount.
*/
WatchQuickFixOverhealth()
{
    self endon("disconnect");
    self endon("death");

    previousHealth = self.health;

    for (;;)
    {
        wait 0.05;

        if (!IsDefined(self.fun_mode_quick_fix_overhealth_ceiling))
        {
            previousHealth = self.health;
            continue;
        }

        baseHealth = self.fun_mode_quick_fix_base_health;

        // Hand control back to IW5 if a real Ballistic Vest is collected.
        if (IsDefined(self.haslightarmor) && self.haslightarmor)
        {
            self.previousmaxhealth = baseHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = undefined;
            self ClearQuickFixOverhealthOverlay();
            previousHealth = self.health;
            continue;
        }

        if (self.health < previousHealth)
        {
            self.fun_mode_quick_fix_overhealth_ceiling = self.health;
        }

        if (self.fun_mode_quick_fix_overhealth_ceiling <= baseHealth)
        {
            self.maxHealth = baseHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = undefined;
        }
        else
        {
            self.maxHealth = self.fun_mode_quick_fix_overhealth_ceiling;

            if (self.health > self.fun_mode_quick_fix_overhealth_ceiling)
            {
                self.health = self.fun_mode_quick_fix_overhealth_ceiling;
            }
        }

        self UpdateQuickFixOverhealthOverlay();
        previousHealth = self.health;
    }
}

/*
    Below base health, kills restore a large burst and carry any excess across
    the base-health boundary. At or above base health, kills add smaller
    overhealth steps. Ten full-health kills reach the default 200-percent cap.
*/
WatchQuickFix()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (
            !GetDvarInt("fun_mode_quick_fix_enable") ||
            !IsAlive(self) ||
            !IsDefined(self.fun_mode_quick_fix_base_health) ||
            (
                IsDefined(self.fun_mode_kill_mode) &&
                self.fun_mode_kill_mode == "vamp"
            ) ||
            (IsDefined(self.haslightarmor) && self.haslightarmor)
        )
        {
            continue;
        }

        baseHealth = self.fun_mode_quick_fix_base_health;
        oldHealth = self.health;

        if (oldHealth < baseHealth)
        {
            healthToRestore = Int(
                baseHealth * GetDvarFloat("fun_mode_quick_fix_heal_percent")
            );
        }
        else
        {
            healthToRestore = Int(
                baseHealth * GetDvarFloat("fun_mode_quick_fix_overheal_percent")
            );
        }

        if (healthToRestore < 1)
        {
            healthToRestore = 1;
        }

        maximumHealth = Int(
            baseHealth * GetDvarFloat("fun_mode_quick_fix_max_percent")
        );
        restoredHealth = self.health + healthToRestore;

        if (restoredHealth > maximumHealth)
        {
            restoredHealth = maximumHealth;
        }

        if (restoredHealth > baseHealth)
        {
            self.maxHealth = restoredHealth;
            self.fun_mode_quick_fix_overhealth_ceiling = restoredHealth;
        }

        self.health = restoredHealth;
        self UpdateQuickFixOverhealthOverlay();
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
