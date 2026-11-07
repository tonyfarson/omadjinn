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

  Repeater {
    model: root.layouts

    Row {
      id: layoutRow
      required property var modelData
      // The name is read-only until Edit is clicked; the button then reads Save.
      property bool editing: false
      width: root.width
      spacing: Style.space(12)

      // Saves the name (or puts the old one back) and closes the field.
      function finish(save) {
        if (!editing) return
        editing = false
        root.focusRequested()
        var name = nameField.text.trim()
        if (!save || name === "") { nameField.text = modelData.name || modelData.id; return }
        if (name !== modelData.name && root.service) root.service.renameLayout(modelData.id, name)
      }

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
        id: nameField
        width: parent.width - Style.space(40) - editButton.width - Style.space(12)
        readOnly: !layoutRow.editing
        text: modelData.name || modelData.id
        // Enter or leaving the field saves; Esc puts the old name back.
        onEditingFinished: layoutRow.finish(true)
        Keys.onEscapePressed: layoutRow.finish(false)
      }

      // Edit opens the field with the cursor at the end of the name; Save closes it.
      Button {
        id: editButton
        anchors.verticalCenter: parent.verticalCenter
        text: layoutRow.editing ? strings.t("save") : strings.t("edit")
        bordered: true
        onClicked: {
          if (layoutRow.editing) { layoutRow.finish(true); return }
          layoutRow.editing = true
          nameField.forceActiveFocus()
          nameField.cursorPosition = nameField.text.length
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

  PageLink {
    text: strings.t("layouts.openfile")
    onClicked: if (root.service) root.service.openLayoutsFile()
  }
}
