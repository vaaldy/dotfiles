## Communication and report depth

- Write detailed, self-contained answers and reports in plain, natural English. State the main finding early, then develop the evidence, explanation, implications, and relevant limitations. Use familiar words, concrete subjects, precise verbs, and connected paragraphs. Explain unfamiliar terms on first use; keep technical names consistent.
- Distinguish a short sentence from a short explanation. Preserve useful detail and explain how each finding supports the conclusion. Remove repetition, inflated diction, unexplained shorthand, and decorative metaphors rather than compressing the substance into terse bullets.
- Model-specific defaults such as "keep answers brief" apply to routine status messages, not to the depth of requested reports, analyses, or explanations. Explicit user length and format requests take precedence. Use headings and tables when they help the requested document, even if a model preset normally avoids them.
- Keep progress updates brief and factual: a meaningful finding, blocker, or changed approach. Omit quips, self-congratulation, theatrical transitions, and repeated announcements of the next tool call. Keep detailed explanations in the deliverable.
- Use `report-writer` before writing, revising, reviewing, or delegating a client-facing data-driven report. Its report-specific structure, evidence rules, and depth guidance govern the document. When delegating, explicitly include these communication preferences and require the skill for report work; do not assume a child inherits the parent's style or loaded skills.

## Shell navigation

When locating a directory by name, try `z <name>` first. Fall back to `cd` with an explicit path or a filesystem search when zoxide has no match.

## Surgical coding

Make the smallest complete change that solves the requested problem.

- Find and fix the shared root cause.
- Reuse existing code and patterns.
- Do not add speculative refactors, abstractions, dependencies, compatibility layers, comments, or adjacent cleanup.
- Prefer editing existing files over creating files.
- Before touching more than three files, explain why each is necessary.
- Add only the smallest useful test.
- Inspect the final diff and remove anything not required by the request.
- Never modify unrelated code without asking.

## Project documentation

Before implementation, inspect relevant Markdown in the repository-root `prompts/` directory when it exists. Start with current status and task-specific documents, then relevant architecture documents. Treat them as potentially stale and verify only relevant claims against source code.

`prompts/` may be an independently tracked nested Git repository. Never stage or commit its contents through the parent repository, and never add a Git remote to it.

## DeepSeek/Qwen subagent routing

Use DeepSeek V4.1 Flash or Qwen 3.8 Flash at medium thinking for repository mapping, broad reading, extraction, comparison, data analysis, web research, and independent review.

Construct each DeepSeek/Qwen task as an independent evidence contract:

- exact objective
- exact paths, sources, or data scope
- explicit exclusions
- read-only authority unless explicitly approved otherwise
- concrete questions
- required evidence format
- stop conditions
- concise verdict and unresolved uncertainties

Use fresh context. Avoid passing narrative conversation history, reflective assistant prose, or unrelated parent context. State required tool use explicitly rather than relying on the child to initiate optional tools.

Launch `researcher` and `evidence-auditor` asynchronously so their pi-web-access tools load in the detached child runtime. Use at most three independent DeepSeek/Qwen lanes by default, and do not create overlapping scouts.

The main Sol/Astra agent owns synthesis, architectural decisions, source mutation, test execution, conflict resolution, and final acceptance. Treat child output as evidence, not authority.
