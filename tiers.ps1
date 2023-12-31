function readCurrency($files) {
    $files | % {
        Get-Content $_ `
        | ConvertFrom-Json `
        | % lines `
        | select @{l="name";e="currencyTypeName"}, `
            @{l="value";e="chaosEquivalent"}
    }
}
$data = readCurrency currency.json,fragments.json
$div = $data | where name -eq "Divine Orb" | % value

$tiered = $data `
    | select *,@{l="log"; e={[math]::Log($_.value,$div)}} `
    | select *,@{l="tier";e={[int] [math]::Max([math]::Floor($_.log*6)+8,0)}}

$stacks=@{}
Get-Content ./stacks.json `
    | ConvertFrom-Json `
    | % {$stacks[$_._pageName]=$_."stack size"}

$typed=$tiered | select *, `
    @{l="stack";e={$stacks[$_.name]}}, `
    @{l="subtype";e={ switch -Regex ($_.name){
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
    }}}

$typed | Sort-Object subtype,name | ft name -GroupBy subtype
