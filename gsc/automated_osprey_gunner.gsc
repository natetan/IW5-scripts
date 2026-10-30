/*
    Automated Assault Osprey Gunner - IW5 / Plutonium

    Preserves the stock laptop location selection, flight path, three Assault
    care-package drops, 75-second lifetime, health, flares, and AA counters.
    The laptop selector omits the stock ride-camera initialization, so the
    owner returns directly to normal play after confirming the drop point and
    the aircraft autonomously operates its minigun.

    Target priority:
        1. Visible hostile helicopters, Pave Lows, and AH-6s
        2. Visible hostile players who do not have Blind Eye

    Set fun_mode_automated_osprey_gunner_enable to 0 before loading a map to
    restore the stock player-controlled Osprey Gunner.
*/

#include maps\mp\killstreaks\_escortairdrop;

main()
{
    setdvarifuninitialized( "fun_mode_automated_osprey_gunner_enable", 1 );
    setdvarifuninitialized( "fun_mode_automated_osprey_burst_shots", 12 );
    setdvarifuninitialized( "fun_mode_automated_osprey_shot_interval", 0.10 );
    setdvarifuninitialized( "fun_mode_automated_osprey_burst_interval", 0.50 );

    if ( !getdvarint( "fun_mode_automated_osprey_gunner_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_escortairdrop::useospreygunner,
        ::useAutomatedOspreyGunner
    );

    replacefunc(
        maps\mp\killstreaks\_escortairdrop::selectdroplocation,
        ::selectAutomatedOspreyDropLocation
    );
}

selectAutomatedOspreyDropLocation(
    lifeId,
    streakName,
    friendlyIcon,
    enemyIcon,
    prompt
)
{
    self endon( "customCancelLocation" );

    maps\mp\_utility::_beginlocationselection(
        streakName,
        "map_artillery_selector",
        0,
        500
    );
    thread maps\mp\killstreaks\_escortairdrop::stopselectionwatcher();
    self waittill( "confirm_location", dropLocation, directionYaw );
    maps\mp\_utility::stoplocationselection( 0 );

    // Stock enters initridekillstreak() here, which starts the remote-camera
    // fade before the gunner is attached. Automation never creates a ride, so
    // validate the aircraft slot directly and retain the confirmed location.
    if ( isdefined( level.chopper ) )
    {
        self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
        return 0;
    }

    if (
        maps\mp\_utility::currentactivevehiclecount() >=
            maps\mp\_utility::maxvehiclesallowed() ||
        level.fauxvehiclecount >= maps\mp\_utility::maxvehiclesallowed()
    )
    {
        self iprintlnbold( &"MP_TOO_MANY_VEHICLES" );
        return 0;
    }

    thread maps\mp\killstreaks\_escortairdrop::finishospreygunnerusage(
        lifeId,
        dropLocation,
        directionYaw,
        streakName
    );
    return 1;
}

useAutomatedOspreyGunner( lifeId, osprey, startNode, destination, exitPoint, flightHeight )
{
    if ( !isdefined( osprey ) )
        return;

    owner = self;

    // The custom selector never enters ride state; only restore the weapon
    // after the laptop closes and keep the stock used-streak feedback.
    owner thread restoreWeaponAfterAutomatedOspreyActivation();
    owner thread maps\mp\_utility::teamplayercardsplash(
        "used_osprey_gunner",
        owner
    );

    osprey thread maps\mp\killstreaks\_escortairdrop::airshipflygunner(
        owner,
        startNode,
        destination,
        exitPoint,
        flightHeight
    );
    osprey thread runAutomatedOspreyGunner( owner, lifeId );
}

restoreWeaponAfterAutomatedOspreyActivation()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );

    waittillframeend;
    returnWeapon = common_scripts\utility::getlastweapon();

    if (
        !isdefined( returnWeapon ) ||
        returnWeapon == "none" ||
        !self hasweapon( returnWeapon )
    )
    {
        primaryWeapons = self getweaponslistprimaries();

        if ( !primaryWeapons.size )
            return;

        returnWeapon = primaryWeapons[0];
    }

    self switchtoweapon( returnWeapon );
}

runAutomatedOspreyGunner( owner, lifeId )
{
    self endon( "helicopter_removed" );
    self endon( "helicopter_done" );
    self endon( "crashing" );
    self endon( "death" );
    level endon( "game_ended" );

    if ( !isdefined( owner ) )
        return;

    burstShots = getdvarint( "fun_mode_automated_osprey_burst_shots" );
    shotInterval = getdvarfloat( "fun_mode_automated_osprey_shot_interval" );
    burstInterval = getdvarfloat( "fun_mode_automated_osprey_burst_interval" );

    if ( burstShots < 1 )
        burstShots = 1;

    if ( shotInterval < 0.05 )
        shotInterval = 0.05;

    if ( burstInterval < 0.05 )
        burstInterval = 0.05;

    // Let the aircraft enter the map before asking its turret to acquire.
    wait 1.0;

    for (;;)
    {
        target = self getAutomatedOspreyTarget( owner );

        if ( !isdefined( target ) )
        {
            wait 0.25;
            continue;
        }

        self setturrettargetent( target );
        self setlookatent( target );

        for ( shot = 0; shot < burstShots; shot++ )
        {
            if ( !self isValidAutomatedOspreyTarget( target, owner ) )
                break;

            self fireweapon( "tag_flash", target );
            wait shotInterval;
        }

        wait burstInterval;
    }
}

getAutomatedOspreyTarget( owner )
{
    muzzle = self gettagorigin( "tag_flash" );
    airTarget = self getAutomatedOspreyAirTarget( owner, muzzle );

    if ( isdefined( airTarget ) )
        return airTarget;

    nearestTarget = undefined;
    nearestDistanceSquared = 999999999;

    foreach ( player in level.players )
    {
        if ( !self isValidAutomatedOspreyPlayerTarget( player, owner, muzzle ) )
            continue;

        targetDistanceSquared = distancesquared( muzzle, player.origin );

        if ( targetDistanceSquared < nearestDistanceSquared )
        {
            nearestTarget = player;
            nearestDistanceSquared = targetDistanceSquared;
        }
    }

    return nearestTarget;
}

getAutomatedOspreyAirTarget( owner, muzzle )
{
    nearestTarget = undefined;
    nearestDistanceSquared = 999999999;

    if ( isdefined( level.helis ) )
    {
        foreach ( aircraft in level.helis )
        {
            if ( !self isValidAutomatedOspreyAircraft( aircraft, owner, muzzle ) )
                continue;

            targetDistanceSquared = distancesquared( muzzle, aircraft.origin );

            if ( targetDistanceSquared < nearestDistanceSquared )
            {
                nearestTarget = aircraft;
                nearestDistanceSquared = targetDistanceSquared;
            }
        }
    }

    if ( isdefined( level.littlebirds ) )
    {
        foreach ( aircraft in level.littlebirds )
        {
            if ( !self isValidAutomatedOspreyAircraft( aircraft, owner, muzzle ) )
                continue;

            targetDistanceSquared = distancesquared( muzzle, aircraft.origin );

            if ( targetDistanceSquared < nearestDistanceSquared )
            {
                nearestTarget = aircraft;
                nearestDistanceSquared = targetDistanceSquared;
            }
        }
    }

    return nearestTarget;
}

isValidAutomatedOspreyTarget( target, owner )
{
    if ( !isdefined( target ) )
        return 0;

    muzzle = self gettagorigin( "tag_flash" );

    if ( isplayer( target ) )
        return self isValidAutomatedOspreyPlayerTarget( target, owner, muzzle );

    return self isValidAutomatedOspreyAircraft( target, owner, muzzle );
}

isValidAutomatedOspreyAircraft( aircraft, owner, muzzle )
{
    if (
        !isdefined( aircraft ) ||
        aircraft == self ||
        !isdefined( aircraft.origin ) ||
        ( isdefined( aircraft.health ) && aircraft.health <= 0 ) ||
        ( isdefined( aircraft.currentstate ) && aircraft.currentstate != "ok" )
    )
    {
        return 0;
    }

    if ( level.teambased )
    {
        if ( !isdefined( aircraft.team ) || aircraft.team == self.team )
            return 0;
    }
    else if ( isdefined( aircraft.owner ) && aircraft.owner == owner )
    {
        return 0;
    }

    return sighttracepassed( muzzle, aircraft.origin, 0, self, aircraft );
}

isValidAutomatedOspreyPlayerTarget( player, owner, muzzle )
{
    if (
        !isdefined( player ) ||
        !isplayer( player ) ||
        !maps\mp\_utility::isreallyalive( player ) ||
        player == owner ||
        player maps\mp\_utility::_hasperk( "specialty_blindeye" )
    )
    {
        return 0;
    }

    if ( level.teambased )
    {
        if ( !isdefined( player.team ) || player.team == self.team )
            return 0;
    }

    targetOrigin = player gettagorigin( "j_spineupper" );
    return sighttracepassed( muzzle, targetOrigin, 0, self, player );
}

