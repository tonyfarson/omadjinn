import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The omadjinn settings, drawn inside the bar popup (BarWidget.qml).
// It only shows state and reports changes; Service.qml owns the files.
Item {
  id: root

  // The "features" object from config.json.
  property var features: ({})
  // The layouts in use: [{id, name, icon, zones}].
  property var layouts: []

  // True while the quick start is showing instead of the settings.
  property bool helpOpen: false

  signal closeRequested()
  signal featureToggled(string key, bool value)
  signal layoutRenamed(string id, string name)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  implicitHeight: helpOpen ? help.implicitHeight : body.implicitHeight

  // The genie in the header corner, in the text color. The SVG is black; it is tinted
  // with the theme's text color so it suits dark and light themes.
  Image {
    id: watermark
    anchors.right: parent.right
    anchors.top: parent.top
    height: Style.space(72)
    width: height
    source: Qt.resolvedUrl("assets/genie-watermark.svg")
    sourceSize: Qt.size(width * 2, height * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: false
  }
  MultiEffect {
    anchors.fill: watermark
    source: watermark
    // The SVG is black, and colorization keeps brightness, so lift it to white first.
    brightness: 1.0
    colorization: 1.0
    colorizationColor: Commons.Color.foreground
  }
  focus: true
  Keys.onEscapePressed: { if (root.helpOpen) root.helpOpen = false; else root.closeRequested() }

  Column {
    id: body
    visible: !root.helpOpen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(12)

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: strings.t("settings.title")
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: strings.t("settings.subtitle")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Rectangle {
      // Stops short of the genie in the corner.
      width: parent.width - watermark.width - Style.space(12)
      height: 1
      color: Util.alpha(Commons.Color.foreground, 0.2)
    }

    PanelSectionHeader {
      text: strings.t("settings.features")
    }

    Toggle {
      width: parent.width
      label: strings.t("feature.dragRestore.label")
      description: strings.t("feature.dragRestore.description")
      checked: root.features.dragRestore === true
      onClicked: root.featureToggled("dragRestore", !checked)
    }

    Toggle {
      width: parent.width
      label: strings.t("feature.snapTiled.label")
      description: strings.t("feature.snapTiled.description")
      checked: root.features.snapTiled === true
      onClicked: root.featureToggled("snapTiled", !checked)
    }

    Toggle {
      width: parent.width
      label: strings.t("feature.rightClickMenu.label")
      description: strings.t("feature.rightClickMenu.description")
      checked: root.features.rightClickMenu === true
      onClicked: root.featureToggled("rightClickMenu", !checked)
    }

    PanelSectionHeader {
      text: strings.t("settings.layouts")
    }

    Repeater {
      model: root.layouts

      Row {
        required property var modelData
        width: body.width
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
            // Hand keyboard focus back to the window so Esc closes it again.
            root.forceActiveFocus()
            var name = text.trim()
            if (name === "") { text = modelData.name || modelData.id; return }
            if (name !== modelData.name) root.layoutRenamed(modelData.id, name)
          }
        }
      }
    }

    Item {
      width: parent.width
      height: hint.implicitHeight

      Text {
        id: questions
        anchors.left: parent.left
        textFormat: Text.PlainText
        text: strings.t("help.link")
        color: Commons.Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.underline: questionsArea.containsMouse

        MouseArea {
          id: questionsArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.helpOpen = true
        }
      }

      // Suggestions and bug reports open the repo's new-issue page.
      Text {
        id: suggestions
        anchors.left: questions.right
        anchors.leftMargin: Style.space(16)
        anchors.verticalCenter: questions.verticalCenter
        textFormat: Text.PlainText
        text: strings.t("help.suggestions")
        color: Commons.Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.underline: suggestionsArea.containsMouse

        MouseArea {
          id: suggestionsArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/tonyfarson/omadjinn/issues/new?labels=enhancement")
        }
      }

      Text {
        id: bug
        anchors.left: suggestions.right
        anchors.leftMargin: Style.space(16)
        anchors.verticalCenter: questions.verticalCenter
        textFormat: Text.PlainText
        text: "\ueaaf"
        color: Commons.Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.body

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/tonyfarson/omadjinn/issues/new?labels=bug")
        }
      }

      Text {
        id: hint
        anchors.right: parent.right
        textFormat: Text.PlainText
        text: strings.t("settings.hint")
        color: Qt.darker(Commons.Color.foreground, 1.8)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  // The quick start: short instructions and links, shown in place of the settings.
  Column {
    id: help
    visible: root.helpOpen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.space(12)

    Text {
      textFormat: Text.PlainText
      text: strings.t("help.back")
      color: Commons.Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.underline: backArea.containsMouse

      MouseArea {
        id: backArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.helpOpen = false
      }
    }

    Text {
      textFormat: Text.PlainText
      // Stops short of the genie in the corner.
      width: parent.width - watermark.width - Style.space(12)
      text: strings.t("help.title")
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
    }

    Repeater {
      model: ["help.what", "help.keys", "help.settings", "help.more"]

      Text {
        required property string modelData
        width: help.width
        textFormat: Text.StyledText
        wrapMode: Text.WordWrap
        text: strings.t(modelData)
        color: Commons.Color.foreground
        linkColor: Commons.Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        onLinkActivated: function(link) { Qt.openUrlExternally(link) }

        // Wrap around the genie: lines that start beside it are shorter.
        onLineLaidOut: function(line) {
          if (y + line.y < watermark.height + Style.space(8))
            line.width = width - watermark.width - Style.space(12)
        }
      }
    }

    // A quiet thank-you link at the bottom.
    Text {
      topPadding: Style.space(8)
      textFormat: Text.PlainText
      text: "\u2615 " + strings.t("help.coffee")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.underline: coffeeArea.containsMouse

      MouseArea {
        id: coffeeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Qt.openUrlExternally("https://www.buymeacoffee.com/tonyfarson")
      }
    }
  }
}
