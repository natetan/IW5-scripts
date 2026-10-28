/*
    Ballistic Vest Pulse - IW5 / Plutonium

    Replaces the repeatedly deployed Ballistic Vest bag with an immediate
    team-armor pulse centered on the user. Every living teammate in range,
    including the user, receives armor through IW5's light_armor callback.
    Its stock grant monitor is narrowly replaced so the armor target follows
    the game mode's base health instead of assuming a fixed 200 HP.

    Defaults:
        Radius: 1,200 units
        Armored health: 2x the game mode's base health

    Set fun_mode_ballistic_vest_pulse_enable to 0 before loading a map to
    restore the stock deployable bag. Radius is independently tunable with:

        fun_mode_ballistic_vest_pulse_radius
        fun_mode_ballistic_vest_health_multiplier
*/

#include maps\mp\killstreaks\_deployablebox;
#include maps\mp\perks\_perkfunctions;

main()
{
    setdvarifuninitialized( "fun_mode_ballistic_vest_pulse_enable", 1 );
    setdvarifuninitialized( "fun_mode_ballistic_vest_pulse_radius", 1200 );
    setdvarifuninitialized( "fun_mode_ballistic_vest_health_multiplier", 2.0 );

    if ( !getdvarint( "fun_mode_ballistic_vest_pulse_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_deployablebox::tryusedeployablevest,
        ::useBallisticVestPulse
    );
    replacefunc(
        maps\mp\perks\_perkfunctions::givelightarmor,
        ::giveScaledLightArmor
    );
}

useBallisticVestPulse( lifeId )
{
    if ( !maps\mp\_utility::validateusestreak() )
        return 0;

    if (
        !isdefined( level.killstreakfuncs ) ||
        !isdefined( level.killstreakfuncs["light_armor"] )
    )
    {
        return 0;
    }

    radius = getdvarfloat( "fun_mode_ballistic_vest_pulse_radius" );

    if ( radius < 1 )
        radius = 1;

    radiusSquared = radius * radius;
    armoredCount = 0;

    foreach ( player in level.players )
    {
        if ( !self canReceiveBallisticVestPulse( player, radiusSquared ) )
            continue;

        player [[ level.killstreakfuncs["light_armor"] ]]();
        player playlocalsound( "ammo_crate_use" );
        player iprintlnbold( "Received Ballistic Vest" );
        armoredCount++;

        // Match the stock bag's reward for each teammate who takes a vest.
        if ( player != self )
        {
            self thread maps\mp\gametypes\_rank::xpeventpopup( &"MP_DEPLOYED_VEST" );
            self thread maps\mp\gametypes\_rank::giverankxp( "support", 50 );
        }
    }

    maps\mp\_matchdata::logkillstreakevent( "deployable_vest", self.origin );
    thread maps\mp\_utility::teamplayercardsplash( "used_deployable_vest", self );
    self iprintlnbold( "Ballistic vest pulse equipped " + armoredCount + " players." );
    return 1;
}

getBallisticVestBaseHealth()
{
    if (
        isdefined( self.fun_mode_quick_fix_base_health ) &&
        self.fun_mode_quick_fix_base_health > 0
    )
    {
        return self.fun_mode_quick_fix_base_health;
    }

    if (
        isdefined( self.previousmaxhealth ) &&
        self.previousmaxhealth > 0 &&
        isdefined( self.haslightarmor ) &&
        self.haslightarmor
    )
    {
        return self.previousmaxhealth;
    }

    if ( isdefined( self.maxHealth ) && self.maxHealth > 0 )
        return self.maxHealth;

    return 100;
}

giveScaledLightArmor()
{
    self notify( "give_light_armor" );
    self endon( "give_light_armor" );
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "end_game" );

    baseHealth = self getBallisticVestBaseHealth();

    if (
        isdefined( self.haslightarmor ) &&
        self.haslightarmor == 1
    )
    {
        self maps\mp\perks\_perkfunctions::removelightarmor(
            self.previousmaxhealth
        );
    }

    multiplier = getdvarfloat( "fun_mode_ballistic_vest_health_multiplier" );

    if ( multiplier < 1 )
        multiplier = 1;

    armoredHealth = int( baseHealth * multiplier );

    if ( armoredHealth < baseHealth )
        armoredHealth = baseHealth;

    self thread maps\mp\perks\_perkfunctions::removelightarmorondeath();
    self.haslightarmor = 1;
    self.combathighoverlay = newclienthudelem( self );
    self.combathighoverlay.x = 0;
    self.combathighoverlay.y = 0;
    self.combathighoverlay.alignx = "left";
    self.combathighoverlay.aligny = "top";
    self.combathighoverlay.horzalign = "fullscreen";
    self.combathighoverlay.vertalign = "fullscreen";
    self.combathighoverlay setshader( "combathigh_overlay", 640, 480 );
    self.combathighoverlay.sort = -10;
    self.combathighoverlay.archived = 1;
    self.previousmaxhealth = baseHealth;
    self.maxHealth = armoredHealth;
    self.health = armoredHealth;
    self.fun_mode_quick_fix_overhealth_ceiling = undefined;

    // Preserve the stock vest's 50-damage armor-state duration while using
    // proportional health targets and restoration thresholds.
    armorDamageRemaining = 50;
    previousHealth = self.health;

    for (;;)
    {
        if ( self.maxHealth != armoredHealth )
        {
            self maps\mp\perks\_perkfunctions::removelightarmor();
            break;
        }

        if ( self.health < baseHealth )
        {
            self maps\mp\perks\_perkfunctions::removelightarmor( baseHealth );
            break;
        }

        if ( self.health < previousHealth )
        {
            armorDamageRemaining -= previousHealth - self.health;
            previousHealth = self.health;

            if ( armorDamageRemaining <= 0 )
            {
                self maps\mp\perks\_perkfunctions::removelightarmor( baseHealth );
                break;
            }
        }

        wait 0.5;
    }
}

canReceiveBallisticVestPulse( player, radiusSquared )
{
    if ( !isdefined( player ) || !isplayer( player ) || !isalive( player ) )
        return 0;

    if (
        !isdefined( player.sessionstate ) ||
        player.sessionstate != "playing" ||
        !isdefined( player.team ) ||
        player.team == "spectator"
    )
    {
        return 0;
    }

    if ( level.teambased && player.team != self.team )
        return 0;

    if ( !level.teambased && player != self )
        return 0;

    if ( distancesquared( self.origin, player.origin ) > radiusSquared )
        return 0;

    return 1;
}
