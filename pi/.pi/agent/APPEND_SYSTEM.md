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

## Gemini subagent routing

Route broad reading, repository mapping, extraction, comparison, and data analysis to `scout` or `data-auditor`. Make each Gemini task independent, read-only, bounded, and evidence-oriented. Include exact scope, paths, questions, exclusions, and expected output; require paths, symbols, representative evidence, uncertainties, and a concise verdict.

Keep synthesis, architectural decisions, implementation, and final verification with the main Sol/Astra agent. After implementation, use a fresh reviewer when independent validation is useful. Do not use `researcher` until its required web-tool extension is deliberately configured.
