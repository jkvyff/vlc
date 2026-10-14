// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts

// Presentation shared by the VLC integration and the standalone QML checks.
FocusScope {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property bool playing: false
    property bool started: false
    property bool hasVideo: false
    property bool seekable: false
    property bool pausable: true
    property bool hasPrevious: false
    property bool hasNext: false
    property bool muted: false
    property bool fullscreen: false
    property int autoHideMode: 1
    property int controlsHideTimeout: 1800
    property bool showFullscreenControls: true
    readonly property bool autoHideActive: started && (autoHideMode === 2 || (fullscreen && autoHideMode === 1))
    property bool maximized: false
    property bool showWindowButtons: true
    property bool libraryOpen: false
    property bool libraryExpanded: false
    onLibraryOpenChanged: if (!libraryOpen) libraryExpanded = false
    property bool queueOpen: false
    property string settingsPage: ""
    property string tracksPage: ""
    // One side panel at a time: queue, playback settings or tracks.
    readonly property bool sidePanelOpen: queueOpen || settingsPage.length > 0 || tracksPage.length > 0
    property real position: 0
    property real volume: 1
    property real maxVolume: 1.25
    property real buffering: 1
    property string mediaTitle: qsTr("VLC Media Player")
    property string locationTitle: qsTr("Videos")
    property string timeText: "00:00:00"
    property string lengthText: "00:00:00"
    property string artist: ""
    property url artwork
    property bool resumeAvailable: false
    property var timeForPosition: function(position) { return "" }
    property var previewForPosition: function(position) { return "" }
    property Component titleBarDragContent
    property Component videoContent
    property Component libraryContent
    property Component queueContent
    property Component settingsContent
    property Component tracksContent
    readonly property alias videoItem: videoLoader.item
    readonly property alias libraryItem: libraryLoader.item
    readonly property alias settingsItem: settingsLoader.item
    readonly property real positionSliderY: toolbar.y + seek.y
    readonly property bool controlsLocked: sidePanelOpen || libraryOpen || resumeAvailable
    readonly property bool topVisible: !fullscreen || headerEdge.hovered || headerHover.hovered || header.activeFocus || revealTimer.running || controlsLocked
    readonly property bool bottomVisible: (!fullscreen || showFullscreenControls) && (!autoHideActive || bottomHover.hovered || toolbarHover.hovered || toolbar.activeFocus || revealTimer.running || controlsLocked)
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }

    signal togglePlayback()
    signal previous()
    signal next()
    signal seekRequested(real value)
    signal volumeRequested(real value)
    signal muteRequested()
    signal fullscreenRequested()
    signal minimizeRequested()
    signal maximizeRequested()
    signal closeRequested()
    signal menuRequested(Item anchor)
    signal openRequested()
    signal preferencesRequested()
    signal fullLibraryRequested()
    signal resumeRequested(bool resume)
    signal keyPressed(var event)

    function revealControls() { revealTimer.restart() }
    // Overshooting an edge hands the pointer to the macOS Dock or menu bar and the window
    // loses hover outright; keep the bars up for the usual delay instead of hiding at once.
    function keepControlsAfterHover(hovered: bool) { if (!hovered && fullscreen) revealControls() }
    function toggleSettings(page: string) {
        queueOpen = false
        tracksPage = ""
        settingsPage = settingsPage === page ? "" : page
    }
    function toggleTracks(page: string) {
        queueOpen = false
        settingsPage = ""
        tracksPage = tracksPage === page ? "" : page
    }
    function dismissPanels() {
        settingsPage = ""
        tracksPage = ""
        queueOpen = false
        libraryOpen = false
    }

    Keys.onEscapePressed: event => {
        if (sidePanelOpen || libraryOpen)
            dismissPanels()
        else if (fullscreen)
            fullscreenRequested()
        else
            event.accepted = false
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
            revealControls()
        keyPressed(event)
    }
    Timer { id: revealTimer; interval: root.controlsHideTimeout; running: root.fullscreen }
    onFullscreenChanged: revealControls()
    // On macOS (and Windows' platform compositor) the video is a native layer *behind*
    // this transparent scene, so while video plays the chrome is painted around the
    // viewport, never over it. Without video the whole window gets the background.
    Rectangle { anchors.fill: parent; color: theme.background; visible: !root.hasVideo }
    Item {
        objectName: "videoFrame"
        anchors.fill: parent
        visible: root.hasVideo
        Rectangle { x: 0; y: 0; width: parent.width; height: viewport.y; color: theme.background }
        Rectangle { x: 0; y: viewport.y + viewport.height; width: parent.width; height: parent.height - y; color: theme.background }
        Rectangle { x: 0; y: viewport.y; width: viewport.x; height: viewport.height; color: theme.background }
        Rectangle { x: viewport.x + viewport.width; y: viewport.y; width: parent.width - x; height: viewport.height; color: theme.background }
    }

    // The library resizes the video surface; side panels float over it.
    Item {
        id: viewport
        objectName: "redesignViewport"
        z: root.libraryExpanded ? 1 : 0
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: root.libraryExpanded ? root.height - theme.dp(54 + 180 + 24) : root.fullscreen ? 0 : theme.dp(40)
            bottomMargin: root.libraryExpanded ? theme.dp(54 + 24) : root.fullscreen ? 0 : theme.dp(54)
            leftMargin: root.libraryExpanded ? Math.max(theme.dp(50), root.width - theme.dp(344)) : root.libraryOpen ? library.width : root.fullscreen ? 0 : theme.dp(10)
            rightMargin: root.libraryExpanded ? theme.dp(24) : root.fullscreen ? 0 : theme.dp(10)
        }
        // Behind artwork and the empty state only; with video this spot must stay clear.
        Rectangle { anchors.fill: parent; color: "black"; radius: theme.dp(10); visible: !root.hasVideo }
        Loader { id: videoLoader; anchors.fill: parent; sourceComponent: root.videoContent }
        Rectangle {
            // The outer border leaves a rounded opening over the native video layer.
            anchors.fill: parent
            anchors.margins: -theme.dp(10)
            color: "transparent"
            radius: theme.dp(20)
            border.width: theme.dp(10)
            border.color: theme.background
            visible: !root.fullscreen
        }


        // An honest empty state; the supplied cat is reference footage only.
        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - theme.dp(40), theme.dp(420))
            spacing: theme.dp(18)
            visible: !root.started && !root.hasVideo
            RedesignIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: theme.dp(48); height: width
                name: "cone"; color: theme.accent; accentColor: theme.accent
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Drop a file to start playing")
                color: "#cccccc"
                font.pixelSize: theme.dp(18)
            }
            RedesignButton {
                objectName: "openFileButton"
                anchors.horizontalCenter: parent.horizontalCenter
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "folder"; text: qsTr("Open file"); caption: text
                accent: true
                onClicked: root.openRequested()
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: theme.dp(14)
            visible: root.started && !root.hasVideo
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: root.artwork
                width: Math.min(viewport.width * 0.45, theme.dp(320))
                height: width
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            RedesignIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: theme.dp(96); height: width
                name: "music"; color: theme.accent
                visible: !root.artwork.toString()
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(0, viewport.width - theme.dp(40))
                text: root.mediaTitle
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "#e5e5e5"
                font.pixelSize: theme.dp(22)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.artist; color: "#8f8f8f"; font.pixelSize: theme.dp(14)
            }
        }
        Text {
            anchors.centerIn: parent
            visible: root.started && root.buffering < 1
            text: qsTr("Buffering %1%").arg(Math.round(root.buffering * 100))
            color: "white"
            style: Text.Outline; styleColor: "black"
            font.pixelSize: theme.dp(16)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: theme.dp(24)
            width: Math.max(0, Math.min(parent.width - theme.dp(24), theme.dp(540)))
            height: theme.dp(width < theme.dp(420) ? 80 : 64)
            visible: root.resumeAvailable
            color: theme.panel; radius: theme.dp(8); border.color: theme.border
            RowLayout {
                id: resumeRow
                anchors.fill: parent; anchors.margins: theme.dp(12)
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Continue where you left off?")
                    color: theme.bright; font.pixelSize: theme.dp(14)
                    wrapMode: Text.WordWrap
                }
                RedesignButton {
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    caption: qsTr("Continue"); text: caption; accent: true
                    onClicked: root.resumeRequested(true)
                }
                RedesignButton {
                    scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                    iconName: "close"; text: qsTr("Start from the beginning")
                    onClicked: root.resumeRequested(false)
                }
            }
        }
    }

    Rectangle {
        id: library
        objectName: "redesignLibraryPanel"
        visible: root.libraryOpen
        width: root.libraryExpanded ? root.width : Math.min(theme.dp(427), root.width * (root.width < theme.dp(900) ? 0.48 : 0.38))
        anchors.top: header.bottom; anchors.bottom: toolbar.top; anchors.left: parent.left
        color: theme.sidebar
        Loader { id: libraryLoader; anchors.fill: parent; sourceComponent: root.libraryContent; active: root.libraryOpen }
    }
    // Side panels float over the video and can be dragged by their tab strip,
    // so opening tracks, settings or the queue never moves or shrinks playback.
    Item {
        id: rightPanel
        objectName: "redesignSidePanel"
        z: 2
        visible: root.sidePanelOpen
        readonly property real topLimit: header.visible ? header.height : 0
        readonly property real bottomLimit: toolbar.visible ? toolbar.y : root.height
        // Buffer the design leaves between the panel, the window edge and the control bar.
        readonly property real gap: theme.dp(20)
        // Within this distance of a side, a drag is pulled onto it.
        readonly property real magnet: theme.dp(48)
        // Side gaps match the bottom one as seen against the video, which is itself inset
        // from the window edges outside fullscreen.
        readonly property real sideInset: root.fullscreen ? 0 : theme.dp(10)
        // With the library open its thin icon rail is the left edge instead (the panel may
        // still float over the library's list beyond it).
        readonly property real leftX: (root.libraryOpen ? theme.dp(50) : sideInset) + gap
        readonly property real rightX: root.width - width - sideInset - gap
        // "right" or "left" while pulled onto a side (it then stays there through resizes),
        // "" while placed freely at freeX. It opens on the right, as the design places it.
        property string dock: "right"
        property real freeX: 0
        width: Math.min(theme.dp(400), root.width - 2 * (sideInset + gap))
        readonly property real contentHeight: root.tracksPage.length > 0 ? theme.dp(524) : theme.dp(946)
        // Never flush against the header: a smaller gap than the others, so tall panels keep
        // most of the height.
        readonly property real topGap: theme.dp(10)
        // Room between the gap below the header and the gap above the control bar.
        readonly property real room: bottomLimit - topLimit - topGap - gap
        // Sized when it opens (or switches between the tracks and the taller panels); a window
        // resize then just moves it to stay attached above the control bar, only squeezing it
        // while the window is too short, and giving the height back once there is room again.
        property real openHeight: contentHeight
        function fitHeight() { openHeight = Math.min(contentHeight, room) }
        onVisibleChanged: if (visible) fitHeight()
        onContentHeightChanged: fitHeight()
        height: Math.max(minHeight, Math.min(openHeight, room))
        y: bottomLimit - gap - height
        x: dock === "right" ? rightX : dock === "left" ? leftX : Math.max(leftX, Math.min(rightX, freeX))
        readonly property real minHeight: theme.dp(160)
        function dragTo(dx: real, dy: real) {
            const newX = panelDrag.startX + dx
            if (newX - leftX < magnet) dock = "left"
            else if (rightX - newX < magnet) dock = "right"
            else { freeX = newX; dock = "" }
            // The grip is the panel's top edge: up grows it, down shrinks it, the bottom stays
            // attached. Only the sides snap; the height follows the pointer freely.
            openHeight = Math.max(minHeight, Math.min(Math.min(contentHeight, room), panelDrag.startHeight - dy))
        }
        Repeater {
            // Soft shadow so the panel reads as floating above the picture.
            model: 4
            Rectangle {
                required property int index
                anchors.fill: parent
                anchors.margins: -theme.dp(index + 1); anchors.topMargin: -theme.dp(index + 1) + theme.dp(4)
                radius: theme.dp(8 + index + 1); color: "#000000"; opacity: 0.08
            }
        }
        Rectangle { anchors.fill: parent; radius: theme.dp(8); color: theme.sidebar }
        // Behind the grip and the panels' rounded tab-strip corners, so they read as one header.
        Rectangle { width: parent.width; height: dragArea.height + theme.dp(16); radius: theme.dp(8); color: theme.topBar }
        Item {
            id: dragArea
            objectName: "sidePanelDragArea"
            // A grip above the tabs moves the panel; the tabs stay plain tabs, so a click with
            // a little pointer movement can never turn into a drag (or a drag into a click).
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: theme.dp(22)
            property bool moved: false
            Grid {
                // two rows of dots, the usual "grab here" texture
                objectName: "sidePanelGripDots"
                anchors.centerIn: parent
                rows: 2; columns: 8
                rowSpacing: theme.dp(3); columnSpacing: theme.dp(3)
                Repeater {
                    model: 16
                    Rectangle {
                        width: theme.dp(3); height: width; radius: width / 2
                        color: gripHover.hovered || panelDrag.active ? theme.foreground : theme.controlKnob
                    }
                }
            }
            DragHandler {
                id: panelDrag
                // Moved by hand (dragTo) rather than as a target, for the gaps and the side magnets.
                target: null
                property real startX: 0
                property real startHeight: 0
                onActiveChanged: if (active) {
                    dragArea.moved = true
                    startX = rightPanel.x
                    startHeight = rightPanel.height
                }
                onTranslationChanged: if (active) rightPanel.dragTo(translation.x, translation.y)
            }
            HoverHandler { id: gripHover; cursorShape: panelDrag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor }
        }
        Loader {
            anchors.fill: parent; anchors.topMargin: dragArea.height
            sourceComponent: root.queueContent
            active: root.queueOpen
            visible: active
        }
        Loader {
            id: settingsLoader
            anchors.fill: parent; anchors.topMargin: dragArea.height
            sourceComponent: root.settingsContent
            active: root.settingsPage.length > 0
            visible: active
        }
        Loader {
            id: tracksLoader
            anchors.fill: parent; anchors.topMargin: dragArea.height
            sourceComponent: root.tracksContent
            active: root.tracksPage.length > 0
            visible: active
        }
    }

    // Fullscreen edges reveal independently; motion in the video stays unobtrusive.
    // Hovered controls stop hover reaching these strips below the bars, so the
    // bars also keep themselves up (headerHover, toolbarHover) or they flicker.
    Item {
        anchors.top: parent.top; width: parent.width; height: theme.dp(48)
        HoverHandler { id: headerEdge; onHoveredChanged: root.keepControlsAfterHover(hovered) }
    }
    Item {
        anchors.bottom: parent.bottom; width: parent.width; height: theme.dp(64)
        HoverHandler { id: bottomHover; onHoveredChanged: root.keepControlsAfterHover(hovered) }
    }

    Rectangle {
        id: header
        objectName: "redesignHeader"
        anchors.top: parent.top; width: parent.width; height: theme.dp(40)
        color: theme.background
        visible: root.topVisible
        HoverHandler { id: headerHover; onHoveredChanged: root.keepControlsAfterHover(hovered) }
        Loader { anchors.fill: parent; sourceComponent: root.titleBarDragContent }
        RowLayout {
            id: headerLeft
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            RedesignButton {
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                implicitWidth: theme.dp(50)
                iconName: "cone"; text: qsTr("Open file"); foreground: theme.accent
                onClicked: root.openRequested()
            }
            RedesignButton {
                implicitWidth: theme.dp(30)
                objectName: "mainMenuButton"
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "more"; text: qsTr("Menu")
                onClicked: root.menuRequested(this)
            }
            RedesignButton {
                implicitWidth: theme.dp(46)
                objectName: "libraryToggleButton"
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                // The design swaps to the filled panel glyph, still grey, while the library is open.
                iconName: root.libraryOpen ? "sidebar-active" : "sidebar-left"
                text: root.libraryOpen ? qsTr("Hide library") : qsTr("Show library")
                Accessible.checkable: true; Accessible.checked: root.libraryOpen
                onClicked: root.libraryOpen = !root.libraryOpen
            }
            Rectangle { Layout.leftMargin: theme.dp(2); Layout.rightMargin: theme.dp(6); width: theme.dp(1); height: theme.dp(18); color: theme.border }
            RedesignButton {
                visible: root.width > theme.dp(700)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "folder"; caption: root.locationTitle; text: qsTr("Browse library")
                onClicked: root.libraryOpen = !root.libraryOpen
            }
        }
        Text {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - Math.max(headerLeft.width, windowControls.width) * 2 - theme.dp(32))
            horizontalAlignment: Text.AlignHCenter
            text: root.mediaTitle
            font.pixelSize: theme.dp(14)
            elide: Text.ElideRight; color: theme.foreground
        }
        Row {
            id: windowControls
            anchors.right: parent.right; anchors.rightMargin: theme.dp(6)
            anchors.verticalCenter: parent.verticalCenter
            RedesignButton {
                visible: root.showWindowButtons
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "minimize"; text: qsTr("Minimize")
                onClicked: root.minimizeRequested()
            }
            RedesignButton {
                visible: root.showWindowButtons
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "maximize"; text: root.maximized ? qsTr("Restore window") : qsTr("Maximize")
                onClicked: root.maximizeRequested()
            }
            RedesignButton {
                objectName: "fullscreenButton"
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "fullscreen"; text: root.fullscreen ? qsTr("Exit fullscreen") : qsTr("Fullscreen")
                onClicked: root.fullscreenRequested()
            }
            RedesignButton {
                visible: root.showWindowButtons
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "close"; text: qsTr("Close")
                onClicked: root.closeRequested()
            }
        }
    }

    Rectangle {
        id: toolbar
        objectName: "redesignToolbar"
        anchors.bottom: parent.bottom; width: parent.width; height: theme.dp(54)
        color: theme.background
        visible: root.bottomVisible
        HoverHandler { id: toolbarHover; onHoveredChanged: root.keepControlsAfterHover(hovered) }
        // Gaps measured from the design's player bar.
        TextMetrics { id: clockMetrics; font.pixelSize: theme.dp(14); text: "00:00:00" }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: theme.dp(20); anchors.rightMargin: theme.dp(20)
            spacing: 0
            RedesignButton {
                objectName: "previousButton"
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(28)
                iconName: "previous"; text: qsTr("Previous"); enabled: root.hasPrevious
                onClicked: root.previous()
            }
            RedesignButton {
                objectName: "playButton"
                Layout.leftMargin: theme.dp(8)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                implicitWidth: theme.dp(54); implicitHeight: theme.dp(28)
                iconName: root.playing ? "pause" : "play"
                text: root.playing ? qsTr("Pause") : qsTr("Play")
                accent: true; enabled: !root.started || root.pausable
                onClicked: root.togglePlayback()
            }
            RedesignButton {
                objectName: "nextButton"
                Layout.leftMargin: theme.dp(8)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(28)
                iconName: "next"; text: qsTr("Next"); enabled: root.hasNext
                onClicked: root.next()
            }
            Text {
                visible: root.width > theme.dp(650)
                Layout.leftMargin: theme.dp(27)
                Layout.preferredWidth: Math.ceil(clockMetrics.advanceWidth)
                horizontalAlignment: Text.AlignHCenter
                text: root.timeText
                color: theme.foreground; font.pixelSize: theme.dp(14)
            }
            RedesignSeekBar {
                id: seek
                objectName: "seekBar"
                Layout.leftMargin: theme.dp(16)
                Layout.fillWidth: true
                Layout.minimumWidth: theme.dp(40)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                enabled: root.seekable
                timeForPosition: root.timeForPosition
                previewForPosition: root.previewForPosition
                // float above the control bar with the side panels' gap (seek.y is its inset)
                previewLift: seek.y + rightPanel.gap
                Binding on value { when: !seek.pressed; value: root.position; restoreMode: Binding.RestoreBindingOrValue }
                onMoved: root.seekRequested(value)
            }
            Text {
                visible: root.width > theme.dp(800)
                Layout.leftMargin: theme.dp(14)
                Layout.preferredWidth: Math.ceil(clockMetrics.advanceWidth)
                horizontalAlignment: Text.AlignHCenter
                text: root.lengthText
                color: theme.foreground; font.pixelSize: theme.dp(14)
            }
            RedesignButton {
                objectName: "muteButton"
                Layout.leftMargin: theme.dp(24)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(32)
                // The design's speaker glyph shows one, two or three bars for the level.
                iconName: root.muted || root.volume <= 0 ? "volume-none"
                    : root.volume < 0.34 ? "volume-low" : root.volume < 0.67 ? "volume-medium" : "volume"
                text: root.muted ? qsTr("Unmute") : qsTr("Mute")
                onClicked: root.muteRequested()
            }
            RedesignVolume {
                id: volumeSlider
                objectName: "volumeSlider"
                Layout.leftMargin: theme.dp(4)
                visible: root.width > theme.dp(750)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                muted: root.muted; to: root.maxVolume
                Binding on value { when: !volumeSlider.pressed; value: root.volume; restoreMode: Binding.RestoreBindingOrValue }
                onMoved: root.volumeRequested(value)
            }
            RedesignButton {
                objectName: "audioButton"
                Layout.leftMargin: theme.dp(20)
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(32)
                visible: root.width > theme.dp(900)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "audio"; text: qsTr("Audio tracks and output")
                selected: root.tracksPage === "audio"
                onClicked: root.toggleTracks("audio")
            }
            RedesignButton {
                objectName: "subtitleButton"
                Layout.leftMargin: theme.dp(12)
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "subtitles"; text: qsTr("Subtitle tracks")
                selected: root.tracksPage === "subtitles"
                onClicked: root.toggleTracks("subtitles")
            }
            RedesignButton {
                objectName: "playbackSettingsButton"
                Layout.leftMargin: theme.dp(12)
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "playback-settings"; text: qsTr("Playback settings")
                selected: root.settingsPage.length > 0
                onClicked: root.toggleSettings("playback")
            }
            RedesignButton {
                objectName: "queueButton"
                Layout.leftMargin: theme.dp(20)
                implicitWidth: theme.dp(30); implicitHeight: theme.dp(32)
                scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor
                iconName: "lists"; text: qsTr("Play queue"); selected: root.queueOpen
                onClicked: { root.settingsPage = ""; root.tracksPage = ""; root.queueOpen = !root.queueOpen }
            }
        }
    }
}
