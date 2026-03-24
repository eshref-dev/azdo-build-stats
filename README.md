# azdo-build-stats 🔧

> PowerShell-скрипт для получения статистики билдов по всем проектам Azure DevOps Server 2022

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![AzDO](https://img.shields.io/badge/Azure%20DevOps-Server%202022-0078d4)

## Требования
- PowerShell 5.1+ или 7+
- PAT с правами: `Project (Read)`, `Build (Read)`

## Быстрый старт
```powershell
.\src\Get-AzdoBuildStats.ps1 `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## Разработка
См. [CONTRIBUTING.md](./CONTRIBUTING.md) — запуск тестов, структура проекта, правила PR.