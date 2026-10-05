#!/usr/bin/env python3
"""Private, read-only Jira issue index, populated through authenticated Jira MCP."""

import argparse
from datetime import datetime, timedelta, timezone
import json
import os
from pathlib import Path
import sqlite3
import subprocess
DB = Path.home() / ".pi/agent/cache/jira-index.sqlite3"
FIELDS = "summary,issuetype,status,components,parent,updated"


def connect(path=DB):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(path.parent, 0o700)
    db = sqlite3.connect(path)
    os.chmod(path, 0o600)
    db.executescript("""
        CREATE TABLE IF NOT EXISTS issues (
            key TEXT PRIMARY KEY, project TEXT NOT NULL, summary TEXT NOT NULL,
            type TEXT NOT NULL, status TEXT NOT NULL, components TEXT NOT NULL,
            parent TEXT, updated TEXT, description TEXT, seen TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS meta (project TEXT PRIMARY KEY, synced_at TEXT NOT NULL);
    """)
    return db


def plain_text(value):
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return " ".join(filter(None, (plain_text(item) for item in value)))
    if isinstance(value, dict):
        return " ".join(filter(None, (plain_text(value.get(k)) for k in ("text", "content"))))
    return ""


def mcp_pages(jql, fields):
    agent_dir = Path.home() / ".pi/agent"
    result = subprocess.run(["node", "--import", "tsx",
                             str(Path(__file__).resolve().with_name("jira-mcp-pages.mjs")), jql, fields],
                            cwd=agent_dir / "npm", capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def sync(db, project, fetch, now, full=False):
    row = db.execute("SELECT synced_at FROM meta WHERE project=?", (project,)).fetchone()
    full = full or row is None
    # The previous day's overlap covers timezone differences and Jira search-index lag.
    cutoff = (datetime.fromisoformat(row[0]) - timedelta(days=1)).date() if not full else None
    scope = f'project = "{project}"' + (f' AND updated >= "{cutoff}"' if cutoff else "")
    seen = now.isoformat()
    count = 0
    # Fetch everything before writing; an API failure must not advance the cursor or prune rows.
    issue_pages = list(fetch(scope + " ORDER BY updated ASC", FIELDS))
    epic_pages = list(fetch(scope + " AND issuetype = Epic ORDER BY updated ASC", "description"))
    with db:
        for page in issue_pages:
            for issue in page:
                f = issue["fields"]
                db.execute("""INSERT INTO issues VALUES (?,?,?,?,?,?,?,?,?,?)
                    ON CONFLICT(key) DO UPDATE SET project=excluded.project, summary=excluded.summary,
                    type=excluded.type, status=excluded.status, components=excluded.components,
                    parent=excluded.parent, updated=excluded.updated, seen=excluded.seen""",
                    (issue["key"], project, f.get("summary") or "", f.get("issuetype", {}).get("name") or "",
                     f.get("status", {}).get("name") or "",
                     json.dumps([c["name"] for c in f.get("components") or []]),
                     (f.get("parent") or {}).get("key"), f.get("updated"), None, seen))
                count += 1
        for page in epic_pages:
            for issue in page:
                db.execute("UPDATE issues SET description=? WHERE key=?",
                           (plain_text(issue["fields"].get("description"))[:3000], issue["key"]))
        if full:
            db.execute("DELETE FROM issues WHERE project=? AND seen != ?", (project, seen))
        db.execute("INSERT INTO meta VALUES (?,?) ON CONFLICT(project) DO UPDATE SET synced_at=excluded.synced_at",
                   (project, seen))
    return count


def search(db, project, kind, terms, component, limit):
    sql = "SELECT key,summary,type,status,components,parent,description,updated FROM issues WHERE project=?"
    args = [project]
    if kind:
        sql += " AND type=?"
        args.append(kind)
    if component:
        sql += " AND lower(components) LIKE ?"
        args.append("%" + component.lower() + "%")
    for term in terms.split():
        sql += " AND lower(key || ' ' || summary || ' ' || coalesce(description,'')) LIKE ?"
        args.append("%" + term.lower() + "%")
    sql += " ORDER BY updated DESC LIMIT ?"
    args.append(limit)
    return [dict(key=key, summary=summary, type=kind, status=status,
                 components=json.loads(components), parent=parent, description=(description or "")[:600],
                 updated=updated) for key, summary, kind, status, components, parent, description, updated
            in db.execute(sql, args)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default="BA")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("sync").add_argument("--full", action="store_true")
    find = commands.add_parser("search")
    find.add_argument("terms", nargs="*", help="Words to match in summary or epic description")
    find.add_argument("--type", dest="kind")
    find.add_argument("--component")
    find.add_argument("--limit", type=int, default=15)
    commands.add_parser("status")
    args = parser.parse_args()
    if not args.project.replace("-", "").isalnum():
        parser.error("project key must be alphanumeric or hyphens")
    db = connect()
    if args.command == "sync":
        now = datetime.now(timezone.utc)
        count = sync(db, args.project, mcp_pages, now, args.full)
        print(json.dumps({"project": args.project, "fetched": count, "synced_at": now.isoformat()}))
    elif args.command == "search":
        if not 1 <= args.limit <= 50:
            parser.error("--limit must be between 1 and 50")
        print(json.dumps(search(db, args.project, args.kind, " ".join(args.terms),
                                args.component, args.limit), ensure_ascii=False))
    else:
        row = db.execute("SELECT synced_at FROM meta WHERE project=?", (args.project,)).fetchone()
        count = db.execute("SELECT count(*) FROM issues WHERE project=?", (args.project,)).fetchone()[0]
        print(json.dumps({"project": args.project, "issues": count,
                          "synced_at": row[0] if row else None}))


if __name__ == "__main__":
    main()
