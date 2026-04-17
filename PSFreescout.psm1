# Module-scoped configuration
$script:FSConfig = $null

# Dot-source private functions
Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

# Dot-source public functions
Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

# Auto-load persisted config on module import
$persisted = Get-FSConfigFile
if ($persisted) {
    $script:FSConfig = @{
        BaseUrl = $persisted.baseUrl
        ApiKey  = $persisted.apiKey
    }
    if ($persisted.meilisearch -and $persisted.meilisearch.host -and $persisted.meilisearch.apiKey) {
        $script:FSConfig.MeilisearchHost   = $persisted.meilisearch.host
        $script:FSConfig.MeilisearchApiKey  = $persisted.meilisearch.apiKey
    }
}
