# MonedaSegura — MVP architecture

Source for the two MVP architecture diagrams, drawn with the `arch-svg` skill. They replace, for the MVP, the paper's final-architecture diagram (`data/01_essentials/architecture/MonedaSegura_arquitectura_v1.svg`).

The architecture is split into two diagrams on purpose: one per kind of flow, so each reads left to right without detours.

| Diagram | What it shows |
|---|---|
| `architecture-decision-path` | What happens while the app waits: steps 1→6 in under 500 ms, plus the degradation paths |
| `architecture-background` | What runs off the critical path: re-evaluation, daily retraining, initial seed, Redis rebuild |

---

## Diagram: architecture-decision-path

Title: MonedaSegura MVP: decision path
Subtitle: What happens while the app waits: steps 1→6 in under 500 ms. Red dotted lines are degradation paths.

### Zones
| id | label | columns | rows |
|---|---|---|---|
| z-app | monedasegura-app | 0 | 1 |
| z-dec | decision-service | 1 | 1 |
| z-cache | infra | 2 | 0 |
| z-sco | scoring-service | 2 | 1 |
| z-obj | infra | 3 | 1 |
| z-db | infra | 2 | 2 |

### Nodes
| id | name | technology | type | column | row |
|---|---|---|---|---|---|
| app | app | Flutter · queue, simulator | APP | 0 | 1 |
| dec | decision-api | Spring · rules + breaker | API | 1 | 1 |
| redis | redis | Redis · 24 h counters | DB | 2 | 0 |
| sco | scoring-api | FastAPI · LightGBM | API | 2 | 1 |
| models | models | SeaweedFS · S3 bucket | DB | 3 | 1 |
| pg | postgres | PostgreSQL · records | DB | 2 | 2 |

### Connections
| from | to | label | type | step |
|---|---|---|---|---|
| app | dec | REST + JWT | sync | 1 |
| dec | redis | counters | sync | 2 |
| dec | pg | profile | sync | 3 |
| dec | sco | /score (breaker) | sync | 4 |
| dec | pg | store | sync | 5 |
| dec | redis | update | sync | 6 |
| dec | pg | without Redis | contingency | |
| sco | models | loads | sync | |

### How to read it
1. **REST + JWT**: the app sends the transaction to `decision-api` with the user's JWT and an `Idempotency-Key`. It can come from the analyst's queue or from the simulator (`ADMIN` only); `decision-api` checks the permission (RBAC). A key it has already stored returns the original result and skips steps 2–6 (`docs/model.md` §9).
2. **counters**: `decision-api` reads the customer's recent facts from Redis (last 24 h of transactions and session events, last location) and counts the short windows: velocity, spend, impossible travel, failed logins (`docs/features.md`).
3. **profile**: it reads the rest from Postgres: the customer and device rows (home, account and device age) and three indexed history queries (30-day average amount, known device, customers on the device). Features that come with the transaction itself (amount, hour, category) need no lookup.
4. **/score (breaker)**: it asks `scoring-api` for the fraud probability behind a circuit breaker with a timeout, then evaluates the rules. If scoring does not answer, the decision uses rules only and is marked `degraded`.
5. **store**: in one database transaction it stores the transaction, the decision with `features_json` (the exact values used), the evaluated rules and, for `REVIEW`/`BLOCK`, the case.
6. **update**: only after that commit it appends the transaction to the customer's Redis keys, so a transaction never counts itself and Redis never holds one that Postgres lost. Then it answers the app.

- **without Redis** (contingency): if Redis does not answer, or answers but has lost its data (no `features:ready` marker), the step-2 features are computed with Postgres queries instead.
- **loads**: `scoring-api` serves the active model from memory. It downloads the file from the `models` bucket (SeaweedFS, S3 API) only when it is told to activate a version (`PUT /active-model`), checks its SHA-256 and swaps it in; `/score` never reads the bucket. After a restart it has no model until `decision-api` sends the active version again, and meanwhile decisions are `degraded`.

---

## Diagram: architecture-background

Title: MonedaSegura MVP: background flows
Subtitle: Flows off the critical path: nobody waits for them. Each band is one flow, read left to right.

### Zones
| id | label | columns | rows |
|---|---|---|---|
| z-a | A · re-evaluation (decision-service) | 0–2 | 0 |
| z-b | B · daily retraining at 02:00 | 0–3 | 1 |
| z-c | C · initial seed (runs once) | 0–2 | 2 |
| z-d | D · Redis rebuild (when empty) | 0–2 | 3 |

### Nodes
| id | name | technology | type | column | row |
|---|---|---|---|---|---|
| dec | decision-api | Spring · rule engine | API | 0 | 0 |
| kafka | kafka | Kafka · topic decisions | BUS | 1 | 0 |
| reeval | re-evaluator | Spring @KafkaListener | API | 2 | 0 |
| pgb | postgres | PostgreSQL · labeled cases | DB | 0 | 1 |
| retrain | retrainer | Spring @Scheduled 02:00 | API | 1 | 1 |
| sco | scoring-api | FastAPI · trains LightGBM | API | 2 | 1 |
| models | models | SeaweedFS · S3 bucket | DB | 3 | 1 |
| sparkov | sparkov | Kaggle · Sparkov (CC0) | EXT | 0 | 2 |
| seed | seed-job | Python · colombianizes | API | 1 | 2 |
| pgc | postgres | PostgreSQL · same DB | DB | 2 | 2 |
| pgd | postgres | PostgreSQL · last 24 h | DB | 0 | 3 |
| rebuild | rebuilder | Spring · warm-up job | API | 1 | 3 |
| redisd | redis | Redis · 24 h counters | DB | 2 | 3 |

`postgres` appears in bands B, C and D on purpose: it is the same database, drawn once per flow so each band reads on its own.

### Connections
| from | to | label | type | step |
|---|---|---|---|---|
| dec | kafka | publishes | async | |
| kafka | reeval | consumes | async | |
| reeval | dec | re-scores degraded | sync | |
| retrain | pgb | reads labels | sync | |
| retrain | sco | /retrain | sync | |
| sco | models | uploads | sync | |
| sparkov | seed | download | async | |
| seed | pgc | load | async | |
| rebuild | pgd | reads | sync | |
| rebuild | redisd | writes keys | sync | |

### How to read it
- **A · re-evaluation**: every decision is published to the `decisions` topic (at least once, so a degraded decision that already has a `REEVALUATION` is skipped). The `re-evaluator` (same `decision-service`) consumes it and, if it was `degraded`, sends it back to `decision-api` once scoring is back. The new `REEVALUATION` decision reuses the original `features_json` (recomputing the windows later would count transactions that happened afterwards): only the score and the rules run again.
- **B · daily retraining**: at 02:00 (or with the manual button) the `retrainer` reads the labeled cases from Postgres and sends them to `scoring-api` (`/retrain`), which trains a new model and uploads it to the `models` bucket; `decision-api` records its `artifact_uri` in `model_version`. It is activated only if it passes the quality gate (`docs/model.md` §8).
- **C · initial seed**: the `seed-job` (a script in `scoring-service`) downloads Sparkov, colombianizes it and loads it into Postgres once (`docs/data.md`).
- **D · Redis rebuild**: Redis keeps no data on disk, so after a restart its keys are gone and an empty key would look like "no activity". When `decision-api` finds no `features:ready` marker, it computes features from Postgres (the contingency path) while one `rebuilder` run reloads the last 24 h of each customer's transactions and session events, and their last location; then it sets the marker and step 2 uses Redis again (`docs/features.md`).
