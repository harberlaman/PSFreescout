function Search-FSMeilisearch {
    <#
    .SYNOPSIS
        Full-text search across FreeScout tickets via Meilisearch.

    .DESCRIPTION
        Searches the Meilisearch freescout index for tickets matching the query.
        Requires Meilisearch to be configured via Set-FSConfig.
        Returns ranked results with readable field names.

    .PARAMETER Query
        Search query string.

    .PARAMETER Limit
        Maximum results to return (default: 20).

    .PARAMETER Offset
        Pagination offset (default: 0).

    .PARAMETER Status
        Filter by status code(s): 1=active, 2=pending, 3=closed.

    .PARAMETER MailboxId
        Filter by mailbox ID(s).

    .PARAMETER UserId
        Filter by assigned user ID.

    .PARAMETER CustomerId
        Filter by customer ID.

    .EXAMPLE
        Search-FSMeilisearch -Query "printer jam"

    .EXAMPLE
        Search-FSMeilisearch -Query "BNRC" -Status 3 -Limit 10

    .EXAMPLE
        Search-FSMeilisearch -Query "password reset" -MailboxId 1,2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [int]$Limit = 20,

        [int]$Offset = 0,

        [int[]]$Status,

        [int[]]$MailboxId,

        [int]$UserId,

        [int]$CustomerId
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    if (-not $script:FSConfig.MeilisearchHost -or -not $script:FSConfig.MeilisearchApiKey) {
        throw "Meilisearch is not configured. Run Set-FSConfig with -MeilisearchHost and -MeilisearchApiKey parameters."
    }

    $statusNames = @{
        1 = "active"
        2 = "pending"
        3 = "closed"
    }

    $uri = "$($script:FSConfig.MeilisearchHost)/indexes/freescout/search"
    $headers = @{
        "Authorization" = "Bearer $($script:FSConfig.MeilisearchApiKey)"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }

    # Build filter expressions
    $filters = @()
    if ($Status) {
        $vals = $Status -join ", "
        $filters += "status IN [$vals]"
    }
    if ($MailboxId) {
        $vals = $MailboxId -join ", "
        $filters += "mid IN [$vals]"
    }
    if ($UserId) {
        $filters += "uid = $UserId"
    }
    if ($CustomerId) {
        $filters += "cid = $CustomerId"
    }
    $filterString = $filters -join " AND "

    $payload = @{
        q                    = $Query
        limit                = $Limit
        offset               = $Offset
        sort                 = @("lr:desc")
        attributesToRetrieve = @("id", "conv_id", "subj", "status", "mid", "uid", "lr", "ca", "_rankingScore")
        showRankingScore     = $true
    }

    if ($filterString) {
        $payload["filter"] = $filterString
    }

    $body = $payload | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body

    # Transform hits to readable field names
    $transformedHits = $response.hits | ForEach-Object {
        $statusCode = $_.status
        [PSCustomObject]@{
            TicketId       = $_.conv_id
            Subject        = $_.subj
            Status         = $statusCode
            StatusName     = $statusNames[$statusCode]
            MailboxId      = $_.mid
            AssignedUserId = $_.uid
            LastReply      = $_.lr
            CreatedAt      = $_.ca
            RankingScore   = $_._rankingScore
        }
    }

    [PSCustomObject]@{
        Query     = $response.query
        TotalHits = $response.estimatedTotalHits
        Limit     = $response.limit
        Offset    = $response.offset
        Results   = $transformedHits
    }
}
