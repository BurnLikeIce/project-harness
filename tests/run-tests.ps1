$ErrorActionPreference = 'Stop'
$skill = (Resolve-Path (Join-Path $PSScriptRoot '../skills/project-harness')).Path
$init = Join-Path $skill 'scripts/init-project.ps1'
$update = Join-Path $skill 'scripts/update-project.ps1'
$validate = Join-Path $skill 'scripts/validate-project.ps1'
$inspect = Join-Path $skill 'scripts/inspect-project.ps1'
$parent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$temp = Join-Path $parent ('project-harness-test-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.Directory]::CreateDirectory($temp) | Out-Null

function Check($condition, [string]$message) { if (-not $condition) { throw $message } }
function Put([string]$path, [string]$body) { [IO.File]::WriteAllText($path, $body, $utf8) }
function Digest([string]$path) { (Get-FileHash -LiteralPath $path).Hash }
function Must-Fail([scriptblock]$action, [string]$message) {
    try { & $action | Out-Null } catch { return }
    throw $message
}
function Git-Test([string[]]$arguments) {
    & git -C $temp @arguments
    if ($LASTEXITCODE -ne 0) { throw "Fixture Git operation failed: $arguments" }
}

try {
    foreach ($language in 'en','zh-CN') {
        $dir = (New-Item -ItemType Directory -Path (Join-Path $temp $language)).FullName
        & $init -ProjectPath $dir -Language $language | Out-Null
        Check (@(Get-ChildItem -LiteralPath $dir -Force).Count -eq 1) 'Empty project must contain only its map'
        $map = Join-Path $dir 'HARNESS.md'
        Check ((Digest $map) -eq (Digest "$skill/assets/minimal-project/$language/HARNESS.md")) 'Wrong localized map'
        & $init -ProjectPath $dir -Language $language | Out-Null
    }

    $project = (New-Item -ItemType Directory -Path "$temp/sample").FullName
    New-Item -ItemType Directory -Path "$project/docs" | Out-Null
    Put "$project/AGENTS.md" "Existing team instructions`r`n"
    Put "$project/README.md" 'Project guide'
    Put "$project/docs/work items.md" 'Package ready, deployment pending.'
    $team = Digest "$project/AGENTS.md"
    & $init -ProjectPath $project -Source 'docs/work items.md' | Out-Null
    Check ((Digest "$project/AGENTS.md") -eq $team) 'Team instructions changed'
    Check (-not (Test-Path "$project/docs/decisions.md")) 'Empty ledger created'
    $map = Join-Path $project 'HARNESS.md'
    $first = Digest $map
    & $update -ProjectPath $project -Source 'docs/work items.md' | Out-Null
    Check ((Digest $map) -eq $first) 'Repeated adoption changed the map'

    $custom = "# Map`r`n`r`nTeam agreements.`r`n- [tasks](docs/work%20items.md#today)`r`n- [tracker](https://example.org/items)`r`n"
    $custom += 'Example `[ignore](missing.txt)`.' + "`r`n" + '```md' + "`r`n[ignore](missing.md)`r`n" + '```'
    Put $map $custom
    Put "$project/docs/验收 [1] (draft)#.md" 'Acceptance'
    & $update -ProjectPath $project -Source 'docs/验收 [1] (draft)#.md','docs/work items.md' | Out-Null
    $changed = [IO.File]::ReadAllText($map)
    Check ($changed.StartsWith($custom)) 'Existing custom text changed'
    Check ($changed -notmatch '(?<!\r)\n') 'CRLF map acquired LF lines'
    $first = Digest $map
    & $update -ProjectPath $project -Source 'docs/验收 [1] (draft)#.md' | Out-Null
    Check ((Digest $map) -eq $first) 'Repeated explicit link duplicated'
    Must-Fail { & $update -ProjectPath $project -Source 'README.md','missing.md' } 'Missing input accepted'
    Check ((Digest $map) -eq $first) 'Failed update wrote a partial change'

    $legacy = (New-Item -ItemType Directory -Path "$temp/legacy").FullName
    Put "$legacy/TASKS.md" 'Conventional alternative'
    Put "$legacy/custom.md" 'Actual source'
    Put "$legacy/HARNESS.md" @'
# Existing map
<!-- project-harness:managed:start -->
- Tasks: `custom.md`
- Decisions: (not mapped)
<!-- project-harness:managed:end -->
'@
    $before = Digest "$legacy/HARNESS.md"
    & $init -ProjectPath $legacy | Out-Null
    Check ((Digest "$legacy/HARNESS.md") -eq $before) 'Legacy content changed'
    Remove-Item -LiteralPath "$legacy/custom.md"
    Must-Fail { & $validate -ProjectPath $legacy } 'Broken legacy link accepted'
    $state = & $inspect -ProjectPath $legacy | ConvertFrom-Json
    Check ($state.sources.tasks -eq 'custom.md') 'Broken mapping silently redirected'

    Git-Test @('init','-q')
    Git-Test @('add','--','sample')
    Git-Test @('-c','user.name=Harness tests','-c','user.email=tests@example.invalid','commit','-qm','Shared handoff')
    $shared = (Git-Test @('rev-parse','HEAD')).Trim()
    Put "$project/docs/work items.md" 'Deployment verified, business check pending.'
    Put "$project/docs/local only.md" 'Local receipt'
    & $update -ProjectPath $project -Source 'docs/local only.md' | Out-Null
    $state = (& $inspect -ProjectPath $project -HandoffRevision $shared | ConvertFrom-Json).handoff
    $records = @{}
    foreach ($item in $state.records) { $records[$item.path] = $item.state }
    Check ($state.commit -eq $shared) 'Wrong compared revision'
    Check ($records['docs/work items.md'] -eq 'differs-from-revision') 'Missed changed deployment fact'
    Check ($records['docs/local only.md'] -eq 'absent-from-revision') 'Missed local-only receipt'
    Check ($records['docs/验收 [1] (draft)#.md'] -eq 'matches-revision') 'URL or nested repository path misread'
    Check ($records['https://example.org/items'] -eq 'verify-separately') 'External access inferred'
    Must-Fail { & $inspect -ProjectPath $project -HandoffRevision 'nonexistent-revision' } 'Invalid ref accepted'
    Git-Test @('add','--','sample')
    Git-Test @('-c','user.name=Harness tests','-c','user.email=tests@example.invalid','commit','-qm','Verified deployment')
    $now = (& $inspect -ProjectPath $project -HandoffRevision HEAD | ConvertFrom-Json).handoff
    Check (($now.records | Where-Object path -eq 'docs/work items.md').state -eq 'matches-revision') 'Current commit missed'
    $old = (& $inspect -ProjectPath $project -HandoffRevision $shared | ConvertFrom-Json).handoff
    Check (($old.records | Where-Object path -eq 'docs/work items.md').state -eq 'differs-from-revision') 'Recipient ref ignored'

    Put $map "# Map`n- [missing](broken.md)"
    Must-Fail { & $validate -ProjectPath $project } 'Missing plain Markdown link accepted'
    Write-Output 'PASS: PowerShell adoption, file preservation, link checks and handoff revisions'
} finally {
    $actual = (Resolve-Path -LiteralPath $temp).Path
    if ($actual -ne $temp -or [IO.Path]::GetDirectoryName($actual).TrimEnd('\','/') -ne $parent.TrimEnd('\','/')) {
        throw "Unexpected fixture cleanup path: $actual"
    }
    Remove-Item -LiteralPath $actual -Recurse -Force
}
exit 0
