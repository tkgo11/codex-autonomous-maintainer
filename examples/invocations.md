# Invocation examples

## Default apply run

```text
$autonomous-maintainer
```

Discovers and applies all automatically eligible findings across all supported categories.

## Report-only audit

```text
$autonomous-maintainer mode=report
```

Builds the inventory, baseline, findings ledger, dependency graph, and plan without editing implementation files.

## Correctness and security focus

```text
$autonomous-maintainer focus=correctness,reliability,tests,security
```

## Disable autonomous feature additions

```text
$autonomous-maintainer feature_policy=off
```

## Require explicit documented feature promises

```text
$autonomous-maintainer feature_policy=documented
```

## Limit parallel work

```text
$autonomous-maintainer parallelism=4
```

## Offline/local-evidence run

```text
$autonomous-maintainer network=off
```

## Local checkpoint commits

```text
$autonomous-maintainer commit=checkpoint
```

This permits verified local commits only. It never permits push.

## Constrained run

```text
$autonomous-maintainer focus=correctness,tests "do not modify frontend/ or add dependencies"
```

## Resume

```text
$autonomous-maintainer resume
```

## Convergence controls

```text
$autonomous-maintainer max_epochs=12 quiescence_scans=3
```

`max_epochs` must be greater than or equal to `quiescence_scans`.

## Supported options

| Option | Values | Default |
|---|---|---|
| `mode` | `apply`, `report` | `apply` |
| `focus` | `all` or comma-separated categories | `all` |
| `feature_policy` | `off`, `documented`, `strong-evidence` | `strong-evidence` |
| `resume` | `true`, `false` | `true` |
| `commit` | `false`, `checkpoint`, `final` | `false` |
| `max_epochs` | `1..50` | `10` |
| `quiescence_scans` | `1..5` | `3` |
| `parallelism` | `auto`, `1..16` | `auto` |
| `network` | `off`, `public-read` | `public-read` |

Valid focus categories:

```text
correctness, reliability, tests, security, maintainability,
documentation, developer-experience, performance, features,
dependencies, compatibility
```
