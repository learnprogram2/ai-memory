#!/usr/bin/env bash
# run-grafana-query.sh - Execute SQL against the Grafana PostgreSQL datasource
#
# Usage:
#   run-grafana-query.sh --check-only
#   run-grafana-query.sh "SELECT ..."
#
# Required env:
#   POMERIUM_TOKEN  - Value of the _pomerium cookie from your Grafana browser session
#
# Optional env:
#   GRAFANA_URL     - Default: https://grafana.guardian.corp.luxor.tech
#   GRAFANA_PG_UID  - Default: ad72880b-7bd5-4272-b1df-228368e8886f

set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-https://grafana.guardian.corp.luxor.tech}"
GRAFANA_PG_UID="${GRAFANA_PG_UID:-ad72880b-7bd5-4272-b1df-228368e8886f}"

# --- Validate token ---
if [ -z "${POMERIUM_TOKEN:-}" ]; then
  echo "ERROR: POMERIUM_TOKEN is not set." >&2
  echo "" >&2
  echo "To get it:" >&2
  echo "  1. Open $GRAFANA_URL in your browser and log in" >&2
  echo "  2. Press F12 → Network tab → click any request" >&2
  echo "  3. In Request Headers, find the Cookie: header" >&2
  echo "  4. Copy the value of _pomerium=..." >&2
  echo "  5. Run: export POMERIUM_TOKEN='<paste here>'" >&2
  echo "" >&2
  echo "Note: the token expires when your browser session ends." >&2
  exit 1
fi

# --- Check-only mode: verify token is still valid ---
if [ "${1:-}" = "--check-only" ]; then
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H 'x-grafana-org-id: 1' \
    -b "_pomerium=${POMERIUM_TOKEN}" \
    "${GRAFANA_URL}/api/user")
  if [ "$http_code" = "200" ]; then
    echo "✓ Grafana access OK (HTTP 200)"
    exit 0
  else
    echo "ERROR: Grafana returned HTTP ${http_code}. POMERIUM_TOKEN may be expired." >&2
    echo "Renew it: open Grafana in browser → F12 → Network → copy _pomerium cookie value" >&2
    exit 1
  fi
fi

SQL="${1:-}"
if [ -z "$SQL" ]; then
  echo "ERROR: No SQL query provided." >&2
  echo "Usage: $0 \"SELECT ...\"" >&2
  exit 1
fi

# JSON-encode the SQL string
SQL_JSON=$(python3 -c "import json, sys; print(json.dumps(sys.argv[1]))" "$SQL")

curl -s -X POST \
  -H 'Content-Type: application/json' \
  -H 'x-grafana-org-id: 1' \
  -b "_pomerium=${POMERIUM_TOKEN}" \
  -d "{
    \"queries\": [{
      \"refId\": \"A\",
      \"datasource\": {\"uid\": \"${GRAFANA_PG_UID}\"},
      \"rawSql\": ${SQL_JSON},
      \"format\": \"table\"
    }],
    \"range\": {\"from\": \"now-90d\", \"to\": \"now\"}
  }" \
  "${GRAFANA_URL}/api/ds/query"
