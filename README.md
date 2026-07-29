# skills

[![Agent Skill](https://shieldcn.dev/badge/agent-skill-spec-000000.svg?variant=branded)](https://agentskills.io)
[![license](https://shieldcn.dev/badge/license-MIT-22c55e.svg)](LICENSE)

> [Agent Skills](https://agentskills.io) by **jal-co**. Badges by [shieldcn.dev](https://shieldcn.dev).

## Status

This repo is being reorganized. The previous skills have been removed and new ones will land here shortly.

## Install

Once skills are published, install any of them with:

```bash
npx skills add jal-co/skills --skill <skill-name>
```

Works in any [Agent Skills](https://agentskills.io)-compatible client (Claude Code, Cursor, Codex, Gemini CLI, opencode, pi, and more).

**Manual install (Claude Code):**
```bash
cp -r skills/<skill-name> ~/.claude/skills/
```

## Repository layout

```
skills/                # repo root (jal-co/skills)
├── README.md          # this file
├── AGENTS.md          # guide for authoring skills here
├── skills.sh.json     # skills.sh grouping metadata
├── LICENSE
└── skills/            # one directory per skill
```

## Authoring

See [AGENTS.md](AGENTS.md) for skill structure, naming rules, and script conventions.

## License

MIT — see [LICENSE](LICENSE).
