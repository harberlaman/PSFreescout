function Get-FSUser {
    <#
    .SYNOPSIS
        List users from FreeScout.

    .DESCRIPTION
        Retrieves all users with optional filtering by email and pagination.

    .PARAMETER Email
        Filter by user email address.

    .PARAMETER Page
        Page number (defaults to 1).

    .PARAMETER PageSize
        Results per page (defaults to 50).

    .EXAMPLE
        Get-FSUser

    .EXAMPLE
        Get-FSUser -Email "agent@example.com"

    .EXAMPLE
        Get-FSUser -PageSize 10 -Page 2
    #>
    [CmdletBinding()]
    param(
        [string]$Email,
        [int]$Page,
        [int]$PageSize
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey

    $params = @()
    if ($Email)    { $params += "email=$Email" }
    if ($Page)     { $params += "page=$Page" }
    if ($PageSize) { $params += "pageSize=$PageSize" }

    $uri = "$($script:FSConfig.BaseUrl)/api/users"
    if ($params.Count -gt 0) {
        $uri += "?" + ($params -join "&")
    }

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $response
}
