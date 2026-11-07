#include maps\mp\_utility;

/*
    Weapon Impersonation - IW5 / Plutonium

    A level-three testing command can redirect an authorized human player's
    qualifying firearm kills to a stock progression weapon. The equipped
    weapon, damage, ammunition, attachments, and handling never change.

    The stock death callback receives the target weapon so the obituary and
    ordinary weapon kill/headshot challenge path use that identity. Weapon XP
    and persistent kill/headshot counters are credited explicitly because
    IW5 normally rejects weapon XP when the credited weapon is not equipped.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_weapon_impersonation_xp_per_kill", 100);
}

Initialize()
{
    level thread InstallPlayerKilledHook();
}

InstallPlayerKilledHook()
{
    level endon("game_ended");

    // Bot Warfare installs its callback wrapper one frame after prematch_over.
    // Install after it so both systems retain their complete callback chain.
    level waittill("prematch_over");
    wait 0.10;

    if (!IsDefined(level.callbackPlayerKilled))
    {
        return;
    }

    level.fun_mode_impersonation_previous_player_killed =
        level.callbackPlayerKilled;
    level.callbackPlayerKilled = ::PlayerKilledWithImpersonation;
}

PlayerKilledWithImpersonation(
    inflictor,
    attacker,
    damage,
    meansOfDeath,
    weapon,
    direction,
    hitLocation,
    timeOffset,
    deathAnimDuration
)
{
    reportedWeapon = weapon;
    shouldCredit = ShouldImpersonateKill(self, attacker, weapon, meansOfDeath);

    if (shouldCredit)
    {
        reportedWeapon = attacker.fun_mode_impersonation_weapon + "_mp";
    }

    self [[level.fun_mode_impersonation_previous_player_killed]](
        inflictor,
        attacker,
        damage,
        meansOfDeath,
        reportedWeapon,
        direction,
        hitLocation,
        timeOffset,
        deathAnimDuration
    );

    if (shouldCredit && IsDefined(attacker) && IsPlayer(attacker))
    {
        attacker CreditImpersonatedWeaponProgress(
            attacker.fun_mode_impersonation_weapon,
            hitLocation,
            meansOfDeath
        );
    }
}

ShouldImpersonateKill(victim, attacker, weapon, meansOfDeath)
{
    if (
        !IsDefined(victim) ||
        !IsPlayer(victim) ||
        !IsDefined(attacker) ||
        !IsPlayer(attacker) ||
        attacker == victim ||
        !IsDefined(attacker.fun_mode_impersonation_weapon) ||
        attacker.fun_mode_impersonation_weapon == ""
    )
    {
        return false;
    }

    if (
        level.teamBased &&
        IsDefined(victim.team) &&
        IsDefined(attacker.team) &&
        victim.team == attacker.team
    )
    {
        return false;
    }

    if (!IsDefined(weapon) || !IsDefined(meansOfDeath))
    {
        return false;
    }

    // Keep equipment, melee, explosives, attachment modes, and killstreaks
    // truthful. This command proxies ordinary primary/secondary gunfire only.
    if (!maps\mp\_utility::IsBulletDamage(meansOfDeath))
    {
        return false;
    }

    weaponBase = GetProgressionWeaponBase(weapon);

    // Let stock IW5 progression handle an already-matching weapon. Without
    // this guard, deliberately impersonating the equipped gun would double
    // its persistent kills and weapon XP.
    if (weaponBase == attacker.fun_mode_impersonation_weapon)
    {
        return false;
    }

    return (
        maps\mp\_utility::IsCACPrimaryWeapon(weaponBase) ||
        maps\mp\_utility::IsCACSecondaryWeapon(weaponBase)
    );
}

CreditImpersonatedWeaponProgress(weaponBase, hitLocation, meansOfDeath)
{
    if (!maps\mp\_utility::RankingEnabled())
    {
        return;
    }

    currentKills = self GetPlayerData("weaponStats", weaponBase, "kills");
    self SetPlayerData(
        "weaponStats",
        weaponBase,
        "kills",
        Int(currentKills + 1)
    );
    maps\mp\_matchdata::LogWeaponStat(weaponBase, "kills", 1);

    if (
        (hitLocation == "head" || hitLocation == "helmet") &&
        meansOfDeath != "MOD_MELEE" &&
        meansOfDeath != "MOD_IMPACT"
    )
    {
        currentHeadshots = self GetPlayerData(
            "weaponStats",
            weaponBase,
            "headShots"
        );
        self SetPlayerData(
            "weaponStats",
            weaponBase,
            "headShots",
            Int(currentHeadshots + 1)
        );
        maps\mp\_matchdata::LogWeaponStat(weaponBase, "headShots", 1);
    }

    AddImpersonatedWeaponXP(weaponBase);
}

AddImpersonatedWeaponXP(weaponBase)
{
    // Passing the impersonated identity through the stock death callback can
    // occasionally satisfy IW5's native ownership check (for example, when
    // the exact bare target weapon is also carried). In that case stock has
    // already awarded the weapon XP and this proxy must not duplicate it.
    if (StockWouldAwardImpersonatedWeaponXP(weaponBase + "_mp"))
    {
        return;
    }

    if (self maps\mp\gametypes\_rank::IsWeaponMaxRank(weaponBase))
    {
        return;
    }

    currentXP = self maps\mp\gametypes\_rank::GetWeaponRankXP(weaponBase);
    maximumXP = self maps\mp\gametypes\_rank::GetWeaponMaxRankXP(weaponBase);
    xpAward = Max(
        0,
        GetDvarInt("fun_mode_weapon_impersonation_xp_per_kill")
    );

    if (xpAward <= 0)
    {
        return;
    }

    // Min/Max arithmetic is represented as a float by this IW5 runtime even
    // when every input is integral. Persistent weapon fields strictly require
    // integer values at the SetPlayerData boundary.
    newXP = Int(Min(currentXP + xpAward, maximumXP));
    appliedXP = Int(newXP - currentXP);

    if (appliedXP <= 0)
    {
        return;
    }

    self SetPlayerData("weaponXP", weaponBase, newXP);
    maps\mp\_matchdata::LogWeaponStat(weaponBase, "XP", appliedXP);
    self maps\mp\_utility::IncPlayerStat("weaponxpearned", appliedXP);

    oldRank = self GetPlayerData("weaponRank", weaponBase);
    newRank = maps\mp\gametypes\_rank::GetWeaponRankForXP(
        newXP,
        weaponBase
    );

    if (newRank > oldRank)
    {
        self SetPlayerData("weaponRank", weaponBase, Int(newRank));
        self thread maps\mp\gametypes\_missions::MasteryChallengeProcess(
            weaponBase
        );
    }
}

StockWouldAwardImpersonatedWeaponXP(targetWeapon)
{
    if (
        IsDefined(self.primaryWeapon) &&
        (
            self.primaryWeapon == targetWeapon ||
            WeaponAltWeaponName(self.primaryWeapon) == targetWeapon
        )
    )
    {
        return true;
    }

    if (IsDefined(self.secondaryWeapon) && self.secondaryWeapon == targetWeapon)
    {
        return true;
    }

    return (
        IsDefined(self.tookWeaponFrom) &&
        IsDefined(self.tookWeaponFrom[targetWeapon])
    );
}

GetProgressionWeaponBase(weapon)
{
    tokens = StrTok(weapon, "_");

    if (tokens.size >= 2 && tokens[0] == "iw5")
    {
        return tokens[0] + "_" + tokens[1];
    }

    return tokens[0];
}

ResolveWeaponAlias(requestedName)
{
    name = ToLower(requestedName);

    switch (name)
    {
        case "m4": case "m4a1": return "iw5_m4";
        case "m16": case "m16a4": return "iw5_m16";
        case "scar": case "scarl": return "iw5_scar";
        case "cm901": return "iw5_cm901";
        case "type95": case "type": return "iw5_type95";
        case "g36": case "g36c": return "iw5_g36c";
        case "acr": case "acr68": return "iw5_acr";
        case "mk14": return "iw5_mk14";
        case "ak": case "ak47": return "iw5_ak47";
        case "fad": return "iw5_fad";

        case "mp5": return "iw5_mp5";
        case "ump": case "ump45": return "iw5_ump45";
        case "pp90": case "pp90m1": return "iw5_pp90m1";
        case "p90": return "iw5_p90";
        case "pm9": return "iw5_m9";
        case "mp7": return "iw5_mp7";

        case "l86": case "l86lsw": return "iw5_sa80";
        case "mg36": return "iw5_mg36";
        case "pkp": case "pecheneg": return "iw5_pecheneg";
        case "mk46": return "iw5_mk46";
        case "m60": case "m60e4": return "iw5_m60";

        case "barrett": case "barrett50": return "iw5_barrett";
        case "l118": case "l118a": case "l96": return "iw5_l96a1";
        case "dragunov": return "iw5_dragunov";
        case "as50": return "iw5_as50";
        case "rsass": return "iw5_rsass";
        case "msr": return "iw5_msr";

        case "usas": case "usas12": return "iw5_usas12";
        case "ksg": case "ksg12": return "iw5_ksg";
        case "spas": case "spas12": return "iw5_spas12";
        case "aa12": return "iw5_aa12";
        case "striker": return "iw5_striker";
        case "model": case "model1887": case "1887": return "iw5_1887";

        case "fmg": case "fmg9": return "iw5_fmg9";
        case "mp9": return "iw5_mp9";
        case "skorpion": return "iw5_skorpion";
        case "g18": return "iw5_g18";

        case "usp": case "usp45": return "iw5_usp45";
        case "p99": return "iw5_p99";
        case "mp412": return "iw5_mp412";
        case "magnum": case "44magnum": return "iw5_44magnum";
        case "fiveseven": case "57": return "iw5_fnfiveseven";
        case "deagle": case "deserteagle": return "iw5_deserteagle";
    }

    return undefined;
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
