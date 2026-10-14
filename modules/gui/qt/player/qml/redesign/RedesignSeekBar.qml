// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Templates as T
import QtQuick.Window

T.Slider {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property var timeForPosition: function(position) { return "" }
    // image URL of a preview frame for a position, "" when there is none
    property var previewForPosition: function(position) { return "" }
    // distance from the bar's top to where the preview card floats, like the side panels
    property real previewLift: theme.dp(10)
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    implicitHeight: theme.dp(28)
    implicitWidth: theme.dp(200)
    padding: theme.dp(2)
    from: 0
    to: 1
    stepSize: 0.005
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.name: qsTr("Playback position")

    background: Rectangle {
        color: theme.field
        radius: theme.dp(6)
        border.color: root.visualFocus ? theme.accent : "transparent"
        border.width: theme.dp(1)
        Rectangle {
            // Ahead of the playhead, the hovered stretch is shaded like on the web.
            objectName: "seekHoverTrail"
            x: root.leftPadding
            y: root.topPadding
            width: Math.max(0, root.hoverX - root.leftPadding)
            height: root.availableHeight
            radius: theme.dp(4)
            color: root.lightTheme ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.16)
            visible: root.hovered && !root.pressed && root.hoverPosition > root.value
        }
        Rectangle {
            x: root.leftPadding
            y: root.topPadding
            width: root.visualPosition * (root.availableWidth - root.handle.width) + root.handle.width
            height: root.availableHeight
            radius: theme.dp(4)
            color: theme.progress
            visible: root.value > 0
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding
        width: theme.dp(8)
        height: root.availableHeight
        radius: theme.dp(4)
        color: theme.accent
        opacity: root.enabled ? 1 : 0.35
    }
    HoverHandler { id: pointer }

    // Same mapping the slider uses for clicks, so the preview shows where a click lands.
    readonly property real hoverPosition: pressed || !hovered ? value
        : Math.max(0, Math.min(1, (pointer.point.position.x - leftPadding - handle.width / 2)
                                  / (availableWidth - handle.width)))
    readonly property real hoverX: pressed || !hovered ? handle.x + handle.width / 2
        : Math.max(leftPadding, Math.min(leftPadding + availableWidth, pointer.point.position.x))

    // A plain item above the bar, not a Popup: an open Popup's overlay covers the window
    // and swallows the hover moves this card follows, freezing it in place.
    Item {
        id: card
        objectName: "seekPreview"
        readonly property string source: root.previewForPosition(root.hoverPosition)
        readonly property real radius: theme.dp(preview.visible ? 16 : 8)
        readonly property real margin: theme.dp(10)
        visible: root.enabled && (root.hovered || root.pressed || root.visualFocus)
        z: 10
        width: preview.visible ? theme.dp(272) : content.implicitWidth + theme.dp(24)
        height: content.implicitHeight + (preview.visible ? theme.dp(12) : theme.dp(6)) + theme.dp(6)
        // centred on the pointer along the whole bar, kept inside the window
        x: {
            const windowX = root.mapToItem(null, 0, 0).x
            const windowWidth = root.Window.width > 0 ? root.Window.width : root.width
            const wanted = root.hoverX - width / 2
            return Math.max(margin - windowX, Math.min(windowWidth - margin - windowX - width, wanted))
        }
        y: -height - root.previewLift
        Repeater {
            // the side panels' soft shadow, so the card floats the same way
            model: 4
            Rectangle {
                required property int index
                anchors.fill: parent
                anchors.margins: -theme.dp(index + 1); anchors.topMargin: -theme.dp(index + 1) + theme.dp(4)
                radius: card.radius + theme.dp(index + 1); color: "#000000"; opacity: 0.08
            }
        }
        Rectangle { anchors.fill: parent; color: theme.background; radius: card.radius; border.color: theme.border }
        Column {
            id: content
            x: theme.dp(12)
            y: preview.visible ? theme.dp(12) : theme.dp(6)
            width: card.width - theme.dp(24)
            spacing: theme.dp(4)
            Item {
                id: preview
                visible: card.source !== ""
                width: parent.width
                height: frame.status === Image.Ready && frame.implicitWidth > 0
                        ? Math.min(width * frame.implicitHeight / frame.implicitWidth, width)
                        : width * 9 / 16
                Rectangle { anchors.fill: parent; color: theme.field }
                Image {
                    id: frame
                    anchors.fill: parent
                    source: card.source
                    asynchronous: false
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                Rectangle {
                    // rounds the frame's corners against the card
                    anchors.fill: parent
                    anchors.margins: -theme.dp(6)
                    color: "transparent"
                    radius: theme.dp(14)
                    border.width: theme.dp(6)
                    border.color: theme.background
                }
            }
            Text {
                id: cardTime
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeForPosition(root.hoverPosition)
                color: theme.foreground
                font.pixelSize: theme.dp(14)
                topPadding: preview.visible ? theme.dp(4) : 0
            }
        }
    }
}
