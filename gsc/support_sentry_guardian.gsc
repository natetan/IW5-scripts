/*
    Support Guardian Sentry - IW5 / Plutonium

    Converts the twelve-point Support Remote Sentry into a place-and-forget
    autonomous turret. It prioritizes visible hostile helicopters, AH-6s,
    Pave Lows, and Harriers from IW5's helicopter registries, then falls back
    to the native sentry controller's infantry targeting.

    Support Sentries remain deployed until destroyed, replaced, the owner
    disconnects or changes teams, or the match ends. Each owner may maintain
    two turrets; placing a third destroys the oldest turret in FIFO order.

    Set fun_mode_support_guardian_sentry_enable to 0 before loading a map to
    restore the stock player-controlled Remote Sentry.
*/

#include maps\mp\killstreaks\_autosentry;
#include maps\mp\killstreaks\_remoteturret;

main()
{
    setdvarifuninitialized( "fun_mode_support_guardian_sentry_enable", 1 );

    if ( !getdvarint( "fun_mode_support_guardian_sentry_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_remoteturret::turret_setactive,
        ::activateSupportGuardianSentry
    );
}

activateSupportGuardianSentry()
{
    self endon( "death" );
    level endon( "game_ended" );

    if ( !isdefined( self.owner ) )
    {
        self notify( "death" );
        return;
    }

    owner = self.owner;
    owner endon( "disconnect" );

    self setdefaultdroppitch( 0 );
    self makeunusable();
    self maketurretsolid();
    self.funModeSupportGuardian = 1;

    // Reuse IW5's proven autonomous Sentry fire, heat, and EMP controllers.
    // The physical weapon and model remain the Support Remote Sentry assets.
    self.sentrytype = "sentry_minigun";
    self setmode( level.sentrysettings[self.sentrytype].sentrymodeon );
    self setsentryowner( owner );
    self setturretminimapvisible( 1, "mg_turret" );

    if ( level.teambased )
    {
        self.team = owner.team;
        self setturretteam( owner.team );
        maps\mp\_entityheadicons::setteamheadicon(
            owner.team,
            ( 0, 0, 65 )
        );
    }
    else
    {
        maps\mp\_entityheadicons::setplayerheadicon(
            owner,
            ( 0, 0, 65 )
        );
    }

    addSupportGuardianToOwnerQueue( owner );
    owner.using_remote_turret = 0;
    owner.remoteturretlist = owner.funModeSupportGuardianQueue;

    self thread maps\mp\killstreaks\_remoteturret::turret_handledeath();
    self thread maps\mp\killstreaks\_remoteturret::turret_handledamage();
    self thread maps\mp\killstreaks\_remoteturret::turret_blinky_light();
    self thread maps\mp\killstreaks\_autosentry::sentry_attacktargets();
    self thread maps\mp\killstreaks\_autosentry::sentry_watchdisabled();
    self thread prioritizeHostileAirSupport();
    self thread removeSupportGuardianFromOwnerQueue( owner );
}

addSupportGuardianToOwnerQueue( owner )
{
    compactQueue = [];

    if ( isdefined( owner.funModeSupportGuardianQueue ) )
    {
        foreach ( turret in owner.funModeSupportGuardianQueue )
        {
            if ( isdefined( turret ) )
                compactQueue[compactQueue.size] = turret;
        }
    }

    while ( compactQueue.size >= 2 )
    {
        oldest = compactQueue[0];
        nextQueue = [];

        for ( index = 1; index < compactQueue.size; index++ )
            nextQueue[nextQueue.size] = compactQueue[index];

        compactQueue = nextQueue;

        if ( isdefined( oldest ) )
            oldest notify( "death" );
    }

    compactQueue[compactQueue.size] = self;
    owner.funModeSupportGuardianQueue = compactQueue;
}

removeSupportGuardianFromOwnerQueue( owner )
{
    self waittill( "death" );

    if ( !isdefined( owner ) || !isdefined( owner.funModeSupportGuardianQueue ) )
        return;

    compactQueue = [];

    foreach ( turret in owner.funModeSupportGuardianQueue )
    {
        if ( isdefined( turret ) && turret != self )
            compactQueue[compactQueue.size] = turret;
    }

    owner.funModeSupportGuardianQueue = compactQueue;
    owner.remoteturretlist = compactQueue;
}

prioritizeHostileAirSupport()
{
    self endon( "death" );
    level endon( "game_ended" );
    currentAirTarget = undefined;

    for (;;)
    {
        airTarget = getHostileSupportSentryAirTarget();

        if ( isdefined( airTarget ) )
        {
            if ( !isdefined( currentAirTarget ) || currentAirTarget != airTarget )
            {
                self settargetentity( airTarget );
                currentAirTarget = airTarget;
            }
        }
        else if ( isdefined( currentAirTarget ) )
        {
            self cleartargetentity();
            currentAirTarget = undefined;
        }

        wait 0.25;
    }
}

getHostileSupportSentryAirTarget()
{
    muzzle = self gettagorigin( "tag_aim" );

    if ( isdefined( level.helis ) )
    {
        foreach ( aircraft in level.helis )
        {
            if ( isValidHostileSupportSentryAircraft( aircraft, muzzle ) )
                return aircraft;
        }
    }

    if ( isdefined( level.littlebirds ) )
    {
        foreach ( aircraft in level.littlebirds )
        {
            if ( isValidHostileSupportSentryAircraft( aircraft, muzzle ) )
                return aircraft;
        }
    }

    return undefined;
}

isValidHostileSupportSentryAircraft( aircraft, muzzle )
{
    if ( !isdefined( aircraft ) || !isdefined( aircraft.origin ) )
        return 0;

    if ( level.teambased )
    {
        if ( !isdefined( aircraft.team ) || aircraft.team == self.team )
            return 0;
    }
    else if (
        isdefined( aircraft.owner ) &&
        isdefined( self.owner ) &&
        aircraft.owner == self.owner
    )
    {
        return 0;
    }

    if ( !sighttracepassed( muzzle, aircraft.origin, 0, self, aircraft ) )
        return 0;

    return 1;
}
