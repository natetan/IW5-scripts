/*
    Reaper -> Bradley Artillery - IW5 / Plutonium

    Replaces the nine-kill player-controlled Reaper with IW5's dormant Mobile
    Mortar Bradley. The player chooses one of three authored entrance lanes;
    the Bradley then attacks autonomously with top-down missiles.

    The dormant implementation is polished for normal multiplayer:
        Duration:         30 seconds (stock dormant value: 90)
        Salvo size:       3 missiles
        Salvo interval:   5 seconds
        Missile spacing:  0.35 seconds
        Missile damage:   2x (configured in fun_mode.gsc)

    Missing dormant objective shaders are replaced with shipped airstrike
    icons, missing Bradley muzzle/dust effects are omitted, and the selection
    device is explicitly holstered after a valid choice.

    Maps without authored Bradley entrances automatically retain the stock
    player-controlled Reaper. Set fun_mode_bradley_artillery_enable to 0 before
    loading a map to retain it everywhere.
*/

#include maps\mp\killstreaks\_mobilemortar;
#include common_scripts\_destructible;

main()
{
    setdvarifuninitialized( "fun_mode_bradley_artillery_enable", 1 );
    setdvarifuninitialized( "fun_mode_bradley_duration_seconds", 30 );
    setdvarifuninitialized( "fun_mode_bradley_salvo_size", 3 );
    setdvarifuninitialized( "fun_mode_bradley_salvo_interval_seconds", 5 );
    setdvarifuninitialized( "fun_mode_bradley_salvo_spacing_seconds", 0.35 );
    setdvarifuninitialized( "fun_mode_bradley_salvo_spread", 160 );

    if ( !getdvarint( "fun_mode_bradley_artillery_enable" ) )
        return;

    precacheshader( "compass_objpoint_airstrike_friendly" );
    precacheshader( "compass_objpoint_airstrike_busy" );
    precachemodel( "vehicle_ugv_talon_mp" );
    precachemodel( "vehicle_ugv_talon_gun_mp" );

    replacefunc(
        maps\mp\killstreaks\_mobilemortar::selectentrancelocation,
        ::selectBradleyEntrance
    );
    replacefunc(
        maps\mp\killstreaks\_mobilemortar::showicons,
        ::showBradleyEntranceIcons
    );
    replacefunc(
        maps\mp\killstreaks\_mobilemortar::movetoposition,
        ::moveBradleyToPosition
    );
    replacefunc(
        maps\mp\killstreaks\_mobilemortar::mortarattack,
        ::runBradleyArtillery
    );
    replacefunc(
        maps\mp\killstreaks\_mobilemortar::watchtimeout,
        ::watchBradleyTimeout
    );
    replacefunc(
        maps\mp\killstreaks\_mobilemortar::watchdeath,
        ::watchBradleyDeath
    );
    replacefunc(
        common_scripts\_destructible::hideapart,
        ::hideDestructiblePartWithBradleyGuard
    );

    // Populate the shipped entrance coordinates and precache the vehicle.
    maps\mp\killstreaks\_mobilemortar::init();

    // The dormant script references FX which are not present in the shipped
    // MP zone and render as the large red FX placeholder. Redirect every one
    // of those handles to known-good Assault Drone effects as a safety net,
    // even though the tuned firing path intentionally omits them.
    level.tankfire = loadfx( "explosions/killstreak_explosion_quick" );
    level.tankexplode = loadfx( "explosions/bouncing_betty_explosion" );
    level.tankflash = loadfx( "impacts/large_metal_painted_hit" );
    level.tankdust1 = loadfx( "impacts/large_metal_painted_hit" );
    level.tankdust2 = loadfx( "impacts/large_metal_painted_hit" );

    level thread installBradleyCallback();
}

hideDestructiblePartWithBradleyGuard( partName )
{
    // Carbon contains a multipart destructible state whose requested part is
    // absent from the active model. Bradley salvos reach that otherwise-rare
    // state repeatedly, and stock hideapart() forwards it to hidepart()
    // without validation. IW5 exposes no model-part predicate, so suppress
    // only those transitions while this streak is active on Carbon.
    if (
        isdefined( level.script ) &&
        level.script == "mp_carbon" &&
        isdefined( level.mobilemortar )
    )
    {
        return;
    }

    self hidepart( partName );
}

installBradleyCallback()
{
    level endon( "game_ended" );

    while (
        !isdefined( level.killstreakfuncs ) ||
        !isdefined( level.killstreakfuncs["remote_mortar"] )
    )
    {
        wait 0.05;
    }

    // Retain the callback installed by _remotemortar::init so unsupported
    // maps can still use the player-controlled Reaper instead of holding an
    // unusable nine-kill reward.
    level.funModeStockReaperCallback = level.killstreakfuncs["remote_mortar"];
    level.killstreakfuncs["remote_mortar"] = ::tryUseBradleyArtillery;
}

tryUseBradleyArtillery( lifeId )
{
    if ( !isdefined( level.ground_support_locs[level.script] ) )
    {
        if ( isdefined( level.funModeStockReaperCallback ) )
            return self [[ level.funModeStockReaperCallback ]]( lifeId );

        return 0;
    }

    if (
        isdefined( self.laststand ) &&
        !self maps\mp\_utility::_hasperk( "specialty_finalstand" )
    )
    {
        self iprintlnbold( &"MP_UNAVILABLE_IN_LASTSTAND" );
        return 0;
    }

    if ( isdefined( level.mobilemortar ) )
    {
        self iprintlnbold( &"MP_GROUND_APPROACHES_TOO_CROWDED" );
        return 0;
    }

    if ( self maps\mp\_utility::isusingremote() )
        return 0;

    entranceIndex = undefined;

    // Bot Warfare confirms arbitrary map positions for Reaper. Pick a valid
    // authored Bradley lane directly so bots cannot become stuck in the
    // three-lane selector.
    isBot = isdefined( self.pers["isBot"] ) && self.pers["isBot"];

    if ( isBot )
        entranceIndex = randomint( 3 );
    else
        entranceIndex = self maps\mp\killstreaks\_mobilemortar::selectentrancelocation();

    if ( !isdefined( entranceIndex ) )
        return 0;

    if ( !isBot )
        self maps\mp\_utility::stoplocationselection( 0 );

    bradley = maps\mp\killstreaks\_mobilemortar::createmobilemortar(
        self,
        entranceIndex
    );

    if ( !isdefined( bradley ) )
        return 0;

    // vehicle_bradley is referenced by the dormant script but absent from the
    // shipped MP zone. Its missing-model proxy is the damaging red FX object
    // seen in-world. Assemble the real UGV chassis and turret models while
    // preserving the Bradley entity's movement, health, and targeting logic.
    bradley setmodel( "vehicle_ugv_talon_mp" );
    bradley.helitype = "helicopter";
    bradley.heli_type = "helicopter";
    bradley.presentationTurret = spawn( "script_model", bradley.origin );

    if ( isdefined( bradley.presentationTurret ) )
    {
        bradley.presentationTurret setmodel( "vehicle_ugv_talon_gun_mp" );
        bradley.presentationTurret linkto(
            bradley,
            "tag_turret_attach",
            ( 0, 0, 0 ),
            ( 0, 0, 0 )
        );
    }

    // The dormant compass shaders are absent from the shipped MP assets.
    if ( isdefined( bradley.objidfriendly ) )
        objective_icon( bradley.objidfriendly, "compass_objpoint_airstrike_friendly" );

    if ( isdefined( bradley.objidenemy ) )
        objective_icon( bradley.objidenemy, "compass_objpoint_airstrike_busy" );

    bradley thread maps\mp\killstreaks\_mobilemortar::movetoposition( "entrance" );
    self thread restoreWeaponAfterBradleySelection();
    return 1;
}

restoreWeaponAfterBradleySelection()
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

selectBradleyEntrance()
{
    selectedIndex = undefined;

    for (;;)
    {
        self thread maps\mp\killstreaks\_mobilemortar::showicons();
        self maps\mp\_utility::_beginlocationselection(
            "remote_mortar",
            "map_artillery_selector",
            0,
            500
        );
        self endon( "stop_location_selection" );
        self waittill( "confirm_location", selectedPosition );

        for ( index = 0; index < 3; index++ )
        {
            entrancePosition =
                level.ground_support_locs[level.script][index]["origin"] *
                ( 1, 1, 0 );

            if ( distancesquared( selectedPosition, entrancePosition ) < 60000 )
            {
                selectedIndex = index;
                break;
            }
        }

        if ( isdefined( selectedIndex ) )
        {
            for ( index = 0; index < 3; index++ )
            {
                if ( index == selectedIndex )
                {
                    objective_icon(
                        self.locationobjectives[index],
                        "compass_objpoint_airstrike_busy"
                    );
                }
                else
                    objective_state( self.locationobjectives[index], "invisible" );
            }
        }
        else
        {
            for ( index = 0; index < 3; index++ )
            {
                objective_icon(
                    self.locationobjectives[index],
                    "compass_objpoint_airstrike_friendly"
                );
            }
        }

        wait 0.5;
        self notify( "picked_location" );
        wait 0.05;

        if ( isdefined( selectedIndex ) )
            break;
    }

    return selectedIndex;
}

showBradleyEntranceIcons()
{
    prompt = maps\mp\gametypes\_hud_util::createfontstring( "bigfixed", 0.5 );
    prompt maps\mp\gametypes\_hud_util::setpoint( "CENTER", "CENTER", 0, -150 );
    prompt settext( &"MP_SELECT_MOBILE_MORTAR_LOCATION" );
    self.locationobjectives = [];

    for ( index = 0; index < 3; index++ )
    {
        self.locationobjectives[index] = maps\mp\gametypes\_gameobjects::getnextobjid();
        objective_add( self.locationobjectives[index], "invisible", ( 0, 0, 0 ) );
        objective_position(
            self.locationobjectives[index],
            level.ground_support_locs[level.script][index]["origin"]
        );
        objective_state( self.locationobjectives[index], "active" );
        objective_team( self.locationobjectives[index], self.team );
        objective_icon(
            self.locationobjectives[index],
            "compass_objpoint_airstrike_friendly"
        );
    }

    common_scripts\utility::waittill_any(
        "cancel_location",
        "picked_location",
        "stop_location_selection"
    );
    prompt maps\mp\gametypes\_hud_util::destroyelem();

    for ( index = 0; index < 3; index++ )
    {
        if ( isdefined( self.locationobjectives[index] ) )
            maps\mp\_utility::_objective_delete( self.locationobjectives[index] );
    }
}

moveBradleyToPosition( direction )
{
    level endon( "game_ended" );
    self endon( "death" );

    if ( direction == "entrance" )
        destination = self.origin + anglestoforward( self.angles ) * 1000;
    else
    {
        self notify( "leaving" );
        destination = self.origin + anglestoforward( self.angles ) * -1000;
    }

    travelTime = 3.0;
    self moveto( destination, travelTime, travelTime * 0.6, travelTime * 0.4 );
    wait( travelTime );

    if ( direction == "entrance" )
    {
        self thread maps\mp\killstreaks\_mobilemortar::mortarattack();
        return;
    }

    cleanupBradleyObjectives();

    if ( isdefined( self.presentationTurret ) )
        self.presentationTurret delete();

    level.mobilemortar = undefined;
    self delete();
}

runBradleyArtillery()
{
    level endon( "game_ended" );
    self endon( "death" );
    self endon( "leaving" );

    for (;;)
    {
        salvoStartTime = gettime();
        target = self maps\mp\killstreaks\_mobilemortar::findtarget();

        if ( !isdefined( target ) )
            target = self maps\mp\killstreaks\_mobilemortar::findrandomtarget();

        salvoSize = getdvarint( "fun_mode_bradley_salvo_size" );
        spacing = getdvarfloat( "fun_mode_bradley_salvo_spacing_seconds" );
        spread = getdvarfloat( "fun_mode_bradley_salvo_spread" );

        if ( salvoSize < 1 )
            salvoSize = 1;
        else if ( salvoSize > 6 )
            salvoSize = 6;

        if ( spacing < 0.05 )
            spacing = 0.05;

        if ( spread < 0 )
            spread = 0;

        for ( shot = 0; shot < salvoSize; shot++ )
        {
            strikeTarget = target;

            if ( shot > 0 && spread > 0 )
            {
                strikeTarget += (
                    randomfloatrange( spread * -1, spread ),
                    randomfloatrange( spread * -1, spread ),
                    0
                );
            }

            height = self.origin[2] + 3500;
            groundTrace = bullettrace(
                strikeTarget + ( 0, 0, height ),
                strikeTarget - ( 0, 0, height ),
                0
            );
            apex = strikeTarget + ( 0, 0, height );
            impact = strikeTarget + ( 0, 0, groundTrace["position"][2] );

            self playsound( "bmp_fire" );
            self thread maps\mp\killstreaks\_mobilemortar::mortarrecoil();
            level thread fireBradleyMissile( self, apex, impact );

            if ( shot < salvoSize - 1 )
                wait spacing;
        }

        salvoInterval = getdvarfloat( "fun_mode_bradley_salvo_interval_seconds" );

        if ( salvoInterval < 1 )
            salvoInterval = 1;

        elapsedSeconds = ( gettime() - salvoStartTime ) / 1000.0;
        remainingDelay = salvoInterval - elapsedSeconds;

        if ( remainingDelay < 0.05 )
            remainingDelay = 0.05;

        wait remainingDelay;
    }
}

fireBradleyMissile( bradley, apex, impact )
{
    level endon( "game_ended" );

    if ( !isdefined( bradley ) || !isdefined( bradley.owner ) )
        return;

    owner = bradley.owner;
    ascent = magicbullet(
        "javelin_mp",
        bradley.origin + ( 0, 0, 150 ),
        apex,
        owner
    );

    elapsed = 0;

    while (
        isdefined( ascent ) &&
        elapsed <= 115 &&
        distancesquared( ascent.origin, apex ) >= 500
    )
    {
        wait 0.05;
        elapsed++;
    }

    if ( isdefined( ascent ) )
        ascent delete();

    if ( !isdefined( bradley ) || !isdefined( owner ) )
        return;

    missile = magicbullet(
        "remote_mortar_missile_mp",
        apex + ( 0, 0, 200 ),
        impact,
        owner
    );
}

watchBradleyTimeout()
{
    level endon( "game_ended" );
    self endon( "death" );

    duration = getdvarfloat( "fun_mode_bradley_duration_seconds" );

    if ( duration < 5 )
        duration = 5;

    maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(
        duration
    );
    self setcandamage( 0 );
    self thread maps\mp\killstreaks\_mobilemortar::movetoposition( "exit" );
}

watchBradleyDeath()
{
    level endon( "game_ended" );
    self endon( "leaving" );
    self waittill( "death" );

    destroyedBradley = spawn( "script_model", self.origin );

    if ( isdefined( destroyedBradley ) )
    {
        destroyedBradley setmodel( "vehicle_ugv_talon_mp" );
        destroyedBradley.angles = self.angles;
    }

    cleanupBradleyObjectives();

    if ( isdefined( self.presentationTurret ) )
        self.presentationTurret delete();

    self delete();
    wait 3.5;

    if ( isdefined( destroyedBradley ) )
        destroyedBradley delete();

    level.mobilemortar = undefined;
}

cleanupBradleyObjectives()
{
    if ( isdefined( self.objidfriendly ) )
        maps\mp\_utility::_objective_delete( self.objidfriendly );

    if ( isdefined( self.objidenemy ) )
        maps\mp\_utility::_objective_delete( self.objidenemy );
}
