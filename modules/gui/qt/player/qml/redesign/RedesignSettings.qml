// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.Player
import VLC.Dialogs

// The design's playback-settings panel. Only controls VLC can drive live are shown;
// the rest of each area stays one click away in the effects window and preferences.
Rectangle {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property string page: "playback"
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    signal pageRequested(string page)
    signal closeRequested()
    signal sleepTimerRequested(int minutes)
    color: "transparent"

    component SectionTitle: Text {
        Layout.fillWidth: true; Layout.topMargin: root.theme.dp(20); Layout.bottomMargin: root.theme.dp(4)
        color: root.theme.sectionTitle; font.pixelSize: root.theme.dp(16); font.weight: Font.Medium
    }
    component Separator: Rectangle {
        Layout.fillWidth: true; Layout.leftMargin: -root.theme.dp(20); Layout.rightMargin: -root.theme.dp(20)
        Layout.topMargin: root.theme.dp(16)
        height: root.theme.dp(1); color: root.theme.separator
    }
    component ChoiceRow: RowLayout {
        property alias label: rowLabel.text
        property alias choices: rowChoice.choices
        Layout.fillWidth: true; Layout.preferredHeight: root.theme.dp(68)
        spacing: root.theme.dp(10)
        Text { id: rowLabel; Layout.fillWidth: true; color: root.theme.foreground; font.pixelSize: root.theme.dp(15); elide: Text.ElideRight }
        RedesignChoiceDropdown {
            id: rowChoice
            Layout.preferredWidth: root.theme.dp(216); Layout.preferredHeight: root.theme.dp(44)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            Accessible.name: rowLabel.text
        }
    }
    component ExpandRow: RedesignButton {
        id: expand
        Layout.fillWidth: true; Layout.preferredHeight: root.theme.dp(40); Layout.topMargin: root.theme.dp(8)
        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
        text: qsTr("Expand Settings")
        background: Rectangle {
            radius: root.theme.dp(4)
            color: expand.hovered || expand.down ? root.theme.controlHover : root.theme.control
            border.width: expand.visualFocus ? root.theme.dp(1) : 0; border.color: root.theme.accent
        }
        contentItem: RowLayout {
            Text { Layout.fillWidth: true; Layout.leftMargin: root.theme.dp(12); text: expand.text; color: expand.hovered ? root.theme.bright : root.theme.foreground; font.pixelSize: root.theme.dp(14) }
            RedesignIcon { Layout.preferredWidth: root.theme.dp(20); Layout.preferredHeight: root.theme.dp(20); Layout.rightMargin: root.theme.dp(8); name: "chevron-right"; color: root.theme.foreground }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RedesignPanelTabs {
            Layout.fillWidth: true
            topRadius: theme.dp(8)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            model: [{key: "playback", icon: "playback", label: qsTr("Playback")}, {key: "video", icon: "video", label: qsTr("Video")}, {key: "audio", icon: "audio", label: qsTr("Audio")}, {key: "subtitles", icon: "subtitles", label: qsTr("Subtitles")}]
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
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: theme.dp(20); Layout.topMargin: theme.dp(16)
                    spacing: 0
                    visible: root.page === "playback"
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: theme.dp(68)
                        Text { Layout.fillWidth: true; text: qsTr("Sleep Timer"); color: theme.foreground; font.pixelSize: theme.dp(15) }
                        RedesignDropdown {
                            objectName: "sleepTimer"
                            Layout.preferredWidth: theme.dp(216); Layout.preferredHeight: theme.dp(44)
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            Accessible.name: qsTr("Sleep timer")
                            model: [qsTr("Off"), qsTr("15 minutes"), qsTr("30 minutes"), qsTr("60 minutes"), qsTr("90 minutes")]
                            onActivated: index => root.sleepTimerRequested([0, 15, 30, 60, 90][index])
                        }
                    }
                    ChoiceRow { label: qsTr("Audio Visualizer"); choices: Player.audioVisualization }
                    RedesignSettingSlider {
                        objectName: "playbackRateControl"
                        Layout.fillWidth: true; Layout.topMargin: theme.dp(12)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        label: qsTr("Speed"); suffix: "x"; decimals: 2
                        from: 0.25; to: 2; stepSize: 0.05
                        ticks: [0.5, 0.75, 1, 1.25, 1.5, 1.75]
                        scaleLabels: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map(v => ({value: v, text: String(v)}))
                        currentValue: Player.rate; enabled: Player.ratechangable
                        onMoved: value => Player.rate = value
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: theme.dp(20); Layout.topMargin: theme.dp(0)
                    spacing: 0
                    visible: root.page === "video"
                    SectionTitle { text: qsTr("Defaults") }
                    ChoiceRow { label: qsTr("Zoom"); choices: Player.zoom }
                    ChoiceRow { label: qsTr("Aspect Ratio"); choices: Player.aspectRatio }
                    ChoiceRow { label: qsTr("Crop"); choices: Player.crop }
                    ChoiceRow { label: qsTr("Deinterlace"); choices: Player.deinterlace }
                    Separator {}
                    SectionTitle { text: qsTr("Filters") }
                    Text { text: qsTr("Essential"); color: theme.foreground; font.pixelSize: theme.dp(15); Layout.topMargin: theme.dp(8) }
                    ExpandRow { onClicked: DialogsProvider.extendedDialog() }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: theme.dp(20); Layout.topMargin: theme.dp(0)
                    spacing: 0
                    visible: root.page === "audio"
                    SectionTitle { text: qsTr("Defaults") }
                    ChoiceRow { label: qsTr("Stereo Mode"); choices: Player.audioStereoMode }
                    Separator {}
                    SectionTitle { text: qsTr("Synchronization") }
                    RedesignSettingSlider {
                        Layout.fillWidth: true; Layout.topMargin: theme.dp(10)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        label: qsTr("Audio Track Delay"); suffix: " s"; decimals: 3
                        from: -10; to: 10; stepSize: 0.05
                        scaleLabels: [{value: -10, text: "-10 s"}, {value: 0, text: "0 s"}, {value: 10, text: "+10 s"}]
                        currentValue: Player.audioDelayMS / 1000
                        onMoved: value => Player.audioDelayMS = Math.round(value * 1000)
                    }
                    Separator {}
                    SectionTitle { text: qsTr("Filters") }
                    Text { text: qsTr("Equalizer"); color: theme.foreground; font.pixelSize: theme.dp(15); Layout.topMargin: theme.dp(8) }
                    ExpandRow { onClicked: DialogsProvider.extendedDialog() }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: theme.dp(20); Layout.topMargin: theme.dp(0)
                    spacing: 0
                    visible: root.page === "subtitles"
                    SectionTitle { text: qsTr("Synchronization") }
                    RedesignSettingSlider {
                        Layout.fillWidth: true; Layout.topMargin: theme.dp(10)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        label: qsTr("Subtitle Track Delay"); suffix: " s"; decimals: 3
                        from: -10; to: 10; stepSize: 0.05
                        scaleLabels: [{value: -10, text: "-10 s"}, {value: 0, text: "0 s"}, {value: 10, text: "+10 s"}]
                        currentValue: Player.subtitleDelayMS / 1000
                        onMoved: value => Player.subtitleDelayMS = Math.round(value * 1000)
                    }
                    RedesignSettingSlider {
                        Layout.fillWidth: true; Layout.topMargin: theme.dp(18)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        label: qsTr("Subtitle Speed"); suffix: " fps"; decimals: 3
                        from: 1; to: 60; stepSize: 0.001
                        currentValue: Player.subtitleFPS
                        onMoved: value => Player.subtitleFPS = value
                    }
                    Separator {}
                    SectionTitle { text: qsTr("Appearance") }
                    Text { text: qsTr("Font, size and colors"); color: theme.foreground; font.pixelSize: theme.dp(15); Layout.topMargin: theme.dp(8) }
                    ExpandRow { onClicked: DialogsProvider.prefsDialog() }
                }
            }
        }
        RedesignButton {
            id: advanced
            objectName: "openAdvancedSettings"
            // Full-width so the whole row is the target; icon and label sit centred in it.
            Layout.fillWidth: true; Layout.preferredHeight: theme.dp(36)
            Layout.leftMargin: theme.dp(20); Layout.rightMargin: theme.dp(20)
            Layout.topMargin: theme.dp(8); Layout.bottomMargin: theme.dp(14)
            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
            text: qsTr("Open Advanced Settings")
            background: Rectangle {
                radius: theme.dp(4); color: advanced.hovered || advanced.down ? theme.sidebarHover : "transparent"
                border.width: advanced.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
            }
            contentItem: Item {
                Row {
                    anchors.centerIn: parent
                    spacing: theme.dp(6)
                    RedesignIcon { anchors.verticalCenter: parent.verticalCenter; width: theme.dp(20); height: width; name: "settings"; color: advanced.hovered ? theme.bright : theme.foreground }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: advanced.text; color: advanced.hovered ? theme.bright : theme.foreground; font.pixelSize: theme.dp(14) }
                }
            }
            onClicked: DialogsProvider.prefsDialog()
        }
    }
}
