[A1] Consumer Declaration
This repository is a consumer of agent-os v1.1.0 (https://github.com/algoSiliguri/Agent_OS), loaded into Pi as a TypeScript extension.

[A2] Binding Instruction
The agent-os Pi extension reads `.agent-os/project.yaml` on load and emits a `BINDING` event automatically. Run `/init` once per checkout to install the extension and vendor the constitution + schemas + contracts at the v1.1.0 tag. No manual `bind` step is required.

[A3] Failure Instruction
If `/doctor` reports `status: hard_fail`, do not proceed as active. The repo is `NOT_ACTIVE` until the failing check (B0 binding header, B1 schema-presence, B5 binding event, etc.) is resolved.

[A4] Deference
`AGENT_OS_CONSTITUTION.md` (vendored at the v1.1.0 tag) governs execution. The user-facing surface is the slash commands `/grill /plan /run /verify /remember /status /doctor` inside Pi. Other harnesses (Claude Code, Copilot) can still talk to the brain via MCP, but agent-os v1.1.0 ships only as a Pi extension.
