function Search-FSMeilisearch {
    <#
    .SYNOPSIS
        Full-text search across FreeScout tickets via Meilisearch.

    .DESCRIPTION
        Searches the Meilisearch freescout index for tickets matching the query and/or filters.
        Returns full conversation objects from the FreeScout REST API.
        Requires Meilisearch to be configured via Set-FSConfig.

        Supports all filter capabilities of the FasterSearch module: status, state, mailbox,
        user, customer, type, tags, attachments, date ranges, followers, and field-specific
        full-text searches on subject, body, and attachment names.

    .PARAMETER Query
        Full-text search query string. Optional — omit to search by filters only.

    .PARAMETER Subject
        Full-text search restricted to the subject field only.

    .PARAMETER Body
        Full-text search restricted to the message body field only.

    .PARAMETER AttachmentName
        Full-text search restricted to attachment file names only.

    .PARAMETER Status
        Filter by status code(s): 1=active, 2=pending, 3=closed.

    .PARAMETER State
        Filter by state code(s): 1=published, 2=deleted.

    .PARAMETER MailboxId
        Filter by mailbox ID(s).

    .PARAMETER UserId
        Filter by assigned user ID.

    .PARAMETER CustomerId
        Filter by customer ID. Matches conversations where the customer is the primary
        customer OR created a thread (cid OR by_cid).

    .PARAMETER Type
        Filter by conversation type code(s): 1=email, 2=phone, 3=chat.

    .PARAMETER Number
        Filter by ticket number.

    .PARAMETER ConversationId
        Filter by conversation ID.

    .PARAMETER HasAttachment
        Filter to only conversations that have attachments.

    .PARAMETER TagId
        Filter by tag ID(s). Multiple IDs are OR'd (matches any of the specified tags).

    .PARAMETER NotTagId
        Exclude conversations that have any of the specified tag ID(s).

    .PARAMETER HasNoTags
        Filter to only conversations that have no tags.

    .PARAMETER FollowerId
        Filter by follower user ID(s). Multiple IDs are OR'd.

    .PARAMETER CreatedAfter
        Filter to conversations created after this date/time.

    .PARAMETER CreatedBefore
        Filter to conversations created before this date/time.

    .PARAMETER SortField
        Sort results by field: LastReply, Number, Subject, or CreatedAt. Default: LastReply.

    .PARAMETER SortOrder
        Sort direction: asc or desc. Default: desc.

    .PARAMETER Limit
        Maximum results to return (default: 20).

    .PARAMETER Offset
        Pagination offset (default: 0).

    .PARAMETER Embed
        Comma-separated related data to include when fetching conversations: threads, timelogs, tags.
        Passed through to Get-FSConversation.

    .EXAMPLE
        Search-FSMeilisearch -Query "printer jam"

    .EXAMPLE
        Search-FSMeilisearch -Query "BNRC" -Status 3 -Limit 10

    .EXAMPLE
        Search-FSMeilisearch -Query "password reset" -MailboxId 1,2

    .EXAMPLE
        Search-FSMeilisearch -Status 1 -Limit 5
        # Filter-only search (no query text), returns active conversations.

    .EXAMPLE
        Search-FSMeilisearch -Subject "password reset"
        # Search only in subject lines.

    .EXAMPLE
        Search-FSMeilisearch -Subject "reset" -Body "password"
        # Multi-field search: subject contains "reset" AND body contains "password".

    .EXAMPLE
        Search-FSMeilisearch -Query "invoice" -CreatedAfter "2026-01-01" -CreatedBefore "2026-03-31"

    .EXAMPLE
        Search-FSMeilisearch -Query "error" -TagId 5,12
        # Find conversations tagged with tag ID 5 or 12.

    .EXAMPLE
        Search-FSMeilisearch -NotTagId 3,7 -Status 1
        # Find active conversations NOT tagged with tag ID 3 or 7.

    .EXAMPLE
        Search-FSMeilisearch -HasNoTags -Status 1
        # Find active conversations with no tags at all.

    .EXAMPLE
        Search-FSMeilisearch -Query "report" -SortField Number -SortOrder asc

    .EXAMPLE
        Search-FSMeilisearch -Query "test" -Limit 3 -Embed "threads,tags"
        # Returns full conversation objects with threads and tags embedded.
    #>
    [CmdletBinding()]
    param(
        [string]$Query,

        [string]$Subject,

        [string]$Body,

        [string]$AttachmentName,

        [int[]]$Status,

        [int[]]$State,

        [int[]]$MailboxId,

        [int]$UserId,

        [int]$CustomerId,

        [int[]]$Type,

        [int]$Number,

        [int]$ConversationId,

        [switch]$HasAttachment,

        [int[]]$TagId,

        [int[]]$NotTagId,

        [switch]$HasNoTags,

        [int[]]$FollowerId,

        [datetime]$CreatedAfter,

        [datetime]$CreatedBefore,

        [ValidateSet("LastReply", "Number", "Subject", "CreatedAt")]
        [string]$SortField = "LastReply",

        [ValidateSet("asc", "desc")]
        [string]$SortOrder = "desc",

        [int]$Limit = 20,

        [int]$Offset = 0,

        [string]$Embed
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    if (-not $script:FSConfig.MeilisearchHost -or -not $script:FSConfig.MeilisearchApiKey) {
        throw "Meilisearch is not configured. Run Set-FSConfig with -MeilisearchHost and -MeilisearchApiKey parameters."
    }

    $msHeaders = @{
        "Authorization" = "Bearer $($script:FSConfig.MeilisearchApiKey)"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }

    # --- Build filter array ---
    $filter = [System.Collections.ArrayList]::new()

    if ($Status) {
        $vals = $Status -join ", "
        [void]$filter.Add("status IN [$vals]")
    }
    if ($State) {
        $vals = $State -join ", "
        [void]$filter.Add("state IN [$vals]")
    }
    if ($MailboxId) {
        $vals = $MailboxId -join ", "
        [void]$filter.Add("mid IN [$vals]")
    }
    if ($UserId) {
        [void]$filter.Add("uid = $UserId")
    }
    if ($CustomerId) {
        # OR logic: customer is on conversation OR created a thread
        [void]$filter.Add(@("cid = $CustomerId", "by_cid = $CustomerId"))
    }
    if ($Type) {
        $vals = $Type -join ", "
        [void]$filter.Add("type IN [$vals]")
    }
    if ($Number) {
        [void]$filter.Add("number = $Number")
    }
    if ($ConversationId) {
        [void]$filter.Add("conv_id = $ConversationId")
    }
    if ($HasAttachment) {
        [void]$filter.Add("has_att = 1")
    }
    if ($TagId) {
        # OR: matches any of the specified tags
        [void]$filter.Add(@($TagId | ForEach-Object { "tags = $_" }))
    }
    if ($NotTagId) {
        # AND: must not have ANY of the specified tags
        foreach ($tid in $NotTagId) {
            [void]$filter.Add("tags != $tid")
        }
    }
    if ($HasNoTags) {
        [void]$filter.Add("tags IS EMPTY")
    }
    if ($FollowerId) {
        # OR: matches any of the specified followers
        [void]$filter.Add(@($FollowerId | ForEach-Object { "flwrs = $_" }))
    }
    if ($CreatedAfter) {
        $unixTs = [DateTimeOffset]::new($CreatedAfter).ToUnixTimeSeconds()
        [void]$filter.Add("ca > $unixTs")
    }
    if ($CreatedBefore) {
        $unixTs = [DateTimeOffset]::new($CreatedBefore).ToUnixTimeSeconds()
        [void]$filter.Add("ca <= $unixTs")
    }

    # --- Build sort ---
    $sortFieldMap = @{
        "LastReply" = "lr"
        "Number"    = "number"
        "Subject"   = "subj"
        "CreatedAt" = "ca"
    }
    $sortKey = "$($sortFieldMap[$SortField]):$SortOrder"

    # --- Collect search terms ---
    $searches = [System.Collections.ArrayList]::new()
    if ($Query) {
        [void]$searches.Add(@{ q = $Query; field = $null })
    }
    if ($Subject) {
        [void]$searches.Add(@{ q = $Subject; field = "subj" })
    }
    if ($Body) {
        [void]$searches.Add(@{ q = $Body; field = "body" })
    }
    if ($AttachmentName) {
        [void]$searches.Add(@{ q = $AttachmentName; field = "att" })
    }

    # --- Execute Meilisearch query ---
    $convIds = @()
    $totalHits = 0
    $queryLabel = if ($Query) { $Query } elseif ($searches.Count -eq 1) { $searches[0].q } else { "" }

    if ($searches.Count -le 1) {
        # Single search or filter-only
        $payload = @{
            q                    = if ($searches.Count -eq 1) { $searches[0].q } else { "" }
            limit                = $Limit
            offset               = $Offset
            sort                 = @($sortKey)
            attributesToRetrieve = @("conv_id")
            filter               = @($filter)
        }

        if ($searches.Count -eq 1 -and $searches[0].field) {
            $payload["attributesToSearchOn"] = @($searches[0].field)
        }

        $uri = "$($script:FSConfig.MeilisearchHost)/indexes/freescout/search"
        $bodyJson = $payload | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $uri -Headers $msHeaders -Method Post -Body $bodyJson

        if (-not $response.hits) {
            return [PSCustomObject]@{
                Query     = $queryLabel
                TotalHits = 0
                Limit     = $Limit
                Offset    = $Offset
                Results   = @()
            }
        }

        $convIds = @($response.hits | ForEach-Object { $_.conv_id }) | Select-Object -Unique
        $totalHits = $response.estimatedTotalHits
    }
    else {
        # Multi-search: one query per search term, intersect conv_id results
        $queries = @($searches | ForEach-Object {
            $q = @{
                indexUid             = "freescout"
                q                    = $_.q
                limit                = 1000
                filter               = @($filter)
                sort                 = @($sortKey)
                attributesToRetrieve = @("conv_id")
            }
            if ($_.field) {
                $q["attributesToSearchOn"] = @($_.field)
            }
            $q
        })

        $multiPayload = @{ queries = $queries }
        $uri = "$($script:FSConfig.MeilisearchHost)/multi-search"
        $bodyJson = $multiPayload | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $uri -Headers $msHeaders -Method Post -Body $bodyJson

        if (-not $response.results) {
            return [PSCustomObject]@{
                Query     = $queryLabel
                TotalHits = 0
                Limit     = $Limit
                Offset    = $Offset
                Results   = @()
            }
        }

        # Intersect conv_ids across all result sets
        $idSets = [System.Collections.ArrayList]::new()
        foreach ($resultSet in $response.results) {
            $ids = @($resultSet.hits | ForEach-Object { $_.conv_id }) | Select-Object -Unique
            [void]$idSets.Add($ids)
        }

        # Start with first set, intersect with each subsequent set
        $intersected = @($idSets[0])
        for ($i = 1; $i -lt $idSets.Count; $i++) {
            $currentSet = @($idSets[$i])
            $intersected = @($intersected | Where-Object { $_ -in $currentSet })
        }

        $totalHits = $intersected.Count

        # Apply paging to intersected results
        $convIds = @($intersected | Select-Object -Skip $Offset -First $Limit)
    }

    # --- Fetch full conversations from FreeScout API ---
    $conversations = @()
    foreach ($id in $convIds) {
        $params = @{ Id = $id }
        if ($Embed) {
            $params["Embed"] = $Embed
        }
        $conversations += Get-FSConversation @params
    }

    [PSCustomObject]@{
        Query     = $queryLabel
        TotalHits = $totalHits
        Limit     = $Limit
        Offset    = $Offset
        Results   = $conversations
    }
}
