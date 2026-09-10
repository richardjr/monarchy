// Shared helpers for the bridge widgets. Colours and sizes come from the
// [bridge] section of shell.toml through the Color singleton's flat dict.
.pragma library

function num(values, key, fallback) {
  var v = Number(values ? values[key] : undefined)
  return isFinite(v) && v > 0 ? v : fallback
}

function workspaceLabel(workspace, id) {
  var title = ""
  if (workspace && workspace.toplevels && workspace.toplevels.values.length > 0) {
    var top = workspace.toplevels.values[0]
    title = top ? (top.title || "") : ""
    if (title.length > 18) title = title.substr(0, 17) + "…"
  }
  return title ? String(id) + " · " + title : String(id)
}

// Opaque blend of `over` at `alpha` on top of `under`, for fills that sit on
// the wallpaper rather than the panel and would otherwise wash out.
function blend(under, over, alpha) {
  var a = Math.max(0, Math.min(1, Number(alpha)))
  return Qt.rgba(under.r * (1 - a) + over.r * a,
                 under.g * (1 - a) + over.g * a,
                 under.b * (1 - a) + over.b * a, 1)
}
