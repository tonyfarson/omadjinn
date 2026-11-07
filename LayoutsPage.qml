import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The layouts in use, with editable names, and a place for the layout editor to come.
Column {
  id: root

  property var service: null
  readonly property var layouts: service ? service.layouts : []

  signal focusRequested()

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  PanelSectionHeader {
    text: strings.t("settings.layouts")
  }

  Repeater {
    model: root.layouts

    Row {
      required property var modelData
      width: root.width
      spacing: Style.space(12)

      Text {
        textFormat: Text.PlainText
        width: Style.space(28)
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: modelData.icon || ""
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.title
      }

      TextField {
        width: parent.width - Style.space(40)
        text: modelData.name || modelData.id
        // Save when the field is left or Enter is pressed, not per keystroke.
        onEditingFinished: {
          // Hand keyboard focus back to the panel so Esc works again.
          root.focusRequested()
          var name = text.trim()
          if (name === "") { text = modelData.name || modelData.id; return }
          if (name !== modelData.name && root.service) root.service.renameLayout(modelData.id, name)
        }
      }
    }
  }

  PanelSectionHeader {
    topPadding: Style.space(12)
    text: strings.t("layouts.custom")
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    wrapMode: Text.WordWrap
    text: strings.t("layouts.custom.soon")
    color: Qt.darker(Commons.Color.foreground, 1.5)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
