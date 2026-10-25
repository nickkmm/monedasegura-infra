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
- Do not modify files in the sibling repos from here; they have their own PRs.

## Skills
Skills live in `.agents/skills/` (`.claude/skills` is a symlink to it):
- `erd-svg`: draws `docs/erd.svg` from `docs/model.md`.
- `arch-svg`: draws `docs/diagrams/*.svg` from `docs/architecture.md`.

Any new skill used in this project is added to `.agents/skills/` so it stays versioned with the repo.
