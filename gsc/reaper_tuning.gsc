/*
    Automated Reaper - IW5 / Plutonium

    Converts the nine-kill Reaper into autonomous air support on every map.
    Stock validation, aircraft spawning, health, flare, anti-air counters,
    destruction credit, timeout, and cleanup remain owned by _remotemortar.

    The aircraft selects living enemies it can see from the air, respects
    Blind Eye, and fires the stock Reaper missile without taking control away
    from its owner.

    Defaults:
        Missiles:         14 (stock)
        Missile interval: 2.25 seconds (stock manual cooldown: 3.0)
        Missile damage:   1.5x (configured in fun_mode.gsc)
*/

#include maps\mp\killstreaks\_remotemortar;

main()
{
    setdvarifuninitialized( "fun_mode_automated_reaper_enable", 1 );
    setdvarifuninitialized( "fun_mode_reaper_missile_interval_ms", 2250 );
    setdvarifuninitialized( "fun_mode_reaper_missile_count", 14 );

    if ( !getdvarint( "fun_mode_automated_reaper_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_remotemortar::tryuseremotemortar,
        ::tryUseAutomatedReaper
    );
}

tryUseAutomatedReaper( lifeId )
{
    if ( isdefined( level.remote_mortar ) )
    {
        self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
        return 0;
    }

    if ( !self maps\mp\_utility::validateusestreak() )
        return 0;

    self maps\mp\_matchdata::logkillstreakevent(
        "remote_mortar",
        self.origin
    );
    return startAutomatedReaper( lifeId );
}

startAutomatedReaper( lifeId )
{
    remote = maps\mp\killstreaks\_remotemortar::spawnremote( lifeId, self );

    if ( !isdefined( remote ) )
        return 0;

    level.remote_mortar = remote;
    self.firingreaper = 0;
    self thread restoreWeaponAfterAutomatedReaperActivation();
    self thread maps\mp\_utility::teamplayercardsplash(
        "used_remote_mortar",
        self
    );
    remote thread runAutomatedReaper( self, lifeId );
    return 1;
}

restoreWeaponAfterAutomatedReaperActivation()
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

runAutomatedReaper( owner, lifeId )
{
    level endon( "game_ended" );
    self endon( "death" );
    self endon( "remote_done" );

    if ( !isdefined( owner ) )
        return;

    owner endon( "disconnect" );
    missilesRemaining = getdvarint( "fun_mode_reaper_missile_count" );

    if ( missilesRemaining < 1 )
        missilesRemaining = 1;
    else if ( missilesRemaining > 20 )
        missilesRemaining = 20;

    // Give the aircraft time to enter its orbit before the first shot.
    wait 1.0;

    while ( missilesRemaining > 0 )
    {
        target = getAutomatedReaperTarget( owner );

        if ( !isdefined( target ) )
        {
            wait 0.25;
            continue;
        }

        targetOrigin = target gettagorigin( "j_spineupper" );
        launchOrigin = self.origin + ( 0, 0, -24 );
        missile = magicbullet(
            "remote_mortar_missile_mp",
            launchOrigin,
            targetOrigin,
            owner
        );

        if ( isdefined( missile ) )
        {
            missile.lifeid = lifeId;
            missile missile_settargetent( target );
            missile missile_setflightmodedirect();
            missile thread maps\mp\killstreaks\_remotemortar::remotemissilelife(
                self
            );
            missilesRemaining--;
        }

        intervalMilliseconds = getdvarint(
            "fun_mode_reaper_missile_interval_ms"
        );

        if ( intervalMilliseconds < 500 )
            intervalMilliseconds = 500;

        wait( intervalMilliseconds / 1000.0 );
    }

    if ( isdefined( owner ) )
        owner notify( "removed_reaper_ammo" );

    self thread maps\mp\killstreaks\_remotemortar::remoteleave();
}

getAutomatedReaperTarget( owner )
{
    candidates = [];

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

        if ( !bullettracepassed( self.origin, targetOrigin, false, self ) )
            continue;

        candidates[candidates.size] = player;
    }

    if ( !candidates.size )
        return undefined;

    return candidates[randomint( candidates.size )];
}
