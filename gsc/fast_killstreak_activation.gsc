/*
    Fast killstreak activation - IW5 / Plutonium

    Gives selected radio-called Assault and Support streaks fast marker-weapon
    draws instead of their stock killstreak-device animations. Their normal
    callbacks, validation, audio, reward consumption, and effects remain
    unchanged.

    Set any of the following to 0 before loading a map to retain that streak's
    stock animation:

        fun_mode_fast_uav_activation_enable
        fun_mode_fast_support_uav_activation_enable
        fun_mode_fast_counter_uav_activation_enable
        fun_mode_fast_emp_activation_enable
        fun_mode_fast_helicopter_activation_enable
        fun_mode_fast_ah6_activation_enable
        fun_mode_fast_pavelow_activation_enable
*/

#include maps\mp\killstreaks\_killstreaks;

main()
{
    setdvarifuninitialized( "fun_mode_fast_uav_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_support_uav_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_counter_uav_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_emp_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_helicopter_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_ah6_activation_enable", 1 );
    setdvarifuninitialized( "fun_mode_fast_pavelow_activation_enable", 1 );

    level.fastUavActivation = getdvarint( "fun_mode_fast_uav_activation_enable" );
    level.fastSupportUavActivation = getdvarint( "fun_mode_fast_support_uav_activation_enable" );
    level.fastCounterUavActivation = getdvarint( "fun_mode_fast_counter_uav_activation_enable" );
    level.fastEmpActivation = getdvarint( "fun_mode_fast_emp_activation_enable" );
    level.fastHelicopterActivation = getdvarint( "fun_mode_fast_helicopter_activation_enable" );
    level.fastAh6Activation = getdvarint( "fun_mode_fast_ah6_activation_enable" );
    level.fastPavelowActivation = getdvarint( "fun_mode_fast_pavelow_activation_enable" );

    if ( !level.fastUavActivation &&
         !level.fastSupportUavActivation &&
         !level.fastCounterUavActivation &&
         !level.fastEmpActivation &&
         !level.fastHelicopterActivation &&
         !level.fastAh6Activation &&
         !level.fastPavelowActivation )
        return;

    replacefunc(
        maps\mp\killstreaks\_killstreaks::getkillstreakweapon,
        ::getFastUavKillstreakWeapon
    );
}

getFastUavKillstreakWeapon( streakName )
{
    if ( streakName == "uav" && level.fastUavActivation )
    {
        // This unused airdrop marker has the quick pull-out/cancel behavior,
        // without colliding with the Care Package or Assault Drone markers.
        return "airdrop_mega_marker_mp";
    }

    // Support streaks receive distinct markers sourced from the Assault
    // package. They therefore cannot consume one another when several
    // Support rewards are being held at once.
    if ( streakName == "uav_support" && level.fastSupportUavActivation )
        return "airdrop_sentry_marker_mp";

    if ( streakName == "counter_uav" && level.fastCounterUavActivation )
        return "airdrop_tank_marker_mp";

    if ( streakName == "emp" && level.fastEmpActivation )
        return "airdrop_juggernaut_mp";

    // These Assault streaks use distinct Support-package markers. This keeps
    // Attack Helicopter, AH-6 Overwatch, and Pave Low separate when all three
    // rewards are held simultaneously.
    if ( streakName == "helicopter" && level.fastHelicopterActivation )
        return "airdrop_trap_marker_mp";

    if ( streakName == "littlebird_support" && level.fastAh6Activation )
        return "airdrop_juggernaut_def_mp";

    if ( streakName == "helicopter_flares" && level.fastPavelowActivation )
        return "airdrop_escort_marker_mp";

    return tablelookup( "mp/killstreakTable.csv", 1, streakName, 12 );
}
