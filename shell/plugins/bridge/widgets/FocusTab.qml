import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Bridge.js" as Bridge

// The reserved top slot: the focused window's title as an accent tab whose
// fill runs to the panel's inner edge, where the focused window's band meets
// it (D008 hybrid rule). It keeps its height when nothing is focused so the
// header below never moves.
BarWidget {
  id: root
  moduleName: "monarchy.focus-tab"

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""
  readonly property int tabHeight: Bridge.num(Color.shellValues, "bridge.slot-height", 38)
  readonly property int radius: Bridge.num(Color.shellValues, "bridge.tab-radius", 16)
  readonly property int inset: Bridge.num(Color.shellValues, "bridge.inset", 14)
  readonly property color fill: Color.flatColor(Color.pick("bridge.tab-active", "accent"), Color.accent)
  readonly property color textColor: Color.flatColor(Color.pick("bridge.tab-active-text", "background"), Color.background)

  implicitWidth: barSize
  implicitHeight: tabHeight

  Item {
    anchors.fill: parent
    anchors.leftMargin: root.inset
    visible: root.title !== ""

    Rectangle {
      anchors.fill: parent
      radius: root.radius
      color: root.fill
    }
    // Square off the inner edge: the tab is rounded on its outer end only.
    Rectangle {
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      width: root.radius
      color: root.fill
    }

    Text {

      textFormat: Text.PlainText
      anchors.fill: parent
      anchors.leftMargin: Style.space(16)
      anchors.rightMargin: Style.space(12)
      verticalAlignment: Text.AlignVCenter
      text: root.title
      color: root.textColor
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.subtitle
      font.weight: Font.Bold
      elide: Text.ElideRight
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton) root.toplevel.close()
      else root.toplevel.activate()
    }
  }
}
