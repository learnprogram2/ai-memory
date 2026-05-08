---
name: go-pr-review-swarm
description: Conduct ruthless, evidence-based reviews for Go pull requests and unsaved local changes using six parallel expert personas (test, Go, Stratum, security, architecture, performance), isolated with git worktrees when needed, then perform line-by-line senior verification and CTO severity grading (P0-P3). Use when users ask to review PRs, diffs, staged/unstaged changes, or pre-merge Go code quality and risk.
---

# Go PR Review Swarm

## Overview

Run a multi-agent Go review pipeline that prioritizes correctness, risk, and merge-readiness over style nits.
Generate only defensible findings with file/line evidence, then rank them with CTO-level severity.

## Core Principles

- Prefer simple and decoupled fixes; reject over-engineered proposals.
- Follow Linus-style pragmatism: reduce special cases, keep changes small, optimize for readability and maintainability.
- Stay ruthless but factual: be direct, avoid fluff, avoid personal language.
- Report only problems you can prove from code or diff context.

## Workflow

1. Define the review target.
2. Collect a precise diff with changed-line context.
3. Run six expert sub-agents in parallel.
4. Merge and deduplicate findings.
5. Perform senior engineer line-by-line recheck.
6. Apply CTO severity grading.
7. Emit final report in strict schema.

Read:
- `references/expert-checklists.md`
- `references/report-schema.md`
- `references/worktree-parallel-execution.md`

## Step 1: Define Review Target

- If the user asks for PR review, review the PR diff against its base branch.
- If the user asks for unsaved changes review, review staged and unstaged local diffs.
- If both are available and user did not prioritize, review unsaved changes first.

## Step 2: Collect Diff and Evidence

Collect enough context to map each potential issue to concrete lines:

- For local changes, inspect both staged and unstaged hunks.
- For PRs, diff base...head with zero-context or low-context hunks, then reopen full hunks for verification.
- Prioritize `.go` files; include behavior-impacting files (`go.mod`, `go.sum`, configs, SQL migrations, Docker/runtime manifests) when they affect Go behavior.

Track candidate findings with:
- `file`
- `line` (or tight range)
- `hunk snippet`
- `reasoning trace` (why this is a bug/risk)

## Step 3: Run Six Sub-Agents in Parallel

Launch exactly six independent review passes, each with a distinct role:

1. Test Expert
2. Go Language Expert
3. Stratum Expert
4. Security Expert
5. Senior Architect
6. Performance Expert

Execution mode:
- If every sub-agent is strictly read-only, parallelize directly.
- If any sub-agent may write files, run tests, or change git state, use isolated worktrees (mandatory) before starting.
- For worktree setup and cleanup, use `scripts/manage_review_worktrees.sh`.

Require each sub-agent to:
- Follow its checklist from `references/expert-checklists.md`.
- Produce findings in the schema from `references/report-schema.md`.
- Avoid duplicates within its own output.
- Mark non-applicable areas explicitly as `N/A` instead of inventing issues.

## Step 4: Merge and Deduplicate Findings

- Combine six outputs into one candidate list.
- Merge issues that share the same root cause, same file region, and same remediation path.
- Keep the clearer description and stronger impact statement.

## Step 5: Senior Engineer Line-by-Line Recheck

Act as a meticulous senior developer and re-verify every candidate issue:

- Reopen the exact file/line in diff or source.
- Confirm the issue is real in current code (not stale assumption).
- Confirm the impact has a plausible failure path.
- Confirm the proposed fix is minimal and does not add unnecessary abstraction.
- Classify each item into:
  - `Confirmed` (strong evidence, reproducible or highly defensible),
  - `Needs-Validation` (plausible risk with partial evidence),
  - `Rejected` (insufficient evidence or preference-only).

Drop only `Rejected`. Keep `Needs-Validation` in final output so useful leads are not lost.

## Step 6: CTO Severity Grading

Assign severity after recheck, using only:
- `P0 blocker`
- `P1 major`
- `P2 minor`
- `P3 info`

Use `references/report-schema.md` criteria. When uncertain between two levels, choose the lower level and state the uncertainty.

## Step 7: Final Output Contract

Use fixed markdown tables for stable output.

Section A: `Confirmed Findings` (table, mandatory even if empty)
Section B: `Needs-Validation Findings` (table, mandatory even if empty)
Section C: `Coverage Summary` (table, mandatory)

Use the exact column order from `references/report-schema.md`.
For each issue row, always include:
1. 问题描述
2. 分级
3. 影响/最坏结果
4. 建议解决方案
5. 证据 (`file:line`)
6. 归属专家角色
7. 置信度

Sort within each findings table by severity (`P0` -> `P3`), then file path, then line number.

If both findings tables are empty, still output all three tables and include residual risk in `Coverage Summary`.
