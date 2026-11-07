import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The keys Omadjinn registers: description, bind, and an Edit button that records new keys.
Column {
  id: root

  property var service: null
  readonly property var chosen: service && service.config && service.config.keys ? service.config.keys : ({})

  spacing: Style.space(12)

  // Which action is waiting for new keys ("" when none), and the last message.
  property string recordingId: ""
  property string message: ""
  readonly property bool recording: recordingId !== ""

  function currentKey(id) {
    for (var i = 0; i < Model.KEY_ACTIONS.length; i++) {
      var a = Model.KEY_ACTIONS[i]
      if (a.id === id) return (id in root.chosen) ? root.chosen[id] : a.key
    }
    return ""
  }

  function startRecording(id) {
    root.message = ""
    root.recordingId = id
    if (root.service) root.service.keysSuspended = true
    recorder.forceActiveFocus()
  }

  function stopRecording() {
    root.recordingId = ""
    if (root.service) root.service.keysSuspended = false
    root.focusRequested()
  }

  // The Hyprland name for a Qt key, or "" when the key can't be a bind.
  function keyName(event) {
    var k = event.key
    if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
    if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
    if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1)
    var names = {}
    names[Qt.Key_Left] = "LEFT"; names[Qt.Key_Right] = "RIGHT"; names[Qt.Key_Up] = "UP"; names[Qt.Key_Down] = "DOWN"
    names[Qt.Key_Comma] = "comma"; names[Qt.Key_Period] = "period"; names[Qt.Key_Slash] = "slash"
    names[Qt.Key_Semicolon] = "semicolon"; names[Qt.Key_Apostrophe] = "apostrophe"; names[Qt.Key_Minus] = "minus"
    names[Qt.Key_Equal] = "equal"; names[Qt.Key_BracketLeft] = "bracketleft"; names[Qt.Key_BracketRight] = "bracketright"
    names[Qt.Key_Backslash] = "backslash"; names[Qt.Key_QuoteLeft] = "grave"
    names[Qt.Key_Space] = "SPACE"; names[Qt.Key_Return] = "RETURN"; names[Qt.Key_Enter] = "RETURN"
    names[Qt.Key_Tab] = "TAB"; names[Qt.Key_Backspace] = "BACKSPACE"; names[Qt.Key_Delete] = "DELETE"
    names[Qt.Key_Home] = "HOME"; names[Qt.Key_End] = "END"; names[Qt.Key_PageUp] = "PRIOR"; names[Qt.Key_PageDown] = "NEXT"
    names[Qt.Key_Insert] = "INSERT"
    return names[k] || ""
  }

  signal focusRequested()

  // Stop recording when the page goes away or the panel closes, so our binds come back.
  onVisibleChanged: if (!visible && recording) stopRecording()
  Component.onDestruction: if (recording && service) service.keysSuspended = false

  // Takes the keys while recording. Nothing else on the page needs the keyboard.
  Item {
    id: recorder
    width: 0; height: 0
    focus: root.recording
    Keys.onPressed: function(event) {
      event.accepted = true
      if (!root.recording) return
      if (event.key === Qt.Key_Escape) { root.stopRecording(); return }
      if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control || event.key === Qt.Key_Alt
          || event.key === Qt.Key_Meta || event.key === Qt.Key_AltGr || event.key === Qt.Key_Super_L
          || event.key === Qt.Key_Super_R) return
      var name = root.keyName(event)
      var mods = []
      if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
      if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
      if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
      if (event.modifiers & Qt.AltModifier) mods.push("ALT")
      var id = root.recordingId
      if (name === "") { root.message = strings.t("keys.unknown"); root.stopRecording(); return }
      if (mods.length === 0) { root.message = strings.t("keys.needmod"); root.stopRecording(); return }
      var parsed = Model.parseKey(mods.concat([name]).join(" + "))
      if (!parsed) { root.message = strings.t("keys.unknown"); root.stopRecording(); return }
      // Another Omadjinn action already using these keys?
      for (var i = 0; i < Model.KEY_ACTIONS.length; i++) {
        var a = Model.KEY_ACTIONS[i]
        var other = Model.parseKey(root.currentKey(a.id))
        if (a.id !== id && other && other.text === parsed.text) {
          root.message = parsed.text + " " + strings.t("keys.taken") + ": " + a.label
          root.stopRecording(); return
        }
      }
      if (!root.service) { root.stopRecording(); return }
      // Something else in Hyprland already using them?
      root.service.run(["hyprctl", "-j", "binds"], function(text) {
        var holder = Model.keyConflict(root.service.json(text), parsed.text)
        if (holder) root.message = parsed.text + " " + strings.t("keys.taken") + ": " + holder
        else { root.service.setKey(id, parsed.text); root.message = strings.t("keys.saved") + ": " + parsed.text }
        root.stopRecording()
      })
    }
  }

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // Column headings. The edit column has none.
  Row {
    width: root.width
    spacing: Style.space(12)
    Text {
      width: root.width * 0.5
      textFormat: Text.PlainText
      text: strings.t("keys.description")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
    Text {
      textFormat: Text.PlainText
      text: strings.t("keys.bind")
      color: Qt.darker(Commons.Color.foreground, 1.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  Repeater {
    model: Model.KEY_ACTIONS

    Row {
      required property var modelData
      width: root.width
      spacing: Style.space(12)

      Text {
        width: root.width * 0.5
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        elide: Text.ElideRight
        text: modelData.label
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      Text {
        width: root.width * 0.5 - editButton.width - Style.space(24)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        elide: Text.ElideRight
        text: root.recordingId === modelData.id ? strings.t("keys.recording") : root.currentKey(modelData.id)
        color: root.recordingId === modelData.id ? Commons.Color.accent : Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }

      Button {
        id: editButton
        anchors.verticalCenter: parent.verticalCenter
        text: root.recordingId === modelData.id ? strings.t("keys.cancel") : strings.t("edit")
        bordered: true
        onClicked: root.recordingId === modelData.id ? root.stopRecording() : root.startRecording(modelData.id)
      }
    }
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    wrapMode: Text.WordWrap
    text: root.message !== "" ? root.message : strings.t("keys.soon")
    color: Qt.darker(Commons.Color.foreground, 1.5)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
