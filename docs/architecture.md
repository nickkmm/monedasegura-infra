# MonedaSegura — MVP architecture

Source for the two MVP architecture diagrams, drawn with the `arch-svg` skill. They replace, for the MVP, the paper's final-architecture diagram (`data/01_essentials/architecture/MonedaSegura_arquitectura_v1.svg`).

The architecture is split into two diagrams on purpose: one per kind of flow, so each reads left to right without detours.

| Diagram | What it shows |
|---|---|
| `architecture-decision-path` | What happens while the app waits: steps 1→4 in under 500 ms, plus the degradation paths |
| `architecture-background` | What runs off the critical path: re-evaluation, daily retraining, initial seed |

---

## Diagram: architecture-decision-path

Title: MonedaSegura MVP: decision path
Subtitle: What happens while the app waits: steps 1→4 in under 500 ms. Red dotted lines are degradation paths.

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
| redis | redis | Redis · online features | DB | 2 | 0 |
| sco | scoring-api | FastAPI · LightGBM | API | 2 | 1 |
| models | models | SeaweedFS · S3 bucket | DB | 3 | 1 |
| pg | postgres | PostgreSQL · records | DB | 2 | 2 |

### Connections
| from | to | label | type | step |
|---|---|---|---|---|
| app | dec | REST + JWT | sync | 1 |
| dec | redis | features | sync | 2 |
| dec | sco | /score (breaker) | sync | 3 |
| dec | pg | SQL | sync | 4 |
| dec | pg | without Redis | contingency | |
| sco | models | loads | sync | |

### How to read it
1. **REST + JWT**: the app sends the transaction to `decision-api` with the user's JWT. It can come from the analyst's queue or from the simulator (`ADMIN` only); `decision-api` checks the permission (RBAC).
2. **features**: `decision-api` reads the customer's counters from Redis (velocity, accumulated spend, last location and device).
3. **/score (breaker)**: it asks `scoring-api` for the fraud probability behind a circuit breaker with a timeout. If scoring does not answer, this step is skipped: the decision uses rules only and is marked `degraded`.
4. **SQL**: it stores the transaction, the decision, `features_json` and the evaluated rules in Postgres, and answers the app.

- **without Redis** (contingency): if Redis does not answer, features are recomputed with Postgres queries.
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

`postgres` appears in bands B and C on purpose: it is the same database, drawn once per flow so each band reads on its own.

### Connections
| from | to | label | type | step |
|---|---|---|---|---|
| dec | kafka | publishes | async | |
| kafka | reeval | consumes | async | |
| reeval | dec | re-decides degraded | sync | |
| retrain | pgb | reads labels | sync | |
| retrain | sco | /retrain | sync | |
| sco | models | uploads | sync | |
| sparkov | seed | download | async | |
| seed | pgc | load | async | |

### How to read it
- **A · re-evaluation**: every decision is published to the `decisions` topic. The `re-evaluator` (same `decision-service`) consumes it and, if it was `degraded`, runs it through `decision-api` again once scoring is back, creating a `REEVALUATION` decision.
- **B · daily retraining**: at 02:00 (or with the manual button) the `retrainer` reads the labeled cases from Postgres and sends them to `scoring-api` (`/retrain`), which trains a new model and uploads it to the `models` bucket; `decision-api` records its `artifact_uri` in `model_version`. It is activated only if it passes the quality gate (`docs/model.md` §8).
- **C · initial seed**: the `seed-job` (a script in `scoring-service`) downloads Sparkov, colombianizes it and loads it into Postgres once (`docs/data.md`).
