# Monarchy roadmap

The [founding brief](BRIEF.md) revised against Omarchy 4 ("Quattro"). Omarchy 4 already ships a Quickshell shell with a replaceable bar, a Lua Hyprland config, a `colors.toml` theme engine that renders into 17 apps (Claude Code included), and first-class agent integration. Monarchy therefore builds far less plumbing than the brief assumed and spends its effort on layout, theme design and the Monarch persona.

Phase numbering here supersedes the brief. Each phase has a "done when" so it can be closed honestly.

## Phase 0 — Repo and VM baseline

- [x] Public fork `richardjr/monarchy` of `omacom/omarchy`; `main` based on tag `v4.0.2`, the exact commit the installed 4.0.2 packages were built from.
- [x] VM stack chosen and scripted: libvirt + virt-manager, `monarchy/vm/create.sh`, runbook in [`vm/README.md`](vm/README.md) (D007). Stock 4.0.2 installed twice from the official ISO on the laptop, proving the script.
- [ ] Per dev machine (laptop, desktop): run [`vm/README.md`](vm/README.md) sections 1 to 4 through to the `stock-4.0.2` restore point. Desktop done 2026-09-09 (NVIDIA host, so a software-rendered guest; see D007). Laptop status on 2026-09-08: VM installed, guest bootstrap not yet run; re-run the bootstrap there, it gained passwordless sudo and the test-dependency clones.
- [x] In the VM: `omarchy dev link ~/monarchy` over the share (runbook section 5). Desktop 2026-09-09: `omarchy version` prints `dev (1566f10c)`, `./test/all` passes all 210 files, desktop screenshot matches stock.
- [x] Screenshot loop: `omarchy capture screenshot fullscreen save` inside the VM, copied to the host for inspection (runbook section 6). Proven on the desktop 2026-09-09.
- [ ] Prove the upstream merge path once: merge the next upstream tag into `main` in a scratch branch and run the tests. `v4.0.3` exists and is a fast-forward of `v4.0.2`, so it is the candidate.
- [ ] Optional: unattended VM installs via the ISO's `cidata` path (`manual/51-unattended-installs.md`) to replace the hand-driven configurator on rebuilds.

Done when the edit → push → pull-in-VM → `omarchy-restart-shell` loop takes under a minute and the dev-linked VM behaves exactly like stock.

## Phase 1 — Bridge console

The brief's three steps survive, with "CSS" becoming "QML" because Omarchy 4 has no Waybar. Target design decided 2026-09-09 (D008): design canvas "Bridge Console", option P with the hybrid tab rule and logo L.

Status 2026-09-09: steps 1 and 2 have a first cut running in the VM (panel, header with logo, focus tab, workspace tabs, stock widgets; `omarchy toggle bridge`). Open: window title bands and the hybrid join (Quickshell overlays aligned to window geometry), system meters, theme keys beyond `[bridge]` sizes and colours, and a stray "another handler is registered for target omarchy.bar" warning at shell start with a plugin bar selected.

1. **Config only.** In the fork's `default/hypr/looknfeel.lua`: `general.layout = "master"`, `master.orientation = "left"`, `mfact` tuned, `gaps_out` reduced to zero on the panel side so the master window abuts the panel, active border colour driven by the theme. Live with it before drawing anything.
2. **Panel.** A new first-party bar plugin at `shell/plugins/bridge/` with id `monarchy.bridge` and `kind: "bar"`, forked from `omarchy.bar`. Left-anchored, wider than the stock 28 px vertical bar, coloured segment blocks, elbows drawn in QML, and an active-window indicator aligned to the focused window's geometry via Quickshell's Hyprland module. `config/omarchy/shell.json` defaults select it. Stock widgets (workspaces, clock, audio, agents, tray) are reused, not rewritten.
3. **Theme hooks.** Panel colours, segment sizes and elbow radii come from new keys in `default/themed/shell.toml.tpl` with sane defaults, so every upstream theme still renders with the bridge bar.

Done when a screenshot shows the panel and the master window as one joined shape, and it has been used daily for a week without reverting.

## Phase 2 — Phosphor and theme switching

- `themes/phosphor/`: `colors.toml`, `shell.toml`, `hyprland.lua`, `backgrounds/`, `preview.png`, `icons.theme`, `neovim.lua`. Green CRT: phosphor green on near-black, one accent, low-saturation greys.
- Verify every template under `default/themed/` renders and that Claude Code, terminals, btop, Chromium and the lock screen all follow.
- Font choice recorded in `DECISIONS.md` with licence; no franchise fonts.
- Then `amber` and `special-order` as variants sharing the shell keys from phase 1.

Done when `omarchy theme set phosphor` restyles everything, and every stock upstream theme still works with the bridge bar.

## Phase 3 — Monarch v1

Omarchy 4 already wires Claude Code (lazy launcher, default-agent picker, `omarchy agent prompt`, usage panel, crash diagnosis, the `omarchy` skill symlinked into `~/.claude/skills`). Monarch is a layer on top of that.

- Persona: `default/agents/skills/monarch/SKILL.md` with the steward tone and a machine-context procedure (current theme, shell layout, Hyprland state, pending updates, recent migrations). Symlinked alongside the `omarchy` skill.
- `bin/monarch`: thin wrapper that launches the default agent with the Monarch skill and system context loaded. Claude Code stays the default agent.
- First system capabilities, read-only first: explain this machine's configuration, summarise pending updates, switch theme on request. Mutating actions confirm before acting.

Done when `monarch` in the VM correctly answers "what theme am I running and why is the bar on the left", and switches to Phosphor when asked.

## Phase 4 — Layout plugin (conditional)

Only if phase 1 leaves a real geometric gap that config and QML cannot close. A Hyprland `IHyprLayout` plugin in C++, with hy3 and hyprscrolling as references. This is the point at which Hyprland must be pinned (`IgnorePkg` plus builds against pinned headers), which is why pinning is deferred until then.

## Phase 5 — ISO (optional)

Fork `omacom/omarchy-iso` and build with `omarchy-iso-make --local-source ../monarchy ../omarchy-pkgs`. Its `omarchy-iso-boot` and `omarchy-iso-test` scripts already boot and drive an install in headless QEMU, and the `cidata` autoinstall path makes unattended VM installs possible. This is the phase where a `monarchy` package name would first matter.

## Upstream tracking

- `main` is Monarchy. `quattro` is a read-only mirror of upstream's development branch, kept for reference and cherry-picks.
- Merge upstream **release tags** only (`v4.0.3`, `v4.1.0`, …). Tags have been linear so far (`v4.0.0 → v4.0.1 → v4.0.2`), while `quattro` has diverged from them; merging tags keeps the checkout aligned with the packages an installed machine actually runs.
- Procedure lives in [`AGENTS.md`](AGENTS.md).
