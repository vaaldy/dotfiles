# Roles, routing and briefs

## Supervisor (main context window)

The supervisor is the parent agent in the main conversation: **one continuous context across
all N phases**, not re-instantiated per phase. It is the only role that talks to the user,
and the only role that decides.

Owns:
- the goal contract (`goal.md`) and the phase order;
- premise checks before each phase;
- the gate verdict (`COMMIT-CORRECT`, `COMMIT-IMPROVED`, `REJECT-NONSENSE`,
  `REJECT-DEFECT`, `BLOCK-PREMISE`);
- integration into the integration branch and the lowercase commit on it;
- the logs, the run-directory artifacts and the `faq.md`;
- context hygiene: only correct, evidence-backed information enters the main window.

Does not:
- write the feature implementation or "quickly fix" the implementer's code — that is the
  implementer's lane, so the main context stays free of half-finished reasoning;
- accept its own claim as evidence: a claim is either in the reviewer's verdict, in a
  command the supervisor itself ran read-only, or it is marked unverified;
- run two writers in one worktree, or edit a lane while its implementer is active.

Bounded direct work by the supervisor is fine and cheap: grep/read for the premise check,
`git` operations, the log script, assembling briefs, running the repository's own
checks on the integration branch after a merge.

## Implementer (subagent)

Tier: **frontier** (the strongest practical coding model). Contract:

- End-to-end ownership of one phase: write the code, run the feature on the frozen cases,
  fix its own bugs, and leave the lane in a state another agent can verify.
- Stay inside the declared file scope. New helper scripts for this case go in the run
  directory, not scattered through the repo.
- Never change the case files, thresholds, harness or tests to make the phase pass. If the
  premise looks wrong, stop and report: that is a `BLOCK-PREMISE` candidate, not a
  workaround.
- Report in the parent's required format (see `templates/implement-brief.md`): what
  changed, exact commands, observed results, artifacts with paths, what is uncertain,
  what was **not** done. Honest negative results are a valid outcome of the phase.
- One cohesive lane commit when the work is coherent, lowercase
  `[feat]`/`[fix]`/`[test]`/`[chore]`, no pushes. The supervisor decides whether it lands.

## Reviewer (subagent)

Tier: **good flash** by default; **frontier at low thinking** for sensitive code (core
engine, memory layout, numerical kernels, concurrency, anything that silently changes
existing results).

- Fresh context, and a different model family from the implementer where availability
  allows. Never the implementer's transcript, never a fork of it.
- Independent: read the diff and the surrounding source, re-run what can be re-run, and
  verify the claimed numbers rather than the claim.
- Review-only by default: findings, no edits. A fix pass is a separate explicit
  commission.
- Output: verdict, findings with `file:line`, the command evidence, explicit semantic
  assessment (units, limiting cases, domain validity), regression risk, and an
  uncertainty flag. "Uncertain" is a legitimate, useful answer.
- The reviewer challenges the premise as well as the code: if the mechanism itself is
  wrong, that is `REJECT-NONSENSE`, not a style note.

A review that only restates the implementer's summary does not count as a review.

## Oracle (optional escalation)

Read-only, top-reasoning tier, bounded question. Use only when ordinary review plus source
evidence is insufficient for a root cause or a hard architectural fork — for example a
non-convergence that survives two phases, or a disagreement between reviewers. Ask for at
most three specific findings, each cited to a file, line or decision. The oracle advises;
the supervisor decides.

## Routing

| Phase kind | Implement | Review |
| --- | --- | --- |
| Ordinary feature / scheme / model addition | frontier | good flash |
| Core engine, numerics kernel, shared contract, silent-result change | frontier | frontier, low thinking |
| Boundary-condition/limiter work with subtle domain rules | frontier | good flash + a second frontier-low review on the final diff |
| Root cause blocked after two phases | frontier (implementer) | oracle, read-only, bounded |
| Parallel independent phases | one implementer per lane, frontier | one reviewer per lane, good flash |

Tiers, not IDs, are the portable contract. Current deployment preferences (2026-10):
implement on `openai-codex/gpt-6.1-sol`; review on a good flash tier such as Gemini
(Argon) flash, `opencode-go/deepseek-v4.1-flash`, or `opencode-go/qwen3.8-flash`; sensitive
review on `openai-codex/gpt-6.1-sol:low`. Top-reasoning tiers are cost-checked with the
user before use.

**Scaffold and architecture work is frontier-tier and happens before the phases**: typed
quantities/units, canonical interfaces, the registration path, required declarations, plus the
results layer — frozen golden cases, invariants, convergence/order-of-accuracy checks and an
independent reference comparison. It is not a phase, it is not delegated to a flash tier, and
it is what lets the gates reject a wrong premise without a human. The scaffold is delivered
with its own evidence: case-set hash, derived tolerances, measured noise floor and a negative
control showing a known-bad variant fails. Implementation phases then work inside that
scaffold rather than extending it; a phase that has to change the scaffold is a flagged,
sensitive-code phase.

Set routing in deployment config, not in briefs:

- per-role defaults: `subagents.agentOverrides.<agent>.{model,thinking}` in
  `~/.pi/agent/settings.json` (see the existing `reviewer`/`scout`/`researcher` entries);
- durable role agents in `~/.pi/agent/agents/<name>.md` (project: `.pi/agents/`), e.g.:

```markdown
---
name: sim-implementer
description: End-to-end implementer for one simulation-improvement phase
advertise: true
tools: read, grep, find, ls, bash, edit, write
model: openai-codex/gpt-6.1-sol
thinking: medium
systemPromptMode: replace
inheritProjectContext: true
inheritSkills: false
---
You implement exactly one phase of a simulation improvement loop...
```

- one-off override at launch when the phase is exceptional, and record the model used in
  the log. Never silently substitute a different model after a provider failure: report
  the failure and let the supervisor relaunch deliberately.

## Brief assembly

Every child packet is cold-start complete and self-contained; assume no shared memory with
the parent:

1. objective and phase id;
2. repo, `cwd`, base ref, lane branch/worktree (one writer per worktree);
3. authority: files in scope, files that are off-limits, no pushes, no history rewrites;
4. the premise: mechanism, domain, reference, expected effect direction;
5. acceptance criteria and the repository's own checks;
6. required validation commands and the frozen cases to use;
7. required artifacts and where to write them;
8. required report format;
9. stop/ask conditions.

Keep the brief about the phase, not the whole mission. A child that receives the entire
goal narrative will start re-litigating the plan.

## Parent–user FAQ dialogue

The user asks questions while the loop runs. Answer from the goal contract, the logs and
the reviewers' verdicts — not from speculation — and append new settled answers to
`runs/<goal-id>/faq.md`. When a question exposes a real gap in the goal or a wrong premise,
stop the loop and record the correction in `goal.md` before continuing.

## Escalation to the user

Escalate, do not improvise, for: an invalid or unverifiable premise; evidence contradicting
the goal; a required scope or taste decision; budget, storage, GPU or wall-clock limits; an
irreversible action outside the declared scope; a lane infrastructure failure that would
require changing execution protocol.
