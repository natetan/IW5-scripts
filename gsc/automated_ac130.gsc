/*
    Automated AC-130 - IW5 / Plutonium

    Converts the stock player-controlled AC-130 into autonomous air support.
    The owner remains on the ground while the stock aircraft orbits, retains
    its normal health and two flares, and remains vulnerable to normal AA.

    Weapon damage, streak duration, aircraft durability, and countermeasures
    remain stock. The existing ac130_reload_tuning.gsc values are used only as
    pacing between the autonomous 105 mm, 40 mm, and 25 mm firing cycle. The
    25 mm cannon prioritizes visible hostile aircraft before infantry; the
    105 mm and 40 mm cannons remain player-only.

    Set fun_mode_automated_ac130_enable to 0 before loading a map to restore
    the stock player-controlled AC-130.
*/

#include maps\mp\killstreaks\_ac130;

main()
{
    setdvarifuninitialized( "fun_mode_automated_ac130_enable", 1 );
    setdvarifuninitialized( "fun_mode_automated_ac130_25mm_air_priority_enable", 1 );

    if ( !getdvarint( "fun_mode_automated_ac130_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_ac130::tryuseac130,
        ::tryUseAutomatedAc130
    );
}

tryUseAutomatedAc130( lifeId )
{
    if ( isdefined( level.civilianjetflyby ) )
    {
        self iprintlnbold( &"MP_CIVILIAN_AIR_TRAFFIC" );
        return 0;
    }

    if ( isdefined( level.ac130player ) || level.ac130inuse )
    {
        self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
        return 0;
    }

    if (
        self maps\mp\_utility::isusingremote() ||
        maps\mp\_utility::isairdenied() ||
        maps\mp\_utility::isemped()
    )
    {
        return 0;
    }

    if ( !self maps\mp\_utility::validateusestreak() )
        return 0;

    self maps\mp\_matchdata::logkillstreakevent( "ac130", self.origin );
    return startAutomatedAc130( self, lifeId );
}

startAutomatedAc130( owner, lifeId )
{
    if (
        !isdefined( owner ) ||
        !isdefined( level.ac130 ) ||
        !isdefined( level.ac130.planemodel )
    )
    {
        return 0;
    }

    plane = level.ac130.planemodel;
    level.ac130player = owner;
    level.ac130.owner = owner;
    level.ac130inuse = 1;
    level.automatedAc130CleaningUp = 0;
    plane.crashed = undefined;
    level.ac130.incomingmissile = 0;
    level.ac130.numflares = level.ac130_num_flares;

    plane show();
    plane playloopsound( "veh_ac130_ext_dist" );
    plane thread maps\mp\killstreaks\_ac130::playac130effects();
    plane thread maps\mp\killstreaks\_ac130::damagetracker();

    compassPlane = spawnplane(
        owner,
        "script_model",
        plane.origin,
        "compass_objpoint_ac130_friendly",
        "compass_objpoint_ac130_enemy"
    );

    if ( isdefined( compassPlane ) )
    {
        compassPlane notsolid();
        compassPlane linkto(
            level.ac130,
            "tag_player",
            ( 0, 80, 32 ),
            ( 0, -90, 0 )
        );
        compassPlane thread maps\mp\killstreaks\_ac130::deleteonac130playerremoved();
    }

    owner thread maps\mp\_utility::teamplayercardsplash(
        "used_ac130",
        owner
    );
    owner thread restoreWeaponAfterAutomatedAc130Activation();
    owner thread watchAutomatedAc130OwnerState();
    plane thread watchAutomatedAc130Crash();
    plane thread runAutomatedAc130( owner, lifeId );

    duration = level.ac130_use_duration * owner.killstreakscaler;
    level thread expireAutomatedAc130( owner, duration );
    return 1;
}

restoreWeaponAfterAutomatedAc130Activation()
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

watchAutomatedAc130OwnerState()
{
    self endon( "ac130player_removed" );
    level endon( "game_ended" );

    common_scripts\utility::waittill_any(
        "disconnect",
        "joined_team",
        "joined_spectators"
    );
    level thread finishAutomatedAc130( self );
}

watchAutomatedAc130Crash()
{
    self endon( "ac130player_removed" );
    self waittill( "crashing" );
    level thread finishAutomatedAc130( level.ac130player );
}

expireAutomatedAc130( owner, duration )
{
    level endon( "game_ended" );
    level endon( "ac130player_removed" );

    maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(
        duration
    );
    level thread finishAutomatedAc130( owner );
}

runAutomatedAc130( owner, lifeId )
{
    level endon( "game_ended" );
    level endon( "ac130player_removed" );
    self endon( "death" );
    self endon( "crashing" );

    wait 1.0;

    while (
        isdefined( owner ) &&
        isdefined( level.ac130player ) &&
        level.ac130player == owner
    )
    {
        target = getAutomatedAc130Target( owner );

        if ( !isdefined( target ) )
        {
            wait 0.25;
            continue;
        }

        fireAutomatedAc130Round(
            owner,
            target,
            "ac130_105mm_mp",
            lifeId
        );
        reloadDelay = getAutomatedAc130ReloadDelay( "ac130_105mm_mp" );
        wait reloadDelay;

        target = getAutomatedAc130Target( owner );

        if ( isdefined( target ) )
        {
            fireAutomatedAc130Round(
                owner,
                target,
                "ac130_40mm_mp",
                lifeId
            );
        }

        reloadDelay = getAutomatedAc130ReloadDelay( "ac130_40mm_mp" );
        wait reloadDelay;

        for ( shot = 0; shot < 10; shot++ )
        {
            target = getAutomatedAc13025mmTarget( owner );

            if ( !isdefined( target ) )
                break;

            fireAutomatedAc130Round(
                owner,
                target,
                "ac130_25mm_mp",
                lifeId
            );
            wait 0.1;
        }

        reloadDelay = getAutomatedAc130ReloadDelay( "ac130_25mm_mp" );
        wait reloadDelay;
    }
}

getAutomatedAc130ReloadDelay( weapon )
{
    if (
        getdvarint( "fun_mode_ac130_reload_tuning_enable" ) &&
        weapon == "ac130_105mm_mp"
    )
    {
        return getdvarfloat( "fun_mode_ac130_105mm_reload_seconds" );
    }

    if (
        getdvarint( "fun_mode_ac130_reload_tuning_enable" ) &&
        weapon == "ac130_40mm_mp"
    )
    {
        return getdvarfloat( "fun_mode_ac130_40mm_reload_seconds" );
    }

    if (
        getdvarint( "fun_mode_ac130_reload_tuning_enable" ) &&
        weapon == "ac130_25mm_mp"
    )
    {
        return getdvarfloat( "fun_mode_ac130_25mm_reload_seconds" );
    }

    return level.weaponreloadtime[weapon];
}

fireAutomatedAc130Round( owner, target, weapon, lifeId )
{
    if (
        !isdefined( owner ) ||
        !isdefined( target ) ||
        !isdefined( level.ac130.planemodel )
    )
    {
        return;
    }

    launchOrigin = level.ac130.planemodel.origin + ( 0, 0, -32 );

    if ( isplayer( target ) )
    {
        if ( !isalive( target ) )
            return;

        targetOrigin = target gettagorigin( "j_spineupper" );
    }
    else
    {
        if (
            !isdefined( target.origin ) ||
            ( isdefined( target.health ) && target.health <= 0 ) ||
            ( isdefined( target.currentstate ) && target.currentstate != "ok" )
        )
        {
            return;
        }

        targetOrigin = target.origin;
    }

    projectile = magicbullet( weapon, launchOrigin, targetOrigin, owner );

    if ( isdefined( projectile ) )
        projectile.lifeid = lifeId;
}

getAutomatedAc13025mmTarget( owner )
{
    if ( getdvarint( "fun_mode_automated_ac130_25mm_air_priority_enable" ) )
    {
        airTarget = getAutomatedAc130AirTarget( owner );

        if ( isdefined( airTarget ) )
            return airTarget;
    }

    return getAutomatedAc130Target( owner );
}

getAutomatedAc130AirTarget( owner )
{
    if (
        !isdefined( owner ) ||
        !isdefined( level.ac130.planemodel )
    )
    {
        return undefined;
    }

    aircraftCandidates = [];

    if ( isdefined( level.helis ) )
    {
        foreach ( aircraft in level.helis )
            aircraftCandidates[aircraftCandidates.size] = aircraft;
    }

    if ( isdefined( level.littlebirds ) )
    {
        foreach ( aircraft in level.littlebirds )
            aircraftCandidates[aircraftCandidates.size] = aircraft;
    }

    if ( isdefined( level.harriers ) )
    {
        foreach ( aircraft in level.harriers )
            aircraftCandidates[aircraftCandidates.size] = aircraft;
    }

    nearestTarget = undefined;
    nearestDistanceSquared = 999999999;
    planeOrigin = level.ac130.planemodel.origin;

    foreach ( aircraft in aircraftCandidates )
    {
        if ( !isValidAutomatedAc130Aircraft( aircraft, owner, planeOrigin ) )
            continue;

        targetDistanceSquared = distancesquared( planeOrigin, aircraft.origin );

        if ( targetDistanceSquared < nearestDistanceSquared )
        {
            nearestTarget = aircraft;
            nearestDistanceSquared = targetDistanceSquared;
        }
    }

    return nearestTarget;
}

isValidAutomatedAc130Aircraft( aircraft, owner, planeOrigin )
{
    if (
        !isdefined( aircraft ) ||
        aircraft == level.ac130.planemodel ||
        !isdefined( aircraft.origin ) ||
        ( isdefined( aircraft.health ) && aircraft.health <= 0 ) ||
        ( isdefined( aircraft.currentstate ) && aircraft.currentstate != "ok" )
    )
    {
        return false;
    }

    // The Reaper also uses the helicopter framework, but it is not one of the
    // lower aircraft the AC-130's 25 mm cannon is intended to engage.
    if (
        isdefined( aircraft.heliType ) &&
        aircraft.heliType == "remote_mortar"
    )
    {
        return false;
    }

    if ( level.teambased )
    {
        if ( !isdefined( aircraft.team ) || aircraft.team == owner.team )
            return false;
    }
    else if ( isdefined( aircraft.owner ) && aircraft.owner == owner )
    {
        return false;
    }

    return sighttracepassed(
        planeOrigin,
        aircraft.origin,
        0,
        level.ac130.planemodel,
        aircraft
    );
}

getAutomatedAc130Target( owner )
{
    candidates = [];
    planeOrigin = level.ac130.planemodel.origin;

    foreach ( player in level.players )
    {
        if (
            !isdefined( player ) ||
            !isplayer( player ) ||
            !isalive( player ) ||
            !isdefined( player.sessionstate ) ||
            player.sessionstate != "playing" ||
            !isdefined( player.team ) ||
            player.team == "spectator"
        )
        {
            continue;
        }

        if ( level.teambased && player.team == owner.team )
            continue;

        if ( player maps\mp\_utility::_hasperk( "specialty_blindeye" ) )
            continue;

        targetOrigin = player gettagorigin( "j_spineupper" );

        if ( !bullettracepassed( planeOrigin, targetOrigin, false, self ) )
            continue;

        candidates[candidates.size] = player;
    }

    if ( !candidates.size )
        return undefined;

    return candidates[randomint( candidates.size )];
}

finishAutomatedAc130( owner )
{
    if (
        !isdefined( level.automatedAc130CleaningUp ) ||
        level.automatedAc130CleaningUp
    )
    {
        return;
    }

    level.automatedAc130CleaningUp = 1;

    if ( isdefined( owner ) )
        owner notify( "ac130player_removed" );

    level notify( "ac130player_removed" );

    if ( isdefined( level.ac130.cameramodel ) )
        level.ac130.cameramodel notify( "death" );

    waittillframeend;

    if ( isdefined( level.ac130.planemodel ) )
    {
        level.ac130.planemodel stoploopsound();

        if ( !isdefined( level.ac130.planemodel.crashed ) )
            level.ac130.planemodel hide();
    }

    level.ac130player = undefined;
    level.ac130.owner = undefined;
    level.ac130inuse = 0;
    level.automatedAc130CleaningUp = 0;
}
