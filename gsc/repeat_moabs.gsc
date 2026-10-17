/*
    Repeat MOABs - IW5 / Plutonium

    Stock IW5 awards a MOAB only when the weapon-only streak is exactly 25,
    or 24 with Hardline. The counter continues increasing afterward, so the
    equality check cannot award another MOAB during the same life.

    Preserve the authoritative cumulative counter for HUD and statistics, then
    award additional MOABs at the same per-cycle cost. Hardline reduces every
    cycle to 24 qualifying kills: 24, 48, 72, and so on.
*/

main()
{
    setdvarifuninitialized( "fun_mode_repeat_moabs_enable", 1 );

    if ( !getdvarint( "fun_mode_repeat_moabs_enable" ) )
    {
        return;
    }

    level thread WatchRepeatMoabConnections();
}

WatchRepeatMoabConnections()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "connected", player );

        if ( IsDefined( player.pers["isBot"] ) && player.pers["isBot"] )
        {
            continue;
        }

        player thread WatchRepeatMoabMilestones();
    }
}

WatchRepeatMoabMilestones()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    previousStreak = 0;
    moabInterval = GetMoabInterval();
    nextMoabStreak = moabInterval * 2;

    for ( ;; )
    {
        currentStreak = 0;

        if ( IsDefined( self.pers["cur_kill_streak_for_nuke"] ) )
        {
            currentStreak = int( self.pers["cur_kill_streak_for_nuke"] );
        }

        // Death and team changes reset the stock counter. Recalculate the
        // first-life discount from the newly spawned loadout.
        if ( currentStreak == 0 || currentStreak < previousStreak )
        {
            moabInterval = GetMoabInterval();
            nextMoabStreak = moabInterval * 2;
        }

        while ( currentStreak >= nextMoabStreak )
        {
            self thread maps\mp\killstreaks\_killstreaks::givekillstreak(
                "nuke",
                0,
                1,
                self,
                1
            );
            self thread maps\mp\gametypes\_hud_message::killstreaksplashnotify(
                "nuke",
                nextMoabStreak
            );

            nextMoabStreak += moabInterval;
        }

        previousStreak = currentStreak;
        wait 0.05;
    }
}

GetMoabInterval()
{
    moabInterval = 25;

    if ( self maps\mp\_utility::_hasperk( "specialty_hardline" ) )
    {
        moabInterval--;
    }

    return moabInterval;
}
