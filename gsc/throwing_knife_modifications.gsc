/*
    Throwing Knife Modifications - IW5 / Plutonium

    Makes a physical Throwing Knife hit lethal to players. The stock player
    damage callback still owns attribution, friendly fire, XP, and effects.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_throwing_knife_lethal_enable", 1);
}

IsLethalThrowingKnifeDamage(weapon)
{
    return (
        GetDvarInt("fun_mode_throwing_knife_lethal_enable") &&
        IsDefined(weapon) &&
        IsSubStr(ToLower(weapon), "throwingknife")
    );
}

GetLethalPlayerDamage(victim, damage, weapon)
{
    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsLethalThrowingKnifeDamage(weapon)
    )
    {
        return damage;
    }

    return victim.health + 1;
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
