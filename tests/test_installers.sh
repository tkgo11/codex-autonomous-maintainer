#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup() { rm -rf -- "$TMP"; }
trap cleanup EXIT

python3 "$ROOT/scripts/validate_skill.py" "$ROOT/SKILL.md"

export HOME="$TMP/home"
mkdir -p "$HOME"

"$ROOT/install.sh" --scope user
USER_FILE="$HOME/.codex/skills/autonomous-maintainer/SKILL.md"
cmp "$ROOT/SKILL.md" "$USER_FILE"

"$ROOT/install.sh" --scope user

printf '\n# local modification\n' >> "$USER_FILE"
if "$ROOT/install.sh" --scope user >/dev/null 2>&1; then
  echo 'expected non-forced overwrite to fail' >&2
  exit 1
fi
"$ROOT/install.sh" --scope user --force
cmp "$ROOT/SKILL.md" "$USER_FILE"
find "$(dirname "$USER_FILE")" -maxdepth 1 -name 'SKILL.md.backup-*' | grep -q .

DRY_PROJECT="$TMP/dry-project"
mkdir -p "$DRY_PROJECT"
"$ROOT/install.sh" --scope project --project-dir "$DRY_PROJECT" --dry-run
[[ ! -e "$DRY_PROJECT/.codex/skills/autonomous-maintainer/SKILL.md" ]]

LINK_PROJECT="$TMP/link-project"
LINK_TARGET="$TMP/link-target"
mkdir -p "$LINK_PROJECT/.codex/skills" "$LINK_TARGET"
ln -s "$LINK_TARGET" "$LINK_PROJECT/.codex/skills/autonomous-maintainer"
if "$ROOT/install.sh" --scope project --project-dir "$LINK_PROJECT" >/dev/null 2>&1; then
  echo 'expected symbolic-link destination to be rejected' >&2
  exit 1
fi

PROJECT="$TMP/project"
mkdir -p "$PROJECT"
"$ROOT/install.sh" --scope project --project-dir "$PROJECT"
PROJECT_FILE="$PROJECT/.codex/skills/autonomous-maintainer/SKILL.md"
cmp "$ROOT/SKILL.md" "$PROJECT_FILE"

"$ROOT/uninstall.sh" --scope project --project-dir "$PROJECT" --yes
[[ ! -f "$PROJECT_FILE" ]]

"$ROOT/uninstall.sh" --scope user --yes
[[ ! -f "$USER_FILE" ]]
# A backup remains intentionally, so the directory may remain.

echo 'ok: installer smoke tests passed'
