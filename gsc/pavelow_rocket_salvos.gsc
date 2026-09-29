/*
    Pave Low Rocket Salvos - IW5 / Plutonium

    Preserves the stock Pave Low's dual miniguns, health, flares, and flight
    behavior while adding a three-rocket ground-suppression salvo every ten
    seconds. Salvos favor visible enemy clusters and use fixed impact points
    rather than homing directly onto players.

    Set fun_mode_pavelow_rocket_salvos_enable to 0 before loading a map to
    retain the completely stock Pave Low.
*/

#include maps\mp\killstreaks\_helicopter;

main()
{
    setdvarifuninitialized( "fun_mode_pavelow_rocket_salvos_enable", 1 );

    if ( !getdvarint( "fun_mode_pavelow_rocket_salvos_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_helicopter::makegunship,
        ::makePavelowGunshipWithRocketSalvos
    );
}

makePavelowGunshipWithRocketSalvos()
{
    self endon( "death" );
    self endon( "helicopter_done" );
    wait 0.5;

    turret = spawnturret( "misc_turret", self.origin, "pavelow_minigun_mp" );
    turret.lifeId = self.lifeId;
    turret linkto( self, "tag_gunner_left", ( 0, 0, 0 ), ( 0, 0, 0 ) );
    turret setmodel( "weapon_minigun" );
    turret.owner = self.owner;
    turret.team = self.team;
    turret maketurretinoperable();
    turret.pers["team"] = self.team;
    turret.killCamEnt = self;
    self.mgTurretLeft = turret;
    self.mgTurretLeft setdefaultdroppitch( 0 );

    turret = spawnturret( "misc_turret", self.origin, "pavelow_minigun_mp" );
    turret.lifeId = self.lifeId;
    turret linkto( self, "tag_gunner_right", ( 0, 0, 0 ), ( 0, 0, 0 ) );
    turret setmodel( "weapon_minigun" );
    turret.owner = self.owner;
    turret.team = self.team;
    turret maketurretinoperable();
    turret.pers["team"] = self.team;
    turret.killCamEnt = self;
    self.mgTurretRight = turret;
    self.mgTurretRight setdefaultdroppitch( 0 );

    if ( level.teamBased )
    {
        self.mgTurretLeft setturretteam( self.team );
        self.mgTurretRight setturretteam( self.team );
    }

    self.mgTurretLeft setmode( "auto_nonai" );
    self.mgTurretRight setmode( "auto_nonai" );
    self.mgTurretLeft setsentryowner( self.owner );
    self.mgTurretRight setsentryowner( self.owner );
    self.mgTurretLeft setturretminimapvisible( 0 );
    self.mgTurretRight setturretminimapvisible( 0 );
    self.mgTurretLeft.chopper = self;
    self.mgTurretRight.chopper = self;
    self.mgTurretLeft thread maps\mp\killstreaks\_helicopter::sentry_attacktargets();
    self.mgTurretRight thread maps\mp\killstreaks\_helicopter::sentry_attacktargets();
    thread maps\mp\killstreaks\_helicopter::deleteturretswhendone();
    thread pavelowRocketSalvoController();
}

pavelowRocketSalvoController()
{
    self endon( "death" );
    self endon( "helicopter_done" );
    self endon( "crashing" );
    self endon( "leaving" );
    level endon( "game_ended" );

    // Let the aircraft enter the map and establish its orbit first.
    wait 4.0;

    for (;;)
    {
        if ( isdefined( self.empGrenaded ) && self.empGrenaded )
        {
            wait 0.25;
            continue;
        }

        target = self getBestPavelowSalvoTarget();

        if ( !isdefined( target ) )
        {
            wait 0.25;
            continue;
        }

        self firePavelowRocketSalvo( target );
        wait 10.0;
    }
}

getBestPavelowSalvoTarget()
{
    candidates = [];

    foreach ( player in level.players )
    {
        if ( !self canPavelowRocketTarget( player ) )
            continue;

        candidates[candidates.size] = player;
    }

    if ( !candidates.size )
        return undefined;

    bestTarget = candidates[randomint( candidates.size )];
    bestScore = -1;

    foreach ( candidate in candidates )
    {
        score = 0;

        foreach ( nearbyEnemy in candidates )
        {
            if ( distancesquared( candidate.origin, nearbyEnemy.origin ) <= 490000 )
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

canPavelowRocketTarget( player )
{
    if ( !isdefined( player ) || !isalive( player ) || player.sessionstate != "playing" )
        return 0;

    if ( player == self.owner || player.team == "spectator" )
        return 0;

    if ( level.teambased && player.team == self.team )
        return 0;

    if ( player maps\mp\_utility::_hasperk( "specialty_blindeye" ) )
        return 0;

    if ( isdefined( player.spawnTime ) && ( gettime() - player.spawnTime ) / 1000 <= 5 )
        return 0;

    if ( distance2d( self.origin, player.origin ) < 512 )
        return 0;

    if ( distance( self.origin, player.origin ) > level.heli_visual_range )
        return 0;

    targetOrigin = player.origin + ( 0, 0, 32 );

    if ( !bullettracepassed( self.origin, targetOrigin, 0, self ) )
        return 0;

    targetDirection = vectornormalize( targetOrigin - self.origin );
    forwardDirection = vectornormalize( anglestoforward( self.angles ) );

    if ( vectordot( targetDirection, forwardDirection ) < level.heli_missile_target_cone )
        return 0;

    return 1;
}

firePavelowRocketSalvo( target )
{
    if ( !isdefined( target ) )
        return;

    baseImpactOrigin = target.origin + ( 0, 0, 24 );

    for ( rocketIndex = 0; rocketIndex < 3; rocketIndex++ )
    {
        impactOrigin = baseImpactOrigin;

        if ( rocketIndex == 0 )
            impactOrigin += ( -120, -60, 0 );
        else if ( rocketIndex == 2 )
            impactOrigin += ( 120, 60, 0 );

        impactAnchor = spawn( "script_origin", impactOrigin );
        launchTag = "tag_gunner_left";

        if ( rocketIndex == 1 )
            launchTag = "tag_gunner_right";

        self setvehweapon( "harrier_FFAR_mp" );
        missile = self fireweapon( launchTag, impactAnchor );

        if ( isdefined( missile ) )
        {
            missile.lifeId = self.lifeId;
            missile missile_setflightmodedirect();
            missile missile_settargetent( impactAnchor );
            missile thread pavelowRocketImpactFx( impactAnchor );
        }
        else
            impactAnchor delete();

        wait 0.35;
    }
}

pavelowRocketImpactFx( impactAnchor )
{
    self endon( "disconnect" );
    self waittill( "death" );

    if ( !isdefined( impactAnchor ) )
        return;

    groundTrace = bullettrace(
        impactAnchor.origin + ( 0, 0, 128 ),
        impactAnchor.origin + ( 0, 0, -512 ),
        0,
        undefined
    );

    playfx( level.airstrikeexplosion, groundTrace["position"] );
    impactAnchor delete();
}
