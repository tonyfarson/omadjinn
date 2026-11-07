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

  // Plain text, then a link in the accent colour, one line each.
  Repeater {
    model: [
      { label: "about.learn.omadjinn", url: "https://github.com/tonyfarson/omadjinn" },
      { label: "about.learn.me", url: "https://farsononline.com" }
    ]

    Row {
      required property var modelData
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        text: strings.t("about.learn")
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      PageLink {
        text: strings.t(modelData.label)
        font.pixelSize: Style.font.body
        onClicked: Qt.openUrlExternally(modelData.url)
      }
    }
  }
}
