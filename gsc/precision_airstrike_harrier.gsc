/*
    Precision Airstrike -> Harrier Strike - IW5 / Plutonium

    IW5 ships a complete dormant Harrier path inside the stock airstrike
    script. Keep the normal Precision Airstrike unlock, cost, icon, and
    selection controls, but send its location selection through that Harrier
    implementation instead.

    Set fun_mode_harrier_airstrike_enable to 0 before loading a map to restore
    the stock Precision Airstrike without uninstalling this script.
*/

#include maps\mp\killstreaks\_airstrike;

main()
{
    setdvarifuninitialized( "fun_mode_harrier_airstrike_enable", 1 );

    // The dormant stock Harrier path incorrectly uses level.planes both as an
    // array of plane entities and as a numeric Harrier counter. Keep our count
    // separate so the stock plane list remains an array.
    level.funModeHarrierCount = 0;
    level.funModeLastEmpPlayer = undefined;

    level thread watchEmpUsers();

    replacefunc(
        maps\mp\killstreaks\_airstrike::tryuseprecisionairstrike,
        ::tryuseprecisionairstrikeasHarrier
    );
}

watchEmpUsers()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread rememberEmpUsage();
    }
}

rememberEmpUsage()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        self waittill( "used_emp" );
        level.funModeLastEmpPlayer = self;
    }
}

tryuseprecisionairstrikeasHarrier( lifeId )
{
    if ( !getdvarint( "fun_mode_harrier_airstrike_enable" ) )
    {
        return self maps\mp\killstreaks\_airstrike::tryuseairstrike(
            lifeId,
            "precision_airstrike"
        );
    }

    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    if ( isdefined( level.civilianjetflyby ) )
    {
        self iprintlnbold( &"MP_CIVILIAN_AIR_TRAFFIC" );
        return 0;
    }

    if ( maps\mp\_utility::isusingremote() )
        return 0;

    if ( level.funModeHarrierCount > 0 )
    {
        self iprintlnbold( &"MP_AIR_SPACE_TOO_CROWDED" );
        return 0;
    }

    return self selectHarrierLocation( lifeId );
}

selectHarrierLocation( lifeId )
{
    selectorScale = level.mapsize / 6.46875;

    if ( level.splitscreen )
        selectorScale *= 1.5;

    // Use the precision-airstrike selector so direction selection and its
    // familiar VO still work, then launch the Harrier implementation.
    self playlocalsound( game["voice"][self.team] + "KS_hqr_airstrike" );
    maps\mp\_utility::_beginlocationselection(
        "precision_airstrike",
        "map_artillery_selector",
        1,
        selectorScale
    );

    self endon( "stop_location_selection" );
    self waittill( "confirm_location", strikeOrigin, strikeYaw );
    self setblurforplayer( 0, 0.3 );

    maps\mp\_matchdata::logkillstreakevent( "precision_airstrike", strikeOrigin );
    self thread finishHarrierUsage( lifeId, strikeOrigin, strikeYaw );
    return 1;
}

finishHarrierUsage( lifeId, strikeOrigin, strikeYaw )
{
    self notify( "used" );

    groundTrace = bullettrace(
        level.mapcenter + ( 0.0, 0.0, 1000000.0 ),
        level.mapcenter,
        0,
        undefined
    );

    strikeOrigin = (
        strikeOrigin[0],
        strikeOrigin[1],
        groundTrace["position"][2] - 514
    );

    thread runHarrierStrike(
        lifeId,
        strikeOrigin,
        strikeYaw,
        self,
        self.pers["team"]
    );
}

runHarrierStrike( lifeId, strikeOrigin, strikeYaw, owner, team )
{
    level.funModeHarrierCount++;

    if ( isdefined( level.airstrikeinprogress ) )
    {
        while ( isdefined( level.airstrikeinprogress ) )
            level waittill( "begin_airstrike" );

        level.airstrikeinprogress = 1;
        wait 2.0;
    }

    if ( !isdefined( owner ) )
    {
        level.funModeHarrierCount--;
        return;
    }

    level.airstrikeinprogress = 1;

    ground = bullettrace(
        strikeOrigin,
        strikeOrigin + ( 0.0, 0.0, -1000000.0 ),
        0,
        undefined
    );
    targetOrigin = ground["position"];

    danger = spawnstruct();
    danger.origin = targetOrigin;
    danger.forward = anglestoforward( ( 0, strikeYaw, 0 ) );
    danger.streakname = "harrier_airstrike";
    level.artillerydangercenters[level.artillerydangercenters.size] = danger;

    harrier = maps\mp\killstreaks\_airstrike::callstrike(
        lifeId,
        owner,
        targetOrigin,
        strikeYaw,
        "harrier_airstrike"
    );

    if ( isdefined( harrier ) )
        harrier thread destroyHarrierOnEmp( owner, team );

    wait 1.0;
    level.airstrikeinprogress = undefined;
    owner notify( "begin_airstrike" );
    level notify( "begin_airstrike" );

    wait 7.5;
    removeHarrierDangerCenter( targetOrigin );

    while ( isdefined( harrier ) )
        wait 0.1;

    level.funModeHarrierCount--;
}

destroyHarrierOnEmp( owner, harrierTeam )
{
    self endon( "death" );

    for (;;)
    {
        empAttacker = getHarrierEmpAttacker( owner, harrierTeam );

        if ( isdefined( empAttacker ) )
        {
            /*
                A script notify named "damage" does not invoke the engine's
                vehicle-damage callback. Call the Harrier's registered native
                callback directly with lethal EMP damage instead. The callback
                halves this otherwise-unrecognized weapon damage, so 7000
                becomes 3500 against the 3000-health aircraft while retaining
                its normal destruction feedback and reward path.
            */
            self [[ self.damagecallback ]](
                self,
                empAttacker,
                7000,
                self.origin,
                ( 0.0, 0.0, 0.0 ),
                "killstreak_emp_mp",
                "MOD_EXPLOSIVE",
                0,
                "none",
                0,
                0,
                0
            );
            return;
        }

        // Poll authoritative state so event ordering cannot strand the watcher
        // if an EMP update fires just before this thread reaches its wait.
        wait 0.1;
    }
}

getHarrierEmpAttacker( owner, harrierTeam )
{
    // The stock MOAB sets its authoritative team EMP flag immediately before
    // nuke_emp_update. Checking the owner entity alone is timing-sensitive and
    // can miss the aircraft when its owner dies in the blast.
    if (
        isdefined( harrierTeam ) &&
        isdefined( level.teamnukeemped ) &&
        isdefined( level.teamnukeemped[harrierTeam] ) &&
        level.teamnukeemped[harrierTeam] &&
        isdefined( level.nukeinfo ) &&
        isdefined( level.nukeinfo.player )
    )
    {
        return level.nukeinfo.player;
    }

    if (
        isdefined( harrierTeam ) &&
        isdefined( level.teamemped ) &&
        isdefined( level.teamemped[harrierTeam] ) &&
        level.teamemped[harrierTeam] &&
        isdefined( level.funModeLastEmpPlayer )
    )
    {
        return level.funModeLastEmpPlayer;
    }

    // Retain the entity checks as fallbacks for FFA or custom recipes that do
    // not populate the stock team arrays in the usual order.
    if (
        isdefined( owner ) &&
        owner maps\mp\_utility::isnuked() &&
        isdefined( level.nukeinfo ) &&
        isdefined( level.nukeinfo.player )
    )
    {
        return level.nukeinfo.player;
    }

    if (
        isdefined( owner ) &&
        owner maps\mp\_utility::isemped() &&
        isdefined( level.funModeLastEmpPlayer )
    )
    {
        return level.funModeLastEmpPlayer;
    }

    return undefined;
}

removeHarrierDangerCenter( targetOrigin )
{
    found = 0;
    remaining = [];

    for ( i = 0; i < level.artillerydangercenters.size; i++ )
    {
        if ( !found && level.artillerydangercenters[i].origin == targetOrigin )
        {
            found = 1;
            continue;
        }

        remaining[remaining.size] = level.artillerydangercenters[i];
    }

    level.artillerydangercenters = remaining;
}
