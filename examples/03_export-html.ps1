# Генерация HTML-отчёта с датой в имени файла
$scriptPath = "$PSScriptRoot\..\src\Get-AzdoBuildStats.ps1"
$date       = Get-Date -Format "yyyy-MM-dd"
$outputFile = "$PSScriptRoot\..\output\report_$date.html"

& $scriptPath `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        $env:AZDO_PAT `
    -ExportHtml $outputFile

# Открыть отчёт в браузере сразу после генерации
Start-Process $outputFile
