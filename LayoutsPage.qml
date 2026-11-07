import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The layouts in use, with editable names, and a place for the layout editor to come.
Column {
  id: root

  property var service: null
  readonly property var layouts: service ? service.layouts : []

  // Shown when a layout has no glyph, and the choices offered when editing one.
  readonly property string defaultIcon: "\uebeb"
  readonly property var glyphs: ["\ueb56", "\ueb57", "\uf009", "\uebeb", "\uebec", "\uebed", "\uebee",
    "\uebf1", "\uebf2", "\uebf3", "\uebf4", "\uebf5", "\uebf7", "\uec00", "\uec01", "\uec02"]

  signal focusRequested()

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Repeater {
    model: root.layouts

    Column {
      id: layoutRow
      required property var modelData
      // The name is read-only until Edit is clicked; the button then reads Save.
      // While editing, the glyph choices show under the name.
      property bool editing: false
      width: root.width
      spacing: Style.space(8)

      // Saves the name (or puts the old one back) and closes the field.
      function finish(save) {
        if (!editing) return
        editing = false
        root.focusRequested()
        var name = nameField.text.trim()
        if (!save || name === "") { nameField.text = modelData.name || modelData.id; return }
        if (name !== modelData.name && root.service) root.service.renameLayout(modelData.id, name)
      }

      Row {
        width: parent.width
        spacing: Style.space(12)

        // The layout's glyph, the same one the toast shows.
        Text {
          textFormat: Text.PlainText
          width: Style.space(28)
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignHCenter
          text: modelData.icon || root.defaultIcon
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

      // The glyph choices, while editing. Picking one saves it at once.
      Flow {
        visible: layoutRow.editing
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.glyphs

          Item {
            required property string modelData
            readonly property bool current: (layoutRow.modelData.icon || root.defaultIcon) === modelData
            width: pick.width
            height: pick.height

            Rectangle {
              anchors.fill: parent
              radius: Style.cornerRadius
              color: Commons.Color.accent
              visible: parent.current
            }

            Button {
              id: pick
              text: parent.modelData
              bordered: true
              fontSize: Style.font.title
              foreground: parent.current ? Commons.Color.background : Commons.Color.foreground
              onClicked: if (root.service) root.service.setLayoutIcon(layoutRow.modelData.id, parent.modelData)
            }
          }
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
