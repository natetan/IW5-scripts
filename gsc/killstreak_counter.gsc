/*
    MOAB and Health Counters - IW5 / Plutonium

    Displays IW5's authoritative MOAB-eligible kill count near the bottom-right
    ammunition HUD. The stock damage callback increments
    pers["cur_kill_streak_for_nuke"] only for qualifying non-killstreak-weapon
    kills and resets it on death. This remains independent of Assault reward
    cycling and Support point persistence.

    Position and scale are sampled when the player connects:

        fun_mode_killstreak_counter_x
        fun_mode_killstreak_counter_y
        fun_mode_killstreak_counter_scale

        fun_mode_health_counter_enable
        fun_mode_health_counter_x
        fun_mode_health_counter_y
        fun_mode_health_counter_scale
*/

#include maps\mp\gametypes\_hud_util;

main()
{
    setdvarifuninitialized("fun_mode_killstreak_counter_enable", 1);
    setdvarifuninitialized("fun_mode_killstreak_counter_x", -92);
    setdvarifuninitialized("fun_mode_killstreak_counter_y", -82);
    setdvarifuninitialized("fun_mode_killstreak_counter_scale", 1.0);
    setdvarifuninitialized("fun_mode_health_counter_enable", 1);
    setdvarifuninitialized("fun_mode_health_counter_x", -92);
    setdvarifuninitialized("fun_mode_health_counter_y", -100);
    setdvarifuninitialized("fun_mode_health_counter_scale", 1.0);

    if (
        !getdvarint("fun_mode_killstreak_counter_enable") &&
        !getdvarint("fun_mode_health_counter_enable")
    )
    {
        return;
    }

    level thread WatchKillstreakCounterConnections();
}

WatchKillstreakCounterConnections()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (
            IsDefined(player.pers["isBot"]) &&
            player.pers["isBot"]
        )
        {
            continue;
        }

        player thread TrackKillstreakCounter();
    }
}

TrackKillstreakCounter()
{
    self endon("disconnect");
    level endon("game_ended");

    counter = undefined;
    healthCounter = undefined;

    if (getdvarint("fun_mode_killstreak_counter_enable"))
    {
        counter = self createFontString(
            "Objective",
            getdvarfloat("fun_mode_killstreak_counter_scale")
        );
        counter setPoint(
            "BOTTOMRIGHT",
            "BOTTOMRIGHT",
            getdvarint("fun_mode_killstreak_counter_x"),
            getdvarint("fun_mode_killstreak_counter_y")
        );
        counter.label = &"^5MOAB STREAK: ^7";
        counter.sort = 1;
        counter.foreground = true;
    }

    if (getdvarint("fun_mode_health_counter_enable"))
    {
        healthCounter = self createFontString(
            "Objective",
            getdvarfloat("fun_mode_health_counter_scale")
        );
        healthCounter setPoint(
            "BOTTOMRIGHT",
            "BOTTOMRIGHT",
            getdvarint("fun_mode_health_counter_x"),
            getdvarint("fun_mode_health_counter_y")
        );
        // Match the proven MOAB-counter pattern. Each label ends with the
        // same blue code so only HEALTH changes color while the value does not.
        healthCounter.label = &"^2HEALTH: ^5";
        healthCounter.sort = 1;
        healthCounter.foreground = true;
    }

    lastValue = -1;
    lastHealth = -1;
    lastHealthBand = "";

    for (;;)
    {
        value = 0;

        if (IsDefined(self.pers["cur_kill_streak_for_nuke"]))
        {
            value = int(self.pers["cur_kill_streak_for_nuke"]);
        }

        if (isdefined(counter) && value != lastValue)
        {
            counter setValue(value);
            lastValue = value;
        }

        health = 0;

        if (isdefined(self.health))
        {
            health = int(self.health);
        }

        if (isdefined(healthCounter) && health != lastHealth)
        {
            healthCounter setValue(health);
            lastHealth = health;
        }

        baseHealth = self getHealthCounterBaseHealth();
        healthBand = getHealthCounterBand(health, baseHealth);

        if (
            isdefined(healthCounter) &&
            healthBand != lastHealthBand
        )
        {
            if (healthBand == "green")
            {
                healthCounter.label = &"^2HEALTH: ^5";
            }
            else if (healthBand == "yellow")
            {
                healthCounter.label = &"^3HEALTH: ^5";
            }
            else
            {
                healthCounter.label = &"^1HEALTH: ^5";
            }

            lastHealthBand = healthBand;
        }

        wait 0.1;
    }
}

getHealthCounterBaseHealth()
{
    if (
        isdefined(self.fun_mode_quick_fix_base_health) &&
        self.fun_mode_quick_fix_base_health > 0
    )
    {
        return self.fun_mode_quick_fix_base_health;
    }

    if (
        isdefined(self.previousmaxhealth) &&
        self.previousmaxhealth > 0 &&
        isdefined(self.haslightarmor) &&
        self.haslightarmor
    )
    {
        return self.previousmaxhealth;
    }

    if (isdefined(self.maxHealth) && self.maxHealth > 0)
    {
        return self.maxHealth;
    }

    return 100;
}

getHealthCounterBand(health, baseHealth)
{
    if (!isdefined(baseHealth) || baseHealth <= 0)
    {
        baseHealth = 100;
    }

    healthPercent = (health * 100.0) / baseHealth;

    if (healthPercent >= 75)
    {
        return "green";
    }

    if (healthPercent > 40)
    {
        return "yellow";
    }

    return "red";
}
