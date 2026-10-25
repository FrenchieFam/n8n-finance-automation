<div align="center">

# n8n Finance Automation

### Your finances. Your hardware. Your workflows.

A local, self-hosted financial automation suite built with **n8n**, **SQLite**, and **Ollama**, with optional **Discord** reports.

[Workflows](#workflows) · [Quick start](#quick-start) · [Privacy](#privacy) · [Project notes](docs/PROJECT.md)

</div>

---

Import expenses, read receipts with a local vision model, track upcoming bills, and share a household budget overview. The core runs on your own machine, without bank connections or a paid AI API. Discord reporting is optional and sends report content to Discord.

```text
CSV uploads ───────────┐
                      ├──► n8n ───► SQLite budget database
Receipt images ─► Ollama       │
                              └──► Discord reports (optional)
```

## Workflows

| Workflow | Purpose | Current trigger |
| --- | --- | --- |
| [Setup database](workflows/setup-database.json) | Create bills, notifications, and run-log tables; seed mock bills | Manual |
| [Bill reminders](workflows/bill-reminders.json) | Preview due bills and record notifications in SQLite | Manual |
| [Monthly overview](workflows/monthly-overview.json) | Summarize unpaid bills and send a Discord report | Schedule |
| [CSV import](workflows/csv-import.json) | Upload transaction CSVs and insert expenses | Form |
| [Receipt OCR](workflows/receipt-ocr.json) | Extract receipt fields with Ollama, save images, and insert expenses | Form |
| [Savings goals](workflows/savings-goals.json) | Summarize savings progress and send a Discord report | Schedule |

**These are sanitized workflow exports, not a verified turnkey deployment.** All are inactive. The setup workflow creates the original bill-reminder schema; CSV import, receipt OCR, and savings reports also require tables described in [setup notes](docs/SETUP.md). The receipt workflow includes an existing JavaScript Code node that must be reviewed before use.

## Quick start

### 1. Start n8n with Docker Compose

Install Docker with Compose, download or clone this repository, and run from its root:

```sh
cp .env.example .env
# Optional: edit GENERIC_TIMEZONE in .env before starting.
docker compose up -d
```

In PowerShell, use `Copy-Item .env.example .env` for the copy step. Open [localhost:5678](http://localhost:5678) and create your n8n owner account.

The included Compose file binds the editor to loopback. It persists n8n settings, encrypted credentials, and installed nodes in `n8n_data`; the separate `budget_data` volume mounts at `/data` for budget records and receipts. Keep both volumes backed up. `N8N_SECURE_COOKIE=false` supports this localhost HTTP setup; use HTTPS and secure cookies if you later expose the service.

The image uses the moving `stable` tag as a starting point. After testing, pin a specific compatible version or digest. This configuration has not been started or tested against the exports here. See the official [n8n Docker guide](https://docs.n8n.io/hosting/installation/docker/).

### 2. Install the SQLite community node

As the n8n owner, open **Settings → Community Nodes → Install**, enter `n8n-nodes-sqlite3`, review the package and installation notice, and install it. These exports use its `sqliteNode` type and `sqliteCredentialsApi` credential. A different SQLite package is not a drop-in replacement.

Verify that a SQLite node loads successfully before importing. If native SQLite bindings fail to install in your container, resolve the package/image compatibility first. Record the working n8n and node versions for reproducibility. See [community-node installation](https://docs.n8n.io/integrations/community-nodes/installation/gui-install/).

### 3. Create and select credentials

| Credential name in exports | Configure inside n8n |
| --- | --- |
| `SQLite Database account` | SQLite credential with database path `/data/budget.sqlite` |
| `Discord Webhook account` | Discord webhook credential containing your private webhook URL |

Create the credentials in n8n, then explicitly select them on every relevant imported node. Names in JSON are placeholders; no credential IDs, passwords, API keys, or webhook URLs are bundled. Use the same budget database across all six workflows. It is separate from n8n's internal database.

For a fully local setup, leave the Discord workflows inactive or disconnect their Discord nodes before testing locally. Keep webhook URLs out of workflow parameters and repository files.

### 4. Prepare local OCR

Install [Ollama](https://ollama.com/) on the host, then download the [model used by the export](https://ollama.com/library/qwen2.5vl:7b-q4_K_M):

```sh
ollama pull qwen2.5vl:7b-q4_K_M
```

The OCR node calls `http://host.docker.internal:11434/api/chat` so a Docker container can reach host Ollama. Native n8n installations should use `http://localhost:11434/api/chat`. Inside a container, `localhost` refers to that container. Confirm connectivity and configure Ollama's bind address/firewall for your Docker network if needed; keep its API private.

Receipt images are written under `/data/receipts/YYYY-MM/`. Create the current month directory before uploading; see [setup notes](docs/SETUP.md). Review OCR results before treating them as financial records.

### 5. Import and test with mock data

1. Import `workflows/setup-database.json` into a new, inactive workflow. Select the SQLite credential, inspect its SQL, and execute it manually against a fresh test database.
2. Import the remaining JSONs as inactive workflows and reselect their credentials.
3. Review [setup notes](docs/SETUP.md) for additional tables, CSV column names, currencies, and receipt storage.
4. Test bills with [mock-bills.csv](examples/mock-bills.csv). The setup export contains matching seed rows; it does not read the CSV file automatically. Use the form test URLs for CSV and receipt uploads.
5. Check database rows, saved files, error paths, and any intended Discord messages. Review schedule times and timezone before activating a workflow.

## Validate exports

With PowerShell installed:

```powershell
Get-ChildItem ./workflows/*.json | ForEach-Object {
    & ./scripts/validate-workflow.ps1 -Path $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Validation failed: $($_.Name)" }
}
```

The included validator checks JSON structure, node names, forbidden Execute Command nodes, and some placeholder values. It does not prove that credentials, SQL, OCR, Docker, or n8n execution work. Import and manual testing remain required.

## Privacy

Budget storage and receipt processing run locally. Discord nodes send financial summaries to a third party when executed. Initial image, package, and model downloads require internet access. No bank credentials are needed.

Keep real statements, receipts, database files, `.env`, exported credentials, and backups out of Git. The supplied `.gitignore` covers common paths and file types, but review every public export. See [SAFETY.md](docs/SAFETY.md).

## Repository map

```text
.
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
├── workflows/    # Six inactive, sanitized n8n exports
├── docs/         # Project scope, safety, conventions, setup notes
├── examples/     # Mock bill data
└── scripts/      # Pre-import validation
```

Read [PROJECT.md](docs/PROJECT.md) for the original MVP design and [CONVENTIONS.md](docs/CONVENTIONS.md) before contributing. The [setup notes](docs/SETUP.md) explain where these exports differ from the original plan.
