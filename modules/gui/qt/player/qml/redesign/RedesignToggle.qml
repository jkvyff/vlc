// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Templates as T

// The design's ON/OFF toggle: a sliding knob beside a labelled half.
// It does not flip itself; bind `checked` to the setting and write it from onClicked.
T.AbstractButton {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitWidth: theme.dp(68)
    implicitHeight: theme.dp(32)
    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.checkable: true
    Accessible.checked: checked

    background: Rectangle {
        radius: theme.dp(6)
        color: theme.field
        border.width: root.visualFocus ? theme.dp(1) : 0
        border.color: theme.accent
        opacity: root.enabled ? 1 : 0.35
    }
    contentItem: Item {
        opacity: root.enabled ? 1 : 0.35
        Rectangle {
            id: label
            x: root.checked ? theme.dp(3) : root.width - width - theme.dp(3)
            y: theme.dp(3)
            width: theme.dp(33); height: root.height - theme.dp(6)
            radius: theme.dp(3)
            color: root.checked ? theme.progress : root.hovered ? theme.controlHover : theme.control
            Text {
                anchors.centerIn: parent
                text: root.checked ? qsTr("ON") : qsTr("OFF")
                color: root.checked ? theme.accent : theme.mutedText
                font.pixelSize: theme.dp(12)
            }
        }
        Rectangle {
            x: root.checked ? root.width - width - theme.dp(3) : theme.dp(3)
            y: theme.dp(3)
            width: theme.dp(26); height: root.height - theme.dp(6)
            radius: theme.dp(3)
            color: root.checked ? theme.accentKnob : theme.controlKnob
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
}
