param(
    [string]$ProjectPath = (Get-Location).Path,
    [ValidateSet('en', 'zh-CN')][string]$Language = 'en',
    [string[]]$Source = @()
)
& "$PSScriptRoot/init-project.ps1" @PSBoundParameters
