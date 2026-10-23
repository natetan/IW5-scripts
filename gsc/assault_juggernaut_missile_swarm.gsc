/*
    Assault Juggernaut Missile Swarm - IW5 / Plutonium

    Replaces the 15-kill Assault Juggernaut package with an immediately
    activated autonomous Predator-style barrage using the Reaper's shipped
    guided missile projectile. The player-steered Predator projectile cannot
    enter autonomous flight and remains suspended without a remote controller.
    Recon Juggernaut remains stock.

    Defaults:
        Salvos:             7
        Missiles per salvo: 3
        Salvo interval:     4 seconds
        Missile spacing:    0.25 seconds
        Launch height:      3,000 units above the target
		Horizontal approach: 1,800 units from the target

    Targets must be alive, hostile, visible from overhead, and not using
    Blind Eye. Restore the stock Assault Juggernaut before map load with
    fun_mode_assault_juggernaut_swarm_enable 0.
*/

#include maps\mp\killstreaks\_airdrop;

main()
{
    setdvarifuninitialized( "fun_mode_assault_juggernaut_swarm_enable", 1 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_salvos", 7 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_missiles_per_salvo", 3 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_salvo_interval_ms", 4000 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_missile_spacing_ms", 250 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_launch_height", 3000 );
    setdvarifuninitialized( "fun_mode_juggernaut_swarm_approach_distance", 1800 );

    if ( !getdvarint( "fun_mode_assault_juggernaut_swarm_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_airdrop::tryusejuggernautairdrop,
        ::tryUseAssaultJuggernautMissileSwarm
    );
}

tryUseAssaultJuggernautMissileSwarm( lifeId, markerWeapon )
{
    if ( !self maps\mp\_utility::validateusestreak() )
        return 0;

    if ( !isdefined( self.team ) || self.team == "spectator" )
        return 0;

    activationTeam = self.team;
    self maps\mp\_matchdata::logkillstreakevent(
        "airdrop_juggernaut",
        self.origin
    );
    self thread runAssaultJuggernautMissileSwarm( activationTeam, lifeId );
    return 1;
}

runAssaultJuggernautMissileSwarm( activationTeam, lifeId )
{
    self endon( "disconnect" );
    self endon( "joined_team" );
    self endon( "joined_spectators" );
    level endon( "game_ended" );

    salvoCount = int( clamp(
        getdvarint( "fun_mode_juggernaut_swarm_salvos" ),
        1,
        12
    ) );
    missilesPerSalvo = int( clamp(
        getdvarint( "fun_mode_juggernaut_swarm_missiles_per_salvo" ),
        1,
        5
    ) );
    salvoIntervalMilliseconds = getdvarint(
        "fun_mode_juggernaut_swarm_salvo_interval_ms"
    );
    missileSpacingMilliseconds = getdvarint(
        "fun_mode_juggernaut_swarm_missile_spacing_ms"
    );

    if ( salvoIntervalMilliseconds < 1000 )
        salvoIntervalMilliseconds = 1000;

    if ( missileSpacingMilliseconds < 100 )
        missileSpacingMilliseconds = 100;

    // Let the fast marker finish its draw/cancel before the first barrage.
    wait 0.75;

    for ( salvo = 0; salvo < salvoCount; salvo++ )
    {
        salvoStartedAt = gettime();

        for ( shot = 0; shot < missilesPerSalvo; shot++ )
        {
            target = getAssaultJuggernautSwarmTarget( activationTeam );

            if ( isdefined( target ) )
                fireAssaultJuggernautSwarmMissile( target, lifeId );

            if ( shot + 1 < missilesPerSalvo )
                wait( missileSpacingMilliseconds / 1000.0 );
        }

        if ( salvo + 1 >= salvoCount )
            continue;

        elapsedMilliseconds = gettime() - salvoStartedAt;
        remainingMilliseconds = salvoIntervalMilliseconds - elapsedMilliseconds;

        if ( remainingMilliseconds > 0 )
            wait( remainingMilliseconds / 1000.0 );
    }
}

getAssaultJuggernautSwarmTarget( activationTeam )
{
    candidates = [];
    launchHeight = getdvarfloat(
        "fun_mode_juggernaut_swarm_launch_height"
    );

    if ( launchHeight < 1000 )
        launchHeight = 1000;

    foreach ( player in level.players )
    {
        if (
            !isdefined( player ) ||
            !isplayer( player ) ||
            player == self ||
            !isalive( player ) ||
            !isdefined( player.sessionstate ) ||
            player.sessionstate != "playing" ||
            !isdefined( player.team ) ||
            player.team == "spectator"
        )
        {
            continue;
        }

        if ( level.teambased && player.team == activationTeam )
            continue;

        if ( player maps\mp\_utility::_hasperk( "specialty_blindeye" ) )
            continue;

        targetOrigin = player gettagorigin( "j_spineupper" );
        launchOrigin = targetOrigin + ( 0, 0, launchHeight );

        if ( !bullettracepassed( launchOrigin, targetOrigin, false, player ) )
            continue;

        candidates[candidates.size] = player;
    }

    if ( !candidates.size )
        return undefined;

    return candidates[randomint( candidates.size )];
}

fireAssaultJuggernautSwarmMissile( target, lifeId )
{
    if ( !isdefined( target ) || !isalive( target ) )
        return;

    launchHeight = getdvarfloat(
        "fun_mode_juggernaut_swarm_launch_height"
    );

    if ( launchHeight < 1000 )
        launchHeight = 1000;

    targetOrigin = target gettagorigin( "j_spineupper" );
    approachDistance = getdvarfloat(
        "fun_mode_juggernaut_swarm_approach_distance"
    );

    if ( approachDistance < 512 )
        approachDistance = 512;

    approachDirection = anglestoforward(
        ( 0, randomint( 360 ), 0 )
    );
    launchOrigin = targetOrigin + approachDirection * approachDistance;
    launchOrigin += ( 0, 0, launchHeight );
    missile = magicbullet(
        "remote_mortar_missile_mp",
        launchOrigin,
        targetOrigin,
        self
    );

    if ( !isdefined( missile ) )
        return;

    missile.lifeid = lifeId;
    missile missile_settargetent( target );
    missile missile_setflightmodedirect();
    missile thread cleanUpAssaultJuggernautSwarmMissile();
}

cleanUpAssaultJuggernautSwarmMissile()
{
    self endon( "death" );
    level endon( "game_ended" );

    wait 8;

    if ( isdefined( self ) )
        self delete();
}
