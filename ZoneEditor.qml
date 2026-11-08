import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The zone editor: a picture of the screen cut by straight lines. Click a zone and split it,
// drag a line to move it (it snaps to twelfths), click a line and merge it away.
// Colours come from the theme.
Column {
  id: root

  property var service: null
  // The layout being edited, or "" for a new one.
  property string layoutId: ""

  // Icons offered for a new layout, and the one used when none is picked (both from the page).
  property var glyphs: []
  property string defaultIcon: ""
  // A new layout is named and given an icon here; an existing one keeps Edit on the page.
  readonly property bool isNew: layoutId === ""
  property string newName: ""
  property string newIcon: ""

  signal finished()

  spacing: Style.space(10)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  property var tree: ({ leaf: true })
  property bool drawable: true
  property var selectedZone: []     // path of the chosen zone
  property var selectedLine: null   // path of the chosen split line, or null
  readonly property var zoneList: Model.leafZones(tree)
  readonly property var lines: Model.splitLines(tree)

  function load() {
    newName = ""
    newIcon = ""
    selectedLine = null
    selectedZone = []
    if (layoutId === "") { tree = ({ leaf: true }); drawable = true; return }
    var layout = service ? service.layoutById(layoutId) : null
    var t = layout ? Model.zonesToTree(layout.zones) : null
    drawable = t !== null
    tree = t || ({ leaf: true })
  }

  onLayoutIdChanged: load()
  Component.onCompleted: load()

  function split(dir) {
    var before = JSON.stringify(tree)
    var next = Model.splitZone(tree, selectedZone, dir)
    if (JSON.stringify(next) === before) return
    tree = next
    selectedLine = null
    selectedZone = selectedZone.concat([0])
  }

  function merge() {
    if (selectedLine === null) return
    tree = Model.mergeSplit(tree, selectedLine)
    selectedZone = selectedLine
    selectedLine = null
  }

  function save() {
    if (service) service.saveZones(layoutId, Model.treeToZones(tree), isNew ? newName : "", isNew ? newIcon : "")
    finished()
  }

  function samePath(a, b) {
    if (!a || !b || a.length !== b.length) return false
    for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false
    return true
  }

  Text {
    visible: !root.drawable
    textFormat: Text.PlainText
    width: parent.width
    wrapMode: Text.WordWrap
    text: strings.t("editor.cannot")
    color: Commons.Color.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
  }

  // The screen.
  Item {
    id: screen
    visible: root.drawable
    width: root.width
    height: Math.round(width * 0.625)

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.width: 1
      border.color: Util.alpha(Commons.Color.foreground, 0.6)
    }

    // Zones: click to choose one.
    Repeater {
      model: root.zoneList.length

      Rectangle {
        required property int index
        readonly property var zone: root.zoneList[index]
        readonly property bool chosen: root.samePath(zone.path, root.selectedZone)
        x: zone.rect[0] * screen.width
        y: zone.rect[1] * screen.height
        width: zone.rect[2] * screen.width
        height: zone.rect[3] * screen.height
        color: chosen ? Util.alpha(Commons.Color.accent, 0.3) : Util.alpha(Commons.Color.foreground, 0.08)
        border.width: 1
        border.color: Util.alpha(Commons.Color.foreground, 0.5)

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: String(parent.index + 1)
          color: Util.alpha(Commons.Color.foreground, 0.7)
          font.family: Style.font.family
          font.pixelSize: Style.font.title
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.selectedZone = parent.zone.path; root.selectedLine = null }
        }
      }
    }

    // Split lines: drag to move, click to choose. The delegate list keeps its size while a
    // line moves, so the drag is not interrupted.
    Repeater {
      model: root.lines.length

      Item {
        id: lineItem
        required property int index
        readonly property var line: root.lines[index]
        readonly property bool vertical: line.dir === "v"
        readonly property bool chosen: root.samePath(line.path, root.selectedLine)
        readonly property real grab: Style.space(12)
        x: vertical ? line.x0 * screen.width - grab / 2 : line.x0 * screen.width
        y: vertical ? line.y0 * screen.height : line.y0 * screen.height - grab / 2
        width: vertical ? grab : (line.x1 - line.x0) * screen.width
        height: vertical ? (line.y1 - line.y0) * screen.height : grab

        Rectangle {
          anchors.centerIn: parent
          width: lineItem.vertical ? (lineItem.chosen ? 4 : 2) : parent.width
          height: lineItem.vertical ? parent.height : (lineItem.chosen ? 4 : 2)
          color: lineItem.chosen ? Commons.Color.accent : Commons.Color.foreground
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: lineItem.vertical ? Qt.SizeHorCursor : Qt.SizeVerCursor
          preventStealing: true
          onPressed: { root.selectedLine = lineItem.line.path }
          onPositionChanged: function(mouse) {
            if (!pressed) return
            var p = mapToItem(screen, mouse.x, mouse.y)
            root.tree = Model.moveSplit(root.tree, lineItem.line.path, lineItem.vertical ? p.x / screen.width : p.y / screen.height)
          }
        }
      }
    }
  }

  Row {
    visible: root.drawable
    spacing: Style.space(8)

    Button { text: strings.t("editor.splitv"); bordered: true; onClicked: root.split("v") }
    Button { text: strings.t("editor.splith"); bordered: true; onClicked: root.split("h") }
    Button { text: strings.t("editor.merge"); bordered: true; onClicked: root.merge() }
  }

  Text {
    visible: root.drawable
    textFormat: Text.PlainText
    width: parent.width
    wrapMode: Text.WordWrap
    text: strings.t("editor.hint")
    color: Qt.darker(Commons.Color.foreground, 1.5)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  // Name and icon, for a new layout only.
  Column {
    visible: root.drawable && root.isNew
    width: parent.width
    spacing: Style.space(6)

    Text {
      textFormat: Text.PlainText
      text: strings.t("editor.name")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    TextField {
      width: parent.width
      text: root.newName
      placeholderText: strings.t("editor.name.placeholder")
      onTextChanged: root.newName = text
      onAccepted: root.save()
    }

    Text {
      textFormat: Text.PlainText
      text: strings.t("editor.glyph")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Flow {
      width: parent.width
      spacing: Style.space(6)

      Repeater {
        model: root.glyphs

        Item {
          required property string modelData
          readonly property bool current: (root.newIcon || root.defaultIcon) === modelData
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
            onClicked: root.newIcon = parent.modelData
          }
        }
      }
    }
  }

  Row {
    spacing: Style.space(8)

    Button { visible: root.drawable; text: strings.t("save"); bordered: true; onClicked: root.save() }
    Button { text: strings.t("keys.cancel"); bordered: true; onClicked: root.finished() }
  }
}
