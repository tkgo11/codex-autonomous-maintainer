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

# Validator contract fixtures.
FIXTURE="$TMP/fixture-skill"
mkdir -p "$FIXTURE/agents" "$FIXTURE/assets"
cp "$ROOT/agents/openai.yaml" "$FIXTURE/agents/openai.yaml"
cp "$ROOT/assets/icon.svg" "$FIXTURE/assets/icon.svg"

# A skill document whose invocation table drops an enforced option must fail.
sed '/^| `permission_fallback`/d' "$ROOT/SKILL.md" > "$FIXTURE/SKILL.md"
if python3 "$ROOT/scripts/validate_skill.py" "$FIXTURE/SKILL.md" >/dev/null 2>&1; then
  echo 'expected option-table drift to fail validation' >&2
  exit 1
fi

# A quoted frontmatter name is normalized by the validator and must still pass.
sed 's/^name: autonomous-maintainer$/name: "autonomous-maintainer"/' "$ROOT/SKILL.md" > "$FIXTURE/SKILL.md"
python3 "$ROOT/scripts/validate_skill.py" "$FIXTURE/SKILL.md"

# Metadata keys under the wrong top-level mapping must fail.
sed 's/^  display_name: .*$/  display_name: "Moved"/' "$ROOT/agents/openai.yaml" > "$FIXTURE/agents/openai.yaml"
python3 - "$FIXTURE/agents/openai.yaml" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
out, moved = [], False
for line in lines:
    if line.startswith("  display_name:"):
        continue
    out.append(line)
    if line == "policy:" and not moved:
        out.append('  display_name: "Moved"')
        moved = True
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
cp "$ROOT/SKILL.md" "$FIXTURE/SKILL.md"
if python3 "$ROOT/scripts/validate_skill.py" "$FIXTURE/SKILL.md" >/dev/null 2>&1; then
  echo 'expected metadata key under wrong mapping to fail validation' >&2
  exit 1
fi
cp "$ROOT/agents/openai.yaml" "$FIXTURE/agents/openai.yaml"

# Release-version consistency validator.
RELEASE_FIXTURE="$TMP/release-fixture"
mkdir -p "$RELEASE_FIXTURE"
printf '9.9.9\n' > "$RELEASE_FIXTURE/VERSION"
printf '# Changelog\n\n## 9.9.9 — 2030-01-01\n\n- entry\n' > "$RELEASE_FIXTURE/CHANGELOG.md"
printf 'Current version: **9.9.9**.\n' > "$RELEASE_FIXTURE/README.md"
python3 "$ROOT/scripts/validate_release.py" --root "$RELEASE_FIXTURE"
printf '9.9.8\n' > "$RELEASE_FIXTURE/VERSION"
if python3 "$ROOT/scripts/validate_release.py" --root "$RELEASE_FIXTURE" >/dev/null 2>&1; then
  echo 'expected version drift to fail validation' >&2
  exit 1
fi

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
