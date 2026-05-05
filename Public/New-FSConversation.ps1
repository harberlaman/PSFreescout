function New-FSConversation {
    <#
    .SYNOPSIS
        Create a new conversation (ticket) in FreeScout.

    .PARAMETER Subject
        The conversation subject line.

    .PARAMETER Customer
        Customer email address.

    .PARAMETER Text
        Initial message body.

    .PARAMETER Type
        Conversation type: email, phone, or chat. Defaults to email.

    .PARAMETER MailboxId
        The mailbox ID to create the conversation in.

    .PARAMETER User
        Agent user ID to assign the conversation to.

    .PARAMETER Status
        Conversation status: active, pending, or closed. Defaults to active.

    .PARAMETER Tags
        Array of tag names to apply to the conversation.

    .EXAMPLE
        New-FSConversation -Subject "Password reset" -Customer "user@example.com" -Text "Please reset my password." -MailboxId 1

    .EXAMPLE
        New-FSConversation -Subject "Phone call" -Customer "user@example.com" -Text "Called about billing." -Type phone -MailboxId 1 -User 5 -Status pending -Tags "billing","phone"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Customer,

        [Parameter(Mandatory)]
        [string]$Text,

        [ValidateSet("email", "phone", "chat")]
        [string]$Type = "email",

        [Parameter(Mandatory)]
        [int]$MailboxId,

        [int]$User,

        [ValidateSet("active", "pending", "closed")]
        [string]$Status = "active",

        [string[]]$Tags
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey -WithContentType

    $bodyHash = @{
        type      = $Type
        mailboxId = $MailboxId
        subject   = $Subject
        customer  = @{ email = $Customer }
        threads   = @(@{ type = "customer"; text = $Text })
        status    = $Status
    }

    if ($User) { $bodyHash.user = $User }
    if ($Tags) { $bodyHash.tags = @($Tags) }

    $body = $bodyHash | ConvertTo-Json -Depth 5
    $uri = "$($script:FSConfig.BaseUrl)/api/conversations"

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ResponseHeadersVariable responseHeaders

    $conversationId = if ($responseHeaders -and $responseHeaders['Resource-ID']) {
        $responseHeaders['Resource-ID'] | Select-Object -First 1
    } else { $null }

    if (-not $conversationId) {
        Write-Error "Conversation created but could not retrieve ID from response headers."
        return
    }

    # Return the full conversation object, consistent with Get-FSConversation
    Get-FSConversation -Id ([int]$conversationId)
}
