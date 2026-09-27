/*
    Strafe Run -> AA Strike - IW5 / Plutonium

    Replaces the nine-kill Strafe Run (littlebird_flock) with IW5's dormant
    AA Strike. The stock AA implementation launches Harrier flybys, targets
    enemy aircraft/UAVs/AC-130s with guided missiles, and temporarily denies
    the enemy team access to air support. Two spaced air-to-ground missiles
    give the nine-kill reward a small amount of offensive value as well.

    Set fun_mode_aa_strike_enable to 0 before loading a map to leave the
    original Strafe Run callback untouched.
*/

#include maps\mp\killstreaks\_aastrike;
#include maps\mp\killstreaks\_helicopter_flock;

main()
{
    setdvarifuninitialized( "fun_mode_aa_strike_enable", 1 );

    if ( !getdvarint( "fun_mode_aa_strike_enable" ) )
        return;

    // _killstreaks initializes Strafe Run, but the shipped AA Strike init is
    // never called. Initialize its projectile, model, and tracking state.
    maps\mp\killstreaks\_aastrike::init();

    replacefunc(
        maps\mp\killstreaks\_helicopter_flock::tryuselbflock,
        ::tryUseAaStrikeInsteadOfStrafeRun
    );
}

tryUseAaStrikeInsteadOfStrafeRun( lifeId, awardId )
{
    used = self maps\mp\killstreaks\_aastrike::tryuseaastrike( lifeId );

    if ( !used )
        return 0;

    self thread aaGroundSupport( lifeId );
    return 1;
}

aaGroundSupport( lifeId )
{
    self endon( "disconnect" );
    self endon( "joined_team" );
    self endon( "joined_spectators" );
    level endon( "game_ended" );

    // Match the timing of the stock AA flybys instead of front-loading the
    // extra damage when the laptop closes.
    wait 6.0;

    for ( shot = 0; shot < 2; shot++ )
    {
        target = self getRandomLivingEnemy();

        if ( isdefined( target ) )
            self fireAaGroundMissile( target, lifeId );

        if ( shot == 0 )
            wait 9.0;
    }
}

getRandomLivingEnemy()
{
    enemies = [];

    foreach ( player in level.players )
    {
        if ( !isdefined( player ) || player == self || !isalive( player ) )
            continue;

        if ( player.team == "spectator" )
            continue;

        if ( level.teambased && player.team == self.team )
            continue;

        enemies[enemies.size] = player;
    }

    if ( !enemies.size )
        return undefined;

    return enemies[randomint( enemies.size )];
}

fireAaGroundMissile( target, lifeId )
{
    launchOrigin = target.origin + (
        randomintrange( -3500, 3500 ),
        randomintrange( -3500, 3500 ),
        5000
    );
    targetOrigin = target.origin + ( 0.0, 0.0, 36.0 );

    missile = magicbullet(
        "aamissile_projectile_mp",
        launchOrigin,
        targetOrigin,
        self
    );

    if ( !isdefined( missile ) )
        return;

    missile.lifeid = lifeId;
    missile missile_settargetent( target );
    missile missile_setflightmodedirect();
}
