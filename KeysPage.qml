import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The keys Omadjinn registers: description, bind, and an Edit button (a placeholder for now).
Column {
  id: root

  property var service: null
  readonly property var chosen: service && service.config && service.config.keys ? service.config.keys : ({})

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  PanelSectionHeader {
    text: strings.t("page.keys")
  }

  // Column headings. The edit column has none.
  Row {
    width: root.width
    spacing: Style.space(12)
    Text {
      width: root.width * 0.5
      textFormat: Text.PlainText
      text: strings.t("keys.description")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
    Text {
      textFormat: Text.PlainText
      text: strings.t("keys.bind")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  Repeater {
    model: Model.KEY_ACTIONS

    Row {
      required property var modelData
      width: root.width
      spacing: Style.space(12)

      Text {
        width: root.width * 0.5
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        elide: Text.ElideRight
        text: modelData.label
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      Text {
        width: root.width * 0.5 - editButton.width - Style.space(24)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        elide: Text.ElideRight
        text: (modelData.id in root.chosen) ? root.chosen[modelData.id] : modelData.key
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      Button {
        id: editButton
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("edit")
        bordered: true
        // Placeholder: editing a bind is not built yet.
      }
    }
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
