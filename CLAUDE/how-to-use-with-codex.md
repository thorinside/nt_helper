# How To Use With Codex

- Codex CLI: run `codex` in this project. Reference an agent naturally, e.g., "As dev, implement ...".
- Codex Web: open this repo and reference roles the same way; Codex reads `AGENTS.md`.
- Commit `.bmad-core` and this `AGENTS.md` file to your repo so Codex (Web/CLI) can read full agent definitions.
- Refresh this section after agent updates: `npx bmad-method install -f -i codex`.

## Helpful Commands

- List agents: `npx bmad-method list:agents`
- Reinstall BMAD core and regenerate AGENTS.md: `npx bmad-method install -f -i codex`
- Validate configuration: `npx bmad-method validate`
