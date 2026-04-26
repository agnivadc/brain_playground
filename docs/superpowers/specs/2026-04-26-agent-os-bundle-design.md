---
title: Agent OS Bundle Design
date: 2026-04-26
status: draft
version: v1
constitution-version: v1
---

# Agent OS Bundle Design

## Purpose

Design a bundleable, harness-agnostic Agent OS system that allows a user to take deterministic control of an agentic coding loop across different harnesses (Claude Code, GitHub Copilot, OpenAI Codex, and others).

This document is a design spec. It defines structure, responsibilities, and constraints — not implementation code.

---

## Governing Constraint

All design decisions in this document are subordinate to `AGENT_OS_CONSTITUTION.md`. If any section of this document conflicts with the constitution, the constitution governs.

---

## Packaging Model

### Layer Hierarchy

```
Level 0 — The System
  AGENT_OS_CONSTITUTION.md
  Single canonical file. Harness-agnostic. Sole source of execution authority.

Level 1 — Invocation Layer
  One adapter file per harness.
  Each adapter attempts to invoke the constitution within its harness runtime.
  Non-authoritative. No content authority. Pointer only.
  If invocation fails: session is NOT ACTIVE. No fallback. No silent degradation.

Level 2 — Execution Layer (optional)
  Skills, agents, protocols, commands.
  Subordinate to the constitution. Modular and removable.
  Removal does not invalidate session.

Level 3 — Memory Layer (optional)
  File-based or MCP-based. Data only. Non-authoritative.
  Removal does not invalidate session.
```

### Installation Invariant

| Condition | Session state |
|---|---|
| L0 missing | Agent OS cannot be attempted |
| L0 present, L1 missing | Agent OS cannot be attempted in this harness |
| L0 + L1 present, constitution successfully bound as governing authority | **Agent OS ACTIVE** |
| L0 + L1 present, binding fails for any reason | **Agent OS NOT ACTIVE** — declared explicitly and observably. Not inferred from behavior. |
| L2 / L3 absent | Session valid if binding succeeded |
| L2 / L3 conflict with L0 | Constitution governs. Conflicting artifact loses authority. |

### Ergonomic Layers (Non-Authoritative)

- **Template repo** — bundle pre-wired for new project creation. Not a source of authority.
- **Bootstrap script** — generates per-machine config (e.g., `.mcp.json`), copies adapters. Not a source of authority.

Installing L0 + L1 enables a session to **attempt** running Agent OS. Runtime validity is confirmed at session start, per harness, per execution. Installation does not guarantee validity.

### Three Usage Modes

| Mode | How | Who |
|---|---|---|
| Clone to project root | `git clone agent-os my-project` | Beginner |
| Git submodule | `git submodule add agent-os .agent-os` | Intermediate — existing project |
| GitHub template repo | "Use this template" on GitHub | Beginner — new project |

### Beginner Entry Path

Minimum valid installation: two files.

```
my-project/
├── AGENT_OS_CONSTITUTION.md
└── CLAUDE.md                 ← adapter for Claude Code
```

No execution layer. No memory layer. No bootstrap. If the constitution binds: Agent OS is active.

---

## Section 2: Constitution Layer

### Role

The constitution is the sole authoritative artifact. It functions as a runtime-checkable contract — a protocol handshake definition.

- Binding = successful handshake
- Failure = rejected handshake
- Ambiguity = invalid session

### Required Structural Blocks

#### [B1] Identity Block

**Contains:** system identifier (fixed, machine-readable string), version (semantic), canonical path declaration.

**Purpose:** enables equivalence comparison across environments. Two instances are the same system only if their identity blocks match.

**Enables:** binding condition C3 — identity mismatch = binding failure.

#### [B2] Authority Declaration

**Contains:** explicit statement that this document is the sole governing authority; precedence statement superseding all prompts, memory, tools, skills, agents, scripts, and config files; statement that adapters are non-authoritative.

**Purpose:** eliminates authority ambiguity when a harness reads multiple config files.

**Enables:** invalidation condition I3 — unresolved competing authority = binding failure.

#### [B3] Binding Conditions

**Contains:** numbered list of runtime-checkable conditions:

| ID | Condition | Check method |
|---|---|---|
| C1 | This file exists at its declared canonical path | File system check |
| C2 | This file is read in full before any execution begins | Enforced by output contract (B5) |
| C3 | Identity block matches expected system-id and version | String comparison |
| C4 | No conflicting governing document exists unresolved | Absence check |
| C5 | Harness produces required binding output before any other output | Observable output contract (B5) |

All five conditions must hold. Any single failure = binding fails. No partial binding.

#### [B4] Invalidation Conditions

**Contains:** numbered list of conditions that immediately invalidate the session:

| ID | Condition |
|---|---|
| I1 | This file cannot be located at its canonical path |
| I2 | This file is read partially, out of order, or after execution has begun |
| I3 | A conflicting authority source exists and has not been explicitly subordinated |
| I4 | The binding output (B5) was not produced, or was produced after other session output |
| I5 | Any subordinate layer modifies or overrides execution authority |
| I6 | The identity block is missing, malformed, or does not match the expected system |

Any I-condition fires → session is invalid → NOT ACTIVE output required immediately.

#### [B5] Observable Output Contract

**Purpose:** makes binding an observable event, not an internal state. Silence is not a valid failure mode.

**On successful binding — required fields (before any other output):**
```
AGENT_OS ACTIVE
system: <system-id>
version: <version>
constitution: <canonical path>
session-scope: <project root or declared scope>
memory-layer:
  file-based: available | unavailable
  mcp: available | unavailable | not configured
```

**On binding failure — required fields (before any other output):**
```
AGENT_OS NOT ACTIVE
reason: <which condition failed: C1–C5 or I1–I6>
detail: <what was missing or conflicting>
session: operating under no Agent OS authority
```

**Timing obligation:** both outputs appear before any other session output, tool call, or response.

#### [B6] Non-Authority Declaration

**Contains:** explicit list of artifact types that cannot hold execution authority:

- Prompts (system, user, injected)
- Memory (file-based, MCP-based, in-context)
- Tools and tool outputs
- Skills and agents
- Bootstrap scripts
- Template repos and scaffold files
- Other config files (including harness-specific adapter files)

Rule: if any artifact on this list conflicts with the constitution, the constitution governs. The conflicting artifact is data, not authority.

#### [B7] Violation Semantics

**Contains:** definition of a violation, consequences, and observable output obligation.

- **Violation:** any action by a subordinate layer that alters system identity, execution authority, truth precedence, or execution semantics without authorization from this document.
- **Consequence:** execution state loses validity immediately. All results, artifacts, and memory writes produced under invalid execution carry no system authority.
- **Output obligation:** violation must be declared observably — same format obligation as binding failure. A mid-session violation is not inferred from behavior.

---

## Section 3: Invocation Layer

### Adapter Responsibility

Each adapter does exactly three things:

1. Instruct the harness to read the constitution before any execution
2. Instruct the harness to produce NOT ACTIVE output if constitution cannot be bound
3. Defer all authority, rules, and execution semantics to the constitution

Any adapter content beyond these three is a violation — it introduces material that competes with constitution authority.

### Adapter Structure (Four Required Blocks)

```
[A1] Self-Declaration
  This file is non-authoritative.
  It does not define execution rules, policies, or system identity.
  It only attempts to invoke the governing contract.

[A2] Invocation Instruction
  Before any execution begins, read: <path to AGENT_OS_CONSTITUTION.md>
  The file at that path is the governing contract for this session.

[A3] Failure Instruction
  If the file at that path cannot be read, does not exist, or cannot be
  bound as the governing authority:
    → Do not proceed as Agent OS active
    → Produce the required NOT ACTIVE output immediately
    → Operate under no Agent OS authority

[A4] Deference
  If the file is successfully bound, follow its binding conditions,
  invalidation conditions, and output contract exactly.
  This file has no further instructions.
```

### Per-Harness Adapter Locations

| Harness | Adapter file |
|---|---|
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| OpenAI Codex | `AGENTS.md` |

Constitution path in A2: `./AGENT_OS_CONSTITUTION.md` (relative from project root). Adapter location varies. Invocation logic is identical across all adapters.

### Harness Capability Taxonomy

| Capability | Definition | Binding outcome |
|---|---|---|
| File-capable | Harness can read arbitrary files before responding | Binding attempt is possible |
| Context-only | Harness operates only on files explicitly provided in context | Binding requires user to provide constitution file contents explicitly. Otherwise: NOT ACTIVE. |
| Injection-only | Harness reads only its designated config file | A2 cannot be satisfied. Session is NOT ACTIVE. |

No capability tier silently degrades into an active session.

### Binding Attempt Sequence

```
1. Harness loads adapter → receives A1 (non-authoritative self-declaration)
2. Adapter A2 → harness attempts to read AGENT_OS_CONSTITUTION.md
     File found → proceed to 3
     File not found → go to 5 (failure)
3. Harness reads constitution in full, checks B3 conditions (C1–C5)
     All conditions met → proceed to 4
     Any condition fails → go to 5 (failure)
4. Harness produces binding success output (B5 format)
     → Session valid. Execution governed by constitution.
5. Harness produces binding failure output (B5 format)
     → Session invalid. No Agent OS execution.
```

Every path terminates in either an explicit ACTIVE or an explicit NOT ACTIVE. No middle state.

---

## Section 4: Execution Layer

### Role

Defines how work is done within a valid Agent OS session. Does not define what is authoritative, what is true, or what makes a session valid. Those are constitution concerns.

### Component Taxonomy

| Type | Role | Defines | Cannot Define |
|---|---|---|---|
| Skill | Reusable capability | Procedure steps, output formats, decision rules within scope | Session authority, truth precedence, execution validity |
| Agent | Role-scoped executor | Permitted actions, role boundary, scope of operation | Authority beyond declared scope |
| Protocol | Phase sequencing | Sequencing rules, phase gates, handoff formats | Completion criteria that override constitution validity |
| Command | User-triggered action | What action to perform when invoked | Session authority, harness behavior, execution semantics |

### Subordination Declaration (Required in Every Component)

```yaml
constitution: AGENT_OS_CONSTITUTION
conforms-to-version: v1.0.0
authority: none
conflict-resolution: constitution governs
scope: <explicit declaration of what this component operates on>
```

A component without this block is not part of Agent OS. It may be used standalone, but carries no Agent OS authority.

### Per-Component Required Structure

**Skills:**
```
[S1] Subordination Declaration
[S2] Scope: what this skill operates on
[S3] Invocation condition: when this skill is appropriate
[S4] Procedure: ordered steps
[S5] Output format: what this skill must produce
[S6] Termination: explicit completion condition
```

**Agents:**
```
[AG1] Subordination Declaration
[AG2] Role: one sentence, no authority language
[AG3] Permitted actions: explicit list
[AG4] Forbidden actions: explicit list
[AG5] Scope boundary: cannot expand beyond declared scope
[AG6] Handoff format: what this agent produces at completion
```

**Protocols:**
```
[P1] Subordination Declaration
[P2] Phase sequence: ordered phases with entry and exit conditions
[P3] Gate definitions: conditions required before phase transition
[P4] Handoff artifact format: what each phase must produce
[P5] Failure behavior: what happens when a gate condition is not met
```

**Commands:**
```
[C1] Subordination Declaration
[C2] Invocation syntax
[C3] Action: what the command does
[C4] Scope: permitted reads and writes
[C5] Output: what the command must produce
```

### Modularity Rules

- Components are loaded on demand, not at session start
- Loading a component does not alter session state
- Adding or removing a component does not affect constitution binding
- A protocol referencing a removed component fails at its gate condition — explicit, not silent

### Drift Prevention

- **Version pinning:** each component declares `conforms-to-version`. Mismatch after constitution update = component is suspect, must be reviewed before use.
- **Scope discipline:** scope declarations use bounded language. Unbounded scope language ("applies always", "operates across the project") is a design violation.
- **Conflict resolution:** if two skills conflict, neither resolves the conflict. User decides. If a skill conflicts with the constitution, constitution governs.

---

## Section 5: Memory Layer

### Role

Persistent state that survives across sessions. Non-authoritative. Not required for session validity.

A session with no memory is identical in authority to a session with full memory.

### Two Modalities

| Modality | Mechanism | Harness requirement | External dependency |
|---|---|---|---|
| File-based | Markdown files in `memory/` | Any file-capable harness | None |
| MCP-based | `brain_write` / `brain_query` via local server | MCP-capable harness + running server | `uvx`, `.mcp.json`, local process |

### Optionality

| Configuration | Session validity | Memory availability |
|---|---|---|
| No memory layer | Valid | None |
| File-based only | Valid | File-based reads/writes |
| MCP-based, server running | Valid | MCP tools available |
| MCP-based, server not running | Valid | MCP tools unavailable — declared in binding output, not silent |
| Both modalities | Valid | Both available |

MCP tool unavailability is not a session failure. The session is Agent OS ACTIVE. Memory layer status is declared in the B5 binding output.

### Memory Validity Rules

1. **Session gate:** memory may only be written during a valid session (binding confirmed). Writes before binding confirmation violate B7.
2. **Data ceiling:** memory content cannot instruct the harness to override the constitution, expand scope, or grant authority. Such entries are data; the attempted instruction has no effect.
3. **Conflict resolution:** memory vs. constitution → constitution governs. Memory vs. execution layer → skill procedure applies within its scope; memory is contextual input to that procedure, not an override. Discrepancy is surfaced to the user. Memory vs. memory → neither is authoritative; user resolves or conflict is declared.
4. **No authority from age:** older memory entries do not become authoritative over time.

### File-Based Memory Structure

```
memory/
├── MEMORY.md       ← index
├── user/           ← user profile, preferences
├── project/        ← project-specific knowledge
├── feedback/       ← observations and pattern-level feedback
└── reference/      ← pointers to external resources
```

### MCP-Based Memory Structure

```
.mcp.json.template          ← template; per-machine .mcp.json gitignored
.mcp.json                   ← generated by bootstrap (gitignored)
data_store/
├── knowledge.jsonl         ← canonical export, committed
└── knowledge.db            ← local SQLite, gitignored, rebuilt from JSONL
```

MCP server runs locally via `uvx`. DB path is project-scoped (absolute path). Global DBs shared across projects are not permitted — they create an implicit cross-project authority surface.

---

## Section 6: Full Bundle Structure

### Directory Layout

```
agent-os/
│
│  ── Layer 0: Constitution ──────────────────────────────────────
│
├── AGENT_OS_CONSTITUTION.md
│
│  ── Layer 1: Invocation ────────────────────────────────────────
│
├── CLAUDE.md
├── AGENTS.md
├── .github/
│   └── copilot-instructions.md
│
│  ── Layer 2: Execution ─────────────────────────────────────────
│
├── execution/
│   ├── skills/
│   │   ├── brainstorming/SKILL.md
│   │   ├── tdd/SKILL.md
│   │   ├── debugging/SKILL.md
│   │   ├── planning/SKILL.md
│   │   ├── review/SKILL.md
│   │   └── spec-writing/SKILL.md
│   ├── agents/
│   │   ├── design.agent.md
│   │   ├── implementation.agent.md
│   │   └── review.agent.md
│   ├── protocols/
│   │   ├── handoff.md
│   │   ├── verification-gate.md
│   │   └── context-packet.md
│   └── commands/
│
│  ── Layer 3: Memory ────────────────────────────────────────────
│
├── memory/
│   ├── MEMORY.md
│   ├── user/
│   ├── project/
│   ├── feedback/
│   └── reference/
│
├── .mcp.json.template
├── .mcp.json                 ← gitignored
├── data_store/
│   ├── knowledge.jsonl
│   └── knowledge.db          ← gitignored
│
│  ── Ergonomic (non-authoritative) ──────────────────────────────
│
├── bootstrap/
│   ├── bootstrap.sh
│   └── bootstrap.ps1
│
└── docs/
    └── specs/
```

### Mapping Existing Artifacts

| Existing artifact | Destination | Change required |
|---|---|---|
| `AGENT_OS_CONSTITUTION.md` | Root — unchanged | Add B3–B7 structural blocks |
| Obsidian Vault `skills/` | `execution/skills/` | Add S1 subordination declaration to each |
| Obsidian Vault `agents/` | `execution/agents/` | Add AG1 subordination declaration + explicit scope bounds |
| Obsidian Vault `protocols/` | `execution/protocols/` | Add P1 subordination declaration |
| Obsidian Vault `copilot-instructions.md` | **Split:** workflow rules → `execution/skills/` and `execution/protocols/`; adapter file → `.github/copilot-instructions.md` (A1–A4 only) | Significant restructure — adapter replaces full file |
| `brain_playground` MCP setup | `data_store/` + `.mcp.json.template` | No structural change |
| `brain_playground/CLAUDE.md` | Brain guidance → relevant execution skills | Adapter file replaced with A1–A4 only |
| `~/.claude/projects/.../memory/` | `memory/` | Move to project scope or keep global and reference by path |

### Authority Chain at Runtime

```
Harness starts
  → Reads adapter [L1] — non-authoritative, attempts invocation
  → Reads AGENT_OS_CONSTITUTION.md [L0] — binds if B3 conditions met
  → Produces binding output [B5] — ACTIVE or NOT ACTIVE, before anything else

If ACTIVE:
  → Execution layer [L2] available on demand — subordinate, modular
  → Memory layer [L3] available if configured — data only
  → Session proceeds under constitution authority
  → Any violation → B7 fires → observable violation output → session invalid
```

### System Identity Across Environments

- Two machines run the same system if and only if `AGENT_OS_CONSTITUTION.md` is identical (B1 identity block matches, same version).
- Each execution layer artifact declares `conforms-to-version`. Version mismatch after a constitution update = artifact is suspect.
- Git history is the audit trail for constitution changes and component re-validation.

---

## Open Questions (for implementation planning)

1. **Constitution content:** B3–B7 blocks are structurally defined here but not yet written as full content. Constitution content design is the first implementation task.
2. **Adapter content:** A1–A4 block structure is defined. Exact wording for each harness adapter needs to be written.
3. **Subordination declaration migration:** each existing Obsidian Vault skill/agent/protocol needs the subordination declaration block added. This is mechanical but requires touching every file.
4. **Copilot adapter migration:** the current `copilot-instructions.md` is a full workflow document. Splitting it into adapter (4 blocks) + execution layer components is the highest-effort migration task.
5. **Memory scoping decision:** current Claude memory lives at `~/.claude/projects/...`. Decision needed: move to project-scoped `memory/` directory, or keep global and reference by absolute path from the constitution.
6. **MCP bootstrap on new machine:** `bootstrap.sh` needs to handle the case where `uvx` is not installed. Failure must be observable (NOT ACTIVE for MCP layer), not silent.
