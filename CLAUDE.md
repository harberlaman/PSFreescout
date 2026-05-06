# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PSFreescout is a PowerShell 7+ module for interacting with a FreeScout help desk instance. It wraps two APIs:

- **FreeScout REST API** — conversations, tags (authenticated via `X-FreeScout-API-Key` header)
- **Meilisearch** — full-text ticket search (authenticated via Bearer token, optional)

## Module Structure

The repo root *is* the module directory (`PSFreescout/` under your modules path).

```
PSFreescout/
├── PSFreescout.psd1      # Module manifest
├── PSFreescout.psm1      # Root module (dot-sources Private/ then Public/)
├── Private/              # Internal helpers (not exported)
│   ├── Get-FSConfigFile.ps1   # Reads persisted config from ~/.psfreescout/config.json
│   └── Get-FSHeaders.ps1      # Builds FreeScout API auth headers
├── Public/               # Exported cmdlets
│   ├── Set-FSConfig.ps1
│   ├── Get-FSConfig.ps1
│   ├── Get-FSConversation.ps1
│   ├── Get-FSConversationList.ps1
│   ├── Search-FSMeilisearch.ps1
│   ├── Set-FSTag.ps1
│   ├── New-FSThread.ps1
│   └── Get-FSUser.ps1
```

## Usage

```powershell
Import-Module PSFreescout

# Configure (session only)
Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "abc123"

# Configure with Meilisearch and persist to disk
Set-FSConfig -BaseUrl "https://helpdesk.example.com" -ApiKey "abc123" -MeilisearchHost "http://localhost:7700" -MeilisearchApiKey "mskey" -Persist

# View current config
Get-FSConfig

# Get a conversation with threads
Get-FSConversation -Id 17064
Get-FSConversation -Id 17064 -Embed "threads,tags"

# List/filter conversations (supports full FreeScout API parameters)
Get-FSConversationList -Status active -PageSize 10
Get-FSConversationList -Subject "password reset" -AssignedTo 5 -SortField updatedAt

# Full-text search via Meilisearch (requires Meilisearch config)
# Returns full conversation objects from the FreeScout API
Search-FSMeilisearch -Query "printer jam" -Limit 10
Search-FSMeilisearch -Query "BNRC" -Status 3 -MailboxId 1,2
Search-FSMeilisearch -Subject "password reset"                  # Field-specific search
Search-FSMeilisearch -Subject "reset" -Body "password"          # Multi-field search
Search-FSMeilisearch -Status 1 -HasNoTags                       # Filter-only (no query)
Search-FSMeilisearch -Query "error" -TagId 5,12                 # Tag filter
Search-FSMeilisearch -NotTagId 3 -Status 1                      # Tag exclusion
Search-FSMeilisearch -Query "invoice" -CreatedAfter "2026-01-01"
Search-FSMeilisearch -Query "test" -Embed "threads,tags"        # With embedded data

# Tag management
Set-FSTag -Id 17064 -Tags "exchange","mobile"              # Add (default)
Set-FSTag -Id 17064 -Tags "urgent","vip" -Action Replace   # Replace all
Set-FSTag -Id 17064 -Tags "obsolete" -Action Remove        # Remove specific

# Create threads (replies/notes)
New-FSThread -ConversationId 17064 -Type note -Text "Internal note" -User 1
New-FSThread -ConversationId 17064 -Type message -Text "Agent reply" -User 1 -Status active
New-FSThread -ConversationId 17064 -Type customer -Text "Customer reply" -CustomerEmail "user@example.com"

# List users
Get-FSUser
Get-FSUser -Email "agent@example.com"
```

## Configuration

Persisted config is stored at `~/.psfreescout/config.json`:

```json
{
  "baseUrl": "https://helpdesk.example.com",
  "apiKey": "...",
  "meilisearch": {
    "host": "http://...",
    "apiKey": "..."
  }
}
```

The `meilisearch` block is optional. Without it, `Search-FSMeilisearch` is unavailable but all other cmdlets work.

## Architecture Notes

- **Config is module-scoped**: `$script:FSConfig` holds the active config. Set via `Set-FSConfig`, auto-loaded from disk on `Import-Module`.
- **Tag merging**: FreeScout's PUT `/api/conversations/{id}/tags` replaces all tags. `Set-FSTag -Action Add` handles the GET→merge→PUT pattern. `-Action Remove` does GET→subtract→PUT.
- **Search two-step**: `Search-FSMeilisearch` queries Meilisearch for matching `conv_id`s, then fetches full conversation objects via `Get-FSConversation`. Supports field-specific searches (Subject, Body, AttachmentName) via `attributesToSearchOn`, and multi-field searches via Meilisearch's `/multi-search` endpoint with result intersection.
- **Search field mapping**: Meilisearch index uses abbreviated field names (`subj`, `mid`, `uid`, `lr`, `ca`, `cid`, `by_cid`, `tags`, `flwrs`, `att`, etc.) defined by the FasterSearch module.
- **Status codes**: FreeScout uses numeric statuses in Meilisearch (1=active, 2=pending, 3=closed) but string names in the REST API (`active`, `pending`, `closed`, `spam`).
- **All public functions return objects** (PSCustomObject), not raw JSON strings.
