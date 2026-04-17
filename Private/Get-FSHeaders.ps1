function Get-FSHeaders {
    <#
    .SYNOPSIS
        Build standard FreeScout API request headers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [switch]$WithContentType
    )

    $headers = @{
        "X-FreeScout-API-Key" = $ApiKey
        "Accept"              = "application/json"
    }

    if ($WithContentType) {
        $headers["Content-Type"] = "application/json"
    }

    return $headers
}
