function Set-FSConfig {
    <#
    .SYNOPSIS
        Configure the FreeScout API connection.

    .DESCRIPTION
        Sets the FreeScout base URL and API key for the current session.
        Optionally configures Meilisearch for full-text search.
        Use -Persist to save the configuration to disk for future sessions.

    .PARAMETER BaseUrl
        The base URL of your FreeScout instance (e.g., https://helpdesk.example.com)

    .PARAMETER ApiKey
        Your FreeScout API key

    .PARAMETER MeilisearchHost
        The Meilisearch host URL (optional, for Search-FSMeilisearch)

    .PARAMETER MeilisearchApiKey
        The Meilisearch API key (optional, for Search-FSMeilisearch)

    .PARAMETER Persist
        Save configuration to ~/.psfreescout/config.json for future sessions

    .EXAMPLE
        Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "abc123"

    .EXAMPLE
        Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "abc123" -MeilisearchHost "http://localhost:7700" -MeilisearchApiKey "mskey" -Persist
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [Parameter(Mandatory)]
        [string]$ApiKey,

        [string]$MeilisearchHost,

        [string]$MeilisearchApiKey,

        [switch]$Persist
    )

    # Trim trailing slash from base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')

    $script:FSConfig = @{
        BaseUrl = $BaseUrl
        ApiKey  = $ApiKey
    }

    if ($MeilisearchHost -and $MeilisearchApiKey) {
        $script:FSConfig.MeilisearchHost  = $MeilisearchHost.TrimEnd('/')
        $script:FSConfig.MeilisearchApiKey = $MeilisearchApiKey
    }

    if ($Persist) {
        $configDir = Join-Path $HOME ".psfreescout"
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        $configObj = @{
            baseUrl = $BaseUrl
            apiKey  = $ApiKey
        }

        if ($MeilisearchHost -and $MeilisearchApiKey) {
            $configObj.meilisearch = @{
                host   = $MeilisearchHost.TrimEnd('/')
                apiKey = $MeilisearchApiKey
            }
        }

        $configPath = Join-Path $configDir "config.json"
        $configObj | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding utf8
        Write-Host "Configuration saved to $configPath"
    }

    Write-Host "PSFreescout configured for $BaseUrl"
}
