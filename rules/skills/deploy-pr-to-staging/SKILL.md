---
name: deploy-pr-to-staging
description: Deploy a Progressive pull request into the staging cluster through Luxor's `fluxor-staging` manifests by resolving the PR's latest Docker image, staging edits in a temporary `./tmp/fluxor-staging` checkout, updating the chosen Progressive app, and checking for related config or dependency changes before optionally pushing. Use when Codex needs to roll a Progressive PR branch or PR number into staging, wait for the PR Docker build, update staging images, inspect related `deployment.yaml` or `config.toml` changes, or prepare a staging deployment for user review.
---

# Deploy PR To Staging

## Overview

Use this skill when a user wants a Progressive PR deployed into the staging cluster through `fluxor-staging` without manually hunting for the image tag or guessing which staging manifests need changes. Keep the deployment checkout isolated in `./tmp/fluxor-staging` unless the user explicitly asks to reuse another checkout.

## Workflow

### 1. Confirm the deployment target

- Prefer a PR number. If the user gives only a branch name, resolve the open PR with `gh pr list --repo LuxorLabs/progressive --head <branch>`.
- Require the target Progressive app if the user has not already named it.
- If the diff suggests multiple deployable services, ask which ones should move together instead of guessing.
- Treat `fluxor-staging` manifest paths as the source of truth for deployable app names. If there is no clear manifest match, ask.

### 2. Prepare an isolated `fluxor-staging` checkout

- Work in `./tmp/fluxor-staging` relative to the current task directory.
- If `./tmp/fluxor-staging/.git` does not exist, clone `git@github.com:LuxorLabs/fluxor-staging.git`.
- If it exists, verify the `origin` remote still points at `LuxorLabs/fluxor-staging`.
- If it exists, inspect the current branch before updating anything.
- If the checkout is on a branch other than `main`, switch back to local `main` first or ask before reusing it.
- If local `main` does not exist yet, create it from `origin/main`.
- If the checkout is dirty, stop and ask whether to reuse it, clean it up manually, or clone a fresh copy elsewhere. Do not discard unknown changes.
- If the checkout is clean and on `main`, update it from `origin/main` with a fast-forward flow.
- Do not silently reuse the user's separate local checkout outside `./tmp` unless the user asks for that.

### 3. Resolve the PR image before editing manifests

- Use [scripts/resolve_pr_image.py](scripts/resolve_pr_image.py) to resolve the current PR image.
- Default repo is `LuxorLabs/progressive`.
- Run it with `--wait` so it polls the `Build and push Docker image` check until it completes or times out.
- If the check is still running, wait.
- If the check finishes with anything other than success, stop the skill and report that the build did not produce a deployable image.
- Use the returned image string as the deployment candidate.

```bash
python3 scripts/resolve_pr_image.py --repo LuxorLabs/progressive --pr 980 --wait --image-only
```

### 4. Inspect PR impact before making edits

- Review the PR diff with `gh pr diff` or `gh pr view --json files`.
- Read [references/dependency-checklist.md](references/dependency-checklist.md) before editing manifests.
- Look for config-surface changes, new env vars, new flags, new secrets, config map schema changes, port changes, service discovery changes, or cross-service contract changes.
- Inspect the staging app directory for adjacent files such as `deployment.yaml`, `config.toml`, `kustomization.yaml`, `scrape.yaml`, `ingress.yaml`, `secret.yaml`, and `certificate.yaml`.
- If the PR touches shared packages and it is unclear whether a sibling service must move too, ask the user instead of assuming.
- If the user asked for a single app rollout but the PR obviously requires a coordinated change, explain the dependency and ask whether to proceed with the broader rollout.

### 5. Update the staging manifests

- Find the target app directory under `apps/luxor-staging/**/<app>/`.
- Prefer an exact directory-name match first.
- Update the image reference in the relevant manifest to the resolved PR image.
- Apply any additional config changes that are clearly required by the PR diff.
- Keep the edit set tight. Do not update unrelated apps just because they share the same repo.
- If the right app path is ambiguous, stop and ask.

### 6. Summarize and ask before pushing

- Show the files changed and summarize why each was touched.
- Call out any assumptions or unresolved questions.
- Ask explicitly whether to push the `fluxor-staging` changes.
- Do not push by default.
- If the user approves, commit intentionally and push to the branch they request. If they do not specify a branch and the workflow is the normal staging rollout, ask before pushing straight to `main`.

## Guardrails

- Assume the app to deploy is a Progressive service. If the user names something outside that scope, ask before proceeding.
- Do not invent config changes. When the PR impact is uncertain, ask a targeted question.
- Do not overwrite or reset an existing `./tmp/fluxor-staging` checkout if it contains local changes.
- Treat a missing or failed Docker image build as a hard stop.
- Keep secrets masked and do not echo GitHub tokens or private credentials.

## Resources

- [scripts/resolve_pr_image.py](scripts/resolve_pr_image.py): Poll the current PR's Docker build check and reconstruct the full `gcr.io/analog-stage-198105/progressive/...` image tag from the job logs.
- [references/dependency-checklist.md](references/dependency-checklist.md): Checklist for deciding whether the rollout needs more than an image bump.
