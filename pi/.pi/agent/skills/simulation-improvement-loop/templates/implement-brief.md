# Implement brief: phase <phase-id> (<goal-id>)

Cold-start packet. You have no shared memory with the supervisor; everything you need is
here and in the repository.

## Objective

Implement exactly one mechanism: <mechanism in one sentence>. Do not implement adjacent
features, refactor the engine, or clean up unrelated code.

## Premise (already validated — implement it, do not re-litigate it)

- mechanism: <…>
- units / dimensional check: <…>
- domain of validity: <…>
- reference: <paper/spec/path>
- expected effect: <what should improve, what may get worse, which limiting case must hold>
- falsification: <the observation that would prove the premise wrong>

If the code cannot implement this premise as stated, or the premise contradicts the source,
**stop and report** — do not substitute a different mechanism, fit constants, or change the
case set. That outcome is recorded as `BLOCK-PREMISE` and is a valid result.

## Workspace

- repository: `<path>` · base ref: `<commit>` · lane branch: `<branch>` · worktree: `<path>`
- one writer per worktree; do not push; do not rewrite history; do not modify other lanes
- files in scope: `<glob list>` · off-limits: `<…>`
- bootstrap if the worktree is fresh (dependencies may not be linked): `<command>`

## Acceptance criteria

- feature runs end-to-end on the frozen cases: `<case set + command>`
- repository checks pass: `<build/test/lint commands>`
- existing behavior unchanged on the frozen baseline cases (list any allowed difference)
- boundary/edge cases probed: `<subset from references/domain-gate.md>`
- no case-specific special-casing, no harness/threshold/test edits, no manual output repair

## Required artifacts

Write to `runs/<goal-id>/phases/<phase-id>/`:

- `implementer-report.md`
- `commands.log` — every command with exit code and duration
- `scripts/` — case-specific scripts you wrote
- `logs/` — raw run logs
- `artifacts/` — outputs a human will use (comparison render, table/plot, export file) plus
  machine outputs; stable names are required

## Required report

Facts, not narration. Report commands and numbers, not your reasoning about them; nobody
reads the report for encouragement or for intentions you did not execute.

1. what changed (files + one-line each) and why
2. exact commands run and their observed results (numbers, not adjectives)
3. artifacts with paths
4. which boundary cases were probed and which were not
5. what is uncertain, and what you could not verify
6. honest negative results or partial completion — never overstate

If you want to preserve your reasoning for debugging a failure, write it to
`phases/<phase-id>/journal.md`. It is quarantined: not evidence, not linked from the index,
never quoted into the main context, never a basis for a verdict.

Never write into `logs/` or `index.md` — the supervisor owns those, and they hold
structured facts only.

## Commit

One cohesive commit on the lane branch when the work is coherent: lowercase
`[feat]`/`[fix]`/`[test]`/`[chore]` subject. The supervisor decides whether it lands.

## Stop / ask

Stop and report instead of improvising when: the premise does not hold in the source; a
required check cannot be run; a file outside scope must change; the change would alter
existing results beyond the declared tolerance; or two attempts at the same defect fail.
