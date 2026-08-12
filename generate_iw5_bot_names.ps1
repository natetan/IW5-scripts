$ErrorActionPreference = "Stop"

# Change this path if your Plutonium folder is elsewhere.
$iw5Folder = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$iwdPath = Join-Path $iw5Folder "z_svr_bots.iwd"

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

# Build a 17-bot lobby with a modern controlled mix:
#   12 clean/try-hard aliases (~71%)
#   4 wannabe-MLG names (~24%)
#   1 Xbox-generated-style tag (~6%)
$tryhardCount = 12
$mlgCount = 4
$xboxCount = 1

# Keep the try-hard aliases first so stronger bots can receive the cleaner IGNs.
# Randomize only the MLG/Xbox names that come after them.
$categories = @()
$categories += @(for ($i = 0; $i -lt $tryhardCount; $i++) { "tryhard" })

$remainingCategories = @()
$remainingCategories += @(for ($i = 0; $i -lt $mlgCount; $i++) { "mlg" })
$remainingCategories += @(for ($i = 0; $i -lt $xboxCount; $i++) { "xbox" })
$remainingCategories = @($remainingCategories | Sort-Object { Get-Random })

$categories += $remainingCategories

$usedTryhardPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedTryhardSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgFirstWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSecondWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxAdjectives = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxNouns = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$names = [System.Collections.Generic.List[string]]::new()
$uniqueNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($category in $categories) {
    $candidate = $null

    # Retry whole-name collisions, though unique components make them very unlikely.
    for ($attempt = 0; $attempt -lt 50; $attempt++) {
        switch ($category) {
            "tryhard" {
                $candidate = New-TryhardName `
                    -UsedPrefixes $usedTryhardPrefixes `
                    -UsedSuffixes $usedTryhardSuffixes
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

        if ($uniqueNames.Add($candidate)) {
            [void] $names.Add($candidate)
            break
        }
    }

    if ($names.Count -lt ($uniqueNames.Count)) {
        throw "Failed to generate a unique bot name."
    }
}

if ($names.Count -ne 17) {
    throw "Expected 17 bot names but generated $($names.Count)."
}

# Save a copy beside this PowerShell script so you can inspect the launch's names.
$scriptDirectory = Split-Path -Parent $PSCommandPath
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

Write-Host "Generated bot names ($tryhardCount try-hard, $mlgCount wannabe-MLG, $xboxCount Xbox-style):"
$names | ForEach-Object { Write-Host "  $_" }

# Delete the old bots.txt from the archive, then add the new one at archive root.
& $winRar d -ibck $iwdPath "bots.txt" | Out-Null
& $winRar a -ibck -ep $iwdPath $botsFile | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "WinRAR failed to update the IWD."
}

Write-Host ""
Write-Host "Updated: $iwdPath"
Write-Host "You can now launch Plutonium."
