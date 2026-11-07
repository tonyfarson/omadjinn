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
  // The layout just deleted stays in its place as a dimmed row, with an undo button where
  // the trash button was, until you leave the page or close the panel.
  property var ghost: null   // { layout, index }
  readonly property var shown: {
    var list = layouts.slice()
    if (ghost) {
      list.splice(Math.min(ghost.index, list.length), 0, ghost.layout)
    }
    return list
  }

  function removeLayout(id) {
    if (!service) return
    var at = layouts.findIndex(function(x) { return x.id === id })
    if (at < 0) return
    var before = JSON.parse(JSON.stringify(layouts[at]))
    if (service.deleteLayout(id)) ghost = { layout: before, index: at }
  }

  function undoRemove() {
    if (service) service.undoDelete()
    ghost = null
  }

  function forgetDelete() {
    ghost = null
    if (service) service.undoLayouts = null
  }

  onVisibleChanged: if (!visible) forgetDelete()
  Component.onDestruction: forgetDelete()

  // Shown when a layout has no glyph, and the choices offered when editing one.
  readonly property string defaultIcon: "\uebeb"
  readonly property var glyphs: ["\ueab9", "\ueb56", "\ueb57", "\uf009", "\uebeb", "\uebec", "\uebed", "\uebee",
    "\uebf1", "\uebf2", "\uebf3", "\uebf4", "\uebf5", "\uebf7", "\uec00", "\uec01", "\uec02"]

  signal focusRequested()

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // Which layout the zone editor is open for: "" when closed, "new" for a new layout.
  property string editorFor: ""
  readonly property bool editorOpen: editorFor !== ""

  signal scrollRequested(real y)

  // Opening the editor starts it fresh and brings it into view.
  onEditorOpenChanged: {
    zoneEditor.load()
    if (editorOpen) scrollRequested(listView.y + zoneEditor.y - Style.space(8))
  }

  Column {
    id: listView
    width: root.width
    spacing: root.spacing


    Repeater {
      model: root.shown

      Column {
        id: layoutRow
        required property var modelData
        required property int index
        // After a delete the row is replaced, in the same space, by a restore bar.
        readonly property bool gone: root.ghost !== null && index === root.ghost.index
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

        // The restore bar: the size of a layout line, shown until you leave the page.
        Button {
          visible: layoutRow.gone
          width: parent.width
          height: Math.max(implicitHeight, nameField.implicitHeight)
          text: strings.t("layouts.restore.row")
          bordered: true
          onClicked: root.undoRemove()
        }

        Row {
          visible: !layoutRow.gone
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

          // Deletes the layout at once. The row is then replaced by a restore bar until you
          // leave the page. The last layout can't be deleted, so its trash button is hidden.
          Button {
            id: trashButton
            visible: root.layouts.length > 1
            anchors.verticalCenter: parent.verticalCenter
            text: "\uea81"
            bordered: true
            tooltipText: strings.t("layouts.delete.tip")
            // The work happens in functions on the page: deleting rebuilds this row, and
            // code running inside it would stop part way.
            onClicked: root.removeLayout(layoutRow.modelData.id)
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

    // New layout on the left, Restore defaults on the right.
    Item {
      width: root.width
      height: Math.max(newButton.height, restoreButton.height)

      Button {
        id: newButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("layouts.new")
        bordered: true
        onClicked: root.editorFor = "new"
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

    // The zone editor lives here, greyed out until New layout (or Edit zones) opens it.
    ZoneEditor {
      id: zoneEditor
      width: root.width
      enabled: root.editorOpen
      opacity: root.editorOpen ? 1 : 0.35
      service: root.service
      layoutId: root.editorFor === "new" ? "" : root.editorFor
      onFinished: root.editorFor = ""
    }

    // Plain text, then a link in the accent colour.
    Row {
      spacing: Style.space(6)

      Text {
        textFormat: Text.PlainText
        text: strings.t("layouts.openfile.lead")
        color: Qt.darker(Commons.Color.foreground, 1.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      PageLink {
        text: strings.t("layouts.openfile")
        onClicked: if (root.service) root.service.openLayoutsFile()
      }
    }

  }
}
