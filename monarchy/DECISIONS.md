# Decisions

Dated, append-only. Newest at the bottom. Each entry: context, decision, consequences, alternatives considered.

## 2026-09-08 — D001: Overlay fork run through `omarchy dev link`

**Context.** Omarchy 4 is a pacman package (`omarchy` + `omarchy-settings`) installed to `/usr/share/omarchy`, not a git clone in `$HOME`. It ships `omarchy dev link <checkout>`, which points `OMARCHY_PATH` at a git checkout for `bin/`, `default/`, `shell/`, `themes/`, `applications/` and `config/`, and `omarchy dev pkg-test` for anything at fixed system paths.

**Decision.** Monarchy is a git fork of `omacom/omarchy` that is run as a dev-linked checkout over the stock `omarchy` package. The package stays installed for `/etc`, systemd units, keyring, pacman guard and updates.

**Consequences.** No package repo, no PKGBUILD maintenance, no ISO needed to test. A machine swaps between stock Omarchy and Monarchy with `omarchy dev link ~/Work/monarchy` / `omarchy dev unlink` plus a reboot. `omarchy update` fast-forwards the checkout as part of its run. Changes that need fixed system paths wait for phase 5 or go through `omarchy dev pkg-test`.

**Alternatives.** Hard fork with a renamed, locally built `monarchy` package (full identity, every upstream merge becomes a rename conflict). Plugin-and-theme-only spin on stock Omarchy (no control over defaults, thin identity). Both remain reachable later.

## 2026-09-08 — D002: Public GitHub fork

**Context.** The project was to be private, but GitHub cannot make a fork of a public repo private; a private copy would have to be a detached repo with no fork linkage.

**Decision.** Public fork `richardjr/monarchy` under the personal account, not the 3ADAPT org.

**Consequences.** Upstream link, "sync fork" and cross-repo PRs all work. MIT licence carries over.

## 2026-09-08 — D003: Keep `omarchy-*` names for now

**Decision.** Command names, paths, package names, plugin ids for existing components and the `~/.config/omarchy` tree stay as upstream has them. Monarchy identity lives in new, original things only: the `monarchy.bridge` bar plugin, the `phosphor` / `amber` / `special-order` themes, `bin/monarch`, the Monarch skill, branding assets and the `monarchy/` docs directory.

**Consequences.** Upstream merges stay cheap. A rename is a single deliberate later decision, not a slow drift.

## 2026-09-08 — D004: `main` on release tags, `quattro` as mirror

**Context.** Upstream develops on `quattro` and cuts releases on `v4-0-x` branches; tags `v4.0.0 → v4.0.1 → v4.0.2` are linear fast-forwards of each other, but `v4.0.2` and `quattro` have diverged (hundreds of commits each way). The installed 4.0.2 packages were built from exactly the `v4.0.2` commit (`346e69e`).

**Decision.** `main` is based on `v4.0.2` and merges upstream release tags only. `quattro` is kept in the fork as a read-only mirror. Fork was created default-branch-only; other upstream branches are fetched from the `upstream` remote when needed.

**Consequences.** The dev-linked checkout always matches the installed package generation, which is what makes `dev link` safe. New upstream features arrive with each release, not daily.

## 2026-09-08 — D005: Quickshell/QML for the bridge panel (resolves a brief open question)

**Context.** Omarchy 4 removed Waybar. The shell is one Quickshell process with a plugin registry; a full bar is a plugin of `kind: "bar"`, left placement is already supported, and first-party status is stamped by directory, so a `monarchy.*` id can be first-party.

**Decision.** The bridge console is a first-party Quickshell bar plugin forked from `omarchy.bar`. The brief's "CSS first, QML if needed" step collapses into QML.

## 2026-09-08 — D006: Hyprland stays unpinned until a layout plugin exists

**Context.** Omarchy tracks Hyprland from `extra` and drives pacman through `omarchy update`; pinning fights that flow. Plugin ABI breakage only matters for a compiled layout plugin.

**Decision.** Do not pin. Revisit at phase 4.

## Open

- VM stack on the dev machine: libvirt + virt-manager from `extra` (snapshots, virtiofs share; the ISO repo's QEMU scripts for ISO tests) versus quickemu from the AUR.
- Monarch's first non-coding capabilities beyond the read-only set in the roadmap.
- Font for Phosphor.
