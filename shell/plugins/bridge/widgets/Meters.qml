import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Bridge.js" as Bridge

// System meters: cpu and memory as label rows over thin bars, and the number
// of pending Omarchy updates. Sits above the agents block in the panel (D008).
// cpu and memory come straight from procfs; the update count reuses
// omarchy-update-available, one line per pending update.
BarWidget {
  id: root
  moduleName: "monarchy.meters"

  readonly property int inset: Bridge.num(Color.shellValues, "bridge.inset", 14)
  readonly property int rightInset: Bridge.num(Color.shellValues, "bridge.tab-inactive-inset", 12)
  readonly property int meterHeight: Bridge.num(Color.shellValues, "bridge.meter-height", 6)
  readonly property int gap: Bridge.num(Color.shellValues, "bridge.meter-gap", 8)
  readonly property color fill: Color.flatColor(Color.pick("bridge.meter-fill", "accent"), Color.accent)
  readonly property color track: Color.composed("bridge.meter-track", "bridge.meter-track-alpha", Color.foreground, 0.12)
  readonly property color textColor: Color.composed("bridge.meter-text", "bridge.meter-text-alpha", Color.foreground, 0.6)

  property real cpu: 0
  property real mem: 0
  property int updates: 0
  property var lastCpu: null

  function clamp(v) { return Math.max(0, Math.min(1, isFinite(v) ? v : 0)) }

  // First line of /proc/stat: cpu user nice system idle iowait irq softirq steal
  function parseStat(text) {
    var line = String(text || "").split("\n")[0] || ""
    var f = line.trim().split(/\s+/).slice(1).map(Number)
    if (f.length < 4) return
    var total = 0
    for (var i = 0; i < f.length; i++) if (isFinite(f[i])) total += f[i]
    var idle = f[3] + (isFinite(f[4]) ? f[4] : 0)
    if (root.lastCpu) {
      var dt = total - root.lastCpu.total
      var di = idle - root.lastCpu.idle
      if (dt > 0) root.cpu = clamp(1 - di / dt)
    }
    root.lastCpu = { total: total, idle: idle }
  }

  function parseMeminfo(text) {
    var totalKb = 0, availKb = -1
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)/)
      if (!m) continue
      if (m[1] === "MemTotal") totalKb = Number(m[2])
      else availKb = Number(m[2])
    }
    if (totalKb > 0 && availKb >= 0) root.mem = clamp(1 - availKb / totalKb)
  }

  function runUpdate() {
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation omarchy-update")
  }

  FileView {
    id: statFile
    path: "/proc/stat"
    printErrors: false
    onLoaded: root.parseStat(text())
  }

  FileView {
    id: memFile
    path: "/proc/meminfo"
    printErrors: false
    onLoaded: root.parseMeminfo(text())
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload()
      memFile.reload()
    }
  }

  property int pendingLines: 0

  Process {
    id: updateProc
    command: ["omarchy-update-available"]
    stdout: SplitParser {
      onRead: function(line) { if (String(line).trim() !== "") root.pendingLines += 1 }
    }
    onStarted: root.pendingLines = 0
    onExited: function(exitCode) {
      root.updates = exitCode === 0 ? root.pendingLines : 0
    }
  }

  Timer {
    interval: 21600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!updateProc.running) updateProc.running = true
  }

  implicitWidth: barSize
  implicitHeight: column.implicitHeight

  // An Item wrapping the row's column, so a row can carry a MouseArea
  // without breaking the outer Column's anchoring rules.
  component MeterRow: Item {
    id: row
    property string label: ""
    property string value: ""
    property real level: -1
    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: rowColumn.implicitHeight

    Column {
      id: rowColumn
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: Style.space(4)

    Item {
      anchors.left: parent.left
      anchors.right: parent.right
      height: Math.max(labelText.implicitHeight, valueText.implicitHeight)

      Text {
        id: labelText
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        color: root.textColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        id: valueText
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: root.textColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Rectangle {
      visible: row.level >= 0
      anchors.left: parent.left
      anchors.right: parent.right
      height: root.meterHeight
      radius: height / 2
      color: root.track

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.round(parent.width * Math.max(0, Math.min(1, row.level)))
        radius: parent.radius
        color: root.fill
      }
    }
    }
  }

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.inset
    anchors.rightMargin: root.rightInset
    spacing: root.gap

    MeterRow { label: "cpu"; value: Math.round(root.cpu * 100) + "%"; level: root.cpu }
    MeterRow { label: "mem"; value: Math.round(root.mem * 100) + "%"; level: root.mem }
    MeterRow {
      id: updatesRow
      label: "updates"
      value: String(root.updates)

      MouseArea {
        anchors.fill: parent
        enabled: root.updates > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.runUpdate()
      }
    }
  }
}
