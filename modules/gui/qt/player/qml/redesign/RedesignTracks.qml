// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

// A titled checklist of tracks or devices, as in the design's track panel.
ColumnLayout {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property var trackModel
    property string heading
    property bool allowDisable: false
    // Buttons shown at the end of the heading (for example add or edit).
    default property alias headerActions: actions.data
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    readonly property bool anySelected: {
        let selected = false
        for (let i = 0; i < choices.count; ++i)
            if (choices.itemAt(i) && choices.itemAt(i).checked) selected = true
        return selected
    }
    signal selectionRequested(int index, bool selected)
    signal disableRequested()
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.theme.dp(40)
        Text {
            Layout.fillWidth: true
            text: root.heading; color: root.theme.mutedText; font.pixelSize: root.theme.dp(14)
            elide: Text.ElideRight
        }
        Row { id: actions; spacing: root.theme.dp(4) }
    }
    Component {
        id: rowComponent
        T.AbstractButton {
            id: row
            // Not "checked": that Button property is FINAL and would make the row checkable.
            property bool marked
            Layout.fillWidth: true
            implicitHeight: root.theme.dp(44)
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.RadioButton
            Accessible.name: text
            Accessible.checked: marked
            background: Rectangle {
                anchors.fill: parent; anchors.leftMargin: -root.theme.dp(8); anchors.rightMargin: -root.theme.dp(8)
                radius: root.theme.dp(4)
                color: row.hovered ? root.theme.sidebarHover : "transparent"
                border.width: row.visualFocus ? root.theme.dp(1) : 0; border.color: root.theme.accent
            }
            contentItem: Item {
                RedesignIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.theme.dp(24); height: width
                    name: "check"; accentColor: root.theme.accent
                    visible: row.marked
                }
                Text {
                    x: root.theme.dp(34); width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.text; elide: Text.ElideRight
                    color: row.marked || row.hovered ? root.theme.bright : root.theme.rowText
                    font.pixelSize: root.theme.dp(15)
                }
            }
        }
    }
    Loader {
        Layout.fillWidth: true
        active: root.allowDisable
        visible: active
        sourceComponent: rowComponent
        onLoaded: {
            item.text = qsTr("None")
            item.marked = Qt.binding(() => !root.anySelected)
            item.clicked.connect(root.disableRequested)
        }
    }
    Repeater {
        id: choices
        model: root.trackModel
        Loader {
            id: track
            required property int index
            required property string display
            required property bool checked
            Layout.fillWidth: true
            sourceComponent: rowComponent
            onLoaded: {
                item.text = Qt.binding(() => track.display)
                item.marked = Qt.binding(() => track.checked)
                item.clicked.connect(() => root.selectionRequested(track.index, !track.checked))
            }
        }
    }
    Text {
        visible: choices.count === 0 && !root.allowDisable
        Layout.preferredHeight: root.theme.dp(44)
        verticalAlignment: Text.AlignVCenter
        text: qsTr("No tracks available"); color: root.theme.mutedText; font.pixelSize: root.theme.dp(14)
    }
}
