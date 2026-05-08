---
name: loki-logcli
description: Use LogCLI against Luxor Loki when Codex needs to inspect, search, or summarize logs from Grafana Loki. Trigger for requests to check logs, list labels or streams, inspect recent errors for a service or namespace, run a LogQL query with `logcli`, measure query stats or volume, or export a bounded slice of logs.
---

# Loki LogCLI

## Overview

Use this skill to query Luxor's Loki with `logcli` after validating credentials and binary availability. Prefer the wrapper script so env resolution, binary discovery, and failure messages stay consistent. Treat `cluster` selection and bounded time windows as mandatory guardrails for any actual log query.

## Workflow

### 1. Resolve access first

- Prefer user-provided overrides for `LOKI_ADDR`, `LOKI_USERNAME`, and `LOKI_PASSWORD`.
- Otherwise read those values from the current shell environment.
- Treat any empty or missing value as a hard error. Do not silently inject defaults.
- The expected Luxor Loki address is `https://loki-custom-auth.corp.luxor.tech`.
- Run `scripts/run-logcli.sh --check-only` before the first query in a session or whenever auth looks suspect.
- If the wrapper reports missing env or no `logcli` binary, stop and return that error.

### 2. Resolve the cluster before log queries

- Every real log or metric query must include a specific `cluster="..."` selector.
- Do not assume the service/app or cluster when the user did not specify them.
- If the user did not specify a cluster and you cannot infer it safely, use label metadata only to enumerate candidate cluster values.
- Prefer `labels cluster` for a quick list of cluster values. Use `series '{}' --since=1h --analyze-labels` only when you need broader label discovery.
- If `cluster` is still unknown after discovery, offer the user a short cluster selection and wait for the choice before running log queries.
- Do not assume a `namespace` label exists or is needed. Add `namespace=...` only when the user explicitly asks for it or label discovery shows it is the correct discriminator.

### 3. Pick the right LogCLI command

- Read [references/logcli-recipes.md](references/logcli-recipes.md) for the command patterns.
- Use `labels` to list labels or values for a specific label.
- Use `series` with `--analyze-labels` when the user does not know which labels to filter on.
- Use `query` for log lines and range metric queries.
- Use `instant-query` for a point-in-time metric query.
- Use `stats` to inspect query cost, timing, and scanned bytes.
- Use `volume` or `volume_range` when the user wants bytes or top streams by volume.
- Use `detected-fields` when the user wants parsed fields from structured logs.

### 4. Normalize and bound the query

- Avoid unbounded queries. If the user does not specify a time range, start with `--since=1h` for one exploratory query.
- If you need to compare multiple queries or reuse the exact same window for follow-up work, convert the window to absolute timestamps once and reuse the same `--from` and `--to` across every query.
- Prefer `--since` for a single exploratory query.
- Prefer `--from` and `--to` for comparisons, aggregations, or follow-up queries that must match the same window exactly.
- Every `logcli query` must include an explicit `--limit`.
- Start low and increase only as needed:
  - `--limit=20` or `--limit=50` for a narrow validation query
  - `--limit=200` for a focused follow-up query
  - `--limit=1000` for a broader aggregation query
- Do not use `--limit=0`, and do not exceed `--limit=5000` unless the user explicitly asks for a higher limit.
- Use `--forward` only when the user wants oldest-first output. Otherwise keep the default newest-first order.
- Prefer exact stream selectors before adding filters like `|=`, `!=`, `|~`, or parser stages.
- For large exports, use `--output=jsonl` and the parallel download flags from the reference file.

### 5. Run through the wrapper

- Resolve `scripts/run-logcli.sh` relative to this skill directory before executing it.
- Invoke the wrapper with `--` before the real `logcli` arguments.
- Prefer shell env over command-line secrets. If the user explicitly provides overrides, pass them once and do not repeat them back.
- Do not echo `LOKI_PASSWORD` or include it in the final response.

```bash
scripts/run-logcli.sh --check-only

scripts/run-logcli.sh -- \
  labels cluster

scripts/run-logcli.sh -- \
  query '{app="statservice",cluster="cairo"} |= "error"' --since=30m --limit=50

scripts/run-logcli.sh -- \
  query '{app="statservice",cluster="cairo"} |= "error"' \
  --from=2026-03-17T06:00:00Z --to=2026-03-17T07:00:00Z --limit=200

scripts/run-logcli.sh -- \
  series '{app="statservice",cluster="cairo"}' --since=1h --analyze-labels
```

### 6. Report results

- State the selector or query, time window, and limit that you used.
- Summarize the important findings instead of dumping raw output unless the user asked for the raw lines.
- If no logs match, suggest the next refinement: broader time range, different labels, or a discovery step with `labels` or `series`.
- When auth or binary resolution fails, surface the exact wrapper error instead of improvising.

## Guardrails

- Do not assume the service/app or cluster when the user did not specify them.
- Do not run log queries without filtering by a specific `cluster`.
- If `cluster` is unknown, offer the user a cluster selection and wait for the choice before running log queries.
- Do not compare multiple relative queries run at different moments. Normalize them to one absolute window first.
- Do not use `--limit=0`.
- Do not omit `--limit`, and do not jump straight to a high limit. Start low, then increase only as needed.
- Do not exceed `--limit=5000` unless the user explicitly asks for a higher limit.
