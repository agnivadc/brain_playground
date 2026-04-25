# One-shot setup: initialize and seed this playground's brain DB.
$ErrorActionPreference = "Stop"

$BrainRepo   = "C:\Users\agnivad\OneDrive - Microsoft\Agniva\knowledge-brain"
$BrainPython = Join-Path $BrainRepo ".venv\Scripts\python.exe"
$Playground  = Split-Path -Parent $PSScriptRoot
$SeedScript  = Join-Path $PSScriptRoot "seed_brain.py"
$DbPath      = Join-Path $Playground "data_store\knowledge.db"

if (-not (Test-Path $BrainPython)) {
    Write-Error "Brain venv not found at $BrainPython. Run 'uv sync --extra dev' inside the brain repo first."
    exit 1
}

if (Test-Path $DbPath) {
    Write-Host "DB already exists at $DbPath. Removing for fresh seed..."
    Remove-Item $DbPath -Force
}

Write-Host "Running seed script via brain venv..."
& $BrainPython $SeedScript
if ($LASTEXITCODE -ne 0) {
    Write-Error "Seed script failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done. Next:"
Write-Host "  1. Open Claude Code in this directory:  claude"
Write-Host "  2. Approve the knowledge-brain MCP server when prompted"
Write-Host "  3. Try the suggested questions in README.md"
