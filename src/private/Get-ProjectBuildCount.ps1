function Get-ProjectBuildCount {
    param([string]$ProjectName)

    $totalCount = 0
    $pageSize   = 5000   # максимум за один запрос
    $skip       = 0

    do {
        $url = "$BaseUrl/$([Uri]::EscapeDataString($ProjectName))/_apis/build/builds" +
               "?`$top=$pageSize&`$skip=$skip&$ApiVersion"

        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get

        $fetched     = $response.count
        $totalCount += $fetched
        $skip       += $pageSize

    } while ($fetched -eq $pageSize)   # если меньше — страниц больше нет

    return $totalCount
}