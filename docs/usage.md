# Руководство по использованию

## Требования

- PowerShell **5.1+** или **7.x** (рекомендуется 7.x)
- Доступ к Azure DevOps Server 2022 по сети
- Personal Access Token (PAT) с правами:
  - `Project` → Read
  - `Build` → Read

---

## Получение PAT-токена

1. Войдите в Azure DevOps Server → нажмите на аватар (правый верхний угол)
2. Выберите **Personal Access Tokens → New Token**
3. Укажите имя, срок действия и права: `Project (Read)`, `Build (Read)`
4. Скопируйте токен — он показывается **один раз**

> ⚠️ Никогда не вставляйте PAT напрямую в скрипт и не коммитьте его в Git.  
> Используйте переменную окружения `$env:AZDO_PAT`.

---

## Установка

```powershell
# Клонировать репозиторий
git clone [https://github.com/your-org/azdo-build-stats.git](https://github.com/eshref-dev/azdo-build-stats.git)
cd azdo-build-stats

# Убедиться что PowerShell видит скрипты
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## Параметры запуска

| Параметр      | Тип      | Обязательный | По умолчанию        | Описание                          |
|---------------|----------|:---:|---------------------|-----------------------------------|
| `-ServerUrl`  | `string` | ✅  | —                   | URL сервера без слэша в конце     |
| `-Collection` | `string` | ❌  | `DefaultCollection` | Имя коллекции AzDO                |
| `-PAT`        | `string` | ✅  | —                   | Personal Access Token             |
| `-ExportCsv`  | `string` | ❌  | —                   | Путь для сохранения CSV-файла     |
| `-ExportHtml` | `string` | ❌  | —                   | Путь для сохранения HTML-отчёта   |

---

## Примеры запуска

### Минимальный — только вывод в консоль
```powershell
.\src\Get-AzdoBuildStats.ps1 `
    -ServerUrl "http://azdo.company.local" `
    -PAT       $env:AZDO_PAT
```

### С экспортом в HTML и CSV
```powershell
.\src\Get-AzdoBuildStats.ps1 `
    -ServerUrl  "http://azdo.company.local" `
    -Collection "DefaultCollection" `
    -PAT        $env:AZDO_PAT `
    -ExportHtml ".\output\report.html" `
    -ExportCsv  ".\output\report.csv"
```

### Через переменные окружения (рекомендуется для CI)
```powershell
$env:AZDO_PAT = "ваш_токен"

.\src\Get-AzdoBuildStats.ps1 `
    -ServerUrl "http://azdo.company.local" `
    -PAT       $env:AZDO_PAT
```

---

## Как читать вывод

```
========== Результаты ===========

 №   Проект              Состояние    Кол-во билдов
 --   -------             ---------    -------------
  1   BackendService      wellFormed            4812
  2   FrontendApp         wellFormed            2340
  3   LegacyProject       wellFormed              12

─────────────────────────────────
Всего проектов  : 3
Активных        : 3
Всего билдов    : 7164
```

- **Кол-во билдов** — все билды за всё время, включая ручные и автоматические
- **Состояние `wellFormed`** — проект активен и доступен
- Значение `-1` означает ошибку при запросе (нет доступа или проект недоступен)

---

## HTML-отчёт

После запуска с параметром `-ExportHtml` откройте файл в браузере:

```powershell
Start-Process ".\output\report.html"
```

Отчёт содержит:
- Карточки с итоговыми цифрами (проекты / активные / билды)
- Таблицу с сортировкой по количеству билдов
- Прогресс-бар с долей каждого проекта от общего числа

---

## Автоматический запуск по расписанию

Используйте готовый пример из папки `examples/`:

```powershell
# Создаёт задание в Task Scheduler — каждый день в 07:00
.\examples\04_scheduled-task.ps1
```

---

## Возможные ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `401 Unauthorized` | Неверный PAT или истёк срок | Перевыпустить токен в AzDO |
| `404 Not Found` | Неверный URL или коллекция | Проверить `-ServerUrl` и `-Collection` |
| `Could not establish trust relationship` | Самоподписанный SSL-сертификат | Добавить в скрипт `[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}` |
| Билды `-1` у некоторых проектов | Нет права `Build (Read)` на проект | Расширить права PAT |

---

## Переменные окружения

Рекомендуется хранить чувствительные данные в переменных окружения,
а не передавать напрямую в параметрах:

```powershell
# Установить на время сессии
$env:AZDO_PAT        = "xxxxxxxxxx"
$env:AZDO_SERVER_URL = "http://azdo.company.local"

# Установить постоянно (для текущего пользователя)
[System.Environment]::SetEnvironmentVariable("AZDO_PAT", "xxxxxxxxxx", "User")
```
