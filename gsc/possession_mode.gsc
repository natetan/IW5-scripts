#include maps\mp\gametypes\_class;
#include maps\mp\killstreaks\_killstreaks;

/*
    Possession Mode Prototype - IW5 / Plutonium

    A permissioned player can toggle possession for personal testing. After a
    confirmed hostile kill, the player's physical entity moves immediately to
    the victim while an invisible camera travels from the old first-person
    view into the new body. On arrival, the killer receives a fresh copy of
    the victim's class loadout while retaining the killer's earned streaks.

    This module deliberately exposes eligibility as a player field. A future
    full game-mode pass can enable the same field for every connected player
    without rewriting the possession pipeline.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_possession_camera_seconds", 0.55);
    SetDvarIfNotInitialized(
        "fun_mode_possession_arrival_protection_seconds",
        1.5
    );
    PrecacheModel("tag_origin");
}

OnHumanPlayerConnected()
{
    self thread WatchPossessionSpawns();
}

ToggleForPlayer()
{
    if (!IsDefined(self.fun_mode_possession_enabled))
    {
        self.fun_mode_possession_enabled = false;
    }

    self.fun_mode_possession_enabled = !self.fun_mode_possession_enabled;

    if (self.fun_mode_possession_enabled)
    {
        self Tell("^2Possession enabled.^7 Hostile kills transfer you into the victim.");
    }
    else
    {
        self Tell("^3Possession disabled.^7");
    }
}

CaptureFatalHit(
    victim,
    attacker,
    damage,
    isKillModeDamage,
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
        !IsAlive(attacker) ||
        attacker == victim ||
        !IsDefined(attacker.fun_mode_possession_enabled) ||
        !attacker.fun_mode_possession_enabled ||
        !IsDefined(damage) ||
        damage < victim.health ||
        isKillModeDamage ||
        !IsPossessionGunKill(weapon, meansOfDeath) ||
        (IsDefined(attacker.fun_mode_possession_transition_pending) &&
            attacker.fun_mode_possession_transition_pending)
    )
    {
        return;
    }

    if (
        IsDefined(level.teambased) &&
        level.teambased &&
        IsDefined(victim.team) &&
        IsDefined(attacker.team) &&
        victim.team == attacker.team
    )
    {
        return;
    }

    currentFrame = GetTime();

    if (
        IsDefined(victim.fun_mode_possession_capture_frame) &&
        victim.fun_mode_possession_capture_frame == currentFrame
    )
    {
        return;
    }

    victimLoadout = victim GetCurrentPossessionLoadout();

    if (!IsDefined(victimLoadout))
    {
        return;
    }

    attackerLoadout = attacker GetCurrentPossessionLoadout();

    if (IsDefined(attackerLoadout))
    {
        victimLoadout = PreservePossessionStrikePackage(
            victimLoadout,
            attackerLoadout
        );
    }

    victim.fun_mode_possession_capture_frame = currentFrame;
    attacker.fun_mode_possession_transition_pending = true;

    attacker thread ConfirmAndRunPossession(
        victim,
        victimLoadout,
        attacker GetEye(),
        victim.origin,
        victim GetEye(),
        victim GetPlayerAngles()
    );
}

ConfirmAndRunPossession(
    victim,
    victimLoadout,
    startEye,
    destinationOrigin,
    destinationEye,
    destinationAngles
)
{
    self endon("disconnect");
    level endon("game_ended");

    // Let the authoritative death callback resolve Final Stand, Death's Dance,
    // and other last-second survival paths before committing the transfer.
    wait 0.05;

    if (
        !IsDefined(victim) ||
        IsAlive(victim) ||
        !IsAlive(self) ||
        !IsDefined(self.fun_mode_possession_enabled) ||
        !self.fun_mode_possession_enabled
    )
    {
        self.fun_mode_possession_transition_pending = false;
        return;
    }

    self RunPossessionTransition(
        victimLoadout,
        startEye,
        destinationOrigin,
        destinationEye,
        destinationAngles
    );
}

RunPossessionTransition(
    victimLoadout,
    startEye,
    destinationOrigin,
    destinationEye,
    destinationAngles
)
{
    self.fun_mode_possession_transition_protected = true;
    self FreezeControls(true);

    // Move the authoritative player immediately. Only the linked camera
    // travels, which makes the old body disappear for everyone else.
    self SetOrigin(destinationOrigin);

    camera = Spawn("script_model", startEye);
    camera SetModel("tag_origin");
    camera.angles = VectorToAngles(destinationEye - startEye);
    self CameraLinkTo(camera, "tag_origin");

    duration = GetDvarFloat("fun_mode_possession_camera_seconds");

    if (duration < 0.05)
    {
        duration = 0.05;
    }

    easeTime = duration * 0.25;
    camera MoveTo(destinationEye, duration, easeTime, easeTime);
    wait duration;

    if (IsAlive(self))
    {
        self ApplyPossessionLoadout(victimLoadout);
        self SetPlayerAngles(destinationAngles);
    }

    self CameraUnlink();

    if (IsDefined(camera))
    {
        camera Delete();
    }

    self FreezeControls(false);

    protectionSeconds = GetDvarFloat(
        "fun_mode_possession_arrival_protection_seconds"
    );

    if (protectionSeconds < 0)
    {
        protectionSeconds = 0;
    }

    self.fun_mode_possession_arrival_protected_until =
        GetTime() + Int(protectionSeconds * 1000);
    self.fun_mode_possession_transition_protected = false;
    self.fun_mode_possession_transition_pending = false;

    if (IsAlive(self))
    {
        self IPrintLnBold("POSSESSED");
    }
}

IsPossessionGunKill(weapon, meansOfDeath)
{
    return (
        IsDefined(weapon) &&
        weapon != "none" &&
        IsDefined(meansOfDeath) &&
        (
            meansOfDeath == "MOD_PISTOL_BULLET" ||
            meansOfDeath == "MOD_RIFLE_BULLET"
        ) &&
        !maps\mp\_utility::IsKillstreakWeapon(weapon)
    );
}

ApplyPossessionLoadout(loadout)
{
    if (!IsDefined(loadout))
    {
        return;
    }

    if (!IsDefined(self.fun_mode_possession_loadout_active))
    {
        self.fun_mode_possession_had_previous_gamemode_loadout =
            IsDefined(self.pers["gamemodeLoadout"]);

        if (self.fun_mode_possession_had_previous_gamemode_loadout)
        {
            self.fun_mode_possession_previous_gamemode_loadout =
                self.pers["gamemodeLoadout"];
        }
    }

    self.fun_mode_possession_loadout_active = true;
    self.fun_mode_possession_loadout = loadout;
    self.pers["gamemodeLoadout"] = loadout;

    self maps\mp\gametypes\_class::GiveLoadout(
        self.pers["team"],
        "gamemode",
        false,
        true
    );

    // GiveLoadout starts with TakeAllWeapons(). Reconstruct the untouched
    // earned streak queue, activation weapons, HUD selection, and action slot.
    self maps\mp\killstreaks\_killstreaks::UpdateKillstreaks(true);
}

GetCurrentPossessionLoadout()
{
    source = undefined;

    if (IsDefined(self.fun_mode_possession_loadout))
    {
        source = self.fun_mode_possession_loadout;
    }
    else if (
        IsDefined(self.pers["gamemodeLoadout"]) &&
        (
            IsDefined(self.pers["fun_mode_temporary_loadout_active"]) ||
            IsDefined(self.isSurvivalPlayer)
        )
    )
    {
        source = self.pers["gamemodeLoadout"];
    }
    else
    {
        source = self maps\mp\gametypes\_class::CloneLoadout();
    }

    return ClonePossessionLoadout(source);
}

ClonePossessionLoadout(source)
{
    if (!IsDefined(source))
    {
        return undefined;
    }

    clone = [];
    keys = [];
    keys[keys.size] = "loadoutPrimary";
    keys[keys.size] = "loadoutPrimaryAttachment";
    keys[keys.size] = "loadoutPrimaryAttachment2";
    keys[keys.size] = "loadoutPrimaryBuff";
    keys[keys.size] = "loadoutPrimaryCamo";
    keys[keys.size] = "loadoutPrimaryReticle";
    keys[keys.size] = "loadoutSecondary";
    keys[keys.size] = "loadoutSecondaryAttachment";
    keys[keys.size] = "loadoutSecondaryAttachment2";
    keys[keys.size] = "loadoutSecondaryBuff";
    keys[keys.size] = "loadoutSecondaryCamo";
    keys[keys.size] = "loadoutSecondaryReticle";
    keys[keys.size] = "loadoutEquipment";
    keys[keys.size] = "loadoutOffhand";
    keys[keys.size] = "loadoutPerk1";
    keys[keys.size] = "loadoutPerk2";
    keys[keys.size] = "loadoutPerk3";
    keys[keys.size] = "loadoutStreakType";
    keys[keys.size] = "loadoutKillstreak1";
    keys[keys.size] = "loadoutKillstreak2";
    keys[keys.size] = "loadoutKillstreak3";
    keys[keys.size] = "loadoutDeathstreak";

    foreach (key in keys)
    {
        if (IsDefined(source[key]))
        {
            clone[key] = source[key];
        }
    }

    clone["loadoutJuggernaut"] = false;
    return clone;
}

PreservePossessionStrikePackage(loadout, previousLoadout)
{
    if (!IsDefined(loadout) || !IsDefined(previousLoadout))
    {
        return loadout;
    }

    streakKeys = [];
    streakKeys[streakKeys.size] = "loadoutStreakType";
    streakKeys[streakKeys.size] = "loadoutKillstreak1";
    streakKeys[streakKeys.size] = "loadoutKillstreak2";
    streakKeys[streakKeys.size] = "loadoutKillstreak3";

    foreach (key in streakKeys)
    {
        if (IsDefined(previousLoadout[key]))
        {
            loadout[key] = previousLoadout[key];
        }
    }

    return loadout;
}

WatchPossessionSpawns()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");

        if (!IsDefined(self.fun_mode_possession_loadout_active))
        {
            continue;
        }

        if (
            IsDefined(self.fun_mode_possession_had_previous_gamemode_loadout) &&
            self.fun_mode_possession_had_previous_gamemode_loadout &&
            IsDefined(self.fun_mode_possession_previous_gamemode_loadout)
        )
        {
            self.pers["gamemodeLoadout"] =
                self.fun_mode_possession_previous_gamemode_loadout;
        }
        else
        {
            self.pers["gamemodeLoadout"] = undefined;
        }

        self.fun_mode_possession_loadout_active = undefined;
        self.fun_mode_possession_loadout = undefined;
        self.fun_mode_possession_previous_gamemode_loadout = undefined;
        self.fun_mode_possession_had_previous_gamemode_loadout = undefined;
        self.fun_mode_possession_transition_pending = false;
        self.fun_mode_possession_transition_protected = false;
        self.fun_mode_possession_arrival_protected_until = undefined;
    }
}

IsTransitionProtected()
{
    return (
        (
            IsDefined(self.fun_mode_possession_transition_protected) &&
            self.fun_mode_possession_transition_protected
        ) ||
        (
            IsDefined(self.fun_mode_possession_arrival_protected_until) &&
            self.fun_mode_possession_arrival_protected_until > GetTime()
        )
    );
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
