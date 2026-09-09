import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Bridge.js" as Bridge

// Logo (D008 option L: a geometric M with a chamfered crown point), the
// wordmark and the current theme's name.
BarWidget {
  id: root
  moduleName: "monarchy.header"

  readonly property int inset: Bridge.num(Color.shellValues, "bridge.inset", 14)
  readonly property color accent: Color.flatColor(Color.pick("bridge.tab-active", "accent"), Color.accent)
  readonly property color textColor: root.bar ? root.bar.barForeground : Color.foreground
  property string themeName: ""

  implicitWidth: barSize
  implicitHeight: row.implicitHeight + Style.space(12)

  // omarchy-theme-current reads this file; the shell already tracks the
  // theme swap through Color, so re-read it whenever the palette changes.
  FileView {
    id: themeNameFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    onLoaded: root.themeName = String(text() || "").replace(/^\s+|\s+$/g, "")
    onFileChanged: reload()
  }

  Connections {
    target: Color
    function onShellValuesChanged() { themeNameFile.reload() }
  }

  Row {
    id: row
    anchors.left: parent.left
    anchors.leftMargin: root.inset
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(12)

    Item {
      id: logo
      width: 44
      height: 35
      anchors.verticalCenter: parent.verticalCenter

      Shape {
        width: 100
        height: 80
        transformOrigin: Item.TopLeft
        scale: logo.width / 100
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          fillColor: root.accent
          strokeWidth: -1
          PathSvg { path: "M6 74 L6 6 L22 6 L50 40 L78 6 L94 6 L94 74 L78 74 L78 32 L56 58 L44 58 L22 32 L22 74 Z" }
        }
        ShapePath {
          fillColor: root.accent
          strokeWidth: -1
          PathSvg { path: "M38 40 L50 14 L62 40 Z" }
        }
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {

        textFormat: Text.PlainText
        text: "MONARCHY"
        color: root.textColor
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.weight: Font.Bold
        font.letterSpacing: 2.5
      }
      Text {
        textFormat: Text.PlainText
        text: root.themeName
        visible: text !== ""
        color: root.textColor
        opacity: 0.6
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
      }
    }
  }
}
