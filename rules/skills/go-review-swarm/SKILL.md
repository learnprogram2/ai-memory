---
name: go-review-swarm
description: Multi-agent Go code review swarm (tests, Go, Stratum, security, architecture, performance) with senior engineer line-by-line verification (anti-hallucination) and CTO severity triage (P0–P3). Ruthless, simple-design, Linus-style pragmatism.
argument-hint: "<PR link|diff|paths> [--scope <pkg/dir>] [--context <notes>] [--output <path>]"
---

# go-review-swarm

Ruthless Go code review using 6 parallel specialist reviewers, then merge/dedupe, then strict verification to eliminate fake issues, then CTO severity grading.

Hard preferences:
- No over-engineering. Smallest fix wins.
- Simple > clever. Delete complexity.
- Decouple only if it reduces *current* complexity.
- Linus-style pragmatism: evidence > vibes. Reality > elegance.
- Ruthless tone toward code. No personal attacks.

Final requirement: every issue MUST include
- Description
- Severity (P0/P1/P2/P3)
- Impact / worst case
- Suggested fix
- Location (file:lines or diff hunk)
- Evidence (1–3 key lines excerpt or exact identifier)

---

## Inputs

Target:
- PR link OR diff/patch OR file/dir paths.

Optional:
- `--scope`: directories/packages to focus on
- `--context`: domain constraints/invariants (e.g., Stratum rules, SLOs)
- `--output`: write final report to a path (otherwise print to chat)

---

## Output

Provide:

1) **Summary**
- counts by P0/P1/P2/P3
- top 3 risks

2) **Issues** (sorted by severity then impact)
- Use the Issue Schema below

3) **Fix these first** (top 3 minimal actions)

---

## Issue Schema (final)

### GO-REV-XXX — <title>
- Location: `<path>:Lx-Ly` (or `<diff hunk>`)
- Severity: `P0|P1|P2|P3`
- Description: ...
- Impact / worst case: ...
- Suggested fix: ...
- Evidence: `<1–3 lines excerpt OR identifier>`

---

## Execution Plan

### Phase 0 — Preflight (Supervisor)
- Identify artifact (PR/diff/paths) and scope (changed files).
- Record invariants from `--context`.
- If Stratum is irrelevant to the code touched, the Stratum reviewer may output “No issues found.”

### Phase 1 — Parallel specialist reviews (6 roles)
Run 6 reviewers in parallel. Each reviewer MUST:
- Use subagent.
- Only report issues provable from the code shown.
- Include Location + Evidence for every issue.
- If nothing relevant: output exactly `No issues found.` and stop.
- Do NOT assign final severity (may suggest only).

Roles:
1. Test expert
2. Go expert
3. Stratum expert
4. Security expert
5. Senior architect
6. Performance expert

### Phase 2 — Merge + dedupe (Supervisor)
- Combine overlapping findings into a single candidate issue per root cause.
- Drop anything missing Location+Evidence.
- Drop “rewrite/refactor everything” suggestions; keep minimal diffs.

### Phase 3 — Senior engineer verification (anti-hallucination)
Line-by-line verification gate:
- Confirm the referenced code exists and the claim matches it.
- Provide a concrete failure path.
- If unprovable: drop it (preferred) or downgrade to info-only (P3) with explicit assumption.
  Hard gate:
- If you cannot include a short Evidence excerpt (1–3 lines) that directly supports the issue → drop.

### Phase 4 — CTO triage (P0–P3)
CTO sees ONLY verified issues and assigns final severity.

Severity rubric:
- P0 blocker: fund loss, protocol break, exploitable vuln, data corruption, deadlock/crash-loop/high-prob outage
- P1 major: serious correctness bug (lower probability), significant perf regression/leak, major ops risk
- P2 minor: maintainability cost, missing tests, minor inefficiency not clearly hot-path
- P3 info: nits, optional improvements, assumption-dependent notes

---

## Sub-agent Prompt Template (copy/paste per role)

Use this template for each role in Phase 1.

ROLE: <Test|Go|Stratum|Security|Architect|Performance>

Target:
- <PR link|diff|paths>
  Scope:
- <optional --scope>
  Context:
- <optional --context>

Rules:
- No overdesign. Smallest fix wins.
- If you can’t prove it from code: don’t report it.
- Every issue MUST include Location + Evidence (1–3 key lines excerpt).
- If nothing relevant: output exactly `No issues found.`

Output format:

### CAND-<ROLE>-NNN — <title>
- Location: ...
- Description: ...
- Impact / worst case: ...
- Suggested fix: ...
- Evidence: ...

---

## CTO Triage Template (Phase 4)

Input: VERIFIED issues only.

For each VERIFIED issue:
- Assign Severity P0–P3 using rubric
- Keep fixes minimal
- Output using final Issue Schema
- Sort: P0 → P1 → P2 → P3

---

## Notes
- Avoid “design patterns”. Prefer straightforward Go.
- Prefer small interfaces and explicit dataflow.
- Prefer bounded resources: timeouts, limits, backpressure.
