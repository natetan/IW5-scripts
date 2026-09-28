/*
    Attack Helicopter Rockets - IW5 / Plutonium

    The stock seven-kill Attack Helicopter already has an FFAR secondary
    weapon, but its secondary targeting is restricted to hostile Harriers.
    Preserve that anti-air behavior and use the current cannon target as a
    fallback, allowing the helicopter to employ its native rockets against
    players when the shot is safe and lined up.

    Ground rockets have no ammunition limit. Their firing cone, minimum range,
    target visibility, and cooldown keep the helicopter counterable.

    Set fun_mode_attack_heli_rockets_enable to 0 before loading a map to retain
    the stock air-to-air-only secondary behavior.
*/

#include maps\mp\killstreaks\_helicopter;

main()
{
    setdvarifuninitialized( "fun_mode_attack_heli_rockets_enable", 1 );

    if ( !getdvarint( "fun_mode_attack_heli_rockets_enable" ) )
        return;

    replacefunc(
        maps\mp\killstreaks\_helicopter::attack_secondary,
        ::attackHelicopterSecondary
    );
}

attackHelicopterSecondary()
{
    self endon( "death" );
    self endon( "helicopter_done" );
    self endon( "crashing" );
    self endon( "leaving" );

    for (;;)
    {
        target = undefined;
        cooldown = 9.0;

        // Preserve the stock secondary weapon's priority: hostile Harriers
        // are still engaged before ground targets.
        if ( isdefined( self.secondarytarget ) && isalive( self.secondarytarget ) )
        {
            target = self.secondarytarget;
            cooldown = level.heli_missile_rof;
        }
        else if ( isdefined( self.primarytarget ) && isalive( self.primarytarget ) )
        {
            target = self.primarytarget;

            // FFARs launch forward and are unreliable/dangerous at point-blank
            // range. This mirrors the unused stock firemissile safety check.
            if ( distance2d( self.origin, target.origin ) < 512 )
                target = undefined;
        }

        if (
            isdefined( target ) &&
            self vehicle_canturrettargetpoint(
                target.origin + ( 0.0, 0.0, 40.0 ),
                1,
                self
            ) &&
            self maps\mp\killstreaks\_helicopter::missile_target_sight_check( target )
        )
        {
            self fireAttackHelicopterRocket( target );

            wait cooldown;
            continue;
        }

        wait 0.25;
    }
}

fireAttackHelicopterRocket( target )
{
    if ( !isdefined( target ) )
        return;

    // The dormant stock fire_missile helper calls weaponfiretime() on
    // harrier_FFAR_mp. IW5 exposes that asset as a vehicle/turret weapon, so
    // the timing builtin rejects it. A single rocket needs no inter-shot
    // timing calculation; perform the helper's launch steps directly.
    self setvehweapon( "harrier_FFAR_mp" );
    missile = self fireweapon( "tag_store_r_2", target );

    if ( !isdefined( missile ) )
        return;

    missile missile_setflightmodedirect();
    missile missile_settargetent( target );
}
