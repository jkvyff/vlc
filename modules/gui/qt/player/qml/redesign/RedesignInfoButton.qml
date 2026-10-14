// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Basic as C

// The design's (i) after a setting's name; shows the setting's help text.
T.AbstractButton {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property string help
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    visible: help.length > 0
    implicitWidth: theme.dp(18)
    implicitHeight: theme.dp(18)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    checkable: true
    Accessible.role: Accessible.Button
    Accessible.name: qsTr("About this setting")
    Accessible.description: help
    onActiveFocusChanged: if (!activeFocus) checked = false

    contentItem: RedesignIcon {
        name: "info"
        color: root.hovered || root.visualFocus || root.checked ? root.theme.foreground : root.theme.controlKnob
    }
    background: Rectangle {
        radius: width / 2
        color: "transparent"
        border.width: root.visualFocus ? root.theme.dp(1) : 0
        border.color: root.theme.accent
    }
    C.ToolTip.text: help
    C.ToolTip.visible: hovered || checked
    C.ToolTip.delay: checked ? 0 : 300
}
