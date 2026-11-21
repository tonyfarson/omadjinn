import QtQuick
import QtQuick.Controls
import qs.Ui

// A text field that never touches the clipboard.
//
// Qt 6.12 makes a writable text field read the whole clipboard every time the clipboard
// changes, with no paste (QTBUG-149610). A read-only field does not. So this field is always
// read-only, and typing is done here instead: printable keys, Backspace, Delete and Enter.
// Arrows, Home, End and mouse selection still work. Paste is off on purpose, and so is the
// right-click menu. Input-method (IME) text does not reach a read-only field.
TextField {
  id: root

  readOnly: true
  cursorVisible: activeFocus
  ContextMenu.menu: null

  function replaceSelection(insertText) {
    const from = selectionStart !== selectionEnd ? selectionStart : cursorPosition
    const to = selectionStart !== selectionEnd ? selectionEnd : cursorPosition
    text = text.slice(0, from) + insertText + text.slice(to)
    cursorPosition = from + insertText.length
  }

  Keys.onPressed: event => {
    const sel = selectionStart !== selectionEnd
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.accepted()
      event.accepted = true
    } else if (event.key === Qt.Key_Backspace) {
      if (sel) replaceSelection("")
      else if (cursorPosition > 0) { select(cursorPosition - 1, cursorPosition); replaceSelection("") }
      event.accepted = true
    } else if (event.key === Qt.Key_Delete) {
      if (sel) replaceSelection("")
      else if (cursorPosition < text.length) { select(cursorPosition, cursorPosition + 1); replaceSelection("") }
      event.accepted = true
    } else if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
      // Shortcuts (Ctrl+A, Ctrl+C) go to the field; Ctrl+V does nothing in a read-only field.
    } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
      replaceSelection(event.text)
      event.accepted = true
    }
  }
}
