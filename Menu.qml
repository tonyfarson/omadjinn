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
  // The row the keyboard or mouse is on; -1 means none yet.
  property int selected: -1

  // The shell fills this in with the plugin's service when it loads the overlay.
  property var service: null
  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

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
    root.selected = -1
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

  function choose(index) {
    if (root.service) root.service.snapToZone(root.address, index)
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
        Keys.onPressed: function(event) {
          var n = root.zones.length
          if (event.key === Qt.Key_Escape) {
            root.dismiss()
          } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J) {
            root.selected = n > 0 ? (root.selected + 1) % n : -1
          } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || event.key === Qt.Key_K) {
            root.selected = n > 0 ? (root.selected <= 0 ? n - 1 : root.selected - 1) : -1
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.selected >= 0 && root.selected < n) root.choose(root.selected)
          } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            if (root.service) root.service.cycle("prev")
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            if (root.service) root.service.cycle("next")
          } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            var index = event.key - Qt.Key_1
            if (index < n) root.choose(index)
          } else {
            return
          }
          event.accepted = true
        }
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
          text: strings.t("menu.title") + "  ·  " + (root.layout ? String(root.layout.name || root.layout.id).toUpperCase() : "")
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
            color: root.selected === row.index ? root.hoverFill : "transparent"

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
              anchors.right: keyHint.left
              anchors.verticalCenter: parent.verticalCenter
              text: Model.zoneName(row.modelData)
              color: root.text
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            // The number key that picks this row.
            Text {
              id: keyHint
              textFormat: Text.PlainText
              anchors.right: parent.right
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              visible: row.index < 9
              text: String(row.index + 1)
              color: Util.alpha(root.text, 0.45)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: rowArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.selected = row.index
              onClicked: root.choose(row.index)
            }
          }
        }

        // A thin line, then the layout row: the name, and arrows to cycle.
        Rectangle {
          width: parent.width
          height: 1
          color: Util.alpha(root.text, 0.2)
        }

        Item {
          width: column.width
          height: root.rowHeight

          Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.leftMargin: Style.space(8)
            anchors.right: prevArrow.left
            anchors.verticalCenter: parent.verticalCenter
            text: strings.t("menu.layout") + ": " + (root.layout ? String(root.layout.name || root.layout.id) : "")
            color: Util.alpha(root.text, 0.8)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }

          Repeater {
            model: [{ glyph: "\u2039", dir: "prev" }, { glyph: "\u203A", dir: "next" }]

            Rectangle {
              id: arrow
              required property var modelData
              required property int index
              property alias hovered: arrowArea.containsMouse
              width: root.rowHeight
              height: root.rowHeight
              radius: Style.cornerRadius / 2
              x: parent.width - root.rowHeight * (2 - index)
              color: arrowArea.containsMouse ? root.hoverFill : "transparent"

              Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: arrow.modelData.glyph
                color: arrowArea.containsMouse ? root.accent : root.text
                font.family: Style.font.family
                font.pixelSize: Style.font.title
              }

              MouseArea {
                id: arrowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.service) root.service.cycle(arrow.modelData.dir)
              }
            }
          }

          // Anchor for the label's right edge: the left edge of the arrow pair.
          Item { id: prevArrow; x: parent.width - root.rowHeight * 2; width: 0; height: 1 }
        }
      }
    }
  }
}
