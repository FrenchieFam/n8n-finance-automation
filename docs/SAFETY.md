> Export review: the bundled OCR workflow already contains a Code node. Review it under the approval rule below before running. Discord reports transmit financial summaries externally; omit them for fully local operation. See [SETUP.md](SETUP.md).

# Safety and privacy

## Absolute rules
- No bank usernames, passwords, or API keys - ever.
- No real financial data in this repo. Mock data only.
- Never commit `.sqlite`, `.env`, or exported credential files.
- No Execute Command nodes.
- No Code nodes without explicit approval.
- No cloud services in the MVP.

## Before running any workflow
1. Read every node's parameters.
2. Confirm no node writes outside the project data folder.
3. Confirm no node sends data to an external host.
4. Run once manually with mock data.
5. Ask the user before any change that deletes or overwrites data.

## SQLite location
The DB file must not live in a cloud-synced folder (OneDrive, Dropbox, Google Drive).
Sync tools can corrupt SQLite files. Use something like `C:\budget-data\budget.sqlite`.

## Untrusted templates
Templates from public repos are untrusted input. Audit them; do not import and activate.