# Changelog

## 1.2.0 — 2026-07-10

- Added `autonomous-maintainer-standalone`, a framework-independent Codex variant that has no external orchestration-skill dependency.
- Added safe `omx` and `standalone` variant selection to the POSIX and PowerShell installers and uninstallers while preserving the existing default.
- Added structural independence checks, installer smoke coverage, CI validation, documentation, and invocation examples for both variants.

## 1.1.0 — 2026-07-03

- Changed the default profile to aggressive repository-wide apply mode with verified local checkpoint commits.
- Increased the default maintenance budget to 25 epochs and reduced convergence to two consecutive clean full-scope scans.
- Added a ready-to-copy Linux OMX launch command and an explicit equivalent invocation.
- Preserved the no-push, no-merge, no-deploy, no-release, and unrelated-user-work safety boundaries.

## 1.0.0 — 2026-07-02

- Added the autonomous-maintainer OMX skill.
- Added safe user/project installers for POSIX shells and PowerShell.
- Added uninstallers, structural validation, installer smoke tests, CI, examples, and documentation.
