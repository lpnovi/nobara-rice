/*
    PC3.ToolButton with a QML-drawn rounded background.

    The stock background is the widgets/button SVG, whose hover/pressed/focus
    frames are tinted by the Plasma theme's own (Breeze blue) colors; KSvg does
    not honour Kirigami.Theme overrides, so the frame is drawn here instead.
    Padding matches the theme's toolbutton margins (4px), so sizes are unchanged.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

PC3.ToolButton {
    id: control

    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing
    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing

    background: Rectangle {
        readonly property bool engaged: control.down || control.checked
        radius: NobaraStyle.radius
        antialiasing: true
        opacity: control.enabled ? 1 : 0.5
        color: engaged ? NobaraStyle.selectedFill
            : control.hovered ? NobaraStyle.hoverFill : "transparent"
        border.width: 1
        border.color: control.visualFocus ? NobaraStyle.accentFocus
            : engaged ? NobaraStyle.selectedBorder
            : control.hovered ? NobaraStyle.inactiveBorder : "transparent"

        Behavior on color {
            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
    }
}
