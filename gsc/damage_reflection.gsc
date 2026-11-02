/*
    Damage Reflection - IW5 / Plutonium

    A permissioned player can toggle hostile damage reflection for personal
    testing. Authorized Fun Mode classes 13-15 receive the same behavior
    automatically through the repository's existing class/GUID policy.

    The first reflection type is melee: the incoming knife hit is suppressed,
    then a lethal attributed melee hit is routed back through IW5's native
    damage callback so ordinary scoring, killfeed, streak, challenge, and
    death handling remain active.
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
        self Tell("^2Reflection enabled.^7 Hostile knives reflect to their owner.");
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
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsAlive(attacker) ||
        attacker == victim ||
        !IsDefined(damage) ||
        damage <= 0 ||
        !IsDefined(meansOfDeath) ||
        meansOfDeath != "MOD_MELEE" ||
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

    victim thread ReflectKnifeAfterDamage(attacker, weapon);
    return 0;
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

ReflectKnifeAfterDamage(target, fallbackWeapon)
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

    reflectedWeapon = self GetCurrentWeapon();

    if (!IsDefined(reflectedWeapon) || reflectedWeapon == "none")
    {
        reflectedWeapon = fallbackWeapon;
    }

    if (!IsDefined(reflectedWeapon) || reflectedWeapon == "none")
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
        "MOD_MELEE",
        reflectedWeapon,
        target.origin,
        direction,
        "none",
        0
    );

    self.fun_mode_reflection_active = false;
}
