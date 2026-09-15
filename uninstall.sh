#!/usr/bin/env bash
set -Eeuo pipefail

VARIANT="omx"
SCOPE="user"
PROJECT_DIR=""
DRY_RUN=0
YES=0
MANAGED_FILES=("SKILL.md" "agents/openai.yaml" "assets/icon.svg")

usage() {
  cat <<'USAGE'
Usage: ./uninstall.sh [options]

Options:
  --variant omx|standalone|both
                         Skill variant (default: omx)
  --scope user|project   Installation scope (default: user)
  --project-dir PATH     Target repository for project scope (default: current directory)
  --yes                  Do not prompt for confirmation
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
    --yes)
      YES=1
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
  TARGET_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
else
  [[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$PWD"
  [[ -d "$PROJECT_DIR" ]] || fail "project directory does not exist: $PROJECT_DIR"
  PROJECT_DIR="$(CDPATH= cd -- "$PROJECT_DIR" && pwd)"
  TARGET_ROOT="$PROJECT_DIR/.codex/skills"
fi

uninstall_variant() {
  local variant="$1"
  local skill_name
  case "$variant" in
    omx) skill_name="autonomous-maintainer" ;;
    standalone) skill_name="autonomous-maintainer-standalone" ;;
  esac

  local target_dir="$TARGET_ROOT/$skill_name"
  local target_file="$target_dir/SKILL.md"

  local candidate rel
  for candidate in "$target_dir" "$target_dir/agents" "$target_dir/assets"; do
    [[ ! -L "$candidate" ]] || fail "refusing to uninstall through a symbolic-link destination: $candidate"
  done
  for rel in "${MANAGED_FILES[@]}"; do
    [[ ! -L "$target_dir/$rel" ]] || fail "refusing to remove symbolic link: $target_dir/$rel"
  done

  if [[ ! -f "$target_file" ]]; then
    printf 'not installed: %s\n' "$target_file"
    return 0
  fi

  local first_name first_char last_char
  first_name="$(sed -n '/^---$/,/^---$/s/^name:[[:space:]]*//p' "$target_file" | head -n 1)"
  first_name="${first_name%"${first_name##*[![:space:]]}"}"
  if [[ ${#first_name} -ge 2 ]]; then
    first_char="${first_name:0:1}"
    last_char="${first_name: -1}"
    if [[ ( "$first_char" == '"' || "$first_char" == "'" ) && "$last_char" == "$first_char" ]]; then
      first_name="${first_name:1:-1}"
    fi
  fi
  [[ "$first_name" == "$skill_name" ]] || fail "refusing to remove an unexpected skill: name=$first_name"

  printf 'remove managed package files from: %s\n' "$target_dir"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: no files removed\n'
    return 0
  fi

  if [[ "$YES" -ne 1 ]]; then
    if [[ ! -t 0 ]]; then
      fail "confirmation required in non-interactive mode; pass --yes"
    fi
    read -r -p "Remove managed skill package files from $target_dir? [y/N] " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]] || {
      printf 'cancelled\n'
      return 0
    }
  fi

  local target_file_path
  for rel in "${MANAGED_FILES[@]}"; do
    target_file_path="$target_dir/$rel"
    if [[ -f "$target_file_path" ]]; then
      rm -f -- "$target_file_path"
    fi
  done

  rmdir "$target_dir/agents" 2>/dev/null || true
  rmdir "$target_dir/assets" 2>/dev/null || true

  # Preserve backups and any unexpected user-managed files.
  if rmdir "$target_dir" 2>/dev/null; then
    printf 'removed skill package directory\n'
  else
    printf 'removed managed package files; preserved other files in %s\n' "$target_dir"
  fi
}

for variant in "${VARIANTS[@]}"; do
  uninstall_variant "$variant"
done
