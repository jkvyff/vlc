// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls.Basic as C
import VLC.MainInterface
import VLC.Style
import VLC.Dialogs

Window {
    id: root
    title: qsTr("Settings — VLC Media Player")
    width: Math.min(theme.dp(1078), Screen.desktopAvailableWidth - theme.dp(40))
    height: Math.min(theme.dp(895), Screen.desktopAvailableHeight - theme.dp(60))
    minimumWidth: theme.dp(640); minimumHeight: theme.dp(440)
    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    transientParent: MainCtx.intfMainWindow
    color: theme.sidebar
    property real scaleFactor: VLCStyle.scale
    property color accentColor: MainCtx.redesignAccent
    property bool lightTheme: !VLCStyle.palette.isDark
    property string category: "general"
    property string categoryTitle: qsTr("General")
    property bool advanced: false
    property bool expert: false
    property bool editingShortcuts: false
    property string search: ""
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    RedesignPreferences { id: preferenceStore; ctx: MainCtx; autoSave: true }
    RedesignPreferencesCatalog { id: specification }
    function begin() {
        preferenceStore.discard()
        searchField.clear()
        visible = true
        raise(); requestActivate()
    }
    function closeSettings() {
        content.forceActiveFocus()
        if (!preferenceStore.dirty || preferenceStore.save()) visible = false
    }
    onClosing: event => { event.accepted = false; closeSettings() }
    Connections {
        target: DialogsProvider
        function onShowRedesignPreferences() { if (!root.visible) root.begin(); else { root.raise(); root.requestActivate() } }
    }
    Item {
        id: content
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeSettings()
        Rectangle {
            id: topBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: theme.dp(50)
            color: theme.topBar
            MouseArea {
                anchors.fill: parent
                onPressed: root.startSystemMove()
            }
            C.TextField {
                id: searchField
                x: theme.dp(8); anchors.verticalCenter: parent.verticalCenter
                width: theme.dp(200); height: theme.dp(34)
                leftPadding: theme.dp(40)
                placeholderText: qsTr("Search")
                color: theme.foreground; placeholderTextColor: theme.controlKnob
                font.pixelSize: theme.dp(14); selectByMouse: true
                Accessible.name: qsTr("Search settings")
                background: Rectangle {
                    color: theme.searchField; radius: theme.dp(6)
                    border.width: searchField.activeFocus ? theme.dp(1) : 0; border.color: theme.accent
                    RedesignIcon {
                        x: theme.dp(8); anchors.verticalCenter: parent.verticalCenter
                        width: theme.dp(24); height: width
                        name: "search"; color: theme.controlKnob
                    }
                }
                onTextEdited: root.search = text
                onTextChanged: if (!text.length) root.search = ""
            }
            Text {
                id: heading
                x: navigation.width + theme.dp(24)
                width: Math.max(0, closeButton.x - x - theme.dp(24))
                anchors.verticalCenter: parent.verticalCenter
                text: root.search.length ? qsTr("Search results") : qsTr("%1 Settings").arg(root.categoryTitle)
                color: theme.topBarText; font.pixelSize: theme.dp(16)
                elide: Text.ElideRight
            }
            RedesignButton {
                id: closeButton
                anchors.right: parent.right; anchors.rightMargin: theme.dp(14)
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: theme.dp(32); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "close"; text: qsTr("Close settings")
                background: Rectangle {
                    radius: theme.dp(4)
                    color: closeButton.hovered || closeButton.down ? theme.sidebarHover : "transparent"
                    border.width: closeButton.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
                }
                onClicked: root.closeSettings()
            }
        }
        Item {
            id: navigation
            width: theme.dp(216); anchors.top: topBar.bottom; anchors.bottom: parent.bottom
            Rectangle {
                id: categoryPanel
                anchors { fill: parent; margins: theme.dp(8) }
                radius: theme.dp(6)
                color: theme.sidebarPanel
                C.ScrollView {
                    anchors.fill: parent; anchors.margins: theme.dp(6)
                    clip: true
                    Column {
                        width: categoryPanel.width - theme.dp(12)
                        Repeater {
                            model: [
                                {group: qsTr("App"), key: "general", title: qsTr("General"), icon: "preferences"},
                                {key: "interface", title: qsTr("Interface"), icon: "interface"},
                                {key: "privacy", title: qsTr("Privacy"), icon: "privacy"},
                                {key: "controls", title: qsTr("Controls"), icon: "hotkeys"},
                                {group: qsTr("Media"), key: "playback", title: qsTr("Playback"), icon: "playback"},
                                {key: "video", title: qsTr("Video"), icon: "video"},
                                {key: "audio", title: qsTr("Audio"), icon: "audio"},
                                {key: "subtitles", title: qsTr("Subtitles"), icon: "subtitles"},
                                {key: "library", title: qsTr("Library"), icon: "folder"},
                                {group: qsTr("System"), key: "network", title: qsTr("Network"), icon: "streaming"},
                                {key: "performance", title: qsTr("Performance"), icon: "preferences"},
                                {key: "recording", title: qsTr("Recording"), icon: "record"},
                                {key: "extensions", title: qsTr("Extensions"), icon: "plugins"} ]
                            delegate: Column {
                                required property var modelData
                                width: parent.width
                                spacing: theme.dp(8)
                                topPadding: modelData.group && modelData.key !== "general" ? theme.dp(8) : 0
                                bottomPadding: theme.dp(8)
                                Text {
                                    visible: !!modelData.group
                                    width: parent.width; height: visible ? theme.dp(33) : 0
                                    leftPadding: theme.dp(10); verticalAlignment: Text.AlignVCenter
                                    text: modelData.group || ""; color: theme.mutedText; font.pixelSize: theme.dp(14)
                                }
                                RedesignButton {
                                    id: categoryButton
                                    objectName: "settingsCategory_" + modelData.key
                                    width: parent.width; height: theme.dp(40)
                                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                                    caption: modelData.title; text: caption; iconName: modelData.icon
                                    selected: root.category === modelData.key && !root.search.length
                                    background: Rectangle {
                                        radius: theme.dp(2)
                                        color: categoryButton.selected ? theme.sidebarSelected : categoryButton.hovered ? theme.sidebarHover : "transparent"
                                        border.width: categoryButton.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
                                    }
                                    contentItem: Row {
                                        leftPadding: theme.dp(4); spacing: theme.dp(8)
                                        RedesignIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: theme.dp(24); height: width
                                            name: categoryButton.selected ? categoryButton.iconName + "-active" : categoryButton.iconName
                                            color: theme.foreground; accentColor: theme.accent
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: categoryButton.caption; font.pixelSize: theme.dp(14)
                                            color: categoryButton.selected ? theme.sidebarSelectedText : categoryButton.hovered ? theme.bright : theme.foreground
                                        }
                                    }
                                    onClicked: {
                                        root.category = modelData.key; root.categoryTitle = modelData.title
                                        root.search = ""; searchField.clear(); root.advanced = false; root.expert = false; root.editingShortcuts = false
                                        scroll.contentItem.contentY = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        C.ScrollView {
            id: scroll
            anchors.top: topBar.bottom; anchors.topMargin: theme.dp(20)
            anchors.left: navigation.right; anchors.right: parent.right; anchors.bottom: footer.top
            anchors.leftMargin: theme.dp(24); anchors.rightMargin: theme.dp(24)
            clip: true
            contentWidth: availableWidth
            Column {
                width: scroll.availableWidth
                spacing: theme.dp(6)
                ColumnLayout {
                    visible: root.category === "general" && !root.search.length
                    width: parent.width
                    spacing: 0
                    Text {
                        Layout.preferredHeight: theme.dp(39); verticalAlignment: Text.AlignVCenter
                        text: qsTr("Appearance"); color: theme.sectionTitle
                        font.pixelSize: theme.dp(16); font.weight: Font.Medium
                    }
                    RowLayout {
                        visible: preferenceStore.interfaceLanguageSupported
                        Layout.fillWidth: true; Layout.preferredHeight: theme.dp(46)
                        spacing: theme.dp(10)
                        Text { text: qsTr("Interface language"); color: theme.foreground; font.pixelSize: theme.dp(14) }
                        RedesignInfoButton {
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            help: qsTr("Language of VLC's menus and windows. Takes effect after VLC restarts.")
                        }
                        Item { Layout.fillWidth: true }
                        RedesignDropdown {
                            id: languageChoice
                            objectName: "interfaceLanguage"
                            Layout.preferredWidth: theme.dp(320)
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            Accessible.name: qsTr("Interface language")
                            model: preferenceStore.interfaceLanguageSupported ? preferenceStore.interfaceLanguages() : []
                            textRole: "label"; valueRole: "value"
                            currentIndex: {
                                preferenceStore.revision
                                return indexOfValue(preferenceStore.interfaceLanguage())
                            }
                            onActivated: preferenceStore.setInterfaceLanguage(currentValue)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: theme.dp(46)
                        spacing: theme.dp(10)
                        Text { text: qsTr("Theme"); color: theme.foreground; font.pixelSize: theme.dp(14) }
                        RedesignInfoButton {
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            help: qsTr("Dark or light colors, or follow the system setting.")
                        }
                        Item { Layout.fillWidth: true }
                        RedesignSegmented {
                            Layout.preferredWidth: theme.dp(320)
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            accessibleName: qsTr("Theme")
                            model: [{label: qsTr("Dark"), value: 2}, {label: qsTr("Light"), value: 1}, {label: qsTr("System"), value: 0}]
                            currentValue: MainCtx.colorScheme.scheme
                            onActivated: value => MainCtx.colorScheme.setData(MainCtx.colorScheme.index(value, 0), true, Qt.CheckStateRole)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: theme.dp(46)
                        spacing: theme.dp(10)
                        Text { text: qsTr("Accent color"); color: theme.foreground; font.pixelSize: theme.dp(14) }
                        RedesignInfoButton {
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            help: qsTr("Color used for highlights, the seek bar and switches.")
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            id: accentSwatches
                            // "default" is stored for the first preset so the option keeps its stock value.
                            readonly property var names: [qsTr("Orange"), qsTr("Red"), qsTr("Yellow"), qsTr("Green"), qsTr("Cyan"), qsTr("Blue"), qsTr("Purple"), qsTr("Pink"), qsTr("Grey")]
                            readonly property color current: {
                                preferenceStore.revision
                                const value = preferenceStore.value("qt-accent-color")
                                return !value || value === "default" || value === "system" ? theme.accentPresets[0] : value
                            }
                            implicitWidth: swatchRow.implicitWidth + theme.dp(4)
                            implicitHeight: theme.dp(36)
                            color: theme.field; radius: theme.dp(6)
                            Row {
                                id: swatchRow
                                anchors.centerIn: parent
                                spacing: theme.dp(3.5)
                                Repeater {
                                    model: theme.accentPresets
                                    RedesignButton {
                                        id: swatch
                                        required property string modelData
                                        required property int index
                                        readonly property bool current: Qt.colorEqual(accentSwatches.current, modelData)
                                        width: theme.dp(31.5); height: theme.dp(32)
                                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                                        text: accentSwatches.names[index]
                                        Accessible.checkable: true; Accessible.checked: current
                                        background: Rectangle {
                                            radius: theme.dp(4)
                                            color: swatch.current ? theme.accentTint(swatch.modelData) : swatch.hovered ? theme.hover : "transparent"
                                            border.width: swatch.visualFocus ? theme.dp(1) : 0; border.color: theme.bright
                                            Rectangle {
                                                anchors.centerIn: parent; width: theme.dp(19.5); height: theme.dp(20); radius: theme.dp(1)
                                                color: swatch.modelData
                                            }
                                        }
                                        onClicked: preferenceStore.stage("qt-accent-color", index === 0 ? "default" : modelData)
                                    }
                                }
                            }
                        }
                        RedesignButton {
                            scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            iconName: "add"; text: qsTr("Custom accent color")
                            onClicked: { const color = preferenceStore.chooseColor(root.accentColor.toString()); if (color.length) preferenceStore.stage("qt-accent-color", color) }
                        }
                    }
                }
                Repeater {
                    model: root.search.length ? [] : specification.sections[root.category] || []
                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        visible: modelData.rows.some(row => preferenceStore.describe(row[0]).kind !== undefined) || root.category === "controls" && modelData.title === qsTr("Keyboard Shortcuts")
                        Text {
                            topPadding: theme.dp(30); bottomPadding: theme.dp(10)
                            text: modelData.title; color: theme.sectionTitle
                            font.pixelSize: theme.dp(16); font.weight: Font.Medium
                        }
                        Row {
                            visible: root.category === "controls" && modelData.title === qsTr("Keyboard Shortcuts")
                            spacing: theme.dp(12)
                            RedesignButton {
                                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                                caption: qsTr("Edit Keyboard Shortcuts"); text: caption
                                onClicked: root.editingShortcuts = !root.editingShortcuts
                            }
                            RedesignButton {
                                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                                caption: qsTr("Reset all shortcuts"); text: caption
                                onClicked: {
                                    for (const entry of preferenceStore.catalog("controls", ""))
                                        if (entry.name.startsWith("key-") || entry.name.startsWith("global-key-")) preferenceStore.reset(entry.name)
                                }
                            }
                        }
                        Repeater {
                            model: root.category === "controls" && root.editingShortcuts && modelData.title === qsTr("Keyboard Shortcuts")
                                ? preferenceStore.catalog("controls", "").filter(entry => entry.name.startsWith("key-") || entry.name.startsWith("global-key-")) : []
                            delegate: RedesignPreferenceRow {
                                required property var modelData
                                width: parent.width; backend: preferenceStore; optionName: modelData.name
                                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            }
                        }
                        Repeater {
                            model: modelData.rows
                            delegate: RedesignPreferenceRow {
                                required property var modelData
                                width: parent.width
                                backend: preferenceStore; optionName: modelData[0]; label: modelData[1]
                                presentation: modelData[2] || {}
                                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            }
                        }
                    }
                }
                Item { width: 1; height: theme.dp(20); visible: !root.search.length }
                RedesignButton {
                    id: advancedToggle
                    objectName: "advancedOptions"
                    visible: !root.search.length
                    width: parent.width; height: theme.dp(38)
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    text: root.advanced ? qsTr("Hide Advanced Options") : qsTr("Advanced Options")
                    Accessible.checkable: true; Accessible.checked: root.advanced
                    background: Rectangle {
                        radius: theme.dp(2)
                        color: advancedToggle.hovered || advancedToggle.down ? theme.controlHover : theme.sidebarPanel
                        border.width: advancedToggle.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
                    }
                    contentItem: Item {
                        Row {
                            anchors.centerIn: parent
                            spacing: theme.dp(4)
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: advancedToggle.text; font.pixelSize: theme.dp(14)
                                color: advancedToggle.hovered ? theme.bright : theme.foreground
                            }
                            RedesignIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: theme.dp(24); height: width
                                name: root.advanced ? "chevron-down" : "chevron-right"
                                color: advancedToggle.hovered ? theme.bright : theme.foreground
                            }
                        }
                    }
                    onClicked: root.advanced = !root.advanced
                }
                Repeater {
                    model: root.advanced && !root.search.length ? specification.advancedSections[root.category] || [] : []
                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        Text {
                            visible: text.length > 0; topPadding: theme.dp(30); bottomPadding: theme.dp(10)
                            text: modelData.title; color: theme.sectionTitle
                            font.pixelSize: theme.dp(16); font.weight: Font.Medium
                        }
                        Repeater {
                            model: modelData.rows
                            delegate: RedesignPreferenceRow {
                                required property var modelData
                                width: parent.width; backend: preferenceStore; optionName: modelData[0]; label: modelData[1]
                                presentation: modelData[2] || {}
                                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                            }
                        }
                    }
                }
                RowLayout {
                    visible: root.advanced && !root.search.length && root.category === "general"
                    width: parent.width; height: theme.dp(56)
                    spacing: theme.dp(10)
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Reset all settings")
                        color: theme.foreground; font.pixelSize: theme.dp(14)
                    }
                    RedesignButton {
                        id: resetAll
                        objectName: "resetAllSettings"
                        Layout.preferredWidth: theme.dp(100); Layout.preferredHeight: theme.dp(32)
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                        text: qsTr("Reset")
                        Accessible.name: qsTr("Reset all settings to their defaults")
                        background: Rectangle {
                            radius: theme.dp(6); color: resetAll.down ? theme.selected : resetAll.hovered ? theme.controlHover : theme.control
                            border.width: resetAll.visualFocus ? theme.dp(1) : 0; border.color: theme.accent
                        }
                        contentItem: Text {
                            text: resetAll.text; color: resetAll.hovered ? "#e56b6b" : theme.foreground
                            font.pixelSize: theme.dp(14); font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: preferenceStore.resetAll()
                    }
                }
                RedesignButton {
                    visible: root.advanced && !root.search.length
                    width: parent.width
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    caption: root.expert ? qsTr("Hide all VLC options") : qsTr("All VLC options")
                    text: caption; selected: root.expert
                    onClicked: root.expert = !root.expert
                }
                Repeater {
                    model: {
                        if (root.search.length) {
                            const matches = specification.find(root.search)
                            for (const entry of preferenceStore.catalog("", root.search))
                                if (!matches.some(row => row.name === entry.name)) matches.push(entry)
                            return matches
                        }
                        return root.expert ? preferenceStore.catalog(root.category, "") : []
                    }
                    delegate: RedesignPreferenceRow {
                        required property var modelData
                        width: parent.width
                        backend: preferenceStore; optionName: modelData.name; label: modelData.title || ""; presentation: modelData.presentation || {}
                        scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    }
                }
                Item { width: 1; height: theme.dp(24) }
            }
        }
        Rectangle {
            id: footer
            anchors.left: navigation.right; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: preferenceStore.errorMessage.length ? theme.dp(64) : 0
            visible: height > 0
            color: theme.background
            RowLayout {
                anchors.fill: parent; anchors.margins: theme.dp(16)
                Text {
                    Layout.fillWidth: true
                    text: preferenceStore.errorMessage
                    color: "#e56b6b"; font.pixelSize: theme.dp(13); wrapMode: Text.WordWrap
                }
                RedesignButton {
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    caption: qsTr("Retry"); text: caption; onClicked: preferenceStore.save()
                }
            }
        }
    }
}
