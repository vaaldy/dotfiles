---
name: jira
description: Jira queries and operations through the Jira MCP server. Use for every Jira task. Unless the user explicitly requests another person or everyone, default the person or assignee to "Valdy Lionel Christian".
---

# Jira

Use the `jira` MCP server for Jira queries and operations.

Unless the user explicitly requests another person or everyone, scope person/assignee queries to **Valdy Lionel Christian**. Resolve the corresponding Jira account ID when the tool requires one.

## Fast ticket lookup and classification

- If a key is known, fetch that issue directly rather than searching JQL.
- For candidate discovery, use a narrow indexed JQL scope (project and issue type; status when relevant). Request only keys, summary, status, and components initially. Avoid broad `text ~` and descriptions in the first pass.
- For multiple candidates, paginate once with `nextPageToken` in `mcpScript`; filter and map the results in JavaScript, and emit only a small shortlist. Fetch full descriptions only for the shortlisted keys.
- For epic/component classification, include a "none fits" option; send only the task-relevant shortlist and concise scope summaries to Jev. Verify the chosen issue's current Jira status and scope before recommending a parent. Jev's probabilities are advisory; never create or edit an issue on classification alone.
- For repeated BA epic/ticket lookups, check `python3 ~/.pi/agent/scripts/jira-index.py status` first. If it has been synced recently, shortlist with `python3 ~/.pi/agent/scripts/jira-index.py search --type Epic <keywords>` (or omit `--type` for tickets); use component filtering if useful. Send only shortlisted keys and scope summaries to Jev, including "none fits". Fetch the winning issue from Jira MCP before recommending or changing its parent. The cache is advisory and can be stale.
- The private SQLite index lives at `~/.pi/agent/cache/jira-index.sqlite3`, outside Git. Populate/refresh it with `python3 ~/.pi/agent/scripts/jira-index.py sync` (`--full` for deletion reconciliation). Its helper reads `JIRA_CLOUD_ID` from `~/.pi/agent/.env` and calls the authenticated Jira MCP server using pi-mcp-adapter's URL-bound OAuth store; no API token is needed. Keep `.env` local and untracked. If status has no `synced_at`, do not treat search results as complete. `mcpScript` in-memory results are not a durable cache.
