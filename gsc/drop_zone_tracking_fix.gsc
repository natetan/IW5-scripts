/*
    Drop Zone Tracking Fix - IW5 / Plutonium

    Stock grndtracking assumes player team state, its HUD elements, and the
    current Drop Zone entity remain defined continuously. Team changes briefly
    invalidate those values while the original thread keeps running, causing
    a permanent 20 Hz runtime-error loop.

    Preserve the stock zone-entry/HUD behavior while waiting safely through
    transient team, HUD, and zone state.
*/

#include maps\mp\gametypes\grnd;

main()
{
    replacefunc(
        maps\mp\gametypes\grnd::grndtracking,
        ::guardedDropZoneTracking
    );

    replacefunc(
        maps\mp\gametypes\grnd::locationscoring,
        ::guardedDropZoneLocationStatus
    );

    // Plutonium r5354 exposes the same updater under this runtime symbol.
    replacefunc(
        maps\mp\gametypes\grnd::locationstatus,
        ::guardedDropZoneLocationStatus
    );
}

guardedDropZoneTracking()
{
    self endon( "disconnect" );
    self endon( "joined_team" );
    level endon( "game_ended" );
    self.funModeDropZoneHudValid = 1;
    self thread clearDropZoneStateOnTeamChange();

    for (;;)
    {
        team = undefined;

        if ( isdefined( self.team ) )
            team = self.team;
        else if ( isdefined( self.pers ) && isdefined( self.pers["team"] ) )
            team = self.pers["team"];

        if ( !isdefined( team ) )
        {
            wait 0.05;
            continue;
        }

        if ( !isdefined( self.grnd_wasspectator ) )
            self.grnd_wasspectator = team == "spectator";

        if ( !isdefined( self.ingrindzone ) )
            self.ingrindzone = 0;

        if ( !isdefined( self.ingrindzonepoints ) )
            self.ingrindzonepoints = 0;

        if ( team == "spectator" )
        {
            if ( !self.grnd_wasspectator )
            {
                self.ingrindzone = 0;
                self.ingrindzonepoints = 0;

                if ( isdefined( self.grndheadicon ) )
                    self.grndheadicon.alpha = 0;

                if ( isdefined( self._id_3A00 ) )
                    self._id_3A00.alpha = 0;

                self.grnd_wasspectator = 1;
            }

            wait 0.05;
            continue;
        }

        if (
            !isdefined( level.grnd_zone ) ||
            !isdefined( level.grnd_zone.origin )
        )
        {
            wait 0.05;
            continue;
        }

        distanceToZone = distance2d( level.grnd_zone.origin, self.origin );

        if ( ( self.grnd_wasspectator || !self.ingrindzone ) && distanceToZone < 300 )
        {
            self.ingrindzone = 1;
            self.ingrindzonepoints = 0;

            if ( isdefined( self._id_3A00 ) )
            {
                self._id_3A00 settext( &"OBJECTIVES_GRND_CONFIRM" );
                self._id_3A00.color = ( 0.6, 1.0, 0.6 );
                self._id_3A00.alpha = 1;
            }

            if ( isdefined( self.grndheadicon ) )
                self.grndheadicon.alpha = 0;
        }
        else if ( ( self.grnd_wasspectator || self.ingrindzone ) && distanceToZone >= 300 )
        {
            self.ingrindzone = 0;
            self.ingrindzonepoints = 0;

            if ( isdefined( self._id_3A00 ) )
            {
                self._id_3A00 settext( &"OBJECTIVES_GRND_HINT" );
                self._id_3A00.color = ( 1.0, 0.6, 0.6 );
                self._id_3A00.alpha = 1;
            }

            if ( isdefined( self.grndheadicon ) )
                self.grndheadicon.alpha = 0.85;
        }

        self.grnd_wasspectator = 0;
        wait 0.05;
    }
}

clearDropZoneStateOnTeamChange()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self waittill( "joined_team" );

    // Stock HUD destruction leaves dead entities stored in these fields.
    // Clear the references and force onspawnplayer() to rebuild everything.
    self.funModeDropZoneHudValid = undefined;
    self.grndheadicon = undefined;
    self._id_3A00 = undefined;
    self.grndobjid = undefined;
    self.grnd_wasspectator = undefined;
    self.ingrindzonepoints = undefined;
    self.ingrindzone = undefined;
}

guardedDropZoneLocationStatus()
{
    level endon( "game_ended" );
    maps\mp\_utility::gameflagwait( "prematch_done" );
    zoneTickScore = maps\mp\gametypes\_rank::getscoreinfovalue( "zone_tick" );

    for (;;)
    {
        teamCounts = [];
        teamCounts["axis"] = 0;
        teamCounts["allies"] = 0;

        if (
            isdefined( level.players ) &&
            isdefined( level.grnd_zone ) &&
            isdefined( level.grnd_zone.origin )
        )
        {
            foreach ( player in level.players )
            {
                if (
                    !isdefined( player ) ||
                    !isdefined( player.pers ) ||
                    !isdefined( player.pers["team"] ) ||
                    !isdefined( player.ingrindzone ) ||
                    !isdefined( player.ingrindzonepoints ) ||
                    !maps\mp\_utility::isreallyalive( player )
                )
                {
                    continue;
                }

                team = player.pers["team"];

                if ( team != "axis" && team != "allies" )
                    continue;

                if ( distance2d( level.grnd_zone.origin, player.origin ) < 300 )
                {
                    teamCounts[team]++;
                    player.ingrindzonepoints += zoneTickScore;
                }
            }

            if ( teamCounts["axis"] )
                maps\mp\gametypes\_gamescore::giveteamscoreforobjective( "axis", zoneTickScore * teamCounts["axis"] );

            if ( teamCounts["allies"] )
                maps\mp\gametypes\_gamescore::giveteamscoreforobjective( "allies", zoneTickScore * teamCounts["allies"] );

            foreach ( player in level.players )
            {
                if ( !canUpdateDropZoneHud( player ) )
                    continue;

                team = player.pers["team"];

                if ( teamCounts["axis"] == teamCounts["allies"] )
                {
                    player.grndheadicon setshader( "waypoint_captureneutral", 14, 14 );
                    player.grndheadicon setwaypoint( 0, 0, 0, 0 );
                    objective_icon( player.grndobjid, "waypoint_captureneutral" );
                }
                else if ( teamCounts[team] > teamCounts[level.otherteam[team]] )
                {
                    player.grndheadicon setshader( "waypoint_defend", 14, 14 );
                    player.grndheadicon setwaypoint( 0, 0, 0, 0 );
                    objective_icon( player.grndobjid, "waypoint_defend" );
                }
                else
                {
                    player.grndheadicon setshader( "waypoint_capture", 14, 14 );
                    player.grndheadicon setwaypoint( 0, 0, 0, 0 );
                    objective_icon( player.grndobjid, "waypoint_capture" );
                }
            }
        }

        maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause( 1.0 );
    }
}

canUpdateDropZoneHud( player )
{
    if ( !isdefined( player ) )
        return 0;

    if (
        !isdefined( player.funModeDropZoneHudValid ) ||
        !player.funModeDropZoneHudValid ||
        !isdefined( player.grndheadicon ) ||
        !isdefined( player.grndobjid ) ||
        !isdefined( player.pers ) ||
        !isdefined( player.pers["team"] )
    )
    {
        return 0;
    }

    team = player.pers["team"];
    return team == "axis" || team == "allies";
}
