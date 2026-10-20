> Historical MVP design: see [SETUP.md](SETUP.md) for the behavior and limitations of the bundled exports.

# Project

Two-person household budget automation on self-hosted n8n.

## Data model (MVP)

Table `bills`:
| column     | type    | notes                                  |
|------------|---------|----------------------------------------|
| id         | INTEGER | primary key, autoincrement             |
| name       | TEXT    | e.g. "Electricity"                     |
| amount     | REAL    | expected amount, informational         |
| currency   | TEXT    | ISO 4217, default EUR                  |
| due_day    | INTEGER | day of month 1-31                      |
| owner      | TEXT    | "me" / "partner" / "shared"            |
| category   | TEXT    | housing / utilities / subs / other     |
| status     | TEXT    | unpaid / paid                          |
| last_paid  | TEXT    | ISO date or NULL                       |
| notes      | TEXT    | free text                              |

Table `notifications` (MVP output):
| column     | type    | notes                        |
|------------|---------|------------------------------|
| id         | INTEGER | primary key                  |
| created_at | TEXT    | ISO timestamp                |
| bill_id    | INTEGER | FK to bills.id               |
| message    | TEXT    | human-readable reminder text |
| channel    | TEXT    | "sqlite" / "discord" / ...   |
| delivered  | INTEGER | 0 or 1                       |

Table `run_log`:
| column     | type    | notes                       |
|------------|---------|-----------------------------|
| id         | INTEGER | primary key                 |
| run_at     | TEXT    | ISO timestamp               |
| workflow   | TEXT    | workflow name               |
| status     | TEXT    | ok / error                  |
| detail     | TEXT    | error message or summary    |

## Input path
MVP: seed from `examples/mock-bills.csv`.
Later: manual entry form or CSV import. No bank API.

## Notification
MVP: write to `notifications` table only (fully local, zero external deps).
Phase 2: Discord webhook to a #finance channel.
Later candidates: Telegram, ntfy (self-hosted), local email.

## Reminder logic (MVP, locked)

### Per-bill configuration
Add to `bills` table:
- `remind_offsets TEXT NOT NULL DEFAULT '7,1,0'`
  - Comma-separated list of "days before due" to remind.
  - Default: 7 days before, 1 day before, day-of.
  - Per-row override examples: rent -> '1,0', subscriptions -> '0'.

### Workflows (two)

**A. `setup-database.json`** (one-time, idempotent)
- Manual trigger.
- Creates tables if not exist: `bills`, `notifications`, `run_log`.
- Seeds `bills` from `examples/mock-bills.csv` (INSERT OR IGNORE by id).
- Safe to re-run without duplicating rows.

**B. `bill-reminders.json`** (daily MVP)
- Cron: daily 09:00.
- For each unpaid bill, compute `days_until_next_due`.
- If `days_until_next_due` is in the bill's `remind_offsets`, insert a notification.
- Insert one row into `run_log` at the end (status ok, or error with detail).

### Due date calculation (careful - this is the one tricky bit)
- Target month = current month if `due_day >= today's day`, else next month.
- Clamp `due_day` to the target month's last day (e.g. day 31 in Feb -> 28/29).
- `days_until_next_due` = integer days from today to the target due date.

### Notification message format
`[{owner}] {name}: {amount} {currency} due in {n} day(s) (due day {due_day})`

Example: `[shared] Rent: 1150.00 EUR due in 1 day(s) (due day 1)`

### Dedup (MVP)
Accept duplicates. A retry on the same day may insert duplicate rows.
Phase 2 adds a unique index on (bill_id, date(created_at), channel).