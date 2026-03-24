# Минимальный запуск — только вывод в консоль
$scriptPath = "$PSScriptRoot\..\src\Get-AzdoBuildStats.ps1"

& $scriptPath `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        $env:AZDO_PAT          # PAT из переменной окружения — не хардкодим!
