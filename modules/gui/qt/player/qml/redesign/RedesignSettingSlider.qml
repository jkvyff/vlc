// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

// The design's labelled slider: name and editable value on one line, then a
// dark track filled from its origin, with optional ticks and scale labels.
ColumnLayout {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property string label
    property string suffix
    property int decimals: 0
    property real currentValue: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.1
    property var ticks: []          // values marked on the track
    property var scaleLabels: []    // [{value, text}] shown under the track
    readonly property real origin: from < 0 && to > 0 ? 0 : from
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    signal moved(real value)
    spacing: theme.dp(10)

    function format(value) { return Number(value).toFixed(root.decimals) + root.suffix }
    function commitText(text) {
        const value = Number(text.replace(root.suffix.trim(), "").replace(",", ".").trim())
        if (!isNaN(value)) root.moved(Math.max(root.from, Math.min(root.to, value)))
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: theme.dp(10)
        Text { Layout.fillWidth: true; text: root.label; color: theme.foreground; font.pixelSize: theme.dp(15); wrapMode: Text.WordWrap }
        Rectangle {
            Layout.preferredWidth: theme.dp(138); Layout.preferredHeight: theme.dp(32)
            radius: theme.dp(4); color: theme.field
            border.width: valueField.activeFocus ? theme.dp(1) : 0; border.color: theme.accent
            TextInput {
                id: valueField
                objectName: "settingValueField"
                anchors.fill: parent; anchors.leftMargin: theme.dp(12); anchors.rightMargin: theme.dp(12)
                verticalAlignment: TextInput.AlignVCenter
                color: theme.rowText; selectionColor: theme.progress; selectedTextColor: theme.bright
                font.pixelSize: theme.dp(14)
                selectByMouse: true
                enabled: root.enabled
                text: root.format(root.currentValue)
                Accessible.name: root.label
                onEditingFinished: { root.commitText(text); text = Qt.binding(() => root.format(root.currentValue)) }
                onActiveFocusChanged: if (activeFocus) selectAll()
            }
        }
    }
    T.Slider {
        id: slider
        objectName: "settingSlider"
        Layout.fillWidth: true
        implicitHeight: theme.dp(26)
        from: root.from; to: root.to; stepSize: root.stepSize
        snapMode: T.Slider.SnapOnRelease
        focusPolicy: Qt.StrongFocus
        Binding on value { when: !slider.pressed; value: root.currentValue }
        onMoved: root.moved(value)
        Accessible.name: root.label
        function at(value) { return (value - root.from) / (root.to - root.from) * width }
        background: Rectangle {
            y: (slider.height - height) / 2
            width: slider.width; height: root.theme.dp(16)
            radius: root.theme.dp(2); color: root.theme.field
            Rectangle {
                readonly property real start: slider.at(root.origin)
                readonly property real end: slider.visualPosition * slider.width
                x: Math.min(start, end); width: Math.abs(end - start); height: parent.height
                radius: parent.radius; color: root.theme.progress
            }
            Repeater {
                model: root.ticks
                Rectangle {
                    required property real modelData
                    x: slider.at(modelData); anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(1, root.theme.dp(1)); height: root.theme.dp(6)
                    color: root.theme.controlKnob
                }
            }
        }
        handle: Rectangle {
            x: slider.visualPosition * (slider.width - width)
            y: (slider.height - height) / 2
            width: root.theme.dp(8); height: root.theme.dp(26); radius: root.theme.dp(4)
            color: root.theme.accent
            border.width: slider.visualFocus ? root.theme.dp(1) : 0; border.color: root.theme.bright
        }
    }
    Item {
        visible: root.scaleLabels.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: theme.dp(16)
        Repeater {
            model: root.scaleLabels
            Text {
                required property var modelData
                required property int index
                // End labels hug the track edges; the rest are centred on their value.
                x: index === 0 ? 0 : index === root.scaleLabels.length - 1 ? parent.width - width
                    : slider.at(modelData.value) - width / 2
                text: modelData.text; color: root.theme.foreground; font.pixelSize: root.theme.dp(12)
            }
        }
    }
}
