function Get-AllProjects {
    $allProjects      = [System.Collections.Generic.List[object]]::new()
    $continuationToken = $null

    do {
        $url = "$BaseUrl/_apis/projects?`$top=100&$ApiVersion"
        if ($continuationToken) {
            $url += "&continuationToken=$continuationToken"
        }

        # Используем Invoke-WebRequest чтобы читать заголовок пагинации
        $response = Invoke-WebRequest -Uri $url -Headers $Headers `
                        -Method Get -UseBasicParsing
        $data = ($response.Content | ConvertFrom-Json)

        foreach ($p in $data.value) { $allProjects.Add($p) }

        $continuationToken = $response.Headers["x-ms-continuationtoken"]

    } while ($continuationToken)

    return $allProjects
}