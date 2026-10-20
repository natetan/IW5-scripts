/*
    MOAB Counter - IW5 / Plutonium

    Displays IW5's authoritative MOAB-eligible kill count near the bottom-right
    ammunition HUD. The stock damage callback increments
    pers["cur_kill_streak_for_nuke"] only for qualifying non-killstreak-weapon
    kills and resets it on death. This remains independent of Assault reward
    cycling and Support point persistence.

    Position and scale are sampled when the player connects:

        fun_mode_killstreak_counter_x
        fun_mode_killstreak_counter_y
        fun_mode_killstreak_counter_scale
*/

#include maps\mp\gametypes\_hud_util;

main()
{
    setdvarifuninitialized("fun_mode_killstreak_counter_enable", 1);
    setdvarifuninitialized("fun_mode_killstreak_counter_x", -92);
    setdvarifuninitialized("fun_mode_killstreak_counter_y", -82);
    setdvarifuninitialized("fun_mode_killstreak_counter_scale", 1.0);

    if (!getdvarint("fun_mode_killstreak_counter_enable"))
    {
        return;
    }

    level thread WatchKillstreakCounterConnections();
}

WatchKillstreakCounterConnections()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (
            IsDefined(player.pers["isBot"]) &&
            player.pers["isBot"]
        )
        {
            continue;
        }

        player thread TrackKillstreakCounter();
    }
}

TrackKillstreakCounter()
{
    self endon("disconnect");
    level endon("game_ended");

    counter = self createFontString(
        "Objective",
        getdvarfloat("fun_mode_killstreak_counter_scale")
    );
    counter setPoint(
        "BOTTOMRIGHT",
        "BOTTOMRIGHT",
        getdvarint("fun_mode_killstreak_counter_x"),
        getdvarint("fun_mode_killstreak_counter_y")
    );
    counter.label = &"^5MOAB STREAK: ^7";
    counter.sort = 1;
    counter.foreground = true;

    lastValue = -1;

    for (;;)
    {
        value = 0;

        if (IsDefined(self.pers["cur_kill_streak_for_nuke"]))
        {
            value = int(self.pers["cur_kill_streak_for_nuke"]);
        }

        if (value != lastValue)
        {
            counter setValue(value);
            lastValue = value;
        }

        wait 0.1;
    }
}
