#!/usr/bin/env bash

set -euo pipefail

readonly GRAFANA_URL="${GRAFANA_URL:-https://grafana.guardian.corp.luxor.tech}"
readonly GRAFANA_LOKI_PROXY="${GRAFANA_URL}/api/datasources/proxy/1"
readonly EXPECTED_LOKI_ADDR="https://loki-custom-auth.corp.luxor.tech"

usage() {
  cat <<'EOF'
Usage:
  run-logcli.sh [--addr URL] [--username USER] [--password PASS] [--check-only] [--] <logcli args...>

Authentication (two modes, in priority order):

  Mode 1 — Pomerium cookie (same as orphan-check):
    POMERIUM_TOKEN  Value of the _pomerium cookie from your Grafana browser session
    Queries go through https://grafana.guardian.corp.luxor.tech/api/datasources/proxy/1

  Mode 2 — Direct Loki Basic Auth:
    LOKI_ADDR      Loki server address (default: https://loki-custom-auth.corp.luxor.tech)
    LOKI_USERNAME  HTTP basic auth username
    LOKI_PASSWORD  HTTP basic auth password

To get POMERIUM_TOKEN:
  1. Open https://grafana.guardian.corp.luxor.tech in your browser and log in
  2. Press F12 → Network tab → click any request
  3. In Request Headers, find the Cookie: header
  4. Copy the value of _pomerium=...
  5. Run: export POMERIUM_TOKEN='<paste here>'

Note: the token expires when your browser session ends.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

find_logcli_binary() {
  local candidate dir entry
  local IFS=':'

  if [[ -n "${LOGCLI_BIN:-}" ]]; then
    [[ -x "${LOGCLI_BIN}" ]] || die "LOGCLI_BIN is set but not executable: ${LOGCLI_BIN}"
    printf '%s\n' "${LOGCLI_BIN}"
    return 0
  fi

  candidate="$(command -v logcli 2>/dev/null || true)"
  if [[ -n "${candidate}" ]]; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  for dir in ${PATH}; do
    [[ -d "${dir}" ]] || continue
    for entry in "${dir}"/logcli*; do
      [[ -e "${entry}" ]] || continue
      [[ -x "${entry}" && ! -d "${entry}" ]] || continue
      printf '%s\n' "${entry}"
      return 0
    done
  done

  return 1
}

# --- Parse CLI overrides ---
addr_override=""
username_override=""
password_override=""
check_only=0

while (($# > 0)); do
  case "$1" in
    --addr)
      (($# >= 2)) || die "--addr requires a value"
      addr_override="$2"
      shift 2
      ;;
    --username)
      (($# >= 2)) || die "--username requires a value"
      username_override="$2"
      shift 2
      ;;
    --password)
      (($# >= 2)) || die "--password requires a value"
      password_override="$2"
      shift 2
      ;;
    --check-only)
      check_only=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

binary="$(find_logcli_binary)" || die "could not find a logcli binary in PATH. Install it and retry."

# --- Resolve auth mode ---
pomerium_token="${POMERIUM_TOKEN:-}"
loki_addr="${addr_override:-${LOKI_ADDR:-}}"
loki_username="${username_override:-${LOKI_USERNAME:-}}"
loki_password="${password_override:-${LOKI_PASSWORD:-}}"

if [[ -n "${pomerium_token}" ]]; then
  # Mode 1: Pomerium cookie → route through Grafana datasource proxy
  auth_mode="pomerium"
  effective_addr="${GRAFANA_LOKI_PROXY}"
elif [[ -n "${loki_addr}" && -n "${loki_username}" && -n "${loki_password}" ]]; then
  # Mode 2: Direct Basic Auth
  auth_mode="basic"
  effective_addr="${loki_addr}"
else
  # Neither mode satisfied — report what's missing
  if [[ -z "${pomerium_token}" && -z "${loki_username}" ]]; then
    die "no credentials found. Set POMERIUM_TOKEN (Grafana cookie) or set LOKI_ADDR + LOKI_USERNAME + LOKI_PASSWORD for direct Loki access. Run with --help for instructions."
  elif [[ -n "${loki_addr}" || -n "${loki_username}" || -n "${loki_password}" ]]; then
    missing=()
    [[ -n "${loki_addr}" ]]     || missing+=("LOKI_ADDR")
    [[ -n "${loki_username}" ]] || missing+=("LOKI_USERNAME")
    [[ -n "${loki_password}" ]] || missing+=("LOKI_PASSWORD")
    die "incomplete direct-auth settings: ${missing[*]}. Expected Loki address: ${EXPECTED_LOKI_ADDR}"
  else
    die "no credentials found. Set POMERIUM_TOKEN or LOKI_ADDR + LOKI_USERNAME + LOKI_PASSWORD. Run with --help for instructions."
  fi
fi

# --- Check-only mode ---
if ((check_only)); then
  (($# == 0)) || die "--check-only does not accept logcli arguments"

  if [[ "${auth_mode}" == "pomerium" ]]; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -b "_pomerium=${pomerium_token}" \
      -H 'x-grafana-org-id: 1' \
      "${GRAFANA_URL}/api/user")
    if [[ "${http_code}" == "200" ]]; then
      printf 'logcli ready\n'
      printf 'binary=%s\n' "${binary}"
      printf 'auth_mode=pomerium\n'
      printf 'LOKI_ADDR=%s\n' "${effective_addr}"
      printf 'credentials=present\n'
      exit 0
    else
      die "Grafana returned HTTP ${http_code}. POMERIUM_TOKEN may be expired. Renew: open Grafana in browser → F12 → Network → copy _pomerium cookie value"
    fi
  else
    printf 'logcli ready\n'
    printf 'binary=%s\n' "${binary}"
    printf 'auth_mode=basic\n'
    printf 'LOKI_ADDR=%s\n' "${effective_addr}"
    printf 'credentials=present\n'
    exit 0
  fi
fi

(($# > 0)) || die "missing logcli arguments. Pass them after --, for example: run-logcli.sh -- labels"

# --- Execute logcli ---
export LOKI_ADDR="${effective_addr}"

if [[ "${auth_mode}" == "pomerium" ]]; then
  unset LOKI_USERNAME LOKI_PASSWORD LOKI_BEARER_TOKEN 2>/dev/null || true
  exec "${binary}" \
    --header "Cookie: _pomerium=${pomerium_token}" \
    --header "x-grafana-org-id: 1" \
    "$@"
else
  export LOKI_USERNAME="${loki_username}"
  export LOKI_PASSWORD="${loki_password}"
  exec "${binary}" "$@"
fi