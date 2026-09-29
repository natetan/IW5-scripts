/*
    AC-130 Reload Tuning - IW5 / Plutonium

    Reduces downtime for all three AC-130 cannons while preserving their
    damage, the streak duration, flares, and vulnerability to AA.

    Defaults:
        105 mm: 2.5 seconds (stock: 5.0)
         40 mm: 1.5 seconds (stock: 3.0)
         25 mm: 0.5 seconds (stock: 1.5)

    Set fun_mode_ac130_reload_tuning_enable to 0 before loading a map to use
    all stock reload times. The tuned values can also be adjusted with:

        fun_mode_ac130_105mm_reload_seconds
        fun_mode_ac130_40mm_reload_seconds
        fun_mode_ac130_25mm_reload_seconds
*/

#include maps\mp\killstreaks\_ac130;

main()
{
    setdvarifuninitialized( "fun_mode_ac130_reload_tuning_enable", 1 );
    setdvarifuninitialized( "fun_mode_ac130_105mm_reload_seconds", 2.5 );
    setdvarifuninitialized( "fun_mode_ac130_40mm_reload_seconds", 1.5 );
    setdvarifuninitialized( "fun_mode_ac130_25mm_reload_seconds", 0.5 );

    if ( !getdvarint( "fun_mode_ac130_reload_tuning_enable" ) )
        return;

    // Hook the reload itself instead of changing level.weaponreloadtime.
    // That prevents the stock AC-130 initializer from restoring its defaults
    // if it happens to run after this standalone script's main function.
    replacefunc(
        maps\mp\killstreaks\_ac130::weaponreload,
        ::reloadAc130WeaponWithTunedDelay
    );
}

reloadAc130WeaponWithTunedDelay( weapon )
{
    self endon( "ac130player_removed" );

    reloadTime = level.weaponreloadtime[weapon];

    if ( weapon == "ac130_105mm_mp" )
        reloadTime = getdvarfloat( "fun_mode_ac130_105mm_reload_seconds" );
    else if ( weapon == "ac130_40mm_mp" )
        reloadTime = getdvarfloat( "fun_mode_ac130_40mm_reload_seconds" );
    else if ( weapon == "ac130_25mm_mp" )
        reloadTime = getdvarfloat( "fun_mode_ac130_25mm_reload_seconds" );

    wait reloadTime;
    self setweaponammoclip( weapon, 9999 );

    switch ( weapon )
    {
        case "ac130_105mm_mp":
            self setplayerdata(
                "ac130Ammo105mm",
                self getweaponammoclip( weapon )
            );
            break;

        case "ac130_40mm_mp":
            self setplayerdata(
                "ac130Ammo40mm",
                self getweaponammoclip( weapon )
            );
            break;

        case "ac130_25mm_mp":
            self setplayerdata(
                "ac130Ammo25mm",
                self getweaponammoclip( weapon )
            );
            thread maps\mp\killstreaks\_ac130::shotfireddarkscreenoverlay();
            break;
    }
}
