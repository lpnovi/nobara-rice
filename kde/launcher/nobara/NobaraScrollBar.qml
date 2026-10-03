/*
    Slim rounded scrollbar for the Kickoff fork.

    The stock PC3.ScrollBar draws widgets/scrollbar, whose hover state uses the
    Plasma theme's Breeze-blue highlight (KSvg ignores Kirigami.Theme
    overrides). Metrics match the stock one under this theme (6px handle,
    6px padding, 18px total) so the views' width math is unchanged.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Templates as T

T.ScrollBar {
    id: control

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    hoverEnabled: interactive
    visible: policy === T.ScrollBar.AlwaysOn || (policy === T.ScrollBar.AsNeeded && size > 0 && size < 1)
    minimumSize: horizontal ? height / width : width / height
    padding: 6

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: Math.min(width, height) / 2
        antialiasing: true
        color: control.pressed ? NobaraStyle.accentFocus
            : control.hovered ? NobaraStyle.accentHover
            : Qt.rgba(1, 1, 1, 0.22)

        Behavior on color {
            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
    }

    background: Rectangle {
        color: Qt.rgba(1, 1, 1, 0.04)
        radius: NobaraStyle.radius
        opacity: control.hovered && control.interactive ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
    }
}
