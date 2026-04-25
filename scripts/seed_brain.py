"""Seed the playground's brain DB with realistic trading-domain nodes.

Run via the brain repo's venv python so knowledge_brain is importable:

    & "C:\\Users\\agnivad\\OneDrive - Microsoft\\Agniva\\knowledge-brain\\.venv\\Scripts\\python.exe" scripts/seed_brain.py

Or simply use: pwsh scripts/setup.ps1
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    from knowledge_brain.models import KnowledgeNode
    from knowledge_brain.store import Store
except ImportError:
    sys.exit(
        "error: knowledge_brain is not importable.\n"
        "Run via the brain repo's venv:\n"
        '  & "<brain-repo>\\.venv\\Scripts\\python.exe" scripts/seed_brain.py\n'
    )

DB_PATH = Path(__file__).resolve().parent.parent / "data_store" / "knowledge.db"

NODES: list[dict] = [
    # ─── System / architecture ────────────────────────────────────────────
    {
        "content": (
            "Trading engine uses event-driven pub/sub. All decisions emit events to a "
            "single in-process bus before the next engine consumes them. This provides "
            "traceability (every event is also persisted to Reality DB) and decouples "
            "strategy from execution."
        ),
        "tags": ["architecture", "decision", "event-bus", "system"],
        "source_ref": "docs/architecture/event-bus.md",
        "confidence": 0.95,
    },
    {
        "content": (
            "Risk engine vetoes are final. If risk rejects a signal, the order never "
            "reaches execution. No retry, no override path in code. Adjusting a risk "
            "rule requires a config change and engine restart."
        ),
        "tags": ["architecture", "risk", "contract", "system", "hard-rule"],
        "source_ref": "docs/architecture/risk-framework.md",
        "confidence": 0.95,
    },
    {
        "content": (
            "Layer 3 (execution) NEVER touches Layer 1 (brain). Hard rule. Determinism "
            "requires pure I/O: market data → strategy → orders, with no async LLM "
            "calls in the trade path."
        ),
        "tags": ["architecture", "layering", "hard-rule", "system"],
        "source_ref": "docs/decisions/2026-04-15-layering.md",
        "confidence": 1.0,
    },
    {
        "content": (
            "Layer 4 (Reality DB) is append-only during execution. No updates to past "
            "decision_log or trades records. All writes happen on the trade path; "
            "reads only after session ends."
        ),
        "tags": ["architecture", "traceability", "reality", "system"],
        "source_ref": "docs/decisions/2026-04-15-layering.md",
        "confidence": 0.9,
    },
    {
        "content": (
            "Position store is the single source of truth for current positions and "
            "cash. Read by all engines; written only by the execution engine on fill "
            "events."
        ),
        "tags": ["architecture", "state", "contract", "system"],
        "source_ref": "docs/architecture/event-bus.md",
        "confidence": 0.9,
    },
    # ─── Empirical findings ────────────────────────────────────────────────
    {
        "content": (
            "MES Supertrend v2.2 backtest 2024-01-01 to 2026-03-31: 312 trades, "
            "47.1% win rate, profit factor 1.34, max drawdown 8.2%, Sharpe 1.18 net "
            "of slippage. Beats buy-and-hold by 4.2% annualized."
        ),
        "tags": ["empirical", "mes", "supertrend", "backtest"],
        "source_ref": "backtest:2026-04-12_supertrend_v2.2",
        "confidence": 0.85,
    },
    {
        "content": (
            "MES slippage averages 0.25 ticks at market open (09:30-09:35 ET), 0.12 "
            "ticks midday, 0.30 ticks in the last 5 minutes. Used for fill-cost "
            "modeling."
        ),
        "tags": ["empirical", "mes", "slippage", "execution"],
        "source_ref": "fill_analysis:2026-Q1",
        "confidence": 0.8,
    },
    {
        "content": (
            "Strategies using ATR(14) on 1h MES bars outperform ATR(7) by 18% over 2 "
            "years. Lower whipsaw cost is the dominant factor, not signal frequency."
        ),
        "tags": ["empirical", "atr", "parameter-sweep", "supertrend"],
        "source_ref": "research:atr_sweep_2026-02",
        "confidence": 0.75,
    },
    {
        "content": (
            "Daily drawdown cap of 1.5% triggered 6 times in 2025. In 5 of 6 cases, "
            "recovery occurred within 3 sessions. Cap is doing its job; tightening "
            "to 1.0% would have triggered 14 times with similar recovery profile."
        ),
        "tags": ["empirical", "drawdown", "risk"],
        "source_ref": "post_mortem:2026-01_drawdown_review",
        "confidence": 0.85,
    },
    # ─── External knowledge ────────────────────────────────────────────────
    {
        "content": (
            "Faber 'Quantitative Tactical Asset Allocation' (2007): a 10-month moving "
            "average filter reduces max drawdown ~30% across major asset classes "
            "(US equities, foreign equities, bonds, REITs, commodities) over 1972-2005."
        ),
        "tags": ["external", "paper", "faber", "drawdown", "filter"],
        "source_ref": "Faber 2007, SSRN 962461",
        "confidence": 0.9,
    },
    {
        "content": (
            "Aronson 'Evidence-Based Technical Analysis' Ch.6: data mining bias "
            "inflates backtest returns by 2-5x without rigorous out-of-sample "
            "validation. Apply Bonferroni correction or White's Reality Check when "
            "testing more than 10 rule variants."
        ),
        "tags": ["external", "book", "aronson", "backtest-bias", "methodology"],
        "source_ref": "Aronson 2007, Ch.6 pp.123-145",
        "confidence": 0.9,
    },
    {
        "content": (
            "Hull 'Options, Futures, and Other Derivatives' Ch.14: index futures have "
            "near-zero basis risk for hedges held to expiry. Basis (futures - spot) "
            "converges to zero by expiry per cost-of-carry."
        ),
        "tags": ["external", "book", "hull", "hedging", "futures"],
        "source_ref": "Hull 11ed, Ch.14",
        "confidence": 0.95,
    },
    # ─── Operational reality ───────────────────────────────────────────────
    {
        "content": (
            "Live MES tick stream from Interactive Brokers averages 8ms latency "
            "end-to-end (exchange → IB gateway → strategy engine). Sufficient for "
            "1-minute bar strategies; insufficient for sub-second arbitrage."
        ),
        "tags": ["operational", "latency", "ib", "infrastructure"],
        "source_ref": "monitoring:2026-04-week",
        "confidence": 0.85,
    },
    {
        "content": (
            "Position store SQLite WAL mode benchmarks at 5k writes/sec on commodity "
            "NVMe. Current load is ~100 writes/min; 50x headroom. No bottleneck risk "
            "for any current strategy."
        ),
        "tags": ["operational", "performance", "state", "infrastructure"],
        "source_ref": "perf_test:2026-03",
        "confidence": 0.9,
    },
    # ─── Meta-knowledge (gaps) ─────────────────────────────────────────────
    {
        "content": (
            "Brain has 0 nodes about portfolio-level sizing rules across multiple "
            "concurrent strategies. Coverage gap; revisit after the multi-strategy "
            "framework spec is written."
        ),
        "tags": ["meta", "gap", "portfolio", "coverage"],
        "source_ref": "vault_audit:2026-04-25",
        "confidence": 0.7,
    },
]


def main() -> int:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    store = Store(DB_PATH)
    store.init_schema()

    print(f"Seeding {len(NODES)} nodes into {DB_PATH}\n")
    for entry in NODES:
        node = KnowledgeNode(source_type="ingestion", **entry)
        store.write_node(node)
        tag_str = ",".join(node.tags)
        print(f"  + {node.id}  [{tag_str}]")

    items, total = store.query(limit=100)
    print(f"\nDB now contains {total} node(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
