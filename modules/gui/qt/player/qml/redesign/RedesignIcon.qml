// SPDX-License-Identifier: GPL-2.0-or-later
// Draws one of the design's icons from RedesignIcons.js.
import QtQuick
import "RedesignIcons.js" as Icons

// An Item rather than an Image: an Image's implicit size follows its sourceSize, which
// here follows its size, and inside layouts that loop overflowed the stack. The fixed
// natural size is the design's 24 x 24 grid.
Item {
    id: root
    property string name
    property color color: "#8f8f8f"
    property color accentColor: "#d37918"
    property color secondaryColor: Qt.rgba(accentColor.r * 0.81, accentColor.g * 0.81, accentColor.b * 0.81, 1)
    implicitWidth: 24
    implicitHeight: 24
    Accessible.ignored: true
    Image {
        anchors.fill: parent
        sourceSize: Qt.size(Math.max(1, root.width) * Screen.devicePixelRatio, Math.max(1, root.height) * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectFit
        source: Icons.source(root.name, root.color.toString(), root.accentColor.toString(), root.secondaryColor.toString())
    }
}
