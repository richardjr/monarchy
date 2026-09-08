# Monarchy — working rules for agents

This repository is **Monarchy**, a fork of Omarchy. Upstream's [`AGENTS.md`](../AGENTS.md) and `agents/skills/` still apply to all code style, command metadata, shell development, migrations and visual verification. This file adds the Monarchy-specific rules. When the two disagree, this file wins.

Read [`ROADMAP.md`](ROADMAP.md) for the current phase and [`DECISIONS.md`](DECISIONS.md) before proposing anything structural. Record new decisions there, dated, before implementing them.

## Naming and IP

- Never use "LCARS" anywhere: names, ids, comments, docs, commit messages, theme assets.
- No franchise trademarks, ship or character names, or pixel-faithful recreations of franchise UIs. Homage in a theme's mood is fine; recognisable IP is not.
- No franchise fonts. Every font added is recorded in `DECISIONS.md` with its licence.
- Original names only for anything user-facing: Monarchy, Monarch, Phosphor, Amber, Special Order.
- Existing `omarchy-*` commands, paths, package names and plugin ids are **not** renamed (D003). New Monarchy things use `monarchy.*` plugin ids, `monarch` for the assistant, and theme directory names as above.

## Where Monarchy code lives

Prefer adding new files over editing upstream ones; it keeps merges clean.

| What | Where |
|---|---|
| Project docs, brief, roadmap, decisions | `monarchy/` |
| Bridge console bar plugin | `shell/plugins/bridge/` (id `monarchy.bridge`, `kind: "bar"`) |
| Themes | `themes/phosphor/`, `themes/amber/`, `themes/special-order/` |
| Monarch skill | `default/agents/skills/monarch/` |
| Monarch launcher | `bin/monarch` |
| Layout defaults | `default/hypr/looknfeel.lua` (an upstream file; keep the diff minimal) |
| Shell default config | `config/omarchy/shell.json` (upstream file; minimal diff) |
| Theme template keys | `default/themed/shell.toml.tpl` (upstream file; add keys with defaults, never remove) |

When an upstream file must be edited, keep the change small and mark it with a `monarchy:` comment on or above the changed lines so it can be found and re-applied after a merge.

## Branches and upstream

- `main` is Monarchy. All work lands here.
- `quattro` is a read-only mirror of upstream's development branch. Never commit to it. Refresh with `git fetch upstream && git push origin upstream/quattro:quattro`.
- Merge upstream **release tags only** (D004):

  ```bash
  git fetch upstream --tags
  git checkout main
  git merge --no-ff v4.0.3          # resolve conflicts, favouring upstream for files we did not intend to change
  ./test/all
  ```

  Before merging, confirm the tag is a fast-forward of the previous tag (`git merge-base --is-ancestor v4.0.2 v4.0.3`). If it is not, stop and record what changed in `DECISIONS.md` before proceeding.
- After a merge, re-check every `monarchy:` marker and the table above.

## Working method

- Develop and verify in a VM running a dev-linked checkout, not on the host. Snapshot the VM as stock before the first link. See ROADMAP phase 0 for the loop.
- Inside the VM: `omarchy dev link ~/monarchy` once (reboot), then `git pull` and `omarchy-restart-shell` after QML changes, `hyprctl reload` after Hyprland Lua changes, `omarchy theme set <name>` after theme changes.
- Layout and theming work is not done until a screenshot has been taken and inspected. Use `omarchy capture screenshot fullscreen save` in the VM, following upstream's `agents/skills/visual-verification.md`.
- Run `./test/all` before declaring any change finished. It must stay green on a headless machine.
- Keep everything idempotent and re-runnable, including any Monarchy-added migrations.

## Workspace note

This checkout lives under `~/Work`, whose `CLAUDE.md` belongs to an unrelated project (Landarna) and also loads. Ignore its vault, promotion-PR and repo-scope instructions here. Its commit discipline does apply: do not commit, push or open PRs unless asked; factual subject lines; no trailers or emoji.
