#!/usr/bin/env bash
# One-shot setup for the agent-os CCP flow on this playground.
#
# What this does:
#   1. Verifies prereqs (uv, npm, pi, curl) are on PATH
#   2. Installs/refreshes the brain CLI globally via `uv tool install`
#   3. Installs agent-os v1.0.0 as a Pi extension via `pi install`
#   4. Fetches AGENT_OS_CONSTITUTION.md + schemas + contracts/index.json
#      from the agent-os repo at the v1.0.0 tag (preserves bytes — content
#      hashes are baked into the constitution and must not be reformatted)
#   5. Renders .agent-os/project.yaml from the committed template
#
# After this, export BRAIN_DB_PATH (printed at the end), then run `pi`.

set -euo pipefail

export UV_LINK_MODE=copy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYGROUND="$(cd "$SCRIPT_DIR/.." && pwd)"
AOS_DIR="$PLAYGROUND/.agent-os"
SCHEMAS_DIR="$AOS_DIR/schemas"
CONTRACTS_DIR="$AOS_DIR/contracts"
RUNTIME_DIR="$AOS_DIR/runtime"
TEMPLATE="$AOS_DIR/project.yaml.template"
PROJECT_YAML="$AOS_DIR/project.yaml"

AOS_TAG="v1.0.0"
AOS_GIT_REF="git:github.com/algoSiliguri/Agent_OS@${AOS_TAG}"
RAW_BASE="https://raw.githubusercontent.com/algoSiliguri/Agent_OS/${AOS_TAG}"
BRAIN_GIT_URL="git+https://github.com/agnivadc/knowledge-brain.git"

# 1. Prereq checks
require() {
    local name="$1" hint="$2"
    if ! command -v "$name" >/dev/null 2>&1; then
        cat >&2 <<EOF
'$name' is not on PATH. Install it first:
  $hint
EOF
        exit 1
    fi
}

require uv "https://docs.astral.sh/uv/getting-started/installation/"
require npm "https://nodejs.org/ (npm ships with Node.js >=20)"
require curl "your OS package manager"

if ! command -v pi >/dev/null 2>&1; then
    cat >&2 <<EOF
'pi' is not on PATH. Install the Pi coding agent first:
  npm install -g @mariozechner/pi-coding-agent

Then ensure ANTHROPIC_API_KEY is set in your shell, e.g.:
  export ANTHROPIC_API_KEY=sk-ant-...
EOF
    exit 1
fi
echo "[1/5] prereqs OK (uv, npm, pi, curl all on PATH)"

# 2. Install brain CLI globally (idempotent; --reinstall upgrades if already there)
echo "[2/5] installing brain CLI via uv tool"
uv tool install --from "$BRAIN_GIT_URL" knowledge-brain --reinstall

# 3. Install agent-os as a Pi extension at v1.0.0
echo "[3/5] installing agent-os $AOS_TAG as a Pi extension"
pi install "$AOS_GIT_REF"

# 4. Fetch constitution + schemas + contract index from the v1.0.0 tag.
#    curl -o preserves bytes; do NOT pipe through any text processor.
mkdir -p "$SCHEMAS_DIR" "$CONTRACTS_DIR" "$RUNTIME_DIR"
fetch() {
    local rel="$1"
    local out="$PLAYGROUND/$rel"
    mkdir -p "$(dirname "$out")"
    curl -sfL -o "$out" "$RAW_BASE/$rel"
}

echo "[4/5] fetching governance files from agent-os $AOS_TAG"
fetch "AGENT_OS_CONSTITUTION.md"
fetch ".agent-os/schemas/constitution-binding.schema.json"
fetch ".agent-os/schemas/telemetry-event.schema.json"
fetch ".agent-os/schemas/permission-manifest.schema.json"
fetch ".agent-os/contracts/index.json"

# 5. Render .agent-os/project.yaml from the committed template
if [[ ! -f "$TEMPLATE" ]]; then
    echo "Template not found at $TEMPLATE" >&2
    exit 1
fi
sed "s|__WORKSPACE_ROOT__|$PLAYGROUND|" "$TEMPLATE" > "$PROJECT_YAML"
echo "[5/5] wrote $PROJECT_YAML"

cat <<EOF

Done. Next:

  1. Export BRAIN_DB_PATH so /remember writes to a real brain DB.
     Either point at the global DB (recommended; same DB Setup A's MCP reads):
       export BRAIN_DB_PATH="\$HOME/.knowledge-brain/knowledge.db"
     Or use a project-local DB:
       export BRAIN_DB_PATH="$PLAYGROUND/data_store/knowledge.db"

  2. Make sure ANTHROPIC_API_KEY is set:
       export ANTHROPIC_API_KEY=sk-ant-...

  3. Open Pi in this directory:
       pi

  4. In the Pi prompt, type:
       /doctor

     If everything is wired correctly, /doctor reports status: ok.

  5. Walk the v1 demo:
       /grill add a smoke-test feature
       /plan
       /run
       /verify
       /remember
       /status
EOF
