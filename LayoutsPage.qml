import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The layouts in use, with editable names, and a place for the layout editor to come.
Column {
  id: root

  property var service: null
  readonly property var layouts: service ? service.layouts : []
  readonly property var problems: service ? service.layoutProblems : []
  property string note: ""
  property bool armed: false
  property string deletedName: ""

  Component.onDestruction: if (service) service.undoLayouts = null

  // Shown when a layout has no glyph, and the choices offered when editing one.
  readonly property string defaultIcon: "\uebeb"
  readonly property var glyphs: ["\ueb56", "\ueb57", "\uf009", "\uebeb", "\uebec", "\uebed", "\uebee",
    "\uebf1", "\uebf2", "\uebf3", "\uebf4", "\uebf5", "\uebf7", "\uec00", "\uec01", "\uec02"]

  signal focusRequested()

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // Which layout the zone editor is open for: "" when closed, "new" for a new layout.
  property string editorFor: ""
  readonly property bool editorOpen: editorFor !== ""

  ZoneEditor {
    visible: root.editorOpen
    width: root.width
    service: root.service
    layoutId: root.editorFor === "new" ? "" : root.editorFor
    onFinished: root.editorFor = ""
  }

  Column {
    id: listView
    visible: !root.editorOpen
    width: root.width
    spacing: root.spacing


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
            width: parent.width - Style.space(40) - editButton.width - Style.space(12) - (trashButton.visible ? trashButton.width + Style.space(12) : 0)
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

          // Deletes the layout at once; the note offers Undo. The last layout stays.
          Button {
            id: trashButton
            visible: root.layouts.length > 1
            anchors.verticalCenter: parent.verticalCenter
            text: "\uea81"
            bordered: true
            tooltipText: strings.t("layouts.delete.tip")
            onClicked: {
              var name = layoutRow.modelData.name || layoutRow.modelData.id
              if (root.service && root.service.deleteLayout(layoutRow.modelData.id)) {
                root.deletedName = name
                root.note = ""
              }
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

        // Opens the zone editor for this layout.
        Button {
          visible: layoutRow.editing
          text: strings.t("layouts.zones")
          bordered: true
          onClicked: { layoutRow.finish(true); root.editorFor = layoutRow.modelData.id }
        }
      }
    }

    Row {
      visible: root.deletedName !== "" && root.service && root.service.undoLayouts !== null
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("layouts.deleted") + ": " + root.deletedName
        color: Qt.darker(Commons.Color.foreground, 1.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      PageLink {
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("layouts.undo")
        onClicked: { if (root.service) root.service.undoDelete(); root.deletedName = "" }
      }
    }

    Button {
      text: strings.t("layouts.new")
      bordered: true
      onClicked: root.editorFor = "new"
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

    // Layouts left out because their zones are wrong.
    Column {
      visible: root.problems.length > 0
      width: parent.width
      spacing: Style.space(4)

      Text {
        textFormat: Text.PlainText
        width: parent.width
        wrapMode: Text.WordWrap
        text: "! " + strings.t("layouts.problems")
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Repeater {
        model: root.problems
        Text {
          required property string modelData
          textFormat: Text.PlainText
          width: root.width
          wrapMode: Text.WordWrap
          text: modelData
          color: Qt.darker(Commons.Color.foreground, 1.3)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }

    Item {
      width: root.width
      height: Math.max(openLink.implicitHeight, restoreButton.height)

      PageLink {
        id: openLink
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("layouts.openfile")
        onClicked: if (root.service) root.service.openLayoutsFile()
      }

      Button {
        id: restoreButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.armed ? strings.t("layouts.restore.confirm") : strings.t("layouts.restore")
        bordered: true
        onClicked: {
          if (!root.armed) { root.armed = true; armTimer.restart(); return }
          root.armed = false
          if (root.service) root.service.restoreLayouts(function(name) {
            root.note = name === "" ? strings.t("layouts.restored.none") : strings.t("layouts.restored") + " " + name
          })
        }
      }

      // The first click only arms the button; it disarms itself after a few seconds.
      Timer { id: armTimer; interval: 5000; onTriggered: root.armed = false }
    }

    Text {
      visible: root.note !== ""
      textFormat: Text.PlainText
      width: parent.width
      wrapMode: Text.WordWrap
      text: root.note
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

  }
}
