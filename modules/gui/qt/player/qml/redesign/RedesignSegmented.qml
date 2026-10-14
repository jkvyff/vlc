// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

// The design's Values component: equal segments in an inset field, the current one tinted with the accent.
Rectangle {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property var model: []            // [{label, value}]
    property var currentValue
    property string accessibleName
    signal activated(var value)
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    implicitWidth: theme.dp(320)
    implicitHeight: theme.dp(36)
    radius: theme.dp(6)
    color: theme.field
    Accessible.role: Accessible.PageTabList
    Accessible.name: accessibleName

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme.dp(2)
        spacing: theme.dp(2)
        Repeater {
            model: root.model
            T.AbstractButton {
                id: segment
                required property var modelData
                readonly property bool current: root.currentValue === modelData.value
                Layout.fillWidth: true; Layout.fillHeight: true
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                text: modelData.label
                Accessible.role: Accessible.PageTab
                Accessible.name: text
                Accessible.selected: current
                background: Rectangle {
                    radius: theme.dp(4)
                    color: segment.current ? theme.progress : segment.hovered ? theme.controlHover : theme.control
                    border.width: segment.visualFocus ? theme.dp(1) : 0
                    border.color: theme.accent
                }
                contentItem: Text {
                    text: segment.text
                    color: segment.current ? theme.accent : segment.hovered ? theme.foreground : theme.mutedText
                    font.pixelSize: theme.dp(14)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                onClicked: root.activated(modelData.value)
            }
        }
    }
}
