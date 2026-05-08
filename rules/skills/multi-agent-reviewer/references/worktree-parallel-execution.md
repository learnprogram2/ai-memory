# Worktree Parallel Execution

Use this guide when running parallel agents with any chance of write operations.

## Why Worktree

Parallel agents can conflict on:
- working directory files
- git index / staging area
- branch checkout state
- Go build/test caches

`git worktree` gives each agent an isolated checkout while keeping a shared object database.

## Decision Rule

- Read-only review only: no worktree required.
- Any write/test/git mutation: worktree required.

## Standard Procedure

1. Export review patch from the source repo.
2. Create one detached worktree per role at the same base commit.
3. Apply the patch into each worktree.
4. Run each role inside its assigned worktree only.
5. Clean up worktrees after collecting findings.

## Minimal Commands

```bash
# in source repo
BASE_SHA=$(git rev-parse HEAD)
PATCH_FILE=/tmp/go-review.patch
git diff HEAD > "$PATCH_FILE"

./scripts/manage_review_worktrees.sh setup \
  --repo "$(pwd)" \
  --base "$BASE_SHA" \
  --patch "$PATCH_FILE" \
  --root "/tmp/go-pr-review-swarm"
```

Cleanup:

```bash
./scripts/manage_review_worktrees.sh cleanup \
  --repo "$(pwd)" \
  --root "/tmp/go-pr-review-swarm"
```

## Per-Agent Runtime Isolation

For each role, set dedicated cache/temp paths:

```bash
export GOCACHE=/tmp/go-pr-review-swarm/cache/<role>/gocache
export GOMODCACHE=/tmp/go-pr-review-swarm/cache/<role>/gomodcache
export GOTMPDIR=/tmp/go-pr-review-swarm/cache/<role>/gotmp
```

This prevents cross-agent pollution during `go test` or build actions.

## Safety Rules

- Use `git worktree add --detach` to avoid branch lock contention.
- Never run one role in another role's worktree.
- Do not apply additional unrelated patches during review.
- If patch apply fails, stop and regenerate patch from a clean base.
- On macOS, the helper script automatically prefers Homebrew Git (`/opt/homebrew/bin/git`) when available.
