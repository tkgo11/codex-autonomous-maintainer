#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VARIANT="omx"
SCOPE="user"
PROJECT_DIR=""
FORCE=0
DRY_RUN=0
MANAGED_FILES=("SKILL.md" "agents/openai.yaml" "assets/icon.svg")

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --variant omx|standalone
                         Skill variant (default: omx)
  --scope user|project   Installation scope (default: user)
  --project-dir PATH     Target repository for project scope (default: current directory)
  --force                Back up and replace conflicting managed files
  --dry-run              Print actions without changing files
  -h, --help             Show this help
USAGE
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --variant)
      (($# >= 2)) || fail "--variant requires a value"
      VARIANT="$2"
      shift 2
      ;;
    --scope)
      (($# >= 2)) || fail "--scope requires a value"
      SCOPE="$2"
      shift 2
      ;;
    --project-dir)
      (($# >= 2)) || fail "--project-dir requires a path"
      PROJECT_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

case "$VARIANT" in
  omx)
    SKILL_NAME="autonomous-maintainer"
    SOURCE_DIR="$SCRIPT_DIR"
    ;;
  standalone)
    SKILL_NAME="autonomous-maintainer-standalone"
    SOURCE_DIR="$SCRIPT_DIR/standalone"
    ;;
  *)
    fail "--variant must be omx or standalone"
    ;;
esac

[[ "$SCOPE" == "user" || "$SCOPE" == "project" ]] || fail "--scope must be user or project"

for rel in "${MANAGED_FILES[@]}"; do
  [[ -f "$SOURCE_DIR/$rel" ]] || fail "missing package file: $SOURCE_DIR/$rel"
done

if command -v python3 >/dev/null 2>&1; then
  python3 "$SCRIPT_DIR/scripts/validate_skill.py" "$SOURCE_DIR/SKILL.md"
else
  printf 'warning: python3 not found; skipping structural validation\n' >&2
fi

if [[ "$SCOPE" == "user" ]]; then
  CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
  TARGET_ROOT="$CODEX_ROOT/skills"
else
  if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="$PWD"
  fi
  [[ -d "$PROJECT_DIR" ]] || fail "project directory does not exist: $PROJECT_DIR"
  PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
  TARGET_ROOT="$PROJECT_DIR/.codex/skills"
fi

TARGET_DIR="$TARGET_ROOT/$SKILL_NAME"
printf 'variant:     %s\n' "$VARIANT"
printf 'scope:       %s\n' "$SCOPE"
printf 'source:      %s\n' "$SOURCE_DIR"
printf 'destination: %s\n' "$TARGET_DIR"

[[ ! -L "$TARGET_DIR" ]] || fail "refusing to install through a symbolic-link destination"
if [[ -e "$TARGET_DIR" && ! -d "$TARGET_DIR" ]]; then
  fail "destination exists and is not a directory: $TARGET_DIR"
fi

for subdir in agents assets; do
  [[ ! -L "$TARGET_DIR/$subdir" ]] || fail "refusing to install through a symbolic-link destination: $TARGET_DIR/$subdir"
  if [[ -e "$TARGET_DIR/$subdir" && ! -d "$TARGET_DIR/$subdir" ]]; then
    fail "managed package directory is not a directory: $TARGET_DIR/$subdir"
  fi
done

all_current=1
has_conflict=0
for rel in "${MANAGED_FILES[@]}"; do
  source_file="$SOURCE_DIR/$rel"
  target_file="$TARGET_DIR/$rel"
  [[ ! -L "$target_file" ]] || fail "refusing to replace symbolic link: $target_file"
  if [[ -e "$target_file" ]]; then
    [[ -f "$target_file" ]] || fail "managed package path is not a file: $target_file"
    if ! cmp -s "$source_file" "$target_file"; then
      all_current=0
      has_conflict=1
    fi
  else
    all_current=0
  fi
done

if [[ "$all_current" -eq 1 ]]; then
  printf 'already installed and up to date\n'
  exit 0
fi

if [[ "$has_conflict" -eq 1 && "$FORCE" -ne 1 ]]; then
  fail "a different managed package file already exists; rerun with --force to back up and replace conflicts"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'dry-run: would install missing managed files'
  if [[ "$has_conflict" -eq 1 ]]; then
    printf ' and back up/replace conflicting managed files'
  fi
  printf '\n'
  exit 0
fi

mkdir -p "$TARGET_DIR/agents" "$TARGET_DIR/assets"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
tmp_file=""
cleanup() {
  if [[ -n "$tmp_file" ]]; then
    rm -f -- "$tmp_file"
  fi
}
trap cleanup EXIT

for rel in "${MANAGED_FILES[@]}"; do
  source_file="$SOURCE_DIR/$rel"
  target_file="$TARGET_DIR/$rel"
  if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
    continue
  fi

  if [[ -f "$target_file" ]]; then
    backup="$target_file.backup-$timestamp-$$"
    cp -p "$target_file" "$backup"
    printf 'backup:      %s\n' "$backup"
  fi

  target_parent="$(dirname -- "$target_file")"
  base="$(basename -- "$target_file")"
  tmp_file="$(mktemp "$target_parent/.$base.tmp.XXXXXX")"
  cp "$source_file" "$tmp_file"
  chmod 0644 "$tmp_file"
  mv -f "$tmp_file" "$target_file"
  tmp_file=""
  cmp -s "$source_file" "$target_file" || fail "post-install verification failed: $rel"
done
trap - EXIT

printf 'installed:   %s\n' "$TARGET_DIR"
printf 'next: start a new Codex session and inspect available skills\n'
