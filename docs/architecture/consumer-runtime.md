# Brain Playground Consumer Runtime Notes

This repository is a consumer of the agent-os v1.0.0 control plane, loaded
into Pi as a TypeScript extension.

Unlike the v3 Python era (when this doc first landed), governance files
**are vendored** at the agent-os v1.0.0 tag. v1.0.0's
`verifyConstitution` requires `AGENT_OS_CONSTITUTION.md` at the repo root
and computes a content-hash against it; the same is true of the schemas
listed in `.agent-os/contracts/index.json`. `scripts/bootstrap-ccp.{sh,ps1}`
fetches all of these as raw bytes from the v1.0.0 tag — they are not
manually authored or kept in sync inside this repo.

Local constraints:

- The agent-os Pi extension manages binding and verification automatically;
  there is no manual `bind` or `doctor` step at the OS level. Use the
  `/doctor` slash command inside Pi instead.
- `data_store/knowledge.db` is project-local memory; `~/.knowledge-brain/knowledge.db`
  is the global brain across all projects. Either is fine for `BRAIN_DB_PATH`.
- This project's `.agent-os/project.yaml` declares
  `memory_policy.global_memory_read: true` and
  `memory_policy.global_memory_write: false`. v1.0.0 does not enforce these
  fields yet; they document the project's intent for v1.x releases that
  will gate brain writes by manifest policy.
- All harness adapters (`AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`)
  declare themselves non-authoritative and defer to `AGENT_OS_CONSTITUTION.md`.
  Only Pi runs the agent-os extension itself; other harnesses can talk to
  the brain via MCP but cannot drive the CCP slash-command loop in v1.0.0.
