# Monarchy bridge console

The `monarchy.bridge` bar option: a 240 px labelled panel down the left edge,
decided in `monarchy/DECISIONS.md` D008 and drawn on the "Bridge Console"
design canvas.

- `manifest.json` declares the plugin (`id: monarchy.bridge`, `kind: bar`).
- `Bar.qml` and `BarModel.js` are a fork of `../bar/`. Every intentional
  difference is marked with a `monarchy:` comment; keep the rest verbatim so
  the stock widgets keep working and upstream changes can be re-applied.
- `widgets/` holds the bridge's own bar widgets, each with a sibling
  manifest: `monarchy.focus-tab` (the reserved top slot showing the focused
  window), `monarchy.header` (logo, wordmark, theme name) and `monarchy.tabs`
  (labelled workspace tabs with rounded outer ends).
- Sizes and colours come from the `[bridge]` section of the theme's
  `shell.toml` (see `default/themed/shell.toml.tpl`).

Select it with `omarchy toggle bridge on` (`off` restores the stock bar,
`--status` reports which is active). The command writes the bridge's bar block
into `~/.config/omarchy/shell.json`; the shipped `config/omarchy/shell.json`
stays stock so upstream's tests and migrations keep their assumptions. The
migration added alongside the plugin runs the command once for users still on
the shipped default. The shell hot-swaps bars when `shell.json` changes.

Two things the fork has to do differently from the built-in bar, both marked
in `Bar.qml`: the host injects `omarchyPath`, `barWidgetRegistry` and
`barConfig` after creation (a plugin bar loads through a `Loader` by URL), so
they are plain properties rather than `required`; and the IPC target is
`monarchy.bridge`, leaving `omarchy.bar` to the stock bar.
