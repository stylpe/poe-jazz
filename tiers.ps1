$data = Get-Content ./currency.json `
    | ConvertFrom-Json `
    | % lines `
    | select @{l="name";e="currencyTypeName"}, `
        @{l="value";e="chaosEquivalent"}

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
        "Mirror|Hinekora" {"god-tier"}
        "Tainted" {"scourge";break}
        "Shard" {"shard";break}
        "Blessing" {"abyss";break}
        "Dominance|'s Exalted|of Conflict|Eldritch|Awakener|Veiled" {"influenced";break}
        "Lifeforce" {"harvest";break}
        "Sextant|Compass|Scouting" {"atlas";break}
        "Catalyst" {"catalyst";break}
        "Oil" {"oil";break}
        "Ritual" {"other";break}
        default {"basic"}
    }}}

$typed | Sort-Object subtype,name | ft name -GroupBy subtype
