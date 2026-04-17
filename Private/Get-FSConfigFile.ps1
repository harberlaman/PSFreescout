function Get-FSConfigFile {
    <#
    .SYNOPSIS
        Read persisted PSFreescout configuration from disk.
    #>
    [CmdletBinding()]
    param()

    $configPath = Join-Path $HOME ".psfreescout" "config.json"

    if (-not (Test-Path $configPath)) {
        return $null
    }

    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    return $config
}
