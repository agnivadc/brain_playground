# One-shot setup for the agent-os CCP flow on this playground.
#
# What this does:
#   1. Verifies prereqs (uv, npm, pi, curl) are on PATH
#   2. Installs/refreshes the brain CLI globally via `uv tool install`
#   3. Installs agent-os v1.0.0 as a Pi extension via `pi install`
#   4. Fetches AGENT_OS_CONSTITUTION.md + schemas + contracts/index.json
#      from the agent-os repo at the v1.0.0 tag (writes raw bytes — content
#      hashes are baked into the constitution and must not be reformatted)
#   5. Renders .agent-os/project.yaml from the committed template
#
# After this, set $env:BRAIN_DB_PATH (printed at the end), then run `pi`.

$ErrorActionPreference = "Stop"

$env:UV_LINK_MODE = "copy"

$Playground   = Split-Path -Parent $PSScriptRoot
$AosDir       = Join-Path $Playground ".agent-os"
$SchemasDir   = Join-Path $AosDir "schemas"
$ContractsDir = Join-Path $AosDir "contracts"
$RuntimeDir   = Join-Path $AosDir "runtime"
$Template     = Join-Path $AosDir "project.yaml.template"
$ProjectYaml  = Join-Path $AosDir "project.yaml"

$AosTag       = "v1.0.0"
$AosGitRef    = "git:github.com/algoSiliguri/Agent_OS@$AosTag"
$RawBase      = "https://raw.githubusercontent.com/algoSiliguri/Agent_OS/$AosTag"
$BrainGitUrl  = "git+https://github.com/agnivadc/knowledge-brain.git"

# 1. Prereq checks
function Require-Cmd {
    param([string]$Name, [string]$Hint)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Error @"
'$Name' is not on PATH. Install it first:
  $Hint
"@
        exit 1
    }
}

Require-Cmd "uv" "https://docs.astral.sh/uv/getting-started/installation/"
Require-Cmd "npm" "https://nodejs.org/ (npm ships with Node.js >=20)"

if (-not (Get-Command pi -ErrorAction SilentlyContinue)) {
    Write-Error @"
'pi' is not on PATH. Install the Pi coding agent first:
  npm install -g @mariozechner/pi-coding-agent

Then ensure ANTHROPIC_API_KEY is set in your shell, e.g.:
  `$env:ANTHROPIC_API_KEY = 'sk-ant-...'
"@
    exit 1
}
Write-Host "[1/5] prereqs OK (uv, npm, pi all on PATH)"

# 2. Install brain CLI globally (idempotent)
Write-Host "[2/5] installing brain CLI via uv tool"
& uv tool install --from $BrainGitUrl knowledge-brain --reinstall
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 3. Install agent-os as a Pi extension at v1.0.0
Write-Host "[3/5] installing agent-os $AosTag as a Pi extension"
& pi install $AosGitRef
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4. Fetch governance files at the v1.0.0 tag.
#    Invoke-WebRequest -OutFile preserves raw bytes; do NOT use Get-Content /
#    Set-Content here or the constitution's content-hash will mismatch.
New-Item -ItemType Directory -Force -Path $SchemasDir, $ContractsDir, $RuntimeDir | Out-Null

function Fetch-Raw {
    param([string]$Rel)
    $Url = "$RawBase/$Rel"
    $OutPath = Join-Path $Playground $Rel
    $OutDir = Split-Path -Parent $OutPath
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing
}

Write-Host "[4/5] fetching governance files from agent-os $AosTag"
Fetch-Raw "AGENT_OS_CONSTITUTION.md"
Fetch-Raw ".agent-os/schemas/constitution-binding.schema.json"
Fetch-Raw ".agent-os/schemas/telemetry-event.schema.json"
Fetch-Raw ".agent-os/schemas/permission-manifest.schema.json"
Fetch-Raw ".agent-os/contracts/index.json"

# 5. Render .agent-os/project.yaml from the committed template
if (-not (Test-Path $Template)) {
    Write-Error "Template not found at $Template"
    exit 1
}
$content = Get-Content $Template -Raw
$content = $content -replace '__WORKSPACE_ROOT__', ($Playground -replace '\\', '/')
Set-Content -Path $ProjectYaml -Value $content -NoNewline
Write-Host "[5/5] wrote $ProjectYaml"

Write-Host ""
Write-Host "Done. Next:"
Write-Host ""
Write-Host "  1. Set BRAIN_DB_PATH so /remember writes to a real brain DB."
Write-Host "     Either point at the global DB (recommended; same DB Setup A's MCP reads):"
Write-Host "       `$env:BRAIN_DB_PATH = `"`$HOME/.knowledge-brain/knowledge.db`""
Write-Host "     Or use a project-local DB:"
Write-Host "       `$env:BRAIN_DB_PATH = '$Playground\data_store\knowledge.db'"
Write-Host ""
Write-Host "  2. Make sure ANTHROPIC_API_KEY is set:"
Write-Host "       `$env:ANTHROPIC_API_KEY = 'sk-ant-...'"
Write-Host ""
Write-Host "  3. Open Pi in this directory:"
Write-Host "       pi"
Write-Host ""
Write-Host "  4. In the Pi prompt, type:"
Write-Host "       /doctor"
Write-Host ""
Write-Host "     If everything is wired correctly, /doctor reports status: ok."
Write-Host ""
Write-Host "  5. Walk the v1 demo:"
Write-Host "       /grill add a smoke-test feature"
Write-Host "       /plan"
Write-Host "       /run"
Write-Host "       /verify"
Write-Host "       /remember"
Write-Host "       /status"
