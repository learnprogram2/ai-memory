# LogCLI Recipes

Sources:

- [Getting started](https://grafana.com/docs/loki/latest/query/logcli/getting-started/)
- [Tutorial](https://grafana.com/docs/loki/latest/query/logcli/logcli-tutorial/)

All commands below use raw `logcli` syntax from the docs. When running from this skill, resolve `scripts/run-logcli.sh` relative to the skill directory and wrap commands as `scripts/run-logcli.sh -- <command>`.

Do not default to `namespace=...`. Use `namespace` only when the user requires it or label discovery proves it is the right selector. Do not run real log or metric queries without filtering on a specific `cluster`.

## Discovery

Use these when the user does not know the label set yet.

```bash
logcli labels
logcli labels cluster
logcli labels job
logcli series '{}' --since=1h --analyze-labels
logcli series '{app="journal",cluster="cairo"}' --since=1h
```

If `cluster` is unknown, stop after metadata discovery and ask the user which cluster to use before running log queries.

## Log Queries

Use `query` for line-oriented log searches.

```bash
logcli query '{job="varlogs",cluster="cairo"}' --since=1h --limit=20
logcli query '{app="journal",cluster="cairo"} |= "error"' --since=30m --limit=50
logcli query '{app="journal",cluster="cairo"} |~ "timeout|deadline"' --from=2026-03-17T06:00:00Z --to=2026-03-17T12:00:00Z --limit=200
logcli query '{app="stratumproxyv2",cluster="cairo"} != "healthcheck"' --from=2026-03-17T06:00:00Z --to=2026-03-17T07:00:00Z --limit=100
```

Notes:

- Start with `--since=1h` when the user did not provide a time window.
- If you need to compare or follow up on multiple queries, convert the window to absolute `--from` and `--to` values once and reuse them exactly.
- Add `--forward` only when oldest-first output matters.
- Keep `--limit` explicit to avoid huge responses. Start with `20` or `50`, raise to `200` or `1000` only when needed, and do not exceed `5000` unless the user explicitly asks for that.
- Do not use `--limit=0`.

## Metric Queries

Use `query` for range metrics and `instant-query` for point-in-time metrics.

```bash
logcli query 'sum(count_over_time({app="journal",cluster="cairo"} |= "error"[5m]))' --since=1h --step=5m
logcli instant-query 'sum(count_over_time({app="journal",cluster="cairo"}[5m]))'
```

## Query Diagnostics

Use these when the user wants to understand cost, scan volume, or likely hot streams.

```bash
logcli stats '{app="journal",cluster="cairo"}' --since=24h
logcli volume '{app="journal",cluster="cairo"}' --since=24h --limit=10
logcli volume_range '{app="journal",cluster="cairo"}' --since=24h --step=1h --limit=10
logcli detected-fields '{app="journal",cluster="cairo"}' --since=1h
```

## Larger Exports

Use these only for larger, explicitly bounded pulls.

```bash
logcli query '{app="journal",cluster="cairo"}' \
  --from=2026-03-17T00:00:00Z \
  --to=2026-03-17T01:00:00Z \
  --output=jsonl \
  --parallel-duration=15m \
  --parallel-max-workers=4 \
  --part-path-prefix=/tmp/logcli-journal \
  --merge-parts
```

`--parallel-duration`, `--parallel-max-workers`, `--part-path-prefix`, and `--merge-parts` are useful when a single query window would be too large or slow.
