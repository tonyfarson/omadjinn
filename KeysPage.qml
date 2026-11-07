import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The keys Omadjinn registers. (The key list and recording come in the next steps.)
Column {
  id: root

  property var service: null

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  PanelSectionHeader {
    text: strings.t("page.keys")
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    wrapMode: Text.WordWrap
    text: strings.t("keys.soon")
    color: Qt.darker(Commons.Color.foreground, 1.5)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
