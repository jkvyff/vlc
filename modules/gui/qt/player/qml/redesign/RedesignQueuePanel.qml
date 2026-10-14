// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.MainInterface
import VLC.Player
import VLC.Playlist

Item {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property int tab: 0
    property Component queueContent
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RedesignPanelTabs {
            Layout.fillWidth: true
            topRadius: theme.dp(8)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            model: [{key: "queue", label: qsTr("Queue"), icon: "queue"}, {key: "bookmarks", label: qsTr("Bookmarks"), icon: "bookmarks"}, {key: "chapters", label: qsTr("Chapters"), icon: "chapters"}]
            current: ["queue", "bookmarks", "chapters"][root.tab]
            onActivated: key => root.tab = ["queue", "bookmarks", "chapters"].indexOf(key)
        }
        Loader { Layout.fillWidth: true; Layout.fillHeight: true; visible: root.tab === 0; active: visible; sourceComponent: root.queueContent }
        Loader {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: root.tab === 1 && MainCtx.mediaLibraryAvailable; active: visible
            source: active ? "qrc:///qt/qml/VLC/Player/RedesignBookmarks.qml" : ""
            onLoaded: { item.scaleFactor = Qt.binding(() => root.scaleFactor); item.lightTheme = Qt.binding(() => root.lightTheme) }
        }
        Text {
            Layout.fillWidth: true; Layout.margins: theme.dp(28)
            visible: root.tab === 1 && !MainCtx.mediaLibraryAvailable
            text: qsTr("Bookmarks need the media library, which this VLC build does not include.")
            wrapMode: Text.WordWrap; color: theme.mutedText; font.pixelSize: theme.dp(14)
        }
        ListView {
            id: chapters
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: theme.dp(28); Layout.rightMargin: theme.dp(20); Layout.topMargin: theme.dp(14)
            visible: root.tab === 2
            clip: true
            model: Player.chapters
            C.ScrollBar.vertical: C.ScrollBar {}
            delegate: RedesignButton {
                id: chapter
                required property int index
                // Read through the model: "checked" and "display" are Button properties.
                required property var model
                readonly property bool current: model.checked
                width: chapters.width; height: theme.dp(36)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                text: chapter.model.display
                background: Rectangle {
                    anchors.fill: parent; anchors.leftMargin: -theme.dp(8)
                    radius: theme.dp(4); color: chapter.hovered ? theme.sidebarHover : "transparent"
                    border.width: chapter.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
                }
                contentItem: Item {
                    Text { anchors.verticalCenter: parent.verticalCenter; text: chapter.index + 1; color: theme.accent; font.pixelSize: theme.dp(15) }
                    Text {
                        x: theme.dp(34); width: chapterTime.x - x - theme.dp(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: chapter.model.display; elide: Text.ElideRight
                        color: chapter.current || chapter.hovered ? theme.bright : theme.rowText; font.pixelSize: theme.dp(15)
                    }
                    Text {
                        id: chapterTime
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: chapter.model.time.formatHMS(); color: theme.mutedText; font.pixelSize: theme.dp(15)
                    }
                }
                onClicked: Player.chapters.setData(Player.chapters.index(chapter.index, 0), true, Qt.CheckStateRole)
            }
            Text { width: parent.width; visible: chapters.count === 0; text: qsTr("This media has no chapters."); wrapMode: Text.WordWrap; color: theme.mutedText; font.pixelSize: theme.dp(14) }
        }
    }
}
