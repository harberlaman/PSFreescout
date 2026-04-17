function New-FSThread {
    <#
    .SYNOPSIS
        Create a new thread (reply or note) on a FreeScout conversation.

    .DESCRIPTION
        Adds a customer reply, agent reply, or agent note to a conversation.
        The FreeScout API requires a customer identifier for customer threads
        and a user ID for agent messages and notes.

    .PARAMETER ConversationId
        The conversation ID to add the thread to.

    .PARAMETER Type
        Thread type: customer (customer reply), message (agent reply), or note (agent note).

    .PARAMETER Text
        The message content.

    .PARAMETER CustomerId
        Customer ID. Required when Type is 'customer' (alternative to CustomerEmail).

    .PARAMETER CustomerEmail
        Customer email. Required when Type is 'customer' (alternative to CustomerId).

    .PARAMETER User
        User ID of the agent. Required when Type is 'message' or 'note'.

    .PARAMETER Imported
        When set, no outgoing emails or notifications are generated.

    .PARAMETER Status
        Change the conversation status: active, pending, or closed.

    .PARAMETER State
        Thread state: draft or published (default).

    .PARAMETER To
        List of TO email addresses.

    .PARAMETER Cc
        List of CC email addresses.

    .PARAMETER Bcc
        List of BCC email addresses.

    .PARAMETER CreatedAt
        Thread creation date (ISO 8601). Only valid when -Imported is set.

    .PARAMETER Attachments
        Array of attachment hashtables. Each must contain fileName, mimeType, and either
        data (Base64-encoded string) or fileUrl.
        Example: @(@{ fileName = "doc.pdf"; mimeType = "application/pdf"; fileUrl = "https://..." })

    .EXAMPLE
        New-FSThread -ConversationId 17064 -Type note -Text "Internal note about this ticket." -User 1

    .EXAMPLE
        New-FSThread -ConversationId 17064 -Type customer -Text "We received your request." -CustomerEmail "user@example.com"

    .EXAMPLE
        New-FSThread -ConversationId 17064 -Type message -Text "Reply to customer" -User 1 -Cc "manager@example.com" -Status active

    .EXAMPLE
        New-FSThread -ConversationId 17064 -Type message -Text "See attached" -User 1 -Attachments @(@{ fileName = "report.pdf"; mimeType = "application/pdf"; fileUrl = "https://example.com/report.pdf" })
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ConversationId,

        [Parameter(Mandatory)]
        [ValidateSet("customer", "message", "note")]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Text,

        [int]$CustomerId,

        [string]$CustomerEmail,

        [int]$User,

        [switch]$Imported,

        [ValidateSet("active", "pending", "closed")]
        [string]$Status,

        [ValidateSet("draft", "published")]
        [string]$State,

        [string[]]$To,

        [string[]]$Cc,

        [string[]]$Bcc,

        [datetime]$CreatedAt,

        [hashtable[]]$Attachments
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    # Validate conditional requirements
    if ($Type -eq "customer" -and -not $CustomerId -and -not $CustomerEmail) {
        throw "Parameter -CustomerId or -CustomerEmail is required when -Type is 'customer'."
    }
    if ($Type -in "message", "note" -and -not $User) {
        throw "Parameter -User is required when -Type is 'message' or 'note'."
    }
    if ($CreatedAt -and -not $Imported) {
        throw "Parameter -Imported must be set when using -CreatedAt."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey -WithContentType

    # Build request body
    $bodyHash = @{
        type = $Type
        text = $Text
    }

    if ($CustomerId)   { $bodyHash.customer = @{ id = $CustomerId } }
    elseif ($CustomerEmail) { $bodyHash.customer = @{ email = $CustomerEmail } }

    if ($User)         { $bodyHash.user = $User }
    if ($Imported)     { $bodyHash.imported = $true }
    if ($Status)       { $bodyHash.status = $Status }
    if ($State)        { $bodyHash.state = $State }
    if ($To)           { $bodyHash.to = $To }
    if ($Cc)           { $bodyHash.cc = $Cc }
    if ($Bcc)          { $bodyHash.bcc = $Bcc }
    if ($CreatedAt)    { $bodyHash.createdAt = $CreatedAt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
    if ($Attachments)  { $bodyHash.attachments = $Attachments }

    $body = $bodyHash | ConvertTo-Json -Depth 5
    $uri = "$($script:FSConfig.BaseUrl)/api/conversations/$ConversationId/threads"

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ResponseHeadersVariable responseHeaders

    $threadId = if ($responseHeaders -and $responseHeaders['Resource-ID']) {
        $responseHeaders['Resource-ID'] | Select-Object -First 1
    } else { $null }

    [PSCustomObject]@{
        ThreadId       = if ($threadId) { [int]$threadId } else { $null }
        ConversationId = $ConversationId
        Type           = $Type
        Status         = 'created'
    }
}
