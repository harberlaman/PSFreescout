function Update-FSConversation {
    <#
    .SYNOPSIS
        Update an existing FreeScout conversation's metadata.

    .PARAMETER Id
        The conversation ID to update.

    .PARAMETER Subject
        New subject line.

    .PARAMETER Status
        New status: active, pending, closed, or spam.

    .PARAMETER User
        Reassign to agent by user ID.

    .PARAMETER Tags
        Tag names to set. Replaces all existing tags.

    .EXAMPLE
        Update-FSConversation -Id 17064 -Status closed

    .EXAMPLE
        Update-FSConversation -Id 17064 -Subject "Updated subject" -User 5 -Tags "urgent","escalated"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Id,

        [string]$Subject,

        [ValidateSet("active", "pending", "closed", "spam")]
        [string]$Status,

        [int]$User,

        [string[]]$Tags
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey -WithContentType

    $bodyHash = @{}

    if ($Subject) { $bodyHash.subject = $Subject }
    if ($Status)  { $bodyHash.status = $Status }
    if ($User)    { $bodyHash.user = $User }
    if ($PSBoundParameters.ContainsKey('Tags')) { $bodyHash.tags = @($Tags) }

    if ($bodyHash.Count -eq 0) {
        Write-Error "At least one parameter to update must be specified."
        return
    }

    $body = $bodyHash | ConvertTo-Json -Depth 5
    $uri = "$($script:FSConfig.BaseUrl)/api/conversations/$Id"

    Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $body

    # Return the updated conversation object
    Get-FSConversation -Id $Id
}
