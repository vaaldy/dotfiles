# Pi Agent Workflow Plan

## Goal

Build a fast, low-bloat Pi workflow. Improve the main agent first; add tools and delegation only when a measured problem remains.

## Pinned implementations — do not substitute similarly named projects

> **TAVILY: use only the official Pi package [`@tavily/pi-extension`](https://www.npmjs.com/package/@tavily/pi-extension).** Its package does not currently declare a public source repository. It wraps the official [`tavily-ai/tavily-js`](https://github.com/tavily-ai/tavily-js) SDK; that SDK repository is not the Pi extension repository.

> **CODEGRAPH: if adopted, use [`lzehrung/codegraph`](https://github.com/lzehrung/codegraph), npm package [`@lzehrung/codegraph`](https://www.npmjs.com/package/@lzehrung/codegraph).** This is the specific implementation intended by this plan because it supports an on-demand CLI and installation into the universal `~/.agents/skills/` location. Do not substitute `colbymchenry/codegraph`, `codegraph-ai/CodeGraph`, or another same-named package without reevaluating the plan.

> **SUBAGENTS: if adopted, use [`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents), npm package [`pi-subagents`](https://www.npmjs.com/package/pi-subagents).**

## Phase 1 — Establish the baseline

Use one main agent (Codex 5.6 Sol or Astra) with medium thinking for routine work.

Main-agent rules:

- Make the smallest complete change.
- Read medium-level documentation before implementation code.
- Treat documentation as potentially stale and verify only relevant claims in code.
- Reuse existing patterns and fix the shared root cause.
- Avoid speculative refactors, abstractions, dependencies, compatibility layers, and adjacent cleanup.
- Explain before touching more than three files.
- Add only the smallest useful test.
- Review the final diff and remove unrelated changes.

Research order:

1. Current status and task-specific documentation in the repository-root `prompts/` directory when present
2. Relevant architecture documents in `prompts/`
3. At most one or two matching specs/prompts
4. External official documentation when needed
5. Targeted implementation code for verification

During this phase, access `prompts/` with native search and file-reading tools. Treat its documents as potentially stale and verify only relevant claims against source code.

Evaluate several real tasks using:

- Correctness
- Number of files changed
- Diff size
- Tool-call count
- Number of user redirects required

Do not add orchestration until this baseline is dependable.

## Phase 1.1 — Automate repository documentation setup

After the manual documentation workflow is dependable:

- Create repository-root `prompts/` as an independent Git repository
- Add `/prompts/` to the parent repository's local `.git/info/exclude`, not its committed `.gitignore`
- Keep commits in `prompts/` explicit; automation must not silently commit changes
- Never configure a Git remote for `prompts/`
- Keep the parent source repository and nested documentation repository histories independent
- Continue using native search for `prompts/`; keep CodeGraph focused on source code unless separate documentation indexing proves measurably useful

## Phase 2 — Add research only if needed

Add **the official [`@tavily/pi-extension`](https://www.npmjs.com/package/@tavily/pi-extension)** if external documentation research remains weak. Do not replace it with a similarly named community Tavily package without reviewing that package separately.

Use it for current official documentation, version-specific references, maintainer repositories, and release notes. It should not replace local documentation or direct source verification.

## Phase 3 — Add bounded delegation only if useful

Add **[`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents)** (`pi-subagents` on npm) only if delegation measurably reduces main-agent context, time, or diff size.

Proposed routing:

- Main Codex/Astra: decisions, synthesis, and final edits
- Gemini Flash through OpenRouter: bounded documentation research, isolated snippet analysis, or focused review
- Main agent remains responsible for integration and critical verification

Prefer foreground children. Avoid councils, nested agents, broad fan-out, and background fleets unless a real task requires them.

## CodeGraph decision

Do not add CodeGraph initially. Native search and targeted reads are the baseline.

The only CodeGraph implementation selected for a possible trial is **[`lzehrung/codegraph`](https://github.com/lzehrung/codegraph)** (`@lzehrung/codegraph` on npm).

Consider CodeGraph later only when repeated tasks require expensive cross-file discovery, such as:

- Tracing callers and callees
- Confirming the real execution path
- Finding a shared implementation boundary
- Estimating blast radius
- Selecting affected tests

If adopted, use the CLI/skill on demand with bounded output rather than wiring a broad MCP tool surface.

## tmux `/btw`

`pi/extensions/btw.ts` remains a separate, manually controlled scratch pane. It is not wired into `pi-subagents`.

If automated delegation is eventually adopted, either retire `/btw` or reserve it strictly for visible human-supervised second opinions. Do not combine both systems into one orchestration pipeline.

## Guiding rule

Add one capability at a time, keep it only when measurements show that it improves the baseline, and avoid multiplying behavior the main agent has not yet learned to control.
