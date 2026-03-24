<#
.SYNOPSIS
    Получает список всех проектов Azure DevOps Server и выводит
    общее количество билдов по каждому проекту.

.PARAMETER ServerUrl
    URL вашего Azure DevOps Server (без слэша в конце).
    Пример: http://azdo.company.local

.PARAMETER Collection
    Имя коллекции. Обычно "DefaultCollection".

.PARAMETER PAT
    Personal Access Token с правами: Project (Read), Build (Read).
#>

param(
    [Parameter(Mandatory)][string]$ServerUrl,
    [string]$Collection  = "DefaultCollection",
    [Parameter(Mandatory)][string]$PAT,
    [string]$ExportCsv,
    [string]$ExportHtml   
)

#region --- Подключение вынесенных функций ---
# Подключение через dot-sourcing
. "$PSScriptRoot\private\Get-AllProjects.ps1"
. "$PSScriptRoot\private\Get-ProjectBuildCount.ps1"
. "$PSScriptRoot\private\Export-HtmlReport.ps1"

#endregion

#region --- Инициализация ---

$ErrorActionPreference = "Stop"
$ApiVersion            = "api-version=6.0"
$BaseUrl               = "$ServerUrl/$Collection"

# Basic-аутентификация через PAT
$EncodedPAT = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes(":$PAT")
)
$Headers = @{
    Authorization  = "Basic $EncodedPAT"
    "Content-Type" = "application/json"
}

#endregion

#region --- Основная логика ---

Write-Host "`n[*] Подключение к: $BaseUrl" -ForegroundColor Cyan
Write-Host "[*] Получение списка проектов...`n" -ForegroundColor Cyan

$projects = Get-AllProjects
Write-Host "Найдено проектов: $($projects.Count)`n" -ForegroundColor Green

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

$i = 0
foreach ($project in $projects) {
    $i++
    Write-Progress -Activity "Подсчёт билдов" `
                   -Status "[$i/$($projects.Count)] $($project.name)" `
                   -PercentComplete (($i / $projects.Count) * 100)

    try {
        $buildCount = Get-ProjectBuildCount -ProjectName $project.name
    } catch {
        Write-Warning "Не удалось получить билды для '$($project.name)': $_"
        $buildCount = -1
    }

    $results.Add([PSCustomObject]@{
        "№"          = $i
        "Проект"     = $project.name
        "Состояние"  = $project.state
        "Кол-во билдов" = $buildCount
    })
}

Write-Progress -Activity "Подсчёт билдов" -Completed

#endregion

# ✅ Защита от пустого списка
if ($null -eq $results -or $results.Count -eq 0) {
    Write-Warning "Нет данных — список результатов пуст."
    return
}

$sorted = $results | Sort-Object "Кол-во билдов" -Descending
#region --- Экспорт ---

if ($ExportCsv) {
    if ($null -ne $sorted) {
        $sorted | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
        Write-Host "📄 CSV сохранён: $ExportCsv" -ForegroundColor Cyan
    } else {
        Write-Warning "Export-Csv пропущен: нет данных"
    }
}
if ($ExportCsv) {
    $sorted | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    Write-Host "📄 CSV сохранён: $ExportCsv" -ForegroundColor Cyan
}

if ($ExportHtml) {
    if ($null -ne $sorted) {
        Export-HtmlReport -Results $results `
                          -OutputPath $ExportHtml `
                          -ServerUrl $ServerUrl `
                          -Collection $Collection
    } else {
        Write-Warning "Export-Html пропущен: нет данных"
    }
}
if ($ExportHtml) {
    Export-HtmlReport -Results $results `
                      -OutputPath $ExportHtml `
                      -ServerUrl $ServerUrl `
                      -Collection $Collection
}

#endregion

#region --- Вывод результатов ---

Write-Host "`n========== Результаты ==========" -ForegroundColor Cyan

$results | Sort-Object "Кол-во билдов" -Descending `
         | Format-Table -AutoSize

$totalBuilds   = ($results | Where-Object { $_."Кол-во билдов" -ge 0 } `
                            | Measure-Object "Кол-во билдов" -Sum).Sum
$activeProjects = ($results | Where-Object { $_.Состояние -eq "wellFormed" }).Count

Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
Write-Host "Всего проектов  : $($projects.Count)" -ForegroundColor Yellow
Write-Host "Активных        : $activeProjects"     -ForegroundColor Yellow
Write-Host "Всего билдов    : $totalBuilds"         -ForegroundColor Green

#endregion
