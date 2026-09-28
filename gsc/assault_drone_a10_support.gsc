/*
    Assault Drone -> A-10 Close Air Support - IW5 / Plutonium

    Replaces the ten-point, player-controlled Assault Drone with two fully
    autonomous A-10 attack passes. Each pass aims at the strongest living
    enemy cluster, opens with a pair of Harrier FFARs, and follows with the
    stock A-10's 30 mm cannon sweep.

    Set fun_mode_a10_support_enable to 0 before loading a map to retain the
    stock Assault Drone.
*/

#include maps\mp\killstreaks\_a10;
#include maps\mp\killstreaks\_airdrop;
#include maps\mp\killstreaks\_remotetank;

main()
{
    setdvarifuninitialized( "fun_mode_a10_support_enable", 1 );

    if ( !getdvarint( "fun_mode_a10_support_enable" ) )
        return;

    // The dormant A-10 script exists, but its model, FX, cannon, and compass
    // assets are incomplete in this IW5 build. Initialize only the working
    // flight and damage tuning, then present the runs with shipped Harrier
    // assets below.
    level.a10maxhealth = 350;
    level.a10speed = 100;
    level.a10speedreduction = 75;
    level.a10startpointoffset = 5000;
    level.a10damage = 200;
    level.a10damageradius = 384;
    level.a10earthquakemagnitude = 0.1;
    level.a10earthquakeduration = 0.5;
    level.a10earthquakedelay = 0.5;
    level.a10dirteffectradius = 350;
    level.a10shootinggroundsounddelay = 0.1;
    level.a10startpositionscalar = 2000;

    level.killstreakweildweapons["aamissile_projectile_mp"] = 1;

    level.funModeA10SupportInProgress = 0;

    replacefunc(
        maps\mp\killstreaks\_remotetank::tryuseremotetank,
        ::tryUseA10SupportInsteadOfAssaultDrone
    );

    // The equipped ten-point Assault Drone is actually an airdrop wrapper.
    // Intercept it before a stealable Remote Tank crate is ever requested.
    replacefunc(
        maps\mp\killstreaks\_airdrop::tryuseairdropremotetank,
        ::tryUseA10SupportInsteadOfAssaultDroneDrop
    );

    // The dormant A-10 model has no tag_gun and its cannon weapon cannot be
    // passed to magicbullet. Replace that broken firing path and its unused
    // minimap shaders while retaining the stock flight and destruction code.
    replacefunc(
        maps\mp\killstreaks\_a10::starta10shooting,
        ::startA10CannonSweep
    );
    replacefunc(
        maps\mp\killstreaks\_a10::spawna10,
        ::spawnA10WithWorkingIcons
    );
    replacefunc(
        maps\mp\killstreaks\_a10::a10playenginefx,
        ::disableBrokenA10EngineFx
    );
}

tryUseA10SupportInsteadOfAssaultDrone( lifeId )
{
    return self tryStartA10Support( lifeId, "remote_tank", 1 );
}

tryUseA10SupportInsteadOfAssaultDroneDrop( lifeId, awardId )
{
    return self tryStartA10Support( lifeId, "airdrop_remote_tank", 0 );
}

tryStartA10Support( lifeId, streakName, removeRemoteTankWeapons )
{
    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    if ( isdefined( level.civilianjetflyby ) )
    {
        self iprintlnbold( &"MP_CIVILIAN_AIR_TRAFFIC" );
        return 0;
    }

    if (
        maps\mp\_utility::isusingremote() ||
        maps\mp\_utility::isairdenied() ||
        maps\mp\_utility::isemped()
    )
    {
        return 0;
    }

    if ( level.funModeA10SupportInProgress > 0 )
    {
        self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
        return 0;
    }

    target = self getBestA10Target();

    if ( !isdefined( target ) )
        return 0;

    maps\mp\_matchdata::logkillstreakevent( streakName, target.origin );

    // Direct Remote Tank awards carry two extra control weapons. The normal
    // ten-point airdrop wrapper does not, and the generic killstreak handler
    // consumes that equipped reward after this callback returns successfully.
    if ( removeRemoteTankWeapons )
        self maps\mp\killstreaks\_remotetank::takekillstreakweapons( "remote_tank" );

    self.iscarrying = 0;
    self thread runA10Support( lifeId );
    return 1;
}

spawnA10WithWorkingIcons( owner, startPoint, endPoint, attackPoint, initialDelay )
{
    startPoint += ( 0, 0, level.a10startpointoffset );
    planeAngles = vectortoangles( endPoint - startPoint );
    plane = spawn( "script_model", startPoint );

    // The shipped A-10 compass shaders render as gray placeholder boxes. Use
    // the valid fighter icons already precached by the stock airstrike system.
    compassPlane = spawnplane(
        owner,
        "script_model",
        startPoint,
        "hud_minimap_harrier_green",
        "hud_minimap_harrier_red"
    );

    if ( !isdefined( plane ) )
        return undefined;

    compassPlane linkto( plane );
    plane.fakea10 = compassPlane;
    if ( owner.team == "allies" )
        plane setmodel( "vehicle_av8b_harrier_jet_mp" );
    else
        plane setmodel( "vehicle_av8b_harrier_jet_opfor_mp" );
    plane.health = 999999;
    plane.maxhealth = level.a10maxhealth;
    plane.damagetaken = 0;
    plane.owner = owner;
    plane.team = owner.team;
    plane.killcount = 0;
    plane.startpoint = startPoint;
    plane.endpoint = endPoint;
    plane.attackpoint = attackPoint;
    plane.initialdelay = initialDelay;
    plane.angles = planeAngles;
    return plane;
}

disableBrokenA10EngineFx()
{
    // vehicle_a10_warthog does not expose the engine and wing tags expected
    // by this dormant function. Its stock calls only emit runtime errors and
    // placeholder effects, so leave the physical aircraft clean.
}

startA10CannonSweep( duration )
{
    self endon( "gone" );
    self endon( "death" );
    self endon( "stopShooting" );

    spawnPoints = level.spawnpoints;
    referenceSpawn = spawnPoints[0];
    lineStart = vectornormalize( self.origin - self.attackpoint ) * level.a10startpositionscalar;
    lineStart = self.attackpoint + ( lineStart[0], lineStart[1], 0 );
    lineEnd = vectornormalize( self.origin - self.attackpoint ) * ( -1 * level.a10startpositionscalar );
    lineEnd = self.attackpoint + ( lineEnd[0], lineEnd[1], 0 );
    lineDirection = vectornormalize( lineEnd - lineStart );
    stepDistance = distance2d( lineStart, lineEnd ) / ( duration / 0.05 );
    self.a10shootingpos = ( lineStart[0], lineStart[1], referenceSpawn.origin[2] - 128 );
    step = lineDirection * stepDistance;

    self thread maps\mp\killstreaks\_a10::manageshootinggroundsound();
    self thread maps\mp\killstreaks\_a10::a10earthquake();

    while ( duration > 0 )
    {
        foreach ( player in level.players )
        {
            if ( !isdefined( player ) || !isalive( player ) )
                continue;

            if ( level.teambased && player.team == self.owner.team )
                continue;

            nearestPoint = pointonsegmentnearesttopoint(
                self.origin,
                self.a10shootingpos,
                player.origin
            );

            if (
                distancesquared( nearestPoint, player.origin ) <
                level.a10damageradius * level.a10damageradius
            )
            {
                // Attribute cannon kills to the streak owner rather than the
                // aircraft entity, which produced the suicide/death icon.
                self radiusdamage(
                    nearestPoint,
                    level.a10damageradius,
                    level.a10damage,
                    level.a10damage,
                    self.owner,
                    "MOD_RIFLE_BULLET",
                    "harrier_20mm_mp"
                );
            }
        }

        self.a10shootingpos += ( step[0], step[1], 0 );
        duration -= 0.05;
        wait 0.05;
    }
}

runA10Support( lifeId )
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    level.funModeA10SupportInProgress++;
    baseYaw = randomintrange( 0, 360 );

    for ( pass = 0; pass < 2; pass++ )
    {
        target = self getBestA10Target();

        if ( isdefined( target ) )
        {
            // Cross the second pass over the first instead of retracing the
            // same lane. This also gives players who survived the first run a
            // different direction of cover to consider.
            passYaw = baseYaw + pass * 120;
            plane = self launchA10Pass( lifeId, target.origin, passYaw );

            if ( isdefined( plane ) )
                plane thread fireA10FfarSalvo( self, lifeId );
        }

        if ( pass == 0 )
            wait 7.0;
    }

    // Keep another A-10 support streak from overlapping the final cannon run.
    wait 6.0;
    level.funModeA10SupportInProgress--;
}

launchA10Pass( lifeId, targetOrigin, yaw )
{
    previousPlane = undefined;

    if ( isdefined( self.a10 ) )
        previousPlane = self.a10;

    self maps\mp\killstreaks\_a10::calla10strike(
        lifeId,
        targetOrigin,
        yaw
    );

    // calla10strike starts the stock spawn routine on level, so allow it a
    // few frames to publish the new plane on its owner.
    for ( attempt = 0; attempt < 20; attempt++ )
    {
        if (
            isdefined( self.a10 ) &&
            ( !isdefined( previousPlane ) || self.a10 != previousPlane )
        )
        {
            return self.a10;
        }

        wait 0.05;
    }

    return undefined;
}

fireA10FfarSalvo( owner, lifeId )
{
    self endon( "death" );
    self endon( "gone" );
    level endon( "game_ended" );

    // Let the aircraft establish its attack run before releasing ordnance.
    wait 1.0;

    if ( !isdefined( owner ) )
        return;

    target = owner getBestA10Target();

    if ( !isdefined( target ) )
        return;

    for ( rocket = 0; rocket < 2; rocket++ )
    {
        if ( !isdefined( target ) || !isalive( target ) )
        {
            target = owner getBestA10Target();

            if ( !isdefined( target ) )
                return;
        }

        sideOffset = -110;

        if ( rocket == 1 )
            sideOffset = 110;

        // The dormant A-10 model has no wingtip tags. Build launch points
        // from the aircraft's position and orientation instead.
        launchOrigin = self.origin + anglestoright( self.angles ) * sideOffset;
        launchOrigin += ( 0.0, 0.0, -24.0 );
        impactOrigin = target.origin + (
            randomintrange( -96, 96 ),
            randomintrange( -96, 96 ),
            32
        );

        missile = magicbullet(
            "aamissile_projectile_mp",
            launchOrigin,
            impactOrigin,
            owner
        );

        if ( isdefined( missile ) )
        {
            missile.lifeid = lifeId;
            missile missile_settargetent( target );
            missile missile_setflightmodedirect();
            level thread playCasMissileImpactFx( target, impactOrigin );
        }

        wait 0.2;
    }
}

playCasMissileImpactFx( target, fallbackOrigin )
{
    level endon( "game_ended" );

    // aamissile_projectile_mp is lethal against ground targets but does not
    // render its normal air-to-air impact presentation there. Add only the
    // proven stock Precision Airstrike explosion effect; damage remains
    // entirely owned by the missile.
    wait 1.0;

    effectOrigin = fallbackOrigin;

    if ( isdefined( target ) )
        effectOrigin = target.origin;

    groundTrace = bullettrace(
        effectOrigin + ( 0.0, 0.0, 128.0 ),
        effectOrigin + ( 0.0, 0.0, -512.0 ),
        0,
        undefined
    );

    playfx( level.airstrikeexplosion, groundTrace["position"] );
}

getBestA10Target()
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

    bestTarget = enemies[randomint( enemies.size )];
    bestScore = -1;

    foreach ( candidate in enemies )
    {
        score = 0;

        foreach ( nearbyEnemy in enemies )
        {
            if ( distancesquared( candidate.origin, nearbyEnemy.origin ) <= 1000000 )
                score++;
        }

        if ( score > bestScore )
        {
            bestTarget = candidate;
            bestScore = score;
        }
    }

    return bestTarget;
}
