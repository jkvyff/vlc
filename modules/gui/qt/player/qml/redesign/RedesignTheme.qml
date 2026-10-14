// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

QtObject {
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    readonly property color background: lightTheme ? "#acacac" : "#1b1b1b"
    readonly property color panel: lightTheme ? "#c3c3c3" : "#101010"
    readonly property color field: lightTheme ? "#dedede" : "#090909"
    readonly property color border: lightTheme ? "#969696" : "#292929"
    readonly property color foreground: lightTheme ? "#404040" : "#8f8f8f"
    readonly property color bright: lightTheme ? "#2e2e2e" : "#e5e5e5"
    readonly property color hover: lightTheme ? "#d5d5d5" : "#292929"
    readonly property color selected: lightTheme ? "#b8b8b8" : "#333333"
    readonly property color accent: accentColor
    readonly property color progress: accentTint(accentColor)
    // Form controls from the design's Toggle, Dropdown and Values components.
    readonly property color control: lightTheme ? "#cbcbcb" : "#191919"
    readonly property color controlHover: lightTheme ? "#d6d6d6" : "#1f1f1f"
    readonly property color controlKnob: lightTheme ? "#9a9a9a" : "#404040"
    readonly property color mutedText: lightTheme ? "#5c5c5c" : "#6b6b6b"
    // Sidebars: the library icon rail and the settings category list.
    readonly property color sidebar: lightTheme ? "#c3c3c3" : "#0e0e0e"
    readonly property color sidebarPanel: lightTheme ? "#b4b4b4" : "#191919"
    readonly property color sidebarHover: lightTheme ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.06)
    readonly property color sidebarSelected: lightTheme ? "#d5d5d5" : "#222222"
    readonly property color sidebarSelectedText: lightTheme ? "#1f1f1f" : "#eaeaea"
    // Settings window: a darker title bar over the main area, and its headings.
    readonly property color topBar: lightTheme ? "#b0b0b0" : "#090909"
    readonly property color topBarText: lightTheme ? "#3a3a3a" : "#969696"
    readonly property color sectionTitle: lightTheme ? "#2e2e2e" : "#c6c6c6"
    readonly property color searchField: lightTheme ? "#c8c8c8" : "#151515"
    // Side panels: list rows and the separator between their sections.
    readonly property color rowText: lightTheme ? "#3a3a3a" : "#969696"
    readonly property color separator: lightTheme ? "#a8a8a8" : "#1b1b1b"
    readonly property color accentKnob: Qt.rgba(accentColor.r * 0.81, accentColor.g * 0.81, accentColor.b * 0.81, 1)
    // The design's swatches and accent presets, in display order.
    readonly property var accentPresets: ["#d37918", "#e15032", "#c49e23", "#19a234", "#18aad3", "#185dd3", "#8e42ff", "#f052b3", "#afafaf"]

    function dp(value: real): real { return value * scaleFactor }
    // Muted accent used for progress fills and selected swatches; #d37918 gives the design's #371f06.
    function accentTint(color: color): color {
        return lightTheme ? Qt.tint("#dedede", Qt.rgba(color.r, color.g, color.b, 0.4))
                          : Qt.tint("#000000", Qt.rgba(color.r, color.g, color.b, 0.26))
    }
}
