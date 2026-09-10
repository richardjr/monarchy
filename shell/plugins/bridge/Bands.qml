import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import "widgets/Bridge.js" as Bridge

// monarchy: window title bands (D008). One click-through overlay per screen
// that draws a band in the strip Hyprland reserves above every tiled window
// (see the gaps in default/hypr/looknfeel.lua). The focused window's band
// takes the accent, the others are dim; the far end is chamfered. Geometry
// comes from the Hyprland IPC toplevel objects, so nothing here touches the
// windows themselves. Bands sit on the Top layer, so a fullscreen window
// covers them.
PanelWindow {
  id: root

  required property var bar
  required property var bandScreen

  screen: bandScreen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "monarchy-bridge-bands"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Input reaches only the bands; everything else falls through to the
  // windows underneath. The list is rebuilt whenever the band set changes.
  mask: Region {
    id: inputMask
  }

  readonly property int bandHeight: Bridge.num(Color.shellValues, "bridge.band-height", 32)
  readonly property int chamfer: Bridge.num(Color.shellValues, "bridge.band-chamfer", 16)
  // Hyprland's general.border_size; the band spans the window including its
  // border so the two edges line up.
  readonly property int border: Bridge.num(Color.shellValues, "bridge.band-border", 2)
  readonly property color activeFill: Color.flatColor(Color.pick("bridge.band-active", "accent"), Color.accent)
  readonly property color activeText: Color.flatColor(Color.pick("bridge.band-active-text", "background"), Color.background)
  // Bands sit on the wallpaper, so the dim fill is blended to an opaque
  // colour over the theme background instead of being left translucent.
  readonly property color inactiveFill: Bridge.blend(Color.background,
    Color.flatColor(Color.pick("bridge.band-inactive", "foreground"), Color.foreground),
    Color.pickAlpha("bridge.band-inactive-alpha", 0.12))
  readonly property color inactiveText: Color.composed("bridge.band-inactive-text", "bridge.band-inactive-text-alpha", Color.foreground, 0.6)

  // The Hyprland monitor backing this screen, matched by output name.
  readonly property var monitor: {
    var values = Hyprland.monitors.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === root.bandScreen.name) return values[i]
    }
    return null
  }

  // Tiled, mapped toplevels on this monitor's active workspace, with their
  // band rectangles in screen-local logical pixels.
  property var bands: []
  property string bandsSignature: ""

  function rebuild() {
    var out = []
    var signature = ""
    var mon = root.monitor
    if (mon) {
      var ws = mon.activeWorkspace
      var values = Hyprland.toplevels.values
      for (var i = 0; i < values.length; i++) {
        var top = values[i]
        var ipc = top.lastIpcObject
        if (!ipc || !ipc.at || !ipc.size) continue
        if (top.monitor !== mon || !ws || top.workspace !== ws) continue
        if (ipc.mapped === false || ipc.hidden === true || ipc.floating === true) continue
        if (ipc.fullscreen && Number(ipc.fullscreen) !== 0) continue
        var x = Number(ipc.at[0]) - mon.x - root.border
        var y = Number(ipc.at[1]) - mon.y - root.border - root.bandHeight
        var w = Number(ipc.size[0]) + 2 * root.border
        if (!isFinite(x) || !isFinite(y) || !isFinite(w) || w <= 0) continue
        out.push({
          key: top.address,
          toplevel: top,
          x: Math.round(x),
          y: Math.round(y),
          width: Math.round(w)
        })
        signature += top.address + ":" + Math.round(x) + "," + Math.round(y) + "," + Math.round(w) + ";"
      }
    }
    // Title and focus are bound live on each band, so the model is only
    // replaced when the set of windows or their geometry changes; a fresh
    // array every poll would rebuild every delegate.
    if (signature === root.bandsSignature) return
    root.bandsSignature = signature
    root.bands = out
  }

  // Hyprland has no resize event, so besides refreshing on the events that
  // reshape a workspace the geometry is re-read on a slow tick while there is
  // anything to draw.
  readonly property var layoutEvents: ({
    openwindow: true, closewindow: true, movewindow: true, movewindowv2: true,
    changefloatingmode: true, fullscreen: true, workspace: true, workspacev2: true,
    focusedmon: true, focusedmonv2: true, activewindow: true, activewindowv2: true,
    configreloaded: true, monitoradded: true, monitorremoved: true,
    createworkspace: true, destroyworkspace: true, moveworkspace: true,
    togglegroup: true, moveintogroup: true, moveoutofgroup: true, pin: true
  })

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (root.layoutEvents[event.name]) refreshDebounce.restart()
    }
  }

  Timer {
    id: refreshDebounce
    interval: 60
    onTriggered: Hyprland.refreshToplevels()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.visible
    onTriggered: Hyprland.refreshToplevels()
  }

  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() { root.rebuild() }
  }

  Connections {
    target: Hyprland
    function onActiveToplevelChanged() { root.rebuild() }
  }

  onMonitorChanged: rebuild()

  // lastIpcObject changes on each toplevel do not bubble up through the
  // model, so watch them per instance.
  Instantiator {
    model: Hyprland.toplevels
    delegate: QtObject {
      required property var modelData
      readonly property Connections watcher: Connections {
        target: modelData
        function onLastIpcObjectChanged() { root.rebuild() }
        function onTitleChanged() { root.rebuild() }
        function onActivatedChanged() { root.rebuild() }
      }
    }
  }

  Component.onCompleted: {
    Hyprland.refreshToplevels()
    rebuild()
  }

  Repeater {
    id: bandRepeater
    model: root.bands

    onItemAdded: root.syncMask()
    onItemRemoved: root.syncMask()

    delegate: Item {
      id: band

      required property var modelData
      readonly property var toplevel: modelData.toplevel
      // Focus comes from the Wayland handle: it carries the current state
      // when the shell starts, where the Hyprland-side flag only follows the
      // next focus event.
      readonly property var handle: toplevel ? toplevel.wayland : null
      readonly property bool focused: handle ? handle.activated : false
      readonly property color fill: focused ? root.activeFill : root.inactiveFill
      readonly property int cut: Math.min(root.chamfer, root.bandHeight)
      readonly property string title: toplevel ? (toplevel.title || (toplevel.lastIpcObject ? toplevel.lastIpcObject["class"] : "") || "") : ""

      x: modelData.x
      y: modelData.y
      width: modelData.width
      height: root.bandHeight
      onXChanged: root.syncMask()
      onYChanged: root.syncMask()
      onWidthChanged: root.syncMask()

      // Drawn from rectangles rather than a Shape so it renders the same on
      // the software scene graph: the body, the strip under the chamfer, and
      // a rotated square clipped to the corner for the 45-degree cut.
      Rectangle {
        x: 0
        y: 0
        width: Math.max(0, band.width - band.cut)
        height: band.height
        color: band.fill
      }
      Rectangle {
        x: Math.max(0, band.width - band.cut)
        y: band.cut
        width: Math.min(band.cut, band.width)
        height: Math.max(0, band.height - band.cut)
        color: band.fill
      }
      Item {
        x: Math.max(0, band.width - band.cut)
        y: 0
        width: Math.min(band.cut, band.width)
        height: band.cut
        clip: true
        Rectangle {
          readonly property real side: band.cut * Math.SQRT2
          x: -side / 2
          y: band.cut - side / 2
          width: side
          height: side
          rotation: 45
          antialiasing: true
          color: band.fill
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: parent
        anchors.leftMargin: Style.space(16)
        anchors.rightMargin: root.chamfer + Style.space(4)
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        text: band.title
        color: band.focused ? root.activeText : root.inactiveText
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.weight: band.focused ? Font.Bold : Font.Normal
        elide: Text.ElideLeft
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
          if (!band.handle) return
          if (mouse.button === Qt.MiddleButton) band.handle.close()
          else band.handle.activate()
        }
      }
    }
  }

  // Deferred: the Repeater signals arrive while its delegates are still
  // being built, and creating mask regions against half-built items inside
  // that pass is not safe.
  function syncMask() { Qt.callLater(root.applyMask) }

  function applyMask() {
    var regions = []
    for (var i = 0; i < bandRepeater.count; i++) {
      var item = bandRepeater.itemAt(i)
      if (item) regions.push(bandRegion.createObject(inputMask, { item: item }))
    }
    var old = inputMask.regions
    inputMask.regions = regions
    for (var j = 0; j < old.length; j++) if (old[j]) old[j].destroy()
  }

  Component {
    id: bandRegion
    Region {}
  }
}
