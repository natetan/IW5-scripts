/*
    Recon Drone -> Recon Pulse - IW5 / Plutonium

    Replaces the manually controlled Recon Drone with a single intelligence
    pulse centered on its user. Enemy players within 2,400 units receive the
    real Recon Drone radar tag for ten seconds, including normal tagged-kill
    assists. The pulse does not flash or damage its targets.

    Set fun_mode_recon_pulse_enable to 0 before loading a map to retain the
    stock Recon Drone. Radius and tag duration are independently tunable.
*/

#include maps\mp\killstreaks\_remoteuav;

main()
{
    setdvarifuninitialized( "fun_mode_recon_pulse_enable", 1 );
    setdvarifuninitialized( "fun_mode_recon_pulse_radius", 2400 );
    setdvarifuninitialized( "fun_mode_recon_pulse_duration_seconds", 10 );
    setdvarifuninitialized( "fun_mode_recon_pulse_radar_visual_enable", 1 );

    if ( !getdvarint( "fun_mode_recon_pulse_enable" ) )
        return;

    level.funModeReconPulseMarkId = 0;

    replacefunc(
        maps\mp\killstreaks\_remoteuav::useremoteuav,
        ::useReconPulseInsteadOfDrone
    );
}

useReconPulseInsteadOfDrone( lifeId )
{
    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    if (
        maps\mp\_utility::isusingremote() ||
        maps\mp\_utility::isemped() ||
        isdefined( level.nukeincoming )
    )
    {
        return 0;
    }

    radius = getdvarfloat( "fun_mode_recon_pulse_radius" );
    duration = getdvarfloat( "fun_mode_recon_pulse_duration_seconds" );

    if ( radius < 1 )
        radius = 1;

    if ( duration < 1 )
        duration = 1;

    radiusSquared = radius * radius;
    taggedCount = 0;

    if ( getdvarint( "fun_mode_recon_pulse_radar_visual_enable" ) )
        self thread playReconPulseRadarVisual();

    foreach ( player in level.players )
    {
        if ( !self canReconPulseTag( player, radiusSquared ) )
            continue;

        self applyReconPulseTag( player, duration );
        taggedCount++;
    }

    self playlocalsound( "recondrone_tag" );
    self iprintlnbold( "Recon pulse tagged " + taggedCount + " enemies." );
    maps\mp\_matchdata::logkillstreakevent( "remote_uav", self.origin );
    thread maps\mp\_utility::teamplayercardsplash( "used_remote_uav", self );
    self thread finishReconPulseActivation();
    return 1;
}

finishReconPulseActivation()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );

    // Recon Drone is classified as a ride streak, so the stock killstreak
    // controller intentionally leaves its activation weapon equipped. The
    // pulse never enters a remote ride; explicitly holster its marker and let
    // the stock weapon-change cleanup remove it without affecting duplicates.
    waittillframeend;
    returnWeapon = common_scripts\utility::getlastweapon();

    if ( !isdefined( returnWeapon ) || returnWeapon == "none" || !self hasweapon( returnWeapon ) )
    {
        primaryWeapons = self getweaponslistprimaries();

        if ( !primaryWeapons.size )
            return;

        returnWeapon = primaryWeapons[0];
    }

    self switchtoweapon( returnWeapon );
}

canReconPulseTag( player, radiusSquared )
{
    if ( !isdefined( player ) || !isplayer( player ) || !isalive( player ) )
        return 0;

    if ( player == self || player.sessionstate != "playing" || player.team == "spectator" )
        return 0;

    if ( level.teambased && player.team == self.team )
        return 0;

    if ( distancesquared( self.origin, player.origin ) > radiusSquared )
        return 0;

    return 1;
}

applyReconPulseTag( player, duration )
{
    level.funModeReconPulseMarkId++;
    markId = level.funModeReconPulseMarkId;

    player.funModeReconPulseMarkId = markId;
    player.uavremotemarkedby = self;
    player setperk( "specialty_radarblip", 1, 0 );
    player thread maps\mp\gametypes\_rank::xpeventpopup( &"SPLASHES_MARKED_BY_REMOTE_UAV" );
    player thread clearReconPulseTagAfterDelay( self, markId, duration );
}

playReconPulseRadarVisual()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    radarPulse = spawn( "script_model", self.origin );

    if ( !isdefined( radarPulse ) )
        return;

    radarPulse.team = self.team;
    radarPulse.owner = self;
    radarPulse makeportableradar( self );

    // Keep the engine radar alive long enough to draw one expanding sweep.
    wait 2.0;

    if ( isdefined( radarPulse ) )
    {
        radarPulse notify( "death" );
        radarPulse delete();
    }
}

clearReconPulseTagAfterDelay( owner, markId, duration )
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    elapsed = 0;

    while ( elapsed < duration && isalive( self ) )
    {
        wait 0.1;
        elapsed += 0.1;
    }

    if (
        !isdefined( self.funModeReconPulseMarkId ) ||
        self.funModeReconPulseMarkId != markId
    )
    {
        return;
    }

    self.funModeReconPulseMarkId = undefined;

    // Do not remove a newer tag owned by a different intelligence source.
    if (
        isdefined( self.uavremotemarkedby ) &&
        self.uavremotemarkedby != owner
    )
    {
        return;
    }

    self.uavremotemarkedby = undefined;

    // An active Advanced UAV may still be revealing this Assassin user.
    if ( !isdefined( self.funModeAdvancedUavRevealed ) )
        self unsetperk( "specialty_radarblip", 1 );
}
