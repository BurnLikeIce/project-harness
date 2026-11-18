param([string]$ProjectPath = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/map-targets.ps1"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$map = Join-Path $project 'HARNESS.md'
if (-not [IO.File]::Exists($map)) { throw "Missing project map: $map" }
$content = [IO.File]::ReadAllText($map)
if ([string]::IsNullOrWhiteSpace($content)) { throw 'HARNESS.md is empty.' }
if ($content -match '(?m)^(<<<<<<< |>>>>>>> )') { throw 'Resolve the merge conflict in HARNESS.md.' }
foreach ($target in Get-MapTargets $map) {
    if (Test-ExternalMapTarget $target) {
        Write-Output "Verify access separately: $target"
    } elseif (-not (Test-Path -LiteralPath (Join-Path $project $target))) {
        throw "Missing linked source: $target"
    }
}
Write-Output "VALID: Project map and declared local paths at $project"
