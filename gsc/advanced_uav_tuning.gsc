/*
    Advanced UAV Tuning - IW5 / Plutonium

    Gives the actual twelve-point Advanced UAV reward two small advantages
    over a naturally stacked strength-three radar:

      - Extends its base active duration from 30 to 40 seconds.
      - Reveals Assassin users globally as ordinary radar dots while retaining
        their protection from directional arrows.

    Only the shipped triple_uav Phantom Ray has a UAV value of three. Three
    separately launched Assault/Support UAVs remain completely stock.
*/

#include maps\mp\killstreaks\_uav;

main()
{
    setdvarifuninitialized( "fun_mode_advanced_uav_tuning_enable", 1 );
    setdvarifuninitialized( "fun_mode_advanced_uav_duration_seconds", 40 );
    setdvarifuninitialized( "fun_mode_advanced_uav_reveal_assassin", 1 );

    if ( !getdvarint( "fun_mode_advanced_uav_tuning_enable" ) )
        return;

    level thread advancedUavTuningController();
}

advancedUavTuningController()
{
    level endon( "game_ended" );

    for (;;)
    {
        extendNewAdvancedUavsForTeam( "allies" );
        extendNewAdvancedUavsForTeam( "axis" );

        if (
            isdefined( level.teambased ) &&
            level.teambased &&
            getdvarint( "fun_mode_advanced_uav_reveal_assassin" )
        )
            updateAdvancedUavAssassinReveals();

        wait 0.25;
    }
}

extendNewAdvancedUavsForTeam( team )
{
    if (
        !isdefined( level.uavmodels ) ||
        !isdefined( level.uavmodels[team] )
    )
        return;

    foreach ( uav in level.uavmodels[team] )
    {
        if ( !isActualAdvancedUav( uav ) )
            continue;

        if ( isdefined( uav.funModeAdvancedUavDurationExtended ) )
            continue;

        uav.funModeAdvancedUavDurationExtended = 1;
        desiredDuration = getdvarfloat( "fun_mode_advanced_uav_duration_seconds" );
        extension = desiredDuration - level.radarviewtime;

        if ( extension > 0 )
            uav.timetoadd += extension;
    }
}

isActualAdvancedUav( uav )
{
    return (
        isdefined( uav ) &&
        isdefined( uav.value ) &&
        uav.value == 3 &&
        isdefined( uav.uavtype ) &&
        uav.uavtype == "standard"
    );
}

teamHasActualAdvancedUav( team )
{
    if (
        !isdefined( level.uavmodels ) ||
        !isdefined( level.uavmodels[team] )
    )
        return 0;

    foreach ( uav in level.uavmodels[team] )
    {
        if ( isActualAdvancedUav( uav ) )
            return 1;
    }

    return 0;
}

updateAdvancedUavAssassinReveals()
{
    if ( !isdefined( level.players ) )
        return;

    alliesAdvancedUavActive = teamHasActualAdvancedUav( "allies" );
    axisAdvancedUavActive = teamHasActualAdvancedUav( "axis" );

    foreach ( player in level.players )
    {
        if ( !isdefined( player ) || player.team == "spectator" )
            continue;

        shouldReveal = 0;

        if ( player maps\mp\_utility::_hasperk( "specialty_coldblooded" ) )
        {
            if ( player.team == "allies" && axisAdvancedUavActive )
                shouldReveal = 1;
            else if ( player.team == "axis" && alliesAdvancedUavActive )
                shouldReveal = 1;
        }

        if ( shouldReveal )
        {
            player.funModeAdvancedUavRevealed = 1;

            if ( !player maps\mp\_utility::_hasperk( "specialty_radarblip" ) )
                player setperk( "specialty_radarblip", 1, 0 );

            continue;
        }

        if ( !isdefined( player.funModeAdvancedUavRevealed ) )
            continue;

        player.funModeAdvancedUavRevealed = undefined;

        // Recon Pulse may still own the same forced radar-blip perk.
        if ( !isdefined( player.uavremotemarkedby ) )
            player unsetperk( "specialty_radarblip", 1 );
    }
}
