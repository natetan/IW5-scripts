/*
    Reaper Tuning - IW5 / Plutonium

    Reduces the delay between guided Reaper missiles by 25 percent while
    preserving the stock ammunition, duration, health, flare, and counter
    behavior. Missile damage is tuned separately through Fun Mode's existing
    player-damage chain.

    Defaults:
        Missile interval: 2.25 seconds (stock: 3.0)
        Missile damage:   1.5x (configured in fun_mode.gsc)

    Set fun_mode_reaper_interval_tuning_enable to 0 before loading a map to
    retain the stock firing interval. The interval can also be adjusted with:

        fun_mode_reaper_missile_interval_ms
*/

#include maps\mp\killstreaks\_remotemortar;

main()
{
    setdvarifuninitialized( "fun_mode_reaper_interval_tuning_enable", 1 );
    setdvarifuninitialized( "fun_mode_reaper_missile_interval_ms", 2250 );

    if ( !getdvarint( "fun_mode_reaper_interval_tuning_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_remotemortar::remotefiring,
        ::fireReaperMissilesWithTunedInterval
    );
}

fireReaperMissilesWithTunedInterval( remote )
{
    level endon( "game_ended" );
    self endon( "disconnect" );
    remote endon( "remote_done" );
    remote endon( "death" );

    now = gettime();
    missileInterval = getdvarint( "fun_mode_reaper_missile_interval_ms" );
    // Preserve the stock relationship between the initial ready delay and
    // the recurring interval: 0.6 seconds here versus stock's 0.8 seconds.
    lastShotTime = now - int( missileInterval * 0.733333 );
    missilesRemaining = 14;
    self.firingreaper = 0;

    for (;;)
    {
        now = gettime();
        missileInterval = getdvarint( "fun_mode_reaper_missile_interval_ms" );

        if (
            self attackbuttonpressed() &&
            now - lastShotTime > missileInterval
        )
        {
            missilesRemaining--;
            self setclientdvar( "ui_reaper_ammoCount", missilesRemaining );
            lastShotTime = now;
            self.firingreaper = 1;
            self playlocalsound( "reaper_fire" );
            self playrumbleonentity( "damage_heavy" );

            eyeOrigin = self geteye();
            forward = anglestoforward( self getplayerangles() );
            right = anglestoright( self getplayerangles() );
            launchOrigin = eyeOrigin + forward * 100 + right * -100;
            missile = magicbullet(
                "remote_mortar_missile_mp",
                launchOrigin,
                remote.targetent.origin,
                self
            );

            earthquake( 0.3, 0.5, eyeOrigin, 256 );
            missile missile_settargetent( remote.targetent );
            missile missile_setflightmodedirect();
            missile thread maps\mp\killstreaks\_remotemortar::remotemissiledistance( remote );
            missile thread maps\mp\killstreaks\_remotemortar::remotemissilelife( remote );
            missile waittill( "death" );
            self setclientdvar( "ui_reaper_targetDistance", -1 );
            self.firingreaper = 0;

            if ( missilesRemaining == 0 )
                break;
        }
        else
            wait 0.05;
    }

    self notify( "removed_reaper_ammo" );
    self maps\mp\killstreaks\_remotemortar::remoteendride( remote );
    remote thread maps\mp\killstreaks\_remotemortar::remoteleave();
}
