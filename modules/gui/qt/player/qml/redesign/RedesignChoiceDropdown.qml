// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

// A RedesignDropdown over one of the player's checkable choice models
// (zoom, aspect ratio, stereo mode, ...): shows the checked entry and checks the chosen one.
RedesignDropdown {
    id: root
    property var choices
    textRole: "display"
    model: choices
    currentIndex: {
        for (let i = 0; i < checkedRows.count; ++i)
            if (checkedRows.objectAt(i) && checkedRows.objectAt(i).checked) return i
        return -1
    }
    displayText: currentIndex < 0 ? qsTr("Default") : currentText
    onActivated: index => choices.setData(choices.index(index, 0), true, Qt.CheckStateRole)
    Instantiator {
        id: checkedRows
        model: root.choices
        delegate: QtObject {
            required property bool checked
        }
    }
}
