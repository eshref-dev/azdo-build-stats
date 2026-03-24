#Requires -Modules Pester

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath

    . (Join-Path $here "..\src\private\Get-AllProjects.ps1")
    . (Join-Path $here "..\src\private\Get-ProjectBuildCount.ps1")
    . (Join-Path $here "..\src\private\Export-HtmlReport.ps1")

    # ── Временная директория внутри tests\ ──────────────────────
    $script:TempDir = Join-Path $here "tmp"

    # Очищаем перед каждым запуском
    if (Test-Path $script:TempDir) {
        Remove-Item $script:TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null

    # ── Общие параметры ──────────────────────────────────────────
    $script:BaseUrl    = "http://azdo.test.local/DefaultCollection"
    $script:ApiVersion = "api-version=6.0"
    $script:Headers    = @{
        Authorization  = "Basic dGVzdDp0ZXN0"
        "Content-Type" = "application/json"
    }

    $script:CommonParams = @{
        BaseUrl    = $script:BaseUrl
        Headers    = $script:Headers
        ApiVersion = $script:ApiVersion
    }

    # ── Фиктивные данные ─────────────────────────────────────────
    $script:FakeProjects = @(
        [PSCustomObject]@{ name = "BackendService"; state = "wellFormed" }
        [PSCustomObject]@{ name = "FrontendApp";    state = "wellFormed" }
        [PSCustomObject]@{ name = "LegacyProject";  state = "wellFormed" }
    )

    $script:FakeResults = [System.Collections.Generic.List[PSCustomObject]]@(
        [PSCustomObject]@{ "№" = 1; "Проект" = "BackendService"; "Состояние" = "wellFormed"; "Кол-во билдов" = 4812 }
        [PSCustomObject]@{ "№" = 2; "Проект" = "FrontendApp";    "Состояние" = "wellFormed"; "Кол-во билдов" = 2340 }
        [PSCustomObject]@{ "№" = 3; "Проект" = "LegacyProject";  "Состояние" = "wellFormed"; "Кол-во билдов" = 12   }
    )
}

AfterAll {
    # Очищаем tmp после завершения всех тестов
    if (Test-Path $script:TempDir) {
        # Remove-Item $script:TempDir -Recurse -Force
    }
}

# ─────────────────────────────────────────────────────────────────
#  1. Get-AllProjects
# ─────────────────────────────────────────────────────────────────
Describe "Get-AllProjects" {

    Context "Успешный запрос — один батч проектов" {

        BeforeAll {
            Mock Invoke-WebRequest {
                [PSCustomObject]@{
                    Content = (@{
                        value = @(
                            @{ name = "BackendService"; state = "wellFormed" }
                            @{ name = "FrontendApp";    state = "wellFormed" }
                        )
                        count = 2
                    } | ConvertTo-Json -Depth 5)
                    Headers = @{}
                }
            }
        }

        It "Возвращает корректное количество проектов" {
            $result = Get-AllProjects @script:CommonParams
            $result.Count | Should -Be 2
        }

        It "Содержит проект BackendService" {
            $result = Get-AllProjects @script:CommonParams
            $result.name | Should -Contain "BackendService"
        }

        It "Вызывает Invoke-WebRequest ровно 1 раз при одной странице" {
            Get-AllProjects @script:CommonParams
            Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context "Пагинация — два батча проектов" {

        BeforeAll {
            $script:callCount = 0

            Mock Invoke-WebRequest {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    [PSCustomObject]@{
                        Content = (@{
                            value = @(@{ name = "Project1"; state = "wellFormed" })
                            count = 1
                        } | ConvertTo-Json -Depth 5)
                        Headers = @{ "x-ms-continuationtoken" = "token_page2" }
                    }
                } else {
                    [PSCustomObject]@{
                        Content = (@{
                            value = @(@{ name = "Project2"; state = "wellFormed" })
                            count = 1
                        } | ConvertTo-Json -Depth 5)
                        Headers = @{}
                    }
                }
            }
        }

        It "Возвращает проекты со всех страниц пагинации" {
            $script:callCount = 0
            $result = Get-AllProjects @script:CommonParams
            $result.Count | Should -Be 2
        }

        It "Вызывает Invoke-WebRequest дважды при двух страницах" {
            $script:callCount = 0
            Get-AllProjects @script:CommonParams
            Should -Invoke Invoke-WebRequest -Times 2 -Exactly
        }
    }

    Context "Обработка ошибок" {

        BeforeAll {
            Mock Invoke-WebRequest { throw "Connection refused" }
        }

        It "Выбрасывает исключение при недоступном сервере" {
            { Get-AllProjects @script:CommonParams } | Should -Throw
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  2. Get-ProjectBuildCount
# ─────────────────────────────────────────────────────────────────
Describe "Get-ProjectBuildCount" {

    Context "Проект с небольшим количеством билдов (одна страница)" {

        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{ count = 42; value = @() }
            }
        }

        It "Возвращает корректное число билдов" {
            $result = Get-ProjectBuildCount -ProjectName "BackendService" @script:CommonParams
            $result | Should -Be 42
        }

        It "Результат является целым числом" {
            $result = Get-ProjectBuildCount -ProjectName "BackendService" @script:CommonParams
            $result | Should -BeOfType [int]
        }

        It "Вызывает Invoke-RestMethod ровно 1 раз" {
            Get-ProjectBuildCount -ProjectName "BackendService" @script:CommonParams
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        }
    }

    Context "Проект с большим количеством билдов (несколько страниц)" {

        BeforeAll {
            $script:pageCallCount = 0

            Mock Invoke-RestMethod {
                $script:pageCallCount++
                if ($script:pageCallCount -le 2) {
                    [PSCustomObject]@{ count = 5000; value = @() }
                } else {
                    [PSCustomObject]@{ count = 312; value = @() }
                }
            }
        }

        It "Суммирует билды по всем страницам пагинации" {
            $script:pageCallCount = 0
            $result = Get-ProjectBuildCount -ProjectName "BigProject" @script:CommonParams
            $result | Should -Be 10312  # 5000 + 5000 + 312
        }
    }

    Context "Проект без билдов" {

        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{ count = 0; value = @() }
            }
        }

        It "Возвращает 0 для пустого проекта" {
            $result = Get-ProjectBuildCount -ProjectName "EmptyProject" @script:CommonParams
            $result | Should -Be 0
        }
    }

    Context "Обработка ошибок" {

        BeforeAll {
            Mock Invoke-RestMethod { throw "403 Forbidden" }
        }

        It "Выбрасывает исключение при отказе в доступе" {
            { Get-ProjectBuildCount -ProjectName "PrivateProject" @script:CommonParams } |
                Should -Throw
        }
    }
}

# ─────────────────────────────────────────────────────────────────
#  3. Export-HtmlReport
# ─────────────────────────────────────────────────────────────────
Describe "Export-HtmlReport" {

    BeforeAll {
        $script:HtmlFile = Join-Path $script:TempDir "report_test.html"

        Export-HtmlReport `
            -Results    $script:FakeResults `
            -OutputPath $script:HtmlFile `
            -ServerUrl  "http://azdo.test.local" `
            -Collection "DefaultCollection"

        $script:HtmlContent = Get-Content $script:HtmlFile -Raw
    }

    It "Создаёт HTML-файл по указанному пути" {
        Test-Path $script:HtmlFile | Should -Be $true
    }

    It "Файл не пустой" {
        $script:HtmlContent.Length | Should -BeGreaterThan 0
    }

    It "Содержит корректный DOCTYPE" {
        $script:HtmlContent | Should -Match "<!DOCTYPE html>"
    }

    It "Содержит все названия проектов" {
        $script:HtmlContent | Should -Match "BackendService"
        $script:HtmlContent | Should -Match "FrontendApp"
        $script:HtmlContent | Should -Match "LegacyProject"
    }

    It "Содержит корректное суммарное число билдов (7164)" {
        $script:HtmlContent | Should -Match "7164"
    }

    It "Содержит URL сервера в отчёте" {
        $script:HtmlContent | Should -Match "azdo.test.local"
    }

    It "Автоматически создаёт вложенную папку если не существует" {
        $deepPath = Join-Path $script:TempDir "nested\sub\report.html"
        Export-HtmlReport -Results $script:FakeResults -OutputPath $deepPath
        Test-Path $deepPath | Should -Be $true
    }

    It "Файл сохранён в кодировке UTF-8" {
        $raw = [System.IO.File]::ReadAllText($script:HtmlFile, [System.Text.Encoding]::UTF8)
        $raw | Should -Match "Статистика"
    }
}

# ─────────────────────────────────────────────────────────────────
#  4. Проверка выходных файлов (CSV + HTML)
# ─────────────────────────────────────────────────────────────────
Describe "Проверка выходных файлов" {

    BeforeAll {
        $script:CsvOut  = Join-Path $script:TempDir "report.csv"
        $script:HtmlOut = Join-Path $script:TempDir "report.html"

        # Генерируем файлы один раз для всех тестов в блоке
        $script:FakeResults | Sort-Object "Кол-во билдов" -Descending |
            Export-Csv -Path $script:CsvOut -NoTypeInformation -Encoding UTF8

        Export-HtmlReport `
            -Results    $script:FakeResults `
            -OutputPath $script:HtmlOut `
            -ServerUrl  "http://azdo.test.local" `
            -Collection "DefaultCollection"

        $script:Csv  = Import-Csv $script:CsvOut
        $script:Html = Get-Content $script:HtmlOut -Raw
    }

    Context "CSV-файл" {

        It "Файл существует и не пустой" {
            Test-Path $script:CsvOut | Should -Be $true
            (Get-Item $script:CsvOut).Length | Should -BeGreaterThan 0
        }

        It "Содержит правильное количество строк" {
            $script:Csv.Count | Should -Be 3
        }

        It "Содержит все обязательные колонки" {
            $cols = $script:Csv[0].PSObject.Properties.Name
            $cols | Should -Contain "№"
            $cols | Should -Contain "Проект"
            $cols | Should -Contain "Состояние"
            $cols | Should -Contain "Кол-во билдов"
        }

        It "Содержит все названия проектов" {
            $script:Csv."Проект" | Should -Contain "BackendService"
            $script:Csv."Проект" | Should -Contain "FrontendApp"
            $script:Csv."Проект" | Should -Contain "LegacyProject"
        }

        It "Числовые значения билдов корректны" {
            $row = $script:Csv | Where-Object { $_.Проект -eq "BackendService" }
            [int]$row."Кол-во билдов" | Should -Be 4812
        }

        It "Состояние всех проектов — wellFormed" {
            $script:Csv | ForEach-Object {
                $_.Состояние | Should -Be "wellFormed"
            }
        }

        It "Строки отсортированы по убыванию билдов" {
            $counts = $script:Csv."Кол-во билдов" | ForEach-Object { [int]$_ }
            $counts | Should -Be ($counts | Sort-Object -Descending)
        }

        It "Файл читается в UTF-8 без потери кириллицы" {
            $raw = [System.IO.File]::ReadAllText($script:CsvOut, [System.Text.Encoding]::UTF8)
            $raw | Should -Match "Проект"
            $raw | Should -Match "Состояние"
        }
    }

    Context "HTML-файл" {

        It "Файл существует и не пустой" {
            Test-Path $script:HtmlOut | Should -Be $true
            (Get-Item $script:HtmlOut).Length | Should -BeGreaterThan 0
        }

        It "Корректная структура HTML" {
            $script:Html | Should -Match "<!DOCTYPE html>"
            $script:Html | Should -Match "<html"
            $script:Html | Should -Match "</html>"
            $script:Html | Should -Match "<head>"
            $script:Html | Should -Match "<body>"
        }

        It "Задана кодировка UTF-8 в мета-теге" {
            $script:Html | Should -Match 'charset="UTF-8"'
        }

        It "Содержит заголовок и упоминание Azure DevOps" {
            $script:Html | Should -Match "<title>"
            $script:Html | Should -Match "Azure DevOps"
        }

        It "Содержит все названия проектов" {
            $script:Html | Should -Match "BackendService"
            $script:Html | Should -Match "FrontendApp"
            $script:Html | Should -Match "LegacyProject"
        }

        It "Содержит числовые значения билдов" {
            $script:Html | Should -Match "4812"
            $script:Html | Should -Match "2340"
            $script:Html | Should -Match "12"
        }

        It "Содержит суммарное число билдов (7164)" {
            $script:Html | Should -Match "7164"
        }

        It "Содержит URL сервера" {
            $script:Html | Should -Match "azdo.test.local"
        }

        It "Содержит карточки со статистикой" {
            $script:Html | Should -Match 'class="card"'
            $script:Html | Should -Match 'class="card-value'
        }

        It "Содержит таблицу с данными" {
            $script:Html | Should -Match "<table>"
            $script:Html | Should -Match "<thead>"
            $script:Html | Should -Match "<tbody>"
        }

        It "Содержит прогресс-бары" {
            $script:Html | Should -Match 'class="bar"'
        }

        It "Содержит бейджи состояния" {
            $script:Html | Should -Match 'class="badge badge-ok"'
        }

        It "Файл читается в UTF-8 без потери кириллицы" {
            $raw = [System.IO.File]::ReadAllText($script:HtmlOut, [System.Text.Encoding]::UTF8)
            $raw | Should -Match "Статистика"
            $raw | Should -Match "Состояние"
        }
    }
}
