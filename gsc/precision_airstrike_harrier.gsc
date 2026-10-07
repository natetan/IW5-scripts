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
        harrier thread destroyHarrierOnEmp( owner );

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

destroyHarrierOnEmp( owner )
{
    self endon( "death" );

    for (;;)
    {
        empAttacker = getHarrierEmpAttacker( owner );

        if ( isdefined( empAttacker ) )
        {
            /*
                The Harrier callback halves unrecognized weapon damage, so
                the stock EMP's 5000 damage leaves this 3000-health aircraft
                alive. Send 7000 through the native callback instead. Its
                halved 3500 damage remains lethal while preserving the normal
                hitmarker, 300 XP, player-card splash, mission progress, and
                destroyed_killstreak notification for the EMP/MOAB owner.
            */
            self notify(
                "damage",
                7000,
                empAttacker,
                ( 0.0, 0.0, 0.0 ),
                ( 0.0, 0.0, 0.0 ),
                "MOD_EXPLOSIVE",
                "",
                "",
                "",
                undefined,
                "killstreak_emp_mp"
            );
            return;
        }

        // Ordinary EMP and MOAB EMP maintain separate state and emit separate
        // update events. Wake for either so both effects destroy the Harrier.
        level common_scripts\utility::waittill_either(
            "emp_update",
            "nuke_emp_update"
        );
    }
}

getHarrierEmpAttacker( owner )
{
    if ( !isdefined( owner ) )
        return undefined;

    if (
        owner maps\mp\_utility::isnuked() &&
        isdefined( level.nukeinfo ) &&
        isdefined( level.nukeinfo.player )
    )
    {
        return level.nukeinfo.player;
    }

    if (
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
