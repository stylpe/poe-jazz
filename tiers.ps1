function calc([string]$name, $e) {
    return @{ name = $name; e = $e }
}

$stacks = Invoke-RestMethod "https://www.poewiki.net/index.php?title=Special:CargoExport&tables=stackables&&fields=stackables.stack_size%3Dsize%2C+stackables._pageName%3Dname%2C&where=stackables._pageNamespace+%3D+0&limit=2000&format=json"
$stacksLookup = @{}
$stacks | % { $stacksLookup[$_.name] = $_.size }
$economy = Invoke-RestMethod "https://poe.ninja/api/data/denseoverviews?league=Affliction"

function categorize([string]$name) {
    switch -Regex ($name) {
        "Mirror|Hinekora" { "GodTier"; break }
        "Key|Valdo" { "Key"; break }
        "Goddess" { "Lab"; break }
        "Tainted" { "Scourge"; break }
        "Shard" { "Shard"; break }
        "Chayula|Uul|Esh|Tul|Xoph" { "Breach"; break }
        "Maven's Orb|Dominance|'s Exalted|of Conflict|Eldritch|Awakener|Veiled|Enkindling"
        { "Influenced"; break }
        "Lifeforce|Sacred Blossom" { "Harvest"; break }
        "Sextant|Compass|Scouting" { "Atlas"; break }
        "Fragment|Memory|Crescent|Writ|Simulacrum|Timeless|Divine Vessel|Sacrifice|Crest|Mortal|Ritual"
        { "Fragment"; break }
        "Catalyst" { "Catalyst"; break }
        "Oil" { "Oil"; break }
        "Stacked Deck" { "DivinationCard"; break }
        default { "Basic" }
    }
}

# filtering out some types that are not yet handled properly
# or that get replaced (i.e. shards), then expanding some properties
$items = $economy.currencyOverviews + $economy.itemOverviews `
| ? type -NotIn Shard,BaseType,Beast,ClusterJewel,IncursionTemple,HelmetEnchant `
| % {
    if ($_.type -eq "Currency") { $exp = { categorize $_.name } }
    else { $ptype = $_.type; $exp = { $ptype } }
    $type = calc type $exp
    $stackprop = calc stack { $stacksLookup[$_.name] ?? 1 }
    $variantprop = calc variant { $_.variant -split ", " }
    $_.lines | select name, $variantprop, chaos, $type, $stackprop
}

# Get a summary of variants:
# $items | group type | fl Name,@{n="Variants";e={$_.group.variant | Sort-Object -Unique | Join-String -Separator ", "}}

# Synthesized shard prices
$basic = $items | ? type -In Basic,GodTier
$orbToShard = $stacks `
| ? name -match " Shard$" `
| % {
        $chaos = if($_.name -eq "Chaos Shard") {1} else {
            $commonPart = $_.name -replace " Shard",""
            $basic | ? name -match $commonPart | % chaos | select -First 1
        }
        [PSCustomObject]@{
            name = $_.name
            chaos = $chaos / $_.size
            type = "Shard"
            stack = $_.size
        }
    }
$items += $orbToShard

# Calculate map tiers
$maptierprop = calc MapTier { @($_.variant) -like "T*" -replace "T","" -as [int[]] }
$maps = $items | ? type -Like "*Map" | select *,$maptierprop

# Calculate tiers
$div = $items | where name -eq "Divine Orb" | % chaos
$tierprop = calc tier {
    [int] [math]::Max(
        [math]::Floor(
            [math]::Log($_.chaos, $div) * 6
        ) + 8, 0
    )
}
$tiered = $items | select *, $tierprop
