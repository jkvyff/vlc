// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtTest
import "../player/qml/redesign"
import "../player/qml/redesign/RedesignIcons.js" as Icons

TestCase {
    id: testCase
    name: "JuxtopposedPlayer"
    width: 1280
    height: 720
    when: windowShown
    visible: true

    RedesignPlayerView {
        id: player
        anchors.fill: parent
        started: true
        hasVideo: true
        seekable: true
        hasPrevious: true
        hasNext: true
        position: 0.25
        volume: 0.5
        timeText: "00:02:10"
        lengthText: "00:25:40"
        onTogglePlayback: playing = !playing
        onSeekRequested: value => position = value
        onVolumeRequested: value => volume = value
        onMuteRequested: muted = !muted
        libraryContent: RedesignLibraryView {
            scaleFactor: player.scaleFactor; lightTheme: player.lightTheme
            itemCount: 2
            mediaModel: ListModel {
                ListElement { title: "First video"; thumbnail: "" }
                ListElement { title: "Second video"; thumbnail: "" }
            }
        }
        tracksContent: RedesignPanelTabs {
            model: [{key: "video", label: "Video", icon: "video"}, {key: "audio", label: "Audio", icon: "audio"}, {key: "subtitles", label: "Subtitles", icon: "subtitles"}]
            current: player.tracksPage
            onActivated: key => player.tracksPage = key
        }
        queueContent: RedesignQueue {
            itemCount: 2
            queueModel: ListModel {
                ListElement { title: "First video"; isCurrent: true }
                ListElement { title: "Second video"; isCurrent: false }
            }
        }
    }
    // Side-panel building blocks, driven by stand-in models.
    ListModel {
        id: fakeTracks
        ListElement { display: "English"; checked: true }
        ListElement { display: "Japanese"; checked: false }
    }
    Item {
        id: panelParts
        x: 0; y: 0; width: 400; height: 720
        visible: false
        RedesignPanelTabs {
            id: tabs
            width: 400
            model: [{key: "video", label: "Video", icon: "video"}, {key: "audio", label: "Audio", icon: "audio"}]
            current: "video"
            onActivated: key => current = key
        }
        RedesignTracks {
            id: trackList
            y: 60; width: 340
            heading: "Embedded Tracks"; trackModel: fakeTracks; allowDisable: true
            property int lastIndex: -1
            onSelectionRequested: (index, selected) => lastIndex = index
        }
        RedesignSettingSlider {
            id: delaySlider
            y: 300; width: 360
            label: "Delay"; suffix: " s"; decimals: 3; from: -10; to: 10
            scaleLabels: [{value: -10, text: "-10 s"}, {value: 0, text: "0 s"}, {value: 10, text: "+10 s"}]
            property real lastValue: 0
            onMoved: value => { lastValue = value; currentValue = value }
        }
    }

    SignalSpy { id: seekSpy; target: player; signalName: "seekRequested" }

    function init() {
        player.libraryOpen = false
        player.libraryExpanded = false
        player.queueOpen = false
        player.settingsPage = ""
        player.tracksPage = ""
        player.playing = false
        player.muted = false
        player.fullscreen = false
        player.lightTheme = false
        player.scaleFactor = 1
        testCase.width = 1280
        testCase.height = 720
        seekSpy.clear()
        wait(20)
    }
    function test_transportAndTrackActions() {
        mouseClick(findChild(player, "playButton"))
        verify(player.playing)
        mouseClick(findChild(player, "playButton"))
        verify(!player.playing)
        mouseClick(findChild(player, "muteButton"))
        verify(player.muted)
        // Track buttons open the side panel on their tab, and close it again.
        mouseClick(findChild(player, "audioButton"))
        compare(player.tracksPage, "audio")
        verify(player.sidePanelOpen)
        mouseClick(findChild(player, "subtitleButton"))
        compare(player.tracksPage, "subtitles")
        mouseClick(findChild(player, "queueButton"))
        verify(player.queueOpen)
        compare(player.tracksPage, "")
        mouseClick(findChild(player, "queueButton"))
        verify(!player.sidePanelOpen)
    }
    function test_seekUsesPointerAndKeyboard() {
        const slider = findChild(player, "seekBar")
        mouseClick(slider, slider.width * 0.75, slider.height / 2)
        verify(seekSpy.count > 0)
        verify(player.position > 0.7 && player.position < 0.8)
        slider.forceActiveFocus()
        const before = player.position
        keyClick(Qt.Key_Right)
        verify(player.position > before)
    }
    function test_seekPreviewFollowsPointer() {
        const slider = findChild(player, "seekBar")
        const card = findChild(player, "seekPreview")
        const trail = findChild(player, "seekHoverTrail")
        let previous = -1
        // several moves in a row: the card used to freeze after the first one
        for (const fraction of [0.3, 0.5, 0.7, 0.9]) {
            mouseMove(slider, slider.width * fraction, slider.height / 2)
            tryVerify(() => card.visible)
            const centre = card.mapToItem(slider, card.width / 2, 0).x
            if (fraction < 0.9)
                fuzzyCompare(centre, slider.width * fraction, 2)
            verify(centre > previous)
            previous = centre
            verify(slider.hoverPosition > fraction - 0.05 && slider.hoverPosition < fraction + 0.05)
            compare(trail.visible, slider.hoverPosition > slider.value)
        }
    }
    function test_panelsResizeVideo() {
        const viewport = findChild(player, "redesignViewport")
        const initialWidth = viewport.width
        mouseClick(findChild(player, "libraryToggleButton"))
        verify(player.libraryOpen)
        verify(viewport.width < initialWidth)
        verify(viewport.x >= findChild(player, "redesignLibraryPanel").width)
        // Side panels float over the video instead of resizing it.
        const withLibrary = viewport.width
        mouseClick(findChild(player, "queueButton"))
        verify(player.queueOpen)
        compare(viewport.width, withLibrary)
        mouseClick(findChild(player, "playbackSettingsButton"))
        compare(player.settingsPage, "playback")
        verify(!player.queueOpen)
        player.forceActiveFocus()
        keyClick(Qt.Key_Escape)
        verify(!player.libraryOpen)
        compare(player.settingsPage, "")
    }
    function test_videoAreaStaysClearForNativeVideo() {
        // The native video layer sits behind the scene: nothing opaque may cover the viewport.
        const viewport = findChild(player, "redesignViewport")
        const frame = findChild(player, "videoFrame")
        verify(player.hasVideo)
        verify(frame.visible)
        const centre = viewport.mapToItem(player, viewport.width / 2, viewport.height / 2)
        for (let i = 0; i < frame.children.length; ++i) {
            const piece = frame.children[i]
            verify(!(centre.x >= piece.x && centre.x < piece.x + piece.width
                     && centre.y >= piece.y && centre.y < piece.y + piece.height), "frame piece " + i + " covers the video")
        }
        for (let i = 0; i < viewport.children.length; ++i) {
            const child = viewport.children[i]
            if (child instanceof Rectangle && child.visible)
                verify(child.color.a === 0, "opaque rectangle over the video")
        }
        player.hasVideo = false
        verify(!frame.visible)
        player.hasVideo = true
    }
    function test_sidePanelFloatsAndDrags() {
        const viewport = findChild(player, "redesignViewport")
        const videoWidth = viewport.width
        mouseClick(findChild(player, "queueButton"))
        const panel = findChild(player, "redesignSidePanel")
        verify(panel.visible)
        compare(viewport.width, videoWidth)
        // Opens at the design's spot: bottom right, 20 px from the video's edge (inset 10 px
        // from the window) and from the bar.
        compare(panel.x + panel.width, player.width - 30)
        compare(panel.y + panel.height, findChild(player, "redesignToolbar").y - 20)
        // Drag the shorter tracks panel, which has room to move vertically too.
        mouseClick(findChild(player, "audioButton"))
        compare(player.tracksPage, "audio")
        // Tabs are plain tabs: a click switches page even when the pointer wobbles a little,
        // and never moves the panel (the grip above them does that).
        mouseClick(findChild(panel, "panelTab_subtitles"))
        compare(player.tracksPage, "subtitles")
        const tab = findChild(panel, "panelTab_video")
        const beforeX = panel.x, beforeY = panel.y
        mousePress(tab, tab.width / 2, tab.height / 2)
        mouseMove(tab, tab.width / 2 + 6, tab.height / 2 + 3)
        mouseRelease(tab, tab.width / 2 + 6, tab.height / 2 + 3)
        compare(player.tracksPage, "video")
        compare(panel.x, beforeX); compare(panel.y, beforeY)
        mouseClick(findChild(panel, "panelTab_subtitles"))
        const handle = findChild(player, "sidePanelDragArea")
        verify(handle.mapToItem(panel, 0, handle.height).y <= tab.mapToItem(panel, 0, 0).y, "grip overlaps the tabs")
        const bottomGap = () => findChild(player, "redesignToolbar").y - (panel.y + panel.height)
        // Drag in window coordinates: mouseDrag re-maps each step through the item, and the grip
        // moves with the panel, which would overshoot.
        const drag = (dx, dy) => {
            const p = handle.mapToItem(player, handle.width / 2, handle.height / 2)
            mouseDrag(player, p.x, p.y, dx, dy)
        }
        const startX = panel.x, startY = panel.y, startHeight = panel.height
        // Dragging the grip down shrinks it (to a floor) and up grows it back, with no vertical
        // snapping; the gap above the control bar holds throughout.
        drag(0, 150)
        fuzzyCompare(panel.height, startHeight - 150, 2)
        compare(bottomGap(), 20)
        drag(0, 2000)
        compare(panel.height, 160)
        drag(0, -(startHeight - 160) + 30)
        fuzzyCompare(panel.height, startHeight - 30, 2)
        drag(0, -100)
        compare(panel.height, startHeight)
        compare(panel.y, startY)
        drag(0, -500)
        compare(panel.height, startHeight)
        compare(bottomGap(), 20)
        // Sideways it moves freely between the side gaps...
        drag(-150, 0)
        fuzzyCompare(panel.x, startX - 150, 2)
        compare(bottomGap(), 20)
        // ...is pulled onto a side when close, and never loses the gap to the video's edge.
        drag(-2000, 0)
        compare(panel.x, 30)
        // With the library open, its icon rail is the left edge: the panel moves over to keep
        // the gap from it, still covering the library's list.
        player.libraryOpen = true
        compare(panel.x, 50 + 20)
        verify(panel.x < findChild(player, "redesignLibraryPanel").width)
        player.libraryOpen = false
        compare(panel.x, 30)
        // On a side it stays there when the window resizes.
        testCase.width = 1000
        compare(panel.x, 30)
        drag(player.width - panel.width - 30 - panel.x - 30, 0)
        compare(panel.x + panel.width, player.width - 30)
        testCase.width = 1280
        compare(panel.x + panel.width, player.width - 30)
        // A window resize keeps its height and moves it to stay above the control bar...
        mouseClick(findChild(player, "queueButton"))
        const openedHeight = panel.height
        testCase.height = 900
        compare(panel.height, openedHeight)
        compare(bottomGap(), 20)
        // ...squeezing it only when the window gets too short, never flush against the header...
        testCase.height = 500
        compare(bottomGap(), 20)
        compare(panel.y, findChild(player, "redesignHeader").height + 10)
        // ...and giving that height back afterwards, but no more.
        testCase.height = 720
        compare(panel.height, openedHeight)
        compare(bottomGap(), 20)
        mouseClick(findChild(player, "subtitleButton"))
        compare(player.tracksPage, "subtitles")
        compare(viewport.width, videoWidth)
        mouseClick(findChild(player, "subtitleButton"))
        verify(!panel.visible)
        mouseClick(findChild(player, "queueButton"))
        mouseClick(findChild(player, "queueButton"))
        verify(!panel.visible)
    }
    function test_minimumWindowAndScaling() {
        testCase.width = 640
        testCase.height = 360
        wait(20)
        const seek = findChild(player, "seekBar")
        verify(seek.width >= 40)
        const queue = findChild(player, "queueButton")
        verify(queue.x + queue.width <= queue.parent.width)
        testCase.width = 1920
        testCase.height = 1080
        player.scaleFactor = 1.5
        wait(20)
        compare(findChild(player, "redesignToolbar").height, 81)
        verify(findChild(player, "redesignViewport").height > 0)
    }
    function test_lightPaletteAndExpandedLibrary() {
        player.lightTheme = true
        compare(player.theme.background.toString(), "#acacac")
        compare(player.theme.panel.toString(), "#c3c3c3")
        player.libraryOpen = true
        player.libraryExpanded = true
        wait(20)
        const viewport = findChild(player, "redesignViewport")
        verify(viewport.width > 0 && viewport.width <= 320)
        verify(viewport.height === 180)
        player.libraryOpen = false
        verify(!player.libraryExpanded)
    }
    function test_accentPresetsAndTint() {
        const theme = player.theme
        compare(theme.accentPresets.length, 9)
        compare(theme.accentPresets[0], "#d37918")
        player.lightTheme = false
        player.accentColor = "#d37918"
        compare(theme.progress.toString(), "#371f06")
        player.accentColor = "#185dd3"
        verify(Qt.colorEqual(theme.progress, theme.accentTint("#185dd3")))
        verify(theme.progress.b > theme.progress.r)
        player.accentColor = "#d37918"
    }
    function test_sidePanelPartsFollowTheDesign() {
        panelParts.visible = true
        wait(20)
        compare(tabs.height, 50)
        mouseClick(findChild(tabs, "panelTab_audio"))
        compare(tabs.current, "audio")
        // "None" plus one row per track; the checked track hides the None mark.
        verify(trackList.anySelected)
        mouseClick(trackList, 100, 40 + 44 + 22 + 44)
        compare(trackList.lastIndex, 1)
        const field = findChild(delaySlider, "settingValueField")
        compare(field.text, "0.000 s")
        field.forceActiveFocus()
        field.selectAll()
        keyClick(Qt.Key_Minus); keyClick(Qt.Key_2); keyClick(Qt.Key_Return)
        compare(delaySlider.lastValue, -2)
        panelParts.visible = false
    }
    function test_libraryToggleSwapsSidebarIcon() {
        const toggle = findChild(player, "libraryToggleButton")
        player.libraryOpen = false
        compare(toggle.iconName, "sidebar-left")
        verify(!toggle.selected)
        mouseClick(toggle)
        verify(player.libraryOpen)
        compare(toggle.iconName, "sidebar-active")
        compare(toggle.text, "Hide library")
        mouseClick(toggle)
        verify(!player.libraryOpen)
        compare(toggle.iconName, "sidebar-left")
    }
    function test_volumeWedgeAndSpeakerLevels() {
        const slider = findChild(player, "volumeSlider")
        compare(slider.width, 89)
        compare(slider.height, 28)
        const speaker = findChild(player, "muteButton")
        player.volume = 0.2
        compare(speaker.iconName, "volume-low")
        player.volume = 0.5
        compare(speaker.iconName, "volume-medium")
        player.volume = 1
        compare(speaker.iconName, "volume")
        player.muted = true
        compare(speaker.iconName, "volume-none")
        player.muted = false
        player.volume = 0.5
    }
    function test_iconNamesResolveToFigmaIcons() {
        // Every icon name the redesign QML refers to must exist in the exported set.
        const used = ["add", "album", "audio", "back", "capture-device-duo", "check", "chevron", "chevron-down", "chevron-right", "close", "cone", "disc-duo", "expand", "file-duo", "folder", "folder-duo", "forward", "fullscreen", "grid", "home", "hotkeys", "info", "info-duo", "interface", "link-duo", "lists", "maximize", "minimize", "more", "music", "next", "paint-duo", "pause", "play", "playback", "playback-settings", "playlist", "playlist-duo", "plugins", "preferences", "previous", "privacy", "queue", "recent", "record", "repeat", "search", "settings", "settings-duo", "shuffle", "sidebar", "songs", "sort", "stop", "streaming", "streaming-duo", "subtitles", "subtitles-duo", "swap-duo", "video", "videos", "volume", "volume-low", "volume-medium", "volume-none"]
        for (const name of used)
            verify(Icons.has(name), name)
        for (const name of ["preferences", "interface", "privacy", "hotkeys", "playback", "video", "audio", "subtitles", "folder", "streaming", "record", "plugins", "home", "videos", "songs", "playlist"])
            verify(Icons.has(name + "-active"), name + "-active")
        compare(Icons.activeName("network"), "streaming-active")
        compare(Icons.activeName("add"), "add")
        verify(Icons.source("play", "#8f8f8f", "#d37918", "#ab6314").startsWith("data:image/svg+xml"))
        compare(Icons.source("does-not-exist", "#8f8f8f", "#d37918", "#ab6314"), "")
    }
    function test_fullscreenUsesIndependentEdges() {
        player.fullscreen = true
        player.forceActiveFocus()
        mouseMove(player, player.width / 2, player.height / 2)
        wait(1900)
        verify(!player.topVisible)
        verify(!player.bottomVisible)
        mouseMove(player, player.width / 2, 2)
        tryCompare(player, "topVisible", true)
        verify(!player.bottomVisible)
        mouseMove(player, player.width / 2, player.height - 2)
        tryCompare(player, "bottomVisible", true)
        // Hovering a control on the revealed bar must not hide it again (it used to flicker).
        for (const name of ["playButton", "seekBar"]) {
            const control = findChild(player, name)
            const point = control.mapToItem(player, control.width / 2, control.height / 2)
            mouseMove(player, point.x, point.y)
            for (let frame = 0; frame < 10; ++frame) {
                wait(20)
                verify(player.bottomVisible, name + " hover hid the bar")
            }
        }
        wait(1900)
        verify(player.bottomVisible)
        // Overshooting past the edge (onto the Dock) leaves the window: the bar lingers, then hides.
        mouseMove(player, player.width / 2, player.height + 20)
        wait(300)
        verify(player.bottomVisible, "bar hid as soon as the pointer left the window")
        tryCompare(player, "bottomVisible", false, 3000)
    }
}
