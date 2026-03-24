# Регистрирует задание в Task Scheduler — запуск каждый день в 07:00
$action  = New-ScheduledTaskAction `
               -Execute "pwsh.exe" `
               -Argument "-NonInteractive -File `"$PSScriptRoot\..\src\Get-AzdoBuildStats.ps1`" -ServerUrl http://azdo.company.local -Collection DefaultCollection -PAT $env:AZDO_PAT -ExportHtml C:\Reports\azdo_report.html"

$trigger = New-ScheduledTaskTrigger -Daily -At "07:00"

Register-ScheduledTask `
    -TaskName "AzdoBuildStats_DailyReport" `
    -Action   $action `
    -Trigger  $trigger `
    -RunLevel Highest `
    -Force

Write-Host "✅ Задание зарегистрировано: AzdoBuildStats_DailyReport" -ForegroundColor Green
