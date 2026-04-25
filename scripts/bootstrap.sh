#!/usr/bin/env bash
# One-shot setup for the trading-playground.
#
# What this does:
#   1. Verifies `uv` is on PATH (fails fast with install instructions if not)
#   2. Generates .mcp.json from .mcp.json.template with absolute DB path
#   3. Seeds data_store/knowledge.db via uvx (downloads brain on first run)
#
# After this, run `claude` in this directory.

set -euo pipefail

# Use copy instead of hardlink for uv's cache; hardlinks fail on cloud-synced
# filesystems (OneDrive, Dropbox, etc.) and the perf cost is negligible.
export UV_LINK_MODE=copy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYGROUND="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$PLAYGROUND/.mcp.json.template"
MCP_CONFIG="$PLAYGROUND/.mcp.json"
DB_PATH="$PLAYGROUND/data_store/knowledge.db"
SEED_SCRIPT="$SCRIPT_DIR/seed_brain.py"
BRAIN_GIT_URL="git+https://github.com/agnivadc/knowledge-brain.git"

# 1. Check uv is installed
if ! command -v uv >/dev/null 2>&1; then
    cat >&2 <<EOF
'uv' is not on PATH. Install it first:
  https://docs.astral.sh/uv/getting-started/installation/

On macOS/Linux, the quickest install is:
  curl -LsSf https://astral.sh/uv/install.sh | sh
EOF
    exit 1
fi
echo "[1/3] uv found: $(command -v uv)"

# 2. Generate .mcp.json from template
if [[ ! -f "$TEMPLATE" ]]; then
    echo "Template not found at $TEMPLATE" >&2
    exit 1
fi
# Use a sed delimiter unlikely to appear in absolute paths
sed "s|__DB_PATH__|$DB_PATH|" "$TEMPLATE" > "$MCP_CONFIG"
echo "[2/3] Wrote $MCP_CONFIG"

# 3. Seed the database
mkdir -p "$(dirname "$DB_PATH")"
if [[ -f "$DB_PATH" ]]; then
    echo "      DB exists at $DB_PATH; removing for fresh seed"
    rm -f "$DB_PATH"
fi
echo "[3/3] Seeding via uvx (first run downloads the brain package)"
uvx --from "$BRAIN_GIT_URL" python "$SEED_SCRIPT"

echo
echo "Done. Next:"
echo "  1. Open Claude Code in this directory:  claude"
echo "  2. Approve the knowledge-brain MCP server when prompted"
echo "  3. Try the suggested questions in README.md"
