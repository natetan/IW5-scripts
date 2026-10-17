/*
    Death Loop Chat Command - IW5 / Plutonium

    Human players can type !death to toggle an intentionally rapid suicide
    loop for statistics/testing cleanup. While enabled, that player is killed
    shortly after every valid spawn. Typing !death again disables the loop.
*/

main()
{
    setdvarifuninitialized( "fun_mode_death_loop_command_enable", 1 );

    if ( !getdvarint( "fun_mode_death_loop_command_enable" ) )
    {
        return;
    }

    level thread WatchDeathLoopCommands();
    level thread WatchDeathLoopConnections();
}

WatchDeathLoopCommands()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "say", message, player, isHidden );

        if ( message != "!death" || !IsEligibleDeathLoopPlayer( player ) )
        {
            continue;
        }

        if (
            IsDefined( player.funModeDeathLoopEnabled ) &&
            player.funModeDeathLoopEnabled
        )
        {
            player.funModeDeathLoopEnabled = false;
            player IPrintLnBold( "Death loop disabled" );
            continue;
        }

        player.funModeDeathLoopEnabled = true;
        player IPrintLnBold( "Death loop enabled" );
        player thread KillDeathLoopPlayerAfterSpawn();
    }
}

WatchDeathLoopConnections()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "connected", player );

        if ( IsEligibleDeathLoopPlayer( player ) )
        {
            player.funModeDeathLoopEnabled = false;
            player thread WatchDeathLoopSpawns();
        }
    }
}

WatchDeathLoopSpawns()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( "spawned_player" );

        if (
            IsDefined( self.funModeDeathLoopEnabled ) &&
            self.funModeDeathLoopEnabled
        )
        {
            self thread KillDeathLoopPlayerAfterSpawn();
        }
    }
}

KillDeathLoopPlayerAfterSpawn()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    if (
        IsDefined( self.funModeDeathLoopKillPending ) &&
        self.funModeDeathLoopKillPending
    )
    {
        return;
    }

    self.funModeDeathLoopKillPending = true;
    wait 0.1;
    self.funModeDeathLoopKillPending = false;

    if (
        !IsDefined( self.funModeDeathLoopEnabled ) ||
        !self.funModeDeathLoopEnabled ||
        !IsAlive( self ) ||
        !IsDefined( self.sessionstate ) ||
        self.sessionstate != "playing"
    )
    {
        return;
    }

    self suicide();
}

IsEligibleDeathLoopPlayer( player )
{
    if ( !IsDefined( player ) || !IsPlayer( player ) )
    {
        return false;
    }

    if ( IsDefined( player.pers["isBot"] ) && player.pers["isBot"] )
    {
        return false;
    }

    return true;
}
