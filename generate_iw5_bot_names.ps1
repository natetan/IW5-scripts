$ErrorActionPreference = "Stop"

# Plutonium accepts player names between 3 and 16 characters, inclusive.
$minimumBotNameLength = 3
$maximumBotNameLength = 16

# Change this path if your Plutonium folder is elsewhere.
$iw5Folder = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$iwdPath = Join-Path $iw5Folder "z_svr_bots.iwd"
$scriptDirectory = Split-Path -Parent $PSCommandPath
$historyFile = Join-Path $scriptDirectory "bot_name_history.txt"

# WinRAR command-line executable.
# Update this if WinRAR is installed elsewhere.
$winRar = "C:\Program Files\WinRAR\WinRAR.exe"

if (-not (Test-Path $iwdPath)) {
    throw "Could not find z_svr_bots.iwd at: $iwdPath"
}

if (-not (Test-Path $winRar)) {
    throw "Could not find WinRAR at: $winRar"
}

# Short, cleaner names that resemble sweaty/competitive aliases.
$tryhardPrefixes = @(

    "Aero","Aether","Arc","Ash","Axiom","Blight","Bloom","Cascade",
    "Chrome","Comet","Cryo","Drift","Eclipse","Ember","Flux","Glint",
    "Glyph","Halo","Hex","Horizon","Ice","Inferno","Jade","Kairo",
    "Khaos","Lucid","Lux","Mirage","Myst","Nero","Nova","Nyx",
    "Obsidian","Onyx","Oracle","Origin","Phantom","Prism","Rift",
    "Rogue","Rune","Shade","Shiver","Silva","Slate","Stryk",
    "Tempest","Titan","Vale","Vector","Vertex","Vex","Vision",
    "Wraith","Zephyr"

)

$tryhardSuffixes = @(

	"a","ac","ace","ad","ael","ai","ain","air","ak","al","an",
	"ane","ant","ar","ard","aris","ark","arn","aro","art","as",
	"ath","ax","aze","ean","ek","el","eld","em","en","ent","er",
	"eris","ern","ero","es","et","eus","ex","ian","ias","ic","id",
	"iel","ik","il","im","in","ion","ir","is","ith","ium","ix",
	"ize","o","od","on","or","ora","orn","os","ous","ov","ox",
	"um","un","ur","us","ux","ven","yn","yr","ys","yx",
	"zen","zer","zeth","zor"

)

# Competitive-looking handles made from phonetic spellings, near-miss words,
# and deliberate gamer stylization. Keeping these as complete names produces
# more natural results than trying to mutate arbitrary dictionary words.
$stylizedTryhardNames = @(
    "Auzentic", "Trvp House", "Streamah", "Kompetitive", "Kracked",
    "Elyte", "Acurate", "Kontrol", "Tryumph", "Victry", "Imortal",
    "Invinsible", "Unstopable", "Natorious", "Fenominal", "Relentliss",
    "Ruthliss", "Precishun", "Demolishun", "Conqer", "Obliviyan",
    "Iridyscent", "Plvtinum", "Dymond", "Crimzn", "Savagry",
    "VybzOnly", "Zero Hesy", "Pure Kontrol", "Aim Assyst", "Game Senz",
    "Map Aware", "HitScannr", "Crosshairr", "Beamr", "Beamah",
    "Grindah", "Slayah", "Snipah", "Rushah", "Clutchah", "Sweatah",
    "Drop Shottah", "Quick Scopah", "One Burstah", "Hard Carryr",
    "Uninstallr", "Respawnr", "Spectatah", "Main Charactr", "Built Diff",
    "Diald In", "Lockt In", "On Timing", "Full Sendr", "No Missin",
    "Never Whiff", "Hittn Clips", "Clip Farmah", "Rankd Demon",
    "Lobby Menace", "Public Menace", "Lobby Tax", "Aim Dealer",
    "Recoil Who", "No Flinch", "Top Fraggin", "Head Glitchr", "Peak Form",
    "Stay Madder", "Get Bettah", "Too Eazy", "Ez Work", "Bad Newz",
    "No Chanc", "Untuchable", "Diff Maker", "Outplayd", "Gun Skillz",
    "Raw Talent", "Pure Skillz", "Xecutive", "Reakted", "Untamedd"
)

# General-purpose IGNs deliberately use complete handles instead of one shared
# construction template. Mundane phrases and dry gaming jokes add variety
# without making the lobby look like a coordinated group of real-life friends.
$generalNames = @(
    "Unpaid Intern", "Not My Lobby", "Mic Muted",
    "Pizza Rolls", "Wrong Loadout", "Local Goblin",
    "A Normal Guy", "Some Dude", "No Signal", "Third Coffee",
    "One More Game",
    "sidequest", "Tax Season", "Chair Enjoyer", "Bad Timing", "Free WiFi",
    "Night Shift", "Monday", "leftovers", "The Neighbor", "Big Sandwich",
    "Small Problem", "Controller Died", "Mild Panic", "No Context",
    "Public Lobby", "Good Enough", "Almost Ready", "Nice Weather",
    "Hold On", "My Bad", "Whoops", "Back Again", "Unsupervised",
    "Do Not Disturb", "Default Settings", "Average Joe", "Casual Friday",
    "Laundry Day", "Room Temperature", "Minor Issue", "Packet Loss",
    "Skill Issue", "Lag Probably", "Not A Bot", "Real Person",
    "Guest Account", "Mom Said Dinner", "Weekend Shift", "No Headset",
    "One Sec", "gg maybe", "okay sure", "justin case",
    "FreshToast", "BlueBucket", "PaperTiger",
    "CheapSeats", "LooseChange", "PocketLint", "ColdPizza", "MildSauce",
    "SlowInternet", "GoodSoup", "NightBus", "LowBattery", "SpareParts",
    "OpenTab", "SideDoor", "BackPocket", "TinyHorse", "Heavy Weather",
    "Soft Reset", "Dead Pixel", "Odd Socks", "Old Receipt", "Blank Tape",
    "Quiet Hours", "Second Monitor", "Kitchen Light", "Parking Lot",
    "Out Of Office", "Wrong Number", "Extra Napkins", "Last Slice",
    "No Refunds", "Slightly Lost", "Pretty Okay", "Long Weekend",
    "Half Awake", "Under Review", "On My Break", "Basic Cable",
    "Forgot Again", "Regular Dude", "Open Door", "Empty Cart",
    "Spawn Trapped", "Missed Again", "Final Kill", "Hitmarker",
    "Red Screen", "Last Magazine", "Bad Spawn", "No UAV",
    "Wrong Perks", "Aim Assist", "Host Migration", "One Bar",
    "Still Reloading", "Out Of Ammo", "Friendly Fire", "Lucky Semtex"
)

# A single gamer-name hybrid per lobby adds the familiar Nick/Kyle/Dan style
# without randomly filling half the server with what looks like one friend group.
$personalGamerNames = @(
    "ShotgunNick", "BigDikNik", "QuickscopeKyle", "SemtexSam",
    "SweatySteve", "CampingCarl", "DropShotDan", "NoScopeNate",
    "FragginFrank", "TacticalTim", "ReloadingRick", "ClutchChris",
    "HeadshotHarry", "TriggerHappyTom", "GrenadeGreg", "SniperMike",
    "RushinRyan", "FlankinFinn", "RPGRob", "StunGrenadeStu",
    "HeartbeatHank", "StealthyScott", "TryhardTyler", "HardscopingHal",
    "AkimboAndy", "JavelinJake", "SilencedSid", "HipfireHenry",
    "PredatorPete", "LastStandLarry", "ScavengerShane", "TacInsertTerry",
    "FMGFrank", "StrikerStan", "SpecialistSean", "OverkillOwen",
    "DeadSilenceDrew", "BlindEyeBen", "QuickdrawQuinn", "MarksmanMatt"
)

# Early-2010s wannabe-MLG styling. Most bots come from this group.
$mlgPrefixes = @(
    "", "", "", "", "", "",
    "x", "X", "ii", "i", "oG", "OG", "iTz", "Its", "Im", "The",
    "xX", "Xx", "v", "z", "Mr", "Lil"
)

$mlgFirstWords = @(
    "Ace", "Alpha", "Angry", "Aqua", "Arctic", "Atomic", "Beast", "Big",
    "Blaze", "Blind", "Blue", "Bold", "Boosted", "Brutal", "Chaos", "Chief",
    "Cold", "Cracked", "Crazy", "Dark", "Deadly", "Delta", "Dirty", "Dizzy",
    "Elite", "Epic", "Fast", "Fatal", "Fearless", "Final", "Flash", "Frosty",
    "Golden", "Grim", "Hyper", "Ice", "Insane", "Killer", "Krazy", "Lucky",
    "Mad", "Major", "Mega", "Mighty", "Mint", "Mystic", "Nasty", "Night",
    "Prime", "Pro", "Quick", "Rapid", "Raw", "Red", "Royal", "Savage",
    "Shadow", "Silent", "Slick", "Sneaky", "Speedy", "Steady", "Stormy",
    "Super", "Swift", "Toxic", "True", "Ultra", "Venom", "Vicious", "Wild"
)

$mlgSecondWords = @(
    "Ace", "Beast", "Blaster", "Boss", "Bullet", "Camper", "Captain", "Chief",
    "Clutch", "Cranker", "Crusher", "Demon", "Drifter", "Falcon", "Fighter",
    "Frag", "Gamer", "Ghost", "Grinder", "Gunner", "Hawk", "Hero", "Hunter",
    "Jumper", "Knight", "Legend", "Ninja", "Phantom", "Player", "Predator",
    "Pro", "Raider", "Ranger", "Reaper", "Ripper", "Rival", "Rogue", "Rusher",
    "Savage", "Scope", "Scout", "Shooter", "Slayer", "Sniper", "Soldier",
    "Spartan", "Striker", "Sweat", "Titan", "Trooper", "Viper", "Warrior",
    "Wolf", "Wizard"
)

$mlgSuffixes = @(
    "", "", "", "", "", "", "",
    "x", "X", "z", "HD", "TV", "YT", "OG", "Pro", "JR", "II", "III",
    "7", "13", "21", "24", "27", "33", "47", "69", "99", "117",
    "xX", "Xx"
)

# Smaller pool of believable Xbox-generated-style tags.
$xboxAdjectives = @(
    "Amber", "Ancient", "Brave", "Bright", "Calm", "Clever", "Cosmic", "Daring",
    "Electric", "Flying", "Frozen", "Fuzzy", "Gentle", "Golden", "Grumpy", "Happy",
    "Hidden", "Jolly", "Lucky", "Mighty", "Misty", "Quiet", "Rapid", "Royal",
    "Shiny", "Silent", "Sleepy", "Sneaky", "Spicy", "Swift", "Wandering", "Wild"
)

$xboxNouns = @(
    "Badger", "Banana", "Bear", "Biscuit", "Cactus", "Cupid", "Dolphin", "Dragon",
    "Eagle", "Falcon", "Hamster", "Knight", "Koala", "Lobster", "Moose", "Otter",
    "Panda", "Penguin", "Phoenix", "Potato", "Rabbit", "Raven", "Tiger", "Turtle",
    "Walrus", "Wizard", "Wolf", "Yak"
)

function Test-ValidBotName {
    param(
        [AllowNull()]
        [string] $Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    return (
        $Name.Length -ge $minimumBotNameLength -and
        $Name.Length -le $maximumBotNameLength
    )
}

function Get-RandomItem {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $Items
    )

    if ($null -eq $Items -or $Items.Count -eq 0) {
        throw "Get-RandomItem received a null or empty array."
    }

    $index = Get-Random -Minimum 0 -Maximum $Items.Count
    return $Items[$index]
}

function Get-UniqueRandomItem {
    param(
        [Parameter(Mandatory)]
        [object[]] $Items,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Used,

        [switch] $AllowEmptyRepeat
    )

    # Prefer unused pieces so prefixes/words/suffixes do not visibly repeat.
    $available = @($Items | Where-Object {
        if ($AllowEmptyRepeat -and $_ -eq "") {
            return $true
        }

        return -not $Used.Contains([string] $_)
    })

    # If a pool is ever exhausted, gracefully fall back to the full list.
    if ($available.Count -eq 0) {
        $available = @($Items)
    }

    $choice = [string](Get-RandomItem $available)

    if (-not ($AllowEmptyRepeat -and $choice -eq "")) {
        [void] $Used.Add($choice)
    }

    return $choice
}

function New-TryhardName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedPrefixes,
        [System.Collections.Generic.HashSet[string]] $UsedSuffixes
    )

    $prefix = Get-UniqueRandomItem -Items $tryhardPrefixes -Used $UsedPrefixes
    $suffix = Get-UniqueRandomItem -Items $tryhardSuffixes -Used $UsedSuffixes
    return "$prefix$suffix"
}

function New-StylizedTryhardName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedNames
    )

    return Get-UniqueRandomItem -Items $stylizedTryhardNames -Used $UsedNames
}

function New-GeneralName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedNames
    )

    return Get-UniqueRandomItem -Items $generalNames -Used $UsedNames
}

function New-PersonalGamerName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedNames
    )

    return Get-UniqueRandomItem -Items $personalGamerNames -Used $UsedNames
}

function New-MlgName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedPrefixes,
        [System.Collections.Generic.HashSet[string]] $UsedFirstWords,
        [System.Collections.Generic.HashSet[string]] $UsedSecondWords,
        [System.Collections.Generic.HashSet[string]] $UsedSuffixes
    )

    $left = Get-UniqueRandomItem -Items $mlgPrefixes -Used $UsedPrefixes -AllowEmptyRepeat
    $first = Get-UniqueRandomItem -Items $mlgFirstWords -Used $UsedFirstWords
    $second = Get-UniqueRandomItem -Items $mlgSecondWords -Used $UsedSecondWords
    $right = Get-UniqueRandomItem -Items $mlgSuffixes -Used $UsedSuffixes -AllowEmptyRepeat

    return "$left$first$second$right"
}

function New-XboxName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedAdjectives,
        [System.Collections.Generic.HashSet[string]] $UsedNouns
    )

    $adjective = Get-UniqueRandomItem -Items $xboxAdjectives -Used $UsedAdjectives
    $noun = Get-UniqueRandomItem -Items $xboxNouns -Used $UsedNouns
    $number = Get-Random -Minimum 0 -Maximum 1000

    return "$adjective$noun$number"
}

# Build a 17-bot lobby from visibly different naming styles. Clean competitive
# aliases remain the largest group, while real-name-like tags are capped at one:
#   6 constructed try-hard aliases (~35%)
#   2 stylized-word try-hard aliases (~12%)
#   5 general gaming names (~29%)
#   1 gamer/name hybrid (~6%)
#   2 wannabe-MLG names (~12%)
#   1 Xbox-generated-style tag (~6%)
$tryhardCount = 6
$stylizedTryhardCount = 2
$generalCount = 5
$personalGamerCount = 1
$mlgCount = 2
$xboxCount = 1

# Keep the eight try-hard names first so stronger bots receive competitive IGNs.
# Randomize all of the more casual styles that follow them.
$categories = @()
$categories += @(for ($i = 0; $i -lt $tryhardCount; $i++) { "tryhard" })
$categories += @(for ($i = 0; $i -lt $stylizedTryhardCount; $i++) { "stylizedTryhard" })

$remainingCategories = @()
$remainingCategories += @(for ($i = 0; $i -lt $generalCount; $i++) { "general" })
$remainingCategories += @(for ($i = 0; $i -lt $personalGamerCount; $i++) { "personalGamer" })
$remainingCategories += @(for ($i = 0; $i -lt $mlgCount; $i++) { "mlg" })
$remainingCategories += @(for ($i = 0; $i -lt $xboxCount; $i++) { "xbox" })
$remainingCategories = @($remainingCategories | Sort-Object { Get-Random })

$categories += $remainingCategories

$usedTryhardPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedTryhardSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedStylizedTryhardNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedGeneralNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedPersonalGamerNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgFirstWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSecondWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxAdjectives = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxNouns = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$names = [System.Collections.Generic.List[string]]::new()
$uniqueNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$recentNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$recentNameList = [System.Collections.Generic.List[string]]::new()

if (Test-Path $historyFile) {
    foreach ($previousName in [System.IO.File]::ReadAllLines($historyFile)) {
        if (-not [string]::IsNullOrWhiteSpace($previousName)) {
            $previousName = $previousName.Trim()

            if ($recentNames.Add($previousName)) {
                [void] $recentNameList.Add($previousName)
            }
        }
    }
}

foreach ($category in $categories) {
    $candidate = $null
    $candidateAdded = $false

    # Retry whole-name collisions, though unique components make them very unlikely.
    for ($attempt = 0; $attempt -lt 50; $attempt++) {
        switch ($category) {
            "tryhard" {
                $candidate = New-TryhardName `
                    -UsedPrefixes $usedTryhardPrefixes `
                    -UsedSuffixes $usedTryhardSuffixes
            }
            "stylizedTryhard" {
                $candidate = New-StylizedTryhardName -UsedNames $usedStylizedTryhardNames
            }
            "general" {
                $candidate = New-GeneralName -UsedNames $usedGeneralNames
            }
            "personalGamer" {
                $candidate = New-PersonalGamerName -UsedNames $usedPersonalGamerNames
            }
            "mlg" {
                $candidate = New-MlgName `
                    -UsedPrefixes $usedMlgPrefixes `
                    -UsedFirstWords $usedMlgFirstWords `
                    -UsedSecondWords $usedMlgSecondWords `
                    -UsedSuffixes $usedMlgSuffixes
            }
            "xbox" {
                $candidate = New-XboxName `
                    -UsedAdjectives $usedXboxAdjectives `
                    -UsedNouns $usedXboxNouns
            }
            default {
                throw "Unknown bot-name category: $category"
            }
        }

        # Reject the complete candidate instead of truncating it. Truncation can
        # cut words awkwardly and turn distinct source names into collisions.
        if (-not (Test-ValidBotName -Name $candidate)) {
            continue
        }

        if (-not $recentNames.Contains($candidate) -and $uniqueNames.Add($candidate)) {
            [void] $names.Add($candidate)
            $candidateAdded = $true
            break
        }
    }

    if (-not $candidateAdded) {
        throw "Failed to generate a unique 3-16 character bot name for category: $category"
    }
}

if ($names.Count -ne 17) {
    throw "Expected 17 bot names but generated $($names.Count)."
}

foreach ($name in $names) {
    if (-not (Test-ValidBotName -Name $name)) {
        throw "Generated bot name violates Plutonium's 3-16 character limit: $name"
    }
}

# Save a copy beside this PowerShell script so you can inspect the launch's names.
$localBotsFile = Join-Path $scriptDirectory "bots.txt"

[System.IO.File]::WriteAllLines(
    $localBotsFile,
    [string[]] $names,
    [System.Text.Encoding]::ASCII
)

$tempFolder = Join-Path $env:TEMP "iw5-random-bot-names"
$botsFile = Join-Path $tempFolder "bots.txt"

New-Item -ItemType Directory -Force -Path $tempFolder | Out-Null

# ASCII avoids encoding surprises in older game assets.
[System.IO.File]::WriteAllLines(
    $botsFile,
    [string[]] $names,
    [System.Text.Encoding]::ASCII
)

Write-Host "Generated bot names ($tryhardCount constructed try-hard, $stylizedTryhardCount stylized try-hard, $generalCount general, $personalGamerCount gamer-name, $mlgCount wannabe-MLG, $xboxCount Xbox-style):"
$names | ForEach-Object { Write-Host "  $_" }

# Delete the old bots.txt from the archive, then add the new one at archive root.
& $winRar d -ibck $iwdPath "bots.txt" | Out-Null
& $winRar a -ibck -ep $iwdPath $botsFile | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "WinRAR failed to update the IWD."
}

# Avoid repeating names from the previous four full lobbies. Keep this local
# runtime history out of Git; older names naturally become eligible again.
$updatedHistory = [System.Collections.Generic.List[string]]::new()
$historySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($historyName in @($names) + @($recentNameList)) {
    if ($historySet.Add($historyName)) {
        [void] $updatedHistory.Add($historyName)
    }

    if ($updatedHistory.Count -ge 68) {
        break
    }
}

[System.IO.File]::WriteAllLines(
    $historyFile,
    [string[]] $updatedHistory,
    [System.Text.Encoding]::ASCII
)

Write-Host ""
Write-Host "Updated: $iwdPath"
Write-Host "You can now launch Plutonium."
