// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import "RedesignIcons.js" as Icons

// The tab strip heading the player's side panels: icon and label per tab,
// with an accent underline under the current one.
Rectangle {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property var model: []          // [{key, label, icon}]
    property string current
    // Rounds the top corners when the strip heads a rounded panel.
    property real topRadius: 0
    signal activated(string key)
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    implicitHeight: theme.dp(50)
    color: "transparent"
    Accessible.role: Accessible.PageTabList
    Rectangle { anchors.fill: parent; radius: root.topRadius; color: root.theme.topBar }
    Rectangle {
        // Squares off the bottom corners again.
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: parent.height - root.topRadius; color: root.theme.topBar
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.dp(14); anchors.rightMargin: theme.dp(14)
        spacing: theme.dp(4)
        Repeater {
            model: root.model
            T.AbstractButton {
                id: tab
                required property var modelData
                readonly property bool current: root.current === modelData.key
                objectName: "panelTab_" + modelData.key
                Layout.fillWidth: true; Layout.fillHeight: true
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                text: modelData.label
                Accessible.role: Accessible.PageTab
                Accessible.name: text
                Accessible.selected: current
                background: Item {
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: root.theme.dp(2)
                        color: root.theme.accent
                        visible: tab.current
                    }
                    Rectangle {
                        anchors.fill: parent; anchors.margins: root.theme.dp(4)
                        radius: root.theme.dp(4)
                        color: tab.hovered && !tab.current ? root.theme.sidebarHover : "transparent"
                        border.width: tab.visualFocus ? root.theme.dp(1) : 0; border.color: root.theme.accent
                    }
                }
                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: root.theme.dp(8)
                        RedesignIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.theme.dp(20); height: width
                            // Tabs without an active variant are tinted instead.
                            name: tab.current ? Icons.activeName(tab.modelData.icon) : tab.modelData.icon
                            color: tab.current ? root.theme.accent : tab.hovered ? root.theme.foreground : root.theme.controlKnob
                            accentColor: root.theme.accent
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.width / Math.max(1, root.model.length) > root.theme.dp(80)
                            text: tab.text
                            font.pixelSize: root.theme.dp(13)
                            color: tab.current || tab.hovered ? root.theme.foreground : root.theme.mutedText
                        }
                    }
                }
                onClicked: root.activated(modelData.key)
            }
        }
    }
}
