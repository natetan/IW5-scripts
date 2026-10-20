/*
    Player Stats HUD - IW5 / Plutonium

    Adapted from Resxt's display_player_stats.gsc:
    https://github.com/Resxt/Plutonium-IW5-Scripts/blob/main/small_scripts/display_player_stats.gsc

    Displays match kills, the stock current killstreak, and deaths in green at
    the top center for human players. The separate bottom-right counter remains
    the authoritative MOAB-eligible weapon streak.
*/

#include maps\mp\gametypes\_hud_util;

main()
{
    setdvarifuninitialized("fun_mode_player_stats_hud_enable", 1);

    if (!getdvarint("fun_mode_player_stats_hud_enable"))
    {
        return;
    }

    level thread WatchPlayerStatsConnections();
}

WatchPlayerStatsConnections()
{
    level endon("game_ended");

    for (;;)
    {
        level waittill("connected", player);

        if (IsDefined(player.pers["isBot"]) && player.pers["isBot"])
        {
            continue;
        }

        player thread DisplayPlayerStats();
    }
}

DisplayPlayerStats()
{
    self endon("disconnect");
    level endon("game_ended");

    kills = self CreatePlayerStatsValue(-58);
    kills.label = &"^2KILLS: ^7";

    streak = self CreatePlayerStatsValue(0);
    streak.label = &"^2 | STREAK: ^7";

    deaths = self CreatePlayerStatsValue(58);
    deaths.label = &"^2 | DEATHS: ^7";

    lastKills = -1;
    lastStreak = -1;
    lastDeaths = -1;

    for (;;)
    {
        currentKills = 0;
        currentStreak = 0;
        currentDeaths = 0;

        if (IsDefined(self.pers["kills"]))
        {
            currentKills = int(self.pers["kills"]);
        }

        if (IsDefined(self.pers["cur_kill_streak"]))
        {
            currentStreak = int(self.pers["cur_kill_streak"]);
        }

        if (IsDefined(self.pers["deaths"]))
        {
            currentDeaths = int(self.pers["deaths"]);
        }

        if (currentKills != lastKills)
        {
            kills setValue(currentKills);
            lastKills = currentKills;
        }

        if (currentStreak != lastStreak)
        {
            streak setValue(currentStreak);
            lastStreak = currentStreak;
        }

        if (currentDeaths != lastDeaths)
        {
            deaths setValue(currentDeaths);
            lastDeaths = currentDeaths;
        }

        wait 0.1;
    }
}

CreatePlayerStatsValue(x)
{
    hud = self createFontString("Objective", 0.65);
    hud setPoint("CENTER", "TOP", x, 7.5);
    hud.sort = 1;
    hud.foreground = true;

    return hud;
}
