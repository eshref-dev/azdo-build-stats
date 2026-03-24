# Экспорт результатов в CSV с датой в имени файла
$scriptPath = "$PSScriptRoot\..\src\Get-AzdoBuildStats.ps1"
$date       = Get-Date -Format "yyyy-MM-dd"
$outputFile = "$PSScriptRoot\..\output\builds_$date.csv"

& $scriptPath `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        $env:AZDO_PAT `
    -ExportCsv  $outputFile
