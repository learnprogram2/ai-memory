# Report Schema and Severity

Use this schema for every finding after senior recheck.

## Required Per-Issue Fields

- `title`: One-line issue label.
- `role`: One of `test`, `go`, `stratum`, `security`, `architecture`, `performance`.
- `severity`: `P0 blocker` | `P1 major` | `P2 minor` | `P3 info`.
- `description`: What is wrong and where.
- `impact_worst_case`: Production/business worst case.
- `suggested_fix`: Minimal practical fix, no over-design.
- `evidence`: `path:line` plus a short, concrete snippet summary.
- `confidence`: `high` | `medium` | `low`.
- `status`: `Confirmed` | `Needs-Validation` | `Rejected`.

## CTO Severity Rubric

### P0 blocker

Use when merge must be blocked immediately.

Typical triggers:
- Critical security exploitability.
- Data corruption or irreversible inconsistency.
- Protocol/consensus break in core Stratum flow.
- High-likelihood outage or financial loss.

### P1 major

Use for serious defects that should be fixed before release.

Typical triggers:
- High-impact functional bug.
- Race/deadlock/panic risk in realistic runtime paths.
- Major performance regression likely to violate SLO.
- Significant architecture breach with near-term failure risk.

### P2 minor

Use for non-blocking but meaningful quality issues.

Typical triggers:
- Maintainability risk with moderate future cost.
- Missing tests around important but non-critical behavior.
- Moderate inefficiency outside critical hot paths.

### P3 info

Use for low-risk improvements or observations.

Typical triggers:
- Useful hardening suggestions.
- Nice-to-have clarity improvements.

## Confidence and Retention Policy

Apply this policy after line-by-line recheck:

- `Confirmed`: Evidence is concrete and reasoning is defensible end-to-end.
- `Needs-Validation`: Risk is plausible but evidence is incomplete; keep it in final report.
- `Rejected`: Not actionable or not evidenced enough; remove from final report.

Default confidence mapping:

- `high` -> Prefer `Confirmed`
- `medium` -> Prefer `Needs-Validation`
- `low` -> Prefer `Rejected`

Never auto-upgrade a `low` confidence issue unless new evidence is found.

## False-Positive Filter (Hard Reject Rules)

Before finalizing, reject any issue that fails one or more checks:

- Cannot point to exact `file:line`.
- Cannot explain a plausible failure path.
- Depends on assumptions not supported by the diff/context.
- Suggests heavy refactor where a small local fix solves it.

## Table Output Format (Stable)

Always output exactly three markdown tables in this order:

1. `Confirmed Findings`
2. `Needs-Validation Findings`
3. `Coverage Summary`

### Confirmed Findings / Needs-Validation Findings

Use this exact header:

| ID | Status | Severity | Role | File:Line | 问题描述 | 影响/最坏结果 | 建议解决方案 | Confidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

Rules:

- Keep `Status` fixed as either `Confirmed` or `Needs-Validation`.
- Keep one issue per row.
- Keep wording concise and concrete.
- Keep rows sorted by severity, then file path, then line.

### Coverage Summary

Use this exact header:

| Role | Files/Areas Reviewed | Findings Count | Notes |
| --- | --- | --- | --- |

Rules:

- Include one row per expert role (always 6 rows).
- If a role found nothing, explain why in `Notes`.

## Output Ordering

Sort by:
1. Severity (`P0` -> `P3`)
2. File path
3. Line number

If no issues survive filtering:

- Keep all three tables.
- Keep `Confirmed Findings` and `Needs-Validation Findings` as header-only (no rows).
- Use `Coverage Summary` notes to state reviewed scope and residual risk.
