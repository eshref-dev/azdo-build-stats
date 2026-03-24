## Запуск тестов

# Установка Pester
Install-Module Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# Все тесты
Invoke-Pester .\tests\ -Output Detailed

# Конкретный блок
Invoke-Pester .\tests\ -Output Detailed -FullNameFilter "Get-AllProjects*"

# С отчётом покрытия кода
Invoke-Pester .\tests\  -CodeCoverage (Get-ChildItem .\src -Recurse -Filter "*.ps1").FullName

## Временные файлы тестов
Создаются в tests\tmp\ и автоматически очищаются после каждого запуска.
Папка добавлена в .gitignore — не коммитить.

## Как добавить новый тест
1. Открыть tests\Get-AzdoBuildStats.Tests.ps1
2. Найти нужный Describe-блок
3. Добавить It-блок с описанием на русском
4. Использовать Mock для изоляции HTTP-запросов
