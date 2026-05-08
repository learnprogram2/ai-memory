# Expert Checklists

Use this file to run six parallel expert passes with distinct identities.

## Shared Rules

- Focus on defects, risks, regressions, and missing verification.
- Prefer simple and decoupled fixes.
- Reject over-design and unnecessary frameworks.
- Require evidence tied to changed code.
- Ignore cosmetic style nitpicks unless they hide risk.

## 1) Test Expert

Check:
- Missing unit/integration tests for new branches, error paths, and boundary conditions.
- Flaky test patterns (time-based sleeps, global state leakage, nondeterminism).
- Missing negative-path and concurrency-path coverage.
- Incomplete contract tests for external interfaces.

Look for worst outcomes:
- Silent regressions and unguarded edge-case failures.

## 2) Go Language Expert

Check:
- Error handling quality (ignored errors, wrapped context, sentinel misuse).
- `context.Context` propagation, cancellation handling, and timeout use.
- Goroutine lifecycle leaks and channel misuse.
- Data race risks around shared mutable state.
- API design clarity, cohesion, and package boundary hygiene.

Look for worst outcomes:
- Deadlocks, leaks, panics, and hard-to-debug production behavior.

## 3) Stratum Expert

Check protocol-sensitive logic relevant to Stratum-like systems:
- Job lifecycle correctness (new job, clean jobs, stale share handling).
- Difficulty target validation and share verification boundaries.
- Extranonce/nonce handling and uniqueness assumptions.
- Message parsing/serialization robustness and malformed payload handling.
- Session/state-machine transitions and reconnect behavior.

Look for worst outcomes:
- Invalid share acceptance/rejection, payout loss, protocol desync, or miner outage.

If Stratum semantics do not apply, output explicit `N/A`.

## 4) Security Expert

Check:
- Input validation and trust boundaries.
- AuthN/AuthZ gaps, permission bypass, and secret handling.
- Injection paths (command, SQL, template, config).
- DoS vectors (unbounded allocations, expensive loops, amplification).
- Unsafe defaults and insecure fallback behavior.

Look for worst outcomes:
- Data breach, privilege escalation, remote code execution, production abuse.

## 5) Senior Architect

Check:
- Unnecessary coupling across modules.
- Leaky abstractions and boundary violations.
- Complexity growth without clear payoff.
- Violations of existing architectural constraints.
- Change isolation and rollback friendliness.

Look for worst outcomes:
- Future feature lock-in, brittle codebase, high change cost.

## 6) Performance Expert

Check:
- Obvious algorithmic regressions (hot-path `O(n^2)`, repeated scans).
- Allocation pressure and avoidable copies on hot paths.
- Lock contention and serialized bottlenecks.
- Blocking I/O in latency-sensitive flows.
- Missing batching/caching where already required by architecture.

Look for worst outcomes:
- Latency spikes, throughput collapse, resource exhaustion, SLO breaches.
