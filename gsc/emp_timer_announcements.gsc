/*
    EMP timer announcements - IW5 / Plutonium

    Uses the stock EMP and MOAB EMP countdowns as sources of truth. When both
    effects overlap, only the longer effective duration is announced. Report
    that duration every ten seconds, then every second from five through one.
*/

main()
{
    setdvarifuninitialized( "fun_mode_emp_timer_announcements_enable", 1 );
    setdvarifuninitialized( "fun_mode_moab_emp_timer_announcements_enable", 1 );

    if (
        getdvarint( "fun_mode_emp_timer_announcements_enable" ) ||
        getdvarint( "fun_mode_moab_emp_timer_announcements_enable" )
    )
    {
        level thread watchEffectiveEmpTimerAnnouncements();
    }
}

watchEffectiveEmpTimerAnnouncements()
{
    level endon( "game_ended" );

    lastAnnouncedTime = -1;
    lastAnnouncedLabel = "";
    lastActiveLabel = "EMP";
    wasActive = false;

    for ( ;; )
    {
        state = getEffectiveEmpTimerState();

        if ( !state["active"] )
        {
            if ( wasActive )
                announceEmpTimer( lastActiveLabel, "effects have expired." );

            lastAnnouncedTime = -1;
            lastAnnouncedLabel = "";
            wasActive = false;
            wait 0.1;
            continue;
        }

        wasActive = true;
        remaining = state["remaining"];
        label = state["label"];
        lastActiveLabel = label;

        if (
            remaining > 0 &&
            (
                remaining != lastAnnouncedTime ||
                label != lastAnnouncedLabel
            ) &&
            ( remaining % 10 == 0 || remaining <= 5 )
        )
        {
            announceEmpTimer( label, remaining + " seconds remaining." );
            lastAnnouncedTime = remaining;
            lastAnnouncedLabel = label;
        }

        wait 0.1;
    }
}

getEffectiveEmpTimerState()
{
    state = [];
    state["active"] = false;
    state["remaining"] = 0;
    state["label"] = "EMP";

    if (
        getdvarint( "fun_mode_emp_timer_announcements_enable" ) &&
        isEmpCurrentlyActive()
    )
    {
        state["active"] = true;
        state["remaining"] = level.emptimeremaining;
    }

    if (
        getdvarint( "fun_mode_moab_emp_timer_announcements_enable" ) &&
        isMoabEmpCurrentlyActive() &&
        (
            !state["active"] ||
            level.nukeemptimeremaining >= state["remaining"]
        )
    )
    {
        state["active"] = true;
        state["remaining"] = level.nukeemptimeremaining;
        state["label"] = "MOAB EMP";
    }

    return state;
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
