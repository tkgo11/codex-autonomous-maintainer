[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user',
    [string]$ProjectDir = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$SkillName = 'autonomous-maintainer'

if ($Scope -eq 'user') {
    $CodexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $TargetRoot = Join-Path $CodexRoot 'skills'
} else {
    if ([string]::IsNullOrWhiteSpace($ProjectDir)) { $ProjectDir = (Get-Location).Path }
    $ResolvedProject = (Resolve-Path -LiteralPath $ProjectDir).Path
    $TargetRoot = Join-Path $ResolvedProject '.codex/skills'
}

$TargetDir = Join-Path $TargetRoot $SkillName
$TargetFile = Join-Path $TargetDir 'SKILL.md'

if (-not (Test-Path -LiteralPath $TargetFile -PathType Leaf)) {
    Write-Host "not installed: $TargetFile"
    exit 0
}

$Content = Get-Content -LiteralPath $TargetFile -Raw
if ($Content -notmatch '(?m)^name:\s*autonomous-maintainer\s*$') {
    throw 'Refusing to remove a file that does not identify as autonomous-maintainer.'
}

Write-Host "remove: $TargetDir"
if ($DryRun) {
    Write-Host 'dry-run: no files removed'
    exit 0
}

if ($PSCmdlet.ShouldProcess($TargetFile, 'Remove installed skill')) {
    Remove-Item -LiteralPath $TargetFile -Force
    $Remaining = Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue
    if (-not $Remaining) {
        Remove-Item -LiteralPath $TargetDir -Force
        Write-Host 'removed skill directory'
    } else {
        Write-Host "removed SKILL.md; preserved other files in $TargetDir"
    }
}
