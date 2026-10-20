# Orchestration: sequential and parallel phases

## Choose the mode

Default to **sequential**. Use **parallel lanes** only when the phases are genuinely
independent. Test each candidate pair:

- Does the feature need the other's landed code, contract or measured evidence? → sequential.
- Do they touch the same files, the same shared contract, the same config/registry entry, or
  the same generated artifact? → sequential (or one lane owns the shared file).
- Is each independently testable and independently revertable? → parallel is allowed.

When in doubt, sequential. Parallel lanes that interfere cost more than they save and
poison the logs with ambiguous verdicts.

## Sequential phases

One phase at a time, one writer. Keep the supervisor's own checkout clean and reserved for
integration; implement in a lane worktree based on the current integration commit.

- Phase `Pn+1`'s brief includes: the integration commit after `Pn`, the evidence `Pn`
  produced, the open questions `Pn` left, and the fact that only `Pn`'s committed behavior
  is assumed.
- Never start `Pn+1` while `Pn`'s gate is open. A phase ends with a log entry and either
  an integration commit or a recorded rejection.

## Parallel lanes

Cap: **4 lanes** (the deployment parallel limit), one worktree per lane, one writer per
worktree. Before launching, write the lane table into the run directory:

| lane key | phase | branch | worktree | files in scope | artifacts dir |
| --- | --- | --- | --- | --- | --- |
| `P1-quick` | QUICK scheme | `sim/<goal>/P1-quick` | managed | `src/schemes/*` | `runs/<goal>/phases/P1-quick` |

Preflight: the file-scope sets must be disjoint. If they are not, serialize those lanes.

Launch shape for parallel independent phases (managed isolation, branched from HEAD):

```js workflow
const results = await runs.all([
  { key: "P1-quick",  agent: "worker", task: "<implement brief P1>",  worktree: true },
  { key: "P2-sou",    agent: "worker", task: "<implement brief P2>",  worktree: true },
  { key: "P3-hds",    agent: "worker", task: "<implement brief P3>",  worktree: true },
  { key: "P4-smart",  agent: "worker", task: "<implement brief P4>",  worktree: true }
]);
return results.map(({ key, artifactPaths }) => ({ key, artifactPaths }));
```

Then review each lane in a fresh-context reviewer that inspects that lane's worktree, and
gate and integrate each lane in the parent, one at a time. Use `runs.lanes` only when the
whole plan is predeclared and benefit comes from visible per-lane stages; do not add
stages for ceremony.

Managed-worktree facts to respect:

- `worktree: true` requires a **clean** git state (pi-subagents' own `.pi/subagents/`
  runtime files are ignored) and branches that worktree from `HEAD`; base lanes on the
  intended integration commit.
- Worktrees start from tracked files: ignored/untracked build state may be absent. Treat
  dependency/bootstrap setup as an explicit step in the implementer brief before it runs
  tests or builds (`worktreeSetupHook` can automate this).
- Read each child's handoff path from `artifactPaths`; do not scrape combined output.
- Keep lane worktrees out of auto-discovered extension directories (e.g.
  `~/.pi/agent/extensions`) so a stale checkout cannot auto-load duplicate tools.
- Keep a worktree while its handoff is not durable, a run still owns it, or a later gate
  needs it. Discard preserved work only through the recorded discard action with its
  handoff path — never delete a rejected lane's branch or worktree silently.

## Integration

The supervisor integrates, not the child.

1. Gate the lane (`COMMIT-*` only) and record the verdict + lane commit sha in the log.
2. Merge the lane commit into the integration branch from the supervisor's checkout, only
   when no writer is active on those files.
3. Run the repository's own checks (build/test/lint/smoke, and the frozen cases when cheap)
   on the integration branch. A failing integration is a `REJECT-DEFECT`, not a round of
   quick fixes by the supervisor.
4. Commit on the integration branch with a lowercase `[feat]`/`[fix]`/`[test]`/`[chore]`
   subject. No pushes. Record the integration commit sha in the log.
5. Move the next phase's base to that commit.

If the repository uses per-host or per-branch policy (for example a shared `main` plus host
branches, or a repo whose docs say not to touch a branch), read that policy before merging
and follow it. This skill does not override repository workflow rules.

## Keeping the parent responsive

- Launch async by default and yield after triaging useful lanes; ordinary async subagents
  notify the parent when they finish, so do not block merely because a child is running.
- Keep long or high-output validation out of the chat: bounded logs, artifact files, or a
  child-owned report, and only a summary plus path in the main context.
- While lanes run, the parent does useful bounded work: premise checks for later phases,
  log entries, briefs, `faq.md`, integration of already-gated phases.
- If only async lanes are running, record the revisit trigger and yield instead of spinning.

## Failure handling

A subagent launch failure, prompt-runtime failure, extension-load failure, or missing child
tooling is a **lane infrastructure blocker**:

1. Stop launching new work for that lane.
2. Preserve the exact error, the run/status output, and the repo/cwd/worktree/branch state.
3. Verify the worktree is clean, or capture the partial diff first.
4. Retry once on the same protocol, or report to the user and ask. Never silently switch to
   another execution mode, foreground agent, or CLI as a fallback, and never silently
   substitute a model after a provider failure.

If the session dies mid-lane, resume from `goal.md` + the log tail + the worktree state.
Never start a second writer while worktree ownership is uncertain.

## Lanes vs single writer

If the run needs one writer thread with several advisory readers (reviewers, oracles,
researchers), do not create parallel writers — review and research fanout is read-only and
can share a checkout. Isolation exists for **concurrent mutation**, not for legitimacy.
