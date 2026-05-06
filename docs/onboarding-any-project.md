# Onboarding agent-os + brain to your own repo

This guide is harness-agnostic where possible. You're adding two things:

1. **Brain** — a persistent memory layer (SQLite DB + CLI + MCP server).
   Lives at [`agnivadc/knowledge-brain`](https://github.com/agnivadc/knowledge-brain).
2. **agent-os v1.1.0** — a Pi extension that wraps your dev loop in
   `/grill /plan /run /verify /remember /status /doctor`. Lives at
   [`algoSiliguri/Agent_OS`](https://github.com/algoSiliguri/Agent_OS),
   pinned at the `v1.1.0` tag.

You can install one or both. Brain works without agent-os; agent-os works
without brain (it'll queue captures to a local `pending-captures.yaml`
when brain is unavailable). Both is the intended pairing.

## Decision: which harness?

The harness is the program you actually type into:

- **Pi** — `npm install -g @mariozechner/pi-coding-agent`. **Required for
  agent-os CCP** — it's a Pi extension. Pi calls Claude (the LLM) under the
  hood via the Anthropic API.
- **Claude Code** — Anthropic's official CLI. Can talk to brain via MCP, but
  cannot run agent-os v1.1 (no Claude Code adapter shipped yet).

If you want CCP slash commands, you need Pi. If you only want brain
tool-use inside chat, either harness works.

## Step 1 — Brain (always do this first)

### 1a. Install the brain CLI globally

This puts both `brain` and `brain-mcp` on your PATH:

```bash
uv tool install --from git+https://github.com/agnivadc/knowledge-brain.git knowledge-brain
```

Requires [`uv`](https://docs.astral.sh/uv/getting-started/installation/).
Verify with `brain --help` afterwards.

### 1b. Initialise a DB

Either global (recommended for cross-project recall) or project-local:

```bash
# global
brain --db-path ~/.knowledge-brain/knowledge.db init
export BRAIN_DB_PATH="$HOME/.knowledge-brain/knowledge.db"

# OR project-local
mkdir -p data_store
brain --db-path data_store/knowledge.db init
export BRAIN_DB_PATH="/absolute/path/to/data_store/knowledge.db"
```

Add the `export` to your shell profile (`~/.zshrc`, `~/.bashrc`, or
PowerShell `$PROFILE`) so every new shell sees it.

### 1c. (Optional) Wire brain as MCP for chat-style use

If you want `brain_query` and `brain_write` as native tools in your AI
conversation, add `.mcp.json` at your repo root:

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

Both Pi and Claude Code read `.mcp.json` and prompt to approve the server
on first start. Use absolute paths.

## Step 2 — Agent-OS CCP (Pi only)

### 2a. Install Pi

```bash
npm install -g @mariozechner/pi-coding-agent
export ANTHROPIC_API_KEY=sk-ant-...
```

### 2b. Install agent-os v1.1.0 as a Pi extension

```bash
pi install git:github.com/algoSiliguri/Agent_OS@v1.1.0
```

The `@v1.1.0` suffix pins to that exact tag. Future bug-fix releases will
ship as new tags; bump the suffix when you want those.

### 2c. Initialize your project

In Pi, run `/init` to fetch governance files from the v1.1.0 tag, render
`.agent-os/project.yaml`, and install the brain CLI if needed:

```
> /init <project-id> --domain <domain> [--critical-actions a,b]
```

For example:
```
> /init my-project --domain trading-research --critical-actions trade_execute
```

`/init` handles fetching governance files as raw bytes so content-hashes
stay valid. See the [Agent OS README](https://github.com/algoSiliguri/Agent_OS#initialize-a-project)
for the full flag reference.

The rendered `.agent-os/project.yaml` looks like:

```yaml
project_id: my-project
domain_type: general
runtime_version: 0.1.x
memory_namespace: my-project
verification_profile: default
critical_actions: []
workspace:
  root: /absolute/path/to/your/project

trust_registry:
  pi_packages:
    - package: "@agnivadc/agent-os"
      trust: trusted
```

The `workspace.root` should be the absolute path of your repo. Run `/init` to
render `project.yaml` with the correct per-checkout absolute path.

### 2d. Tell agent-os where the brain DB lives

```bash
export BRAIN_DB_PATH="/absolute/path/to/data_store/knowledge.db"
```

(Or point at the global DB from Step 1b.) Without this, `/remember`
queues captures locally to
`.agent-os/tasks/<task>/pending-captures.yaml` and reports them as
deferred in the artifact.

## Step 3 — Verify

Inside Pi, type:

```
/doctor
```

If everything's wired you see `status: ok` and a list of green checks.
If anything's wrong, the failing line tells you which check (B0 binding
header, B1 schema-presence, B5 binding-event, etc.).

## Step 4 — Smoke test the loop

```
/grill <one-line description of the work you want to do>
/plan
/run
/verify
/remember
/status
```

Expect minor friction the first time through. The v1 default `/grill`
question generator is template-driven (7 fixed questions); the v1 default
`/plan` drafter produces a single-step plan; `/run`'s step executor is
Pi-agent-backed but the prompt is minimal. These are deliberately shallow
defaults that the v1.x roadmap upgrades to LLM-backed implementations.

## What lands on disk

```
your-repo/
├── AGENT_OS_CONSTITUTION.md          (vendored from agent-os tag)
├── .agent-os/
│   ├── project.yaml                  bind config (you write this)
│   ├── schemas/                      vendored from agent-os tag
│   ├── contracts/                    vendored from agent-os tag
│   ├── runtime/
│   │   ├── events.jsonl              truth log (append-only)
│   │   ├── session.json              snapshot of session state
│   │   └── projection.db             SQLite projection rebuilt from events.jsonl
│   └── tasks/
│       └── T-001/
│           ├── state.json
│           ├── grill.yaml | plan.yaml | execution.yaml | verification.yaml | knowledge.yaml
│           ├── pending-captures.yaml (only if brain was unavailable)
│           └── raw/<hash>.txt        compressed-output backing store
└── data_store/
    ├── knowledge.jsonl               brain export (commit this)
    └── knowledge.db                  brain DB (do not commit)
```

What to gitignore:

```
.agent-os/runtime/
.agent-os/tasks/
.agent-os/project.yaml          # has absolute path
.agent-os/schemas/              # fetched per-tag; not committed
.agent-os/contracts/            # fetched per-tag; not committed
AGENT_OS_CONSTITUTION.md        # fetched per-tag; not committed
data_store/*.db
data_store/*.db-journal
data_store/*.db-shm
data_store/*.db-wal
.mcp.json
```

What to commit:

- `data_store/knowledge.jsonl` (brain content, collaboratively shared)

## Upgrading agent-os

Uninstall the old extension, install the new tag, then re-run `/init` to
refresh the vendored governance files.

```bash
pi uninstall @agnivadc/agent-os
pi install git:github.com/algoSiliguri/Agent_OS@v1.1.0
# then in Pi: /init <project-id> --domain <domain> ...
```

If the constitution version changed (e.g. `v2 → v3`), `/doctor` hard-fails
until the bind config is also updated. Read the agent-os release notes for
that version's migration guide.

## Troubleshooting

- **`/doctor` reports `B0 hard_fail`** — content-hash mismatch. Almost
  always a line-ending issue. Re-fetch with `curl -o` (don't run files
  through editors or formatters that normalise CRLF/LF).
- **`/doctor` reports `B5 hard_fail`** — no `BINDING` event in
  `.agent-os/runtime/events.jsonl`. The first slash command after install
  emits one; if you see this on a fresh install, run any read-only command
  (e.g. `/status`) to trigger binding.
- **`/remember` always shows `brain_status: deferred`** — `BRAIN_DB_PATH`
  isn't set or `brain` isn't on PATH. Verify with `which brain` (Unix) or
  `Get-Command brain` (PowerShell), and `echo $BRAIN_DB_PATH`.
- **Pi can't find the extension** — `pi list` should show the
  agent-os extension. If not, re-run
  `pi install git:github.com/algoSiliguri/Agent_OS@v1.1.0`.

## References

- [agent-os Section-16 walkthrough](https://github.com/algoSiliguri/Agent_OS/blob/v1.1.0/docs/demo/section-16-walkthrough.md)
- [agent-os CONTEXT.md](https://github.com/algoSiliguri/Agent_OS/blob/v1.1.0/CONTEXT.md) (domain glossary)
- [knowledge-brain README](https://github.com/agnivadc/knowledge-brain)
- [Pi coding agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent)
