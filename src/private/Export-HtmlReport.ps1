function Export-HtmlReport {
    param(
        [Parameter(Mandatory)][System.Collections.Generic.List[PSCustomObject]]$Results,
        [Parameter(Mandatory)][string]$OutputPath,
        [string]$ServerUrl = "",
        [string]$Collection = ""
    )

    $totalBuilds    = ($Results | Where-Object { $_."Кол-во билдов" -ge 0 } |
                       Measure-Object "Кол-во билдов" -Sum).Sum
    $activeProjects = ($Results | Where-Object { $_.Состояние -eq "wellFormed" }).Count
    $totalProjects  = $Results.Count
    $generatedAt    = Get-Date -Format "dd.MM.yyyy HH:mm:ss"

    # Строки таблицы
    $tableRows = foreach ($r in ($Results | Sort-Object "Кол-во билдов" -Descending)) {
        $stateLabel = if ($r.Состояние -eq "wellFormed") {
            '<span class="badge badge-ok">wellFormed</span>'
        } else {
            "<span class='badge badge-warn'>$($r.Состояние)</span>"
        }

        $barWidth = if ($totalBuilds -gt 0) {
            [math]::Round(($r."Кол-во билдов" / $totalBuilds) * 100, 1)
        } else { 0 }

        @"
        <tr>
            <td>$($r."№")</td>
            <td class="project-name">$($r.Проект)</td>
            <td>$stateLabel</td>
            <td class="count">$($r."Кол-во билдов")</td>
            <td class="bar-cell">
                <div class="bar-wrap">
                    <div class="bar" style="width:$($barWidth)%"></div>
                    <span class="bar-label">$barWidth%</span>
                </div>
            </td>
        </tr>
"@
    }

    $html = @"
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure DevOps — Статистика билдов</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0d1117;
            color: #c9d1d9;
            padding: 32px 24px;
        }

        .header {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 32px;
        }
        .header-icon { font-size: 2rem; }
        .header h1 { font-size: 1.6rem; color: #f0f6fc; }
        .header p  { font-size: 0.85rem; color: #8b949e; margin-top: 4px; }

        .cards {
            display: flex;
            gap: 16px;
            margin-bottom: 32px;
            flex-wrap: wrap;
        }
        .card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 10px;
            padding: 18px 24px;
            min-width: 160px;
            flex: 1;
        }
        .card-label { font-size: 0.78rem; color: #8b949e; text-transform: uppercase; letter-spacing: .05em; }
        .card-value { font-size: 2rem; font-weight: 700; margin-top: 6px; color: #f0f6fc; }
        .card-value.accent { color: #58a6ff; }
        .card-value.green  { color: #3fb950; }

        .table-wrap {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 10px;
            overflow: hidden;
        }
        .table-title {
            padding: 16px 20px;
            font-size: 0.95rem;
            font-weight: 600;
            color: #f0f6fc;
            border-bottom: 1px solid #30363d;
        }

        table { width: 100%; border-collapse: collapse; }
        thead th {
            background: #0d1117;
            padding: 10px 16px;
            text-align: left;
            font-size: 0.78rem;
            color: #8b949e;
            text-transform: uppercase;
            letter-spacing: .05em;
            border-bottom: 1px solid #30363d;
        }
        tbody tr { transition: background .15s; }
        tbody tr:hover { background: #1c2128; }
        tbody td {
            padding: 11px 16px;
            font-size: 0.9rem;
            border-bottom: 1px solid #21262d;
            vertical-align: middle;
        }
        tbody tr:last-child td { border-bottom: none; }

        .project-name { font-weight: 500; color: #58a6ff; }
        .count        { font-weight: 700; color: #f0f6fc; text-align: right; }

        .badge {
            display: inline-block;
            padding: 2px 10px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        .badge-ok   { background: #1a4027; color: #3fb950; border: 1px solid #2ea043; }
        .badge-warn { background: #3d1f00; color: #d29922; border: 1px solid #9e6a03; }

        .bar-cell { min-width: 200px; }
        .bar-wrap  { display: flex; align-items: center; gap: 8px; }
        .bar       { height: 8px; border-radius: 4px; background: #1f6feb; min-width: 2px; transition: width .3s; }
        .bar-label { font-size: 0.75rem; color: #8b949e; white-space: nowrap; }

        .footer {
            margin-top: 24px;
            text-align: right;
            font-size: 0.78rem;
            color: #484f58;
        }
    </style>
</head>
<body>

<div class="header">
    <div class="header-icon">⚙️</div>
    <div>
        <h1>Azure DevOps Server — Статистика билдов</h1>
        <p>$ServerUrl / $Collection &nbsp;·&nbsp; Сформировано: $generatedAt</p>
    </div>
</div>

<div class="cards">
    <div class="card">
        <div class="card-label">Всего проектов</div>
        <div class="card-value accent">$totalProjects</div>
    </div>
    <div class="card">
        <div class="card-label">Активных</div>
        <div class="card-value">$activeProjects</div>
    </div>
    <div class="card">
        <div class="card-label">Всего билдов</div>
        <div class="card-value green">$totalBuilds</div>
    </div>
</div>

<div class="table-wrap">
    <div class="table-title">📋 Детализация по проектам</div>
    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Проект</th>
                <th>Состояние</th>
                <th style="text-align:right">Билды</th>
                <th>Доля</th>
            </tr>
        </thead>
        <tbody>
            $($tableRows -join "`n")
        </tbody>
    </table>
</div>

<div class="footer">
    Сгенерировано скриптом Get-AzdoBuildStats.ps1 · $generatedAt
</div>

</body>
</html>
"@

    # Создать папку если не существует
    $dir = Split-Path $OutputPath -Parent
    if ($dir -and !(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`n✅ HTML-отчёт сохранён: $OutputPath" -ForegroundColor Green
}
