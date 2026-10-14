// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C

// The design's queue tab: a summary line with list actions, then draggable rows.
Item {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property var queueModel
    property int itemCount: 0
    property string totalDuration
    property bool random: false
    property bool repeating: false
    property int selectedIndex: -1
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    signal closeRequested()
    signal addRequested()
    signal saveRequested()
    signal clearRequested()
    signal shuffleRequested()
    signal repeatRequested()
    signal sortRequested(string key)
    signal playRequested(int index)
    signal removeRequested(int index)
    signal moveRequested(int from, int to)
    signal libraryDropRequested(var source)
    onItemCountChanged: if (selectedIndex >= itemCount) selectedIndex = -1

    function removeSelected() {
        if (selectedIndex < 0) return
        const index = selectedIndex
        selectedIndex = -1
        removeRequested(index)
    }

    component HeaderButton: RedesignButton {
        implicitWidth: root.theme.dp(32); implicitHeight: root.theme.dp(32)
        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.dp(28); anchors.rightMargin: theme.dp(20); anchors.topMargin: theme.dp(18)
        spacing: theme.dp(8)
        RowLayout {
            Layout.fillWidth: true
            spacing: theme.dp(4)
            Text {
                objectName: "queueSummary"
                Layout.fillWidth: true
                text: root.totalDuration.length ? qsTr("%n item(s) - %1", "", root.itemCount).arg(root.totalDuration)
                                                : qsTr("%n item(s)", "", root.itemCount)
                color: theme.mutedText; font.pixelSize: theme.dp(15); elide: Text.ElideRight
            }
            HeaderButton { iconName: "sort"; text: qsTr("Sort and queue actions"); onClicked: queueMenu.popup() }
            HeaderButton { iconName: "repeat"; text: qsTr("Repeat"); selected: root.repeating; onClicked: root.repeatRequested() }
            HeaderButton { iconName: "shuffle"; text: qsTr("Shuffle"); selected: root.random; onClicked: root.shuffleRequested() }
            HeaderButton { objectName: "queueRemove"; iconName: "remove"; text: qsTr("Remove selected item"); enabled: root.selectedIndex >= 0; onClicked: root.removeSelected() }
            HeaderButton { iconName: "add"; text: qsTr("Add files to queue"); onClicked: root.addRequested() }
            C.Menu {
                id: queueMenu
                C.MenuItem { text: qsTr("Sort by title"); enabled: root.itemCount > 1; onTriggered: root.sortRequested("title") }
                C.MenuItem { text: qsTr("Sort by duration"); enabled: root.itemCount > 1; onTriggered: root.sortRequested("duration") }
                C.MenuItem { text: qsTr("Sort by artist"); enabled: root.itemCount > 1; onTriggered: root.sortRequested("artist") }
                C.MenuItem { text: qsTr("Sort by album"); enabled: root.itemCount > 1; onTriggered: root.sortRequested("album") }
                C.MenuSeparator {}
                C.MenuItem { text: qsTr("Save queue to file"); enabled: root.itemCount > 0; onTriggered: root.saveRequested() }
                C.MenuItem { text: qsTr("Clear queue"); enabled: root.itemCount > 0; onTriggered: root.clearRequested() }
            }
        }
        ListView {
            id: list
            objectName: "queueList"
            Layout.fillWidth: true; Layout.fillHeight: true
            model: root.queueModel
            clip: true
            focus: true
            property int dropIndex: -1
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) { root.removeSelected(); event.accepted = true }
            }
            C.ScrollBar.vertical: C.ScrollBar {}
            delegate: Item {
                id: row
                required property int index
                required property string title
                required property bool isCurrent
                required property var model
                readonly property bool selected: root.selectedIndex === index
                width: list.width; height: root.theme.dp(44)
                Accessible.role: Accessible.ListItem
                Accessible.name: title
                Accessible.selected: selected
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: -root.theme.dp(8)
                    radius: root.theme.dp(4)
                    color: row.selected ? root.theme.sidebarSelected : rowHover.hovered ? root.theme.sidebarHover : "transparent"
                }
                Rectangle {
                    // Where a dragged row will land.
                    visible: list.dropIndex === row.index
                    width: parent.width; height: root.theme.dp(2); color: root.theme.accent
                }
                HoverHandler { id: rowHover }
                TapHandler {
                    onTapped: { root.selectedIndex = row.index; list.forceActiveFocus() }
                    onDoubleTapped: root.playRequested(row.index)
                }
                RedesignIcon {
                    id: handle
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.theme.dp(24); height: width
                    name: "move"; color: root.theme.foreground
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -root.theme.dp(6)
                        cursorShape: Qt.SizeVerCursor
                        preventStealing: true
                        onPositionChanged: mouse => {
                            const y = mapToItem(list.contentItem, mouse.x, mouse.y).y
                            const target = list.indexAt(10, y)
                            list.dropIndex = target < 0 ? (y < 0 ? 0 : root.itemCount - 1) : target
                        }
                        onReleased: {
                            const target = list.dropIndex
                            list.dropIndex = -1
                            if (target >= 0 && target !== row.index)
                                root.moveRequested(row.index, target > row.index ? target + 1 : target)
                        }
                    }
                }
                Text {
                    x: root.theme.dp(34); width: duration.x - x - root.theme.dp(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.title; elide: Text.ElideRight
                    color: row.isCurrent ? root.theme.accent : row.selected || rowHover.hovered ? root.theme.bright : root.theme.rowText
                    font.pixelSize: root.theme.dp(15)
                }
                Text {
                    id: duration
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: row.model.duration && row.model.duration.valid() ? row.model.duration.formatHMS() : ""
                    color: root.theme.mutedText; font.pixelSize: root.theme.dp(15)
                }
            }
            Text {
                anchors.fill: parent
                anchors.topMargin: root.theme.dp(12)
                visible: root.itemCount === 0
                text: qsTr("Drop files here, or add media from your library.")
                wrapMode: Text.WordWrap; color: root.theme.mutedText; font.pixelSize: root.theme.dp(14)
            }
        }
    }
    DropArea {
        anchors.fill: parent
        keys: ["vlc-redesign-library"]
        onDropped: drop => {
            if (drop.source && drop.source["libraryView"]) {
                root.libraryDropRequested(drop.source)
                drop.acceptProposedAction()
            }
        }
    }
}
