# Monarchy — founding brief

Written 2026-09-08, before the Omarchy 4 ("Quattro") audit. This is the statement of intent. Where it conflicts with how Omarchy 4 actually works (Waybar is gone, Omarchy is a pacman package), [`ROADMAP.md`](ROADMAP.md) and [`DECISIONS.md`](DECISIONS.md) take precedence.

An AI-embedded, retro-sci-fi desktop built on Arch Linux and Hyprland. Started as a personal fork of Omarchy; intended to become an opinionated spin with its own identity, theming and an integrated assistant called Monarch.

## What Monarchy is (and isn't)

- It is a spin, not a distro. Arch stays Arch. We do not run our own package repository or rebuild packages. Monarchy is an installer, a package manifest, a set of dotfiles/configs, themes, and the Monarch assistant layered on top of stock Arch, the official repos and the AUR.
- It is a fork of Omarchy in spirit and initially in code. Omarchy already does most of what we want; we strip what we don't like, add what we do, and keep our own configs. Decide deliberately how much upstream we track.
- A bootable ISO is a later, optional step via archiso. Not a phase-1 goal.

## Stack

- Arch Linux (rolling), installed via archinstall or a scripted installer
- Hyprland as the compositor, with a pinned version (plugin ABI breaks on updates; upgrade on a schedule, not ad hoc)
- Waybar for the main bar/sidebar; Quickshell (QML) or AGS if we need shapes CSS can't do
- Launcher, terminal, notifications, lock screen etc. inherited from Omarchy unless replaced for a reason
- Claude Code as the primary AI runtime for coding; Monarch wraps and extends it for system-level tasks

## The layout: bridge console

The defining visual idea. Think starship-bridge control panel: a persistent panel down the left edge, one dominant active window, other windows stacked, and the active window visually "flowing" into the panel (matching colours, joined edges, elbow shapes).

Approach, in order — do not skip ahead:

1. **Config only.** Hyprland master layout with orientation = left. Per-window border colours so the focused window matches its sidebar segment. Rounding and gaps tuned to suit.
2. **Chrome.** Left-anchored Waybar styled with CSS: coloured blocks, rounded elbows, active-window indicator that lines up with the focused window. Move to Quickshell/AGS only if CSS can't draw the joining shapes.
3. **Layout plugin.** Only if 1+2 leave a real geometric gap. Hyprland IHyprLayout plugin in C++ (see hy3, hyprscrolling as references). Never a new window manager.

## Theming: retro sci-fi, not any one franchise

Monarchy ships multiple themes sharing the same layout. Themes are the place for homage; the project identity is original.

Planned themes:

- **Phosphor** — green CRT terminal. First theme to build.
- **Amber** — amber phosphor variant.
- **Special Order** — dark, industrial, "commercial towing vessel" feel.
- Others as they occur. Keep names evocative, not borrowed.

Theme engine should be one place to change palette, fonts, bar shapes and border colours across Hyprland, Waybar, terminal, launcher and GTK/Qt apps.

## Monarch (the assistant)

- Monarch is the name the user addresses the AI by. Monarchy is the OS; Monarch is the voice of it.
- Phase 1: Claude Code embedded and configured out of the box for development work.
- Later: system-level assistance (package management, config changes, troubleshooting), theme switching, and whatever else fits the "ship's computer" role. Design for the assistant to have context about this machine's configuration.
- Tone: calm, capable, understated. Ship's steward, not overlord.

## Naming and IP — important

- Do not use "LCARS" anywhere in project name, package names, repo names, theme names or marketing. It is CBS/Paramount property with a history of enforcement against small developers.
- Do not name the project, packages or the assistant after protected franchise elements. Franchise inspiration in a theme is fine; recognisable trademarks, character/ship names as product identity, and pixel-faithful recreations of franchise UIs are not.
- Do not use franchise fonts (e.g. Swiss 911 for a Trek look). Pick open alternatives.
- Original names only for anything user-facing: Monarchy, Monarch, Phosphor, Amber, Special Order.

## Working method

- Always develop against a VM (quickemu or virt-manager) with a clean snapshot. Run the installer end to end; never assume a config works from reading it.
- Take screenshots (grim) after visual changes and inspect them. Layout and theming work is not done until it has been looked at.
- Keep the installer idempotent and re-runnable.
- Everything lives in git: installer, package list, dotfiles, themes, assistant config. One repo to start; split later only if needed.
- Prefer editing Omarchy's existing scripts over rewriting them until the divergence is large enough that a rewrite is clearer.

## Phases

1. **Fork and baseline** — Omarchy fork installs cleanly in a VM under the Monarchy name. Nothing visual changed yet.
2. **Bridge console** — master layout, left sidebar, active-window colour flow, first pass at elbow shapes. Live with it.
3. **Phosphor** — first full theme and the theme-switching mechanism.
4. **Monarch v1** — Claude Code preconfigured, plus a thin wrapper for the first system tasks.
5. **Layout plugin** — only if phase 2 proves insufficient.
6. **ISO** — optional, via archiso.

## Open questions

- How closely to track Omarchy upstream vs. hard-fork.
- Waybar vs. Quickshell for the sidebar — decide after phase 2 attempt in CSS.
- What Monarch's first non-coding capabilities should be.
