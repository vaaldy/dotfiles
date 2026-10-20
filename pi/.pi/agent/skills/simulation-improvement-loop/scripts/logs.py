#!/usr/bin/env python3
"""Log helper for the simulation-improvement-loop skill.

Stdlib only. One JSONL log per phase, all of them under `<run-dir>/logs/`, plus a generated
`index.md` that states, per log, whether it failed or succeeded and why.

    init <run-dir> --goal <goal.md>     record the goal contract hash, create logs/, phases/
    append <run-dir> --file <json>      append one event (or --stdin); routes by phase
    verify <run-dir>                    re-hash every referenced artifact; exit 1 on drift
    index <run-dir> [--all]             write index.md: one line per log — failed/success + reason
    status <run-dir>                    counts across logs, open logs, budget usage
    selftest                            end-to-end smoke test in a temporary directory

Run directory:

    runs/<goal-id>/
    ├── run.json                 goal id, contract hash, phase -> log mapping
    ├── index.md                 generated index over logs/ (never hand-edited)
    ├── logs/log-01-p1-quick.jsonl
    ├── logs/log-02-p2-sou.jsonl
    └── phases/<phase-id>/       briefs, reports, reviews, artifacts

Artifact paths in a log are resolved against the project root (the run directory's
grandparent), or used as-is when absolute.

Logs hold structured facts only: event, phase, models, commands, metrics, artifacts with
hashes, codebase identity, deps, verdict, plus one optional curated `supervisor_note`.
Monologue, hedges and plan-talk are refused; reasoning belongs in the phase's report files
or a quarantined `journal.md`.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import re
import sys
import tempfile

VERDICTS = (
    "COMMIT-CORRECT",
    "COMMIT-IMPROVED",
    "REJECT-NONSENSE",
    "REJECT-DEFECT",
    "BLOCK-PREMISE",
)
COMMITTING = ("COMMIT-CORRECT", "COMMIT-IMPROVED")

# Structured facts only. Logs are read by scripts and by the next session, so prose,
# reasoning and narration are refused or warned about rather than stored.
LOG_FIELDS = {
    "ts", "event", "goal", "goal_sha256", "phase", "mode", "lane", "hypothesis",
    "premise", "models", "runs", "commands", "metrics", "artifacts", "codebase", "deps",
    "env", "verdict", "verdict_reason", "commit", "notes", "supervisor_note",
}
# `notes` is the machine-fact field; `supervisor_note` is the one human-readable line that
# `index` prints. Both are curated and factual, so both are screened.
PROSE_LIMITS = {"hypothesis": 300, "notes": 400, "verdict_reason": 400,
                "supervisor_note": 600}
PROSE_FIELDS = tuple(PROSE_LIMITS)
NARRATION_MARKERS = (
    "hmm", "i'll", "i will ", "i think", "i guess", "i'm going to", "im going to",
    "let me ", "let's try", "lets try", "maybe i", "hopefully", "seems like",
    "should be correct", "not commit yet", "not ready to commit", "just to see",
)


def narrates(value: str) -> str | None:
    lowered = value.lower()
    return next((marker for marker in NARRATION_MARKERS if marker in lowered), None)


def utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def slug(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "-", str(value).lower()).strip("-")
    return cleaned or "log"


def logs_dir(run_dir: Path) -> Path:
    return run_dir / "logs"


def state_path(run_dir: Path) -> Path:
    return run_dir / "run.json"


def load_state(run_dir: Path) -> dict:
    path = state_path(run_dir)
    if not path.is_file():
        raise SystemExit(f"no run.json in {run_dir}; run 'init' first")
    return json.loads(path.read_text())


def save_state(run_dir: Path, state: dict) -> None:
    with tempfile.NamedTemporaryFile(mode="w", dir=run_dir, delete=False) as stream:
        temporary = Path(stream.name)
        json.dump(state, stream, indent=2, sort_keys=True)
        stream.write("\n")
    temporary.replace(state_path(run_dir))


def log_files(run_dir: Path) -> list[Path]:
    directory = logs_dir(run_dir)
    if not directory.is_dir():
        raise SystemExit(f"no logs/ in {run_dir}; run 'init' first")
    return sorted(directory.glob("log-*.jsonl"), key=lambda path: path.name)


def read_log(path: Path) -> list[dict]:
    events: list[dict] = []
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError as error:
            raise SystemExit(f"{path}:{number}: invalid JSON: {error}") from error
        if not isinstance(entry, dict):
            raise SystemExit(f"{path}:{number}: entry must be a JSON object")
        events.append(entry)
    return events


def read_events(run_dir: Path) -> list[dict]:
    events: list[dict] = []
    for path in log_files(run_dir):
        events.extend(read_log(path))
    return events


def project_root(run_dir: Path) -> Path:
    return run_dir.resolve().parent.parent


def resolve(run_dir: Path, value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else project_root(run_dir) / path


def log_for_phase(run_dir: Path, phase: str) -> Path:
    """The log file for a phase, allocating the next sequence number on first use."""
    state = load_state(run_dir)
    known = state.setdefault("logs", {})
    if phase in known:
        return logs_dir(run_dir) / f"{known[phase]}.jsonl"
    used = [int(match.group(1)) for path in log_files(run_dir)
            if (match := re.match(r"log-(\d+)", path.name))]
    number = max(used, default=0) + 1
    log_id = f"log-{number:02d}-{slug(phase)}"
    known[phase] = log_id
    save_state(run_dir, state)
    return logs_dir(run_dir) / f"{log_id}.jsonl"


def append_entry(run_dir: Path, entry: dict) -> dict:
    if not isinstance(entry, dict) or not entry.get("event"):
        raise SystemExit("log entry must be an object with an 'event' field")
    for field in PROSE_FIELDS:
        value = entry.get(field)
        if not isinstance(value, str):
            continue
        marker = narrates(value)
        if marker:
            raise SystemExit(
                f"{field} narrates ({marker!r}): the log stores facts and decisions, not the "
                "agent's monologue. Keep the command, the numbers and the verdict, and state "
                "a supervisor_note as a decision record (judgement + basis) rather than a "
                "plan or a hedge; put the rest in the phase report or a quarantined "
                "journal.md."
            )
        limit = PROSE_LIMITS[field]
        if len(value) > limit:
            raise SystemExit(
                f"{field} is {len(value)} chars, limit {limit}: the log stores facts, not "
                "narration. Record the command, the numbers and the verdict; put the "
                "reasoning in the phase report or a quarantined journal.md."
            )
    unknown = sorted(set(entry) - LOG_FIELDS)
    if unknown:
        print(f"warning: unknown log field(s): {', '.join(unknown)}; log entries are "
              "structured facts, not commentary", file=sys.stderr)
    entry = {"ts": utc(), **entry}
    path = log_for_phase(run_dir, str(entry.get("phase") or "goal"))
    with path.open("a") as stream:
        stream.write(json.dumps(entry, sort_keys=False) + "\n")
    return {**entry, "log": path.name}


def log_status(events: list[dict]) -> tuple[str, str, str, str]:
    """(status, reason, verdict, commit) for one log."""
    verdict = commit = reason = ""
    for entry in events:
        if entry.get("verdict"):
            verdict = str(entry["verdict"])
            reason = str(entry.get("verdict_reason") or entry.get("supervisor_note") or "")
        if entry.get("commit"):
            commit = str(entry["commit"])
        if entry.get("event") == "lane_failed" and not verdict:
            reason = str(entry.get("notes") or entry.get("supervisor_note") or "lane failure")
            verdict = "LANE-FAILED"
        if entry.get("event") == "premise_blocked" and not verdict:
            verdict = "BLOCK-PREMISE"
            reason = str(entry.get("verdict_reason") or entry.get("notes") or "premise blocked")
    if not verdict and events and all(str(entry.get("event", "")).startswith("goal")
                                      for entry in events):
        return "goal", "", "", ""
    if verdict in COMMITTING:
        status = "success"
    elif verdict in ("REJECT-NONSENSE", "REJECT-DEFECT", "LANE-FAILED"):
        status = "failed"
    elif verdict == "BLOCK-PREMISE":
        status = "blocked"
    else:
        status = "open"
    return status, reason, verdict, commit


def cmd_init(args: argparse.Namespace) -> int:
    run_dir = Path(args.run_dir)
    if state_path(run_dir).exists():
        raise SystemExit(f"run already initialized at {state_path(run_dir)}")
    goal = Path(args.goal)
    if not goal.is_file():
        raise SystemExit(f"goal contract not found: {goal}")
    run_dir.mkdir(parents=True, exist_ok=True)
    logs_dir(run_dir).mkdir(exist_ok=True)
    (run_dir / "phases").mkdir(exist_ok=True)
    (run_dir / "review").mkdir(exist_ok=True)
    state = {
        "version": 2,
        "goal_id": run_dir.resolve().name,
        "created": utc(),
        "goal_path": str(goal),
        "goal_sha256": digest(goal),
        "logs": {},
    }
    save_state(run_dir, state)
    append_entry(run_dir, {"event": "goal_opened", "goal": state["goal_id"],
                           "goal_sha256": state["goal_sha256"]})
    print(json.dumps(load_state(run_dir), indent=2))
    return 0


def cmd_append(args: argparse.Namespace) -> int:
    raw = sys.stdin.read() if args.stdin else Path(args.file).read_text()
    try:
        entry = json.loads(raw)
    except json.JSONDecodeError as error:
        raise SystemExit(f"input is not valid JSON: {error}") from error
    if args.phase and not entry.get("phase"):
        entry["phase"] = args.phase
    print(json.dumps(append_entry(Path(args.run_dir), entry), indent=2))
    return 0


def cmd_verify(args: argparse.Namespace) -> int:
    run_dir = Path(args.run_dir)
    checked = missing = drifted = 0
    for path in log_files(run_dir):
        for index, entry in enumerate(read_log(path), 1):
            for artifact in entry.get("artifacts") or []:
                if not isinstance(artifact, dict) or not artifact.get("path"):
                    print(f"{path.name}:{index}: malformed artifact entry")
                    drifted += 1
                    continue
                target = resolve(run_dir, str(artifact["path"]))
                expected = artifact.get("sha256")
                if not target.is_file():
                    print(f"{path.name}:{index}: missing artifact {artifact['path']}")
                    missing += 1
                    continue
                actual = digest(target)
                checked += 1
                if expected and actual != expected:
                    print(f"{path.name}:{index}: hash drift {artifact['path']}")
                    print(f"  recorded {expected}")
                    print(f"  actual   {actual}")
                    drifted += 1
    print(f"verified {checked} artifacts, {missing} missing, {drifted} problems")
    return 1 if missing or drifted else 0


def cmd_index(args: argparse.Namespace) -> int:
    run_dir = Path(args.run_dir)
    if args.all:
        root = run_dir.resolve().parent
        rows = []
        for child in sorted(root.iterdir()):
            if not state_path(child).is_file() or not logs_dir(child).is_dir():
                continue
            state = load_state(child)
            counts = {"success": 0, "failed": 0, "blocked": 0, "open": 0, "goal": 0}
            for path in log_files(child):
                status, *_ = log_status(read_log(path))
                counts[status] += 1
            rows.append((state.get("goal_id", child.name), state.get("created", ""),
                         counts, f"{child.name}/index.md"))
        lines = ["# Runs index", "",
                 f"Generated {utc()}. Regenerate with `scripts/logs.py index <run-dir> --all`."
                 " Do not hand-edit.", "",
                 "| goal | created | logs | success | failed | blocked | open | goal log | index |",
                 "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
        for goal_id, created, counts, link in rows:
            total = sum(counts.values())
            lines.append(f"| {goal_id} | {created} | {total} | {counts['success']} | "
                         f"{counts['failed']} | {counts['blocked']} | {counts['open']} | "
                         f"{counts['goal']} | [{goal_id}]({link}) |")
        text = "\n".join(lines) + "\n"
        (root / "index.md").write_text(text)
        print(text)
        return 0

    state = load_state(run_dir)
    goal_id = state.get("goal_id", run_dir.name)
    counts = {"success": 0, "failed": 0, "blocked": 0, "open": 0, "goal": 0}
    lines = [f"# Log index: {goal_id}", "",
             f"Generated {utc()} from `logs/`. Regenerate with `scripts/logs.py index "
             "<run-dir>`. Do not hand-edit.", "",
             "One line per log: what ran, whether it landed, and why.", ""]
    entries = []
    for path in log_files(run_dir):
        events = read_log(path)
        status, reason, verdict, commit = log_status(events)
        counts[status] += 1
        phase = next((str(event["phase"]) for event in events if event.get("phase")), "goal")
        hypothesis = next((str(event["hypothesis"]) for event in events
                           if event.get("hypothesis")), "")
        note = next((str(event["supervisor_note"]) for event in reversed(events)
                     if event.get("supervisor_note")), "")
        entries.append((path, status, reason, verdict, commit, phase, hypothesis, note))
    for path, status, reason, verdict, commit, phase, hypothesis, note in entries:
        label = {"success": "SUCCESS", "failed": "FAILED", "blocked": "BLOCKED",
                 "open": "OPEN", "goal": "GOAL"}[status]
        lead = f"- **{path.stem}**"
        if phase != "goal":
            lead += f" `{phase}`"
        lead += f" — **{label}**"
        if reason:
            lead += f": {reason}"
        links = [f"[log](logs/{path.name})"]
        phase_dir = run_dir / "phases" / phase
        if (phase_dir / "review.md").is_file():
            links.append(f"[review](phases/{phase}/review.md)")
        if (phase_dir / "artifacts").is_dir():
            links.append(f"[artifacts](phases/{phase}/artifacts/)")
        lead += f" · commit `{commit[:12] or '—'}` · " + " · ".join(links)
        if hypothesis:
            lead += f"\n  - hypothesis: {hypothesis}"
        if note:
            lead += f"\n  - note: {note}"
        lines.append(lead)
    if not entries:
        lines.append("_no logs yet_")
    lines += ["", f"logs {sum(counts.values())} · success {counts['success']} · "
                  f"failed {counts['failed']} · blocked {counts['blocked']} · "
                  f"open {counts['open']} · goal record {counts['goal']}"]
    text = "\n".join(lines) + "\n"
    (run_dir / "index.md").write_text(text)
    print(text)
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    run_dir = Path(args.run_dir)
    print(f"run:    {run_dir.resolve()}")
    total = 0
    counts = {"success": 0, "failed": 0, "blocked": 0, "open": 0, "goal": 0}
    for path in log_files(run_dir):
        status, reason, verdict, commit = log_status(read_log(path))
        counts[status] += 1
        total += 1
        print(f"  {path.stem:<28} {status:<8} {verdict or 'pending'}")
    print(f"logs:   {total} · success {counts['success']} · failed {counts['failed']} · "
          f"blocked {counts['blocked']} · open {counts['open']} · goal record {counts['goal']}")
    return 0


def cmd_selftest(args: argparse.Namespace) -> int:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        run_dir = root / "runs" / "selftest-goal"
        goal = root / "goal.md"
        goal.write_text("# goal contract\n")
        artifact = run_dir / "phases" / "P1-quick" / "artifacts" / "compare.png"
        artifact.parent.mkdir(parents=True)
        artifact.write_bytes(b"fake-png")
        cmd_init(argparse.Namespace(run_dir=str(run_dir), goal=str(goal)))
        relative = artifact.relative_to(root).as_posix()
        rejected = run_dir / "phases" / "P2-sou" / "review.md"
        rejected.parent.mkdir(parents=True)
        rejected.write_text("verdict: DEFECTIVE\n")
        for entry in (
            {"event": "phase_started", "phase": "P1-quick", "mode": "sequential",
             "hypothesis": "QUICK scheme"},
            {"event": "implemented", "phase": "P1-quick",
             "models": {"implement": "m-frontier"}, "commit": "a" * 40},
            {"event": "verdict", "phase": "P1-quick", "verdict": "COMMIT-CORRECT",
             "verdict_reason": "valid scheme, checks pass",
             "supervisor_note": "Kept although case-a accuracy is 1.9 percent worse: the "
                                "scheme is physically valid and the repo checks pass.",
             "artifacts": [{"path": relative, "sha256": digest(artifact), "kind": "human"}]},
            {"event": "phase_started", "phase": "P2-sou", "hypothesis": "SOU upwinding"},
            {"event": "verdict", "phase": "P2-sou", "verdict": "REJECT-DEFECT",
             "verdict_reason": "regresses the frozen case-b baseline"},
        ):
            append_entry(run_dir, entry)
        assert cmd_verify(argparse.Namespace(run_dir=str(run_dir))) == 0, "verify must pass"
        assert len(log_files(run_dir)) == 3, "one log per phase plus the goal log"
        cmd_index(argparse.Namespace(run_dir=str(run_dir), all=False))
        index_text = (run_dir / "index.md").read_text()
        assert "SUCCESS" in index_text and "valid scheme, checks pass" in index_text
        assert "FAILED" in index_text and "regresses the frozen case-b baseline" in index_text
        assert "logs/log-02-p1-quick.jsonl" in index_text, "index must link the log file"
        assert "phases/P1-quick/review.md" not in index_text, "only real files are linked"
        assert "phases/P2-sou/review.md" in index_text, "review link for a real file"
        cmd_index(argparse.Namespace(run_dir=str(run_dir), all=True))
        assert "Runs index" in (root / "runs" / "index.md").read_text(), "cross-run index"
        cmd_status(argparse.Namespace(run_dir=str(run_dir)))
        try:
            append_entry(run_dir, {"event": "implemented", "phase": "P3-hds",
                                   "supervisor_note": "hmmm this should be correct, not "
                                                      "commit yet, maybe i retry"})
        except SystemExit as error:
            assert "narrates" in str(error), "guard must report narration"
        else:
            raise AssertionError("narrative supervisor_note must be refused")
        try:
            append_entry(run_dir, {"event": "implemented", "phase": "P3-hds",
                                   "notes": "x" * 401})
        except SystemExit:
            pass
        else:
            raise AssertionError("over-long notes must be refused")
        artifact.write_bytes(b"tampered")
        assert cmd_verify(argparse.Namespace(run_dir=str(run_dir))) == 1, "drift must be caught"
    print("selftest: ok")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    init = commands.add_parser("init")
    init.add_argument("run_dir")
    init.add_argument("--goal", required=True)
    init.set_defaults(func=cmd_init)
    append = commands.add_parser("append")
    append.add_argument("run_dir")
    append.add_argument("--phase", help="route the entry to this phase's log")
    source = append.add_mutually_exclusive_group(required=True)
    source.add_argument("--file")
    source.add_argument("--stdin", action="store_true")
    append.set_defaults(func=cmd_append)
    for name, function in (("verify", cmd_verify), ("status", cmd_status)):
        command = commands.add_parser(name)
        command.add_argument("run_dir")
        command.set_defaults(func=function)
    index = commands.add_parser("index")
    index.add_argument("run_dir")
    index.add_argument("--all", action="store_true",
                       help="index every run under the same runs/ directory")
    index.set_defaults(func=cmd_index)
    selftest = commands.add_parser("selftest")
    selftest.set_defaults(func=cmd_selftest)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
