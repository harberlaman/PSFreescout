function Get-FSConfig {
    <#
    .SYNOPSIS
        Display the current PSFreescout configuration.

    .DESCRIPTION
        Shows the current FreeScout connection settings with API keys masked.

    .EXAMPLE
        Get-FSConfig
    #>
    [CmdletBinding()]
    param()

    if (-not $script:FSConfig) {
        Write-Warning "PSFreescout is not configured. Run Set-FSConfig first."
        return
    }

    $masked = @{
        BaseUrl = $script:FSConfig.BaseUrl
        ApiKey  = (Hide-ApiKey $script:FSConfig.ApiKey)
        MeilisearchConfigured = $false
    }

    if ($script:FSConfig.MeilisearchHost) {
        $masked.MeilisearchConfigured = $true
        $masked.MeilisearchHost       = $script:FSConfig.MeilisearchHost
        $masked.MeilisearchApiKey      = (Hide-ApiKey $script:FSConfig.MeilisearchApiKey)
    }

    [PSCustomObject]$masked
}

function Hide-ApiKey {
    param([string]$Key)
    if (-not $Key -or $Key.Length -lt 8) { return "****" }
    $Key.Substring(0, 4) + ("*" * ($Key.Length - 8)) + $Key.Substring($Key.Length - 4)
}
