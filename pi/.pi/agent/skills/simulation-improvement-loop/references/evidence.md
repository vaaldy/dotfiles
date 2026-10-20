# Evidence, logs and reproducibility

The loop's memory is the run directory, not the context window. A fresh session must be able
to read `goal.md`, `index.md` and the tail of the relevant log and continue exactly where
the previous one stopped.

## Run directory

```
runs/<goal-id>/
├── goal.md                  # agreed contract: goal, phases, gates, bounds (see templates/goal.md)
├── faq.md                   # user questions + settled answers
├── index.md                 # generated: one line per log — failed or succeeded, and why
├── run.json                 # goal id, contract hash, phase -> log mapping
├── review/                  # cross-phase human-facing material (comparison sheets, tables)
├── logs/
│   ├── log-01-goal.jsonl          # goal-level entries (opened, amended, closed)
│   ├── log-02-p1-quick.jsonl      # one log per phase, append-only
│   └── log-03-p2-sou.jsonl
└── phases/<phase-id>/
    ├── brief.md             # the implementer brief actually sent
    ├── implementer-report.md  # compact factual report: changes, commands, results, artifacts
    ├── review.md            # the reviewer verdict
    ├── journal.md           # optional, quarantined: reasoning and dead ends, never evidence
    ├── commands.log         # exact commands + exit codes + durations
    ├── scripts/             # case-specific scripts written for this phase
    ├── logs/                # loguru/stdout/stderr, run logs
    └── artifacts/           # outputs a human will use, plus machine outputs
```

`logs/` is the machine record: one JSONL file per phase, routed automatically by the phase
id. `index.md` is the human record over those logs — it states, per log, whether the phase
failed or succeeded and why. Everything else in the phase directory is the working material
behind it.

Artifact kinds that belong in `artifacts/`: comparison images/renderings, plots, scorecards,
exported JSON for downstream tooling, patches, checkpoints/configs (identities, not huge
binaries in git), and measurement tables. Keep names stable and lane-qualified:
`P3-quick/artifacts/compare-baseline-vs-quick.png`.

## Log entries

Each `logs/log-NN-<phase>.jsonl` is append-only; never rewrite a line. One event per entry:

| event | written when |
| --- | --- |
| `goal_opened` | the contract is agreed (`goal.md` sha recorded) |
| `phase_started` | brief sent, lane/base recorded |
| `implemented` | implementer reported (commit sha, stats, artifacts) |
| `reviewed` | reviewer returned (verdict, findings, uncertainty) |
| `verdict` | supervisor gate decision with reason |
| `integrated` | merged into the integration branch, repo checks result |
| `rejected` | lane kept, reason recorded, no integration |
| `lane_failed` | infrastructure blocker with exact error and state |
| `premise_blocked` | premise invalid; loop paused for the user |
| `budget_reached` / `goal_closed` / `goal_amended` | stop and contract changes |

Common fields (omit only what genuinely does not apply; use `null` rather than inventing):

```json
{
  "ts": "2026-10-15T18:40:30Z",
  "event": "verdict",
  "goal": "cfd-schemes-v1",
  "phase": "P3-quick",
  "mode": "sequential",
  "lane": {"key": "P3-quick", "branch": "sim/cfd-schemes-v1/P3-quick", "worktree": "managed"},
  "hypothesis": "QUICK upwind-biased scheme, third-order on uniform grids, with a limiter for monotonicity",
  "premise": {"mechanism": "QUICK interpolation", "domain": "incompressible, Peclet < 2 cells", "reference": "<paper/spec>", "expected_effect": "accuracy ~ CD on smooth flow, better on upwind-biased transport"},
  "models": {"implement": "openai-codex/gpt-6.1-sol", "review": "opencode-go/deepseek-v4.1-flash"},
  "runs": {"implement_run": "<run-id>", "review_run": "<run-id>"},
  "commands": [{"cmd": "python -m pytest tests/schemes -q", "exit": 0, "duration_s": 41.2}],
  "metrics": {"frozen_cases": {"case-a": {"baseline": 0.031, "candidate": 0.033, "direction": "lower"}}},
  "artifacts": [{"path": "runs/.../artifacts/compare.png", "sha256": "…", "bytes": 48213, "kind": "human"}],
  "codebase": {"branch": "sim/cfd-schemes-v1/P3-quick", "commit": "…", "semver": "0.4.2", "dirty": false},
  "deps": {"lock": "poetry.lock", "sha256": "…", "python": "3.12.7"},
  "env": {"device": "cpu", "seeds": [11, 12, 13]},
  "verdict": "COMMIT-CORRECT",
  "verdict_reason": "valid scheme, all repo checks pass, no regression on frozen cases; accuracy 1.9% worse on case-a, kept by design",
  "commit": "<integration commit sha>",
  "notes": "reviewer flagged limiter behavior at high Peclet as untested; recorded as a follow-up phase candidate",
  "supervisor_note": "Kept although case-a accuracy is 1.9% worse: the scheme is valid, the repo checks pass, and the worse number is expected for this regime."
}
```

Rules:

- **No agent prose in the logs.** Every line is structured fact: event, phase, lane, model
  actually used, commands, metrics, artifacts with hashes, codebase and dependency identity,
  verdict. No reasoning, narration, hesitation or plan-talking. Only the supervisor appends
  to the logs.

  Rejected entry (never write this):

  ```text
  hmmm this cfd simulation failed, but like the physics equation SHOULD be correct, not
  commit yet. ill try to run a case where it converges with better initialization settings
  ```

  The same situation as facts:

  ```json
  {"event": "implemented", "phase": "P3-quick", "hypothesis": "QUICK interpolation, third-order on uniform grids, limiter for monotonicity",
   "commands": [{"cmd": "python run_case.py --case case-b --cfl 0.9", "exit": 3, "duration_s": 62.1}],
   "metrics": {"case-b": {"residual_final": 0.14, "converged": false}}}
  {"event": "verdict", "phase": "P3-quick", "verdict": "REJECT-DEFECT",
   "verdict_reason": "diverges above CFL 0.8 on case-b; nothing committable in this state"}
  {"event": "phase_started", "phase": "P3-quick-retry", "hypothesis": "same scheme with a bounded limiter and lower CFL"}
  ```

  What is preserved: the failed command, the number, the verdict and the next hypothesis —
  not the agent's monologue about them.
- **Where the thinking goes instead.** Speculation, half-formed hypotheses and dead ends
  belong to the subagent that owns them: its own transcript, which is already retained, and
  never the log, the index or the main context. If a lane's reasoning is worth keeping
  for debugging, write `phases/<phase-id>/journal.md` — explicitly quarantined: not
  evidence, not linked from `index.md`, never quoted into the main window, never the basis
  of a verdict.
- **The one sanctioned comment: `supervisor_note`.** The supervisor may attach a short,
  curated, human-readable line to any entry, and `index.md` prints it under the log's line so
  a human never has to read raw JSON. It is a decision record, not a diary: state the
  judgement and its basis, in the past or present tense, without first-person hedges,
  intentions or plans.

  ```text
  good  "Kept although case-a accuracy is 1.9% worse: valid scheme, repo checks pass, expected for this regime."
  good  "Retried at CFL 0.6; still diverges. Phase parked; limiter work queued as P3-retry."
  bad   "hmmm this should be correct, not commit yet, maybe i retry with better initialization"
  ```
- Two note fields, different readers: `notes` holds short machine-fact state a later phase
  must know; `supervisor_note` holds the human-facing line. `append` screens `hypothesis` /
  `notes` / `verdict_reason` / `supervisor_note` for length **and** for narration markers
  ("hmm", "i'll", "let me", "maybe i", "hopefully", "seems like", "should be correct",
  "not commit yet") and warns on unknown fields. Facts and judgements land; monologue goes to
  `journal.md`.
- Every claim in a log has the producing command, artifact or review attached. No bare
  "works" or "improved" entries.
- Hash every referenced artifact (sha256) at write time; logs are evidence, so their file
  references must be checkable later with `scripts/logs.py verify`.
- Record the **model actually used**, including one-off overrides and failures.
- Record the codebase identity (branch, commit, semver, dirty flag) for both the lane and
  the integration commit. Never record a result against a dirty or unknown tree.
- Record the environment that can change results: dependency lock hash, language/runtime
  version, device/GPU, seeds, case-set id/hash.
- Record the scaffold's own evidence once, at `goal_opened` or a dedicated scaffold entry:
  verification case-set hash, how the tolerances were derived, the measured noise floor, the
  negative control and its observed failure. A colleague must be able to audit the instrument,
  not just the experiments.
- A rejected phase is a first-class entry, not a gap.
- When the user changes the goal or a gate, append a `goal_amended` event with the sha of
  the previous and new `goal.md`. Never edit history to match a new decision.

## Reproducibility

State, in `goal.md`, the frozen case set, the metric and its direction, seeds, and the
checks that must pass. Freeze the case files by hash when the phase begins; if a case file
must change, that is a goal amendment followed by a re-baseline, and every affected phase
is re-judged or explicitly marked stale.

Retention: keep all phase directories, all lane branches, and rejected diffs. Model
weights, datasets and large binaries stay out of git — commit their identities (hashes,
config, provenance) and evidence summaries instead. Never delete or rewrite a failed run to
make the index look better, and never edit a log file or `index.md` by hand.

## scripts/logs.py

Stdlib-only helper (no dependencies), run from the skill directory:

```sh
python3 scripts/logs.py init runs/<goal-id> --goal templates/goal.md
python3 scripts/logs.py append runs/<goal-id> --file /tmp/event.json   # routes by "phase"
python3 scripts/logs.py append runs/<goal-id> --phase P3-quick --stdin
python3 scripts/logs.py verify runs/<goal-id>     # re-hash referenced artifacts; exit 1 on mismatch
python3 scripts/logs.py index runs/<goal-id>      # writes index.md: one line per log
python3 scripts/logs.py index runs/<goal-id> --all  # cross-run index at runs/index.md
python3 scripts/logs.py status runs/<goal-id>     # per-log status, counts, budget usage
python3 scripts/logs.py selftest                  # end-to-end smoke test in a temp dir
```

`init` records the goal contract hash, creates `logs/` and writes the goal log. `append`
adds `ts`, refuses monologue, and routes the entry into the log of the entry's `phase`
(allocating `log-NN-<phase>.jsonl` on first use, recorded in `run.json`). `verify` is the
integrity check to run before closing the goal or reporting to the user. `index` is
regenerated after every phase verdict, so the user never has to read a log to know what
happened.

## Human-readable layer

`index.md` is the human entry point and is **generated, never hand-written**: one line per
log in `logs/`, stating what ran, whether it landed, and why —

```text
- log-02-p1-quick `P1-quick` — SUCCESS: valid scheme, checks pass · commit 4acffb5 · [log] [artifacts]
  - hypothesis: QUICK scheme
  - note: Kept although case-a accuracy is 1.9 percent worse: the scheme is physically valid…
- log-03-p2-sou `P2-sou` — FAILED: regresses the frozen case-b baseline · [log] [review]
```

— with links to each log, its review and its artifacts. Regenerate it after every verdict,
and at the end of the goal. `index --all` writes `runs/index.md`, one row per goal, for a
quick scan of everything that was implemented or rejected.

Machine-readable is for the loop and for replay; human-readable is what the user actually
operates with. For every phase, produce at least one of: a comparison rendering against the
baseline, a table/plot of the frozen cases, or an export file ready for downstream tooling.
`review/` holds the cross-phase view (case-by-case matrix) that the user reads when deciding
the next goal.
