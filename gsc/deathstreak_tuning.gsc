/*
    Deathstreak Tuning - IW5 / Plutonium

    Extends Juiced from seven to ten seconds while preserving its stock
    1.25x movement boost, timer HUD, two-second HUD fade, and early cleanup on
    death, faux spawn, disconnect, or remote-streak use.

    Adjust the duration before loading a map with:

        fun_mode_juiced_duration
*/

#include maps\mp\perks\_perkfunctions;

main()
{
    setdvarifuninitialized( "fun_mode_juiced_duration", 10.0 );

    replacefunc(
        maps\mp\perks\_perkfunctions::setjuiced,
        ::setjuicedextended
    );
}

setjuicedextended()
{
    self endon( "death" );
    self endon( "faux_spawn" );
    self endon( "disconnect" );
    self endon( "unset_juiced" );
    level endon( "end_game" );

    duration = getdvarfloat( "fun_mode_juiced_duration" );

    if ( duration < 2.0 )
        duration = 2.0;

    self.isjuiced = 1;
    self.movespeedscaler = 1.25;
    self maps\mp\gametypes\_weapons::updatemovespeedscale();

    if ( level.splitscreen )
    {
        timerY = 56;
        iconSize = 21;
    }
    else
    {
        timerY = 80;
        iconSize = 32;
    }

    self.juicedtimer = maps\mp\gametypes\_hud_util::createtimer( "hudsmall", 1.0 );
    self.juicedtimer maps\mp\gametypes\_hud_util::setpoint( "CENTER", "CENTER", 0, timerY );
    self.juicedtimer settimer( duration );
    self.juicedtimer.color = ( 0.8, 0.8, 0.0 );
    self.juicedtimer.archived = 0;
    self.juicedtimer.foreground = 1;

    self.juicedicon = maps\mp\gametypes\_hud_util::createicon(
        "specialty_juiced",
        iconSize,
        iconSize
    );
    self.juicedicon.alpha = 0;
    self.juicedicon maps\mp\gametypes\_hud_util::setparent( self.juicedtimer );
    self.juicedicon maps\mp\gametypes\_hud_util::setpoint( "BOTTOM", "TOP" );
    self.juicedicon.archived = 1;
    self.juicedicon.sort = 1;
    self.juicedicon.foreground = 1;
    self.juicedicon fadeovertime( 1.0 );
    self.juicedicon.alpha = 0.85;

    self thread maps\mp\perks\_perkfunctions::unsetjuicedondeath();
    self thread maps\mp\perks\_perkfunctions::unsetjuicedonride();

    wait( duration - 2.0 );

    if ( isdefined( self.juicedicon ) )
    {
        self.juicedicon fadeovertime( 2.0 );
        self.juicedicon.alpha = 0.0;
    }

    if ( isdefined( self.juicedtimer ) )
    {
        self.juicedtimer fadeovertime( 2.0 );
        self.juicedtimer.alpha = 0.0;
    }

    wait 2.0;
    self maps\mp\perks\_perkfunctions::unsetjuiced();
}
