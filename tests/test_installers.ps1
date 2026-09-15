[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Temp = Join-Path ([IO.Path]::GetTempPath()) ('autonomous-maintainer-tests-' + [Guid]::NewGuid().ToString('N'))

function Invoke-PwshFile {
    param(
        [Parameter(Mandatory)]
        [string]$File,
        [string[]]$ScriptArgs = @(),
        [switch]$ExpectFailure
    )

    & pwsh -NoLogo -NoProfile -NonInteractive -File $File @ScriptArgs
    $ExitCode = $LASTEXITCODE
    if ($ExpectFailure) {
        if ($ExitCode -eq 0) { throw "Expected failure from $File" }
    } elseif ($ExitCode -ne 0) {
        throw "$File failed with exit code $ExitCode"
    }
}

function Assert-FileEqual {
    param(
        [Parameter(Mandatory)]
        [string]$Expected,
        [Parameter(Mandatory)]
        [string]$Actual
    )

    if (-not (Test-Path -LiteralPath $Actual -PathType Leaf)) {
        throw "Expected file was not created: $Actual"
    }
    $ExpectedHash = (Get-FileHash -LiteralPath $Expected -Algorithm SHA256).Hash
    $ActualHash = (Get-FileHash -LiteralPath $Actual -Algorithm SHA256).Hash
    if ($ExpectedHash -ne $ActualHash) {
        throw "File content mismatch: $Actual"
    }
}

function Assert-Package {
    param(
        [Parameter(Mandatory)]
        [string]$SourceDir,
        [Parameter(Mandatory)]
        [string]$TargetDir
    )

    foreach ($Rel in @('SKILL.md', 'agents/openai.yaml', 'assets/icon.svg')) {
        Assert-FileEqual -Expected (Join-Path $SourceDir $Rel) -Actual (Join-Path $TargetDir $Rel)
    }
}

function Assert-PackageRemoved {
    param([Parameter(Mandatory)][string]$TargetDir)

    foreach ($Rel in @('SKILL.md', 'agents/openai.yaml', 'assets/icon.svg')) {
        $Target = Join-Path $TargetDir $Rel
        if (Test-Path -LiteralPath $Target) {
            throw "Managed package file survived uninstall: $Target"
        }
    }
}

try {
    $HomeDir = Join-Path $Temp 'home'
    $env:HOME = $HomeDir
    $env:USERPROFILE = $HomeDir
    $env:CODEX_HOME = Join-Path $HomeDir '.codex'
    New-Item -ItemType Directory -Path $HomeDir -Force | Out-Null

    $Install = Join-Path $Root 'install.ps1'
    $Uninstall = Join-Path $Root 'uninstall.ps1'
    $StandaloneSource = Join-Path $Root 'standalone'

    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'invalid') -ExpectFailure

    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'omx', '-Scope', 'user')
    $OmxUserDir = Join-Path $env:CODEX_HOME 'skills/autonomous-maintainer'
    $OmxUserFile = Join-Path $OmxUserDir 'SKILL.md'
    Assert-Package -SourceDir $Root -TargetDir $OmxUserDir
    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'omx', '-Scope', 'user')

    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'standalone', '-Scope', 'user')
    $StandaloneUserDir = Join-Path $env:CODEX_HOME 'skills/autonomous-maintainer-standalone'
    Assert-Package -SourceDir $StandaloneSource -TargetDir $StandaloneUserDir
    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'standalone', '-Scope', 'user')

    Add-Content -LiteralPath $OmxUserFile -Value "`n# local modification"
    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'omx', '-Scope', 'user') -ExpectFailure
    Invoke-PwshFile -File $Install -ScriptArgs @('-Variant', 'omx', '-Scope', 'user', '-Force')
    Assert-Package -SourceDir $Root -TargetDir $OmxUserDir
    $Backups = Get-ChildItem -LiteralPath $OmxUserDir -Filter 'SKILL.md.backup-*'
    if (-not $Backups) { throw 'Expected forced installation to create a backup' }

    $LegacyProject = Join-Path $Temp 'legacy-project'
    $LegacyTarget = Join-Path $LegacyProject '.codex/skills/autonomous-maintainer-standalone'
    New-Item -ItemType Directory -Path $LegacyTarget -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $StandaloneSource 'SKILL.md') -Destination (Join-Path $LegacyTarget 'SKILL.md')
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'standalone', '-Scope', 'project', '-ProjectDir', $LegacyProject
    )
    Assert-Package -SourceDir $StandaloneSource -TargetDir $LegacyTarget

    $DryProject = Join-Path $Temp 'dry-project'
    New-Item -ItemType Directory -Path $DryProject -Force | Out-Null
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'standalone', '-Scope', 'project', '-ProjectDir', $DryProject, '-DryRun'
    )
    $DryTarget = Join-Path $DryProject '.codex/skills/autonomous-maintainer-standalone'
    if (Test-Path -LiteralPath (Join-Path $DryTarget 'SKILL.md')) { throw 'Dry-run unexpectedly created SKILL.md' }
    if (Test-Path -LiteralPath (Join-Path $DryTarget 'agents/openai.yaml')) { throw 'Dry-run unexpectedly created metadata' }

    $Project = Join-Path $Temp 'project'
    New-Item -ItemType Directory -Path $Project -Force | Out-Null
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $Project
    )
    $OmxProjectDir = Join-Path $Project '.codex/skills/autonomous-maintainer'
    Assert-Package -SourceDir $Root -TargetDir $OmxProjectDir

    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'standalone', '-Scope', 'project', '-ProjectDir', $Project
    )
    $StandaloneProjectDir = Join-Path $Project '.codex/skills/autonomous-maintainer-standalone'
    Assert-Package -SourceDir $StandaloneSource -TargetDir $StandaloneProjectDir

    Set-Content -LiteralPath (Join-Path $StandaloneProjectDir 'user-note.txt') -Value 'keep me'
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'standalone', '-Scope', 'project', '-ProjectDir', $Project, '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir $StandaloneProjectDir
    if (-not (Test-Path -LiteralPath (Join-Path $StandaloneProjectDir 'user-note.txt') -PathType Leaf)) {
        throw 'Uninstaller removed an unexpected user file'
    }

    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $Project, '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir $OmxProjectDir

    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'standalone', '-Scope', 'user', '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir $StandaloneUserDir

    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'user', '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir $OmxUserDir

    # Invalid scope and missing project directories must fail cleanly.
    Invoke-PwshFile -File $Install -ScriptArgs @('-Scope', 'invalid') -ExpectFailure
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Scope', 'project', '-ProjectDir', (Join-Path $Temp 'no-such-dir')
    ) -ExpectFailure

    # Uninstall reports a missing skill without removing anything.
    $EmptyProject = Join-Path $Temp 'empty-project'
    New-Item -ItemType Directory -Path $EmptyProject -Force | Out-Null
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $EmptyProject, '-Confirm:$false'
    )

    # Uninstall dry-run preserves managed files.
    $DryUninstall = Join-Path $Temp 'dry-uninstall-project'
    New-Item -ItemType Directory -Path $DryUninstall -Force | Out-Null
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $DryUninstall
    )
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $DryUninstall, '-DryRun', '-Confirm:$false'
    )
    if (-not (Test-Path -LiteralPath (Join-Path $DryUninstall '.codex/skills/autonomous-maintainer/SKILL.md') -PathType Leaf)) {
        throw 'Dry-run uninstall removed SKILL.md'
    }

    # Non-interactive uninstall without -Confirm:$false refuses and preserves files.
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', $DryUninstall
    ) -ExpectFailure
    if (-not (Test-Path -LiteralPath (Join-Path $DryUninstall '.codex/skills/autonomous-maintainer/SKILL.md') -PathType Leaf)) {
        throw 'Unconfirmed uninstall removed SKILL.md'
    }

    # A SKILL.md identifying as a different skill is refused and preserved.
    $MismatchDir = Join-Path $Temp 'mismatch-project/.codex/skills/autonomous-maintainer'
    New-Item -ItemType Directory -Path $MismatchDir -Force | Out-Null
    (Get-Content -LiteralPath (Join-Path $Root 'SKILL.md') -Raw) -replace '(?m)^name: autonomous-maintainer$', 'name: other-skill' |
        Set-Content -LiteralPath (Join-Path $MismatchDir 'SKILL.md')
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', (Join-Path $Temp 'mismatch-project'), '-Confirm:$false'
    ) -ExpectFailure
    if (-not (Test-Path -LiteralPath (Join-Path $MismatchDir 'SKILL.md') -PathType Leaf)) {
        throw 'Uninstaller removed a mismatched skill'
    }

    # A quoted frontmatter name still identifies the skill for uninstall.
    $QuotedDir = Join-Path $Temp 'quoted-project/.codex/skills/autonomous-maintainer'
    New-Item -ItemType Directory -Path (Join-Path $QuotedDir 'agents'), (Join-Path $QuotedDir 'assets') -Force | Out-Null
    (Get-Content -LiteralPath (Join-Path $Root 'SKILL.md') -Raw) -replace '(?m)^name: autonomous-maintainer$', 'name: "autonomous-maintainer"' |
        Set-Content -LiteralPath (Join-Path $QuotedDir 'SKILL.md')
    Copy-Item -LiteralPath (Join-Path $Root 'agents/openai.yaml') -Destination (Join-Path $QuotedDir 'agents/openai.yaml')
    Copy-Item -LiteralPath (Join-Path $Root 'assets/icon.svg') -Destination (Join-Path $QuotedDir 'assets/icon.svg')
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'omx', '-Scope', 'project', '-ProjectDir', (Join-Path $Temp 'quoted-project'), '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir $QuotedDir

    # -Variant both installs and uninstalls each variant in one pass.
    $BothProject = Join-Path $Temp 'both-project'
    New-Item -ItemType Directory -Path $BothProject -Force | Out-Null
    Invoke-PwshFile -File $Install -ScriptArgs @(
        '-Variant', 'both', '-Scope', 'project', '-ProjectDir', $BothProject
    )
    Assert-Package -SourceDir $Root -TargetDir (Join-Path $BothProject '.codex/skills/autonomous-maintainer')
    Assert-Package -SourceDir $StandaloneSource -TargetDir (Join-Path $BothProject '.codex/skills/autonomous-maintainer-standalone')
    Invoke-PwshFile -File $Uninstall -ScriptArgs @(
        '-Variant', 'both', '-Scope', 'project', '-ProjectDir', $BothProject, '-Confirm:$false'
    )
    Assert-PackageRemoved -TargetDir (Join-Path $BothProject '.codex/skills/autonomous-maintainer')
    Assert-PackageRemoved -TargetDir (Join-Path $BothProject '.codex/skills/autonomous-maintainer-standalone')

    Write-Host 'ok: PowerShell installer smoke tests passed'
} finally {
    if (Test-Path -LiteralPath $Temp) {
        Remove-Item -LiteralPath $Temp -Recurse -Force
    }
}
