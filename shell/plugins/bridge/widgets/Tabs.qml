import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Bridge.js" as Bridge

// Workspace tabs: one per workspace, labelled with the workspace number and
// the title of its first window. Rounded on the outer end only; the focused
// workspace's tab takes the accent and runs to the panel's inner edge, the
// others stop short of it.
BarWidget {
  id: root
  moduleName: "monarchy.tabs"

  readonly property int tabHeight: Bridge.num(Color.shellValues, "bridge.tab-height", 32)
  readonly property int radius: Bridge.num(Color.shellValues, "bridge.tab-radius", 16)
  readonly property int inset: Bridge.num(Color.shellValues, "bridge.inset", 14)
  readonly property int gap: Bridge.num(Color.shellValues, "bridge.tab-gap", 6)
  readonly property int inactiveInset: Bridge.num(Color.shellValues, "bridge.tab-inactive-inset", 12)
  readonly property color activeFill: Color.flatColor(Color.pick("bridge.tab-active", "accent"), Color.accent)
  readonly property color activeText: Color.flatColor(Color.pick("bridge.tab-active-text", "background"), Color.background)
  readonly property color inactiveFill: Color.composed("bridge.tab-inactive", "bridge.tab-inactive-alpha", Color.foreground, 0.12)
  readonly property color inactiveText: root.bar ? root.bar.barForeground : Color.foreground

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  implicitWidth: barSize
  implicitHeight: column.implicitHeight

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.inset
    spacing: root.gap

    Repeater {
      model: root.workspaceIds()

      Item {
        id: tab
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property color fill: focused ? root.activeFill : root.inactiveFill

        width: parent.width - (focused ? 0 : root.inactiveInset)
        height: root.tabHeight
        opacity: occupied || focused ? 1 : 0.55

        Rectangle { anchors.fill: parent; radius: root.radius; color: tab.fill }
        Rectangle {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          width: root.radius
          color: tab.fill
        }

        Text {

          textFormat: Text.PlainText
          anchors.fill: parent
          anchors.leftMargin: Style.space(16)
          anchors.rightMargin: Style.space(12)
          verticalAlignment: Text.AlignVCenter
          text: Bridge.workspaceLabel(tab.workspace, tab.modelData)
          color: tab.focused ? root.activeText : root.inactiveText
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.weight: tab.focused ? Font.Bold : Font.Normal
          elide: Text.ElideRight
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(tab.modelData)
        }
      }
    }
  }
}
