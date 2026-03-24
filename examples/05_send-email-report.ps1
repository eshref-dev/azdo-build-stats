# Генерирует HTML-отчёт и отправляет его письмом
$scriptPath = "$PSScriptRoot\..\src\Get-AzdoBuildStats.ps1"
$reportFile = "$env:TEMP\azdo_report.html"

& $scriptPath `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        $env:AZDO_PAT `
    -ExportHtml $reportFile

$mailParams = @{
    From       = "devops-bot@company.local"
    To         = "team@company.local"
    Subject    = "AzDO Build Stats — $(Get-Date -Format 'dd.MM.yyyy')"
    Body       = Get-Content $reportFile -Raw
    BodyAsHtml = $true
    SmtpServer = "smtp.company.local"
}

Send-MailMessage @mailParams
Write-Host "📧 Письмо отправлено" -ForegroundColor Green
