#include maps\mp\_utility;

/*
    Configurable Kill Modes - IW5 / Plutonium

    Implements permissioned AoE, nearest-target chain, wide-radius virus,
    on-hit splash, and uncapped bullet lifesteal effects while routing
    synthetic damage through IW5's native player-damage callback for
    attribution, scoring, friendly fire, and target defenses.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_kill_mode_radius", 382);
    SetDvarIfNotInitialized("fun_mode_kill_mode_virus_radius", 1000);
    SetDvarIfNotInitialized("fun_mode_kill_mode_splash_fraction", 0.50);
    SetDvarIfNotInitialized("fun_mode_kill_mode_vamp_fraction", 1.00);
    SetDvarIfNotInitialized("fun_mode_kill_mode_chain_delay", 0.15);
    SetDvarIfNotInitialized("fun_mode_kill_mode_chain_max_hops", 17);
}

ApplyVampLifesteal(
    victim,
    attacker,
    damage,
    weapon,
    meansOfDeath,
    isSyntheticKillModeDamage
)
{
    if (
        isSyntheticKillModeDamage ||
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsAlive(attacker) ||
        attacker == victim ||
        !IsDefined(attacker.fun_mode_kill_mode) ||
        attacker.fun_mode_kill_mode != "vamp" ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        maps\mp\_utility::IsKillstreakWeapon(weapon) ||
        (
            meansOfDeath != "MOD_PISTOL_BULLET" &&
            meansOfDeath != "MOD_RIFLE_BULLET"
        ) ||
        !IsDefined(damage) ||
        damage <= 0
    )
    {
        return;
    }

    // Do not let a testing mode farm health by deliberately shooting allies.
    if (
        IsDefined(level.teamBased) &&
        level.teamBased &&
        IsDefined(victim.team) &&
        IsDefined(attacker.team) &&
        victim.team == attacker.team
    )
    {
        return;
    }

    lifestealFraction = GetDvarFloat("fun_mode_kill_mode_vamp_fraction");

    if (lifestealFraction <= 0)
    {
        return;
    }

    // Credit only health the victim can actually lose, not overkill damage.
    dealtDamage = damage;

    if (dealtDamage > victim.health)
    {
        dealtDamage = victim.health;
    }

    healing = Int((dealtDamage * lifestealFraction) + 0.5);

    if (healing < 1)
    {
        healing = 1;
    }

    attacker.health += healing;

    // Raising maxHealth makes the added health real consumable overhealth.
    // Vamp deliberately has no script-side ceiling and resets on respawn.
    if (attacker.health > attacker.maxHealth)
    {
        attacker.maxHealth = attacker.health;
    }

    if (IsDefined(attacker.fun_mode_quick_fix_base_health))
    {
        attacker.fun_mode_quick_fix_overhealth_ceiling = attacker.health;
        attacker UpdateQuickFixOverhealthOverlayForVamp();
    }
}

UpdateQuickFixOverhealthOverlayForVamp()
{
    self scripts\quick_fix::UpdateQuickFixOverhealthOverlay();
}

ShouldTrigger(
    victim,
    attacker,
    damage,
    weapon,
    meansOfDeath
)
{
    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        attacker == victim ||
        !IsDefined(attacker.fun_mode_kill_mode) ||
        (
            attacker.fun_mode_kill_mode != "aoe" &&
            attacker.fun_mode_kill_mode != "chain" &&
            attacker.fun_mode_kill_mode != "virus" &&
            attacker.fun_mode_kill_mode != "splash"
        ) ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        !IsDefined(meansOfDeath) ||
        maps\mp\_utility::IsKillstreakWeapon(weapon) ||
        damage <= 0 ||
        (
            attacker.fun_mode_kill_mode != "splash" &&
            damage < victim.health
        ) ||
        (
            IsDefined(attacker.fun_mode_player_aoe_damage_active) &&
            attacker.fun_mode_player_aoe_damage_active
        )
    )
    {
        return false;
    }

    if (!IsDefined(level.teamBased) || !level.teamBased)
    {
        return true;
    }

    if (
        !IsDefined(victim.team) ||
        !IsDefined(attacker.team) ||
        !IsDefined(level.friendlyFire)
    )
    {
        return false;
    }

    return victim.team != attacker.team || level.friendlyFire != 0;
}

ApplySplash(
    originalVictim,
    effectOrigin,
    damage,
    weapon,
    meansOfDeath
)
{
    self endon("disconnect");
    level endon("game_ended");

    if (
        !IsDefined(originalVictim) ||
        !IsPlayer(originalVictim) ||
        !IsDefined(effectOrigin) ||
        damage <= 0 ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        !IsDefined(meansOfDeath) ||
        !IsDefined(level.callbackPlayerDamage)
    )
    {
        return;
    }

    radius = GetDvarFloat("fun_mode_kill_mode_radius");
    splashFraction = GetDvarFloat("fun_mode_kill_mode_splash_fraction");

    if (radius <= 0 || splashFraction <= 0)
    {
        return;
    }

    targets = [];

    foreach (candidate in level.players)
    {
        if (
            !IsDefined(candidate) ||
            !IsPlayer(candidate) ||
            !IsAlive(candidate) ||
            candidate == self ||
            candidate == originalVictim ||
            DistanceSquared(effectOrigin, candidate.origin) > radius * radius
        )
        {
            continue;
        }

        if (IsDefined(level.teamBased) && level.teamBased)
        {
            if (!IsDefined(candidate.team) || !IsDefined(self.team))
            {
                continue;
            }

            if (
                candidate.team == self.team &&
                (
                    !IsDefined(level.friendlyFire) ||
                    level.friendlyFire == 0
                )
            )
            {
                continue;
            }
        }

        targets[targets.size] = candidate;
    }

    if (!targets.size)
    {
        return;
    }

    splashPool = Int(damage * splashFraction);

    if (splashPool <= 0)
    {
        return;
    }

    damagePerTarget = Int(splashPool / targets.size);
    remainder = splashPool - damagePerTarget * targets.size;

    // Let the original hit finish before routing attributed secondary damage.
    wait 0.05;

    if (!IsDefined(self) || !IsPlayer(self))
    {
        return;
    }

    self.fun_mode_player_aoe_damage_active = true;
    self.fun_mode_kill_mode_damage_active = true;

    for (index = 0; index < targets.size; index++)
    {
        target = targets[index];
        targetDamage = damagePerTarget;

        if (index < remainder)
        {
            targetDamage++;
        }

        if (
            targetDamage <= 0 ||
            !IsDefined(target) ||
            !IsPlayer(target) ||
            !IsAlive(target)
        )
        {
            continue;
        }

        delta = target.origin - effectOrigin;

        if (DistanceSquared(target.origin, effectOrigin) > 0)
        {
            direction = VectorNormalize(delta);
        }
        else
        {
            direction = (0, 0, 1);
        }

        target [[level.callbackPlayerDamage]](
            self,
            self,
            targetDamage,
            0,
            meansOfDeath,
            weapon,
            target.origin,
            direction,
            "none",
            0
        );
    }

    self.fun_mode_kill_mode_damage_active = false;
    self.fun_mode_player_aoe_damage_active = false;
}

ApplyAfterDamage(
    originalVictim,
    effectOrigin,
    damage,
    weapon,
    meansOfDeath,
    killMode
)
{
    self endon("disconnect");
    level endon("game_ended");

    wait 0.05;

    if (
        !IsDefined(originalVictim) ||
        !IsPlayer(originalVictim) ||
        IsAlive(originalVictim) ||
        !IsDefined(killMode)
    )
    {
        return;
    }

    if (killMode == "aoe")
    {
        self thread ApplyFunModePlayerAoeDamage(
            originalVictim,
            effectOrigin,
            effectOrigin,
            damage,
            weapon,
            meansOfDeath,
            GetDvarFloat("fun_mode_kill_mode_radius"),
            1.0,
            false,
            true
        );

        return;
    }

    if (killMode == "chain" || killMode == "virus")
    {
        chainRadius = GetDvarFloat("fun_mode_kill_mode_radius");
        lethalHops = false;

        if (killMode == "virus")
        {
            chainRadius = GetDvarFloat("fun_mode_kill_mode_virus_radius");
            lethalHops = true;
        }

        self thread ApplyFunModeKillModeChain(
            originalVictim,
            effectOrigin,
            damage,
            weapon,
            meansOfDeath,
            chainRadius,
            lethalHops
        );
    }
}

ApplyFunModeKillModeChain(
    originalVictim,
    chainOrigin,
    damage,
    weapon,
    meansOfDeath,
    radius,
    lethalHops
)
{
    self endon("disconnect");
    level endon("game_ended");

    if (
        !IsDefined(originalVictim) ||
        !IsPlayer(originalVictim) ||
        damage <= 0 ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        !IsDefined(meansOfDeath) ||
        !IsDefined(level.callbackPlayerDamage)
    )
    {
        return;
    }

    hopDelay = GetDvarFloat("fun_mode_kill_mode_chain_delay");
    maxHops = GetDvarInt("fun_mode_kill_mode_chain_max_hops");

    if (radius <= 0 || maxHops <= 0)
    {
        return;
    }

    if (hopDelay < 0.05)
    {
        hopDelay = 0.05;
    }

    visitedPlayers = [];
    visitedPlayers[visitedPlayers.size] = originalVictim;
    currentOrigin = chainOrigin;
    hopCount = 0;

    while (hopCount < maxHops)
    {
        nextTarget = FindNearestFunModeKillModeTarget(
            currentOrigin,
            radius,
            visitedPlayers
        );

        if (!IsDefined(nextTarget))
        {
            break;
        }

        visitedPlayers[visitedPlayers.size] = nextTarget;
        nextOrigin = nextTarget.origin + (0, 0, 40);
        delayBeforeDamage = hopDelay;

        if (hopCount > 0)
        {
            delayBeforeDamage = hopDelay - 0.05;
        }

        if (delayBeforeDamage > 0)
        {
            wait delayBeforeDamage;
        }

        if (
            !IsDefined(nextTarget) ||
            !IsPlayer(nextTarget) ||
            !IsAlive(nextTarget)
        )
        {
            break;
        }

        delta = nextOrigin - currentOrigin;

        if (DistanceSquared(nextOrigin, currentOrigin) > 0)
        {
            direction = VectorNormalize(delta);
        }
        else
        {
            direction = (0, 0, 1);
        }

        self.fun_mode_player_aoe_damage_active = true;
        self.fun_mode_kill_mode_damage_active = true;

        hopDamage = damage;
        hopHitLocation = "none";

        if (lethalHops)
        {
            // Virus is a map-testing mode: once a valid target is selected,
            // use an overwhelming attributed headshot instead of copying the
            // initiating weapon's final damage. Stock IW5 headshots bypass
            // Final Stand for weapon types that can otherwise trigger it.
            hopDamage = nextTarget.health + 100000;
            hopHitLocation = "head";
        }

        nextTarget [[level.callbackPlayerDamage]](
            self,
            self,
            hopDamage,
            0,
            meansOfDeath,
            weapon,
            nextOrigin,
            direction,
            hopHitLocation,
            0
        );

        self.fun_mode_kill_mode_damage_active = false;
        self.fun_mode_player_aoe_damage_active = false;
        hopCount++;

        wait 0.05;

        if (
            !IsDefined(nextTarget) ||
            !IsPlayer(nextTarget) ||
            IsAlive(nextTarget)
        )
        {
            break;
        }

        currentOrigin = nextOrigin;
    }

    self.fun_mode_kill_mode_damage_active = false;
    self.fun_mode_player_aoe_damage_active = false;
}

FindNearestFunModeKillModeTarget(origin, radius, visitedPlayers)
{
    nearestTarget = undefined;
    nearestDistanceSquared = radius * radius;

    foreach (candidate in level.players)
    {
        if (
            !IsDefined(candidate) ||
            !IsPlayer(candidate) ||
            !IsAlive(candidate) ||
            candidate == self ||
            IsPlayerInFunModeKillModeChain(candidate, visitedPlayers)
        )
        {
            continue;
        }

        if (IsDefined(level.teamBased) && level.teamBased)
        {
            if (!IsDefined(candidate.team) || !IsDefined(self.team))
            {
                continue;
            }

            if (
                candidate.team == self.team &&
                (
                    !IsDefined(level.friendlyFire) ||
                    level.friendlyFire == 0
                )
            )
            {
                continue;
            }
        }

        candidateDistanceSquared = DistanceSquared(origin, candidate.origin);

        if (candidateDistanceSquared > nearestDistanceSquared)
        {
            continue;
        }

        nearestTarget = candidate;
        nearestDistanceSquared = candidateDistanceSquared;
    }

    return nearestTarget;
}

IsPlayerInFunModeKillModeChain(candidate, visitedPlayers)
{
    foreach (visitedPlayer in visitedPlayers)
    {
        if (IsDefined(visitedPlayer) && visitedPlayer == candidate)
        {
            return true;
        }
    }

    return false;
}
/*
    Reusable player-centered area-damage path for Fun Mode attacks. Every
    secondary hit re-enters IW5's active damage callback, preserving Bot
    Warfare, friendly fire, target defenses, attribution, scoring, and the
    original weapon's killfeed presentation.
*/
ApplyFunModePlayerAoeDamage(
    originalVictim,
    centerOrigin,
    traceOrigin,
    baseDamage,
    weapon,
    meansOfDeath,
    radius,
    damageMultiplier,
    requireLineOfSight,
    preserveFinalDamage
)
{
    self endon("disconnect");
    level endon("game_ended");

    if (
        baseDamage <= 0 ||
        !IsDefined(weapon) ||
        weapon == "none" ||
        !IsDefined(level.callbackPlayerDamage)
    )
    {
        return;
    }

    areaDamage = Int(baseDamage * damageMultiplier);

    if (
        !IsDefined(centerOrigin) ||
        !IsDefined(traceOrigin) ||
        !IsDefined(meansOfDeath) ||
        radius <= 0 ||
        areaDamage <= 0
    )
    {
        return;
    }

    targets = [];

    foreach (candidate in level.players)
    {
        if (
            !IsDefined(candidate) ||
            !IsPlayer(candidate) ||
            !IsAlive(candidate) ||
            candidate == self ||
            candidate == originalVictim ||
            DistanceSquared(centerOrigin, candidate.origin) > radius * radius
        )
        {
            continue;
        }

        if (requireLineOfSight)
        {
            targetPoint = candidate.origin + (0, 0, 40);

            if (!BulletTracePassed(traceOrigin, targetPoint, false, candidate))
            {
                continue;
            }
        }

        targets[targets.size] = candidate;
    }

    if (!targets.size)
    {
        return;
    }

    // Defer until the original hit callback has completed, then guard every
    // synthetic callback so area damage cannot recursively create another AoE.
    wait 0.05;

    if (!IsDefined(self) || !IsPlayer(self))
    {
        return;
    }

    self.fun_mode_player_aoe_damage_active = true;

    if (preserveFinalDamage)
    {
        self.fun_mode_kill_mode_damage_active = true;
    }

    foreach (target in targets)
    {
        if (!IsDefined(target) || !IsPlayer(target) || !IsAlive(target))
        {
            continue;
        }

        direction = VectorNormalize(target.origin - centerOrigin);

        target [[level.callbackPlayerDamage]](
            self,
            self,
            areaDamage,
            0,
            meansOfDeath,
            weapon,
            target.origin,
            direction,
            "none",
            0
        );
    }

    self.fun_mode_kill_mode_damage_active = false;
    self.fun_mode_player_aoe_damage_active = false;
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}

