# brain_playground

A reference project that shows how Agent OS works in practice.

This repo is a **consumer** of the Agent OS control plane. It does not contain any runtime code — it contains the configuration, manifests, and documents that make a project Agent-OS-ready. Think of it as a working example you can look at, copy from, or experiment with.

---

## What this repo demonstrates

- How to declare a project's identity and rules in `.agent-os.yaml`
- How to set critical actions that require human approval before the AI can run them
- How memory scoping works (this project reads global memory but cannot write to it)
- The full Agent OS bundle structure: constitution, manifest, event log, lock file

---

## Prerequisites

To run this project you need:

1. **Python 3.12+** — check with `python3 --version`
2. **uv** — install with: `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **context_os** — the Agent OS runtime (see setup below)

---

## Setup

### Step 1 — Install the Agent OS runtime

```bash
# Clone context_os (the control plane) somewhere on your machine
git clone https://github.com/algoSiliguri/context_os.git ~/agent-os
cd ~/agent-os
uv sync
```

### Step 2 — Set up global memory (one-time)

```bash
uvx --from git+https://github.com/agnivadc/knowledge-brain.git \
  brain --db-path ~/.knowledge-brain/knowledge.db init

# Add this to your shell profile (~/.zshrc or ~/.bashrc)
export BRAIN_DB_PATH="$HOME/.knowledge-brain/knowledge.db"
```

### Step 3 — Bind this project

```bash
# From the brain_playground directory
cd /path/to/brain_playground

uv --directory ~/agent-os run context-os bind
```

Expected output:
```
BINDING ACTIVE
session_id: ...
project_id: brain-playground
conditions_verified: C1 C2 C3 C4 C5 C6 C7 C8 C11
```

If it says `NOT_ACTIVE`, run the doctor to see what's wrong:
```bash
uv --directory ~/agent-os run context-os doctor
```

---

## How this project is configured

The manifest file `.agent-os.yaml` declares everything Agent OS needs to know about this project:

```yaml
project_id: brain-playground
domain_type: trading-research
runtime_version: 0.1.x
memory_namespace: brain-playground
verification_profile: production
global_memory_read: true
global_memory_write: false        # reads global memory but cannot write to it
critical_actions:
  - trade_execute                 # must be approved before any trade executes
  - global_memory_write           # must be approved before writing to global memory
```

**Critical actions** are operations that require explicit human approval before the AI can run them. When the AI requests a critical action, it is held in a pending queue. You approve or deny it with:

```bash
# Approve a pending action
uv --directory ~/agent-os run context-os approve <action-hash>

# Deny a pending action
uv --directory ~/agent-os run context-os deny <action-hash> --reason "not now"
```

---

## Checking session state

```bash
# Current snapshot
uv --directory ~/agent-os run context-os status

# Live view that refreshes automatically
uv --directory ~/agent-os run context-os status --watch
```

The status view shows:
- Whether the session is `ACTIVE` or `NOT_ACTIVE`
- Any pending actions waiting for approval
- Memory route (which database is in use)
- Recent events

---

## What each file does

| File | Purpose |
|---|---|
| `.agent-os.yaml` | Project manifest — identity, memory scope, critical actions |
| `AGENTS.md` | Instructions for AI assistants (read by Codex, Pi) |
| `CLAUDE.md` | Instructions for Claude Code specifically |
| `data_store/` | Project-local data storage |
| `docs/design/` | Design documents for this project and the broader Agent OS system |
| `docs/strategies/` | Domain-specific strategy documents (trading research context) |
| `docs/decisions/` | Architecture decision records |
| `scripts/sync.sh` | Helper script for syncing data |
| `config/` | Configuration files |

---

## Using this as a template for your own project

To make your own project Agent-OS-ready:

1. Copy `.agent-os.yaml` to your project root and fill in your `project_id`, `domain_type`, and `critical_actions`.
2. Copy `AGENTS.md` and `CLAUDE.md` to your project root (they just point at the Agent OS constitution — no changes needed).
3. Run `context-os bind` from your project directory.

That's it. The AI will now declare itself `ACTIVE` or `NOT_ACTIVE` at the start of every session, and critical actions will require your approval.

---

## Related repos

- [context_os](https://github.com/algoSiliguri/context_os) — the Agent OS runtime (bind, status, doctor, approve, deny)
- [knowledge-brain](https://github.com/agnivadc/knowledge-brain) — the persistent memory layer
