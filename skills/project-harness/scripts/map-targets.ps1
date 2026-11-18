# Read ordinary Markdown entry links and the explicit paths in older maps.
function Get-MapTargets {
    param([string]$Map)
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $managed = $false
    $fence = ''
    $link = '`+[^`]*`+|!?\[(?:\\.|[^\]\\])*\]\(\s*(?:<(?<angle>[^>]+)>|(?<bare>(?:\\.|[^\s()\\]|\([^()]*\))+))(?:\s+["''][^)]*)?\s*\)'
    foreach ($line in [IO.File]::ReadAllLines($Map)) {
        if ($line -match '^\s{0,3}(`{3,}|~{3,})(.*)$') {
            if (-not $fence) { $fence = $Matches[1]; continue }
            if ($Matches[1].StartsWith($fence) -and -not $Matches[2].Trim()) { $fence = '' }
            continue
        }
        if ($fence) { continue }
        if ($line -match '^\s*<!-- project-harness:managed:(start|end) -->\s*$') {
            $managed = $Matches[1] -eq 'start'
            continue
        }
        if ($managed -and $line -match '^\s*-\s*(?:Tasks|Decisions|Product|Architecture|API(?: 契约)?|Acceptance|Handoff|任务记录|决策记录|产品事实|架构事实|验收依据|主控交接)\s*[:：]\s*(.+?)\s*$') {
            $value = $Matches[1].Trim([char]96)
            if ($value -ne '(not mapped)' -and $value -notmatch '^\[' -and $seen.Add($value)) { $value }
        }
        foreach ($m in [regex]::Matches($line, $link)) {
            if (-not $m.Value.StartsWith('[')) { continue }
            $target = $m.Groups['angle'].Value + $m.Groups['bare'].Value
            $path = ($target -split '#', 2)[0]
            if ($path -and $path -notmatch '^[A-Za-z][A-Za-z0-9+.-]*:|^//') {
                $path = [Uri]::UnescapeDataString(($path -replace '\\([()])', '$1'))
            }
            if ($path -and $seen.Add($path)) { $path }
        }
    }
}

function Test-ExternalMapTarget([string]$Path) {
    return $Path -match '^[A-Za-z][A-Za-z0-9+.-]*:|^[/\\]'
}
