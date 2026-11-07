import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The Omadjinn right-click menu: a small card that opens at the cursor when a
// floating window's titlebar is right-clicked, listing the zones of the current
// layout. Esc or a click outside closes it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string address: ""
  property real cursorX: 0
  property real cursorY: 0

  // The shell fills this in with the plugin's service when it loads the overlay.
  property var service: null
  readonly property var layout: service ? service.layoutById(service.currentId) : null
  readonly property var zones: layout && layout.zones ? layout.zones : []

  // Every colour comes from the selected Omarchy theme; nothing here is fixed.
  readonly property color accent: Commons.Color.accent
  readonly property color border: Commons.Color.menu.border
  readonly property color hoverFill: Commons.Color.menu.selectedBackground
  readonly property color text: Commons.Color.menu.text
  readonly property color background: Commons.Color.menu.background
  readonly property int rowHeight: Style.space(34)
  readonly property int pad: Style.space(10)

  function open(payloadJson) {
    var p = {}
    try { p = JSON.parse(payloadJson || "{}") } catch (e) {}
    root.address = String(p.address || "")
    root.cursorX = Number(p.x) || 0
    root.cursorY = Number(p.y) || 0
    root.opened = true
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function" && root.manifest)
      root.shell.hide(root.manifest.id)
  }

  // Step 2 of the prototype: choosing a zone only says so; snapping comes next.
  function choose(index) {
    Quickshell.execDetached(["omarchy", "osd", "-m", "Zone " + (index + 1) + ": " + Model.zoneName(root.zones[index]), "-d", "1200"])
    root.dismiss()
  }

  OverlayWindow {
    id: panel
    shown: root.opened
    WlrLayershell.namespace: "omadjinn-menu"

    // Where the card goes: at the cursor, kept on the screen.
    readonly property real originX: targetMonitor ? targetMonitor.x : 0
    readonly property real originY: targetMonitor ? targetMonitor.y : 0

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: root.dismiss()
    }

    Rectangle {
      id: card
      width: Style.space(230)
      height: column.implicitHeight + root.pad * 2
      radius: Style.cornerRadius
      color: root.background
      border.color: root.border
      border.width: Math.max(1, Style.space(2))
      x: Math.max(Style.space(8), Math.min(root.cursorX - panel.originX, panel.width - width - Style.space(8)))
      y: Math.max(Style.space(8), Math.min(root.cursorY - panel.originY, panel.height - height - Style.space(8)))

      MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: {} }

      Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onEscapePressed: root.dismiss()
      }

      Column {
        id: column
        x: root.pad
        y: root.pad
        width: card.width - root.pad * 2
        spacing: Style.space(2)

        Text {
          textFormat: Text.PlainText
          width: parent.width
          bottomPadding: Style.space(6)
          text: "OMADJINN  ·  " + (root.layout ? String(root.layout.name || root.layout.id).toUpperCase() : "")
          color: root.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.5
          elide: Text.ElideRight
        }

        Repeater {
          model: root.zones

          Rectangle {
            id: row
            required property var modelData
            required property int index
            width: column.width
            height: root.rowHeight
            radius: Style.cornerRadius / 2
            color: rowArea.containsMouse ? root.hoverFill : "transparent"

            // A tiny screen with this row's zone lit up.
            Rectangle {
              id: mini
              x: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(30)
              height: Style.space(19)
              radius: 2
              color: "transparent"
              border.color: Util.alpha(root.text, 0.45)
              border.width: 1

              Rectangle {
                x: 1 + row.modelData[0] * (mini.width - 2)
                y: 1 + row.modelData[1] * (mini.height - 2)
                width: Math.max(2, row.modelData[2] * (mini.width - 2))
                height: Math.max(2, row.modelData[3] * (mini.height - 2))
                radius: 1
                color: root.accent
              }
            }

            Text {
              textFormat: Text.PlainText
              anchors.left: mini.right
              anchors.leftMargin: Style.space(10)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: Model.zoneName(row.modelData)
              color: root.text
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            MouseArea {
              id: rowArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.choose(row.index)
            }
          }
        }
      }
    }
  }
}
