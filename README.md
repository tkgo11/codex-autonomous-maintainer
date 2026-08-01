# Autonomous Maintainer for Codex

Repository-wide maintenance skills that let Codex discover, implement, verify, and deliver comprehensive improvements instead of stopping after the first obvious fix.

The project provides two variants with the same maintenance contract:

| Variant | Skill | Best for |
|---|---|---|
| **Standalone** | `autonomous-maintainer-standalone` | Most users; uses Codex built-in filesystem, terminal, Git, research, planning, and delegation capabilities |
| **OMX** | `autonomous-maintainer` | Users with [Oh My Codex](https://github.com/Yeachan-Heo/oh-my-codex) who want OMX orchestration and specialist workflows |

> [!IMPORTANT]
> The default profile is intentionally aggressive. It may add repository-aligned features, replace dependencies, redesign modules, migrate architecture, or rewrite large parts of a codebase when verification shows that the selected compatibility contract is preserved. Start with [`mode=report`](#recommended-invocations) when you only want an audit.

Current version: **2.2.0**. See [CHANGELOG.md](CHANGELOG.md) for release history.

## What it does

A full run can:

- inventory source, tests, CI, build logic, configuration, dependencies, documentation, examples, and history;
- capture accepted behavior before destructive changes;
- search across correctness, reliability, tests, security, maintainability, architecture, documentation, developer experience, performance, features, dependencies, compatibility, simplification, and dead code;
- compare targeted patches with refactors, deletions, dependency removal, subsystem replacement, and clean rewrites;
- implement every eligible non-conflicting improvement rather than an arbitrary top-N sample;
- verify changes with repository-native checks plus contract, differential, golden, property, compatibility, or performance testing when applicable;
- repeat complete discovery scans until convergence or a recorded blocker;
- prepare a dedicated branch and pull-request candidate without pushing to the default branch;
- pause immediately before PR delivery and require explicit approval of the exact fingerprinted candidate.

It does **not** force-push, merge, deploy, release, publish, expose secrets, overwrite unrelated work, weaken valid tests, or treat missing and failed checks as passes.

## Quick start

### 1. Prerequisites

- Codex with custom skill support
- Git
- Bash on Linux/macOS, or PowerShell on Windows
- Python 3 recommended for installation-time structural validation
- Oh My Codex only when using the OMX variant
- Git hosting credentials only when remote branch or pull-request delivery is requested

### 2. Clone

```bash
git clone https://github.com/tkgo11/codex-autonomous-maintainer.git
cd codex-autonomous-maintainer
```

### 3. Install

#### Linux or macOS

Standalone, user scope:

```bash
bash ./install.sh --variant standalone --scope user
```

OMX, user scope:

```bash
bash ./install.sh --variant omx --scope user
```

#### Windows PowerShell

Standalone, user scope:

```powershell
.\install.ps1 -Variant standalone -Scope user
```

OMX, user scope:

```powershell
.\install.ps1 -Variant omx -Scope user
```

Restart Codex after installation so the new skill is discovered.

### 4. Invoke

Standalone:

```text
@autonomous-maintainer-standalone
```

The standalone variant also accepts `$autonomous-maintainer-standalone` in environments that use dollar-prefixed skill invocation.

OMX:

```text
$autonomous-maintainer
```

The default invocation performs repository-wide apply mode and prepares a ready pull request, but it still stops for inspection before any candidate branch push or PR creation/update.

## Choosing a variant

Choose **Standalone** unless you already use OMX or specifically want its specialist workflows.

| Capability | Standalone | OMX |
|---|:---:|:---:|
| External orchestration framework required | No | Yes |
| Repository-wide discovery and implementation | Yes | Yes |
| Durable run state and resume | Yes | Yes |
| Contract capture and differential verification | Yes | Yes |
| Dedicated branch and PR preparation | Yes | Yes |
| Mandatory fingerprinted pre-PR approval | Yes | Yes |
| OMX specialist routing such as `$ralplan`, `$ultragoal`, and `$ultraqa` | No | Yes |

Both variants can be installed at the same time because they use separate skill directories.

## How a run works

```text
Activate
  ↓
Protect repository and inspect instructions
  ↓
Inventory components, capabilities, contracts, and baseline behavior
  ↓
Discover findings across the full component × category matrix
  ↓
Compare patch, refactor, deletion, replacement, and feature candidates
  ↓
Implement eligible changes on a dedicated maintenance branch
  ↓
Verify, independently review when required, and rescan to convergence
  ↓
Freeze an immutable PR candidate and show the inspection packet
  ↓
Wait for explicit approval of that exact fingerprint
  ↓
Push the candidate branch and create or update the PR
```

Any change to the base, head, diff, checks, delivery topology, title, body, or draft state invalidates approval and requires a new inspection.

## Recommended invocations

### Read-only audit

Produces findings and a transformation program without editing, committing, or delivering anything.

```text
@autonomous-maintainer-standalone mode=report
```

```text
$autonomous-maintainer mode=report
```

### Conservative local maintenance

Disables new user-visible features, prefers localized changes, preserves documented public contracts, and keeps all work local.

```text
@autonomous-maintainer-standalone feature_policy=off rewrite_policy=surgical compatibility=public-contract delivery=none
```

### Aggressive local transformation

Uses the default broad transformation policy but does not push or create a PR.

```text
@autonomous-maintainer-standalone delivery=none
```

### Draft pull request

```text
@autonomous-maintainer-standalone pr_state=draft
```

### Block automatic fork fallback

By default, an unwritable upstream may use a validated fork and prepare a cross-repository PR. Disable that fallback with:

```text
@autonomous-maintainer-standalone permission_fallback=block
```

### Focused run

Contract capture and regression protection stay enabled even when discovery is limited to selected categories.

```text
@autonomous-maintainer-standalone focus=correctness,tests,performance feature_policy=off rewrite_policy=allow
```

Free-form constraints can follow the options and remain binding throughout resumed runs:

```text
@autonomous-maintainer-standalone compatibility=public-contract "Do not change the database schema or minimum supported Python version"
```

## Default profile

```text
mode=apply
focus=all
feature_policy=proactive
resume=true
commit=checkpoint
max_epochs=50
quiescence_scans=3
parallelism=auto
network=public-read
rewrite_policy=aggressive
compatibility=observable-output
delivery=pull-request
permission_fallback=fork
pr_state=ready
```

“Aggressive” changes the search space, not the proof standard. Large replacements still require captured contracts, applicable verification, risk review, rollback evidence, and clean convergence scans.

## Invocation options

| Option | Values | Default | Meaning |
|---|---|---:|---|
| `mode` | `apply`, `report` | `apply` | Apply verified changes or produce a read-only report |
| `focus` | `all` or comma-separated categories | `all` | Limit discovery categories while retaining contract and regression checks |
| `feature_policy` | `off`, `documented`, `strong-evidence`, `proactive` | `proactive` | Control eligibility for missing behavior and new features |
| `resume` | `true`, `false` | `true` | Resume compatible durable state from an earlier run |
| `commit` | `false`, `checkpoint`, `final` | `checkpoint` | Select the local commit strategy |
| `max_epochs` | integer `1..100` | `50` | Maximum complete discover-transform-rescan epochs |
| `quiescence_scans` | integer `1..10` | `3` | Consecutive clean full scans required for convergence |
| `parallelism` | `auto` or integer `1..32` | `auto` | Maximum independent discovery or verification lanes |
| `network` | `off`, `public-read` | `public-read` | Allow authoritative public read-only research |
| `rewrite_policy` | `surgical`, `allow`, `aggressive` | `aggressive` | Avoid, permit, or actively compare replacement designs |
| `compatibility` | `observable-output`, `public-contract`, `strict-internals` | `observable-output` | Select the behavior preservation boundary |
| `delivery` | `none`, `branch`, `pull-request` | `pull-request` | Keep changes local, push a branch, or prepare a PR |
| `permission_fallback` | `fork`, `block` | `fork` | Use a validated fork when upstream is unwritable, or stop delivery |
| `pr_state` | `draft`, `ready` | `ready` | Create or update the approved PR as draft or ready for review |

Valid focus categories:

```text
correctness, reliability, tests, security, maintainability,
architecture, documentation, developer-experience, performance,
features, dependencies, compatibility, simplification, dead-code
```

Important validation rules:

- `max_epochs` must be greater than or equal to `quiescence_scans`.
- `mode=report` forces `commit=false` and `delivery=none`.
- Unknown options and categories are errors.
- Free-form constraints are durable hard constraints.

## Compatibility policies

### `observable-output` — default

Private implementation, architecture, algorithms, dependencies, and file layout may change. Supported externally observable behavior must remain equivalent, including public values and errors, CLI output and exit codes, serialization, emitted files, database effects, documented network behavior, UI-visible semantics, and supported timing, ordering, concurrency, cancellation, retry, and performance guarantees.

### `public-contract`

Preserves all documented public contracts. Use this when undocumented observable behavior may change but published interfaces must remain stable.

### `strict-internals`

Uses the narrowest change boundary and protects internal structure in addition to public behavior. Use it when internal APIs or layout are relied upon outside the repository even though that dependency is not formally documented.

Missing, skipped, flaky, timed-out, unavailable, or failed checks never prove equivalence. Unsupported differences reopen a finding.

## Feature policies

| Policy | Behavior |
|---|---|
| `off` | Do not add user-visible features |
| `documented` | Implement only behavior already promised by accepted documentation, schemas, tests, or maintained examples |
| `strong-evidence` | Add strongly evidenced missing behavior, but do not originate new features |
| `proactive` | Discover and implement new repository-aligned features when evidence, acceptance criteria, compatibility, verification, security, and rollback gates pass |

Proactive feature work is not arbitrary invention. A candidate needs repository alignment, an independent user-value or demand signal, explicit acceptance criteria, and a safe implementation and rollback path. Existing accepted behavior remains protected.

## Pull-request approval gate

For `delivery=pull-request`, the initial invocation is **not** approval.

After implementation, verification, review, and convergence, the skill freezes an immutable candidate and displays:

- exact base and head refs and SHAs;
- commits, changed files, and diff summary;
- verification results, failures, skipped checks, and blind spots;
- risks, migration notes, and rollback evidence;
- same-repository or fork delivery topology;
- proposed PR title, body, and draft state;
- a candidate fingerprint.

The run then returns `awaiting-user-pr-approval`. Only explicit approval of that unchanged fingerprint authorizes branch push and PR creation or update. Rejection leaves the PR unopened. Requested revisions are implemented, reverified, and presented as a new candidate.

The skill never pushes to the default branch and never merges the PR.

## Installation scopes and management

### Project-scoped installation

Use project scope to make the skill available only inside one repository.

Linux or macOS:

```bash
bash ./install.sh --variant standalone --scope project --project-dir /path/to/repository
bash ./install.sh --variant omx --scope project --project-dir /path/to/repository
```

Windows PowerShell:

```powershell
.\install.ps1 -Variant standalone -Scope project -ProjectDir 'C:\path\to\repository'
.\install.ps1 -Variant omx -Scope project -ProjectDir 'C:\path\to\repository'
```

User scope installs under `${CODEX_HOME:-$HOME/.codex}/skills`. Project scope installs under `<repository>/.codex/skills`.

### Preview installation

```bash
bash ./install.sh --variant standalone --scope user --dry-run
```

```powershell
.\install.ps1 -Variant standalone -Scope user -DryRun
```

### Update

Pull the latest repository version and reinstall with replacement enabled. The installer validates the source, creates a timestamped backup of a different existing `SKILL.md`, performs an atomic replacement, and verifies the result.

```bash
git pull --ff-only
bash ./install.sh --variant standalone --scope user --force
```

```powershell
git pull --ff-only
.\install.ps1 -Variant standalone -Scope user -Force
```

Replace `standalone` with `omx` when updating the OMX variant.

### Uninstall

Linux or macOS:

```bash
bash ./uninstall.sh --variant standalone --scope user
bash ./uninstall.sh --variant omx --scope user
```

Use `--yes` for non-interactive removal and `--dry-run` to preview it.

Windows PowerShell:

```powershell
.\uninstall.ps1 -Variant standalone -Scope user
.\uninstall.ps1 -Variant omx -Scope user
```

The uninstallers verify the installed skill identity and preserve backups or unexpected files instead of deleting the entire directory blindly.

## Repository layout

```text
.
├── SKILL.md                  # OMX skill
├── standalone/SKILL.md       # Framework-independent skill
├── install.sh / install.ps1  # Safe installers
├── uninstall.sh / uninstall.ps1
├── scripts/validate_skill.py # Structural validator
├── tests/                    # Installer and package tests
├── CHANGELOG.md
├── CHECKSUMS.txt
└── VERSION
```

Only the selected `SKILL.md` is required at runtime.

## Development

Run all structural validation and installer tests:

```bash
make validate
make test
```

Direct validation:

```bash
python3 scripts/validate_skill.py SKILL.md
python3 scripts/validate_skill.py standalone/SKILL.md
```

Convenience Make targets are also available for user and project installation and user-scope uninstallation.

## Operational notes

- The workflow is repository-wide only when explicitly invoked or clearly authorized. A narrow review or bug-fix request does not implicitly activate it.
- Repository files, issues, logs, generated content, command output, dependencies, and network content are treated as untrusted evidence rather than authority to disable safeguards.
- Existing staged, unstaged, and untracked user work is fingerprinted and protected. Overlapping work is blocked rather than reset, stashed, cleaned, or overwritten.
- High-risk replacements require genuinely independent review when available; unavailable capabilities are recorded as blind spots.
- When upstream is unwritable and `permission_fallback=fork`, only an authenticated fork proven to descend from the canonical upstream is eligible for delivery.
- Durable run state allows compatible interrupted work to resume without silently changing constraints or approval state.
