import QtQuick
import qs.Commons
import qs.Commons as Commons

// A small underlined-on-hover link in the theme's accent colour.
Text {
  id: root

  property color linkColor: Commons.Color.accent
  signal clicked()

  textFormat: Text.PlainText
  color: linkColor
  font.family: Style.font.family
  font.pixelSize: Style.font.caption
  font.underline: area.containsMouse

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
