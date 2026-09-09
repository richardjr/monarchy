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
