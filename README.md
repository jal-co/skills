<p align="center">
  <picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/header/transparent.svg?title=skills&amp;subtitle=by+justin+levine&amp;logo=false&amp;size=wide&amp;mode=dark&amp;border=false" /><img alt="header" src="https://shieldcn.dev/header/transparent.svg?title=skills&amp;subtitle=by+justin+levine&amp;logo=false&amp;size=wide&amp;mode=light&amp;border=false" /></picture>
</p>

<p align="center">
  <a href="https://github.com/jal-co/skills"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/jal-co/skills/license.svg?size=xs" /><img alt="license" src="https://shieldcn.dev/github/jal-co/skills/license.svg?size=xs&amp;mode=light" /></picture></a>
  <a href="https://github.com/jal-co/skills"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/github/jal-co/skills/stars.svg?size=xs" /><img alt="badge" src="https://shieldcn.dev/github/jal-co/skills/stars.svg?size=xs&amp;mode=light" /></picture></a>
  <a href="https://www.skills.sh/jal-co/skills"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/badge/install_on-skills.sh.svg?variant=branded&amp;size=xs&amp;logo=vercel&amp;color=000000" /><img alt="install on skills.sh" src="https://shieldcn.dev/badge/install_on-skills.sh.svg?variant=branded&amp;size=xs&amp;mode=light&amp;logo=vercel&amp;color=000000" /></picture></a>
</p>

<p align="center">
  <a href="https://agentskills.io">Agent Skills</a> for design and product work. Badges by <a href="https://shieldcn.dev">shieldcn.dev</a>.
</p>

## Skills

### Design

| Skill | Installs | What it does | Install |
|---|---|---|---|
| [`ux-sound`](skills/ux-sound) | <a href="https://www.skills.sh/jal-co/skills/ux-sound"><picture><source media="(prefers-color-scheme: dark)" srcset="https://shieldcn.dev/skills/installs/jal-co/skills/ux-sound.svg?size=xs" /><img alt="installs" src="https://shieldcn.dev/skills/installs/jal-co/skills/ux-sound.svg?size=xs&amp;mode=light" /></picture></a> | Decides whether an interface element should make a sound, which kind, how loud, and where the audio comes from (synthesis, recording, or generation). | `npx skills add jal-co/skills --skill ux-sound` |

## Install

```bash
npx skills add jal-co/skills --skill ux-sound
```

Works in any [Agent Skills](https://agentskills.io)-compatible client (Claude Code, Cursor, Codex, Gemini CLI, opencode, pi, and more).

**Manual install (Claude Code):**

```bash
cp -r skills/ux-sound ~/.claude/skills/
```

## Usage

Describe the problem and the skill activates on its own:

- *"Should this toggle make a sound?"* → decision tree, usually a no
- *"This click sounds cheap."* → sourcing and levelling fix
- *"Audit the sound layer in this app."* → pass over every trigger
- *"Sync this sound to the drawer animation."* → timing rules

## Repository layout

```
skills/                # repo root (jal-co/skills)
├── README.md          # this file
├── AGENTS.md          # guide for authoring skills here
├── skills.sh.json     # skills.sh grouping metadata
├── LICENSE
└── skills/
    └── ux-sound/
        ├── SKILL.md
        └── scripts/
            ├── transients.mjs
            └── trim-to-transient.sh
```

## Authoring

See [AGENTS.md](AGENTS.md) for skill structure, naming rules, and script conventions.

## License

MIT — see [LICENSE](LICENSE).
