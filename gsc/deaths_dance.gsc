#include maps\mp\killstreaks\_airdrop;
#include maps\mp\_utility;

/*
    Death's Dance - IW5 / Plutonium

    Replaces the 18-point Recon Juggernaut care package with a stackable,
    immediately activated death-prevention charge. A charge converts one
    fatal hit into survival at 1 HP and grants three seconds of invulnerability.
    A kill during that window detonates a native, friendly-fire-aware explosion
    around the player and grants a full scaled Ballistic Vest.
*/

main()
{
    SetDvarIfNotInitialized("fun_mode_deaths_dance_enable", 1);
    SetDvarIfNotInitialized("fun_mode_deaths_dance_invulnerability_seconds", 3.0);
    SetDvarIfNotInitialized("fun_mode_deaths_dance_explosion_radius", 384);
    SetDvarIfNotInitialized("fun_mode_deaths_dance_explosion_max_damage", 200);
    SetDvarIfNotInitialized("fun_mode_deaths_dance_explosion_min_damage", 25);

    if (!GetDvarInt("fun_mode_deaths_dance_enable"))
    {
        return;
    }

    ReplaceFunc(
        maps\mp\killstreaks\_airdrop::tryusejuggernautreconairdrop,
        ::TryUseDeathsDance
    );
}

OnPlayerConnected()
{
    self thread WatchDeathsDanceKills();
}

TryUseDeathsDance(lifeId, markerWeapon)
{
    if (!self maps\mp\_utility::ValidateUseStreak())
    {
        return 0;
    }

    if (!IsDefined(self.fun_mode_deaths_dance_charges))
    {
        self.fun_mode_deaths_dance_charges = 0;
    }

    self.fun_mode_deaths_dance_charges++;

    self maps\mp\_matchdata::LogKillstreakEvent(
        "airdrop_juggernaut_recon",
        self.origin
    );

    if (!self IsBotPlayer())
    {
        self IPrintLnBold(
            "Death's Dance armed (" + self.fun_mode_deaths_dance_charges + ")"
        );
    }

    return 1;
}

PreventFatalDamage(victim, damage)
{
    if (
        !GetDvarInt("fun_mode_deaths_dance_enable") ||
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(damage) ||
        damage <= 0
    )
    {
        return damage;
    }

    if (victim IsDeathsDanceInvulnerable())
    {
        return 0;
    }

    if (
        damage < victim.health ||
        !IsDefined(victim.fun_mode_deaths_dance_charges) ||
        victim.fun_mode_deaths_dance_charges <= 0
    )
    {
        return damage;
    }

    victim.fun_mode_deaths_dance_charges--;

    durationMilliseconds = Int(
        GetDvarFloat("fun_mode_deaths_dance_invulnerability_seconds") * 1000
    );

    if (durationMilliseconds < 1)
    {
        durationMilliseconds = 1;
    }

    if (!IsDefined(victim.fun_mode_deaths_dance_generation))
    {
        victim.fun_mode_deaths_dance_generation = 0;
    }

    victim.fun_mode_deaths_dance_generation++;
    generation = victim.fun_mode_deaths_dance_generation;
    victim.fun_mode_deaths_dance_active = true;
    victim.fun_mode_deaths_dance_reward_resolved = false;
    victim.fun_mode_deaths_dance_invulnerable_until =
        GetTime() + durationMilliseconds;

    victim thread EndDeathsDanceWindowAfterDelay(
        generation,
        durationMilliseconds
    );

    if (!victim IsBotPlayer())
    {
        victim IPrintLnBold("DEATH'S DANCE - GET A KILL!");
    }

    // Leave exactly one point of health after the engine applies this hit.
    survivingDamage = victim.health - 1;

    if (survivingDamage < 0)
    {
        survivingDamage = 0;
    }

    return survivingDamage;
}

IsDeathsDanceInvulnerable()
{
    return (
        IsDefined(self.fun_mode_deaths_dance_active) &&
        self.fun_mode_deaths_dance_active &&
        IsDefined(self.fun_mode_deaths_dance_invulnerable_until) &&
        self.fun_mode_deaths_dance_invulnerable_until > GetTime()
    );
}

EndDeathsDanceWindowAfterDelay(generation, durationMilliseconds)
{
    self endon("disconnect");
    level endon("game_ended");

    wait durationMilliseconds / 1000.0;

    if (
        IsDefined(self.fun_mode_deaths_dance_generation) &&
        self.fun_mode_deaths_dance_generation == generation
    )
    {
        self ClearDeathsDanceWindow();
    }
}

WatchDeathsDanceKills()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("killed_enemy");

        if (
            !self IsDeathsDanceInvulnerable() ||
            !IsAlive(self) ||
            (
                IsDefined(self.fun_mode_deaths_dance_reward_resolved) &&
                self.fun_mode_deaths_dance_reward_resolved
            )
        )
        {
            continue;
        }

        // Resolve the payoff once, but preserve immunity until the original
        // three-second rescue window expires.
        self.fun_mode_deaths_dance_reward_resolved = true;
        self TriggerDeathsDanceExplosion();
        self thread scripts\ballistic_vest_pulse::giveScaledLightArmor();

        if (!self IsBotPlayer())
        {
            self IPrintLnBold("Death's Dance revived you!");
        }
    }
}

ClearDeathsDanceWindow()
{
    self.fun_mode_deaths_dance_active = false;
    self.fun_mode_deaths_dance_reward_resolved = undefined;
    self.fun_mode_deaths_dance_invulnerable_until = undefined;
}

TriggerDeathsDanceExplosion()
{
    radius = GetDvarFloat("fun_mode_deaths_dance_explosion_radius");
    maximumDamage = GetDvarInt("fun_mode_deaths_dance_explosion_max_damage");
    minimumDamage = GetDvarInt("fun_mode_deaths_dance_explosion_min_damage");

    if (radius < 1)
    {
        radius = 1;
    }

    if (maximumDamage < 1)
    {
        maximumDamage = 1;
    }

    if (minimumDamage < 0)
    {
        minimumDamage = 0;
    }
    else if (minimumDamage > maximumDamage)
    {
        minimumDamage = maximumDamage;
    }

    explosionOrigin = self.origin + (0, 0, 24);

    if (IsDefined(level.airstrikeexplosion))
    {
        PlayFX(level.airstrikeexplosion, explosionOrigin);
    }

    // Keep an explicit owner guard around the synchronous explosion while
    // RadiusDamage routes every other victim through native FF and callbacks.
    self.fun_mode_deaths_dance_explosion_active = true;
    self RadiusDamage(
        explosionOrigin,
        radius,
        maximumDamage,
        minimumDamage,
        self,
        "MOD_EXPLOSIVE",
        "airdrop_trap_explosive_mp"
    );
    self.fun_mode_deaths_dance_explosion_active = false;
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
