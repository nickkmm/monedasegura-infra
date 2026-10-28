# MonedaSegura — feature catalog

Single source of truth for the risk features. The same names are used by:

- the `decision-service`, which computes them (see "Where each feature comes from") and stores them in `decision.features_json`;
- the rule engine, whose `condition_json` refers to them by name;
- the `scoring-service`, which receives them in `POST /score` and trains on them in `POST /retrain`;
- the app's rule editor, which lists them through `GET /features`.

Adding, renaming or changing a feature is a PR against this file (and the OpenAPI contracts), reviewed by the owners of the decision and scoring services. A feature that exists in one place but not the others breaks the model silently.

## Conventions

- `snake_case` names; windows are suffixes (`_5m`, `_1h`, `_24h`, `_30d`).
- Windows are measured backwards from the transaction's `occurred_at`, excluding the transaction itself: features are computed before the transaction is written anywhere.
- `BALANCE_QUERY` transactions count for velocity features but are never scored.
- Distances in kilometers (haversine), amounts in COP, times in Colombia time (`America/Bogota`).
- When a value cannot be computed (new customer, no previous transaction), the default listed below is used; the model learns that the default means "no history".

## Catalog (v1)

| Name | Type | Default | Definition | Signal it targets |
|---|---|---|---|---|
| `amount` | number | — | Transaction amount in COP | card fraud (Sparkov p50: 5× legit) |
| `amount_vs_avg_30d` | number | `1.0` | `amount` / customer's average amount over the last 30 days | card fraud, ATO |
| `spend_24h` | number | `0` | Sum of the customer's amounts in the last 24 h | card fraud bursts |
| `tx_count_5m` | integer | `0` | Customer's transactions in the last 5 minutes | velocity |
| `tx_count_1h` | integer | `0` | Customer's transactions in the last hour | velocity |
| `minutes_since_prev` | number | `10080` | Minutes since the customer's previous transaction (default: one week) | velocity (Sparkov p50: 82 vs 262) |
| `km_from_home` | number | `0` | Distance from `customer.home_latitude/longitude` to the transaction | ATO, impossible travel |
| `km_from_prev` | number | `0` | Distance from the previous transaction's location | impossible travel |
| `implied_speed_kmh` | number | `0` | `km_from_prev` / (`minutes_since_prev` / 60), capped at 2000 | impossible travel |
| `hour_of_day` | integer | — | Local hour 0–23 of `occurred_at` | night fraud |
| `is_night` | boolean | — | `hour_of_day` in 22–03 | night fraud (Sparkov: 1.9 % vs 0.1 %) |
| `category` | string | `unknown` | Merchant category (`transaction.category`) | online categories concentrate fraud |
| `is_new_device` | boolean | `true` | The device never appeared before in the customer's transactions or session events | ATO |
| `device_age_days` | number | `0` | Days since `device.first_seen_at` | ATO |
| `customers_on_device` | integer | `1` | Distinct customers seen on this device in the last 30 days | fraud rings |
| `failed_logins_1h` | integer | `0` | Customer's `LOGIN_FAILED` session events in the last hour | ATO |
| `password_changed_24h` | boolean | `false` | A `PASSWORD_CHANGED` event in the last 24 h | ATO |
| `account_age_days` | number | — | Days since `customer.created_at` | origination fraud |

Notes:
- `score` is **not** a feature of the model: it is the model's output. Rules may use it as if it were one (`docs/model.md` §5).
- `scenario` and `source` are never features (`docs/data.md` §4).
- Sparkov provides no device or session data, so `is_new_device`, `device_age_days`, `customers_on_device`, `failed_logins_1h` and `password_changed_24h` take their defaults for seed rows; only the simulator produces non-default values.

## Where each feature comes from

| Source | Features | Why there |
|---|---|---|
| The transaction itself | `amount`, `category`, `hour_of_day`, `is_night` | Nothing to look up. Never stored beforehand |
| Redis, recent facts | `tx_count_5m`, `tx_count_1h`, `spend_24h`, `minutes_since_prev`, `km_from_prev`, `implied_speed_kmh`, `failed_logins_1h`, `password_changed_24h` | The answer depends on the exact second and changes with every event, so it is counted when the transaction arrives |
| Postgres, one row by id | `km_from_home`, `account_age_days`, `device_age_days` | Fixed data of the customer or device |
| Postgres, indexed history query | `amount_vs_avg_30d`, `is_new_device`, `customers_on_device` | Long windows that barely move with one more transaction. The same SQL computes them for the seed and live, so training and serving cannot drift apart. At real scale they would become a per-customer profile refreshed daily |

When Redis does not answer or has lost its data, the Redis features are computed with Postgres queries over `transaction` and `session_event`; the values are the same, only slower.

## Redis keys

Redis holds **recent facts** (times, amounts, places, logins), never feature values: a value such as `tx_count_5m = 3` changes with the clock, so it is counted from the facts on every request. All keys are per customer except the marker.

| Key | Structure | Content | Retention | Feeds |
|---|---|---|---|---|
| `cust:{id}:tx` | sorted set, score = `occurred_at` (epoch ms) | member `{txId}:{amount}`; `BALANCE_QUERY` has amount `0` | trimmed to 24 h on every write; the key expires 24 h after the last write | `tx_count_5m`, `tx_count_1h`, `spend_24h` |
| `cust:{id}:last` | hash | `lat`, `lon`, `at` of the last transaction | overwritten on every transaction; no expiry (three fields per customer) | `minutes_since_prev`, `km_from_prev`, `implied_speed_kmh` |
| `cust:{id}:auth` | sorted set, score = `occurred_at` (epoch ms) | member `{eventId}:{eventType}` | trimmed to 24 h on every write; expires 24 h after the last write | `failed_logins_1h`, `password_changed_24h` |
| `features:ready` | string | `1` | set when a rebuild finishes; absent means Redis lost its data | — |

The member carries the id because a sorted set keeps one copy of each member: two purchases of the same amount would otherwise collapse into one.

## Write order

1. Compute the features (Redis + Postgres + the transaction).
2. Score and evaluate the rules.
3. Commit to Postgres in one database transaction: `transaction`, `decision` with `features_json`, `decision_rule_hit` rows and, if any, `fraud_case`.
4. Only then update Redis in one pipeline: `ZADD` + trim + `EXPIRE` on `cust:{id}:tx`, `HSET` on `cust:{id}:last`.

Session events follow the same order: insert into `session_event`, then `ZADD` on `cust:{id}:auth`.

- If step 3 fails, Redis is not touched: it never counts a transaction that does not exist.
- If step 4 fails after the commit, Redis is missing one fact. The `decision-service` deletes `features:ready`, which triggers a rebuild.
- Two transactions of the same customer decided at the same instant do not see each other. The MVP accepts it; the simulator sends one customer's events in order.

## Rebuild when Redis is empty

Redis runs without persistence, so after a restart every key is gone, and a missing key would read as "no activity". The marker tells the two cases apart:

- `features:ready` present → use Redis.
- Absent → compute these features from Postgres for this request, and start one rebuild (guarded with `SET features:rebuilding 1 NX EX 300`): for every customer, reload the last 24 h of `transaction` and `session_event` and the last transaction into the keys above, then `SET features:ready 1`.

The same Postgres path serves when Redis does not answer at all; the dashboard then shows `REDIS_UNAVAILABLE`.
