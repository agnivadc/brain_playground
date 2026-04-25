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
│   ├── seed_brain.py        Pre-populates the brain with realistic nodes
│   ├── bootstrap.ps1        One-shot setup (Windows)
│   └── bootstrap.sh         One-shot setup (macOS / Linux)
└── data_store/              Brain DB lives here (gitignored)
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
3. Seeds `data_store/knowledge.db` with 15 realistic trading-domain nodes
   via `uvx --from git+https://github.com/agnivadc/knowledge-brain.git`
   (first run downloads and caches the brain package)

You don't need to clone the brain repo — `uvx` resolves it on demand.

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

Re-running the bootstrap deletes and re-seeds the DB:

```powershell
# Windows
pwsh scripts/bootstrap.ps1
```

```bash
# macOS / Linux
bash scripts/bootstrap.sh
```
