# The loop, visually

The scaffold in one sentence: a supervisor in the main context window works a bounded
goal through **N phases**; each phase is one hypothesis implemented by an **implement
subagent** and independently checked by a **review subagent**; the supervisor gates the
result and commits when the phase is *semantically* right, whatever the numbers say.

Mermaid source — renders in GitHub, your nvim Markdown preview, or any Mermaid renderer.

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

    P1 --> I1["Implement subagent — frontier tier, end to end<br/>writes it, runs it, fixes its own bugs<br/>own worktree, one writer"]
    I1 --> R1["Review subagent — fresh context, other model family<br/>flash tier — frontier low if sensitive<br/>diff · boundary cases · re-runs the checks"]
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
    S["Supervisor — main context window<br/>preflight: disjoint file scopes · one worktree per lane · max 4 lanes"]

    S --> L1["Lane 1 — own worktree"]
    S --> L2["Lane 2 — own worktree"]
    S --> L3["Lane 3 — own worktree"]
    S --> L4["Lane 4 — own worktree"]

    L1 --> I1["Implement 1"]
    L2 --> I2["Implement 2"]
    L3 --> I3["Implement 3"]
    L4 --> I4["Implement 4"]
    I1 --> R1["Review 1"]
    I2 --> R2["Review 2"]
    I3 --> R3["Review 3"]
    I4 --> R4["Review 4"]

    R1 -->|"verdict + lane commit"| G["Supervisor gates and integrates<br/>one lane at a time — COMMIT-* only"]
    R2 --> G
    R3 --> G
    R4 --> G
    G -->|"next batch — same supervisor"| S
    G --> LG["Log per lane in logs/ — structured only<br/>artifacts + sha256 · commit shas · index.md regenerated"]

    classDef supervisor fill:#3d2f5c,stroke:#a855f7,stroke-width:3px,color:#fff
    classDef neutral fill:#243b55,stroke:#123,color:#fff
    class S,G supervisor
    class L1,L2,L3,L4,I1,I2,I3,I4,R1,R2,R3,R4,LG neutral
    %% Purple edges: lane dispatch, verdict return, next-batch loop-back to the same supervisor.
    linkStyle 0,1,2,3,12,13,14,15,16 stroke:#a855f7,stroke-width:2px,color:#c4b5fd
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
