# MonedaSegura — feature catalog

Single source of truth for the risk features. The same names are used by:

- the `decision-service`, which computes them (from Redis, or from Postgres when Redis is unavailable) and stores them in `decision.features_json`;
- the rule engine, whose `condition_json` refers to them by name;
- the `scoring-service`, which receives them in `POST /score` and trains on them in `POST /retrain`;
- the app's rule editor, which lists them through `GET /features`.

Adding, renaming or changing a feature is a PR against this file (and the OpenAPI contracts), reviewed by the owners of the decision and scoring services. A feature that exists in one place but not the others breaks the model silently.

## Conventions

- `snake_case` names; windows are suffixes (`_5m`, `_1h`, `_24h`, `_30d`).
- Windows are measured backwards from the transaction's `occurred_at`, excluding the transaction itself.
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

## Where each feature lives in Redis

Per-customer keys, updated on every transaction or session event; Postgres can rebuild all of them.

| Key | Structure | Feeds |
|---|---|---|
| `cust:{id}:tx` | sorted set (score = epoch ms, member = `{txId}:{amount}`), trimmed to 30 days | `tx_count_*`, `spend_24h`, `amount_vs_avg_30d`, `minutes_since_prev` |
| `cust:{id}:last` | hash (`lat`, `lon`, `at`) | `km_from_prev`, `implied_speed_kmh` |
| `cust:{id}:devices` | set of device ids | `is_new_device` |
| `cust:{id}:auth` | sorted set of session events (score = epoch ms) | `failed_logins_1h`, `password_changed_24h` |
| `dev:{id}:customers` | sorted set (score = last seen) | `customers_on_device` |
