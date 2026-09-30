/*
    Osprey Tuning - IW5 / Plutonium

    Shared behavior:
        Safely creates both the Support Escort Airdrop and Assault Osprey
        Gunner on maps that skip normal helicopter-attractor initialization.

    Support Osprey tuning only:
        Defensive radius: 1.25x (about 707 -> 884 units)
        Removes trapped crates from the Escort Airdrop reward pool
        Reduces UAV and Counter-UAV odds to about 3 percent each
        Shifts the remaining odds toward useful mid-tier support rewards

    The Assault Osprey Gunner receives no balance changes.
*/

#include maps\mp\killstreaks\_airdrop;
#include maps\mp\killstreaks\_escortairdrop;

main()
{
    setdvarifuninitialized( "fun_mode_support_osprey_tuning_enable", 1 );

    // This factory is shared by the Support and Assault Ospreys. Keep its
    // safety fix active independently of the optional Support balance tuning.
    replacefunc(
        maps\mp\killstreaks\_escortairdrop::createairship,
        ::createOspreyWithSafeAttractorDefaults
    );

    if ( getdvarint( "fun_mode_support_osprey_tuning_enable" ) )
    {
        replacefunc(
            maps\mp\killstreaks\_escortairdrop::killguysnearcrates,
            ::defendEscortAirdropCrates
        );

        replacefunc(
            maps\mp\killstreaks\_escortairdrop::aishootplayer,
            ::shootEscortAirdropTarget
        );

        level thread configureEscortAirdropRewards();
    }
}

createOspreyWithSafeAttractorDefaults( owner, lifeId, origin, angles, destination, ospreyType )
{
    osprey = spawnhelicopter(
        owner,
        origin,
        angles,
        level.ospreysettings[ ospreyType ].vehicle,
        level.ospreysettings[ ospreyType ].modelbase
    );

    if ( !isdefined( osprey ) )
        return undefined;

    osprey.ospreytype = ospreyType;
    osprey.heli_type = level.ospreysettings[ ospreyType ].modelbase;
    osprey.helitype = level.ospreysettings[ ospreyType ].helitype;

    // Some maps return from the stock helicopter initializer before these
    // globals are assigned. Resolve the stock values at the point of use so
    // missile_createattractorent never receives an undefined float.
    attractorStrength = 1000.0;
    attractorRange = 4096.0;

    if ( isdefined( level.heli_attract_strength ) )
        attractorStrength = level.heli_attract_strength;

    if ( isdefined( level.heli_attract_range ) )
        attractorRange = level.heli_attract_range;

    osprey.attractor = missile_createattractorent(
        osprey,
        attractorStrength,
        attractorRange
    );
    osprey.lifeid = lifeId;
    osprey.team = owner.pers[ "team" ];
    osprey.pers[ "team" ] = owner.pers[ "team" ];
    osprey.owner = owner;
    osprey.maxhealth = level.ospreysettings[ ospreyType ].maxhealth;
    osprey.zoffset = ( 0.0, 0.0, 0.0 );
    osprey.targeting_delay = level.heli_targeting_delay;
    osprey.primarytarget = undefined;
    osprey.secondarytarget = undefined;
    osprey.attacker = undefined;
    osprey.currentstate = "ok";
    osprey.droptype = level.ospreysettings[ ospreyType ].droptype;
    level.chopper = osprey;
    osprey maps\mp\killstreaks\_helicopter::addtohelilist();
    osprey thread maps\mp\killstreaks\_helicopter::heli_flares_monitor();
    osprey thread maps\mp\killstreaks\_helicopter::heli_leave_on_disconnect( owner );
    osprey thread maps\mp\killstreaks\_helicopter::heli_leave_on_changeteams( owner );
    osprey thread maps\mp\killstreaks\_helicopter::heli_leave_on_gameended( owner );
    osprey thread maps\mp\killstreaks\_helicopter::heli_leave_on_timeout(
        level.ospreysettings[ ospreyType ].timeout
    );
    osprey thread maps\mp\killstreaks\_helicopter::heli_damage_monitor();
    osprey thread maps\mp\killstreaks\_helicopter::heli_health();
    osprey thread maps\mp\killstreaks\_helicopter::heli_existance();
    osprey thread maps\mp\killstreaks\_escortairdrop::airshipfx();

    if ( ospreyType == "escort_airdrop" )
    {
        killcamOrigin = osprey.origin +
            ( anglestoforward( osprey.angles ) * -200 + anglestoright( osprey.angles ) * -200 ) +
            ( 0.0, 0.0, 200.0 );
        osprey.killcament = spawn( "script_model", killcamOrigin );
        osprey.killcament setscriptmoverkillcam( "explosive" );
        osprey.killcament linkto( osprey, "tag_origin" );
    }

    return osprey;
}

configureEscortAirdropRewards()
{
    level endon( "game_ended" );

    while (
        !isdefined( level.cratetypes ) ||
        !isdefined( level.cratetypes[ "airdrop_escort" ] ) ||
        !isdefined( level.cratemaxval )
    )
    {
        wait 0.05;
    }

    /*
        The stock airdrop initializer converts individual weights into
        cumulative thresholds. Preserve its original key order and replace
        those thresholds with this 60-point distribution:

          UAV 2, Counter-UAV 2, Vest 6, Sentry 8, IMS 8, SAM 6,
          Stealth Bomber 8, Recon Juggernaut 5, Recon Drone 5,
          Advanced UAV 5, Remote Turret 3, EMP 2.
    */
    level.cratetypes[ "airdrop_escort" ][ "airdrop_trap" ] = 0;
    level.cratetypes[ "airdrop_escort" ][ "uav" ] = 2;
    level.cratetypes[ "airdrop_escort" ][ "counter_uav" ] = 4;
    level.cratetypes[ "airdrop_escort" ][ "deployable_vest" ] = 10;
    level.cratetypes[ "airdrop_escort" ][ "sentry" ] = 18;
    level.cratetypes[ "airdrop_escort" ][ "ims" ] = 26;
    level.cratetypes[ "airdrop_escort" ][ "sam_turret" ] = 32;
    level.cratetypes[ "airdrop_escort" ][ "stealth_airstrike" ] = 40;
    level.cratetypes[ "airdrop_escort" ][ "airdrop_juggernaut_recon" ] = 45;
    level.cratetypes[ "airdrop_escort" ][ "remote_uav" ] = 50;
    level.cratetypes[ "airdrop_escort" ][ "triple_uav" ] = 55;
    level.cratetypes[ "airdrop_escort" ][ "remote_mg_turret" ] = 58;
    level.cratetypes[ "airdrop_escort" ][ "emp" ] = 60;
    level.cratemaxval[ "airdrop_escort" ] = 60;
}

defendEscortAirdropCrates( dropOrigin )
{
    self endon( "osprey_leaving" );
    self endon( "helicopter_removed" );
    self endon( "death" );

    // Stock uses 500000 (about 707 units). A 1.25x radius requires the
    // squared-distance threshold to be multiplied by 1.25 squared.
    defenseRadiusSquared = 781250;

    for (;;)
    {
        foreach ( player in level.players )
        {
            wait 0.05;

            if ( !isdefined( self ) )
                return;

            if ( !isdefined( player ) )
                continue;

            if ( !maps\mp\_utility::isreallyalive( player ) )
                continue;

            if ( level.teambased && player.team == self.team )
                continue;

            if ( isdefined( self.owner ) && player == self.owner )
                continue;

            if ( player maps\mp\_utility::_hasperk( "specialty_blindeye" ) )
                continue;

            if ( distancesquared( dropOrigin, player.origin ) > defenseRadiusSquared )
                continue;

            thread shootEscortAirdropTarget( player, dropOrigin );
            maps\mp\killstreaks\_escortairdrop::waitforconfirmation();
        }
    }
}

shootEscortAirdropTarget( player, dropOrigin )
{
    self notify( "aiShootPlayer" );
    self endon( "aiShootPlayer" );
    self endon( "helicopter_removed" );
    self endon( "leaving" );
    player endon( "death" );

    defenseRadiusSquared = 781250;
    self setturrettargetent( player );
    self setlookatent( player );
    thread maps\mp\killstreaks\_escortairdrop::targetdeathwaiter( player );
    burstShotsRemaining = 6;
    burstsRemaining = 2;

    for (;;)
    {
        burstShotsRemaining--;
        self fireweapon( "tag_flash", player );
        wait 0.15;

        if ( burstShotsRemaining <= 0 )
        {
            burstsRemaining--;
            burstShotsRemaining = 6;

            if (
                distancesquared( player.origin, dropOrigin ) > defenseRadiusSquared ||
                burstsRemaining <= 0 ||
                !maps\mp\_utility::isreallyalive( player )
            )
            {
                self notify( "abandon_target" );
                return;
            }

            wait 1;
        }
    }
}
