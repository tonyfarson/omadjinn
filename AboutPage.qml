import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// About: a few words from the developer. Links and the version live in the panel frame.
Column {
  id: root

  property var service: null

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Repeater {
    model: ["about.bio1", "about.bio2"]

    Text {
      required property string modelData
      width: root.width
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      text: strings.t(modelData)
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
