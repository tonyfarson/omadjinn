import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The main page: the feature switches. The page buttons live in SettingsPanel.
Column {
  id: root

  property var service: null
  readonly property var features: service && service.config && service.config.features ? service.config.features : ({})

  spacing: Style.space(12)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  PanelSectionHeader {
    id: featuresHeader
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

  Toggle {
    width: parent.width
    label: strings.t("feature.swap.label")
    description: strings.t("feature.swap.description")
    checked: root.features.swap === true
    onClicked: if (root.service) root.service.setFeature("swap", !checked)
  }
}
