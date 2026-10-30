/*
    Permissioned Admin Chat Commands - IW5 / Plutonium

    A compact command registry inspired by Resxt's Plutonium IW5 chat-command
    framework:
    https://github.com/Resxt/Plutonium-IW5-Scripts/tree/main/chat_commands

    Dedicated-server permissions are assigned by GUID through local dvars so
    private identifiers never need to be committed to this repository.

    Permission levels:
        0 - no administrative commands
        1 - low-risk helpers
        2 - moderator/testing helpers
        3 - owner-level gameplay and server testing commands

    Hosts of non-dedicated sessions automatically receive level 3. On
    dedicated servers, fun_mode_super_class_guids also grants level 3 so the
    existing private owner allowlist can be reused.
*/

main()
{
    setdvarifuninitialized( "fun_mode_chat_commands_enable", 1 );
    setdvarifuninitialized( "fun_mode_chat_permission_default", 0 );
    setdvarifuninitialized( "fun_mode_chat_permission_1_guids", "" );
    setdvarifuninitialized( "fun_mode_chat_permission_2_guids", "" );
    setdvarifuninitialized( "fun_mode_chat_permission_3_guids", "" );

    if ( !getdvarint( "fun_mode_chat_commands_enable" ) )
        return;

    level.funModeChatCommands = [];
    level.funModeChatAliases = [];

    registerAdminChatCommand(
        "commands",
        0,
        ::showAvailableAdminChatCommands,
        "!commands"
    );
    registerAdminChatCommand(
        "help",
        0,
        ::showAdminChatCommandHelp,
        "!help <command>"
    );
    registerAdminChatCommand(
        "permission",
        0,
        ::showAdminChatPermission,
        "!permission"
    );
    registerAdminChatCommand(
        "give",
        3,
        ::giveKillstreakAdminChatCommand,
        "!give <killstreak> [player]"
    );
    registerAdminChatCommand(
        "random",
        3,
        ::randomMapAdminChatCommand,
        "!random"
    );
    registerAdminChatCommand(
        "killmode",
        3,
        ::killModeAdminChatCommand,
        "!killmode <chain|virus|aoe|splash|vamp|off>"
    );

    level.funModeChatAliases["commands"] = "commands";
    level.funModeChatAliases["cmds"] = "commands";
    level.funModeChatAliases["help"] = "help";
    level.funModeChatAliases["permission"] = "permission";
    level.funModeChatAliases["perm"] = "permission";
    level.funModeChatAliases["give"] = "give";
    level.funModeChatAliases["givekillstreak"] = "give";
    level.funModeChatAliases["giveks"] = "give";
    level.funModeChatAliases["random"] = "random";
    level.funModeChatAliases["randommap"] = "random";
    level.funModeChatAliases["killmode"] = "killmode";

    level thread watchAdminChatCommands();
}

registerAdminChatCommand( name, minimumPermission, handler, usage )
{
    command = spawnstruct();
    command.minimumPermission = minimumPermission;
    command.handler = handler;
    command.usage = usage;
    level.funModeChatCommands[name] = command;
}

watchAdminChatCommands()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "say", message, player, isHidden );

        if ( !isdefined( player ) || !isplayer( player ) || !isdefined( message ) )
            continue;

        if ( message.size < 2 )
            continue;

        // Some Plutonium chat events include a leading control character.
        if ( message[0] != "!" )
            message = getsubstr( message, 1 );

        if ( message.size < 2 || message[0] != "!" )
            continue;

        tokens = strtok( message, " " );

        if ( !tokens.size )
            continue;

        requestedName = tolower( getsubstr( tokens[0], 1 ) );

        if ( !isdefined( level.funModeChatAliases[requestedName] ) )
            continue;

        commandName = level.funModeChatAliases[requestedName];
        command = level.funModeChatCommands[commandName];

        if ( !isdefined( command ) )
            continue;

        permission = player getAdminChatPermission();

        if ( permission < command.minimumPermission )
        {
            player tell(
                "^1Permission denied. ^7Level " +
                command.minimumPermission + " required; you have " + permission + "."
            );
            continue;
        }

        args = [];

        for ( index = 1; index < tokens.size; index++ )
            args[args.size] = tokens[index];

        player [[ command.handler ]]( args );
    }
}

showAvailableAdminChatCommands( args )
{
    permission = self getAdminChatPermission();
    available = "^2Commands:^7";

    foreach ( commandName in getarraykeys( level.funModeChatCommands ) )
    {
        command = level.funModeChatCommands[commandName];

        if ( permission >= command.minimumPermission )
            available += " !" + commandName;
    }

    self tell( available );
}

showAdminChatCommandHelp( args )
{
    if ( !args.size )
    {
        self tell( "^3Usage:^7 !help <command>" );
        return;
    }

    requestedName = tolower( args[0] );

    if ( isdefined( level.funModeChatAliases[requestedName] ) )
        requestedName = level.funModeChatAliases[requestedName];

    if ( !isdefined( level.funModeChatCommands[requestedName] ) )
    {
        self tell( "^1Unknown command:^7 " + args[0] );
        return;
    }

    command = level.funModeChatCommands[requestedName];

    permission = self getAdminChatPermission();

    if ( permission < command.minimumPermission )
    {
        self tell( "^1Permission denied." );
        return;
    }

    self tell(
        "^3Usage:^7 " + command.usage +
        " ^3Permission:^7 " + command.minimumPermission
    );
}

showAdminChatPermission( args )
{
    permission = self getAdminChatPermission();
    self tell( "^3Chat permission level:^7 " + permission );
}

killModeAdminChatCommand( args )
{
    if ( !args.size )
    {
        self tell( "^3Usage:^7 !killmode <chain|virus|aoe|splash|vamp|off>" );
        return;
    }

    mode = tolower( args[0] );

    if (
        mode != "chain" &&
        mode != "virus" &&
        mode != "aoe" &&
        mode != "splash" &&
        mode != "vamp" &&
        mode != "off"
    )
    {
        self tell( "^1Unknown kill mode:^7 " + args[0] );
        self tell( "^3Usage:^7 !killmode <chain|virus|aoe|splash|vamp|off>" );
        return;
    }

    self.fun_mode_kill_mode = mode;

    if ( mode == "off" )
    {
        self tell( "^2Kill mode disabled.^7" );
        return;
    }

    self tell( "^2Kill mode enabled:^7 " + mode );
}

giveKillstreakAdminChatCommand( args )
{
    if ( !args.size )
    {
        self tell( "^3Usage:^7 !give <killstreak> [player]" );
        return;
    }

    streakName = resolveTestingKillstreakName( args[0] );

    if (
        !isdefined( level.killstreakfuncs[streakName] ) ||
        tablelookup( "mp/killstreakTable.csv", 1, streakName, 0 ) == ""
    )
    {
        self tell( "^1Unknown killstreak:^7 " + args[0] );
        return;
    }

    target = self;

    if ( args.size > 1 )
        target = self findAdminChatPlayer( args[1] );

    if ( !isdefined( target ) )
    {
        self tell( "^1Player not found or name is ambiguous:^7 " + args[1] );
        return;
    }

    if (
        !isdefined( target.pers ) ||
        !isdefined( target.pers["killstreaks"] ) ||
        !isdefined( target.team ) ||
        target.team == "spectator"
    )
    {
        self tell( "^1That player cannot receive a killstreak right now." );
        return;
    }

    target thread maps\mp\killstreaks\_killstreaks::givekillstreak(
        streakName,
        0,
        0,
        target,
        0
    );

    if ( target == self )
        self tell( "^2Granted killstreak:^7 " + streakName );
    else
        self tell( "^2Granted " + streakName + " to:^7 " + target.name );
}

randomMapAdminChatCommand( args )
{
    mapPool = scripts\mapvote::GetConfiguredMapvoteMapPool();

    if (!IsDefined(mapPool) || !mapPool.size)
    {
        self tell("^1No maps are configured for map voting.");
        return;
    }

    candidates = [];
    currentMap = GetDvar("mapname");

    foreach (mapName in mapPool)
    {
        if (mapName != currentMap || mapPool.size == 1)
        {
            candidates[candidates.size] = mapName;
        }
    }

    if (!candidates.size)
    {
        self tell("^1No alternate map is available.");
        return;
    }

    selectedMap = candidates[RandomInt(candidates.size)];
    modeDsr = scripts\mapvote::GetCurrentMapvoteModeDsr();

    if (!IsDefined(modeDsr) || modeDsr == "")
    {
        self tell("^1The current mode is not configured in map voting.");
        return;
    }

    compatibleDsr = scripts\mapvote::GetCompatibleMapvoteModeDsr(
        selectedMap,
        modeDsr
    );

    if (!IsDefined(compatibleDsr) || compatibleDsr == "")
    {
        self tell("^1No compatible recipe is configured for that map.");
        return;
    }

    modeName = scripts\mapvote::GetConfiguredMapvoteModeName(compatibleDsr);
    self tell("^2Random map:^7 " + selectedMap + " ^2Mode:^7 " + modeName);

    level thread RunRandomMapRotation(compatibleDsr, selectedMap);
}

RunRandomMapRotation(modeDsr, mapName)
{
    // Allow the confirmation chat line to reach clients before map teardown.
    wait 0.5;
    scripts\mapvote::DoRotation(modeDsr, mapName);
}

resolveTestingKillstreakName( requestedName )
{
    requestedName = tolower( requestedName );

    switch ( requestedName )
    {
        case "pred":
        case "predator":
            return "predator_missile";
        case "harrier":
            return "precision_airstrike";
        case "heli":
            return "helicopter";
        case "strafe":
        case "aa":
            return "littlebird_flock";
        case "ah6":
            return "littlebird_support";
        case "reaper":
            return "remote_mortar";
        case "assaultdrone":
        case "a10":
            return "airdrop_remote_tank";
        case "pavelow":
            return "helicopter_flares";
        case "jugg":
        case "swarm":
            return "airdrop_juggernaut";
        case "osprey":
            return "osprey_gunner";
        case "cuav":
            return "counter_uav";
        case "vest":
            return "deployable_vest";
        case "recon":
            return "remote_uav";
        case "auav":
            return "triple_uav";
        case "support_sentry":
            return "remote_mg_turret";
        case "dance":
        case "deaths_dance":
            return "airdrop_juggernaut_recon";
        case "moab":
            return "nuke";
        default:
            return requestedName;
    }
}

findAdminChatPlayer( requestedName )
{
    if ( tolower( requestedName ) == "me" )
        return self;

    exactMatch = undefined;
    partialMatch = undefined;
    partialMatches = 0;

    foreach ( player in level.players )
    {
        if ( !isdefined( player ) || !isplayer( player ) )
            continue;

        if ( tolower( player.name ) == tolower( requestedName ) )
        {
            exactMatch = player;
            break;
        }

        if (
            requestedName.size <= player.name.size &&
            tolower( getsubstr( player.name, 0, requestedName.size ) ) ==
                tolower( requestedName )
        )
        {
            partialMatch = player;
            partialMatches++;
        }
    }

    if ( isdefined( exactMatch ) )
        return exactMatch;

    if ( partialMatches == 1 )
        return partialMatch;

    return undefined;
}

getAdminChatPermission()
{
    if ( isdefined( self.pers["isBot"] ) && self.pers["isBot"] )
        return 0;

    // Plutonium does not reliably set the stock xblive_privatematch dvar for
    // every locally hosted private match. The dedicated dvar is the stable
    // boundary: only the actual listen-server host bypasses GUID permission.
    if ( !getdvarint( "dedicated" ) && self ishost() )
        return 3;

    if (
        self guidIsInAdminChatDvar( "fun_mode_chat_permission_3_guids" ) ||
        self guidIsInAdminChatDvar( "fun_mode_super_class_guids" )
    )
    {
        return 3;
    }

    if ( self guidIsInAdminChatDvar( "fun_mode_chat_permission_2_guids" ) )
        return 2;

    if ( self guidIsInAdminChatDvar( "fun_mode_chat_permission_1_guids" ) )
        return 1;

    return int( clamp(
        getdvarint( "fun_mode_chat_permission_default" ),
        0,
        3
    ) );
}

guidIsInAdminChatDvar( dvarName )
{
    playerGuid = self getguid() + "";
    configuredGuids = strtok( getdvar( dvarName ), "," );

    foreach ( configuredGuid in configuredGuids )
    {
        if ( configuredGuid == playerGuid )
            return true;
    }

    return false;
}
