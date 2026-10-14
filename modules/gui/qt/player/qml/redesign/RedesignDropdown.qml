// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

// The design's Dropdown: an inset field with a chevron, and a raised list marking the current choice.
T.ComboBox {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    implicitWidth: theme.dp(320)
    implicitHeight: theme.dp(36)
    leftPadding: theme.dp(16)
    rightPadding: theme.dp(16) + theme.dp(24)
    hoverEnabled: true
    font.pixelSize: theme.dp(14)

    background: Rectangle {
        radius: theme.dp(6)
        color: theme.field
        border.width: root.visualFocus ? theme.dp(1) : 0
        border.color: theme.accent
        opacity: root.enabled ? 1 : 0.35
        Rectangle {
            anchors.fill: parent
            anchors.margins: theme.dp(2)
            radius: theme.dp(4)
            color: root.hovered || root.popup.visible ? theme.controlHover : theme.control
        }
    }
    contentItem: Text {
        text: root.displayText
        font: root.font
        color: theme.foreground
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: root.enabled ? 1 : 0.35
    }
    indicator: RedesignIcon {
        x: root.width - width - theme.dp(14)
        y: (root.height - height) / 2
        width: theme.dp(24); height: width
        name: "chevron"
        color: theme.foreground
        rotation: root.popup.visible ? 180 : 0
        opacity: root.enabled ? 1 : 0.35
    }
    delegate: T.ItemDelegate {
        id: option
        required property int index
        required property var model
        required property var modelData
        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: theme.dp(40)
        leftPadding: theme.dp(14); rightPadding: theme.dp(14)
        highlighted: root.highlightedIndex === index
        hoverEnabled: true
        text: root.textRole ? (Array.isArray(root.model) ? modelData[root.textRole] : model[root.textRole]) : modelData
        font: root.font
        Accessible.role: Accessible.ListItem
        Accessible.name: text
        Accessible.selected: root.currentIndex === index
        background: Rectangle {
            radius: theme.dp(4)
            color: option.highlighted || option.hovered ? theme.controlHover : "transparent"
        }
        contentItem: RowLayout {
            spacing: theme.dp(10)
            Text {
                Layout.fillWidth: true
                text: option.text
                font: option.font
                color: option.highlighted || root.currentIndex === option.index ? theme.bright : theme.foreground
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            RedesignIcon {
                Layout.preferredWidth: theme.dp(24); Layout.preferredHeight: theme.dp(24)
                name: "check"
                color: theme.accent; accentColor: theme.accent
                visible: root.currentIndex === option.index
            }
        }
    }
    popup: T.Popup {
        y: root.height + theme.dp(4)
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, theme.dp(320))
        padding: theme.dp(2)
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            spacing: theme.dp(2)
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
        }
        background: Item {
            // Approximates the design's 0 4 14 #00000059 drop shadow without a graphics effect.
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.fill: parent
                    anchors.margins: -theme.dp(index + 1)
                    anchors.topMargin: -theme.dp(index + 1) + theme.dp(4)
                    radius: theme.dp(6 + index + 1)
                    color: "#000000"
                    opacity: 0.09
                }
            }
            Rectangle { anchors.fill: parent; radius: theme.dp(6); color: theme.control }
        }
    }
}
