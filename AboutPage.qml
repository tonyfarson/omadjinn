import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// About: the quick start, links, the version, and a restart button for after an update.
Column {
  id: root

  property var service: null
  readonly property string version: service && service.manifest && service.manifest.version ? String(service.manifest.version) : ""

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Repeater {
    model: ["help.what", "help.keys", "help.settings", "help.more"]

    Text {
      required property string modelData
      width: root.width
      textFormat: Text.StyledText
      wrapMode: Text.WordWrap
      text: strings.t(modelData)
      color: Commons.Color.foreground
      linkColor: Commons.Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      onLinkActivated: function(link) { Qt.openUrlExternally(link) }
    }
  }

  // Suggestions and bug reports open the repo's new-issue page.
  Row {
    spacing: Style.space(16)

    PageLink {
      text: strings.t("help.suggestions")
      onClicked: Qt.openUrlExternally("https://github.com/tonyfarson/omadjinn/issues/new?labels=enhancement")
    }

    Text {
      textFormat: Text.PlainText
      text: ""
      color: Commons.Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.body

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Qt.openUrlExternally("https://github.com/tonyfarson/omadjinn/issues/new?labels=bug")
      }
    }
  }

  PanelSectionHeader {
    topPadding: Style.space(12)
    text: strings.t("about.version")
  }

  Row {
    spacing: Style.space(16)

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: "Omadjinn " + root.version
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Button {
      text: strings.t("about.restart")
      bordered: true
      tooltipText: strings.t("about.restart.tip")
      onClicked: Quickshell.execDetached(["omarchy-restart-shell"])
    }
  }

  // A quiet thank-you link at the bottom.
  PageLink {
    topPadding: Style.space(8)
    text: "☕ " + strings.t("help.coffee")
    linkColor: Qt.darker(Commons.Color.foreground, 1.5)
    onClicked: Qt.openUrlExternally("https://www.buymeacoffee.com/tonyfarson")
  }
}
