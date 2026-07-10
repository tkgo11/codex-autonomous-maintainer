# Invocation examples

Choose one installed variant:

- `@autonomous-maintainer-standalone` uses Codex capabilities directly and requires no external orchestration framework.
- `$autonomous-maintainer` uses the OMX workflow and helpers.

## Default aggressive apply run

```text
@autonomous-maintainer-standalone
```

or, with OMX:

```text
$autonomous-maintainer
```

The default invocation is intentionally aggressive within local repository boundaries. It discovers and applies every automatically eligible finding across all supported categories, uses public read-only research, creates verified local checkpoint commits, allows up to 25 implementation epochs, and requires two consecutive clean full-scope scans before convergence.

It still never permits push, merge, deployment, release, production mutation, destructive Git cleanup, secret handling, or overwriting unrelated user work.

## Standalone invocation

No separate launcher is required. From the repository you want to maintain:

```text
@autonomous-maintainer-standalone mode=apply focus=all feature_policy=strong-evidence resume=true commit=checkpoint max_epochs=25 quiescence_scans=2 parallelism=auto network=public-read
```

Use `$autonomous-maintainer-standalone` instead when the Codex interface uses dollar-prefixed skill invocation.

## OMX launch and invocation

From the repository you want to maintain, launch OMX in an isolated worktree:

```bash
omx --worktree=maintenance/autonomous --madmax --xhigh
```

Then invoke the skill inside Codex:

```text
$autonomous-maintainer
```

The explicit equivalent is:

```text
$autonomous-maintainer mode=apply focus=all feature_policy=strong-evidence resume=true commit=checkpoint max_epochs=25 quiescence_scans=2 parallelism=auto network=public-read
```

The `--madmax` and `--xhigh` launch flags are operator choices made outside the skill. The skill does not enable them itself.

## Report-only audit

```text
@autonomous-maintainer-standalone mode=report
```

or:

```text
$autonomous-maintainer mode=report
```

Builds the inventory, baseline, findings ledger, dependency graph, and plan without editing implementation files or creating commits.

## Correctness and security focus

```text
@autonomous-maintainer-standalone focus=correctness,reliability,tests,security
```

## Disable autonomous feature additions

```text
@autonomous-maintainer-standalone feature_policy=off
```

## Require explicit documented feature promises

```text
@autonomous-maintainer-standalone feature_policy=documented
```

## Limit parallel work

```text
@autonomous-maintainer-standalone parallelism=4
```

## Offline/local-evidence run

```text
@autonomous-maintainer-standalone network=off
```

## Disable local commits

```text
@autonomous-maintainer-standalone commit=false
```

The aggressive default is `commit=checkpoint`. This override keeps all verified changes uncommitted.

## Single final local commit

```text
@autonomous-maintainer-standalone commit=final
```

This permits at most one verified local commit after the complete final gate passes. It never permits push.

## Constrained run

```text
@autonomous-maintainer-standalone focus=correctness,tests "do not modify frontend/ or add dependencies"
```

## Resume

```text
@autonomous-maintainer-standalone resume
```

## Convergence controls

```text
@autonomous-maintainer-standalone max_epochs=25 quiescence_scans=2
```

`max_epochs` must be greater than or equal to `quiescence_scans`.

## Supported options

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
