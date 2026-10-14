// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.MediaLibrary

// The design's bookmarks tab: a count with remove/add, then named times.
Item {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property int selectedIndex: -1
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    MLBookmarkModel { id: bookmarks; ml: MediaLib; player: Player }
    function removeSelected() {
        if (selectedIndex < 0) return
        bookmarks.remove([bookmarks.index(selectedIndex, 0)])
        selectedIndex = -1
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.dp(24); anchors.rightMargin: theme.dp(20); anchors.topMargin: theme.dp(16)
        spacing: theme.dp(6)
        RowLayout {
            Layout.fillWidth: true
            spacing: theme.dp(4)
            Text { Layout.fillWidth: true; text: qsTr("%n Bookmark(s)", "", list.count); color: theme.mutedText; font.pixelSize: theme.dp(15) }
            RedesignButton {
                implicitWidth: theme.dp(32); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "remove"; text: qsTr("Remove selected bookmark"); enabled: root.selectedIndex >= 0
                onClicked: root.removeSelected()
            }
            RedesignButton {
                implicitWidth: theme.dp(32); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "add"; text: qsTr("Bookmark current time"); enabled: Player.isStarted
                onClicked: bookmarks.add()
            }
        }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true
            model: bookmarks
            clip: true
            Keys.onDeletePressed: root.removeSelected()
            C.ScrollBar.vertical: C.ScrollBar {}
            delegate: Item {
                id: row
                required property int index
                required property string name
                required property string time
                readonly property bool selected: root.selectedIndex === index
                width: list.width; height: root.theme.dp(36)
                Accessible.role: Accessible.ListItem
                Accessible.name: name
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: -root.theme.dp(6)
                    radius: root.theme.dp(4)
                    color: row.selected ? root.theme.sidebarSelected : hover.hovered ? root.theme.sidebarHover : "transparent"
                }
                HoverHandler { id: hover }
                TapHandler {
                    onTapped: { root.selectedIndex = row.index; list.forceActiveFocus() }
                    onDoubleTapped: bookmarks.select(bookmarks.index(row.index, 0))
                }
                Text {
                    width: parent.width - bookmarkTime.width - root.theme.dp(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.name; elide: Text.ElideRight
                    color: row.selected || hover.hovered ? root.theme.bright : root.theme.rowText; font.pixelSize: root.theme.dp(15)
                }
                Text {
                    id: bookmarkTime
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: row.time; color: root.theme.mutedText; font.pixelSize: root.theme.dp(15)
                }
            }
            Text {
                width: parent.width; anchors.top: parent.top; anchors.topMargin: root.theme.dp(8)
                visible: list.count === 0
                text: qsTr("Save a moment with the + button.")
                color: root.theme.mutedText; font.pixelSize: root.theme.dp(14); wrapMode: Text.WordWrap
            }
        }
    }
}
