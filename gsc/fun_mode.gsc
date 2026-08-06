#include maps\mp\_utility;

/*
    Fun Mode - IW5 / Plutonium

    Features:
    - Only Custom Class 15 receives the full Specialist perk set.
    - Unlimited sprint is enabled only for human players.

    MW3 custom-class numbers shown in the UI are 1-based.
    Class 15 maps to internal class index 14.
*/

Main()
{
    SetDvarIfNotInitialized("fun_mode_enable", 1);
    SetDvarIfNotInitialized("fun_mode_specialist_class_index", 14);
}

Init()
{
    if (!GetDvarInt("fun_mode_enable"))
    {
        return;
    }

    level thread OnPlayerConnect();
}

OnPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);

        if (player IsBotPlayer())
        {
            continue;
        }

        player thread WatchPlayerLoadout();
    }
}

WatchPlayerLoadout()
{
    self endon("disconnect");

    // Client-side, so bots are unaffected.
    // don't think this actually works
    self SetClientDvar("player_unlimitedSprint", "1");

    for (;;)
    {
        // Fired after spawning and when changing classes.
        self waittill("changed_kit");

        self SetClientDvar("player_unlimitedSprint", "1");

        wait 0.1;

        if (
            IsDefined(self.class_num) &&
            (self.class_num == 13 || self.class_num == 14)
        )
        {
            self maps\mp\killstreaks\_killstreaks::giveallperks();
        }
    }
}

// Custom function for just perks. The giveallperks() one gives full proficiencies too
GiveFullSpecialistBonus()
{
    perks = [];

    /*
        Standard perks. Each base perk is granted, then its Pro mapping is
        read directly from mp/perktable.csv. This bypasses progression locks
        for the current life only; it does not permanently unlock anything.
    */

    // Tier 1
    perks[0]  = "specialty_fastreload";        // Sleight of Hand
    perks[1]  = "specialty_scavenger";         // Scavenger
    perks[2]  = "specialty_blindeye";          // Blind Eye
    perks[3]  = "specialty_longersprint";      // Extreme Conditioning
    perks[4]  = "specialty_paint";             // Recon

    // Tier 2
    perks[5]  = "specialty_quickdraw";         // Quickdraw
    perks[6]  = "specialty_hardline";          // Hardline
    perks[7]  = "specialty_coldblooded";       // Assassin
    perks[8]  = "_specialty_blastshield";      // Blast Shield

    // Tier 3
    perks[9]  = "specialty_stalker";           // Stalker
    perks[10] = "specialty_bulletaccuracy";    // Steady Aim
    perks[11] = "specialty_detectexplosive";   // SitRep
    perks[12] = "specialty_autospot";          // Marksman
    perks[13] = "specialty_quieter";           // Dead Silence

    foreach (perk in perks)
    {
        self GivePerk(perk, false);

        proPerk = GetProPerkName(perk);

        if (
            IsDefined(proPerk) &&
            proPerk != "" &&
            proPerk != "specialty_null"
        )
        {
            self GivePerk(proPerk, false);
        }
    }

    /*
        Extra bonuses granted by MW3's actual Specialist Bonus.
        These are not ordinary selectable perks.
    */

    self GivePerk("specialty_marksman", false);
    self GivePerk("specialty_sharp_focus", false);
    self GivePerk("specialty_longerrange", false);
    self GivePerk("specialty_fastermelee", false);
    self GivePerk("specialty_reducedsway", false);
    self GivePerk("specialty_lightweight", false); // Movement-speed boost
}

GetProPerkName(perkName)
{
    // Column 1 is the base perk name; column 8 is its Pro perk mapping.
    return TableLookup("mp/perktable.csv", 1, perkName, 8);
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
