# The domain gate: correctness commits, accuracy informs

The loop exists to add real mechanisms to a real codebase. The domain is the user's
responsibility — the agent's job is to implement and verify honestly, and to refuse to fit.

## Premise validation (before the phase)

Write this for the phase, in the brief and in the log. If any line cannot be filled
without guessing, the phase is `BLOCK-PREMISE` and the loop asks the user.

1. **Mechanism** — the scheme, equation, model, property or boundary treatment being added,
   in one sentence, with the symbols defined.
2. **Units / dimensions** — dimensional analysis of the new terms. A term that does not
   reduce to the expected dimension is not a candidate.
3. **Domain of validity** — regimes where it is expected to hold, and where it is known to
   misbehave (Mach/Peclet/Reynolds/CFL/stiffness/… range, grid assumptions, symmetry).
4. **Reference** — a paper, textbook section, spec, or existing implementation the reviewer
   can check against. "It seemed reasonable" is not a reference.
5. **Expected effect and direction** — what should improve, what may get worse, and which
   limiting case must reproduce the expected asymptotic behavior.
6. **Falsification** — the observation that would prove the premise wrong.
7. **Existing neighbors** — the current implementation it must slot next to (for example the
   central-differencing scheme it will be selected against), so the new feature is a peer,
   not a rewrite of the engine.

## The scaffold is the first ground truth

A codebase engineered so that a wrong mechanism cannot quietly fit is worth more than any
review prompt. The scaffold is **not just types** — it has three layers, and the second one is
where meaning gets checked:

- **Shape (static, cheap).** Units and dimensions carried in the type system; canonical
  interfaces and one registration path; required declarations next to the code (order of
  accuracy, domain of validity, stability condition, limiting behavior); no untyped side
  channel where a fitted constant or per-case branch can hide.
- **Results (dynamic, this is the ground truth for meaning).** Frozen golden cases, invariants
  and conservation checks, measured order of accuracy via a convergence study, and at least
  one comparison against an analytic, manufactured, published-benchmark or independent-
  implementation result.
- **Declarations (metadata the reviewer and later phases consume).** What the phase claims,
  over which regime, with which stability condition — required fields, not prose.

Before the phases start, build or extend this — a frontier-tier architecture job, not a phase.
This is what keeps the premise gate from being an LLM grading an LLM: the compiler, the type
system, the registry contract and the verification cases reject a whole class of wrong
premises before review begins, and fitting the harness becomes *more* work than implementing
the mechanism. Scaffold changes mid-run are flagged phases — larger blast radius,
sensitive-code review tier.

### The scaffold must be results-driven and must not overfit

An uncalibrated harness is just a second place to be confidently wrong. Treat it as an
instrument with its own evidence:

- **Prove it discriminates (negative control).** A deliberately wrong variant — flipped sign,
  dropped term, wrong order, wrong limiting case — must fail the verification set. If the
  scaffold passes a known-bad implementation, it cannot reject a wrong premise, and the phase
  gates are decorative. Record the control and its result.
- **Derive tolerances, never choose them to pass.** Order of accuracy from a convergence
  study, invariant residuals against round-off, and a **measured noise floor** (repeat runs)
  so no tolerance is tighter than the noise or looser than the physics.
- **Keep the judge independent of the feature.** Cases come from physics, references and
  independent implementations — not from the incumbent's own output. A verification set built
  from what the code already produces is a change-detector, not a correctness test, and it
  teaches every new phase to reproduce the old one.
- **Freeze and hash the verification set.** A phase may not edit the cases, tolerances or
  invariants that judge it. Changing the judge is a goal amendment followed by a re-baseline,
  and every affected phase is re-judged or explicitly marked stale.
- **Never weaken the scaffold to pass a phase.** No loosened tolerance, no deleted case, no new
  exemption, no special case in the base class. If the scaffold needs a special case for the
  new mechanism, the abstraction is wrong (or the premise is) — flag it as a scaffold phase.
- **State coverage honestly.** Which regimes the cases cover, which they do not, and which
  were merely not run. Green tests imply nothing about an uncovered regime.

The scaffold's own evidence — case-set hash, tolerance derivations, noise floor, negative
control — belongs in `goal.md` and the log, so a colleague can audit the instrument, not just
the experiments.

Residual risk, stated honestly: types check **shape**, not **meaning**, and a calibrated
harness only checks the meanings it was built to check. A dimensionally consistent, correctly
typed correlation with no physical basis still compiles, can still pass loosely chosen cases,
and will still be accepted by a reviewer who trusts the scaffold. The checks that remain
necessary are therefore the ones about meaning: limiting and asymptotic behavior, invariants
and conservation, measured order of accuracy, and comparison against an independent result for
at least one case per phase.

## Two separate verdicts

| Verdict | Question | Gate role |
| --- | --- | --- |
| Semantic / physical correctness | Is this a real mechanism, correctly implemented, with the right units, limits and domain? | **Commit gate** |
| Accuracy / performance | Does it beat the incumbent on the frozen cases? | **Informational** |

A phase commits when the first is yes, the feature runs, the repository's own checks pass,
and existing behavior does not regress — even when the second is worse. A phase never
commits because the second is better while the first fails.

Do not silently tighten or loosen either side. If the accuracy gate should become a
commit gate for one phase (a pure optimization phase), record that in `goal.md` before the
phase starts, with the user.

## The nonsense test

`q = m·ΔT` instead of `q = m·c·ΔT` is the canonical rejection: the code may run, the case may
even pass after constant tuning, but there is no mechanism. Reject when any of these hold:

- the new term/coefficient has no units that close with its neighbors;
- the "fix" only works for the specific case, seed, grid or threshold it was tuned on;
- the reference does not actually contain the mechanism as implemented;
- limiting cases (zero, uniform, symmetric, steady, inviscid, low/high regime) do not
  reproduce the expected asymptotics;
- the implementation special-cases the harness, the case file, the test, or the baseline
  instead of the engine;
- the claim rests on a metric that the change also perturbs (self-fulfilling evaluation).

The reviewer asks: *would a domain expert sign this off, and why?* An answer of "the numbers
got better" is not an answer.

## Boundary and edge-case matrix

Give the reviewer a concrete list to probe, fixed at phase start, not a vague instruction.
For numerical/simulation work the reusable set is:

- **Dimensional consistency** of every new term.
- **Conservation / invariants** (mass, momentum, energy, monotonicity, positivity) on the
  frozen cases.
- **Limiting behavior**: zero and uniform fields, steady state, symmetric configurations,
  the asymptotic regime the scheme is derived for, and its opposite extreme.
- **Stability / CFL / conditioning**: does the change alter a stability condition, and is
  that stated?
- **Order of accuracy**: expected order on a smooth case (grid refinement) — measured, not
  asserted.
- **Boundedness / monotonicity**: limiter or TVD property where claimed, and no unphysical
  oscillations introduced.
- **Discretization artifacts**: grid-orientation dependence, odd-even decoupling,
  checkerboarding, over/under-shoots.
- **Interaction with existing features**: the previously added schemes/phases must still
  produce their previous results on the frozen cases.
- **Repository checks**: build, test suite, lint, and any golden/regression test in-tree.

Select the subset that applies to the phase, plus anything domain-specific the user
supplied. The reviewer must report which cases were actually run and which were not — an
untested boundary is recorded as untested, never as passed.

## What "robust" means for a commit

The code path is rule-based (no per-case branching), semantically correct, runs the feature
being tested, handles the declared domain, and does not degrade the core engine or existing
edge-case handling. A feature that only works through manual intervention, a hand-edited
output, or a case-specific constant is not robust and does not commit.

## When evidence contradicts the premise

Stop the phase, record `BLOCK-PREMISE` (or `REJECT-NONSENSE` when the implementation, not the
premise, was the fit), and tell the user what the evidence shows. Do not iterate the numbers
until a gate passes, do not re-scope the phase to something adjacent that does pass, and do
not present a refuted premise as a partial success. A correctly recorded refutation is a
successful phase of the loop.

## The expertise expectation

This loop rewards domain understanding and punishes metric-chasing. It cannot compensate for
an agent (or a user) who skipped the crux of the problem: the mechanism, its units, its
validity range and its limiting behavior have to be understood before the phase runs. When
the understanding is missing, the correct loop behavior is to say so, ask the user, or
research the reference — not to generate code and hope the case passes.
