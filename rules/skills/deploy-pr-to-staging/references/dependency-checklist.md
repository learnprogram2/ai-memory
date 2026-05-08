# Dependency Checklist

Use this checklist after identifying the target app and before editing `fluxor-staging`.

## 1. PR-to-staging mapping

- Confirm which Progressive app the PR is meant to deploy.
- If the PR touches multiple app entrypoints under `cmd/`, ask whether the rollout should include all of them.
- If the user names a staging app that does not have a clear manifest under `apps/luxor-staging`, ask before editing.

## 2. Files to inspect in `fluxor-staging`

Inside the target app directory, inspect at least:

- `deployment.yaml`
- `config.toml`
- `kustomization.yaml`
- `scrape.yaml`
- `ingress.yaml`
- `secret.yaml`
- `certificate.yaml`

Not every app has all of these files, but `deployment.yaml` plus any sibling config files are the minimum review set.

## 3. Change types that usually require more than an image bump

- Config parsing or config surface changes
- New CLI flags or changed command arguments
- New environment variables
- Renamed environment variables
- New secret references
- Changed ports, listeners, service type, ingress, or NEG behavior
- New sidecars, volumes, or volume mounts
- Changes to service-to-service addresses
- Schema or protocol changes that affect another staged service

## 4. Common questions to ask

- Is the rollout for one app or a coordinated set of apps?
- Does the PR require a matching `config.toml` update?
- Does the PR depend on another staging service moving first?
- Is there a secret, config map, or ingress change that is not represented in the PR diff?
- Should the `fluxor-staging` change be prepared only, or committed and pushed?

## 5. Mining-pool heuristics

For `mining-pool` services, double-check nearby peers when the PR changes shared control flow:

- `btc-proxy`
- `hashratecoordinator`
- `poolwatcher`
- `stratumwatcher`
- jobserver / stratum pairs
- `moneta-*`
- `statservice-*`

Do not change these peers by default. Use the list only to decide whether to inspect them or ask the user a clarifying question.

## 6. Safe editing rules

- Keep the checkout in `./tmp/fluxor-staging` unless the user asks otherwise.
- Do not delete unknown local changes in the temp checkout.
- Do not push without an explicit yes from the user.
