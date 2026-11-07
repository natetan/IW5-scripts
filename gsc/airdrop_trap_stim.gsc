/*
    Airdrop Trap -> Juiced Pulse - IW5 / Plutonium

    Replaces the trapped care package with an immediate team movement-stim
    pulse centered on the user. Living teammates in range receive the real
    Juiced movement effect and its timer HUD. Repeated pulses refresh Juiced
    rather than stacking movement multipliers.

    Defaults:
        Radius:   1,200 units
        Duration: 15 seconds

    Set fun_mode_airdrop_trap_stim_enable to 0 before loading a map to restore
    the stock trapped care package. Radius and duration are independently
    tunable with:

        fun_mode_airdrop_trap_stim_radius
        fun_mode_airdrop_trap_stim_duration
*/

#include maps\mp\killstreaks\_airdrop;

main()
{
    setdvarifuninitialized( "fun_mode_airdrop_trap_stim_enable", 1 );
    setdvarifuninitialized( "fun_mode_airdrop_trap_stim_radius", 1200 );
    setdvarifuninitialized( "fun_mode_airdrop_trap_stim_duration", 15.0 );

    if ( !getdvarint( "fun_mode_airdrop_trap_stim_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_airdrop::tryuseairdroptrap,
        ::useJuicedPulseInsteadOfAirdropTrap
    );
}

useJuicedPulseInsteadOfAirdropTrap( lifeId, awardId )
{
    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    radius = getdvarfloat( "fun_mode_airdrop_trap_stim_radius" );
    duration = getdvarfloat( "fun_mode_airdrop_trap_stim_duration" );

    if ( radius < 1 )
        radius = 1;

    if ( duration < 1.0 )
        duration = 1.0;

    radiusSquared = radius * radius;

    foreach ( player in level.players )
    {
        if ( !self canReceiveJuicedPulse( player, radiusSquared ) )
            continue;

        player scripts\deathstreak_tuning::grantTimedJuiced( duration );
        player playlocalsound( "ammo_crate_use" );
    }

    maps\mp\_matchdata::logkillstreakevent( "airdrop_trap", self.origin );
    return 1;
}

canReceiveJuicedPulse( player, radiusSquared )
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
