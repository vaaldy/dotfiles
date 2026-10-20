---
description: Start or resume a bounded simulation improvement loop (phases, implement+review subagents, commit gates, evidence ledger)
argument-hint: "[goal description, or runs/<goal-id> to resume]"
---
Load and follow the `simulation-improvement-loop` skill (`/skill:simulation-improvement-loop`) for this request:

${@:-<no goal supplied — ask the user for the bounded goal, the N phases/features, and the stop condition before doing anything else>}

Do not start compute before the goal contract and phase plan exist in `runs/<goal-id>/goal.md`.
