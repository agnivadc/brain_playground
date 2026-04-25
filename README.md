# Trading Playground

A synthetic trading-system repo wired to the [Knowledge
Brain](https://github.com/agnivadc/knowledge-brain) so you can feel how the
brain works inside a real project context.

The code here is intentionally thin — stubs, docs, and config that *look*
like a trading system. The interesting thing is the **brain wiring** and the
**seeded knowledge** that mirrors what the Brain accumulates over time.

## Layout

```
trading-playground/
├── .mcp.json.template       Template for project-scoped MCP server config
├── .mcp.json                Generated per-machine by bootstrap (gitignored)
├── docs/
│   ├── strategies/          Strategy specifications (Layer 2)
│   ├── architecture/        Engine and risk design (Layer 2)
│   └── decisions/           ADR-style design decisions (Layer 2)
├── config/                  Strategy + risk YAML (Layer 2 → Layer 3)
├── scripts/
│   ├── bootstrap.{ps1,sh}   One-shot setup (Windows / macOS / Linux)
│   └── sync.{ps1,sh}        Move knowledge between local DB and the JSONL
└── data_store/
    ├── knowledge.jsonl      Source of truth, committed and shared (LFR-style)
    └── knowledge.db         Local SQLite, rebuilt from the JSONL (gitignored)
```

## Setup (one time)

**Prerequisites:**

- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) on PATH
- [Claude Code](https://www.claude.com/product/claude-code) installed
- `git` for cloning this repo

**Steps:**

```bash
git clone https://github.com/agnivadc/brain_playground.git
cd brain_playground
```

Then run the bootstrap for your platform:

```powershell
# Windows
pwsh scripts/bootstrap.ps1
```

```bash
# macOS / Linux
bash scripts/bootstrap.sh
```

The bootstrap:

1. Verifies `uv` is installed
2. Generates `.mcp.json` with an absolute `BRAIN_DB_PATH` for your machine
3. Imports `data_store/knowledge.jsonl` into a fresh `data_store/knowledge.db`
   via `uvx --from git+https://github.com/agnivadc/knowledge-brain.git`
   (first run downloads and caches the brain package)

You don't need to clone the brain repo — `uvx` resolves it on demand.

## Collaborating across machines

The brain DB itself is **not** committed — only `data_store/knowledge.jsonl`,
which is the canonical line-oriented dump of all nodes. The local SQLite DB
is rebuilt from the JSONL on every bootstrap.

This makes the brain knowledge collaborative across users in the same way
source code is: pull the JSONL, work, export your additions back into the
JSONL, commit, push.

### Workflow

**Pulling someone else's contributions:**

```bash
git pull
bash scripts/sync.sh import         # macOS / Linux
pwsh scripts/sync.ps1 import        # Windows
```

This merges new nodes from the JSONL into your local DB. Existing nodes
(matching by id) are left alone — your in-progress local writes survive.
Pass `--force` to the underlying brain CLI if you want pull to overwrite
local changes; the wrapper is opinionated towards "merge wins."

**Pushing your contributions:**

```bash
bash scripts/sync.sh export         # macOS / Linux
pwsh scripts/sync.ps1 export        # Windows
git add data_store/knowledge.jsonl
git diff --cached data_store/knowledge.jsonl    # review what you're sharing
git commit -m "brain: <one-line summary of what you added>"
git push
```

### Conflict resolution

Two collaborators adding **different** facts → no conflict (different node
ids → different lines → clean text-level merge).

Two collaborators editing the **same** node (e.g. via supersedes) → standard
git conflict markers in the JSONL. Each line is one node, sorted by id, so
the conflict surface is small. Resolve textually, commit, both sides re-import.

### Hard reset

If your local DB drifts and you want to start over from the committed JSONL:

```bash
rm data_store/knowledge.db
bash scripts/sync.sh import         # or pwsh scripts/sync.ps1 import on Windows
```

The DB is a derived artifact; deleting it is always safe as long as the
JSONL is up to date.

## Use

Open Claude Code from this directory:

```bash
claude
```

Claude Code reads `.mcp.json` and prompts to approve the `knowledge-brain`
server. Approve it. From that point, `brain_write` and `brain_query` are
available as tools, scoped to **this project's** DB.

### Things to ask Claude

These exercise different brain behaviors:

1. *"What do we know about MES Supertrend's backtest performance?"*
   → triggers `brain_query("supertrend")`

2. *"Are there any architectural hard rules I should respect?"*
   → triggers `brain_query` with tags or text "hard-rule"

3. *"Save this to brain: I noticed risk vetoes spike during Fed announcements. Tags: empirical, risk, observation."*
   → triggers `brain_write`, then queryable in future sessions

4. Open a **new** Claude session, then ask: *"What did we observe about Fed announcements?"*
   → cross-session recall — the canonical brain value loop

5. *"What's missing in the brain about portfolio sizing?"*
   → exercises a meta/gap node

### Inspecting the DB directly

The brain CLI talks to the same DB. Run it via `uvx`:

```bash
# macOS / Linux
uvx --from git+https://github.com/agnivadc/knowledge-brain.git \
  brain --db-path "$(pwd)/data_store/knowledge.db" list --limit 20

uvx --from git+https://github.com/agnivadc/knowledge-brain.git \
  brain --db-path "$(pwd)/data_store/knowledge.db" query "supertrend"

uvx --from git+https://github.com/agnivadc/knowledge-brain.git \
  brain --db-path "$(pwd)/data_store/knowledge.db" query "drawdown" --tags empirical
```

```powershell
# Windows
$db = Join-Path (Get-Location) "data_store\knowledge.db"
uvx --from git+https://github.com/agnivadc/knowledge-brain.git `
  brain --db-path $db list --limit 20
```

## Reset

Re-running the bootstrap rebuilds the DB from the committed JSONL:

```powershell
# Windows
pwsh scripts/bootstrap.ps1
```

```bash
# macOS / Linux
bash scripts/bootstrap.sh
```
