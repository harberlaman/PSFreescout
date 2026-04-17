# PSFreescout

A PowerShell 7+ module for interacting with [FreeScout](https://freescout.net/) help desk instances.

## Features

- **Conversations** - Retrieve and list conversations with full filtering support
- **Threads** - Create customer replies, agent replies, and internal notes
- **Tags** - Add, replace, or remove tags on conversations
- **Users** - List and look up FreeScout users
- **Search** - Full-text ticket search via Meilisearch (optional)

## Requirements

- PowerShell 7.0 or later
- A FreeScout instance with API access
- A FreeScout API key

## Installation

Clone or copy this repository into your PowerShell modules directory:

```powershell
# Typical module paths
# Windows: $HOME\Documents\PowerShell\Modules\PSFreescout
# Linux/macOS: ~/.local/share/powershell/Modules/PSFreescout

Import-Module PSFreescout
```

## Configuration

### Session Only

```powershell
Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "your-api-key"
```

### Persist to Disk

Configuration is saved to `~/.psfreescout/config.json` and loaded automatically on module import.

```powershell
Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "your-api-key" -Persist
```

### With Meilisearch (Optional)

```powershell
Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "your-api-key" `
    -MeilisearchHost "http://localhost:7700" -MeilisearchApiKey "mskey" -Persist
```

### View Current Config

```powershell
Get-FSConfig
```

API keys are partially masked in the output.

## Usage

### Conversations

```powershell
# Get a single conversation with threads
Get-FSConversation -Id 17064

# Include threads and tags
Get-FSConversation -Id 17064 -Embed "threads,tags"

# List conversations with filters
Get-FSConversationList -Status active -PageSize 10
Get-FSConversationList -Subject "password reset" -AssignedTo 5 -SortField updatedAt
Get-FSConversationList -MailboxId 1 -UpdatedSince "2026-03-15T00:00:00Z"
```

### Threads

```powershell
# Add an internal note
New-FSThread -ConversationId 17064 -Type note -Text "Escalating to L2." -User 1

# Send an agent reply
New-FSThread -ConversationId 17064 -Type message -Text "We're looking into this." -User 1

# Send an agent reply and close the conversation
New-FSThread -ConversationId 17064 -Type message -Text "This is resolved." -User 1 -Status closed

# Add a customer reply
New-FSThread -ConversationId 17064 -Type customer -Text "Thanks for the help." -CustomerEmail "user@example.com"

# Reply with CC recipients
New-FSThread -ConversationId 17064 -Type message -Text "Looping in the team." -User 1 -Cc "manager@example.com","team@example.com"

# Import a historical thread (no emails sent)
New-FSThread -ConversationId 17064 -Type message -Text "Old reply" -User 1 -Imported -CreatedAt "2025-01-15T10:30:00"

# Attach files
New-FSThread -ConversationId 17064 -Type message -Text "See attached." -User 1 -Attachments @(
    @{ fileName = "report.pdf"; mimeType = "application/pdf"; fileUrl = "https://example.com/report.pdf" }
)
```

### Tags

```powershell
# Add tags (merges with existing)
Set-FSTag -Id 17064 -Tags "exchange","mobile"

# Replace all tags
Set-FSTag -Id 17064 -Tags "urgent","vip" -Action Replace

# Remove specific tags
Set-FSTag -Id 17064 -Tags "obsolete" -Action Remove
```

### Users

```powershell
# List all users
Get-FSUser

# Find a user by email
Get-FSUser -Email "agent@example.com"

# Paginate
Get-FSUser -PageSize 10 -Page 2
```

### Search (Meilisearch)

Requires Meilisearch configuration via `Set-FSConfig`.

```powershell
# Full-text search
Search-FSMeilisearch -Query "printer jam" -Limit 10

# Search with filters
Search-FSMeilisearch -Query "password reset" -Status 3 -MailboxId 1,2
```

## Cmdlet Reference

| Cmdlet | Description |
|--------|-------------|
| `Set-FSConfig` | Configure API connection (session or persisted) |
| `Get-FSConfig` | Display current configuration |
| `Get-FSConversation` | Retrieve a single conversation by ID |
| `Get-FSConversationList` | List/filter conversations |
| `New-FSThread` | Create a thread (reply or note) on a conversation |
| `Set-FSTag` | Add, replace, or remove tags on a conversation |
| `Get-FSUser` | List FreeScout users |
| `Search-FSMeilisearch` | Full-text search via Meilisearch |

## Authentication

All FreeScout API requests are authenticated via the `X-FreeScout-API-Key` header. Meilisearch requests use a Bearer token. Both keys are configured through `Set-FSConfig`.

## Status

This module is a work in progress. The cmdlets listed above are functional and tested, but the FreeScout API has additional endpoints that are not yet covered (customers, mailboxes, conversations creation, webhooks, etc.). More cmdlets will be added over time.

Pull requests are welcome.

## License

MIT License. See [LICENSE](LICENSE) for details.
