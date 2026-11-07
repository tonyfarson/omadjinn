import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// The omadjinn icon in the top bar, and the settings popup that drops
// from it. The engine (files, binds, layouts) is Service.qml; this widget is
// one per monitor and only draws and relays.
BarWidget {
  id: root
  moduleName: "io.github.tonyfarson.omadjinn"

  readonly property var svc: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(root.moduleName) : null
  readonly property bool ready: svc !== null && svc !== undefined

  // Shape contract the shell expects from a bar widget with a popup.
  readonly property bool opened: ready && svc.settingsOpen
  function open() { if (ready) svc.settingsOpen = true }
  function close() { if (ready) svc.settingsOpen = false }
  function togglePanel() { if (ready) svc.settingsOpen = !svc.settingsOpen }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: root.bar ? root.bar.barForeground : Color.foreground
    useActiveColor: false
    tooltipText: "Omadjinn"
    iconComponent: Component {
      GenieIcon { color: root.bar ? root.bar.barForeground : Color.foreground }
    }
    onPressed: function(b) { root.togglePanel() }
  }

  // KeyboardPanel, not PopupCard: an xdg-popup gets no keys until clicked, so Esc
  // would not work. KeyboardPanel takes keyboard focus when it opens.
  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.opened
    focusTarget: settings
    // A fixed size: pages scroll inside it, so the popup never changes size.
    contentWidth: popup.fittedContentWidth(Style.space(420))
    contentHeight: popup.fittedContentHeight(Style.space(440))

    SettingsPanel {
      id: settings
      anchors.fill: parent
      service: root.ready ? root.svc : null
      onCloseRequested: root.close()
    }
  }
}
