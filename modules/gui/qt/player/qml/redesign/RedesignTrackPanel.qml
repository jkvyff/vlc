// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Dialogs

// The design's track panel, opened from the audio and subtitle buttons.
Rectangle {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property string page: "subtitles"
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    signal pageRequested(string page)
    signal preferencesRequested(string page)
    signal subtitleSettingsRequested()
    color: "transparent"

    function select(model, index, selected) { model.setData(model.index(index, 0), selected, Qt.CheckStateRole) }
    function disable(model) { for (let i = 0; i < model.rowCount(); ++i) select(model, i, false) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RedesignPanelTabs {
            Layout.fillWidth: true
            topRadius: theme.dp(8)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            model: [{key: "video", label: qsTr("Video"), icon: "video"}, {key: "audio", label: qsTr("Audio"), icon: "audio"}, {key: "subtitles", label: qsTr("Subtitles"), icon: "subtitles"}]
            current: root.page
            onActivated: key => root.pageRequested(key)
        }
        C.ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            ColumnLayout {
                width: parent.width
                spacing: 0
                RedesignTracks {
                    objectName: "embeddedTracks"
                    Layout.fillWidth: true; Layout.leftMargin: theme.dp(28); Layout.rightMargin: theme.dp(28); Layout.topMargin: theme.dp(12)
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    heading: qsTr("Embedded Tracks")
                    trackModel: root.page === "video" ? Player.videoTracks : root.page === "audio" ? Player.audioTracks : Player.subtitleTracks
                    allowDisable: true
                    onSelectionRequested: (index, selected) => root.select(trackModel, index, selected)
                    onDisableRequested: root.disable(trackModel)
                }
                Rectangle {
                    visible: root.page !== "video"
                    Layout.fillWidth: true; Layout.topMargin: theme.dp(12); Layout.bottomMargin: theme.dp(12)
                    height: theme.dp(1); color: theme.separator
                }
                RedesignTracks {
                    visible: root.page === "audio"
                    Layout.fillWidth: true; Layout.leftMargin: theme.dp(28); Layout.rightMargin: theme.dp(28)
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    heading: qsTr("Output Device"); trackModel: Player.audioDevices
                    onSelectionRequested: (index, selected) => root.select(trackModel, index, selected)
                }
                RowLayout {
                    visible: root.page === "subtitles"
                    Layout.fillWidth: true; Layout.leftMargin: theme.dp(28); Layout.rightMargin: theme.dp(20)
                    Layout.preferredHeight: theme.dp(40)
                    Text { Layout.fillWidth: true; text: qsTr("External Tracks"); color: theme.mutedText; font.pixelSize: theme.dp(14) }
                    RedesignButton {
                        implicitWidth: theme.dp(32); implicitHeight: theme.dp(32)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        iconName: "edit"; text: qsTr("Subtitle timing and appearance")
                        onClicked: root.subtitleSettingsRequested()
                    }
                    RedesignButton {
                        objectName: "addSubtitleButton"
                        implicitWidth: theme.dp(32); implicitHeight: theme.dp(32)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        iconName: "add"; text: qsTr("Add subtitle file")
                        onClicked: DialogsProvider.loadSubtitlesFile()
                    }
                }
                Item { Layout.preferredHeight: theme.dp(16) }
            }
        }
        RedesignButton {
            id: showPreferences
            objectName: "showPreferencesButton"
            Layout.fillWidth: true; Layout.margins: theme.dp(20); Layout.preferredHeight: theme.dp(32)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            text: qsTr("Show Preferences")
            background: Rectangle {
                radius: theme.dp(4)
                color: showPreferences.hovered || showPreferences.down ? theme.control : theme.topBar
                border.width: showPreferences.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
            }
            contentItem: Text {
                text: showPreferences.text; font.pixelSize: theme.dp(15)
                color: showPreferences.hovered ? theme.foreground : theme.mutedText
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            onClicked: root.preferencesRequested(root.page)
        }
    }
}
