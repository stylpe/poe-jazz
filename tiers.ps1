function calc([string]$name, $e) {
    return @{ name=$name; e=$e }
}

$stacks = Invoke-RestMethod "https://www.poewiki.net/index.php?title=Special:CargoExport&tables=stackables&&fields=stackables.stack_size%3Dsize%2C+stackables._pageName%3Dname%2C&where=stackables._pageNamespace+%3D+0&limit=2000&format=json"
$stacksLookup = @{}
$stacks | % {$stacksLookup[$_.name]=$_.size}

function categorize([string]$name) {
    switch -Regex ($name){
        "Mirror|Hinekora" {"god-tier";break}
        "Key|Valdo" {"key";break}
        "Goddess" {"lab";break}
        "Tainted" {"scourge";break}
        "Shard" {"shard";break}
        "Chayula|Uul|Esh|Tul|Xoph" {"abyss";break}
        "Maven's Orb|Dominance|'s Exalted|of Conflict|Eldritch|Awakener|Veiled|Enkindling"
            {"influenced";break}
        "Lifeforce|Sacred Blossom" {"harvest";break}
        "Sextant|Compass|Scouting" {"atlas";break}
        "Fragment|Memory|Crescent|Writ|Simulacrum|Timeless|Divine Vessel|Sacrifice|Crest|Mortal|Ritual"
            {"fragment";break}
        "Catalyst" {"catalyst";break}
        "Oil" {"oil";break}
        "Stacked Deck" {"card";break}
        #"Ritual" {"other";break}
        default {"basic"}
    }
}

$economy = Invoke-RestMethod "https://poe.ninja/api/data/denseoverviews?league=Affliction"

$items = $economy.currencyOverviews + $economy.itemOverviews | % {
    if ($_.type -eq "Currency") { $type = calc type {categorize $_.name} }
    else { $ptype = $_.type; $type = calc type {$ptype} }
    $stackprop = calc stack {$stacksLookup[$_.name] ?? 1}
    $_.lines | select name,variant,chaos,$type,$stackprop
}

$div = $items | where name -eq "Divine Orb" | % chaos

$tierprop = calc tier {
    [int] [math]::Max(
        [math]::Floor(
            [math]::Log($_.chaos,$div) * 6
        ) + 8, 0
    )
}
$tiered = $items | select *, $tierprop
