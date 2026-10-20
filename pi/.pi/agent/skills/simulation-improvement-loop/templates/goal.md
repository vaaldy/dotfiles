# Goal contract: <goal-id>

Agreed with the user on <date>. This file is the authority for the loop; changes are
recorded as amendments (new date, what changed, why), never edited silently.

## Bounded goal

<One paragraph: what the codebase must be able to do at the end, and what is explicitly out
of scope.>

- **Repository / integration branch:** `<path>` / `<branch>`
- **Mode:** sequential | parallel (max 4 lanes)
- **Phase budget:** N phases · **Wall-clock / session budget:** <…> · **Stop condition:** <…>
- **Frozen case set:** `<path or id>` (sha256: `<…>`)
- **Metric(s):** `<name>`, direction `<lower|higher>`, baseline `<value>` — informational
  unless a phase below declares it a gate
- **Repository checks that must pass:** `<build/test/lint/smoke commands>`
- **Human deliverable per phase:** `<comparison render / table / export file>`

## Phase plan

| # | phase-id | mechanism / feature | premise (mechanism, domain, reference) | files in scope | depends on | acceptance |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P1-… | … | … | … | — | semantic + repo checks |
| 2 | P2-… | … | … | … | P1 | semantic + repo checks |

Every phase is a peer addition: it must slot next to the existing implementation, not
rewrite it. Each phase's premise has already been validated (units, domain, reference,
limiting cases, falsification) — see `references/domain-gate.md`.

## Scaffold and verification (before any phase)

The instrument the gates rely on. Fill this in before the first phase and freeze it.

- **Shape:** units/dimensions in the type system `<how>`, canonical interface + registration
  path `<where>`, required declarations (order, domain of validity, stability, limiting
  behavior) `<fields>`
- **Results:** golden cases `<path>` — **sha256** `<hash>`; invariants `<list>`; order of
  accuracy measured by `<convergence command>`; independent reference comparison
  `<analytic / manufactured / published benchmark / other implementation>`
- **Calibration:** noise floor from `<n>` repeat runs = `<value>`; tolerances derived from
  `<derivation, not chosen to pass>`
- **Negative control:** `<known-bad variant>` must fail — observed result `<...>`
- **Coverage:** regimes covered `<...>` · not covered `<...>` · untested but in scope `<...>`
- **Immutability:** no phase may edit these cases, tolerances or invariants. Changing the
  judge is a goal amendment + re-baseline, and every affected phase is re-judged or marked
  stale.
- **Scaffold changes:** any phase needing a scaffold change is a flagged sensitive-code phase.

## Commit policy

- `COMMIT-CORRECT` (correct + runs + no regression, accuracy may be worse) and
  `COMMIT-IMPROVED` integrate.
- `REJECT-NONSENSE`, `REJECT-DEFECT` do not integrate; both stay in the log.
- `BLOCK-PREMISE` pauses the loop for the user.
- Commit subject: lowercase `[feat]`/`[fix]`/`[test]`/`[chore]`. No pushes.

## Safety and bounds

- <storage / GPU / time / process limits, immutability rules, paths that must never be
  mutated — e.g. a parent repository or an independently tracked `prompts/` repo>
- Escalate instead of improvising when a bound is hit or an action falls outside scope.

## Run directory

`runs/<goal-id>/` with `goal.md`, `faq.md`, `logs/log-NN-<phase>.jsonl`, generated
`index.md`, `review/`, `phases/…` — see `references/evidence.md`.
