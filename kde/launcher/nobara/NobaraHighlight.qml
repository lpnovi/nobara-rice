/*
    Rounded purple replacement for PlasmaExtras.Highlight.

    PlasmaExtras.Highlight draws widgets/viewitem, whose hover/focus colors come
    from the Plasma theme's ButtonFocus/ViewHover entries (Breeze blue) and
    cannot be overridden through Kirigami.Theme, so this is drawn in QML.

    Same API subset as PlasmaExtras.Highlight: hovered, pressed, active.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

Item {
    id: highlight

    // true: the "current"/selected item; false: plain hover feedback
    property bool hovered: true
    property bool pressed: false
    // false: selected item whose view does not have focus
    property bool active: true
    property real inset: 1
    // sidebar categories use the slightly stronger sidebar* palette
    property bool sidebar: false

    Rectangle {
        anchors.fill: parent
        anchors.margins: highlight.inset
        radius: NobaraStyle.radius
        antialiasing: true

        color: {
            if (highlight.pressed) {
                return NobaraStyle.pressedFill;
            }
            if (!highlight.hovered) {
                return NobaraStyle.hoverFill;
            }
            if (highlight.sidebar) {
                return highlight.active ? NobaraStyle.sidebarSelectedFill : NobaraStyle.sidebarInactiveFill;
            }
            return highlight.active ? NobaraStyle.selectedFill : NobaraStyle.inactiveFill;
        }
        border.width: 1
        border.color: {
            if (!highlight.hovered && !highlight.pressed) {
                return "transparent";
            }
            if (highlight.sidebar) {
                return highlight.active ? NobaraStyle.sidebarSelectedBorder : NobaraStyle.sidebarInactiveBorder;
            }
            return highlight.active ? NobaraStyle.selectedBorder : NobaraStyle.inactiveBorder;
        }

        Behavior on color {
            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
    }
}
