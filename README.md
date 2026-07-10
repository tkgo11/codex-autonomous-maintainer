# Autonomous Maintainer Skills for Codex

Evidence-driven, resumable repository-maintenance skills that discover material defects and strongly evidenced gaps, apply every safe and objectively verifiable finding, review the result, run applicable adversarial QA, and repeat full-scope scans until a guarded fixed point or documented blocker is reached.

This repository provides two installable variants:

| Variant | Skill name | Extra runtime requirement | Best for |
|---|---|---|---|
| Standalone | `autonomous-maintainer-standalone` | None beyond Codex, Git, and repository tools | Standard Codex environments and the simplest setup |
| OMX | `autonomous-maintainer` | [Oh My Codex (OMX)](https://github.com/Yeachan-Heo/oh-my-codex) | Users who want OMX goals, team workflows, and specialized review helpers |

The variants can be installed side by side. The existing OMX variant remains the installer default for backward compatibility.

> These are independent custom skills. They are not part of the official Codex or OMX distributions.

## What is included

```text
.
├── SKILL.md                         # OMX variant
├── standalone/SKILL.md              # Framework-independent Codex variant
├── install.sh                       # macOS/Linux installer
├── install.ps1                      # Windows PowerShell installer
├── uninstall.sh                     # macOS/Linux uninstaller
├── uninstall.ps1                    # Windows PowerShell uninstaller
├── scripts/validate_skill.py        # Dependency-free structural validator
├── tests/test_installers.sh         # Both-variant installer smoke tests
├── examples/AGENTS.md.snippet       # Optional project policy snippet
├── examples/invocations.md          # Ready-to-copy invocation examples
├── .github/workflows/validate.yml   # CI validation
└── Makefile                         # Common local commands
```

## Prerequisites

### Standalone variant

- OpenAI Codex with local repository access
- Git
- the build, test, and analysis tools already declared by the target repository

No OMX command, goal runtime, tmux session, or third-party orchestration skill is required. Native Codex delegation is optional; the skill falls back to sequential discovery and clearly labeled self-review when it is unavailable. High-risk work still requires independent review or remains blocked.

### OMX variant

The recommended OMX path is macOS or Linux with OpenAI Codex CLI:

```bash
codex --version
npm install -g oh-my-codex
omx setup --scope user
omx doctor
```

For project-level OMX guidance, run this from the target repository:

```bash
omx setup --scope project --merge-agents
omx doctor
```

## Quick install

Clone the repository once:

```bash
git clone https://github.com/tkgo11/autonomous-maintainer-skill.git
cd autonomous-maintainer-skill
```

### Standalone — macOS or Linux

User scope:

```bash
bash ./install.sh --variant standalone --scope user
```

Project scope:

```bash
bash ./install.sh --variant standalone --scope project --project-dir /path/to/target-repository
```

Destinations:

```text
${CODEX_HOME:-$HOME/.codex}/skills/autonomous-maintainer-standalone/SKILL.md
/path/to/target-repository/.codex/skills/autonomous-maintainer-standalone/SKILL.md
```

### Standalone — Windows PowerShell

User scope:

```powershell
.\install.ps1 -Variant standalone -Scope user
```

Project scope:

```powershell
.\install.ps1 -Variant standalone -Scope project -ProjectDir C:\path\to\target-repository
```

### OMX — macOS or Linux

User scope:

```bash
bash ./install.sh --variant omx --scope user
```

Project scope:

```bash
bash ./install.sh --variant omx --scope project --project-dir /path/to/target-repository
```

`--variant omx` may be omitted because it is the default.

### OMX — Windows PowerShell

```powershell
.\install.ps1 -Variant omx -Scope user
.\install.ps1 -Variant omx -Scope project -ProjectDir C:\path\to\target-repository
```

## Manual install

Only the selected `SKILL.md` is required at runtime.

| Variant | Source | Destination directory |
|---|---|---|
| Standalone | `standalone/SKILL.md` | `autonomous-maintainer-standalone` |
| OMX | `SKILL.md` | `autonomous-maintainer` |

Validate either source before copying:

```bash
python3 scripts/validate_skill.py standalone/SKILL.md
python3 scripts/validate_skill.py SKILL.md
```

Standalone user-scope example for macOS or Linux:

```bash
destination="${CODEX_HOME:-$HOME/.codex}/skills/autonomous-maintainer-standalone"
mkdir -p "$destination"
cp ./standalone/SKILL.md "$destination/SKILL.md"
cmp -s ./standalone/SKILL.md "$destination/SKILL.md"
```

OMX user-scope example:

```bash
destination="${CODEX_HOME:-$HOME/.codex}/skills/autonomous-maintainer"
mkdir -p "$destination"
cp ./SKILL.md "$destination/SKILL.md"
cmp -s ./SKILL.md "$destination/SKILL.md"
```

For project scope, use the same variant-specific directory below the target repository's `.codex/skills/` directory.

## Installer safety behavior

The installers:

- validate the selected variant before copying when Python 3 is available;
- install the two variants to different skill directories so they can coexist;
- refuse to overwrite a different existing installation by default;
- exit successfully when the installed file is already identical;
- create a timestamped backup only when `--force` or `-Force` is explicitly supplied;
- write through a temporary file before replacing the destination;
- reject symbolic-link or reparse-point destinations;
- support dry-run mode;
- do not modify `AGENTS.md`, Codex configuration, Git state, or runtime state.

Examples:

```bash
bash ./install.sh --variant standalone --scope user --dry-run
bash ./install.sh --variant standalone --scope user --force
bash ./install.sh --variant omx --scope project --project-dir "$PWD" --force
```

```powershell
.\install.ps1 -Variant standalone -Scope user -DryRun
.\install.ps1 -Variant standalone -Scope user -Force
```

## Usage

### Standalone

Invoke it directly in the repository to maintain:

```text
@autonomous-maintainer-standalone
```

Codex interfaces that use dollar-prefixed skill invocation can use:

```text
$autonomous-maintainer-standalone
```

The explicit aggressive profile is:

```text
@autonomous-maintainer-standalone mode=apply focus=all feature_policy=strong-evidence resume=true commit=checkpoint max_epochs=25 quiescence_scans=2 parallelism=auto network=public-read
```

No separate launcher or setup command is needed. The skill keeps resumable state in `.autonomous-maintainer/`, uses native delegation only when available, and otherwise runs discovery sequentially.

### OMX

Recommended launch sequence from the repository to maintain:

```bash
omx setup --scope project --merge-agents
omx doctor
omx --worktree=maintenance/autonomous --madmax --xhigh
```

Then invoke:

```text
$autonomous-maintainer
```

Launch flags remain an operator decision. The skill does not enable approval bypasses, push, merge, deployment, or release.

### Common examples

Report-only audit:

```text
@autonomous-maintainer-standalone mode=report
$autonomous-maintainer mode=report
```

Focused maintenance:

```text
@autonomous-maintainer-standalone focus=correctness,security,tests
```

Project constraint:

```text
@autonomous-maintainer-standalone "do not touch the frontend or add dependencies"
```

Resume durable state:

```text
@autonomous-maintainer-standalone resume
```

## Supported options

Both variants share the same public option contract:

| Option | Values | Default |
|---|---|---|
| `mode` | `apply`, `report` | `apply` |
| `focus` | `all` or comma-separated categories | `all` |
| `feature_policy` | `off`, `documented`, `strong-evidence` | `strong-evidence` |
| `resume` | `true`, `false` | `true` |
| `commit` | `false`, `checkpoint`, `final` | `checkpoint` |
| `max_epochs` | `1..50` | `25` |
| `quiescence_scans` | `1..5` | `2` |
| `parallelism` | `auto`, `1..16` | `auto` |
| `network` | `off`, `public-read` | `public-read` |

Valid focus categories:

```text
correctness, reliability, tests, security, maintainability,
documentation, developer-experience, performance, features,
dependencies, compatibility
```

The default creates verified local checkpoint commits and performs repeated repository-wide scans. Neither variant ever interprets a commit option as permission to push.

## Optional project policy

The skills contain their own activation and safety rules. Teams that want an additional repository-level reminder may merge [`examples/AGENTS.md.snippet`](examples/AGENTS.md.snippet) into an existing `AGENTS.md`. Do not replace existing project guidance wholesale.

## Updating

```bash
git pull --ff-only
bash ./install.sh --variant standalone --scope user --force
bash ./install.sh --variant omx --scope user --force
```

Install only the variants you use. A forced update backs up a different installed file before replacement.

## Uninstall

macOS or Linux:

```bash
bash ./uninstall.sh --variant standalone --scope user --yes
bash ./uninstall.sh --variant omx --scope user --yes
bash ./uninstall.sh --variant standalone --scope project --project-dir /path/to/repository --yes
```

Windows PowerShell:

```powershell
.\uninstall.ps1 -Variant standalone -Scope user
.\uninstall.ps1 -Variant omx -Scope user
.\uninstall.ps1 -Variant standalone -Scope project -ProjectDir C:\path\to\repository
```

Uninstallers verify the expected skill name and remove only the selected installed `SKILL.md`. They preserve backups and unexpected files.

## Development

```bash
make validate
make test
```

Or run the checks directly:

```bash
python3 scripts/validate_skill.py SKILL.md
python3 scripts/validate_skill.py standalone/SKILL.md
bash tests/test_installers.sh
```

Validation also rejects external orchestration references inside the standalone variant.

## Important limitations

- No prompt or skill can guarantee that an externally terminated process continues running; both variants use durable state to support an honest resume.
- Repository-wide discovery is bounded by available tools, declared scope, objective evidence, and safety constraints.
- The standalone variant cannot manufacture independent review when native delegation is unavailable. It records self-review for low-risk work and blocks high-risk work that requires independence.
- Both variants forbid remote mutation, push, merge, deployment, release, destructive Git operations, secret handling, and speculative product invention.

## Upstream references

- [OpenAI Codex](https://github.com/openai/codex)
- [Official Oh My Codex repository](https://github.com/Yeachan-Heo/oh-my-codex)
- [OMX skills documentation](https://oh-my-codex.dev/docs/skills.html)

## License

No license has been selected yet. Until a license is added, standard copyright restrictions apply.
