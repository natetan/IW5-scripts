/*
    Ballistic Vest Pulse - IW5 / Plutonium

    Replaces the repeatedly deployed Ballistic Vest bag with an immediate
    team-armor pulse centered on the user. Every living teammate in range,
    including the user, receives armor through IW5's native light_armor
    callback so normal health, HUD, and damage behavior remain intact.

    Defaults:
        Radius: 1,200 units

    Set fun_mode_ballistic_vest_pulse_enable to 0 before loading a map to
    restore the stock deployable bag. Radius is independently tunable with:

        fun_mode_ballistic_vest_pulse_radius
*/

#include maps\mp\killstreaks\_deployablebox;

main()
{
    setdvarifuninitialized( "fun_mode_ballistic_vest_pulse_enable", 1 );
    setdvarifuninitialized( "fun_mode_ballistic_vest_pulse_radius", 1200 );

    if ( !getdvarint( "fun_mode_ballistic_vest_pulse_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_deployablebox::tryusedeployablevest,
        ::useBallisticVestPulse
    );
}

useBallisticVestPulse( lifeId )
{
    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    if (
        !isdefined( level.killstreakfuncs ) ||
        !isdefined( level.killstreakfuncs["light_armor"] )
    )
    {
        return 0;
    }

    radius = getdvarfloat( "fun_mode_ballistic_vest_pulse_radius" );

    if ( radius < 1 )
        radius = 1;

    radiusSquared = radius * radius;
    armoredCount = 0;

    foreach ( player in level.players )
    {
        if ( !self canReceiveBallisticVestPulse( player, radiusSquared ) )
            continue;

        player [[ level.killstreakfuncs["light_armor"] ]]();
        player playlocalsound( "ammo_crate_use" );
        player iprintlnbold( "Received Ballistic Vest" );
        armoredCount++;

        // Match the stock bag's reward for each teammate who takes a vest.
        if ( player != self )
        {
            self thread maps\mp\gametypes\_rank::xpeventpopup( &"MP_DEPLOYED_VEST" );
            self thread maps\mp\gametypes\_rank::giverankxp( "support", 50 );
        }
    }

    maps\mp\_matchdata::logkillstreakevent( "deployable_vest", self.origin );
    thread maps\mp\_utility::teamplayercardsplash( "used_deployable_vest", self );
    self iprintlnbold( "Ballistic vest pulse equipped " + armoredCount + " players." );
    return 1;
}

canReceiveBallisticVestPulse( player, radiusSquared )
{
    if ( !isdefined( player ) || !isplayer( player ) || !isalive( player ) )
        return 0;

    if (
        !isdefined( player.sessionstate ) ||
        player.sessionstate != "playing" ||
        !isdefined( player.team ) ||
        player.team == "spectator"
    )
    {
        return 0;
    }

    if ( level.teambased && player.team != self.team )
        return 0;

    if ( !level.teambased && player != self )
        return 0;

    if ( distancesquared( self.origin, player.origin ) > radiusSquared )
        return 0;

    return 1;
}
