# The loop, visually

The scaffold in one sentence: a supervisor in the main context window works a bounded
goal through **N phases**; each phase is one hypothesis implemented by an **implement
subagent** and independently checked by a **review subagent**; the supervisor gates the
result and commits when the phase is *semantically* right, whatever the numbers say.

Mermaid source — renders in GitHub, your nvim Markdown preview, or any Mermaid renderer.
Sections 1–4 show the supervisory model; the final section adds the actual checkpointed
execution, repository ownership and recovery contract. Shared `APPEND_SYSTEM.md` governs
model routing and parent/runner ownership.

## 1. Overview — node headings only

The same shape as the detailed diagram below, with nothing written inside the boxes.

```mermaid
flowchart TD
    U["User"]
    SC["Scaffold"]
    S["Supervisor"]

    U --> SC
    SC --> S
    S --> P1["Phase 1"]
    S --> P2["Phase 2"]
    S --> PN["… Phase N"]

    P1 --> I1["Implement"]
    I1 --> R1["Review"]
    P2 --> I2["Implement"]
    I2 --> R2["Review"]
    PN -.-> I2

    R1 -->|"verdict"| G
    R2 -->|"verdict"| G
    G -.->|"rework"| I1

    G{"Gate"}
    G -->|"next phase"| S
    G -->|"COMMIT-*"| C["Commit"]
    G -->|"REJECT-*"| X["Reject"]
    G -->|"BLOCK-PREMISE"| B["Pause"]
    C --> LG["Log"]
    X --> LG
    B --> LG
    LG -->|"budget or done"| Z["Close goal"]

    classDef supervisor fill:#3d2f5c,stroke:#a855f7,stroke-width:3px,color:#fff
    classDef scaffold fill:#1f4b55,stroke:#22d3ee,stroke-width:2px,color:#fff
    classDef commit fill:#1f6f43,stroke:#123,color:#fff
    classDef reject fill:#7a2b2b,stroke:#123,color:#fff
    classDef pause fill:#7a5c1f,stroke:#123,color:#fff
    classDef neutral fill:#243b55,stroke:#123,color:#fff
    class SC scaffold
    class S,G supervisor
    class C commit
    class X reject
    class B pause
    class U,P1,P2,PN,I1,R1,I2,R2,LG,Z neutral
    linkStyle 0,1,2,3,4,10,11,12,13,14,15,16 stroke:#a855f7,stroke-width:2px,color:#c4b5fd
```

## 2. The scaffold: supervisor first, then N phases of implement + review

The supervisor node is **the same agent in the same context window before, between and after
every phase** — the loop returns to it. The log entry is the phase's durable record, not
a new actor, so the back-edge goes straight from the gate to the supervisor and the logs
hang off the side.

```mermaid
flowchart TD
    U["User — bounded goal<br/>N phases = hypotheses<br/>stop condition and bounds"]
    SC["Scaffold — built first, with the frontier model<br/>shape: units in the type system · one registration path · required declarations<br/>results: frozen cases · invariants · order of accuracy · independent reference<br/>calibrated: derived tolerances · noise floor · negative control must fail"]
    S["Supervisor — the main agent<br/>SAME supervisor before and after every phase<br/>persistent main context: correct information only<br/>premise checks · gate verdicts · commits · user Q&amp;A"]

    U --> SC
    SC --> S
    S --> P1["Phase 1 — hypothesis<br/>scheme / equation / feature"]
    S --> P2["Phase 2 — hypothesis<br/>scheme / equation / feature"]
    S --> PN["… Phase N"]

    P1 --> I1["Implement command — prepared by the owning parent<br/>Haiku runner executes the scoped script<br/>own worktree, one writer"]
    I1 --> R1["Independent review — Terra, fresh context<br/>diff · premise · boundary cases · re-runs checks<br/>wait for the actual verdict, not launcher success"]
    P2 --> I2["Implement subagent"]
    I2 --> R2["Review subagent"]
    PN -.->|"same two subagents"| I2

    R1 -->|"verdict + evidence"| G
    R2 -->|"verdict + evidence"| G
    G -.->|"REJECT-DEFECT: one rework pass"| I1

    G{"Supervisor gate<br/>semantically correct + runs<br/>repo checks pass + no regression"}
    G -->|"next phase<br/>same supervisor, same context"| S
    G -->|"COMMIT-CORRECT — accuracy may be worse<br/>COMMIT-IMPROVED"| C["Integrate the lane commit<br/>re-run the repository checks there"]
    G -->|"REJECT-NONSENSE — fitted to the metric<br/>REJECT-DEFECT after the rework pass"| X["Keep lane + diff, do not merge"]
    G -->|"BLOCK-PREMISE — premise invalid"| B["Pause and ask the user"]
    C --> LG["Log written to logs/log-NN-phase.jsonl<br/>structured only: commands · metrics · sha256 hashes · commit shas<br/>supervisor_note · index.md regenerated"]
    X --> LG
    B --> LG
    LG -->|"budget or goal reached"| Z["Close the goal<br/>index.md · faq.md · rejected runs preserved"]

    classDef supervisor fill:#3d2f5c,stroke:#a855f7,stroke-width:3px,color:#fff
    classDef scaffold fill:#1f4b55,stroke:#22d3ee,stroke-width:2px,color:#fff
    classDef commit fill:#1f6f43,stroke:#123,color:#fff
    classDef reject fill:#7a2b2b,stroke:#123,color:#fff
    classDef pause fill:#7a5c1f,stroke:#123,color:#fff
    classDef neutral fill:#243b55,stroke:#123,color:#fff
    class SC scaffold
    class S,G supervisor
    class C commit
    class X reject
    class B pause
    class U,P1,P2,PN,I1,R1,I2,R2,LG,Z neutral
    %% Purple edges = lines owned by the supervisor: scaffold handoff, dispatch, verdict return,
    %% rework, loop-back. Indices follow source order; keep in sync when edges change.
    linkStyle 0,1,2,3,4,10,11,12,13,14,15,16 stroke:#a855f7,stroke-width:2px,color:#c4b5fd
```

Purple marks the supervisor and every edge the supervisor owns: the scaffold handoff, the
phase dispatch, the review verdicts coming back, the rework pass, and the loop-back to the
*same* supervisor. The implement/review chain and the logs stay neutral. Each phase writes
`logs/log-NN-<phase>.jsonl`, and `index.md` states per log whether it failed or succeeded and
why.

Two phases are drawn to show the repetition; `Phase N` is the same shape. `COMMIT-CORRECT`
exists for the QUICK case — a real scheme whose numbers may be worse than central
differencing. `REJECT-NONSENSE` exists for the `q = m·ΔT` case — numbers that only come
from fitting.

## 3. Parallel independent phases

Only when the phases do not depend on each other: same supervisor, same two subagents per
phase, but N lanes at once, each in its own worktree.

```mermaid
flowchart TD
    S["Supervisor — main context window<br/>preflight: disjoint file scopes · one worktree per lane · max 3 lanes"]

    S --> L1["Lane 1 — own worktree"]
    S --> L2["Lane 2 — own worktree"]
    S --> L3["Lane 3 — own worktree"]

    L1 --> I1["Implement 1"]
    L2 --> I2["Implement 2"]
    L3 --> I3["Implement 3"]
    I1 --> R1["Review 1"]
    I2 --> R2["Review 2"]
    I3 --> R3["Review 3"]

    R1 -->|"verdict + lane commit"| G["Supervisor gates and integrates<br/>one lane at a time — COMMIT-* only"]
    R2 --> G
    R3 --> G
    G -->|"next batch — same supervisor"| S
    G --> LG["Log per lane in logs/ — structured only<br/>artifacts + sha256 · commit shas · index.md regenerated"]

    classDef supervisor fill:#3d2f5c,stroke:#a855f7,stroke-width:3px,color:#fff
    classDef neutral fill:#243b55,stroke:#123,color:#fff
    class S,G supervisor
    class L1,L2,L3,I1,I2,I3,R1,R2,R3,LG neutral
    %% Purple edges: lane dispatch, verdict return, next-batch loop-back to the same supervisor.
    linkStyle 0,1,2,9,10,11,12 stroke:#a855f7,stroke-width:2px,color:#c4b5fd
```

Two writers never share a worktree, and only the supervisor merges.

## 4. Where information is allowed to live

```mermaid
flowchart LR
    subgraph SUB["Subagents — disposable context"]
        I["Implementer"]
        V["Reviewer"]
    end
    subgraph MAIN["Main context window — correct information only"]
        M1["Goal contract + phase plan"]
        M2["Verdicts + evidence paths + commit shas"]
        M3["User FAQ"]
    end
    subgraph DISK["Run directory — durable evidence"]
        D1["Briefs, reports, raw logs, scripts"]
        D2["Artifacts + sha256, logs/log-*.jsonl"]
    end
    I -->|"compact report + artifact paths"| M2
    V -->|"verdict line + evidence paths"| M2
    I -->|"full transcript, dead ends, raw logs"| D1
    V -->|"full review, failed hypotheses"| D1
    D2 -->|"log tail, hashes — on demand"| M2
    M1 --- M3
```

Rot stays in the subagents and on disk, so a long loop does not slowly fill the main window
with wrong intermediate beliefs.

## Verdicts at a glance

| Verdict | Meaning | Lands? |
| --- | --- | --- |
| `COMMIT-CORRECT` | real mechanism, correct, runs, repo checks pass, no regression; accuracy may be worse | yes |
| `COMMIT-IMPROVED` | the same, and the frozen-case metric improves | yes |
| `REJECT-NONSENSE` | only "works" by fitting the metric, harness, case or a tuned constant | no |
| `REJECT-DEFECT` | right idea, broken/incomplete/regressing implementation; one rework pass allowed | no |
| `BLOCK-PREMISE` | the premise itself is invalid or cannot be stated | paused for the user |

Details: `references/domain-gate.md` (gates and the nonsense test),
`references/orchestration.md` (lanes and integration), `references/evidence.md` (logs and
hashing), `references/roles.md` (roles, routing, briefs).

## 5. Durable execution — repo ownership, checkpoints and recovery

For an authorized multi-phase loop, use `~/.pi/agent/scripts/durable-loop/runner.mjs`.
The supervisor prepares the bounded, immutable plan and exact commands first. Haiku
executes prepared work; Terra provides independent review. The negative-control command
succeeds only after proving the validator rejects a known-bad variant. Neither a
successful agent launch nor a passing metric establishes a review verdict or a correct
mechanism.

### Declare which repository owns each change

Before launch, write the exact ownership map in the approved goal/briefs. Replace the
example repo labels below with absolute repository/worktree paths and named owners.
Each `phase.cwd` must be the owning worktree. Keep the commands, allowed paths,
exclusions, prerequisite versions and evidence paths in that phase's contract; do not
expect the runner or a child to infer them from conversation history.

| Scope | Writer and authority | Required handoff |
| --- | --- | --- |
| Producer/library repo | Its owning parent prepares source changes; one writer in its worktree. Other repo agents are read-only there. | Interface contract, reproducer, exact source revision or built artifact identity, and validation evidence. |
| Consumer/application repo | Its owning parent changes the consumer only, after the producer version gate passes. | Pin the verified producer identity; run consumer tests against it, not a stale local build. |
| Integration worktree | One explicitly named owner; the supervisor owns final acceptance and authorized integration/commits. | End-to-end checks of the actual stack and remaining acceptance criteria. Producer tests alone are insufficient. |

```mermaid
flowchart LR
    S["Supervisor<br/>goal, ownership map and dependency gates"]
    A["Producer repo owner<br/>one writer in producer worktree"]
    H["Exact interface and artifact handoff<br/>revision or artifact hash + test evidence"]
    B["Consumer repo owner<br/>one writer in consumer worktree"]
    I["Integration owner<br/>full-stack checks on pinned identities"]
    S --> A
    A --> H
    H -->|"version gate passes"| B
    B --> I
    I -->|"evidence, not a completion assertion"| S
```

Express phase ordering with `dependsOn`: the default is sequential; independent
worktrees may run concurrently, at most three phases. A dependent phase may start when
its own prerequisites pass without waiting for unrelated lanes. The supervisor separately
reserves shared ports, databases, containers and mutable artifacts. Worktree overlap
checks apply within one run; they do not coordinate other sessions or run directories.

### Execute commands through the persisted state machine

```mermaid
flowchart TD
    P["Supervisor seals plan<br/>goal, exclusions, repo owners, commands, artifacts and budgets"]
    PRE["prepare<br/>persist launch checkpoint"]
    LA["launch<br/>seal intent before spawning"]
    CL["Worker takes exclusive claim"]
    W["implement -> validate -> negativeControl -> review<br/>exact prepared commands in the owning worktree"]
    EX["exit.json + logs + process identities + artifact hashes"]
    MO["monitor<br/>observe the existing worker"]
    GA["gate<br/>verify input, exits, deadline and artifacts"]
    RE["Seal and verify receipt.json"]
    DB["Commit verdict to state.sqlite"]
    SG{"Supervisor domain gate<br/>correct mechanism and integration evidence?"}
    C["COMMIT-CORRECT or COMMIT-IMPROVED<br/>integrate, recheck and commit only if authorized"]
    N["Runner admits ready dependent phases<br/>only configured gates are enforced"]
    X["Reject integration and preserve evidence<br/>chat verdicts are not runner gates"]
    F["Stop new admissions; let active lanes settle<br/>preserve failure evidence, no in-place retry"]

    P --> PRE --> LA
    LA --> CL --> W --> EX --> MO
    LA --> MO
    MO -->|"exit evidence available"| GA
    MO -->|"worker lost or deadline exceeded without exit"| F
    GA -->|"evidence valid"| RE --> DB
    GA -->|"invalid or missing evidence"| F
    RE -->|"receipt write or verification failure"| F
    DB -->|"FAIL or ledger failure"| F
    DB -->|"PASS: dependency gate satisfied"| N
    DB -->|"evidence for final acceptance"| SG
    SG -->|"domain-correct; accuracy may be worse"| C
    SG -->|"invalid premise, defect or metric fitting"| X
```

A durable `PASS` establishes the configured command/evidence checks, not scientific
truth or automatic commit permission. The review command must wait for the actual
independent verdict and fail on unresolved required findings. The supervisor still
rejects metric fitting and preserves domain-correct features even if accuracy does not
improve. Phase JSONL reports and `index.md` explain the result; they do not replace the
SQLite execution ledger and sealed receipts. The scheduler admits dependent work after
a durable `PASS`; it does not wait for a later chat verdict. If parent acceptance is
required before that work, encode it in an enforced review or prerequisite phase command.
`dependsOn` alone proves neither domain correctness nor that a consumer loaded the right
producer artifact.

Launch only the approved plan, using absolute paths:

```sh
node "$HOME/.pi/agent/scripts/durable-loop/runner.mjs" run \
  /absolute/private/run-dir /absolute/approved-plan.json
```

### Recover the same run after interruption or compaction

Nunc retains the goal, remaining acceptance conditions, exact run/plan/worktree paths,
artifact identities and last observed status. That status is a dated observation, not
permission to repeat work. After resuming the supervisor, inspect the live workers,
ledger, receipts and recorded process identities before acting.

```mermaid
flowchart TD
    R["Resume project session<br/>Nunc supplies run and plan pointers"]
    I["Inspect supervisor lock, live workers<br/>ledger, receipts and process identities"]
    L{"Old supervisor still live?"}
    H["Keep the existing supervisor<br/>do not unlock or start another"]
    U["If stale, documented unlock<br/>run the same directory and original plan<br/>original deadline remains"]
    E{"Persisted evidence"}
    M["Monitor the existing live worker"]
    V["Verify sealed exits, receipts and artifacts"]
    A["Resume only eligible unfinished work<br/>never replay a completed phase"]
    F["Stop and reconcile<br/>preserve uncertainty or failure, no blind relaunch"]
    R --> I --> L
    L -->|"yes"| H
    L -->|"confirmed stopped"| U --> E
    E -->|"existing worker"| M
    E -->|"completed phase"| V
    E -->|"uncertain launch, missing exit or failed phase"| F
    M -->|"actual exit evidence"| V
    M -->|"worker lost or deadline exhausted"| F
    V -->|"required gates pass"| A
    V -->|"invalid or failed evidence"| F
```

If the old supervisor is confirmed stopped and its lock remains, use the documented
`unlock` command, then `run` with the **same run directory and original plan**. Existing
workers may survive the supervisor; the scheduler advances only while running. Keep a
long-lived supervisor under a terminal or service manager when unattended operation is
required. Downtime still counts against the persisted deadline.

Missing exits, uncertain launches, failed receipts or failed phases never authorize a
blind relaunch. Preserve the failed run and use a separately authorized, budgeted
correction plan/run instead of clearing markers or editing sealed artifacts. The
conceptual one-rework allowance above is not permission to retry a failed durable phase
in place. Resuming chat does not restart commands, reset deadlines or extend authority.

Implementation and full recovery contract:
[`durable-loop/README.md`](../../../scripts/durable-loop/README.md).
