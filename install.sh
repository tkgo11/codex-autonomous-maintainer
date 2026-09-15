#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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
  --variant omx|standalone|both
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

VARIANTS=()
case "$VARIANT" in
  omx|standalone) VARIANTS=("$VARIANT") ;;
  both) VARIANTS=(omx standalone) ;;
  *) fail "--variant must be omx, standalone, or both" ;;
esac

[[ "$SCOPE" == "user" || "$SCOPE" == "project" ]] || fail "--scope must be user or project"

if [[ "$SCOPE" == "user" ]]; then
  CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
  TARGET_ROOT="$CODEX_ROOT/skills"
else
  if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="$PWD"
  fi
  [[ -d "$PROJECT_DIR" ]] || fail "project directory does not exist: $PROJECT_DIR"
  PROJECT_DIR="$(CDPATH='' cd -- "$PROJECT_DIR" && pwd)"
  TARGET_ROOT="$PROJECT_DIR/.codex/skills"
fi

tmp_file=""
cleanup() {
  if [[ -n "$tmp_file" ]]; then
    rm -f -- "$tmp_file"
  fi
}
trap cleanup EXIT

install_variant() {
  local variant="$1"
  local skill_name source_dir
  case "$variant" in
    omx)
      skill_name="autonomous-maintainer"
      source_dir="$SCRIPT_DIR"
      ;;
    standalone)
      skill_name="autonomous-maintainer-standalone"
      source_dir="$SCRIPT_DIR/standalone"
      ;;
  esac

  local rel
  for rel in "${MANAGED_FILES[@]}"; do
    [[ -f "$source_dir/$rel" ]] || fail "missing package file: $source_dir/$rel"
  done

  if command -v python3 >/dev/null 2>&1; then
    python3 "$SCRIPT_DIR/scripts/validate_skill.py" "$source_dir/SKILL.md"
  else
    printf 'warning: python3 not found; skipping structural validation\n' >&2
  fi

  local target_dir="$TARGET_ROOT/$skill_name"
  printf 'variant:     %s\n' "$variant"
  printf 'scope:       %s\n' "$SCOPE"
  printf 'source:      %s\n' "$source_dir"
  printf 'destination: %s\n' "$target_dir"

  [[ ! -L "$target_dir" ]] || fail "refusing to install through a symbolic-link destination"
  if [[ -e "$target_dir" && ! -d "$target_dir" ]]; then
    fail "destination exists and is not a directory: $target_dir"
  fi

  local subdir
  for subdir in agents assets; do
    [[ ! -L "$target_dir/$subdir" ]] || fail "refusing to install through a symbolic-link destination: $target_dir/$subdir"
    if [[ -e "$target_dir/$subdir" && ! -d "$target_dir/$subdir" ]]; then
      fail "managed package directory is not a directory: $target_dir/$subdir"
    fi
  done

  local all_current=1 has_conflict=0
  local source_file target_file
  for rel in "${MANAGED_FILES[@]}"; do
    source_file="$source_dir/$rel"
    target_file="$target_dir/$rel"
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
    return 0
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
    return 0
  fi

  mkdir -p "$target_dir/agents" "$target_dir/assets"
  local timestamp backup target_parent base
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

  for rel in "${MANAGED_FILES[@]}"; do
    source_file="$source_dir/$rel"
    target_file="$target_dir/$rel"
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

  printf 'installed:   %s\n' "$target_dir"
}

for variant in "${VARIANTS[@]}"; do
  install_variant "$variant"
done

printf 'next: start a new Codex session and inspect available skills\n'
