function Get-FSConversation {
    <#
    .SYNOPSIS
        Retrieve a single conversation from FreeScout.

    .DESCRIPTION
        Gets full conversation details including threads, timelogs, and/or tags.

    .PARAMETER Id
        The conversation ID.

    .PARAMETER Embed
        Comma-separated list of related data to include: threads, timelogs, tags.
        Defaults to "threads".

    .EXAMPLE
        Get-FSConversation -Id 17064

    .EXAMPLE
        Get-FSConversation -Id 17064 -Embed "threads,tags"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Id,

        [string]$Embed = "threads"
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey

    $uri = "$($script:FSConfig.BaseUrl)/api/conversations/$Id"
    if ($Embed) {
        $uri += "?embed=$Embed"
    }

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $response
}
