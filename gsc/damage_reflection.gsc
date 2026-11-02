/*
    Damage Reflection - IW5 / Plutonium

    A permissioned player can toggle hostile damage reflection for personal
    testing. Authorized Fun Mode classes 13-15 receive the same behavior
    automatically through the repository's existing class/GUID policy.

    The initial reflection types are hostile melee and direct SMAW/RPG rocket
    collisions. The incoming hit is suppressed, then a lethal attributed hit
    of the same type is routed back through IW5's native damage callback so
    ordinary scoring, killfeed, streak, challenge, and death handling remain
    active. Only the directly struck player's paired splash callback is also
    suppressed; ordinary splash against nearby players remains unchanged.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns the damage hook.
}

ToggleForPlayer()
{
    if (!IsDefined(self.fun_mode_reflect_enabled))
    {
        self.fun_mode_reflect_enabled = false;
    }

    self.fun_mode_reflect_enabled = !self.fun_mode_reflect_enabled;

    if (self.fun_mode_reflect_enabled)
    {
        self Tell(
            "^2Reflection enabled.^7 Hostile knives and direct rockets " +
            "reflect to their owner."
        );
    }
    else
    {
        if (self scripts\specialist_system::IsFunModeSuperClassOwner())
        {
            self Tell(
                "^3Command reflection disabled.^7 " +
                "Authorized classes 13-15 remain reflective."
            );
        }
        else
        {
            self Tell("^3Reflection disabled.^7");
        }
    }
}

ProcessIncomingDamage(victim, attacker, damage, weapon, meansOfDeath)
{
    if (
        ShouldSuppressReflectedRocketSplash(
            victim,
            attacker,
            weapon,
            meansOfDeath
        )
    )
    {
        return 0;
    }

    reflectionType = GetReflectionType(weapon, meansOfDeath);

    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsAlive(attacker) ||
        attacker == victim ||
        !IsDefined(damage) ||
        damage <= 0 ||
        reflectionType == "" ||
        !victim HasDamageReflection() ||
        (
            IsDefined(attacker.fun_mode_reflection_active) &&
            attacker.fun_mode_reflection_active
        )
    )
    {
        return damage;
    }

    if (
        IsDefined(level.teamBased) &&
        level.teamBased &&
        IsDefined(victim.team) &&
        IsDefined(attacker.team) &&
        victim.team == attacker.team
    )
    {
        return damage;
    }

    if (reflectionType == "rocket")
    {
        // IW5 follows the physical MOD_PROJECTILE collision with a separate
        // splash callback. Suppress only that directly struck player's paired
        // splash; unrelated players and ordinary nearby splash remain normal.
        victim.fun_mode_reflected_rocket_attacker = attacker;
        victim.fun_mode_reflected_rocket_splash_until = GetTime() + 150;
    }

    victim thread ReflectDamageAfterDamage(
        attacker,
        weapon,
        meansOfDeath,
        reflectionType
    );
    return 0;
}

GetReflectionType(weapon, meansOfDeath)
{
    if (!IsDefined(meansOfDeath))
    {
        return "";
    }

    if (meansOfDeath == "MOD_MELEE")
    {
        return "melee";
    }

    if (
        meansOfDeath == "MOD_PROJECTILE" &&
        IsReflectableRocketWeapon(weapon)
    )
    {
        return "rocket";
    }

    return "";
}

IsReflectableRocketWeapon(weapon)
{
    if (!IsDefined(weapon))
    {
        return false;
    }

    normalizedWeapon = ToLower(weapon);
    return IsSubStr(normalizedWeapon, "smaw") || IsSubStr(normalizedWeapon, "rpg");
}

ShouldSuppressReflectedRocketSplash(victim, attacker, weapon, meansOfDeath)
{
    return (
        IsDefined(victim) &&
        IsPlayer(victim) &&
        IsDefined(attacker) &&
        IsDefined(weapon) &&
        IsDefined(meansOfDeath) &&
        meansOfDeath == "MOD_PROJECTILE_SPLASH" &&
        IsDefined(victim.fun_mode_reflected_rocket_splash_until) &&
        victim.fun_mode_reflected_rocket_splash_until >= GetTime() &&
        IsDefined(victim.fun_mode_reflected_rocket_attacker) &&
        victim.fun_mode_reflected_rocket_attacker == attacker &&
        IsReflectableRocketWeapon(weapon)
    );
}

HasDamageReflection()
{
    return (
        (
            IsDefined(self.fun_mode_reflect_enabled) &&
            self.fun_mode_reflect_enabled
        ) ||
        self scripts\specialist_system::IsFunModeSuperClassOwner()
    );
}

ReflectDamageAfterDamage(target, originalWeapon, originalMeansOfDeath, reflectionType)
{
    self endon("disconnect");
    level endon("game_ended");

    // Finish the original callback before starting another attributed hit.
    wait 0.05;

    if (
        !IsDefined(self) ||
        !IsPlayer(self) ||
        !IsAlive(self) ||
        !IsDefined(target) ||
        !IsPlayer(target) ||
        !IsAlive(target) ||
        !IsDefined(level.callbackPlayerDamage)
    )
    {
        return;
    }

    reflectedWeapon = originalWeapon;
    reflectedMeansOfDeath = originalMeansOfDeath;

    if (reflectionType == "melee")
    {
        reflectedWeapon = self GetCurrentWeapon();
        reflectedMeansOfDeath = "MOD_MELEE";

        if (!IsDefined(reflectedWeapon) || reflectedWeapon == "none")
        {
            reflectedWeapon = originalWeapon;
        }
    }

    if (
        !IsDefined(reflectedWeapon) ||
        reflectedWeapon == "none" ||
        !IsDefined(reflectedMeansOfDeath)
    )
    {
        return;
    }

    delta = target.origin - self.origin;

    if (DistanceSquared(target.origin, self.origin) > 0)
    {
        direction = VectorNormalize(delta);
    }
    else
    {
        direction = (0, 0, 1);
    }

    self.fun_mode_reflection_active = true;

    target [[level.callbackPlayerDamage]](
        self,
        self,
        target.health + 100000,
        0,
        reflectedMeansOfDeath,
        reflectedWeapon,
        target.origin,
        direction,
        "none",
        0
    );

    self.fun_mode_reflection_active = false;
}
