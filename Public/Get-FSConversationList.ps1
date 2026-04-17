function Get-FSConversationList {
    <#
    .SYNOPSIS
        List conversations from FreeScout with filtering.

    .DESCRIPTION
        Retrieves conversations from FreeScout with optional filtering by status,
        mailbox, folder, type, assignment, customer, dates, and more.

    .PARAMETER MailboxId
        Filter by mailbox ID(s).

    .PARAMETER FolderId
        Filter by folder ID.

    .PARAMETER Status
        Filter by status: active, pending, closed, spam. Comma-separated for multiple.

    .PARAMETER State
        Filter by state: draft, published, deleted.

    .PARAMETER Type
        Filter by type: email, phone, chat.

    .PARAMETER AssignedTo
        Filter by assigned user ID. Use 0 for unassigned.

    .PARAMETER CustomerEmail
        Filter by customer email address.

    .PARAMETER CustomerPhone
        Filter by customer phone number.

    .PARAMETER CustomerId
        Filter by customer ID.

    .PARAMETER Number
        Filter by conversation number.

    .PARAMETER Subject
        Text search in conversation subject.

    .PARAMETER Tag
        Filter by tag name.

    .PARAMETER CreatedByUserId
        Filter by the user ID who created the conversation.

    .PARAMETER CreatedByCustomerId
        Filter by the customer ID who created the conversation.

    .PARAMETER CreatedSince
        Filter to conversations created since this datetime (ISO 8601 UTC).

    .PARAMETER UpdatedSince
        Filter to conversations updated since this datetime (ISO 8601 UTC).

    .PARAMETER SortField
        Sort by field: createdAt, mailboxId, number, subject, updatedAt, waitingSince.

    .PARAMETER SortOrder
        Sort direction: asc or desc (default: desc).

    .PARAMETER Page
        Page number (default: 1).

    .PARAMETER PageSize
        Results per page (default: 50).

    .PARAMETER Embed
        Comma-separated related data to include: threads, timelogs, tags.

    .EXAMPLE
        Get-FSConversationList -Status active -PageSize 10

    .EXAMPLE
        Get-FSConversationList -Status closed -MailboxId 1 -UpdatedSince "2026-03-15T00:00:00Z" -Embed threads

    .EXAMPLE
        Get-FSConversationList -Subject "password reset" -AssignedTo 5 -SortField updatedAt
    #>
    [CmdletBinding()]
    param(
        [int[]]$MailboxId,
        [int]$FolderId,
        [string]$Status,
        [string]$State,
        [string]$Type,
        [int]$AssignedTo = -1,
        [string]$CustomerEmail,
        [string]$CustomerPhone,
        [int]$CustomerId,
        [int]$Number,
        [string]$Subject,
        [string]$Tag,
        [int]$CreatedByUserId,
        [int]$CreatedByCustomerId,
        [string]$CreatedSince,
        [string]$UpdatedSince,
        [string]$SortField,
        [string]$SortOrder,
        [int]$Page,
        [int]$PageSize,
        [string]$Embed
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey

    $params = @()
    if ($MailboxId)          { $params += "mailboxId=$($MailboxId -join ',')" }
    if ($FolderId)           { $params += "folderId=$FolderId" }
    if ($Status)             { $params += "status=$Status" }
    if ($State)              { $params += "state=$State" }
    if ($Type)               { $params += "type=$Type" }
    if ($AssignedTo -ge 0)   { $params += "assignedTo=$AssignedTo" }
    if ($CustomerEmail)      { $params += "customerEmail=$CustomerEmail" }
    if ($CustomerPhone)      { $params += "customerPhone=$CustomerPhone" }
    if ($CustomerId)         { $params += "customerId=$CustomerId" }
    if ($Number)             { $params += "number=$Number" }
    if ($Subject)            { $params += "subject=$Subject" }
    if ($Tag)                { $params += "tag=$Tag" }
    if ($CreatedByUserId)    { $params += "createdByUserId=$CreatedByUserId" }
    if ($CreatedByCustomerId){ $params += "createdByCustomerId=$CreatedByCustomerId" }
    if ($CreatedSince)       { $params += "createdSince=$CreatedSince" }
    if ($UpdatedSince)       { $params += "updatedSince=$UpdatedSince" }
    if ($SortField)          { $params += "sortField=$SortField" }
    if ($SortOrder)          { $params += "sortOrder=$SortOrder" }
    if ($Page)               { $params += "page=$Page" }
    if ($PageSize)           { $params += "pageSize=$PageSize" }
    if ($Embed)              { $params += "embed=$Embed" }

    $uri = "$($script:FSConfig.BaseUrl)/api/conversations"
    if ($params.Count -gt 0) {
        $uri += "?" + ($params -join "&")
    }

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return $response
}
