param(
    [string]$ProjectPath = (Get-Location).Path,
    [ValidateSet('en', 'zh-CN')][string]$Language = 'en',
    [string[]]$Source = @()
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/map-targets.ps1"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$map = Join-Path $project 'HARNESS.md'
$validate = Join-Path $PSScriptRoot 'validate-project.ps1'
if ([IO.File]::Exists($map) -and -not $Source.Count) {
    & $validate -ProjectPath $project
    return
}

$lock = Join-Path $project '.project-harness-write.lock'
New-Item -ItemType Directory -Path $lock -ErrorAction Stop | Out-Null
$tempMap = Join-Path $lock 'HARNESS.md'
try {
    $exists = Test-Path -LiteralPath $map
    if ($exists) { & $validate -ProjectPath $project }
    $candidates = @(
        if (-not $exists) {
            'AGENTS.md', 'README.md' | Where-Object { [IO.File]::Exists((Join-Path $project $_)) }
        }
        $Source
    )
    $known = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    if ($exists) { foreach ($entry in Get-MapTargets $map) { [void]$known.Add($entry) } }
    $links = @(foreach ($candidate in $candidates) {
        $relative = ($candidate -replace '\\', '/' -replace '^(\./)+', '')
        if (-not $relative -or (Test-ExternalMapTarget $relative) -or
            $relative -match '(^|/)\.\.(/|$)|[\r\n]' -or
            -not [IO.File]::Exists((Join-Path $project $relative))) {
            throw "Expected an existing project-relative source file: $candidate"
        }
        if ($known.Add($relative)) {
            $label = $relative.Replace('[', '\[').Replace(']', '\]')
            $url = $relative.Replace('%', '%25').Replace('#', '%23').Replace('<', '%3C').Replace('>', '%3E')
            "- [$label](<$url>)"
        }
    })
    if (-not $exists) {
        $template = Join-Path $PSScriptRoot "../assets/minimal-project/$Language/HARNESS.md"
        [IO.File]::Copy($template, $tempMap)
        $destination = $tempMap
    } else {
        $destination = $map
    }
    if ($links.Count) {
        if ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw 'Edit the shared link target explicitly before adding sources.'
        }
        $bytes = [IO.File]::ReadAllBytes($destination)
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        $original = $utf8.GetString($bytes)
        if ($original.Contains([char]0)) { throw 'Edit this map in its existing text encoding.' }
        $newline = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
        $separator = if ($original.EndsWith("`n")) { $newline } else { $newline + $newline }
        [IO.File]::AppendAllText($destination, $separator + ($links -join $newline) + $newline, $utf8)
    }
    if (-not $exists) { [IO.File]::Move($tempMap, $map) }
    & $validate -ProjectPath $project
} finally {
    if ([IO.File]::Exists($tempMap)) { [IO.File]::Delete($tempMap) }
    [IO.Directory]::Delete($lock)
}
