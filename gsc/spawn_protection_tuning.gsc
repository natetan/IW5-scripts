/*
    Spawn Protection Tuning - IW5 / Plutonium

    IW5 normally discards enemy grenade and projectile damage for 3.5 seconds
    when the explosive is within 250 units of the victim's last spawn point.
    It separately reduces all explosive damage to 8% during the first 10
    seconds after the opening countdown. fun_mode.gsc compensates for that
    opening scalar through the existing player-damage callback so Blast Shield
    and Juggernaut resistance remain intact.
    Replace the stock spawn-finalization helper so the player-only protection
    timestamp can be shortened or removed without replacing the stock damage
    callback. The spawn point's real timestamp and weighting data remain
    unchanged.

    Duration is expressed in milliseconds and clamped to the stock range:

        fun_mode_explosive_spawn_protection_ms
        fun_mode_match_start_explosive_protection_enable

    Defaults:
        Per-spawn explosive protection: 0 ms (stock: 3500 ms)
        Match-start explosive protection: disabled (stock: enabled)
*/

#include maps\mp\gametypes\_spawnlogic;

main()
{
    setdvarifuninitialized( "fun_mode_explosive_spawn_protection_ms", 0 );
    setdvarifuninitialized(
        "fun_mode_match_start_explosive_protection_enable",
        0
    );

    replacefunc(
        maps\mp\gametypes\_spawnlogic::finalizespawnpointchoice,
        ::finalizespawnpointchoicewithtunedprotection
    );
}

finalizespawnpointchoicewithtunedprotection( spawnPoint )
{
    spawnTime = gettime();
    protectionMs = getdvarint( "fun_mode_explosive_spawn_protection_ms" );

    if ( protectionMs < 0 )
        protectionMs = 0;
    else if ( protectionMs > 3500 )
        protectionMs = 3500;

    self.lastspawnpoint = spawnPoint;
    self.lastspawntime = spawnTime - ( 3500 - protectionMs );

    // Preserve the real spawn time on the spawn-point entity because IW5's
    // spawn weighting uses it to avoid recently occupied locations.
    spawnPoint.lastspawnedplayer = self;
    spawnPoint.lastspawntime = spawnTime;
}
