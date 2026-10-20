---
name: simulation-improvement-loop
description: Run a bounded, multi-phase implementation loop over a simulation, numerical, physics, or domain-engine codebase, supervised from the main context window. One implement subagent and one independent review subagent per phase (sequential, or parallel in isolated worktrees), a commit gate that keeps physically/semantically correct features even when accuracy does not improve and rejects metric-fitting nonsense, and a per-phase log with hashes of code, artifacts, commands and dependencies. Use when the user asks to implement or iterate N features, schemes, equations, models, or phases in such a codebase, asks for a phased or parallel implement-and-review loop, or asks for an autonomous improvement loop with commit gates and machine+human readable logs.
---

# Simulation improvement loop

A supervisor-driven loop that adds one domain-correct feature at a time to a robust
simulation codebase, and commits each phase that is *semantically right* even when its
numbers are not better.

```
goal + phase plan  →  [ phase: premise → implement → review → gate ]  ×N  →  goal closed
```

The supervisor is the main agent in the main context window. It holds **only correct
information**: the goal contract, verdicts, evidence paths, and landed commits. All
churn, exploration, failed reasoning and raw logs live in subagents and in the run
directory on disk. See `references/evidence.md` for the context contract.

## Do not start until these exist

1. **A bounded goal** with a finite phase list (N features/hypotheses) and an explicit
   stop condition: phase budget, lane budget, wall-clock or user handoff.
2. **A validated premise per phase.** Each phase names the mechanism it implements
   (scheme, equation, property, boundary treatment), its domain of validity, and a
   reference the reviewer can check against. Unvalidated premise → ask the user, do not
   invent. See `references/domain-gate.md`.
3. **Two independent verdicts per phase**: *semantic correctness* (the commit gate) and
   *accuracy/performance* (informational, never the commit gate on its own).
4. **The repository's own checks** that the feature must still pass on the integration
   branch (build/test/lint/smoke), so "it runs" is not a hand claim.
5. **A calibrated architectural scaffold — not just types.** Shape: units/dimensions in the
   type system, canonical interfaces and one registration path, required declarations
   (order, domain, stability, limiting behavior). Results: frozen golden cases, invariants,
   measured order of accuracy, and an analytic / manufactured / independent-implementation
   comparison. The scaffold must be *proven discriminating* by a negative control (a
   known-bad variant must fail), with derived tolerances and a measured noise floor — and no
   phase may edit or weaken the cases, tolerances or invariants that judge it. A frontier
   model builds this *before* the phases; it is the loop's only non-LLM ground truth.
   See `references/domain-gate.md`.
6. **A clean integration branch and a run directory** for the logs:
   `runs/<goal-id>/goal.md`, `runs/<goal-id>/logs/`, `runs/<goal-id>/index.md`,
   `runs/<goal-id>/phases/<phase-id>/`.

If any of these are missing, write them with the user first. The whole value of the loop
is that the phase plan and the gates were agreed *before* compute.

## Roles

| Role | Where | Owns |
| --- | --- | --- |
| Supervisor | main context | goal, phase order, gate verdicts, integration commits, user dialogue, context hygiene |
| Implementer | subagent, isolated lane | end-to-end feature: writes code, runs it, fixes its own bugs, reports honestly |
| Reviewer | subagent, fresh context | independent adversarial + domain review of the implementer's diff, no fixes by default |
| Oracle (optional) | subagent, read-only, escalation | root-cause only when ordinary review and evidence are insufficient |

Default routing: implement on the **frontier** tier; review on a **good flash** tier
(Gemini Argon flash, DeepSeek V4 flash, Qwen 3.8 flash); when the code is sensitive or
the phase is a core-engine change, review on the frontier tier at **low** thinking.
Top-reasoning tiers are escalation-only and read-only. Exact IDs, agent files and
per-call overrides: `references/roles.md`.

This skill authorizes subagent delegation for the implement and review phases, and for
the optional read-only oracle. Everything else — premise checks, verdicts, log writes,
merges, commits, and the final report — stays in the parent. One writer per worktree;
never run two implementers in the same checkout.

## Phase lifecycle

For phase `Pn` (one feature, one hypothesis, one lane):

1. **Premise check (parent, cheap).** State the mechanism, units/dimensions, limiting
   cases, expected effect direction, and "what would prove this wrong". Grep the codebase
   for the existing related implementation it must slot next to. If the phase premise
   cannot be stated this concretely, it is a `BLOCK-PREMISE`.
2. **Implement (subagent, frontier tier).** Cold-start brief from
   `templates/implement-brief.md`: objective, lane/cwd/ref, files in scope, the premise,
   acceptance criteria, required validation commands, required artifacts, report format,
   stop/ask conditions. The implementer runs the feature and fixes its own bugs.
3. **Review (subagent, flash tier, fresh context).** Independent brief from
   `templates/review-brief.md`: the diff, the premise, the boundary-case matrix, the
   repository's own checks, and the exact claims to verify. The reviewer must inspect
   source and re-run what it can rather than trust the implementer's summary.
4. **Gate (parent).** Choose exactly one verdict from the rules below, write the log
   entry, and only then move on.
5. **Integrate (parent).** On `COMMIT-*`, merge the lane commit into the integration
   branch, run the repository's own checks there, and record the integration commit sha.

Run phases sequentially by default. Use parallel lanes only when the phase features are
genuinely independent — different files, no shared contract — and then at most four lanes,
one worktree each. Mechanics: `references/orchestration.md`.

## Commit rules — correctness commits, accuracy informs

| Verdict | Condition | Action |
| --- | --- | --- |
| `COMMIT-CORRECT` | Feature is domain-correct, robust, runs the repository's checks, does not regress existing behavior or edge cases. **Accuracy may be worse** than the incumbent. | Integrate and commit. |
| `COMMIT-IMPROVED` | As above, and the measured accuracy/performance on the frozen cases also improves. | Integrate and commit. |
| `REJECT-NONSENSE` | The change only "works" by fitting the harness, metric, test, or a lucky parameter; units/dimensions, limiting cases, or the underlying mechanism are wrong. | Keep the log, do not integrate. |
| `REJECT-DEFECT` | The approach is right but the implementation is broken, incomplete, unverified, or regresses existing behavior. | Send back to the implementer once; repeat failure ends the phase as rejected. |
| `BLOCK-PREMISE` | The premise itself is invalid, contradicts the source, or cannot be stated. | Stop this phase and ask the user. |

Canonical example: adding QUICK/SOU/HDS/SMART next to the existing central-differencing
scheme. QUICK is less accurate than central differencing on some flows, but it is a real,
physically valid scheme with a defined order, limiter behavior and domain of validity —
so it commits. Canonical counterexample: implementing `q = m·ΔT` instead of
`q = m·c·ΔT` and tuning constants until a case passes. It may produce numbers, but it is
not a mechanism, so it is rejected and recorded.

A worse number is not a failure. An unjustifiable mechanism is. Do not loosen a gate,
re-scope a phase, or change the frozen cases to manufacture a commit; if a gate is wrong,
say so and get the change recorded in `goal.md` with the user.

## Context discipline

- The parent reads: `goal.md`, `templates/…`, the log tail, the implementer's compact
  report, the reviewer's verdict, `git diff --stat`, artifact paths and hashes.
- The parent never pastes subagent transcripts, dead ends, raw logs or speculative
  reasoning into its own context. Distill each phase to one verdict line plus evidence
  paths and write the raw material into the run directory.
- When the parent catches itself holding an unverified belief, it turns it into a review
  question instead of acting on it.
- Keep a `runs/<goal-id>/faq.md`: the user's questions with their settled answers. Answer
  repeat questions from it, not from re-derivation.
- **Speculation is not evidence.** "the equation should be right, let me try another case"
  is a next hypothesis, not a finding: it becomes a new `phase_started` entry, a review
  question, or a quarantined `journal.md` note — never a claim in the main context. The
  log holds what ran, what the numbers were, and what was decided; the supervisor may add
  one curated `supervisor_note` per entry, which `index.md` renders as prose for the user.
- Escalate to the user only for: an invalid premise, a contradiction between evidence and
  the goal, a scope/taste decision, a budget or safety limit, or a lane infrastructure
  failure that would need a protocol change.

## Evidence

Every phase writes human- and machine-readable material to
`runs/<goal-id>/phases/<phase-id>/`: the brief, the implementer report, the review,
the scripts written for this case, the commands run, logs, and the artifacts a human will
actually use (comparison render, plot, exported JSON, scorecard).

`runs/<goal-id>/logs/` holds one append-only JSONL log per phase and contains **no agent
prose** — event, phase, lane, model, commands, metrics, artifacts with sha256, codebase
commit + semver, dependency lock hash, environment, seeds, verdict, plus one optional
curated `supervisor_note` (the supervisor's decision record, and the only comment allowed in
a log). Reasoning and narration stay in the phase's report files. `index.md` is generated
from the logs after every verdict: one line per log saying what ran, whether it failed or
succeeded, and why, with links to the log, its review and its artifacts (`index --all` covers
every goal). `scripts/logs.py` handles init/append/verify/index/status. Schema and
retention rules: `references/evidence.md`.

Rejected runs are evidence. Keep them, keep their branches, and keep the diff — never
delete a lane or rewrite history to hide a failed phase.

## Stop conditions

Stop the loop, capture partial results and a diff, and report the exact blocker when: the
goal is closed and reviewed; the phase or wall-clock budget is exhausted; the user
interrupts; a premise is invalid; a lane or environment failure cannot be retried on the
same protocol; storage/GPU/time safety limits are reached; or the same phase fails twice
for the same reason. Do not silently extend the budget, silently change execution
protocol, or restart a rejected phase hoping for a different result.

## Anti-patterns this skill exists to prevent

- Writing agent narration into the log ("this failed but the equation should be correct,
  not commit yet, I'll retry with better initialization") instead of the facts: command,
  number, verdict, next hypothesis.
- Inventing an equation, unit, or mechanism to make a case pass.
- Committing because the metric improved while the mechanism is meaningless.
- Rejecting a correct feature because its accuracy is not better.
- Letting implementer/reviewer noise accumulate in the main context.
- Special-casing the test, the case file, or the harness instead of the engine.
- Two lanes editing the same files, or one worktree with two writers.
- Tightening/loosening gates mid-run without recording it.
- Running the next phase while an unverified claim from the previous phase is still open.

## Files

| Path | Purpose |
| --- | --- |
| `references/roles.md` | supervisor/implementer/reviewer contracts, model routing, briefs, escalation |
| `references/orchestration.md` | sequential vs parallel lanes, worktrees, integration, failure handling |
| `references/evidence.md` | run directory, logs, `index.md`, hashing, reproducibility, human-readable review |
| `references/domain-gate.md` | premise validation, correctness vs accuracy, boundary matrices, nonsense test |
| `references/flow.md` | Mermaid flowcharts of the phase loop, the parallel lanes and the context layout |
| `templates/goal.md` | bounded goal + phase plan contract to agree with the user |
| `templates/implement-brief.md` | cold-start implementer packet |
| `templates/review-brief.md` | independent reviewer packet |
| `scripts/logs.py` | `init` / `append` / `verify` / `index` / `status` for `logs/log-*.jsonl` and `index.md` |
