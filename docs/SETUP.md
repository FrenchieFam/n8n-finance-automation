# Setup notes and export limitations

These notes describe the supplied exports. The original PROJECT.md records the MVP design, including planned behavior that is not implemented in every export.

## Database coverage

`setup-database.json` creates only `bills`, `notifications`, and `run_log`. Its fixed seed rows match `examples/mock-bills.csv`; it does not parse that file. `INSERT OR IGNORE` avoids duplicate seed IDs, but setup also writes a new run-log row each time.

Before using the other workflows, provision and review your own compatible schema:

- CSV import needs `expenses` columns: `date`, `description`, `amount`, `currency`, `category`, `owner`, `source`, `external_id`, `notes`, `created_at`. Deduplication requires a UNIQUE constraint/index on `external_id`.
- Receipt OCR also needs `expenses.receipt_path`. Allow null external IDs for receipts.
- Savings reports need `savings_goals` columns: `name`, `target_amount`, `current_amount`, `deadline`.

No additional schema migration is bundled. Test on a fresh local database before using real data.

## Bill reminders and reports

The bill-reminder export has a Manual Trigger and writes SQLite notifications; it does not send a Discord message. Add and verify a Schedule Trigger yourself if you want daily reminders. The daily 09:00 trigger described in PROJECT.md is a design target.

The monthly overview labels its total EUR. CSV and receipt imports have USD defaults. Adapt currency assumptions before mixing data. The monthly report's ordered aggregate syntax also depends on the SQLite runtime shipped by the installed community node.

## CSV input

The CSV form expects the following case-sensitive headings:

```csv
Date,Description,Amount Debit,Amount Credit,Transaction Number,Memo
01/15/2026,Mock groceries,-42.50,0,mock-0001,Example only
```

Dates are parsed as MM/DD/YYYY. The existing amount expression negates the sum of debit and credit; review your bank export's signs first. Transaction numbers become deduplication IDs. `examples/mock-bills.csv` is bill seed data, not a transaction CSV for this form.

## Receipt images

The export uses the existing `Parse Extraction` JavaScript Code node. No new Code node was introduced during repository preparation. Review this node under the project's approval policy before running it.

The write node targets `/data/receipts/YYYY-MM/<uploaded filename>`. Prepare the current month folder, for example in PowerShell:

```powershell
$receiptMonth = Get-Date -Format 'yyyy-MM'
docker compose exec -u node n8n mkdir -p "/data/receipts/$receiptMonth"
```

Use filenames you control, avoid repeated names that could overwrite files, and verify the file-access restriction permits `/data`. The workflow does not create the monthly directory. Its file-write node may require migration on newer n8n versions; verify node availability before execution.

Ollama runs on the host in the supplied configuration. Use `host.docker.internal` from Docker, `localhost` from native n8n, or your own private service address. No cloud OCR provider is configured.

## Public-copy preparation

Six workflow files were copied from the source project. The monthly overview was found at the source root. Source files were preserved. Only the mock bill CSV and validator script were carried over as supporting files; receipt images, captured OCR request payloads, historical exports, and internal planning files were excluded.

Workflow credential bindings contain generic names only. Source credential IDs, webhook IDs, workflow IDs, pinned data, and instance metadata were removed; all exports were set inactive. The private Tailscale address was checked and no occurrence was found in these six source exports. Any occurrence would be replaced with localhost.

Static validation does not certify runtime compatibility. Docker deployment, community-node installation, n8n imports, credential connections, Discord delivery, and OCR execution must be checked locally.
