import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// About: what it does and where to find more. Links and the version live in the panel frame.
Column {
  id: root

  property var service: null

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Repeater {
    model: ["help.what", "help.settings", "help.more"]

    Text {
      required property string modelData
      width: root.width
      textFormat: Text.StyledText
      wrapMode: Text.WordWrap
      text: strings.t(modelData)
      color: Commons.Color.foreground
      linkColor: Commons.Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      onLinkActivated: function(link) { Qt.openUrlExternally(link) }
    }
  }
}
