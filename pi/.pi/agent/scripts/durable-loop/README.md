# Durable phase workflow

Run an approved, bounded plan with SQLite checkpoints and detached workers. The same command resumes an interrupted run. This is a command orchestrator, not an autonomous agent that invents tasks or a replacement for the parent agent.

Requires Node 26.7 or later on macOS or Linux, `/bin/sh`, and a local filesystem. Install once in this directory:

```sh
npm install --ignore-scripts --no-audit --no-fund
npm test
node runner.mjs run /absolute/path/to/run /absolute/path/to/plan.json
```

Dependencies are pinned in `package.json`. The SQLite file, inputs, logs, process identities and receipts stay in the run directory, outside shared dotfiles. Choose a private run location: command output may contain private data. Keep the supervisor under a service manager or terminal session for unattended operation; detached workers survive supervisor termination, but the scheduler resumes only when the command runs again. No cloud service or model credentials are needed by the runner itself.

## Plan and commands

The parent defines the exact goal, exclusions, acceptance criteria, command budgets, repository ownership, dependency versions and stop conditions before execution. Prepare and inspect scripts first. Do not use a vague prompt as a phase implementation command. A phase needs a falsifiable hypothesis, an actual validation command, a negative control that proves the validator rejects a known defect, and an independent review command. Successful commands must return zero; a negative control returns zero only after confirming that the intentionally invalid case was rejected.

```json
{
  "goal": "Implement and verify the approved change",
  "maxWallSeconds": 14400,
  "maxPhases": 3,
  "concurrency": 2,
  "phases": [
    {
      "id": "p1",
      "cwd": "/absolute/path/to/worktree",
      "timeoutSeconds": 1800,
      "hypothesis": "The proposed mechanism satisfies the stated contract",
      "falsificationCriterion": "Any contract assertion or negative control fails",
      "implement": "./scripts/implement-approved-change.sh",
      "validate": "./scripts/test-contract.sh",
      "negativeControl": "./scripts/test-validator-rejects-defect.sh",
      "review": "./scripts/independent-review.sh",
      "artifacts": ["evidence/test-results.json", "evidence/review.json"]
    }
  ]
}
```

Commands are trusted shell code, with the caller's environment and full filesystem authority. This is not a sandbox. Commands must stay in the authorized scope, terminate their child processes, and produce truthful machine-readable evidence. They receive `DURABLE_PHASE_DIR` and `DURABLE_PHASE_ID`. Review scripts must block on the actual review result and fail on unresolved required findings, rather than treating a successful agent launch as a successful review. Store source revision/diff hashes, test commands, results and the review verdict in the declared artifacts. The runner checks exits and hashes; it cannot judge whether an assertion is meaningful, an agent is independent, or a scientific premise is correct. The parent remains responsible for those judgments and the final integration gate. No automatic commits, pushes, model fallback, or retries are performed.

## Sequential and parallel phases

Omit `dependsOn` for the default chain: `p1 -> p2 -> p3`. Declare `"dependsOn": []` to make a phase independent, or `"dependsOn": ["p1"]` to require a predecessor. Forward references work; missing dependencies and cycles are rejected. `concurrency` defaults to one and is capped at three.

Only ready phases are admitted. Ready phases run concurrently when their canonical working directories do not overlap. A phase starts as soon as its dependencies pass and a slot is free, without waiting for unrelated lanes. Failure stops new admissions while already-running lanes settle. A failed phase does not become a success when rerun; corrections belong in a new plan/run with preserved failure evidence.

Use a separate worktree for each writer. Canonical-path overlap checks cover only this run, not other agents, other run directories, shared databases, ports, Docker volumes or services. Before launching, the parent reserves those resources and coordinates with their owning agents. Across a stack, request changes from each repository owner using an exact interface contract, reproducer, expected artifact, and dependency/version gate. Wait for the owner's verified revision or published artifact, pin its identity, then run consumer and end-to-end tests. A library test alone does not prove application integration. Keep integration as a final phase depending on every required lane.

## Recovery and evidence

The durable task progresses through `prepare -> launch -> monitor -> gate`. The launch intent is persisted before spawning. The worker takes an exclusive claim before running commands; a launch marker is never automatically cleared. SQLite is the authoritative completion ledger. A receipt must be written and hash-verified before the completion transaction. Missing exits, nonzero exits, signals, missing artifacts, invalid input identity and failed receipt writes cannot produce success.

Each phase directory retains:

- `input.json`: sealed plan identity, phase, token and absolute deadline.
- `launch.json`, `claim.json`, and `<stage>.process.json`: launch intent and worker/command identities.
- `<stage>.log`, `worker.log`, `exit.json`: output and actual stage exit evidence.
- `receipt.json`: verdict, input/exit/log/process hashes and artifact hashes, linked from SQLite.

The original absolute deadline survives restarts. The run budget is calendar elapsed time, including downtime, not active compute time. Timeout kills the current command's process group; independently detached containers, remote jobs and daemonized grandchildren require command-specific cleanup. On a killed worker, commands may remain live: inspect recorded process identities and external jobs before any manual cleanup. PID liveness alone is not proof of process identity, and the runner never kills a recorded PID during recovery.

After a supervisor crash, the exclusive lock remains. First confirm the old supervisor ended, then:

```sh
node runner.mjs unlock /absolute/path/to/run
node runner.mjs run /absolute/path/to/run /absolute/path/to/plan.json
```

`unlock` refuses live or malformed lock owners. It removes only the supervisor lock, not workers or phase markers. PID reuse may conservatively require manual investigation. Do not remove a lock to work around a live owner.

If interruption occurred between launch intent and worker creation, or a worker died without an exit, the runner fails closed instead of replaying a command whose effects are uncertain. This is not an exactly-once external execution guarantee. Reconcile the effects, preserve the failed run, and authorize a new run only when safe. Do not edit receipts or clear phase markers to force advancement. Completed phase evidence is checked again on resume; later edits to declared artifacts invalidate it. Keep artifacts phase-specific and immutable; write corrections as supplements in a new phase/run.

SQLite's WAL checkpoints survive ordinary process crashes. This runner does not promise survival of host power loss, filesystem corruption, arbitrary child-process crashes, or uninterrupted multi-hour operation. Recovery tests exercise short synthetic commands; long real workloads still need task-specific smoke tests and monitoring. Quality comes from meaningful checks, independent review, and evidence-based parent decisions, not from elapsed runtime or the durable library alone.
