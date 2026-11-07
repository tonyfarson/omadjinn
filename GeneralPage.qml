import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The main page: a contents list, then the feature switches.
Column {
  id: root

  property var service: null
  readonly property var features: service && service.config && service.config.features ? service.config.features : ({})

  // Where the Features section starts, for the contents link.
  readonly property real featuresY: featuresHeader.y

  signal navigate(string page)
  signal scrollRequested(real y)

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  PanelSectionHeader {
    text: strings.t("toc.title")
  }

  Row {
    spacing: Style.space(10)

    PageLink { text: strings.t("page.features"); onClicked: root.scrollRequested(root.featuresY) }
    Text { text: "·"; color: Util.alpha(Commons.Color.foreground, 0.4); font.pixelSize: Style.font.caption }
    PageLink { text: strings.t("page.keys"); onClicked: root.navigate("keys") }
    Text { text: "·"; color: Util.alpha(Commons.Color.foreground, 0.4); font.pixelSize: Style.font.caption }
    PageLink { text: strings.t("page.layouts"); onClicked: root.navigate("layouts") }
    Text { text: "·"; color: Util.alpha(Commons.Color.foreground, 0.4); font.pixelSize: Style.font.caption }
    PageLink { text: strings.t("page.about"); onClicked: root.navigate("about") }
  }

  PanelSectionHeader {
    id: featuresHeader
    topPadding: Style.space(12)
    text: strings.t("settings.features")
  }

  Toggle {
    width: parent.width
    label: strings.t("feature.dragRestore.label")
    description: strings.t("feature.dragRestore.description")
    checked: root.features.dragRestore === true
    onClicked: if (root.service) root.service.setFeature("dragRestore", !checked)
  }

  Toggle {
    width: parent.width
    label: strings.t("feature.snapTiled.label")
    description: strings.t("feature.snapTiled.description")
    checked: root.features.snapTiled === true
    onClicked: if (root.service) root.service.setFeature("snapTiled", !checked)
  }

  Toggle {
    width: parent.width
    label: strings.t("feature.rightClickMenu.label")
    description: strings.t("feature.rightClickMenu.description")
    checked: root.features.rightClickMenu === true
    onClicked: if (root.service) root.service.setFeature("rightClickMenu", !checked)
  }
}
