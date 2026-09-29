/*
    EMP timer announcements - IW5 / Plutonium

    Uses the stock EMP and MOAB EMP countdowns as sources of truth. While
    either effect is active, announce its remaining duration every ten
    seconds, then every second from five through one. A newly activated effect
    naturally restarts its announcements when the corresponding timer resets.
*/

main()
{
    setdvarifuninitialized( "fun_mode_emp_timer_announcements_enable", 1 );
    setdvarifuninitialized( "fun_mode_moab_emp_timer_announcements_enable", 1 );

    if ( getdvarint( "fun_mode_emp_timer_announcements_enable" ) )
        level thread watchEmpTimerAnnouncements();

    if ( getdvarint( "fun_mode_moab_emp_timer_announcements_enable" ) )
        level thread watchMoabEmpTimerAnnouncements();
}

watchEmpTimerAnnouncements()
{
    level endon( "game_ended" );

    lastAnnouncedTime = -1;
    expirationAnnounced = false;
    wasActive = false;

    for ( ;; )
    {
        if ( !isEmpCurrentlyActive() )
        {
            if ( wasActive && !expirationAnnounced )
                announceEmpTimer( "EMP", "effects have expired." );

            lastAnnouncedTime = -1;
            expirationAnnounced = false;
            wasActive = false;
            wait 0.1;
            continue;
        }

        wasActive = true;
        remaining = level.emptimeremaining;

        if (
            remaining > 0 &&
            remaining != lastAnnouncedTime &&
            ( remaining % 10 == 0 || remaining <= 5 )
        )
        {
            announceEmpTimer( "EMP", remaining + " seconds remaining." );
            lastAnnouncedTime = remaining;
        }
        else if ( remaining <= 0 && !expirationAnnounced )
        {
            announceEmpTimer( "EMP", "effects have expired." );
            expirationAnnounced = true;
        }

        wait 0.1;
    }
}

watchMoabEmpTimerAnnouncements()
{
    level endon( "game_ended" );

    lastAnnouncedTime = -1;
    expirationAnnounced = false;
    wasActive = false;

    for ( ;; )
    {
        if ( !isMoabEmpCurrentlyActive() )
        {
            if ( wasActive && !expirationAnnounced )
                announceEmpTimer( "MOAB EMP", "effects have expired." );

            lastAnnouncedTime = -1;
            expirationAnnounced = false;
            wasActive = false;
            wait 0.1;
            continue;
        }

        wasActive = true;
        remaining = level.nukeemptimeremaining;

        if (
            remaining > 0 &&
            remaining != lastAnnouncedTime &&
            ( remaining % 10 == 0 || remaining <= 5 )
        )
        {
            announceEmpTimer( "MOAB EMP", remaining + " seconds remaining." );
            lastAnnouncedTime = remaining;
        }
        else if ( remaining <= 0 && !expirationAnnounced )
        {
            announceEmpTimer( "MOAB EMP", "effects have expired." );
            expirationAnnounced = true;
        }

        wait 0.1;
    }
}

announceEmpTimer( label, message )
{
    cmdexec( "say ^3[" + label + "]^7 " + message );
}

isEmpCurrentlyActive()
{
    if ( !isdefined( level.emptimeremaining ) )
        return false;

    if ( level.teambased )
    {
        if ( !isdefined( level.teamemped ) )
            return false;

        return (
            ( isdefined( level.teamemped["allies"] ) && level.teamemped["allies"] ) ||
            ( isdefined( level.teamemped["axis"] ) && level.teamemped["axis"] )
        );
    }

    return isdefined( level.empplayer );
}

isMoabEmpCurrentlyActive()
{
    if (
        !isdefined( level.nukeemptimeremaining ) ||
        !isdefined( level.teamnukeemped )
    )
    {
        return false;
    }

    return (
        ( isdefined( level.teamnukeemped["allies"] ) && level.teamnukeemped["allies"] ) ||
        ( isdefined( level.teamnukeemped["axis"] ) && level.teamnukeemped["axis"] )
    );
}
