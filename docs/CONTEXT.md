# MonedaSegura — essential context

Distilled from `data/01_essentials/NuestroReto.pdf`, `data/01_essentials/instruciones_entrega.md` and `data/01_essentials/MonedaSegura_IEEE_FINAL_con_diagrama.docx` (source documents, in Spanish). If anything here contradicts them, the source documents win. The current MVP is defined in `docs/MVP_PLAN.md`.

## 1. The challenge (client: Lovelytics, Case 3)
A neobank (Colombia, Peru, Mexico) with 1.8 M active users, ~4 M tx/day, peaks of 500 tx/s. The risk team's manually maintained static rules let fraud through (false negatives) and block legitimate customers (false positives). Fraud types: origination (fake accounts) and account takeover.

The Risk Committee asks for:
1. Evaluating every transaction in < 500 ms, combining business rules and ML models.
2. An enriched per-user history (spending, devices, locations) as model features.
3. Letting the risk team change rules/models without a long development cycle.

Hard constraint: if scoring fails or is slow, the system keeps operating (contingency mode) without blocking legitimate transactions.

Available data: transaction stream, auth/session events (login, password change, new device), device fingerprinting from an external API, a small and imbalanced history of labeled cases, the current rules in an internal tool.

Challenge deliverables: end-to-end streaming architecture diagram with real-time decision points, feature catalog (feature store), resilience/contingency strategy, continuous-improvement loop fed by investigated cases.

Lovelytics rubric: architecture 25 %, data quality and governance 20 %, problem understanding 15 %, justification of decisions 15 %, clarity/communication 15 %, risks and assumptions 10 %. Reasoning is graded, not implementation; there is no single correct architecture.

## 2. Current course deliverable (`instruciones_entrega.md`)
Deliverables: (a) context text, (b) ERD image, (c) link to the prototype + component gallery, readable by the professor.
- ERD: entities with main attributes, PKs, FKs, cardinalities.
- Prototype: screens of the main journey (sign in, see the list, open a detail, create something); the data shown must be consistent with the ERD.
- Component gallery: a single view with each component once, named (buttons, fields, list card, top/navigation bar, custom components).

## 3. The paper (IEEE, Icesi) — what it decided
Authors: Rojas, Mejía, Solis, Gómez, Cárdenas. Advisor: J. L. Jurado. AI-assisted SLR (Gemini and Claude) with an Importance-Reliability Matrix; final corpus of 54 sources. Nine decisions by layer:

| # | Decision | Chosen | Discarded |
|---|---|---|---|
| 1 | Flink state | Disaggregated state (Flink 2.0 ForSt): checkpoints < 3 s, recovery up to 49× faster | Local RocksDB |
| 2 | Rescaling | Prioritized state migration (Meces) | Full restart, Megaphone, Rhino |
| 3 | Messaging | Kafka with tiered storage (Kora) | Monolithic Kafka |
| 4 | Model | HTGNN (AUC 0.940 vs 0.851 LightGBM, ~1.9 ms), shadow mode first | Tabular only / static GNN |
| 5 | Features | Centralized online + offline feature store (no training-serving skew) | Per-team features |
| 6 | Inference | Conventional ML microservice + edge filters | In-network inference on P4 switches (MIND) |
| 7 | Robustness | MLOps checklist: drift, fail-open circuit breaker to last-known-good rules, shadow/canary, label-noise audit | Vendor default monitoring |
| 8 | Governance | Rules versioned in a repo, PR + backtest, commit/data/approver lineage | Direct edits in the tool |
| 9 | Pattern | Lambda (offline BatchNet + online SpeedNet) | Pure Kappa as the target |

Paper roadmap: **MVP in pure Kappa (Kafka + Flink)**, then integrate the HTGNN. A transaction authorized in fail-open stays in the Kafka log and is re-evaluated later (deferred, not absent, enforcement).

## 4. How the MVP departs from the paper
The paper's Section VII planned Kafka + PyFlink + Feast + LightGBM + FastAPI + a React console. The course changed to Flutter, and the team defined a new MVP (`docs/MVP_PLAN.md`): Flutter app, Spring Boot decision service, FastAPI scoring service, Postgres, Redis and Kafka. It keeps the paper's principles (contingency path, single feature definitions via `features_json`, shadow + backtest + approval for rules, deferred enforcement through Kafka, tabular model first) without Flink, Feast or the HTGNN.

## 5. Diagrams
- `data/01_essentials/architecture/MonedaSegura_arquitectura_v1.svg`: the paper's **final** architecture (not the MVP).
- `docs/diagrams/architecture-decision-path.svg` and `docs/diagrams/architecture-background.svg`: the MVP architecture (`docs/architecture.md`).
