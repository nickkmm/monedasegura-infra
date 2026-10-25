# monedasegura-infra

Orchestration and shared documentation for **MonedaSegura**: real-time transactional fraud detection (Universidad Icesi + Lovelytics project).

The system is split into four repos:

| Repo | What it is | Owners |
|---|---|---|
| `monedasegura-infra` (this one) | `docker-compose`, configuration and the shared `docs/` | Nicolás |
| `monedasegura-app` | Flutter app for risk analysts, with a simulator | Juan José, Santiago |
| `monedasegura-decision-service` | Spring Boot: rules, features, decisions, cases, RBAC | Nicolás |
| `monedasegura-scoring-service` | FastAPI + LightGBM: scoring and retraining | Nicholas, Laura |

Locally, all four are cloned as sibling folders inside a `SecureMoney/` workspace folder.

## Layout

```
docs/                     Shared source of truth for the 4 repos
  CONTEXT.md              Summary of the challenge, the course deliverable and the paper
  MVP_PLAN.md             MVP scope (Must / Should / Could / Won't), schedule, risks, team rules
  model.md                Data model (Mermaid + tables + RBAC + business rules)
  erd.svg                 Entity-relationship diagram (erd-svg skill)
  data.md                 Data sources: colombianized Sparkov + simulator
  architecture.md         Source of the architecture diagrams
  diagrams/               architecture-decision-path.svg, architecture-background.svg (arch-svg skill)
  features.md             Feature catalog (single source for Spring, rules, Python and the app)
  api/                    OpenAPI contracts: decision-api.yaml (app → Spring), scoring-api.yaml (Spring → Python)
data/                     Source material: challenge, course instructions, paper and poster
                          (third-party SLR papers are never published)
.agents/skills/           Agent skills (Claude Code and Antigravity)
.claude/skills            Symlink to .agents/skills
AGENTS.md / CLAUDE.md     Instructions for coding agents
redocly.yaml              Lint config for the OpenAPI contracts
scripts/                  bootstrap-workspace.sh: clones the 4 repos as siblings
.github/workflows/ci.yml  CI: no forbidden files, contract lint, compose validation and smoke test
docker-compose.yml        Local stack (profiles: default infra, apps, seed, tools)
.env.example              Template for .env (never commit .env)
```

## Running locally

The repos do not reference each other through git: they rely on being **sibling folders**. Set up the workspace once:

```bash
mkdir SecureMoney && cd SecureMoney
git clone https://github.com/nickkmm/monedasegura-infra.git
sh monedasegura-infra/scripts/bootstrap-workspace.sh   # clones the other three next to it
```

```bash
# workspace layout
SecureMoney/
├── monedasegura-infra/               # this repo
├── monedasegura-decision-service/    # needed for --profile apps
├── monedasegura-scoring-service/     # needed for --profile apps / seed
└── monedasegura-app/                 # needed for --profile apps

cd monedasegura-infra
cp .env.example .env                               # then change the secrets
docker compose up -d                               # postgres, redis, kafka (+ creates topic `decisions`)
docker compose --profile apps up -d --build        # + the three services
docker compose --profile seed run --rm seed-job    # load the Sparkov seed once
docker compose --profile tools up -d               # + kafka-ui on http://localhost:8081
docker compose down                                # stop (add -v to wipe the database)
```

| Service | Inside compose | From your machine |
|---|---|---|
| postgres | `postgres:5432` | `localhost:5432` |
| redis | `redis:6379` | `localhost:6379` |
| kafka | `kafka:9092` | `localhost:9094` |
| decision-service | `decision-service:8080` | `http://localhost:8080/api/v1` |
| scoring-service | `scoring-service:8000` | `http://localhost:8000` |
| app (Flutter web) | — | `http://localhost:3000` |

### What each sibling repo must provide

The compose file is the integration contract between repos:

| Repo | Must provide |
|---|---|
| `monedasegura-decision-service` | A `Dockerfile` at the repo root; the app listens on `8080` with base path `/api/v1` (`docs/api/decision-api.yaml`); reads the `SPRING_*`, `SCORING_SERVICE_*` and `JWT_SECRET` variables; owns the database schema (migrations). |
| `monedasegura-scoring-service` | A `Dockerfile` at the repo root; by default serves the API on `8000` (`docs/api/scoring-api.yaml`); the command `seed` runs the seed job (`docs/data.md`) using `DATABASE_URL` and the `SEED_*` / `USD_TO_COP` variables; stores models in `MODEL_DIR`. |
| `monedasegura-app` | A `Dockerfile` at the repo root that builds Flutter web and serves it on port `80`; reads `API_BASE_URL`. |

## Deployment

One VM runs the same `docker-compose.yml` (`docs/MVP_PLAN.md` §4). Every merge to `main` in any of the four repos deploys automatically:

```
merge to main → .github/workflows/deploy.yml → SSH to the server → scripts/deploy.sh
                                                                    (all four repos to the latest main,
                                                                     docker compose --profile apps up -d --build)
```

### One-time server setup

```bash
# on the server (Docker and git installed)
mkdir SecureMoney && cd SecureMoney
git clone https://github.com/nickkmm/monedasegura-infra.git
sh monedasegura-infra/scripts/bootstrap-workspace.sh
cp monedasegura-infra/.env.example monedasegura-infra/.env   # then set real secrets; it stays on the server
sh monedasegura-infra/scripts/deploy.sh                      # first deploy
docker compose -f monedasegura-infra/docker-compose.yml --profile seed run --rm seed-job   # load the seed once
```

Then create an SSH key used only for deploying, add its public half to `~/.ssh/authorized_keys` on the server, and add these **repository secrets** in each of the four repos (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | server IP or host name |
| `DEPLOY_USER` | SSH user on the server |
| `DEPLOY_SSH_KEY` | the private deploy key |
| `DEPLOY_KNOWN_HOSTS` | output of `ssh-keyscan <host>` (pins the server's host key) |
| `DEPLOY_PATH` | optional: workspace folder on the server, relative to the user's home (default `SecureMoney`) |

Until these secrets exist, the deploy job skips without failing. To redeploy by hand: Actions → deploy → Run workflow, or run `sh scripts/deploy.sh` on the server.

## Agent skills

| Skill | What it does |
|---|---|
| `erd-svg` | Draws `docs/erd.svg` from `docs/model.md` |
| `arch-svg` | Draws the diagrams in `docs/diagrams/` from `docs/architecture.md` |

Skills live once in `.agents/skills/` (Antigravity); Claude Code sees them through the `.claude/skills` symlink. On Windows, enable git symlinks (`git config core.symlinks true`) or copy the folder.

## Branch flow (same in all 4 repos)

```
feature/<task>  ──PR──►  develop  ──PR (Nicolás only)──►  main
 (person or agent)      (peer review)                    (stable)
```

| Branch | Purpose | How a change gets in |
|---|---|---|
| `feature/…`, `fix/…`, `docs/…` | work in progress; one branch per task | free commits |
| `develop` (default branch) | team integration | PR with **1 approval from any teammate**; GitHub requests the repo owners (`CODEOWNERS`) |
| `main` | stable: what is shown and deployed | `develop → main` PR **merged by Nicolás**: a ruleset lets only repo admins update `main` |

- Nobody, person or agent, pushes directly to `develop` or `main`: GitHub rejects it.
- Work PRs always target `develop`. Only Nicolás opens and merges `develop → main`.
- The required check `ci` (build + tests + lint) must pass on every PR to `develop` and `main`.

| Repo | Owners (`CODEOWNERS`) | Write access |
|---|---|---|
| `monedasegura-infra` | Nicolás (`@nickkmm`) | everyone (contract and model changes start here) |
| `monedasegura-decision-service` | Nicolás (`@nickkmm`) | Nicolás |
| `monedasegura-scoring-service` | Nicholas (`@NSP2007`), Laura (`@LauCZ41`) | Nicholas, Laura |
| `monedasegura-app` | Juan José (`@Jujoroco06`), Santiago (`@Gomaxd11`) | Juan José, Santiago |

All repos are public, so everyone can read all of them.

## Collaboration rules

- **Language:** everything is in English (code, comments, docs, diagrams, commits, PRs). The only exception is user-facing text in the Flutter app, which is in Spanish.
- A change to a contract (`docs/api/`) or to the model (`docs/model.md`) needs review from the owners of the affected repos.
- The other repos read `docs/` from the sibling folder `../monedasegura-infra/docs/`; they never copy it.
- The dataset is never committed to any repo: the `scoring-service` script downloads and transforms it (see `docs/data.md`).
