import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// A small picture of a layout, drawn from its zones (fractions [x, y, w, h] of the screen).
// Any layout gets one, built in or custom, so no icon has to be made by hand.
// Colours come from the theme (override `color` where a surface has its own text colour).
Item {
  id: root

  property var zones: []
  property color color: Commons.Color.foreground

  width: Style.space(28)
  height: Style.space(18)

  // The screen.
  Rectangle {
    anchors.fill: parent
    radius: Style.space(2)
    color: "transparent"
    border.width: 1
    border.color: Util.alpha(root.color, 0.6)
  }

  Repeater {
    model: root.zones

    Rectangle {
      required property var modelData
      x: modelData[0] * root.width + 1.5
      y: modelData[1] * root.height + 1.5
      width: Math.max(2, modelData[2] * root.width - 3)
      height: Math.max(2, modelData[3] * root.height - 3)
      color: Util.alpha(root.color, 0.25)
      border.width: 1
      border.color: root.color
    }
  }
}
