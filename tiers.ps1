function calc([string]$name, $e) {
    return @{ name = $name; e = $e }
}

$economy = Invoke-RestMethod "https://poe.ninja/api/data/denseoverviews?league=Affliction"

# Currencies and Fragments get some custom variants
function categorize([string]$name) {
    switch -Regex ($name) {
        "Mirror|Hinekora" { "GodTier"; break }
        "Key|Valdo" { "Key"; break }
        "Goddess" { "Lab"; break }
        "Tainted" { "Scourge"; break }
        "Shard" { "Shard"; break }
        "Chayula|Uul|Esh|Tul|Xoph" { "Breach"; break }
        "Maven's Orb|Dominance|'s Exalted|of Conflict|Eldritch|Awakener|Veiled|Enkindling" { "Influenced"; break }
        "Lifeforce|Sacred Blossom" { "Harvest"; break }
        "Sextant|Compass|Scouting|Divine Vessel" { "Atlas"; break }
        "Memory" { "Memory"; break }
        "Crest" { "Elderslayer"; break }
        "Ritual" { "Ritual"; break }
        "Timeless" { "Legion"; break }
        "Fragment|Crescent|Writ|Simulacrum|Sacrifice|Mortal" { "Boss"; break }
        "Catalyst" { "Catalyst"; break }
        "Oil" { "Oil"; break }
        "Stacked Deck" { "DivinationCard"; break }
        default { "Basic" }
    }
}

$currency = $economy | % currencyOverviews -PipelineVariable group | % lines |
    select name, chaos, (calc type {$group.type}), (calc variant { categorize $_.name }) |
    ? variant -ne "Shard" # these get calculated
$items = $currency

# filtering out some types that are not yet handled properly
$skippedTypes = "BaseType|Beast|ClusterJewel|IncursionTemple|HelmetEnchant|Unique|SkillGem"
$items += $economy.itemOverviews |
    ? type -NotMatch $skippedTypes -PipelineVariable group |
    % lines |
    select name, chaos, (calc type {$group.type}), (calc variant { $_.variant -split ", " })

# Synthesized shard prices
$basic = $currency | ? variant -In Basic,GodTier
$orbToShard = $stacks `
| ? name -match " Shard$" `
| % {
        $chaos = if($_.name -eq "Chaos Shard") {1} else {
            $commonPart = $_.name -replace " Shard",""
            $basic | ? name -match $commonPart | select -First 1 -expand chaos
        }
        [PSCustomObject]@{
            name = $_.name
            chaos = $chaos / $_.size
            type = "Currency"
            variant = "Shard"
        }
    }
$items += $orbToShard

# Get a summary of variants:
# $items | group type | fl Name,@{n="Variants";e={$_.group.variant | Sort-Object -Unique | Join-String -Separator ", "}}


# Calculate tiers
# My note progression is C D# E F# G Bb
# I want Chaos Orb and Divine orb to be anchors at C4 and C5.
$div = $items | where name -eq "Divine Orb" | % chaos
# I want the lowest note to be Bb2.
# I'll define tiers as higher is better.
# So Bb2 is T1, C3 is T2, C4 is T8 (chaos), C5 is T14 (div), C6 is T20.
# I'll use an exponential scale to divide tiers.
# x^0=1 (chaos) at T8 and x^6 = div at T14
$base=[math]::Pow($div, 1/6) # sixth root
$tierBreakpoints = 1..20 | % { [pscustomobject]@{
    Tier=$_
    Chaos=($_ -eq 1 ? 0 : [math]::pow($base,$_-8))
} }
function toTier($value) {
    @($tierBreakpoints | ? chaos -LE $value)[-1].Tier
}

$tierprop = calc tier { toTier $_.chaos }
$tiered = $items | select *, $tierprop
# Test the math:
# $tiered | group tier | select name, {$_.group | measure chaos -Minimum -Maximum | select * } | select name -ExpandProperty "$*" | select Name,@{n="BreakPoint";e={$tierBreakpoints | where t -eq $_.Name | % c} },Minimum,Maximum | ft *,{$_.Minimum -ge $_.BreakPoint}

# Override cheap maps
$tiered |
    ? type -Like "*Map" |
    ? chaos -lt 10 |
    % { $_.tier = (@($_.variant -like "T*")[0] -replace "T","" -as [int]) }

# Generate item stacks for each tier
$stacks = Invoke-RestMethod "https://www.poewiki.net/index.php?title=Special:CargoExport&tables=stackables&&fields=stackables.stack_size%3Dsize%2C+stackables._pageName%3Dname%2C&where=stackables._pageNamespace+%3D+0&limit=2000&format=json"
$stacksLookup = @{}
$stacks | ? size -gt 1 | % { $stacksLookup[$_.name] = $_.size }
$stackable = $tiered | ? name -in $stacksLookup.Keys
$stacked = $stackable | % {
    $item = $_
    $fullStack=$stacksLookup[$item.name]
    $fullStackValue = $item.chaos * $fullStack
    $maxTier = toTier $fullStackValue
    if ($maxTier -eq $item.tier) { return }
    $tierBreakpoints | ? tier -in (($item.tier+1)..$maxTier) | % {
        $tierStack = [int][math]::Ceiling($_.chaos/$item.chaos)
        $tier = $_.tier
        $item | select -ExcludeProperty chaos,tier *,
            (calc chaos {$_.chaos*$tierStack}),
            (calc tier {$tier}),
            (calc stack {$tierStack})
    }
}
$tiered += $stacked

$tiered |
    Sort-Object tier,stack -Descending |
    select -First 100 | % {
        "Show"
        "BaseType ""{0}""" -f $_.name
        if ($_.stack) { "StackSize >= {0}" -f $_.stack }
        "CustomAlertSound ""{0}-{1:00}.wav""" -f $_.type,$_.tier
        "Continue"
        ""
    } | Out-File jazz.filter -Encoding utf8 -Force
