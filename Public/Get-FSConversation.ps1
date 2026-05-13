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

    .PARAMETER OutFile
        Write the full conversation as JSON (UTF-8) to this file path instead of
        returning an object to the pipeline. Creates parent directories if needed.

    .EXAMPLE
        Get-FSConversation -Id 17064

    .EXAMPLE
        Get-FSConversation -Id 17064 -Embed "threads,tags"

    .EXAMPLE
        Get-FSConversation -Id 17064 -Embed "threads,tags" -OutFile "C:\temp\ticket-17064.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Id,

        [string]$Embed = "threads",

        [string]$OutFile
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

    if ($OutFile) {
        $parent = Split-Path -Path $OutFile -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }
        $response | ConvertTo-Json -Depth 10 | Set-Content -Path $OutFile -Encoding UTF8
        Write-Verbose "Conversation $Id written to $OutFile"
    }
    else {
        return $response
    }
}
