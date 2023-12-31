$data = Get-Content ./currency.json | ConvertFrom-Json
$div = $data.lines | where detailsId -eq "divine-orb" | % chaosEquivalent
$tiered = $data.lines `
    | select currencyTypeName, detailsId, chaosEquivalent, @{l="log"; e={[math]::Log($_.chaosEquivalent,$div)}} `
    | select *,@{l="tier";e={[int] [math]::Max([math]::Floor($_.log*6)+8,0)}}

$stacks=@{}
Get-Content ./stacks.json `
    | ConvertFrom-Json `
    | % {$stacks[$_._pageName]=$_."stack size"}

$typed=$tiered | select *, `
    @{l="stack";e={$stacks[$_.currencyTypeName]}}, `
    @{l="subtype";e={ switch -Regex ($_.currencyTypeName){
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

$typed | Sort-Object subtype,currencyTypeName | ft currencyTypeName -GroupBy subtype
