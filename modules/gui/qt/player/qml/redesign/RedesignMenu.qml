// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C

C.Popup {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    signal actionRequested(string action)
    width: theme.dp(290)
    padding: theme.dp(6)
    focus: true
    background: Rectangle { color: theme.background; radius: theme.dp(6); border.color: theme.border }
    contentItem: Column {
        Repeater {
            model: [
                {action: "file", icon: "file-duo", label: qsTr("Open file"), shortcut: "Ctrl+O"},
                {action: "subtitles", icon: "subtitles-duo", label: qsTr("Open subtitle file"), shortcut: ""},
                {action: "directory", icon: "folder-duo", label: qsTr("Open directory"), shortcut: "Ctrl+F"},
                {action: "disc", icon: "disc-duo", label: qsTr("Open disc"), shortcut: "Ctrl+D"},
                {action: "network", icon: "streaming-duo", label: qsTr("Open network stream"), shortcut: "Ctrl+N"},
                {action: "capture", icon: "capture-device-duo", label: qsTr("Open capture device"), shortcut: "Ctrl+C"},
                {action: "convert", icon: "swap-duo", label: qsTr("Convert"), shortcut: "Ctrl+R"},
                {action: "stream", icon: "link-duo", label: qsTr("Stream to another device"), shortcut: "Ctrl+S"},
                {action: "library", icon: "playlist-duo", label: qsTr("Full media library"), shortcut: ""},
                {action: "customize", icon: "paint-duo", label: qsTr("Customize player"), shortcut: ""},
                {action: "settings", icon: "settings-duo", label: qsTr("Settings"), shortcut: "Ctrl+P"},
                {action: "advanced", icon: "more", label: qsTr("All VLC actions"), shortcut: ""},
                {action: "about", icon: "info-duo", label: qsTr("About VLC"), shortcut: ""}
            ]
            RedesignButton {
                required property var modelData
                width: root.availableWidth
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                text: modelData.label
                contentItem: RowLayout {
                    spacing: root.theme.dp(10)
                    RedesignIcon { width: root.theme.dp(20); height: width; name: modelData.icon; color: root.theme.foreground; accentColor: root.theme.accent }
                    Text { Layout.fillWidth: true; text: modelData.label; color: root.theme.bright; font.pixelSize: root.theme.dp(13) }
                    Text { text: modelData.shortcut; color: root.theme.foreground; font.pixelSize: root.theme.dp(11) }
                }
                onClicked: { root.close(); root.actionRequested(modelData.action) }
            }
        }
    }
}
