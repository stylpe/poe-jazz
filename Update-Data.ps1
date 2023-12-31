Invoke-RestMethod -OutFile stacks.json "https://www.poewiki.net/index.php?title=Special:CargoExport&tables=stackables&&fields=stackables.stack_size%2C+stackables._pageName%2C&where=stackables._pageNamespace+%3D+0&limit=2000&format=json"
Invoke-RestMethod -OutFile currency.json "https://poe.ninja/api/data/currencyoverview?league=Affliction&type=Currency"
Invoke-RestMethod -OutFile fragments.json "https://poe.ninja/api/data/currencyoverview?league=Affliction&type=Fragment"
