#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup() { rm -rf -- "$TMP"; }
trap cleanup EXIT

assert_package() {
  local source_dir="$1"
  local target_dir="$2"
  local rel
  for rel in SKILL.md agents/openai.yaml assets/icon.svg; do
    [[ -f "$target_dir/$rel" ]] || {
      echo "missing installed package file: $target_dir/$rel" >&2
      exit 1
    }
    cmp "$source_dir/$rel" "$target_dir/$rel"
  done
}

assert_package_removed() {
  local target_dir="$1"
  local rel
  for rel in SKILL.md agents/openai.yaml assets/icon.svg; do
    [[ ! -e "$target_dir/$rel" ]] || {
      echo "managed package file survived uninstall: $target_dir/$rel" >&2
      exit 1
    }
  done
}

python3 "$ROOT/scripts/validate_skill.py" "$ROOT/SKILL.md"
python3 "$ROOT/scripts/validate_skill.py" "$ROOT/standalone/SKILL.md"

if bash "$ROOT/install.sh" --variant invalid >/dev/null 2>&1; then
  echo 'expected an unknown variant to fail' >&2
  exit 1
fi

export HOME="$TMP/home"
export CODEX_HOME="$HOME/.codex"
mkdir -p "$HOME"

bash "$ROOT/install.sh" --scope user
USER_DIR="$HOME/.codex/skills/autonomous-maintainer"
USER_FILE="$USER_DIR/SKILL.md"
assert_package "$ROOT" "$USER_DIR"
bash "$ROOT/install.sh" --scope user

bash "$ROOT/install.sh" --variant standalone --scope user
STANDALONE_USER_DIR="$HOME/.codex/skills/autonomous-maintainer-standalone"
STANDALONE_USER_FILE="$STANDALONE_USER_DIR/SKILL.md"
assert_package "$ROOT/standalone" "$STANDALONE_USER_DIR"
bash "$ROOT/install.sh" --variant standalone --scope user

printf '\n# local modification\n' >> "$USER_FILE"
if bash "$ROOT/install.sh" --scope user >/dev/null 2>&1; then
  echo 'expected non-forced overwrite to fail' >&2
  exit 1
fi
bash "$ROOT/install.sh" --scope user --force
assert_package "$ROOT" "$USER_DIR"
find "$USER_DIR" -maxdepth 1 -name 'SKILL.md.backup-*' | grep -q .

LEGACY_PROJECT="$TMP/legacy-project"
mkdir -p "$LEGACY_PROJECT/.codex/skills/autonomous-maintainer-standalone"
cp "$ROOT/standalone/SKILL.md" "$LEGACY_PROJECT/.codex/skills/autonomous-maintainer-standalone/SKILL.md"
bash "$ROOT/install.sh" --variant standalone --scope project --project-dir "$LEGACY_PROJECT"
assert_package "$ROOT/standalone" "$LEGACY_PROJECT/.codex/skills/autonomous-maintainer-standalone"

DRY_PROJECT="$TMP/dry-project"
mkdir -p "$DRY_PROJECT"
bash "$ROOT/install.sh" --scope project --project-dir "$DRY_PROJECT" --dry-run
[[ ! -e "$DRY_PROJECT/.codex/skills/autonomous-maintainer/SKILL.md" ]]
[[ ! -e "$DRY_PROJECT/.codex/skills/autonomous-maintainer/agents/openai.yaml" ]]

LINK_PROJECT="$TMP/link-project"
LINK_TARGET="$TMP/link-target"
mkdir -p "$LINK_PROJECT/.codex/skills" "$LINK_TARGET"
cp "$ROOT/SKILL.md" "$LINK_TARGET/SKILL.md"
ln -s "$LINK_TARGET" "$LINK_PROJECT/.codex/skills/autonomous-maintainer"
if bash "$ROOT/install.sh" --scope project --project-dir "$LINK_PROJECT" >/dev/null 2>&1; then
  echo 'expected symbolic-link destination to be rejected' >&2
  exit 1
fi
if bash "$ROOT/uninstall.sh" --scope project --project-dir "$LINK_PROJECT" --yes >/dev/null 2>&1; then
  echo 'expected symbolic-link uninstallation to be rejected' >&2
  exit 1
fi
[[ -f "$LINK_TARGET/SKILL.md" ]]

PROJECT="$TMP/project"
mkdir -p "$PROJECT"
bash "$ROOT/install.sh" --scope project --project-dir "$PROJECT"
PROJECT_DIR="$PROJECT/.codex/skills/autonomous-maintainer"
assert_package "$ROOT" "$PROJECT_DIR"

bash "$ROOT/install.sh" --variant standalone --scope project --project-dir "$PROJECT"
STANDALONE_PROJECT_DIR="$PROJECT/.codex/skills/autonomous-maintainer-standalone"
assert_package "$ROOT/standalone" "$STANDALONE_PROJECT_DIR"

printf 'keep me\n' > "$STANDALONE_PROJECT_DIR/user-note.txt"
bash "$ROOT/uninstall.sh" --variant standalone --scope project --project-dir "$PROJECT" --yes
assert_package_removed "$STANDALONE_PROJECT_DIR"
[[ -f "$STANDALONE_PROJECT_DIR/user-note.txt" ]]

bash "$ROOT/uninstall.sh" --scope project --project-dir "$PROJECT" --yes
assert_package_removed "$PROJECT_DIR"

bash "$ROOT/uninstall.sh" --variant standalone --scope user --yes
assert_package_removed "$STANDALONE_USER_DIR"

bash "$ROOT/uninstall.sh" --scope user --yes
assert_package_removed "$USER_DIR"
# A forced-install backup remains intentionally, so the directory may remain.

echo 'ok: installer smoke tests passed'
