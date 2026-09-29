/*
    AH-6 Rocket Support - IW5 / Plutonium

    Preserves the stock AH-6 Overwatch flight, dual miniguns, health, duration,
    and defensive counters while adding a single FFAR against its current
    minigun target. The rocket has an eight-second cooldown and alternates
    between the helicopter's left and right weapon mounts.

    This is deliberately isolated as an experimental fun-mode enhancement.
    Set fun_mode_ah6_rockets_enable to 0 before loading a map to retain the
    completely stock AH-6.
*/

#include maps\mp\killstreaks\_helicopter_guard;

main()
{
    setdvarifuninitialized( "fun_mode_ah6_rockets_enable", 1 );
    setdvarifuninitialized( "fun_mode_ah6_rocket_cooldown_seconds", 8 );

    if ( !getdvarint( "fun_mode_ah6_rockets_enable" ) )
        return;

    level thread watchForAh6RocketSupport();
}

watchForAh6RocketSupport()
{
    level endon( "game_ended" );
    activeAh6 = undefined;

    for (;;)
    {
        if (
            isdefined( level.littlebirdguard ) &&
            ( !isdefined( activeAh6 ) || level.littlebirdguard != activeAh6 )
        )
        {
            activeAh6 = level.littlebirdguard;
            activeAh6 thread ah6RocketController();
        }

        wait 0.25;
    }
}

ah6RocketController()
{
    self endon( "death" );
    self endon( "leaving" );
    self endon( "gone" );
    level endon( "game_ended" );

    // Allow the helicopter to enter the map and establish its escort route.
    wait 4.0;
    launchFromLeft = 1;

    for (;;)
    {
        if ( isdefined( self.empgrenaded ) && self.empgrenaded )
        {
            wait 0.25;
            continue;
        }

        target = self getAh6CurrentTarget();

        if ( !self canAh6RocketTarget( target ) )
        {
            wait 0.25;
            continue;
        }

        self fireAh6Rocket( target, launchFromLeft );
        launchFromLeft = !launchFromLeft;

        cooldown = getdvarfloat( "fun_mode_ah6_rocket_cooldown_seconds" );

        if ( cooldown < 1.0 )
            cooldown = 1.0;

        wait cooldown;
    }
}

getAh6CurrentTarget()
{
    target = undefined;

    if ( isdefined( self.mgturretleft ) )
        target = self.mgturretleft getturrettarget( 0 );

    if ( !isdefined( target ) && isdefined( self.mgturretright ) )
        target = self.mgturretright getturrettarget( 0 );

    return target;
}

canAh6RocketTarget( target )
{
    if ( !isdefined( target ) || !isplayer( target ) || !isalive( target ) )
        return 0;

    if ( target.sessionstate != "playing" || target.team == "spectator" )
        return 0;

    if ( target == self.owner )
        return 0;

    if ( level.teambased && target.team == self.team )
        return 0;

    if ( target maps\mp\_utility::_hasperk( "specialty_blindeye" ) )
        return 0;

    if ( isdefined( target.spawntime ) && ( gettime() - target.spawntime ) / 1000 <= 5 )
        return 0;

    if ( distance2d( self.origin, target.origin ) < 512 )
        return 0;

    targetOrigin = target.origin + ( 0, 0, 32 );

    if ( !bullettracepassed( self.origin, targetOrigin, 0, self ) )
        return 0;

    targetDirection = vectornormalize( targetOrigin - self.origin );
    forwardDirection = vectornormalize( anglestoforward( self.angles ) );

    if ( vectordot( targetDirection, forwardDirection ) < 0.35 )
        return 0;

    return 1;
}

fireAh6Rocket( target, launchFromLeft )
{
    if ( !isdefined( target ) )
        return;

    launchTag = "tag_minigun_attach_right";

    if ( launchFromLeft )
        launchTag = "tag_minigun_attach_left";

    self setvehweapon( "harrier_FFAR_mp" );
    missile = self fireweapon( launchTag, target );

    if ( !isdefined( missile ) )
        return;

    missile missile_setflightmodedirect();
    missile missile_settargetent( target );
}
