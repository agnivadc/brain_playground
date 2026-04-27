# Brain Playground Consumer Runtime Notes

This repository is a thin consumer of the machine-local `context_os` runtime.
It does not vendor framework governance files.

Local constraints:

- use the central runtime for binding and verification
- treat `data_store/knowledge.db` as project-local memory
- allow reads from global memory, but keep project writes local by default
