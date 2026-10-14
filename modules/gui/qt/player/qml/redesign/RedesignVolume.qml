// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Controls.Basic as C

// The design's volume wedge: a rounded trapezoid that widens to the right,
// filled with a green-to-red gradient up to the current volume.
T.Slider {
    id: root
    property real scaleFactor: 1
    property color accentColor: "#d37918"
    property bool lightTheme: false
    property bool muted: false
    readonly property RedesignTheme theme: RedesignTheme { scaleFactor: root.scaleFactor; lightTheme: root.lightTheme; accentColor: root.accentColor }
    // Proportions measured from the design's volume component (89 x 26, 10 px at the narrow end).
    readonly property real narrowRatio: 10 / 26
    implicitWidth: theme.dp(89)
    implicitHeight: theme.dp(28)
    from: 0
    to: 1.25
    stepSize: 0.05
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.name: qsTr("Volume")
    padding: 0
    handle: Item { width: 0; height: 0 }
    background: Item {
        Canvas {
            id: wedge
            // Paint at device resolution so the edges stay sharp on HiDPI screens.
            readonly property real ratio: Screen.devicePixelRatio || 1
            width: parent.width * ratio; height: parent.height * ratio
            scale: 1 / ratio; transformOrigin: Item.TopLeft
            opacity: root.muted ? 0.35 : 1
            function trace(ctx, inset) {
                const w = width, h = height, d = inset * ratio
                const narrow = h * root.narrowRatio
                const left = d, right = w - d
                const top = (h - narrow) / 2 + d, bottom = (h + narrow) / 2 - d
                const r = Math.min(3 * root.scaleFactor * ratio, (bottom - top) / 2)
                ctx.beginPath()
                ctx.moveTo(left, h / 2)
                ctx.arcTo(left, top, right, d, r)
                ctx.arcTo(right, d, right, h - d, r)
                ctx.arcTo(right, h - d, left, bottom, r)
                ctx.arcTo(left, bottom, left, top, r)
                ctx.closePath()
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                trace(ctx, 0)
                ctx.fillStyle = root.lightTheme ? "#dedede" : "#090909"
                ctx.fill()
                const level = root.visualPosition * width
                if (level <= 0) return
                ctx.save()
                trace(ctx, 1 * root.scaleFactor)
                ctx.clip()
                // Sampled along the design's full-volume state.
                const gradient = ctx.createLinearGradient(0, 0, width, 0)
                gradient.addColorStop(0, "#79a713")
                gradient.addColorStop(0.5, "#8c8c14")
                gradient.addColorStop(0.64, "#9f7114")
                gradient.addColorStop(0.85, "#b84b1e")
                gradient.addColorStop(1, "#c7332a")
                ctx.fillStyle = gradient
                ctx.fillRect(0, 0, level, height)
                ctx.restore()
            }
            Connections {
                target: root
                function onVisualPositionChanged() { wedge.requestPaint() }
                function onLightThemeChanged() { wedge.requestPaint() }
                function onScaleFactorChanged() { wedge.requestPaint() }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -theme.dp(2)
            color: "transparent"
            radius: theme.dp(4)
            border.width: root.visualFocus ? theme.dp(1) : 0
            border.color: theme.accent
        }
    }
    C.ToolTip.visible: root.hovered || root.visualFocus || root.pressed
    C.ToolTip.text: qsTr("%1%").arg(Math.round(value * 100))
}
