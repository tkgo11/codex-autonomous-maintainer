# Autonomous Maintainer Skill for Oh My Codex

An evidence-driven, resumable repository-maintenance skill for [Oh My Codex (OMX)](https://github.com/Yeachan-Heo/oh-my-codex).

It is intended for explicit repository-wide maintenance requests: discover defects and strongly evidenced gaps, apply every safe and objectively verifiable finding, review the result independently, run applicable adversarial QA, and repeat full-scope scans until a guarded fixed point or a documented blocker is reached.

> This is an independent custom skill. It is not part of the official OMX distribution.

## What is included

```text
.
├── SKILL.md                         # The installable skill
├── install.sh                       # macOS/Linux installer
├── install.ps1                      # Windows PowerShell installer
├── uninstall.sh                     # macOS/Linux uninstaller
├── uninstall.ps1                    # Windows PowerShell uninstaller
├── scripts/validate_skill.py        # Dependency-free structural validator
├── tests/test_installers.sh         # Installer smoke tests
├── examples/AGENTS.md.snippet       # Optional project policy snippet
├── examples/invocations.md          # Ready-to-copy invocation examples
├── .github/workflows/validate.yml   # CI validation
├── .editorconfig                    # Cross-editor formatting defaults
├── .gitattributes                   # Stable LF line endings
└── Makefile                         # Common local commands
```

## Prerequisites

The recommended OMX path is macOS or Linux with OpenAI Codex CLI. Native Windows may work but receives less upstream support.

```bash
codex --version
npm install -g oh-my-codex
omx setup --scope user
omx doctor
```

For a repository that should own project-level OMX guidance, run this from that repository instead:

```bash
omx setup --scope project --merge-agents
omx doctor
```

Official OMX documentation recommends user skills under `~/.codex/skills/` and project skills under `.codex/skills/`.

## Quick install

### macOS or Linux — user scope

```bash
git clone https://github.com/tkgo11/autonomous-maintainer-skill.git
cd autonomous-maintainer-skill
./install.sh --scope user
```

This installs:

```text
${CODEX_HOME:-$HOME/.codex}/skills/autonomous-maintainer/SKILL.md
```

### macOS or Linux — project scope

```bash
./install.sh --scope project --project-dir /path/to/target-repository
```

This installs:

```text
/path/to/target-repository/.codex/skills/autonomous-maintainer/SKILL.md
```

### Windows PowerShell — user scope

```powershell
 git clone https://github.com/tkgo11/autonomous-maintainer-skill.git
 Set-Location autonomous-maintainer-skill
 .\install.ps1 -Scope user
```

### Windows PowerShell — project scope

```powershell
.\install.ps1 -Scope project -ProjectDir C:\path\to\target-repository
```

## Installer safety behavior

The installers:

- validate `SKILL.md` before copying when Python 3 is available;
- refuse to overwrite a different existing installation by default;
- exit successfully when the installed file is already identical;
- create a timestamped backup only when `--force` or `-Force` is explicitly supplied;
- write through a temporary file before replacing the destination;
- support dry-run mode;
- do not modify `AGENTS.md`, Codex configuration, Git state, or OMX runtime state.

Examples:

```bash
./install.sh --scope user --dry-run
./install.sh --scope user --force
./install.sh --scope project --project-dir "$PWD" --force
```

```powershell
.\install.ps1 -Scope user -DryRun
.\install.ps1 -Scope user -Force
```

## Verify discovery

Restart Codex after installation, then browse skills:

```text
/skills
```

Confirm that `autonomous-maintainer` is listed. You can also validate the source file directly:

```bash
python3 scripts/validate_skill.py SKILL.md
```

## Usage

Basic invocation:

```text
$autonomous-maintainer
```

Safer first run in report-only mode:

```text
$autonomous-maintainer mode=report
```

Focused maintenance:

```text
$autonomous-maintainer focus=correctness,security,tests
```

Project constraints:

```text
$autonomous-maintainer "do not touch the frontend or add dependencies"
```

Resume a durable run:

```text
$autonomous-maintainer resume
```

See [`examples/invocations.md`](examples/invocations.md) for the complete option summary and additional examples.

## Recommended operating sequence

From the repository you want to maintain:

```bash
omx setup --scope project --merge-agents
omx doctor
omx --worktree=maintenance/autonomous --madmax --xhigh
```

Then invoke the skill inside Codex. Launch flags remain an operator decision; the skill itself does not enable `--madmax`, bypass approval controls, push, merge, deploy, or release.

For a cautious introduction, use:

```text
$autonomous-maintainer mode=report focus=correctness,reliability,tests
```

Review its ledger and plan before starting a separate apply run.

## Optional project policy

The skill already contains its own activation and safety rules. Teams that want an additional repository-level reminder may merge [`examples/AGENTS.md.snippet`](examples/AGENTS.md.snippet) into their existing `AGENTS.md`.

Do not replace an existing `AGENTS.md` wholesale. OMX's project setup supports preserving existing guidance:

```bash
omx setup --scope project --merge-agents
```

## Updating

```bash
git pull --ff-only
./install.sh --scope user --force
```

For project scope:

```bash
git pull --ff-only
./install.sh --scope project --project-dir /path/to/target-repository --force
```

A forced update backs up the previous installed `SKILL.md` beside the destination before replacing it.

## Uninstall

### macOS or Linux

```bash
./uninstall.sh --scope user
./uninstall.sh --scope project --project-dir /path/to/target-repository
```

### Windows PowerShell

```powershell
.\uninstall.ps1 -Scope user
.\uninstall.ps1 -Scope project -ProjectDir C:\path\to\target-repository
```

Uninstallers remove only this skill directory after confirming its name and expected path. They do not remove OMX, `.omx/` run state, or unrelated skills.

## Development

```bash
make validate
make test
```

Or run the commands directly:

```bash
python3 scripts/validate_skill.py SKILL.md
bash tests/test_installers.sh
```

## Important limitations

- No prompt or skill can guarantee that an externally terminated process continues running. The skill instead requires durable state and resumability.
- Repository-wide discovery is bounded by available tools, declared scope, objective evidence, and safety constraints.
- Missing required OMX capabilities must be reported honestly; they are not simulated.
- The skill intentionally forbids remote mutation, push, merge, deployment, release, destructive Git operations, secret handling, and speculative product invention.

## Upstream references

- [Official Oh My Codex repository](https://github.com/Yeachan-Heo/oh-my-codex)
- [OMX skills documentation](https://oh-my-codex.dev/docs/skills.html)
- [OpenAI Codex CLI](https://github.com/openai/codex)

## License

No license has been selected yet. Until a license is added, standard copyright restrictions apply.
