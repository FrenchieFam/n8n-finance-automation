> Public exports use generic credential names: `SQLite Database account` and `Discord Webhook account`. Select local credentials explicitly after import.

# Conventions

## JSON output
- Always output a complete workflow object with `name`, `nodes`, `connections`.
- Never output partial snippets or pseudocode.
- Node names: Title Case, descriptive, unique ("Get Due Bills").
- Positions: increment x by 220 per node, keep y at 300 unless branching.

## Nodes
- Prefer built-in `n8n-nodes-base.*` nodes.
- SQLite access only via `n8n-nodes-sqlite3`.
- All SQL must be parameterized; never string-concatenate user values.
- No Execute Command nodes.
- No Code nodes unless approved in writing.

## Expressions
- Reference nodes by name: `$('Node Name').item.json.field`.
- Never hardcode dates; use `$now` / `DateTime`.
- Guard against missing fields: `{{ $json.x ?? '' }}`.

## Naming
- Files: kebab-case, matching workflow name.
- Credentials: "SQLite Database account", "Bill Reminders", "Budget Reports".

## Verification
- Every generated JSON must pass `scripts/validate-workflow.ps1`.
- Every workflow must be imported inactive and run once manually.
