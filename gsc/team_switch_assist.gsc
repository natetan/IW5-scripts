/*
    Full-Lobby Team-Switch Assist - IW5 / Plutonium

    Temporarily removes one destination-team bot when a human opens the team
    menu in a full 9v9 Bot Warfare lobby, then restores the configured fill
    target so Bot Warfare replaces the vacated slot.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    SetDvarIfNotInitialized("fun_mode_team_switch_assist", 1);
    SetDvarIfNotInitialized("fun_mode_team_switch_fill", 18);
}

OnPlayerConnected()
{
    self thread WatchTeamSwitchMenu();
}

WatchTeamSwitchMenu()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("menuresponse", menu, response);

        if (
            !GetDvarInt("fun_mode_team_switch_assist") ||
            response != "changeteam" ||
            !IsDefined(self.pers["team"]) ||
            (
                IsDefined(level.fun_mode_team_switch_in_progress) &&
                level.fun_mode_team_switch_in_progress
            )
        )
        {
            continue;
        }

        currentTeam = self.pers["team"];

        if (currentTeam != "allies" && currentTeam != "axis")
        {
            continue;
        }

        destinationTeam = "axis";

        if (currentTeam == "axis")
        {
            destinationTeam = "allies";
        }

        foreach (candidate in level.players)
        {
            if (
                !candidate IsBotPlayer() ||
                !IsDefined(candidate.pers["team"]) ||
                candidate.pers["team"] != destinationTeam
            )
            {
                continue;
            }

            fillTarget = GetDvarInt("fun_mode_team_switch_fill");
            previousFillKick = GetDvarInt("bots_manage_fill_kick");

            level.fun_mode_team_switch_in_progress = true;

            // Keep Bot Warfare from racing us by removing a second bot.
            SetDvar("bots_manage_fill_kick", 0);
            SetDvar("bots_manage_fill", fillTarget - 1);
            kick(candidate GetEntityNumber(), "EXE_PLAYERKICKED");

            level thread RestoreBotFill(fillTarget, previousFillKick);
            break;
        }
    }
}

RestoreBotFill(fillTarget, fillKickValue)
{
    wait 10;
    SetDvar("bots_manage_fill", fillTarget);
    SetDvar("bots_manage_fill_kick", fillKickValue);
    level.fun_mode_team_switch_in_progress = false;
}

IsBotPlayer()
{
    return IsDefined(self.pers["isBot"]) && self.pers["isBot"];
}

SetDvarIfNotInitialized(dvarName, value)
{
    if (GetDvar(dvarName) == "")
    {
        SetDvar(dvarName, value);
    }
}
