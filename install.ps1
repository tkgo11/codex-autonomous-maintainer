[CmdletBinding()]
param(
    [ValidateSet('omx', 'standalone')]
    [string]$Variant = 'omx',
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user',
    [string]$ProjectDir = '',
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManagedFiles = @('SKILL.md', 'agents/openai.yaml', 'assets/icon.svg')

if ($Variant -eq 'standalone') {
    $SkillName = 'autonomous-maintainer-standalone'
    $SourceDir = Join-Path $ScriptDir 'standalone'
} else {
    $SkillName = 'autonomous-maintainer'
    $SourceDir = $ScriptDir
}

foreach ($Rel in $ManagedFiles) {
    $SourcePath = Join-Path $SourceDir $Rel
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Missing package file: $SourcePath"
    }
}

$Python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($Python) {
    & $Python.Source (Join-Path $ScriptDir 'scripts/validate_skill.py') (Join-Path $SourceDir 'SKILL.md')
    if ($LASTEXITCODE -ne 0) { throw 'Skill package validation failed' }
} else {
    Write-Warning 'Python 3 was not found; skipping structural validation.'
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
Write-Host "variant:     $Variant"
Write-Host "scope:       $Scope"
Write-Host "source:      $SourceDir"
Write-Host "destination: $TargetDir"

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
            throw "Refusing to install through a symbolic-link/reparse-point destination: $Candidate"
        }
    }
}

if ((Test-Path -LiteralPath $TargetDir) -and -not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
    throw "Destination exists and is not a directory: $TargetDir"
}
foreach ($Subdir in @('agents', 'assets')) {
    $Candidate = Join-Path $TargetDir $Subdir
    if ((Test-Path -LiteralPath $Candidate) -and -not (Test-Path -LiteralPath $Candidate -PathType Container)) {
        throw "Managed package directory is not a directory: $Candidate"
    }
}

$AllCurrent = $true
$HasConflict = $false
foreach ($Rel in $ManagedFiles) {
    $SourcePath = Join-Path $SourceDir $Rel
    $TargetPath = Join-Path $TargetDir $Rel
    if (Test-Path -LiteralPath $TargetPath) {
        if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
            throw "Managed package path is not a file: $TargetPath"
        }
        $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $TargetHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
        if ($SourceHash -ne $TargetHash) {
            $AllCurrent = $false
            $HasConflict = $true
        }
    } else {
        $AllCurrent = $false
    }
}

if ($AllCurrent) {
    Write-Host 'already installed and up to date'
    exit 0
}
if ($HasConflict -and -not $Force) {
    throw 'A different managed package file already exists. Rerun with -Force to back up and replace conflicts.'
}
if ($DryRun) {
    if ($HasConflict) {
        Write-Host 'dry-run: would install missing managed files and back up/replace conflicts'
    } else {
        Write-Host 'dry-run: would install missing managed files'
    }
    exit 0
}

New-Item -ItemType Directory -Path (Join-Path $TargetDir 'agents') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $TargetDir 'assets') -Force | Out-Null
$Timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')

foreach ($Rel in $ManagedFiles) {
    $SourcePath = Join-Path $SourceDir $Rel
    $TargetPath = Join-Path $TargetDir $Rel

    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $TargetHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
        if ($SourceHash -eq $TargetHash) { continue }

        $Backup = "$TargetPath.backup-$Timestamp-$PID"
        Copy-Item -LiteralPath $TargetPath -Destination $Backup
        Write-Host "backup:      $Backup"
    }

    $TargetParent = Split-Path -Parent $TargetPath
    $TempFile = Join-Path $TargetParent ('.' + (Split-Path -Leaf $TargetPath) + '.tmp.' + [Guid]::NewGuid().ToString('N'))
    try {
        Copy-Item -LiteralPath $SourcePath -Destination $TempFile
        Move-Item -LiteralPath $TempFile -Destination $TargetPath -Force
    } finally {
        if (Test-Path -LiteralPath $TempFile) {
            Remove-Item -LiteralPath $TempFile -Force
        }
    }

    $InstalledHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
    $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
    if ($InstalledHash -ne $SourceHash) {
        throw "Post-install verification failed: $Rel"
    }
}

Write-Host "installed:   $TargetDir"
Write-Host 'next: start a new Codex session and inspect available skills'
