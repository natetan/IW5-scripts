/*
    Direct-deploy hybrid Sentry - IW5 / Plutonium

    Replaces the five-kill Sentry airdrop wrapper with the stock carried-Sentry
    placement flow. The placed turret retains its normal minigun, health,
    lifetime, pickup, EMP, and destruction behavior, while occasionally firing
    one grenade at the same target it is already tracking.

    Tuning:
        fun_mode_direct_sentry_deployment_enable
        fun_mode_sentry_grenade_secondary_enable
        fun_mode_sentry_grenade_interval_seconds
        fun_mode_sentry_grenade_min_range
*/

#include maps\mp\killstreaks\_airdrop;
#include maps\mp\killstreaks\_autosentry;

main()
{
    setdvarifuninitialized( "fun_mode_direct_sentry_deployment_enable", 1 );
    setdvarifuninitialized( "fun_mode_sentry_grenade_secondary_enable", 1 );
    setdvarifuninitialized( "fun_mode_sentry_grenade_interval_seconds", 8 );
    setdvarifuninitialized( "fun_mode_sentry_grenade_min_range", 512 );

    directDeploymentEnabled =
        getdvarint( "fun_mode_direct_sentry_deployment_enable" );
    grenadeSecondaryEnabled =
        getdvarint( "fun_mode_sentry_grenade_secondary_enable" );

    if ( !directDeploymentEnabled && !grenadeSecondaryEnabled )
        return;

    if ( directDeploymentEnabled )
    {
        replacefunc(
            maps\mp\killstreaks\_airdrop::tryuseairdropsentryminigun,
            ::tryUseDirectSentry
        );
    }

    if ( grenadeSecondaryEnabled )
    {
        // The dormant player-controlled GL turret weapon supplies a shipped
        // grenade projectile and killfeed asset without changing the Sentry's
        // actual minigun weapon.
        precacheitem( "manned_gl_turret_mp" );
        level.killstreakweildweapons["manned_gl_turret_mp"] = 1;
        level.killstreakchainingweapons["manned_gl_turret_mp"] =
            "airdrop_sentry_minigun";

        replacefunc(
            maps\mp\killstreaks\_autosentry::sentry_burstfirestart,
            ::sentryBurstFireStartWithGrenades
        );
    }
}

tryUseDirectSentry( lifeId, awardId )
{
    // givesentry() owns normal streak validation and the complete carried
    // placement/cancellation flow. Returning zero preserves the reward if the
    // player cancels or a Sentry cannot be created.
    if ( !self maps\mp\killstreaks\_autosentry::givesentry( "sentry_minigun" ) )
        return 0;

    self maps\mp\_matchdata::logkillstreakevent(
        "airdrop_sentry_minigun",
        self.origin
    );
    return 1;
}

sentryBurstFireStartWithGrenades()
{
    self endon( "death" );
    self endon( "stop_shooting" );
    level endon( "game_ended" );

    self maps\mp\killstreaks\_autosentry::sentry_spinup();
    fireTime = weaponfiretime(
        level.sentrysettings[self.sentrytype].weaponinfo
    );
    minShots = level.sentrysettings[self.sentrytype].burstmin;
    maxShots = level.sentrysettings[self.sentrytype].burstmax;
    minPause = level.sentrysettings[self.sentrytype].pausemin;
    maxPause = level.sentrysettings[self.sentrytype].pausemax;

    for (;;)
    {
        shotCount = randomintrange( minShots, maxShots + 1 );

        for ( shot = 0; shot < shotCount && !self.overheated; shot++ )
        {
            self shootturret();
            self.heatlevel += fireTime;
            wait fireTime;
        }

        if (
            self.sentrytype == "minigun_turret" &&
            !isdefined( self.funModeSupportGuardian ) &&
            getdvarint( "fun_mode_sentry_grenade_secondary_enable" )
        )
        {
            self tryFireSentryGrenade();
        }

        wait randomfloatrange( minPause, maxPause );
    }
}

tryFireSentryGrenade()
{
    now = gettime();

    if (
        isdefined( self.funModeLastGrenadeTime ) &&
        now - self.funModeLastGrenadeTime <
            getSentryGrenadeIntervalMilliseconds()
    )
    {
        return;
    }

    target = self getturrettarget( 1 );

    if (
        !isdefined( target ) ||
        !isplayer( target ) ||
        !maps\mp\_utility::isreallyalive( target ) ||
        !isdefined( self.owner )
    )
    {
        return;
    }

    muzzle = self gettagorigin( "tag_flash" );
    targetPosition = target gettagorigin( "j_spineupper" );

    if ( !isdefined( muzzle ) || !isdefined( targetPosition ) )
        return;

    minimumRange = getdvarfloat( "fun_mode_sentry_grenade_min_range" );

    if ( minimumRange < 0 )
        minimumRange = 0;

    if ( distancesquared( muzzle, targetPosition ) < minimumRange * minimumRange )
        return;

    if ( !bullettracepassed( muzzle, targetPosition, false, self ) )
        return;

    grenade = magicbullet(
        "manned_gl_turret_mp",
        muzzle,
        targetPosition,
        self.owner
    );

    if ( !isdefined( grenade ) )
        return;

    self.funModeLastGrenadeTime = now;
    self playsound( "weap_m203_fire_npc" );
}

getSentryGrenadeIntervalMilliseconds()
{
    interval = getdvarfloat( "fun_mode_sentry_grenade_interval_seconds" );

    if ( interval < 1 )
        interval = 1;

    return int( interval * 1000 );
}
