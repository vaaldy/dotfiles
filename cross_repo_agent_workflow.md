# Cross-Repository Agent Architecture (tmux + nvim + pi)

A battle-tested architecture and operating loop for running multiple `pi` coding agents across interdependent repositories, designed specifically for a terminal-first workflow using `tmux`, `nvim`, and `sesh`.

---

## 1. Context & Motivation

### The Working Environment
* **Terminal-First:** Fully operated inside `tmux` and `nvim`.
* **Session Management:** `sesh` + `zoxide` for fast navigation between projects and directories.
* **Agent Engine:** `pi` coding agent with per-session context tracking, auto-compaction, and tool extensions.

### The Problem
Features frequently span multiple interdependent repositories (e.g. `dclib` and `dcwiz-task-library`).
- Running open-ended peer-to-peer agent chatter between sessions burns context, risks deadlocks, and causes token bleed.
- Agents directly modifying files in another repository trigger nvim swapfile/buffer desyncs and git branch collisions.
- Long-running agents accumulate "rotten" context (approaching 1M tokens), requiring resets (`/new`) without losing the task's historical objectives.

---

## 2. Core Architectural Pillars

### Pillar 1: Worktree Isolation (Zero Buffer / Branch Collision)
Never mutate code directly inside your primary `main` repository folders. Instead, both repositories use linked **Git Worktrees** pointing to the shared task branch:

```text
~/projects/
├── dclib/                                    <- Primary checkout (clean on 'main')
├── dcwiz-task-library/                       <- Primary checkout (clean on 'main')
│
├── dclib-worktrees/
│   └── feat-stream-v2/                       <- Worktree (on branch 'feat/stream-v2')
│
└── dcwiz-task-library-worktrees/
    └── feat-stream-v2/                       <- Worktree (on branch 'feat/stream-v2')
```

#### Why Worktrees?
* **An isolated directory, not an abstract branch:** A worktree is a real folder on disk with its own working files, sharing the same underlying `.git` database.
* **No nvim buffer clobbering:** Your main session editing `main` in nvim will never experience swapfile warnings or file shifts while an agent is modifying code in the worktree.
* **Direct local package linking:** Worktree paths can be linked directly (`npm link`, `pip install -e`, or `go.work`) without dirtying `main`.
* **Direct PR pipeline:** Commits made in a worktree already live on that local branch. You push to remote (`git push -u origin feat/...`) and create PRs (`gh pr create` or lazygit `prefix + g`) directly from the worktree folder.

---

### Pillar 2: Shared Contract Workspace (`~/.pi/tasks/<task-id>/`)

Cross-repo state is communicated **asynchronously via structured filesystem artifacts**, not via unconstrained inter-agent chat.

```text
~/.pi/tasks/<task-id>/
├── 00_SPEC.md              # Requirements, missing APIs, expected types, and acceptance tests
├── 01_DCWIZ_CHANGES.md     # Exports, breaking changes, and commit hashes produced by dcwiz
└── 02_DCLIB_INTEGRATION.md # Integration verification and end-to-end test results
```

#### Why File-Based Contracts?
1. **Solves the Rotten Context / `/new` Problem:** When a session approaches token limits (e.g. 800k+ tokens), run `/new` with zero guilt. The fresh session simply reads `00_SPEC.md` and begins working immediately.
2. **Context Shielding:** Prevents logs, failed test traces, and chatty internal monologue in Repo B from polluting the context window of Repo A.
3. **Audit Trail:** You (the developer) can review, tweak, and approve the contract in `nvim` before dispatching.

---

### Pillar 3: Ground Truth Anchor via Dynamic System Prompt

Auto-compaction compresses older messages and will eventually drop mentions of task contract files. To make the connection indestructible across compactions and `/new` invocations:

1. **The Git Branch is the Foreign Key:** The directory name matches the active Git branch (`feat/stream-v2` -> `~/.pi/tasks/feat-stream-v2/`).
2. **`before_agent_start` Hook Injection:** A lightweight Pi extension intercepts every agent turn and dynamically prepends the active contract path to the **system prompt**. Because the system prompt is rebuilt fresh on every turn, it is **immune to compaction**.

```typescript
// pi/extensions/task-anchor.ts
import * as fs from "node:fs";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    try {
      const branch = execSync("git rev-parse --abbrev-ref HEAD", { cwd: ctx.cwd })
        .toString()
        .trim()
        .replace(/\//g, "-");

      const contractPath = `${process.env.HOME}/.pi/tasks/${branch}/00_SPEC.md`;

      if (fs.existsSync(contractPath)) {
        return {
          systemPrompt:
            event.systemPrompt +
            `\n\n[ACTIVE CROSS-REPO CONTRACT]\n` +
            `Branch: ${branch}\n` +
            `Contract File: ${contractPath}\n` +
            `Rule: When in doubt about requirements, types, or dependencies, re-read this contract file.`
        };
      }
    } catch {
      // not a git repo or no active branch
    }
  });
}
```

---

## 3. The Operating Workflow Loop

```
[ Tmux Session: dclib ]                 [ Tmux Session: dcwiz-task-library ]
  (worktree: feat-stream-v2)              (worktree: feat-stream-v2)
             │                                       │
 1. Discovers dependency                             │
    gap in dcwiz                                     │
             │                                       │
 2. Writes Contract                                  │
    (~/.pi/tasks/.../00_SPEC.md)                     │
             │                                       │
 3. You switch via sesh (prefix + s) ───────────────>│
                                                     │ 4. Check context tokens:
                                                          - Rotten (>500k)? Run /new
                                                          - Fresh? Continue
                                                     │ 5. Agent reads 00_SPEC.md
                                                     │ 6. Implements, tests, commits
                                                     │ 7. Writes 01_DCWIZ_CHANGES.md
             │<── You switch back (prefix + Tab) ────│
 8. Reads 01_DCWIZ_CHANGES.md                        │
 9. Verifies integration & tests                     │
```

### Step-by-Step Procedure

1. **Initialize Feature Worktrees:**
   ```bash
   # In dclib:
   git worktree add ../dclib-worktrees/feat-stream-v2 -b feat/stream-v2

   # In dcwiz-task-library:
   git worktree add ../dcwiz-task-library-worktrees/feat-stream-v2 -b feat/stream-v2
   ```

2. **Start Sessions via `sesh`:**
   - Open `sesh` (`prefix + s`), select `dclib-worktrees/feat-stream-v2`. Launch `nvim` and `pi`.
   - Open `sesh`, select `dcwiz-task-library-worktrees/feat-stream-v2`. Launch `nvim` and `pi`.

3. **Produce the Contract (`00_SPEC.md`):**
   - In `pi-dclib`, prompt the agent to outline the missing interface/behavior.
   - Save to `~/.pi/tasks/feat-stream-v2/00_SPEC.md`.

4. **Execute in Dependency Repo (`dcwiz`):**
   - Switch to the `dcwiz` session (`prefix + s` or `prefix + Tab`).
   - Check context usage in the status bar:
     - If bloated / distracted: hit `/new`.
   - Ask `pi-dcwiz` to implement the requirements in `00_SPEC.md`.
   - Run tests and inspect diffs via `lazygit` (`prefix + g`).
   - `pi-dcwiz` writes `01_DCWIZ_CHANGES.md` documenting exported symbols and commits.

5. **Consume & Verify in Main Repo (`dclib`):**
   - Switch back to `dclib`.
   - `pi-dclib` reads `01_DCWIZ_CHANGES.md`, updates imports/calls, and runs end-to-end tests.

6. **Push & PR Creation:**
   - Both worktree directories are already on `feat/stream-v2`.
   - In each worktree: `git push -u origin feat/stream-v2 && gh pr create`.

7. **Clean Teardown (After Merging Upstream):**
   ```bash
   git -C ~/projects/dclib worktree remove ../dclib-worktrees/feat-stream-v2
   git -C ~/projects/dcwiz-task-library worktree remove ../dcwiz-task-library-worktrees/feat-stream-v2
   rm -rf ~/.pi/tasks/feat-stream-v2
   ```

---

## 4. Subagent Policy & Guardrails

When a main agent (`pi-dclib` or `pi-dcwiz`) spawns subagents, enforce these rules:

1. **Write-Local Only:** Subagents may only use mutating tools (`write`, `edit`, `bash`) on files within their own worktree (`ctx.cwd`). They must **never** edit files across repo boundaries.
2. **Read-Global Allowed (Scouts):** A subagent in `dclib` may use read-only tools (`read`, `grep`, `find`) with `cwd` pointed at `dcwiz` to inspect types or implementations without polluting the main agent's context.
3. **No Recursive Subagents:** Subagent definitions must exclude the `subagent` tool to prevent nested tree recursion and runaway token consumption.
4. **Human In The Loop for Session Switches:** Let `tmux` and `sesh` remain the switchboard. Do not allow autonomous unmonitored back-and-forth loops between live main agents.
