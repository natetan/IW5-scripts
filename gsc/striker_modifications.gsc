#include maps\mp\_utility;

/*
    Striker Modifications - IW5 / Plutonium

    Striker pellet damage restores health. Healing beyond the player's current
    maxHealth becomes an independent consumable shield, allowing it to layer
    above Quick Fix overhealth and scaled Ballistic Vest health without taking
    ownership of either system's maxHealth state.

    Firing the final shell also emits a local EMP damage pulse. Player damage
    from that synthetic pulse is suppressed by fun_mode; native equipment
    damage handlers still receive the EMP weapon attribution.
*/

main()
{
    SetDvarIfNotInitialized("fun_mode_striker_bloodthirster_enable", 1);
    SetDvarIfNotInitialized("fun_mode_striker_lifesteal_fraction", 0.50);
    SetDvarIfNotInitialized("fun_mode_striker_shield_base_health_multiplier", 1.50);
    SetDvarIfNotInitialized("fun_mode_striker_bloodshield_max_damage_bonus", 0.50);
    SetDvarIfNotInitialized("fun_mode_striker_emp_pulse_enable", 1);
    SetDvarIfNotInitialized("fun_mode_striker_emp_pulse_radius", 600);
    SetDvarIfNotInitialized("fun_mode_striker_emp_pulse_damage", 10000);
}

OnPlayerConnected()
{
    self thread WatchStrikerBloodthirsterSpawns();
    self thread WatchStrikerFinalShells();
}

ShouldSuppressPlayerDamage(attacker, weapon)
{
    return (
        IsDefined(attacker) &&
        IsPlayer(attacker) &&
        IsDefined(attacker.fun_mode_striker_emp_pulse_active) &&
        attacker.fun_mode_striker_emp_pulse_active &&
        IsDefined(weapon) &&
        weapon == "emp_grenade_mp"
    );
}

ProcessIncomingDamage(victim, damage)
{
    return AbsorbIncomingDamage(victim, damage);
}

ApplyBloodshieldDamageBonus(attacker, damage, weapon, meansOfDeath)
{
    if (
        !GetDvarInt("fun_mode_striker_bloodthirster_enable") ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsDefined(damage) ||
        damage <= 0 ||
        !IsDefined(weapon) ||
        !IsSubStr(weapon, "iw5_striker_mp") ||
        (
            meansOfDeath != "MOD_PISTOL_BULLET" &&
            meansOfDeath != "MOD_RIFLE_BULLET"
        ) ||
        !IsDefined(attacker.fun_mode_striker_bloodthirster_shield) ||
        attacker.fun_mode_striker_bloodthirster_shield <= 0
    )
    {
        return damage;
    }

    shieldCap = Int(
        attacker GetBloodthirsterBaseHealth() *
        GetDvarFloat("fun_mode_striker_shield_base_health_multiplier")
    );

    if (shieldCap <= 0)
    {
        return damage;
    }

    shieldFraction =
        attacker.fun_mode_striker_bloodthirster_shield / shieldCap;

    if (shieldFraction > 1.0)
    {
        shieldFraction = 1.0;
    }

    maximumBonus = GetDvarFloat(
        "fun_mode_striker_bloodshield_max_damage_bonus"
    );

    if (maximumBonus < 0)
    {
        maximumBonus = 0;
    }

    return Int(damage * (1.0 + (maximumBonus * shieldFraction)));
}

ProcessOutgoingDamage(
    victim,
    attacker,
    damage,
    weapon,
    meansOfDeath,
    isSyntheticKillModeDamage
)
{
    if (!isSyntheticKillModeDamage)
    {
        ApplyLifesteal(
            victim,
            attacker,
            damage,
            weapon,
            meansOfDeath
        );
    }

}

WatchStrikerBloodthirsterSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        self.fun_mode_striker_bloodthirster_shield = 0;
    }
}

ApplyLifesteal(victim, attacker, damage, weapon, meansOfDeath)
{
    if (
        !GetDvarInt("fun_mode_striker_bloodthirster_enable") ||
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsAlive(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        !IsAlive(attacker) ||
        attacker == victim ||
        !IsDefined(weapon) ||
        !IsSubStr(weapon, "iw5_striker_mp") ||
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

    // Never generate sustain by deliberately shooting a teammate.
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

    lifestealFraction = GetDvarFloat("fun_mode_striker_lifesteal_fraction");

    if (lifestealFraction <= 0)
    {
        return;
    }

    healing = Int((damage * lifestealFraction) + 0.5);

    if (healing < 1)
    {
        healing = 1;
    }

    missingHealth = attacker.maxHealth - attacker.health;

    if (missingHealth > 0)
    {
        healthHealing = healing;

        if (healthHealing > missingHealth)
        {
            healthHealing = missingHealth;
        }

        attacker.health += healthHealing;
        healing -= healthHealing;
    }

    if (healing <= 0)
    {
        return;
    }

    if (!IsDefined(attacker.fun_mode_striker_bloodthirster_shield))
    {
        attacker.fun_mode_striker_bloodthirster_shield = 0;
    }

    shieldCap = Int(
        attacker GetBloodthirsterBaseHealth() *
        GetDvarFloat("fun_mode_striker_shield_base_health_multiplier")
    );

    if (shieldCap < 0)
    {
        shieldCap = 0;
    }

    attacker.fun_mode_striker_bloodthirster_shield += healing;

    if (attacker.fun_mode_striker_bloodthirster_shield > shieldCap)
    {
        attacker.fun_mode_striker_bloodthirster_shield = shieldCap;
    }
}

AbsorbIncomingDamage(victim, damage)
{
    if (
        !GetDvarInt("fun_mode_striker_bloodthirster_enable") ||
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsDefined(damage) ||
        damage <= 0 ||
        !IsDefined(victim.fun_mode_striker_bloodthirster_shield) ||
        victim.fun_mode_striker_bloodthirster_shield <= 0
    )
    {
        return damage;
    }

    absorbedDamage = damage;

    if (absorbedDamage > victim.fun_mode_striker_bloodthirster_shield)
    {
        absorbedDamage = victim.fun_mode_striker_bloodthirster_shield;
    }

    victim.fun_mode_striker_bloodthirster_shield -= absorbedDamage;
    damage -= absorbedDamage;

    if (victim.fun_mode_striker_bloodthirster_shield < 0)
    {
        victim.fun_mode_striker_bloodthirster_shield = 0;
    }

    if (damage < 0)
    {
        damage = 0;
    }

    return damage;
}

WatchStrikerFinalShells()
{
    self endon("disconnect");
    level endon("game_ended");

    for (;;)
    {
        self waittill("weapon_fired");

        if (
            !GetDvarInt("fun_mode_striker_emp_pulse_enable") ||
            !IsAlive(self)
        )
        {
            continue;
        }

        firedWeapon = self GetCurrentWeapon();

        if (
            !IsDefined(firedWeapon) ||
            !IsSubStr(firedWeapon, "iw5_striker_mp")
        )
        {
            continue;
        }

        waittillframeend;

        if (self GetWeaponAmmoClip(firedWeapon) > 0)
        {
            continue;
        }

        self TriggerStrikerEmpPulse();
    }
}

TriggerStrikerEmpPulse()
{
    radius = GetDvarFloat("fun_mode_striker_emp_pulse_radius");
    pulseDamage = GetDvarInt("fun_mode_striker_emp_pulse_damage");

    if (radius < 1)
    {
        radius = 1;
    }

    if (pulseDamage < 1)
    {
        pulseDamage = 1;
    }

    if (!self IsBotPlayer())
    {
        self IPrintLnBold("PRESSURE RELEASE");
        self thread scripts\recon_drone_pulse::playReconPulseRadarVisual();
    }

    pulseOrigin = self.origin;
    radiusSquared = radius * radius;
    self.fun_mode_striker_emp_pulse_active = true;

    grenades = GetEntArray("grenade", "classname");

    foreach (equipment in grenades)
    {
        if (
            IsDefined(equipment) &&
            IsDefined(equipment.name) &&
            (
                equipment.name == "c4_mp" ||
                equipment.name == "claymore_mp"
            )
        )
        {
            self PulseStrikerEquipment(
                equipment,
                equipment.owner,
                pulseOrigin,
                radiusSquared,
                pulseDamage
            );
        }
    }

    foreach (player in level.players)
    {
        if (!IsDefined(player) || !IsPlayer(player) || player == self)
        {
            continue;
        }

        if (IsDefined(player.trophyArray))
        {
            foreach (equipment in player.trophyArray)
            {
                self PulseStrikerEquipment(
                    equipment,
                    player,
                    pulseOrigin,
                    radiusSquared,
                    pulseDamage
                );
            }
        }

        if (IsDefined(player.setSpawnPoint))
        {
            self PulseStrikerEquipment(
                player.setSpawnPoint,
                player,
                pulseOrigin,
                radiusSquared,
                pulseDamage
            );
        }

        if (IsDefined(player.deployedPortableRadar))
        {
            self PulseStrikerEquipment(
                player.deployedPortableRadar,
                player,
                pulseOrigin,
                radiusSquared,
                pulseDamage
            );
        }
    }

    self PulseStrikerEquipmentRegistry(
        level.ims,
        pulseOrigin,
        radiusSquared,
        pulseDamage
    );
    self PulseStrikerEquipmentRegistry(
        level.scramblers,
        pulseOrigin,
        radiusSquared,
        pulseDamage
    );
    self PulseStrikerEquipmentRegistry(
        level.mines,
        pulseOrigin,
        radiusSquared,
        pulseDamage
    );
    self PulseStrikerEquipmentRegistry(
        level.turrets,
        pulseOrigin,
        radiusSquared,
        pulseDamage
    );
    self PulseStrikerEquipmentRegistry(
        level.remote_uav,
        pulseOrigin,
        radiusSquared,
        pulseDamage
    );

    self.fun_mode_striker_emp_pulse_active = false;
}

PulseStrikerEquipmentRegistry(
    registry,
    pulseOrigin,
    radiusSquared,
    pulseDamage
)
{
    if (!IsDefined(registry))
    {
        return;
    }

    registryKeys = GetArrayKeys(registry);

    foreach (registryKey in registryKeys)
    {
        equipment = registry[registryKey];

        if (!IsDefined(equipment))
        {
            continue;
        }

        equipmentOwner = undefined;

        if (IsDefined(equipment.owner))
        {
            equipmentOwner = equipment.owner;
        }

        self PulseStrikerEquipment(
            equipment,
            equipmentOwner,
            pulseOrigin,
            radiusSquared,
            pulseDamage
        );
    }
}

PulseStrikerEquipment(
    equipment,
    equipmentOwner,
    pulseOrigin,
    radiusSquared,
    pulseDamage
)
{
    if (
        !IsDefined(equipment) ||
        !IsDefined(equipment.origin) ||
        DistanceSquared(pulseOrigin, equipment.origin) > radiusSquared ||
        !self IsHostileStrikerEquipment(equipment, equipmentOwner)
    )
    {
        return;
    }

    if (
        IsDefined(equipment.damageTaken) &&
        IsDefined(equipment.maxHealth) &&
        equipment.damageTaken >= equipment.maxHealth
    )
    {
        return;
    }

    if (IsDefined(equipment.carriedBy))
    {
        return;
    }

    // Centering native EMP damage on the equipment itself avoids the engine's
    // world-geometry occlusion while preserving its destruction callback.
    equipment RadiusDamage(
        equipment.origin,
        16,
        pulseDamage,
        pulseDamage,
        self,
        "MOD_GRENADE_SPLASH",
        "emp_grenade_mp"
    );
}

IsHostileStrikerEquipment(equipment, equipmentOwner)
{
    if (IsDefined(equipmentOwner) && equipmentOwner == self)
    {
        return false;
    }

    if (!IsDefined(level.teamBased) || !level.teamBased)
    {
        return !IsDefined(equipmentOwner) || equipmentOwner != self;
    }

    equipmentTeam = undefined;

    if (
        IsDefined(equipmentOwner) &&
        IsDefined(equipmentOwner.team)
    )
    {
        equipmentTeam = equipmentOwner.team;
    }
    else if (IsDefined(equipment.team))
    {
        equipmentTeam = equipment.team;
    }

    return IsDefined(equipmentTeam) && equipmentTeam != self.team;
}

GetBloodthirsterBaseHealth()
{
    if (
        IsDefined(self.fun_mode_quick_fix_base_health) &&
        self.fun_mode_quick_fix_base_health > 0
    )
    {
        return self.fun_mode_quick_fix_base_health;
    }

    if (
        IsDefined(self.previousMaxHealth) &&
        self.previousMaxHealth > 0 &&
        IsDefined(self.hasLightArmor) &&
        self.hasLightArmor
    )
    {
        return self.previousMaxHealth;
    }

    if (IsDefined(self.maxHealth) && self.maxHealth > 0)
    {
        return self.maxHealth;
    }

    return 100;
}

GetDisplayedBloodthirsterShield()
{
    if (
        IsDefined(self.fun_mode_striker_bloodthirster_shield) &&
        self.fun_mode_striker_bloodthirster_shield > 0
    )
    {
        return Int(self.fun_mode_striker_bloodthirster_shield);
    }

    return 0;
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
