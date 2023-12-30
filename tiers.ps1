$data = Get-Content ./currency.json | ConvertFrom-Json | % lines
$div = $data | where detailsId -eq "divine-orb" | % chaosEquivalent
$data | select detailsId,chaosEquivalent,@{l="log";e={[math]::Log($_.chaosEquivalent,$div)+1}} | select *,@{l="tier";e={[int] [math]::Max([math]::Floor($_.log*8),0)}} | ft detailsId,tier