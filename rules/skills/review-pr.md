# Code Review Command

Review the current branch's changes against `origin/master` with a critical eye.

## Instructions

1. Run `git diff origin/master...HEAD` to get the full diff
2. Run `git log --oneline origin/master..HEAD` to understand the commit history
3. Run `gh pr view` to get PR metadata (title, description, labels, reviewers) — skip PR Health checks if no open PR exists
4. Review the changes against **all** of the following criteria

## Review Checklist

### Correctness

#### Logic
- Does the logic do what it claims to do?
- Are there off-by-one errors, wrong comparisons, or missed edge cases?
- Do functions signal failure via a bool or error return value, not by returning an empty/zero object?
- Are race conditions possible? Are shared resources protected with proper synchronization?
- Does any new HTTP client set a `Timeout` or use a context with timeout in `NewRequestWithContext`? (No timeout = potential hang)
- Is `resp.Body.Close()` deferred immediately after a successful HTTP response?

#### Error Handling
- Are error paths handled correctly and wrapped with context, including SDK/third-party errors (`fmt.Errorf("context: %w", err)`)?
- Do error messages follow the `doing xxx: err_msg` format in active voice? (e.g., `"decoding body: %w"` not `"body could not be decoded: %w"`)
- Do new `errors.New()` calls describe the action/state? (`"block header is nil"` not `"nil block header"`)
- Are `errors.Is()` / `errors.As()` used instead of string comparison?
- Are error texts kept as single, non-concatenated phrases (to preserve searchability in the codebase)?

### API & Protocol Buffers
- Do new/modified protobuf definitions follow existing conventions?
- Are gRPC / Connect RPC endpoints consistent with the rest of the codebase?
- Are request/response types properly validated at system boundaries?

### Database
- Are raw SQL queries parameterized (no string interpolation)?
- Is transaction management correct (commit/rollback in the right place)?
- Are new columns/indexes justified? Are nullable/default values appropriate?
- Are new queries added to `queries/` using goyesql conventions?
- Are there unbounded queries missing LIMIT where appropriate?
- Are ClickHouse schema changes (DDL) applied via the designated init/migration script, not hardcoded in application startup?

### Configuration
- Does each new config field have a sensible default value?
- Is each new config field reflected in the corresponding `dev-resources/<service>/config.toml`?
- Are Viper environment variable mappings correct and consistent with existing patterns?

### Code Quality
- Does the code follow existing patterns in the codebase (hexagonal architecture, adapter pattern)?
- Are there unused imports, dead code, or unused variables?
- Are functions focused (not doing too many things)?
- Is there unnecessary complexity that could be simplified?
- Are denied packages avoided (see CLAUDE.md for the list)?
- Do files end with a newline?
- Are names accurate and consistent? Names can be long — accuracy matters more than brevity. Related variables, functions, and metrics should use consistent naming (e.g., `mFooBar` → `collectFooBar()`). Follow existing naming conventions in the codebase.
- Has `/simplify` been run to check for code reuse opportunities, quality, and efficiency issues?
- Do exported types and functions have a doc comment explaining their purpose?
- Do comments explain *why* or the reasoning, not just restate what the code does?
- Does the `.go` file follow the correct content order: Imports → Globals/Constants → Types → Constructors → Public functions → Private functions?
- Are global variables avoided where possible? If used, are initialization errors handled via panic/MustXxx rather than swallowed?
- Are map keys and values documented (comment or descriptive name) to clarify what they represent?
- Does `main()` avoid `panic()`? (Use logger + `os.Exit` with an error code instead)

### Dependency Management
- Are changes to `go.mod` / `go.sum` necessary and traceable to a specific functional requirement in this PR?
- Do any newly introduced packages appear on the denied list? (emperror, gorilla, github.com/pkg/errors, go.uber.org/atomic, math/rand, oklog/run)

### Go Design Principles
- Are interfaces defined close to the consumer, not the implementer?
- After interface separation, do constructors return the Interface type?
- Are callback functions non-blocking? (Blocking ties slave resources to master, causing lock/shutdown risks)
- Are imports organized in exactly two groups (stdlib + everything else)?
- Is the reconnection pattern correct for persistent connections? (separate business loop and reconnect loop)

### Type Safety & Go Idioms
- Are nil pointer dereferences possible? Are nil checks in place where needed?
- Are goroutine lifecycles managed properly (no leaks, proper cancellation via context)?
- Is `defer` used correctly (especially in loops or with mutable variables)?
- Are `if` statements written in compact form where possible? (`if err := f(); err != nil` over separate assignment + check)
- Are maps initialized with the short literal form (`map[K]V{}`) rather than `make(map[K]V, 0)`?
- Do enum types use a meaningful zero value (e.g., `Invalid`, `Unknown`) to prevent accidental use of the zero value as valid state?
- Does each `Mutex` field have a comment identifying which fields it protects (if not self-evident from its name)?
- Is `sync.RWMutex` used instead of `sync.Mutex` in read-heavy scenarios to reduce lock contention?
- Are multiple fine-grained mutexes used rather than one broad lock covering unrelated state?
- Are `Mutex` fields named (not anonymous/embedded without a name) to allow tooling to trace all usages?
- Is the lock held for the minimum necessary duration? (Objects created outside the lock; only the write into shared state happens inside)

### Testing
- Are there tests for the new code? Check for:
  - Happy path
  - Error/edge cases
  - Boundary values (zero, nil, empty)
- Do top-level test functions follow `Test${FunctionName}_${Case}` naming?
- Do table-driven subtests follow the `When_condition_then_should_expected_outcome` naming convention?
- Are there any `t.Skip()` calls (not allowed)?
- Has `go test -race` been run on the affected packages?
- Is `require` used to abort the test on failure, and `assert` used only when the test can meaningfully continue after a failure?
- Does each package have a `TestMain` that includes goroutine leak detection (`testutils.DetectGoroutineLeaksMain(m)`)?
- Are mocks genuinely necessary, or can the behavior be tested with a real implementation? (Mocks should not exist solely to make tests pass)
- Are benchmarks added or updated for any performance-critical code paths changed in this PR?
- Are fuzz tests added for new functions that parse or decode external/untrusted input?

### Security
- Are there any secrets or credentials in the diff?
- Are all potentially unsafe inputs protected against SQL injection? (parameterized queries only)
- Do error responses avoid leaking internal details to external callers?

### Observability

#### Logging
- Do new log messages start with a lowercase letter (unless the first word requires capitalization, e.g., "RPC request failed")?
- Are errors bubbled up rather than logged at every layer? (Log once at the point where the error is handled, not at every return)
- Are log call sites structured with each field on its own line?

#### Metrics (if applicable)
- Are Histograms used for latency measurements (with appropriate bucket config)?
- Are Counters used for monotonically increasing values (not Gauges)?
- Are Gauges used only for point-in-time values?
- Are logs used for specific failure identification, not for counting (use metrics instead)?

### Temporal Workflows (if applicable)
- Are activities idempotent?
- Are workflow and activity options (timeouts, retries) configured appropriately?
- Is workflow determinism preserved (no random, no time.Now, no network calls in workflow code)?

#### Git Commit Messages
- Is the subject line separated from the body by a blank line?
- Is the subject line 50 characters or fewer?
- Does the subject line start with a capital letter?
- Does the subject line omit a trailing period?
- Is the subject written in the imperative mood? ("Add feature" not "Added feature" or "Adding feature")
- Is the body wrapped at 72 characters per line?
- Does the body explain *what* changed and *why*, rather than *how*?

### Changelog
- Is there a file in `.changelog.d/` for this PR? If not, create one via `make cl "scope: verb + short description"`
- Format: `scope: verb + short description` (lowercase); scope = service/package/area (e.g., `energyworkflow`, `moneta`, `pkg/rpcclient`, `ci`)
- Does the description start with a verb (add, fix, update, remove) completing "This commit will..."?
- Is there one entry per distinct change when the branch touches multiple areas? (run `make changelog add` for each)
- Do all changelog entries accurately cross-reference the actual diff? (flag entries that are misleading, too vague, omit a significant change, or describe something not present in the diff)
- Has `make changelog validate` been run to confirm the entry is well-formed?

### PR Health
- **Size**: Is this PR focused on a single concern? Flag for splitting if it mixes unrelated changes
- **Title**: Does it follow the `scope: verb + short description` format and stay under 70 characters?
- **Description**: Does it include a Summary section (what changed and why) and a Test plan section?
- **Labels**: Are appropriate labels applied (e.g., `bug`, `enhancement`, `breaking-change`)?
- **Reviewers**: Has at least one reviewer been assigned?
- **Milestone / Project**: Is it linked if applicable?

## Output Format

Organize findings by severity:
- **Blocker**: Must fix before merge (bugs, security issues, data loss risk)
- **Should fix**: Strong recommendation (design issues, missing validation, no tests)
- **Nit**: Style or minor improvements (naming, code organization)

For each finding, reference the specific file and line number.
