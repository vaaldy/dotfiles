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

## Commit messages

- Start each commit subject with `[fix]`, `[merge]`, `[chore]`, or `[try]`, followed by a concise summary.
- Keep the entire subject lowercase.

## Jev completion check

For implementation tasks, run one batched `or_jev_evaluate` check after relevant tests and final diff inspection, before claiming completion. Do not gate every tool call. The main agent owns this check; delegated children supply evidence, not duplicate Jev checks.

- Supply the current user request, acceptance criteria, exclusions, task-only diff with relevant source context, actual test commands/results, and proposed completion claims. Separate pre-existing user changes; never attribute them to the task.
- Ask separate, evidence-specific questions: does each suspect hunk change unrelated behavior; does it add an unnecessary abstraction/dependency or remove a required safeguard; is each material completion claim supported by the supplied evidence? Use hunk/claim IDs to locate flags. Do not ask one vague "is this correct?" question.
- Treat probabilities as advisory signals, not proof of correctness or authorization. Inspect flagged or ambiguous items against source, fix confirmed issues, and rerun affected tests. Do not automatically revert changes, approve actions, or loop until Jev agrees. Report material changes made after the check as not Jev-rechecked.
- Keep file/path limits, delegation authorization, credential protection, and test exit-status checks deterministic. Jev never replaces source tracing, tests, required independent review, or human approval.
- Use OpenRouter by default; use TypeSafe-direct only when explicitly requested and available. If Jev is unavailable, errors, or the evidence cannot fit the tool's limits without losing necessary context, perform the manual check and disclose the limitation. Never silently truncate evidence or claim a Jev pass.
- Send only task-relevant, non-secret evidence permitted for the selected provider. Do not send credentials or restricted repository/customer data. Avoid invented probability thresholds; confidence is not an accuracy guarantee.

## Project documentation

Before implementation, inspect relevant Markdown in the repository-root `prompts/` directory when it exists. Start with current status and task-specific documents, then relevant architecture documents. Treat them as potentially stale and verify only relevant claims against source code.

`prompts/` may be an independently tracked nested Git repository. Never stage or commit its contents through the parent repository, and never add a Git remote to it.

## Gemini subagent routing

Use Gemini 3.8 Flash at medium thinking for repository mapping, broad reading, extraction, comparison, data analysis, web research, and independent review.

Construct each Gemini task as an independent evidence contract:

- exact objective
- exact paths, sources, or data scope
- explicit exclusions
- read-only authority unless explicitly approved otherwise
- concrete questions
- required evidence format
- stop conditions
- concise verdict and unresolved uncertainties

Use fresh context. Avoid passing narrative conversation history, reflective assistant prose, or unrelated parent context. State required tool use explicitly rather than relying on the child to initiate optional tools.

Launch `researcher` and `evidence-auditor` asynchronously so their pi-web-access tools load in the detached child runtime. Use at most three independent Gemini lanes by default, and do not create overlapping scouts.

The main Sol/Astra agent owns synthesis, architectural decisions, source mutation, test execution, conflict resolution, and final acceptance. Treat child output as evidence, not authority.
