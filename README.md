# Autonomous Maintainer Skills for Codex

Two repository-wide maintenance skills that aggressively discover and apply verifiable improvements, allow large refactors or complete rewrites when accepted observable behavior remains equivalent, and automatically deliver verified work through a dedicated branch and pull request.

| Variant | Skill | Runtime |
|---|---|---|
| Standalone | `autonomous-maintainer-standalone` | Codex, Git, and repository tools |
| OMX | `autonomous-maintainer` | Codex plus Oh My Codex |

## New default behavior in 2.0

The default profile now uses:

```text
mode=apply
focus=all
feature_policy=strong-evidence
resume=true
commit=checkpoint
max_epochs=50
quiescence_scans=3
parallelism=auto
network=public-read
rewrite_policy=aggressive
compatibility=observable-output
delivery=pull-request
pr_state=ready
```

“Aggressive” means exhaustive search and active comparison of large replacement alternatives; it does not mean accepting unverified changes. Every selected transformation must still preserve the chosen compatibility contract and pass the applicable verification, review, rollback, and delivery gates.

This means the maintainer:

- searches every supported category and continues after the first fixes;
- considers module replacement, dependency removal, architecture migration, and whole-codebase rewrites;
- treats internal implementation as replaceable when public and observable behavior remains equivalent;
- captures baseline behavior and uses differential, golden, contract, property, compatibility, and performance checks as applicable;
- commits verified waves to a dedicated `autonomous-maintainer/<run-id>-<slug>` branch;
- pushes that branch and creates or updates a pull request automatically after verification;
- never force-pushes, pushes to the default branch, merges the PR, deploys, releases, exposes secrets, overwrites unrelated work, or weakens valid tests.

## Risks and safeguards

Aggressive transformations can expose incomplete contracts, change undocumented behavior, increase migration complexity, or produce a large review surface. The default workflow mitigates these risks by capturing observable behavior before replacement, strengthening contract tests, comparing baseline and candidate outputs, requiring independent review for high-risk work, retaining candidate-specific rollback evidence, and running three clean repository-wide rescans.

Automatic delivery is limited to a dedicated run branch and a pull request. It does not push to the default branch or merge the PR. Delivery is skipped or marked blocked when repository identity, write permission, secret scanning, verification, branch safety, or PR-target checks fail. Use `pr_state=draft` for additional human review or `delivery=none` to keep all work local.

## Install

Clone the repository:

```bash
git clone https://github.com/tkgo11/autonomous-maintainer-skill.git
cd autonomous-maintainer-skill
```

Standalone, user scope:

```bash
bash ./install.sh --variant standalone --scope user
```

OMX, user scope:

```bash
bash ./install.sh --variant omx --scope user
```

Project scope:

```bash
bash ./install.sh --variant standalone --scope project --project-dir /path/to/repository
bash ./install.sh --variant omx --scope project --project-dir /path/to/repository
```

PowerShell uses the equivalent `install.ps1` arguments.

## Invoke

Standalone:

```text
@autonomous-maintainer-standalone
```

OMX:

```text
$autonomous-maintainer
```

The explicit default invocation is:

```text
mode=apply focus=all feature_policy=strong-evidence resume=true commit=checkpoint max_epochs=50 quiescence_scans=3 parallelism=auto network=public-read rewrite_policy=aggressive compatibility=observable-output delivery=pull-request pr_state=ready
```

Useful overrides:

```text
mode=report                         # read-only audit and transformation plan
rewrite_policy=surgical             # prefer localized changes
delivery=none                       # do not push or create a PR
pr_state=draft                      # create a draft PR
compatibility=public-contract       # preserve all documented public contracts
feature_policy=off                  # do not add missing features
```

## Observable-output compatibility

With the default `compatibility=observable-output`, private implementation, architecture, algorithms, dependencies, and file layout may change. The skill must preserve supported externally observable effects such as public API values and errors, CLI output and exit codes, serialization, emitted files, database effects, documented network behavior, UI-visible semantics, concurrency/cancellation/retry guarantees, and required performance ceilings.

The maintainer must record the comparison corpus and cannot treat missing, skipped, flaky, timed-out, or failed checks as proof of equivalence. Unsupported output differences reopen a finding instead of being normalized away.

## Development

```bash
make validate
make test
```

Direct validation:

```bash
python3 scripts/validate_skill.py SKILL.md
python3 scripts/validate_skill.py standalone/SKILL.md
```

Only the selected `SKILL.md` is required at runtime. The installers keep the two variants in separate skill directories so they may coexist.
