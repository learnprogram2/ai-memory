#!/usr/bin/env bash
set -euo pipefail

ROLES=(test go stratum security architecture performance)

resolve_git_bin() {
  if [[ -x "/opt/homebrew/bin/git" ]]; then
    echo "/opt/homebrew/bin/git"
    return 0
  fi
  command -v git
}

usage() {
  cat <<'EOF'
Usage:
  manage_review_worktrees.sh setup --repo <path> --base <rev> --patch <patch-file> --root <tmp-root>
  manage_review_worktrees.sh cleanup --repo <path> --root <tmp-root>

Examples:
  manage_review_worktrees.sh setup --repo "$(pwd)" --base "HEAD" --patch "/tmp/go-review.patch" --root "/tmp/go-pr-review-swarm"
  manage_review_worktrees.sh cleanup --repo "$(pwd)" --root "/tmp/go-pr-review-swarm"
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

MODE="$1"
shift

REPO=""
BASE="HEAD"
PATCH=""
ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --base)
      BASE="$2"
      shift 2
      ;;
    --patch)
      PATCH="$2"
      shift 2
      ;;
    --root)
      ROOT="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${REPO}" || -z "${ROOT}" ]]; then
  echo "--repo and --root are required" >&2
  usage
  exit 2
fi

if [[ "${MODE}" == "setup" && -z "${PATCH}" ]]; then
  echo "--patch is required for setup" >&2
  usage
  exit 2
fi

if [[ ! -d "${REPO}" ]]; then
  echo "repo does not exist: ${REPO}" >&2
  exit 1
fi

GIT_BIN="$(resolve_git_bin)"

if [[ -z "${GIT_BIN}" ]]; then
  echo "git binary not found" >&2
  exit 1
fi

if ! "${GIT_BIN}" -C "${REPO}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not a git repo: ${REPO}" >&2
  exit 1
fi

if [[ "${MODE}" == "setup" ]]; then
  if [[ ! -f "${PATCH}" ]]; then
    echo "patch file does not exist: ${PATCH}" >&2
    exit 1
  fi

  mkdir -p "${ROOT}"
  touch "${ROOT}/.review-worktrees"
  mkdir -p "${ROOT}/cache"
  ENV_FILE="${ROOT}/worktrees.env"
  : > "${ENV_FILE}"

  for role in "${ROLES[@]}"; do
    WT_PATH="${ROOT}/${role}"
    if [[ -e "${WT_PATH}" ]]; then
      echo "worktree path already exists: ${WT_PATH}" >&2
      echo "run cleanup first or choose a new --root" >&2
      exit 1
    fi

    "${GIT_BIN}" -C "${REPO}" worktree add --detach "${WT_PATH}" "${BASE}"
    "${GIT_BIN}" -C "${WT_PATH}" apply "${PATCH}"

    CACHE_BASE="${ROOT}/cache/${role}"
    mkdir -p "${CACHE_BASE}/gocache" "${CACHE_BASE}/gomodcache" "${CACHE_BASE}/gotmp"

    {
      echo "${role}_worktree=${WT_PATH}"
      echo "${role}_gocache=${CACHE_BASE}/gocache"
      echo "${role}_gomodcache=${CACHE_BASE}/gomodcache"
      echo "${role}_gotmp=${CACHE_BASE}/gotmp"
    } >> "${ENV_FILE}"
  done

  echo "setup complete"
  echo "env file: ${ENV_FILE}"
  exit 0
fi

if [[ "${MODE}" == "cleanup" ]]; then
  if [[ ! -f "${ROOT}/.review-worktrees" ]]; then
    echo "marker not found at ${ROOT}/.review-worktrees; refusing cleanup" >&2
    exit 1
  fi

  for role in "${ROLES[@]}"; do
    WT_PATH="${ROOT}/${role}"
    if [[ -d "${WT_PATH}" ]]; then
      "${GIT_BIN}" -C "${REPO}" worktree remove --force "${WT_PATH}" || true
    fi
  done

  rm -f "${ROOT}/worktrees.env" "${ROOT}/.review-worktrees"
  rm -rf "${ROOT}/cache"
  rmdir "${ROOT}" 2>/dev/null || true

  echo "cleanup complete"
  exit 0
fi

echo "unknown mode: ${MODE}" >&2
usage
exit 2
