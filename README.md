# Trading Playground

A synthetic trading-system repo wired to the Knowledge Brain so you can feel
how the brain works inside a real project context.

The code here is intentionally thin — stubs, docs, and config that *look*
like a trading system. The interesting thing is the **brain wiring** and the
**seeded knowledge** that mirrors what the Brain accumulates over time.

## Layout

```
trading-playground/
├── .mcp.json                  Project-scoped MCP server (knowledge-brain)
├── docs/
│   ├── strategies/            Strategy specifications (Layer 2)
│   ├── architecture/          Engine and risk design (Layer 2)
│   └── decisions/             ADR-style design decisions (Layer 2)
├── config/                    Strategy + risk YAML (Layer 2 → Layer 3)
├── scripts/
│   ├── seed_brain.py          Pre-populates the brain with realistic nodes
│   └── setup.ps1              One-shot setup
└── data_store/                Brain DB lives here (gitignored)
```

## Setup (one time)

Prerequisite: the `knowledge-brain` repo is a sibling and `uv sync --extra dev`
has been run inside it. The brain's venv exists at:

```
C:\Users\agnivad\OneDrive - Microsoft\Agniva\knowledge-brain\.venv\
```

Then, from this directory, run:

```powershell
pwsh scripts/setup.ps1
```

This:
1. Initializes `data_store/knowledge.db` (this project's brain DB)
2. Seeds it with 15 realistic trading-domain nodes

## Use

Open Claude Code from this directory:

```powershell
claude
```

Claude Code reads `.mcp.json` and prompts to approve the `knowledge-brain`
server. Approve it. From that point, `brain_write` and `brain_query` are
available as tools, scoped to **this project's** DB.

### Things to ask Claude

These exercise different brain behaviors:

1. *"What do we know about MES Supertrend's backtest performance?"*
   → triggers `brain_query("supertrend backtest")`

2. *"Are there any architectural hard rules I should respect?"*
   → triggers `brain_query` with tags or text "hard-rule"

3. *"Save this to brain: I noticed risk vetoes spike during Fed announcements. Tags: empirical, risk, observation."*
   → triggers `brain_write`, then queryable in future sessions

4. Open a **new** Claude session, then ask: *"What did we observe about Fed announcements?"*
   → cross-session recall — the canonical brain value loop

5. *"What's missing in the brain about portfolio sizing?"*
   → exercises a meta/gap node

### Inspecting the DB directly

The brain CLI talks to the same DB:

```powershell
$db = "C:\Users\agnivad\OneDrive - Microsoft\Agniva\trading-playground\data_store\knowledge.db"
$brain = "C:\Users\agnivad\OneDrive - Microsoft\Agniva\knowledge-brain\.venv\Scripts\brain.exe"

& $brain --db-path $db list --limit 20
& $brain --db-path $db query "supertrend"
& $brain --db-path $db query "drawdown" --tags empirical
```

## Reset

```powershell
Remove-Item data_store\knowledge.db
pwsh scripts/setup.ps1
```
