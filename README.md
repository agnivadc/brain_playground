> **This is an integration lab, not a starter template.**
> For first-time setup: [agnivadc/agent-os-starter](https://github.com/agnivadc/agent-os-starter)

# brain_playground

A reference project that shows how Agent OS works in practice.

This repo is a **consumer** of the Agent OS control plane. It does not contain runtime code — it contains the configuration, manifests, and documents that make a project Agent-OS-ready. Think of it as a working example you can look at, copy from, or experiment with.

Agent OS shipped its first tagged release as **v1.1.0** (2026-05-05). It now lives at [`algoSiliguri/Agent_OS`](https://github.com/algoSiliguri/Agent_OS) (renamed from `context_os` on 2026-05-04) and ships as a TypeScript Pi extension. The Python `context-os` CLI from the v3 era no longer exists.

---

## What this repo demonstrates

- How to declare a project's identity and rules in `.agent-os/project.yaml`
- How to set critical actions that document operations needing human approval
- How memory scoping works (this project reads global memory but won't pollute it with project-local writes by default)
- The full Agent OS bundle structure: constitution, manifest, schemas, contracts, event log
- **Two interchangeable harnesses** against the same brain DB:
  - **Claude Code** with brain via MCP — chat-style brain queries (`brain_query`, `brain_write`)
  - **Pi** with the agent-os v1.1.0 extension — structured slash commands (`/grill /plan /run /verify /remember /status /doctor`)

Both setups can coexist on the same checkout. They're different transports to the same DB.

---

## Prerequisites

Common (both setups):

- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) — for the brain CLI install
- `git`, plus `curl` and either `bash` or `pwsh` — for bootstraps
- The brain CLI itself, installed once per machine:
  ```bash
  uv tool install --from git+https://github.com/agnivadc/knowledge-brain.git knowledge-brain
  ```

For Setup A only:
- [Claude Code](https://www.claude.com/product/claude-code)

For Setup B only:
- Node.js ≥20 (for `npm`)
- The Pi coding agent: `npm install -g @mariozechner/pi-coding-agent`
- An LLM API key for whichever provider Pi will use — `ANTHROPIC_API_KEY` (Claude), `OPENAI_API_KEY` (GPT), `GOOGLE_API_KEY` (Gemini), or any custom/local model. See the [Agent OS README's "Pick a model in Pi"](https://github.com/algoSiliguri/Agent_OS#pick-a-model-in-pi) section for the full provider list and `pi /login` interactive setup.

---

## Setup A — Brain via MCP (Claude Code)

The brain is reachable from Claude Code as MCP tools (`brain_query`, `brain_write`).

### A1 — initialise a brain DB

You can use either a project-local DB or your global one (recommended for cross-project recall):

```bash
brain --db-path ~/.knowledge-brain/knowledge.db init
export BRAIN_DB_PATH="$HOME/.knowledge-brain/knowledge.db"
```

Add the `export` to your shell profile so every new shell sees it.

### A2 — wire MCP

Render `.mcp.json` from the template (or write it manually):

```json
{
  "mcpServers": {
    "knowledge-brain": {
      "command": "brain-mcp",
      "env": {
        "BRAIN_DB_PATH": "/absolute/path/to/your/knowledge.db"
      }
    }
  }
}
```

Use absolute paths — Claude Code may launch from a different working directory.

### A3 — open Claude Code

```bash
claude
```

Claude Code reads `.mcp.json` and prompts to approve the `knowledge-brain` server. Approve. From that point, `brain_write` and `brain_query` are available as tools.

### Things to ask Claude

These exercise different brain behaviours:

1. *"What do we know about MES Supertrend's backtest performance?"* → `brain_query`
2. *"Save this to brain: I noticed risk vetoes spike during Fed announcements. Tags: empirical, risk."* → `brain_write`
3. Open a new Claude session and ask about Fed announcements again → cross-session recall.

---

## Setup B — Agent-OS CCP (Pi)

The structured loop: Pi loads agent-os v1.1.0 as an extension; seven slash commands walk a feature through grill → plan → run → verify → remember.

### B1 — install agent-os

```bash
pi install git:github.com/algoSiliguri/Agent_OS@v1.1.0
```

### B2 — initialize this project

```bash
pi
```

In Pi:
```
> /init brain-playground --domain trading-research --critical-actions trade_execute,global_memory_write
```

`/init` installs the brain CLI if needed, copies bundled governance files, and renders `.agent-os/project.yaml`. See the [Agent OS README](https://github.com/algoSiliguri/Agent_OS#initialize-a-project) for details and flag reference.

### B3 — export `BRAIN_DB_PATH`

Recommended: point at the same global DB Setup A uses, so all captures land in one place.

**macOS / Linux (bash, zsh):**
```bash
export BRAIN_DB_PATH="$HOME/.knowledge-brain/knowledge.db"
```

**Windows (PowerShell):**
```powershell
$env:BRAIN_DB_PATH = "$HOME\.knowledge-brain\knowledge.db"
```

To persist across shells, add the line to your shell rc file (`~/.zshrc`, `~/.bashrc`) on macOS/Linux, or use `[System.Environment]::SetEnvironmentVariable('BRAIN_DB_PATH', ..., 'User')` on Windows.

### B4 — verify

```
> /doctor
```

If everything is wired correctly, `/doctor` reports `status: ok`. If not, the failing line tells you which check.

### B5 — walk the loop

```
> /grill add a smoke-test feature to the playground
> /plan
> /run
> /verify
> /remember
> /status
```

Artifacts land under `.agent-os/tasks/T-001/` (`grill.yaml`, `plan.yaml`, `execution.yaml`, `verification.yaml`, `knowledge.yaml`). Truth log at `.agent-os/runtime/events.jsonl`.

For a per-step transcript with expected events, see [the Section-16 walkthrough in the agent-os repo](https://github.com/algoSiliguri/Agent_OS/blob/v1.1.0/docs/demo/section-16-walkthrough.md).

---

## How this project is configured

The rendered `.agent-os/project.yaml` (written by `/init`) declares everything Agent OS needs to know:

```yaml
project_id: brain-playground
domain_type: trading-research
runtime_version: 0.1.x
memory_namespace: brain-playground
verification_profile: production
critical_actions:
  - trade_execute
  - global_memory_write
workspace:
  root: <absolute path to this checkout>

memory_policy:
  global_memory_read: true
  global_memory_write: false

trust_registry:
  pi_packages:
    - package: "@agnivadc/agent-os"
      trust: trusted
```

**Critical actions** document operations that should require human approval. v1.1.0's policy module (`src/ccp/policy/`) gates each `tool_call` against the 4-tier permission ladder. Tier-3 calls re-prompt every time; tier-4 calls are blocked unless `break_glass.enabled` is set.

**Memory policy** fields document this project's *intent*. v1.1.0 doesn't enforce them (`/remember` writes go wherever `BRAIN_DB_PATH` points), but they're committed for future agent-os releases that gate brain writes by manifest policy.

---

## What each file does

| File / dir | Purpose |
|---|---|
| `.agent-os/project.yaml` | Rendered per machine by `/init` (gitignored — has absolute path) |
| `.agent-os/{runtime,tasks,schemas,contracts}/` | Per-machine state + fetched governance (gitignored) |
| `AGENT_OS_CONSTITUTION.md` | Fetched from agent-os v1.1.0 tag by `/init` (gitignored) |
| `AGENTS.md` / `CLAUDE.md` / `.github/copilot-instructions.md` | Capability declarations per harness — each defers to the constitution |
| `docs/architecture/consumer-runtime.md` | Notes on this repo as a v1.1.0 consumer |
| `docs/design/` | Design history (v3 Python era, pre-v1.0.0 TS rewrite) |
| `docs/onboarding-any-project.md` | How to add agent-os + brain to your own repo |
| `data_store/knowledge.jsonl` | Project-scoped brain export (committed, line-oriented) |
| `data_store/knowledge.db` | Project-scoped brain DB (gitignored, optional — defaults to global) |
| `scripts/sync.{sh,ps1}` | Sync helpers between brain DB and committed JSONL |

---

## Adding agent-os + brain to your own repo

This playground is one example. To add the same wiring to any other repo, see [`docs/onboarding-any-project.md`](docs/onboarding-any-project.md).

---

## Related repos

- [Agent_OS](https://github.com/algoSiliguri/Agent_OS) — the agent-os runtime + Pi extension (currently `v1.1.0`)
- [knowledge-brain](https://github.com/agnivadc/knowledge-brain) — the persistent memory layer
- [pi-mono](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) — the Pi harness
