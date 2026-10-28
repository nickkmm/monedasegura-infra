# MonedaSegura — data sources and processing

Decision (2026-10-24): **hybrid approach**. No real banking data is available (it is protected personal and financial data), so the system combines a public dataset for card fraud with an in-house simulator for what no dataset provides.

| Part | Comes from | `transaction.source` | `scenario` |
|---|---|---|---|
| Customers, historical transactions and card fraud | **Sparkov** dataset, colombianized | `SEED_DATASET` | `NORMAL`, `DATASET_FRAUD` |
| Devices, session events, account takeover (ATO) and origination fraud | In-house **simulator** | `SIMULATOR` | `NORMAL`, `ATO`, `ORIGINATION` |

## 1. Base dataset: Sparkov

- Source: [Credit Card Transactions Fraud Detection Dataset](https://www.kaggle.com/datasets/kartik2112/fraud-detection) (Kaggle, Kartik Shenoy), generated with Brandon Harris's [Sparkov Data Generation](https://github.com/namebrandon/Sparkov_Data_Generation).
- License: **CC0: Public Domain** (checked against the Kaggle API on 2026-10-24).
- Content: 1,852,394 simulated card transactions, 2019-01-01 to 2020-12-31, 999 customers (one card each), 693 merchants, 51 US states; 0.52 % fraud (9,651 rows).
- It is never committed to any repo (~500 MB). The `scoring-service` owns the script that downloads and transforms it.

### Signals it carries (own analysis over the 1.85 M rows)

| Signal | Legitimate (p50) | Fraud (p50) | Useful |
|---|---|---|---|
| Amount | 47 USD | 390 USD | yes |
| Amount / customer's previous average | 0.7× | 5.3× | yes |
| Fraud rate 22:00–03:00 vs rest of the day | — | 1.9 % vs 0.1 % | yes |
| Minutes since previous transaction | 262 | 82 | yes |
| Category (`shopping_net`, `misc_net`, `grocery_pos` concentrate fraud) | — | — | yes |
| Km home → merchant | 78 | 78 | **no** |
| Km from previous transaction | 101 | 100 | **no** |

### Declared limitations
- **Location does not discriminate**: the generator places merchants randomly around the home, fraud or not. "Impossible travel" is provided by the simulator.
- **Unrealistic fraud distribution**: 976 of 999 customers suffer exactly one episode (≈10 transactions over ≈45 h). Good for training, not for claiming fraud rates.
- **No device or session data**: no account-takeover signal.
- It is simulated: the model demonstrates the mechanism, not effectiveness on real fraud.

## 2. Transformation ("colombianize")

1. **Sample**: 200 customers and their last 6 months (~70k transactions), with a fixed random seed so every teammate gets the same data.
2. **Dates**: shifted to end on the load date, preserving time of day, weekday and gaps between transactions.
3. **Amounts**: USD → COP at a fixed **1 USD = 4,000 COP** (round and declared; it does not try to match the day's rate).
4. **Location**: each customer gets a Colombian city as home (draw weighted by population). Their merchants are moved keeping the offset (distance and bearing) they had from the original home.
5. **Identity**: names and document numbers are regenerated as fictitious Colombian data; `cc_num` is not stored.
6. **Mapping**:

| Sparkov | MonedaSegura |
|---|---|
| `cc_num` | `customer` (one to one) |
| `lat`, `long` (moved) | `customer.home_latitude`, `home_longitude` |
| `city` (reassigned) | `customer.home_city` |
| `trans_date_trans_time` (shifted) | `transaction.occurred_at` |
| `amt` × 4,000 | `transaction.amount` (`currency = COP`) |
| `category` | `transaction.category` |
| `merchant` | `transaction.counterparty` |
| `merch_lat`, `merch_long` (moved) | `transaction.latitude`, `longitude` |
| `trans_num` | `transaction.idempotency_key` (reloading the seed cannot duplicate rows) |
| `is_fraud` | `scenario = DATASET_FRAUD` / `NORMAL` |

There is no `account` table: Sparkov has one card per customer, so it would duplicate `customer`.

## 3. Simulator

Generates live traffic from the app (permission `SIMULATOR_RUN`, `ADMIN` only). It takes each seeded customer's real habits (typical amount, hours, categories, city) and produces:

- **Normal**: transactions within those habits.
- **Account takeover (ATO)**: failed logins, password change, new device, then large transactions from an impossible location.
- **Origination**: a brand-new customer (account just created) that immediately moves large amounts.
- **Card fraud**: a burst of online purchases at night, far above the customer's average (the Sparkov pattern); stored as `scenario = CARD_FRAUD`, so it can be told apart from the seeded `DATASET_FRAUD`.

The simulator calls `POST /transactions` like any client would, with a fresh `Idempotency-Key` per event; the decision path does not know the transaction is simulated.

## 4. Golden rule

`scenario` and `source` are **never** model features. `scenario` is the right answer: it is only used as a training label and to measure false positives and false negatives.
