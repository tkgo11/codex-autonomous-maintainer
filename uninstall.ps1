[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [ValidateSet('omx', 'standalone', 'both')]
    [string]$Variant = 'omx',
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user',
    [string]$ProjectDir = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ManagedFiles = @('SKILL.md', 'agents/openai.yaml', 'assets/icon.svg')

if ($Scope -eq 'user') {
    $CodexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $TargetRoot = Join-Path $CodexRoot 'skills'
} else {
    if ([string]::IsNullOrWhiteSpace($ProjectDir)) { $ProjectDir = (Get-Location).Path }
    if (-not (Test-Path -LiteralPath $ProjectDir -PathType Container)) {
        throw "Project directory does not exist: $ProjectDir"
    }
    $ResolvedProject = (Resolve-Path -LiteralPath $ProjectDir).Path
    $TargetRoot = Join-Path $ResolvedProject '.codex/skills'
}

function Uninstall-SkillVariant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param([string]$V)

    $SkillName = if ($V -eq 'standalone') {
        'autonomous-maintainer-standalone'
    } else {
        'autonomous-maintainer'
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
        return
    }

    $Content = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($TargetFile))
    $FirstName = $null
    $Frontmatter = [regex]::Match($Content, "(?s)\A---\r?\n(.*?)\r?\n---(?=\r?\n|\z)")
    if ($Frontmatter.Success) {
        $NameMatch = [regex]::Match($Frontmatter.Groups[1].Value, '(?m)^name:\s*(.*?)\s*$')
        if ($NameMatch.Success) {
            $FirstName = $NameMatch.Groups[1].Value
            if ($FirstName.Length -ge 2 -and
                ($FirstName[0] -eq '"' -or $FirstName[0] -eq "'") -and
                $FirstName[-1] -eq $FirstName[0]) {
                $FirstName = $FirstName.Substring(1, $FirstName.Length - 2)
            }
        }
    }
    if ($FirstName -cne $SkillName) {
        throw "Refusing to remove an unexpected skill: name=$FirstName"
    }

    Write-Host "remove managed package files from: $TargetDir"
    if ($DryRun) {
        Write-Host 'dry-run: no files removed'
        return
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
}

$VariantsToUninstall = if ($Variant -eq 'both') { @('omx', 'standalone') } else { @($Variant) }
foreach ($V in $VariantsToUninstall) {
    Uninstall-SkillVariant -V $V
}
