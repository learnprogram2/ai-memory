# Orphan Check Command

Check orphan block status and orphan rate from the production PostgreSQL database via Grafana.

**Skill**: `.agents/skills/orphan-check/SKILL.md`

## Usage

```
/orphan-check [coin] [--days N]
```

- `coin`: coin schema name or alias (bitcoin/btc, litecoin/ltc, siacoin/sc, etc.). Defaults to `bitcoin`.
- `--days N`: how many days back for the orphan rate table. Defaults to 14.

## Instructions

Follow the workflow in `.agents/skills/orphan-check/SKILL.md` exactly:

1. **Resolve access**: Check `POMERIUM_TOKEN` env var. Run `--check-only` first. Stop with renewal instructions if it fails.
2. **Determine coin(s)** from the argument. If none specified, check all supported coins and show a summary table.
3. **Run three queries** per coin via `.agents/skills/orphan-check/scripts/run-grafana-query.sh`:
   - **Query A** — Orphan rate over last N blocks by height (matches production Grafana alert logic)
   - **Query B** — Individual orphaned block list (height, hash, time, luck) over last N blocks
   - **Query C** — Orphan rate by day (last `--days` days, default 14)
4. **Report** a clean summary table (all coins), orphaned block details, and daily rate trend.