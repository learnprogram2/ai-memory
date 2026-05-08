---
name: update-branch
description: Update a target branch with latest master via merge, with smart CHANGELOG conflict resolution
allowed-tools: Bash(git *), Read, Edit, Grep, Glob, AskUserQuestion
---

# Update Branch

Update a target branch by merging the latest master into it, automatically handling common conflicts like CHANGELOG.md.

## Steps

1. **Select target branch to update (and switch):**
   - If the command arguments have branch name, switch to it:
     ```bash
     git switch <branch-name>
     ```
   - If not found, ask the user whether to:
      1) update the **current** branch, or
      2) provide **another** branch name (new input), then repeat this step.

2. **Check current state:**
   ```bash
   git status
   git branch --show-current
   ```
   - If there are uncommitted changes, ask the user whether to stash them first or abort.

3. **Fetch and merge latest master into target branch:**
   ```bash
   git fetch origin master
   git merge --no-ff origin/master
   ```

4. **If merge succeeds with no conflicts**, report success and skip to step `Final verification`.

5. **If conflicts occur**, handle them:

   **For CHANGELOG.md conflicts:**
   - CHANGELOG.md conflicts are almost always caused by both branches adding entries that were under `## [Unreleased]`, but master has since cut a new release version (e.g., `## [2.243.0]`), moving those entries into the versioned section.
   - Resolution strategy:
      1. Read the conflicted file and identify the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
      2. Identify which entries are **ours** (from `HEAD`) and which are **master's** (from `origin/master`).
      3. **Master's entries** stay where master put them — typically inside the newly versioned section (e.g., `## [2.243.0]`).
      4. **Our branch's entries** must be placed under `## [Unreleased]` at the top, since they have NOT been released yet. If the conflict placed them inside a versioned section, **move them up** to `## [Unreleased]`.
      5. If `## [Unreleased]` doesn't have our entries yet, add them there.
   - Stage the resolved file: `git add CHANGELOG.md`

   **For other conflicts:**
   - Show the user which files have conflicts: `git diff --name-only --diff-filter=U`
   - Read each conflicted file and present the conflicts to the user.
   - Ask the user how to resolve each conflict.
   - After resolution, stage the file.

6. **Complete the merge after resolving conflicts:**
   - After staging resolved files, finish the merge with a meaningful message:
   ```bash
   git commit -m "Merge origin/master into <branch-name>"
   ```
   - If your team has a standard format (e.g., include ticket id), follow it.
   - If Git already completed the merge automatically after `git add`, report success and continue.

7. **Final verification:**
   - Check CHANGELOG.md: read the top of the file and verify that our branch's new entries appear under `## [Unreleased]` and NOT inside a versioned section (e.g., `## [2.x.x]`). If they ended up in a versioned section, move them to `## [Unreleased]`.
  ```bash
  git log --oneline -5
  git status
  ```

## Notes

- Avoid using `git merge --abort` unless the user explicitly requests it.
- If stashed changes at the beginning, remind the user to `git stash pop` at the end.
- CHANGELOG.md is the most common source of conflicts — always try to auto-resolve it by keeping both sides' entries.