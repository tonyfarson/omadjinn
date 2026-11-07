import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The omadjinn settings, drawn inside the bar popup (BarWidget.qml).
//
// A fixed-size frame: a pinned header (the title and subtitle) over one
// scrolling area that shows the current page. The popup never resizes with the page.
// Pages are separate files (GeneralPage, KeysPage, LayoutsPage, AboutPage) and talk to
// the engine, Service.qml, directly through `service`.
Item {
  id: root

  property var service: null

  // "general" is the main page; the others open from the button row.
  property string page: "general"

  signal closeRequested()

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  focus: true
  Keys.onEscapePressed: { if (root.page !== "general") root.page = "general"; else root.closeRequested() }

  onPageChanged: flick.contentY = 0

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

  // ── Pinned header ──────────────────────────────────────────────────────────
  Column {
    id: header
    anchors.left: parent.left
    anchors.top: parent.top
    width: parent.width - watermark.width - Style.space(12)
    spacing: Style.space(6)

    // The product name and what it does, on every page.
    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: strings.t("settings.title")
      color: Commons.Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
      wrapMode: Text.WordWrap
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: strings.t("settings.subtitle")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  Rectangle {
    id: rule
    anchors.top: header.bottom
    anchors.topMargin: Math.max(Style.space(8), watermark.height - header.height)
    anchors.left: parent.left
    // Stops short of the genie in the corner.
    width: parent.width - watermark.width - Style.space(12)
    height: 1
    color: Util.alpha(Commons.Color.foreground, 0.2)
  }

  // ── Pinned page buttons, on every page ─────────────────────────────────────
  Row {
    id: tabs
    anchors.top: rule.bottom
    anchors.topMargin: Style.space(10)
    anchors.left: parent.left
    spacing: Style.space(6)

    Repeater {
      model: ["general", "keys", "layouts", "about"]
      // The current page gets a pill in the theme's accent colour behind its button;
      // the button's own selected look is a grey that ignores the accent.
      Item {
        required property string modelData
        readonly property bool current: root.page === modelData
        width: tabButton.width
        height: tabButton.height

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: Commons.Color.accent
          visible: parent.current
        }

        Button {
          id: tabButton
          text: strings.t("page." + parent.modelData)
          bordered: true
          foreground: parent.current ? Commons.Color.background : Commons.Color.foreground
          onClicked: root.page = parent.modelData
        }
      }
    }
  }

  // ── Scrolling page area ───────────────────────────────────────────────────
  Flickable {
    id: flick
    anchors.top: tabs.bottom
    anchors.topMargin: Style.space(10)
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    anchors.bottomMargin: Style.space(8)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    contentWidth: width
    contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
    interactive: contentHeight > height
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    Loader {
      id: pageLoader
      // Room on the right for the scroll bar.
      width: flick.width - Style.space(14)
      sourceComponent: root.page === "keys" ? keysPage
        : root.page === "layouts" ? layoutsPage
        : root.page === "about" ? aboutPage
        : generalPage
      onLoaded: if (item) { item.width = Qt.binding(function() { return pageLoader.width }) }
    }
  }

  Component {
    id: generalPage
    GeneralPage { service: root.service }
  }
  Component { id: keysPage; KeysPage { service: root.service } }
  Component { id: layoutsPage; LayoutsPage { service: root.service; onFocusRequested: root.forceActiveFocus() } }
  Component { id: aboutPage; AboutPage { service: root.service } }

  // ── Pinned footer ──────────────────────────────────────────────────────────
  Text {
    id: footer
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    textFormat: Text.PlainText
    text: strings.t("settings.hint")
    color: Qt.darker(Commons.Color.foreground, 1.8)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
