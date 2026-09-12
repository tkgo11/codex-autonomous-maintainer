[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('omx', 'standalone')]
    [string]$Variant = 'omx',
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user',
    [string]$ProjectDir = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ManagedFiles = @('SKILL.md', 'agents/openai.yaml', 'assets/icon.svg')
$SkillName = if ($Variant -eq 'standalone') {
    'autonomous-maintainer-standalone'
} else {
    'autonomous-maintainer'
}

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

$PathsToCheck = @(
    $TargetDir,
    (Join-Path $TargetDir 'agents'),
    (Join-Path $TargetDir 'assets')
)
foreach ($Rel in $ManagedFiles) {
    $PathsToCheck += Join-Path $TargetDir $Rel
}
foreach ($Candidate in $PathsToCheck) {
    if (Test-Path -LiteralPath $Candidate) {
        $Item = Get-Item -LiteralPath $Candidate -Force
        if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to uninstall through a symbolic-link/reparse-point destination: $Candidate"
        }
    }
}

if (-not (Test-Path -LiteralPath $TargetFile -PathType Leaf)) {
    Write-Host "not installed: $TargetFile"
    exit 0
}

$Content = Get-Content -LiteralPath $TargetFile -Raw
$NamePattern = '(?m)^name:\s*' + [regex]::Escape($SkillName) + '\s*$'
if ($Content -notmatch $NamePattern) {
    throw "Refusing to remove a file that does not identify as $SkillName."
}

Write-Host "remove managed package files from: $TargetDir"
if ($DryRun) {
    Write-Host 'dry-run: no files removed'
    exit 0
}

if ($PSCmdlet.ShouldProcess($TargetDir, 'Remove managed skill package files')) {
    foreach ($Rel in $ManagedFiles) {
        $TargetPath = Join-Path $TargetDir $Rel
        if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
            Remove-Item -LiteralPath $TargetPath -Force
        }
    }

    foreach ($Subdir in @('agents', 'assets')) {
        $SubdirPath = Join-Path $TargetDir $Subdir
        if (Test-Path -LiteralPath $SubdirPath -PathType Container) {
            $Remaining = Get-ChildItem -LiteralPath $SubdirPath -Force -ErrorAction SilentlyContinue
            if (-not $Remaining) {
                Remove-Item -LiteralPath $SubdirPath -Force
            }
        }
    }

    $Remaining = Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue
    if (-not $Remaining) {
        Remove-Item -LiteralPath $TargetDir -Force
        Write-Host 'removed skill package directory'
    } else {
        Write-Host "removed managed package files; preserved other files in $TargetDir"
    }
}
