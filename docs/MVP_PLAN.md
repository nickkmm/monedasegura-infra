# MonedaSegura — MVP plan

Status: agreed on 2026-10-24. Replaces the Kafka/Flink/Feast stack from the paper (Section VII). Deadline: ~early December 2026.

## 1. Scope
An app for **risk analysts only**, with a **Simulator** tab (admin only) that generates synthetic transactions. There is no customer-facing app.

## 2. Architecture and repos
See `docs/architecture.md` and its two diagrams in `docs/diagrams/` (decision path and background flows).

| Repo | Responsibility | Owners |
|---|---|---|
| `monedasegura-app` | Flutter: login, case queue, detail, rules, simulator, dashboard | Juan José, Santiago |
| `monedasegura-decision-service` | Spring Boot: JWT auth + RBAC, transactions, features, rule engine, verdict, cases, circuit breaker (Resilience4j), Kafka re-evaluator, daily retraining job | Nicolás |
| `monedasegura-scoring-service` | Python/FastAPI: `/score`, `/retrain`, model files in the S3 bucket, Sparkov seed job | Nicholas, Laura |
| `monedasegura-infra` | `docker-compose.yml`, `.env.example`, Postgres/Kafka/Redis/SeaweedFS config, startup and seed scripts; `docs/` (context, ERD, diagrams, OpenAPI contracts) | Nicolás |

**Contract first.** Before coding, the OpenAPI contracts are written: `docs/api/decision-api.yaml` (app → decision-service) and `docs/api/scoring-api.yaml` (decision-service → scoring-service), plus the feature catalog `docs/features.md`; each repo works against mocks until the others exist. Locally the 4 repos are cloned as sibling folders inside `SecureMoney/`, and the compose file builds them with `build: ../<repo>`; later each repo can publish its image (GHCR) and compose only pulls. Everything starts with a single `docker compose up` from `monedasegura-infra`.

## 3. Scope by priority

### Must (no MVP without it)
- Analyst login (JWT) with RBAC: 5 roles, 10 permissions (`docs/model.md` §4).
- Transaction ingestion over REST → features → rules + score → verdict `APPROVE | REVIEW | BLOCK`, with `latency_ms`.
- **Redis as online feature store**: each customer's recent facts (last 24 h of transactions and session events in sorted sets, last location), updated after every committed transaction, to count the short windows (`docs/features.md`). The 30-day and fixed features are read from Postgres. Postgres remains the source of truth: if Redis fails or loses its data, Spring computes from Postgres and rebuilds Redis. Latency is measured first with Postgres-only features and then with Redis, to show the before/after (paper Decision 5).
- Every decision stores its `features_json` (prevents training-serving skew without a full feature store).
- Versioned rules in the database with the lifecycle `DRAFT → SHADOW → PENDING_APPROVAL → ACTIVE`; changing a rule needs no redeploy. **Shadow, backtest and two-step approval are mandatory** (`docs/model.md` §6). Score thresholds are rules too.
- Traceability: each decision links the evaluated `rule_version`s, the `model_version`, the features and the timestamp.
- Scoring service with LightGBM trained on the colombianized Sparkov seed (`docs/data.md`). Model files go to object storage with the S3 API (**SeaweedFS** in docker-compose; S3 or GCS later by changing the endpoint), and `model_version.artifact_uri` points to each one.
- **Contingency:** timeout + circuit breaker; if scoring fails, the decision uses rules only and is marked `degraded = true`.
- **Kafka (1 broker, KRaft mode)** off the critical path: each decision is published to the `decisions` topic; a Spring consumer **re-evaluates `degraded` decisions** once scoring recovers (deferred enforcement, paper Decisions 3 and 7).
- Case queue, detail and confirmed/dismissed labeling.
- **Automatic daily retraining** (Spring `@Scheduled`, 02:00) + manual button → new `model_version`, activated automatically only if it passes the quality gate (`docs/model.md` §8). Replaces the paper's "manual retraining".
- Simulator (normal, card fraud, origination, ATO), `ADMIN` only.
- Synthetic data only, and PII masked in the UI.

### Should (if the Must is on time)
- **Dashboard:** count per verdict, p50/p95/p99 latency, % degraded, active model version, quality-gate alerts.

### Could (only with slack)
- Simple drift check: PSI of recent score distribution vs a reference, with an alert on the dashboard.
- Push notification (FCM) to analysts when a `REVIEW` case arrives.
- Explainability: top-N features behind each score (SHAP or local importance).

### Won't (kept as argued design only)
HTGNN / Lambda, Flink, Feast, tiered storage, disaggregated state, sustained 500 tx/s (the breaking point is measured instead), multi-jurisdiction compliance (design only), Firebase/ML Kit for the model (client-side inference can be tampered with; the decision must be server-side), `account` table, general audit log.

## 4. Deployment
- Everything packaged with **Docker** (one container per service + Postgres + Kafka + Redis + SeaweedFS), orchestrated with **docker-compose** on a single host.
- **No Kubernetes:** ~7 containers on one host, no autoscaling or multiple nodes; K8s would add complexity with no benefit. It is argued in the design as the future scaling path.
- **Pending decision:** develop locally with docker-compose from day 1; decide around week 5 whether to deploy to **GCP Compute Engine** (VM with ≥4 GB RAM, docker-compose, Caddy for HTTPS; trial credits require a card, a budget alert and shutting the VM down afterwards). Zero-cost alternatives: student credits or a local demo.
- **Continuous deployment (decided):** whatever the host, it is one VM running the same `docker-compose.yml`. Every merge to `main` in any of the four repos runs `.github/workflows/deploy.yml` (in this repo; the other three call it), which connects over SSH and runs `scripts/deploy.sh`: move all four repos to the latest `main`, then `docker compose --profile apps up -d --build`. The server's `.env` is created once by hand and never leaves the server. Until the `DEPLOY_*` secrets are set, the job skips. Setup steps: README, "Deployment".
- PaaS such as Render/Railway/Fly are ruled out: poor fit for Kafka, and cold starts distort latency.
- Final latency is measured on the deployed VM, not locally.

## 5. Data model
Defined in `docs/model.md` (single source, with Mermaid) and drawn in `docs/erd.svg`. 15 tables: RBAC (`app_user`, `role`, `permission`, `user_role`, `role_permission`), customers and events (`customer`, `device`, `session_event`, `transaction`), decision and model (`decision`, `model_version`, `decision_rule_hit`), rules (`rule`, `rule_version`) and cases (`fraud_case`).

## 6. Prototype screens
Login · Case queue · Transaction/case detail · Rule list · Create/edit rule (shadow, backtest, approval) · Simulator · Dashboard.

## 7. Tentative schedule (6 weeks)
| Week | Focus |
|---|---|
| 1 | Close scope, context text, ERD, architecture, OpenAPI contracts |
| 2 | Figma prototype + component gallery; skeletons of the 4 repos; compose in `infra` |
| 3 | Critical path: tx → features (Postgres) → rules → verdict; baseline latency; Flutter: login, queue, detail |
| 4 | Scoring service + integration; circuit breaker; Kafka and re-evaluation; Redis feature store and before/after latency |
| 5 | Labeling, backtest, two-step approval, daily retraining; dashboard; deployment decision |
| 6 | Latency measurement, induced failure, polish, documentation and demo |

## 8. Risks
- Four repos and five people: without early OpenAPI contracts they block each other.
- Model trained on synthetic data: it does not prove real effectiveness; this is stated explicitly.
- Scope creep: nothing from the Should starts before the Must works end to end.
- Hosting cold starts distort latency; measure and document them.

## 9. Team, branches and agents

**Branch flow** (all 4 repos): `feature/* → develop` (default branch, protected, 1 approval from any teammate) `→ main` (protected, approval from Nicolás required via `CODEOWNERS`). Nobody — person or agent — pushes directly to `develop` or `main`. GitHub Actions (build + tests + lint) becomes a required check once each repo has code.

**Language policy** (decision 2026-10-24): **everything is in English** — code, identifiers, comments, docs, diagrams, commit messages, PRs, OpenAPI contracts, skills and agent files. **The only exception is user-facing text in the Flutter app** (labels, messages, screens), which is in Spanish. Every repo's `AGENTS.md` states this rule.

**Agent tooling:** Claude Code (reads `CLAUDE.md`, skills in `.claude/skills/`) and Antigravity (reads `AGENTS.md`, rules in `.agents/rules/`, skills in `.agents/skills/`). Shared skill format: a folder with a `SKILL.md`.

Per-repo convention:
- `AGENTS.md` = source of truth for any agent.
- `CLAUDE.md` = a single line `@AGENTS.md` + only Claude-specific notes.
- `.agents/skills/<skill>/SKILL.md` = skills; `.claude/skills` is a symlink to `.agents/skills` (one copy).

Boundaries: shared context (challenge context, ERD, diagrams, OpenAPI contracts, feature catalog) lives only in `monedasegura-infra/docs/`, and the other repos read it from the sibling folder `../monedasegura-infra/docs/`. An agent only modifies the repo it is working in; a contract or feature-catalog change is a PR against `infra`, never a local edit.
