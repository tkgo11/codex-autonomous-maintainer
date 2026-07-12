# Invocation examples

## Default aggressive transformation and automatic PR

Standalone:

```text
@autonomous-maintainer-standalone
```

OMX:

```text
$autonomous-maintainer
```

Equivalent explicit options:

```text
mode=apply focus=all feature_policy=strong-evidence resume=true commit=checkpoint max_epochs=50 quiescence_scans=3 parallelism=auto network=public-read rewrite_policy=aggressive compatibility=observable-output delivery=pull-request pr_state=ready
```

The default may replace modules, dependencies, architecture, or the entire implementation when differential verification proves accepted observable behavior is preserved. Verified commits are pushed to a dedicated branch and a ready-for-review PR is created or updated automatically.

## Draft PR

```text
@autonomous-maintainer-standalone pr_state=draft
```

## Keep work local

```text
@autonomous-maintainer-standalone delivery=none
```

## Push a branch without opening a PR

```text
@autonomous-maintainer-standalone delivery=branch
```

## Prefer surgical changes

```text
@autonomous-maintainer-standalone rewrite_policy=surgical
```

## Preserve documented public contracts, not only outputs

```text
@autonomous-maintainer-standalone compatibility=public-contract
```

## Read-only aggressive audit

```text
@autonomous-maintainer-standalone mode=report
```

## Disable autonomous features

```text
@autonomous-maintainer-standalone feature_policy=off
```

## Constrained run

```text
@autonomous-maintainer-standalone "do not modify frontend/ or add runtime dependencies"
```

## Resume

```text
@autonomous-maintainer-standalone resume
```

## Supported options

| Option | Values | Default |
|---|---|---|
| `mode` | `apply`, `report` | `apply` |
| `focus` | `all` or categories | `all` |
| `feature_policy` | `off`, `documented`, `strong-evidence` | `strong-evidence` |
| `resume` | `true`, `false` | `true` |
| `commit` | `false`, `checkpoint`, `final` | `checkpoint` |
| `max_epochs` | `1..100` | `50` |
| `quiescence_scans` | `1..10` | `3` |
| `parallelism` | `auto`, `1..32` | `auto` |
| `network` | `off`, `public-read` | `public-read` |
| `rewrite_policy` | `surgical`, `allow`, `aggressive` | `aggressive` |
| `compatibility` | `observable-output`, `public-contract`, `strict-internals` | `observable-output` |
| `delivery` | `none`, `branch`, `pull-request` | `pull-request` |
| `pr_state` | `draft`, `ready` | `ready` |
