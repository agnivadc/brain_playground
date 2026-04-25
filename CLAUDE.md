# Trading Playground — Context for Claude

This is a synthetic trading-system repo wired to the **Knowledge Brain** via
MCP (`.mcp.json`). The brain is a persistent memory layer scoped to this
project's DB at `data_store/knowledge.db`.

## How to use the brain in this repo

You have two MCP tools:

- **`brain_query(query, tags?, max_results?)`** — search seeded knowledge
- **`brain_write(content, tags, source_type?, source_ref?, confidence?)`** —
  persist a new finding

### When to query

Before answering substantive questions about strategies, risk rules,
architectural decisions, or empirical findings, **query the brain first**.
The seeded knowledge contains things like:

- Strategy backtest results (MES Supertrend v2.2)
- Architectural hard rules (layering, risk veto contracts)
- External research (Faber, Aronson, Hull)
- Operational realities (latency, slippage)
- Coverage gaps (meta-knowledge)

If the brain returns relevant nodes, ground your answer in them and cite by
node id and source_ref.

### When to write

When the user shares a new finding, decision, observation, or external
reference, propose writing it to the brain. Use tags drawn from existing
patterns (look at existing nodes via `brain_query` with broad terms first).

Source types:
- `human` — user told you something directly
- `session` — derived from this conversation's analysis
- `ingestion` — extracted from a doc/source

## Project layout

- `docs/strategies/` — strategy specs (e.g., MES Supertrend)
- `docs/architecture/` — engine and risk design
- `docs/decisions/` — ADR-style design decisions
- `config/` — strategy and risk YAML
- `scripts/seed_brain.py` — what was seeded; reference for tag conventions

## Conventions

- Brain content should be **atomic** — one fact or decision per node
- Tags use lowercase, hyphenated, no spaces
- Always include a `source_ref` if the knowledge has a citable origin
- Confidence: 0.95+ for hard rules and citable claims, 0.7-0.85 for
  empirical findings, 0.5-0.7 for hypotheses
