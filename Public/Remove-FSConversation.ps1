function Remove-FSConversation {
    <#
    .SYNOPSIS
        Delete a FreeScout conversation.

    .PARAMETER Id
        The conversation ID to delete.

    .PARAMETER Confirm
        Bypass the confirmation prompt.

    .EXAMPLE
        Remove-FSConversation -Id 17064

    .EXAMPLE
        Remove-FSConversation -Id 17064 -Confirm
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Id,

        [switch]$Confirm
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    if (-not $Confirm) {
        $answer = Read-Host "Are you sure you want to delete conversation $Id? (y/N)"
        if ($answer -notmatch '^[yY]') {
            Write-Host "Cancelled."
            return
        }
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey
    $uri = "$($script:FSConfig.BaseUrl)/api/conversations/$Id"

    Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete
}
