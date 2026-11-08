# AGENTS.md — monedasegura-infra

Instructions for any coding agent (Claude Code, Antigravity, others) working in this repo.

## What this repo is
Orchestration (`docker-compose`, configuration) and the **shared source of truth** for the four MonedaSegura repos: `docs/` (context, MVP plan, data model, data sources, architecture, OpenAPI contracts). It contains no business code. Read `docs/CONTEXT.md` and `docs/MVP_PLAN.md` first.

## Language policy
- **Everything is written in English**: code, identifiers, comments, docs, diagrams, commit messages, PR titles and descriptions, OpenAPI contracts, skills and agent files.
- **The only exception is user-facing text in the Flutter app** (`monedasegura-app`): labels, messages and screens are in Spanish.
- When the source material is in Spanish (`data/`), keep it as is; anything you produce from it is in English.

## Branches and commits
- Never push to `develop` or `main`. Create `feature/<task>`, `fix/<task>` or `docs/<task>` and open a PR against `develop`.
- `develop → main` is opened and merged only by the repo owner (Nicolás).
- One topic per PR. Commit messages in English, imperative mood ("Add …", "Fix …").

## Rules for this repo
- `docs/model.md` is the only source for the data model. If you change it, regenerate `docs/erd.svg` with the `erd-svg` skill in the same PR.
- `docs/architecture.md` is the only source for the architecture diagrams. If you change it, regenerate `docs/diagrams/` with the `arch-svg` skill in the same PR.
- `docs/features.md` is the only source for feature names. A feature change also updates `Features` in `docs/api/scoring-api.yaml` in the same PR.
- `docs/api/*.yaml` are the contracts between repos (OpenAPI 3.1). Before opening a PR that touches them, run `npx @redocly/cli@1.34.0 lint` from the repo root; it must report no errors.
- Contract or model changes affect other repos: list the affected repos in the PR template.
- Never commit `data/02_references/` (third-party papers under copyright) or any dataset file. The Sparkov dataset is downloaded by the `scoring-service` script (`docs/data.md`).
- Never commit secrets: only `.env.example`, never `.env`.
- `docker-compose.yml` is the integration contract between repos (ports, env variables, the scoring image's `seed` command; see README "What each sibling repo must provide"). Changing it affects the other repos: say so in the PR. Pin image versions; never use `latest`. Check with `docker compose --env-file .env.example config` before opening the PR.
- Do not modify files in the sibling repos from here; they have their own PRs. The one exception is `/factory install`, which only opens a PR in the sibling repo.
- Deployment is `.github/workflows/deploy.yml` (reusable; the other repos call it) running `scripts/deploy.sh` on the server. Never put server addresses, keys or production values in the repo: they are `DEPLOY_*` repository secrets and the server's own `.env`.
- CI (`.github/workflows/ci.yml`) must pass: it rejects tracked papers/datasets, lints the contracts, validates compose for every profile and smoke-tests Postgres, Redis and Kafka.

## Skills
Skills live in `.agents/skills/` (`.claude/skills` is a symlink to it):
- `erd-svg`: draws `docs/erd.svg` from `docs/model.md`.
- `arch-svg`: draws `docs/diagrams/*.svg` from `docs/architecture.md`.
- `factory`: the software factory (see below).

Any new skill used in this project is added to `.agents/skills/` so it stays versioned with the repo.

<!-- factory:start (managed by monedasegura-infra factory/bin/install; edit it there) -->
## Software factory

`/factory run` builds every open GitHub issue labeled `factory` **and assigned to you** through intake → spec → build → gate → review → approve, one PR per issue. A person always reviews and merges the PR: the factory never merges. State is in `factory/jobs/` (gitignored, local to your machine); `factory/bin/job` is its only writer. Checks: `factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then open http://localhost:8000/dashboard.html.

| Command | What it does |
|---|---|
| `/factory run` | release the issues whose dependencies are merged, then build your queue (3 at a time) |
| `/factory run <n>` | build issue `<n>` now (it must be assigned to you) |
| `/factory divide <#n, file or text>` | split a large request into PR-sized issues, each with an owner; shows the plan before creating anything |
| `/factory <anything>` | ask about jobs, give feedback on a PR waiting for you, or file a new feature |

- **Who builds what.** Every factory issue is assigned to one person, and each person's factory only takes their own issues, so two people never build the same issue. Never take an issue assigned to someone else.
- **Order.** A task that needs another one says `Depends on #n` and stays unlabeled; `/factory run` labels it once `#n` is closed by a merged PR.
- **Record.** Each PR carries the job's record (intake, spec, build, reviews, checks, decision) in `docs/factory-history/issue-<n>/`. Only the factory writes there.
- **Branches.** The factory pushes `factory/<job-id>` branches and opens PRs against `develop`; this is the only exception to the branch-name rule above.
- **Worktrees.** Each job works in its own git worktree, a full checkout of the repo at `.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't read `.gitignore` sees those copies too; exclude `.worktrees/` in its config. **Sibling repos are relative to the main checkout, not to the worktree**: from a worktree, the shared docs are at `<main checkout>/../monedasegura-infra/docs/`.
- **Antigravity.** Use the App or the CLI (custom subagents aren't in the IDE yet), from the repo root: `agy --model <id>`, with an id from `agy models` (Gemini 4 Argon if your plan has it, otherwise Gemini 3.8 Flash), then the same `/factory` commands. The agents in `.agents/agents/` are generated from `.claude/agents/` by `factory/bin/sync-agents`; edit the `.claude/agents/` file and run it, never edit `.agents/agents/` by hand.
- **License.** The factory comes from ZazenCodes' software factory v2 (GPLv3, see `factory/LICENSE`).

### This repo (monedasegura-infra)

- **Managing the other repos.** Two extra commands run only here:
  - `/factory install <app|decision-service|scoring-service>`: installs this factory in that sibling repo through a PR (`factory/bin/install`), using its profile in `factory/profiles/<repo>/` (its checks, its notes for `AGENTS.md` and any extra files). Only repos with a profile can be installed; today that is `monedasegura-app`.
  - `/factory status`: open issues and PRs across the four repos, per person.
- **Changing the factory.** This repo holds the master copy: edit it here, run `factory/bin/sync-agents` after changing `.claude/agents/`, and roll it out with `factory/bin/install <repo> --update`.
- **Checks.** `factory/checks.sh` runs the CI steps except the Docker smoke test, which stays in CI.
<!-- factory:end -->
