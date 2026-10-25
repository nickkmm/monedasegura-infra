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
  api/                    OpenAPI contracts (pending)
data/                     Source material: challenge, course instructions, paper and poster
                          (third-party SLR papers are never published)
.agents/skills/           Agent skills (Claude Code and Antigravity)
.claude/skills            Symlink to .agents/skills
AGENTS.md / CLAUDE.md     Instructions for coding agents
```

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
| `develop` (default branch) | team integration | PR with **1 approval from any teammate** |
| `main` | stable: what is shown and deployed | `develop → main` PR with **Nicolás's approval** (`CODEOWNERS`) |

- Nobody, person or agent, pushes directly to `develop` or `main`: GitHub rejects it.
- Work PRs always target `develop`. Only Nicolás opens and merges `develop → main`.
- Once each repo has code, its **GitHub Actions** (build + tests + lint) become required checks for `develop` and `main`.

## Collaboration rules

- **Language:** everything is in English (code, comments, docs, diagrams, commits, PRs). The only exception is user-facing text in the Flutter app, which is in Spanish.
- A change to a contract (`docs/api/`) or to the model (`docs/model.md`) needs review from the owners of the affected repos.
- The other repos read `docs/` from the sibling folder `../monedasegura-infra/docs/`; they never copy it.
- The dataset is never committed to any repo: the `scoring-service` script downloads and transforms it (see `docs/data.md`).
