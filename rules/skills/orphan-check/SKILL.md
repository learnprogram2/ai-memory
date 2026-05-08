---
name: orphan-check
description: Check orphan block status and orphan rate from the production PostgreSQL database via Grafana. Use when asked to check orphaned blocks, orphan rate, pending blocks, or block confirmation status for any supported coin.
---

# Orphan Check

## Overview

Query orphan block data from production PostgreSQL through the Grafana datasource API using the Pomerium session cookie for authentication. The orphan rate is calculated over the **last N blocks by height** (not by time), matching the logic used in production Grafana alerts.

## Coin configuration

| Alias | Schema | Last N blocks | Alert threshold |
|-------|--------|--------------|-----------------|
| btc   | bitcoin   | 100 | no alert configured |
| ltc   | litecoin  | 200 | any orphan in last 24h |
| sc / sia | siacoin | 200 | > 2% |
| doge  | dogecoin  | 100 | > 3% |
| zec   | zcash     | 200 | > 2% |
| zen   | horizen   | 200 | > 2% |
| fb    | fractal   | 200 | > 10% |

If the user does not specify a coin, check **all** coins above and show a summary table.

## Workflow

### 1. Resolve access first

- Read `POMERIUM_TOKEN` from the current shell environment.
- Treat a missing or empty value as a hard error — do not proceed.
- Run `scripts/run-grafana-query.sh --check-only` before the first query in a session.
- If the check fails (non-200), stop and show renewal steps:
  1. Open `https://grafana.guardian.corp.luxor.tech` in browser and log in
  2. F12 → Network tab → click any request → Request Headers → find `Cookie:`
  3. Copy the `_pomerium=...` value
  4. `export POMERIUM_TOKEN='<paste here>'`

### 2. For each coin: run three queries

**Query A — Orphan rate (last N blocks by height)**

Use the exact same pattern as the production Grafana alerts:

```sql
WITH latest_blocks AS (
  SELECT *
  FROM <schema>.blocks
  ORDER BY height DESC
  LIMIT <N>
)
SELECT
  COUNT(*)                                                        AS total,
  COUNT(*) FILTER (WHERE orphaned = true)                        AS orphaned_count,
  COUNT(*) FILTER (WHERE orphaned IS NULL)                       AS pending_count,
  TRUNC(
    (COUNT(*) FILTER (WHERE orphaned = true))::numeric
    / NULLIF(COUNT(*), 0)
  , 4) * 100                                                     AS orphan_rate_pct
FROM latest_blocks;
```

**Query B — Recent orphan blocks (last N blocks by height)**

```sql
WITH latest_blocks AS (
  SELECT *
  FROM <schema>.blocks
  ORDER BY height DESC
  LIMIT <N>
)
SELECT height, hash, time, luck
FROM latest_blocks
WHERE orphaned = true
ORDER BY height DESC;
```

**Query C — Orphan rate by day (last N days)**

```sql
SELECT
  date_trunc('day', time)                                           AS day,
  COUNT(*)                                                          AS total,
  COUNT(*) FILTER (WHERE orphaned = true)                          AS orphaned_count,
  TRUNC(
    (COUNT(*) FILTER (WHERE orphaned = true))::numeric
    / NULLIF(COUNT(*), 0)
  , 4) * 100                                                        AS orphan_rate_pct
FROM <schema>.blocks
WHERE time >= NOW() - INTERVAL '<N> days'
GROUP BY 1
ORDER BY 1 DESC;
```

Default N = 14 days unless the user specifies `--days`.

### 3. Format output

For each coin, print one status line, then a detail table if orphans were found:

```
== Orphan Check ==

Coin   Schema     Last N   Total   Orphaned   Pending   Rate     Status
------ ---------- ------   -----   --------   -------   ------   ------
BTC    bitcoin      100     100        0          0      0.00%    ✓ OK
LTC    litecoin     200     200        1          2      0.50%    ⚠ ALERT (orphan in last 24h)
SIA    siacoin      200     198        5          2      2.53%    ✗ ALERT (> 2%)
DOGE   dogecoin     100      99        0          1      0.00%    ✓ OK
ZEC    zcash        200     200        0          0      0.00%    ✓ OK
ZEN    horizen      200     196        0          4      0.00%    ✓ OK
FB     fractal      200     200       18          0      9.00%    ✓ OK (< 10%)

--- Orphaned blocks detail ---

[SIA] siacoin — 5 orphaned in last 200 blocks:
  height   hash (short)          time                  luck
  -------  --------------------  --------------------  -----
  ...

[LTC] litecoin — 1 orphaned in last 200 blocks:
  ...

--- Pending blocks (orphaned IS NULL) ---
  LTC: 2 pending  ZEN: 4 pending
```

Status rules:
- `✗ ALERT` — rate exceeds the configured threshold
- `⚠ ALERT` — LTC: any orphan exists within last 24h (check `time` column)
- `✓ OK` — rate below threshold
- If `pending_count > 10`, add a note: "⚠ N pending blocks not yet checked"

### 4. Single-coin mode

If the user specifies one coin, run the same two queries for that coin only and show the full block list without truncation (up to 50 rows).

### 5. Handle errors

- `relation "<schema>.blocks" does not exist` → schema name is wrong; list valid schemas from the table above
- HTTP 401/403 → token expired; show renewal steps
- Division by zero in orphan rate → all blocks are pending; report as "N/A (all pending)"

## Wrapper usage

```bash
scripts/run-grafana-query.sh --check-only
scripts/run-grafana-query.sh "SELECT ..."
```

Raw JSON response: parse `results.A.frames[0].data.values` — each element is an array for one column.

The `time` field is returned as **Unix milliseconds** (e.g., `1775641715090`). Convert to UTC with:
```python
from datetime import datetime, timezone
t = datetime.fromtimestamp(ts_ms / 1000, tz=timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
```

## Guardrails

- Always run `--check-only` before the first query in a session.
- Never proceed if `POMERIUM_TOKEN` is unset.
- Do not print the value of `POMERIUM_TOKEN`.
- Always use `LIMIT` in queries.
