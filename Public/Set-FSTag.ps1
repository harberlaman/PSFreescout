function Set-FSTag {
    <#
    .SYNOPSIS
        Manage tags on a FreeScout conversation.

    .DESCRIPTION
        Add, replace, or remove tags on a conversation.
        - Add (default): merges new tags with existing tags.
        - Replace: overwrites all tags with the provided list.
        - Remove: removes the specified tags from the conversation.

    .PARAMETER Id
        One or more conversation IDs. Accepts an array of integers.

    .PARAMETER Tags
        One or more tag names. Accepts an array or a comma-separated string.

    .PARAMETER Action
        The tag operation: Add (default), Replace, or Remove.

    .EXAMPLE
        Set-FSTag -Id 17064 -Tags "exchange","mobile"

    .EXAMPLE
        Set-FSTag -Id 17064 -Tags "disk-full","dnrc" -Action Add

    .EXAMPLE
        Set-FSTag -Id 17064 -Tags "urgent","vip" -Action Replace

    .EXAMPLE
        Set-FSTag -Id 17064 -Tags "obsolete" -Action Remove

    .EXAMPLE
        Set-FSTag -Id 17064,17065,17066 -Tags "analyzing" -Action Add
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]]$Id,

        [Parameter(Mandatory)]
        [string[]]$Tags,

        [ValidateSet("Add", "Replace", "Remove")]
        [string]$Action = "Add"
    )

    if (-not $script:FSConfig) {
        throw "PSFreescout is not configured. Run Set-FSConfig first."
    }

    $headers = Get-FSHeaders -ApiKey $script:FSConfig.ApiKey -WithContentType

    # Normalize tags: split any comma-separated values, trim whitespace
    $newTags = $Tags | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    foreach ($ConversationId in $Id) {
        try {
            $finalTags = $newTags

            if ($Action -eq "Add" -or $Action -eq "Remove") {
                # GET existing tags
                $getUri = "$($script:FSConfig.BaseUrl)/api/tags?conversationId=$ConversationId&pageSize=100"
                try {
                    $existing = Invoke-RestMethod -Uri $getUri -Headers $headers -Method Get
                    $existingTags = @()
                    if ($existing._embedded.tags) {
                        $existingTags = @($existing._embedded.tags | ForEach-Object { $_.name })
                    }
                }
                catch {
                    $existingTags = @()
                }

                if ($Action -eq "Add") {
                    $finalTags = ($existingTags + $newTags) | Sort-Object -Unique
                }
                elseif ($Action -eq "Remove") {
                    $finalTags = $existingTags | Where-Object { $_ -notin $newTags }
                }
            }

            # PUT the final tag list
            $uri = "$($script:FSConfig.BaseUrl)/api/conversations/$ConversationId/tags"
            $body = @{ tags = @($finalTags) } | ConvertTo-Json

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $body

            [PSCustomObject]@{
                ConversationId = $ConversationId
                Action         = $Action
                Tags           = $finalTags
            }
        }
        catch {
            Write-Error "Failed to set tags on conversation ${ConversationId}: $_"
        }
    }
}
