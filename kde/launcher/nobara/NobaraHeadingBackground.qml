/*
    Replacement band for Kickoff's header/footer PlasmoidHeading.

    The theme's widgets/plasmoidheading.svg draws the band out to the popup
    edge with ~3px outer corners, which hides the popup frame's rounder corner
    and makes the launcher look sharp. This draws the same band (75% background
    fill + 15% hairline on the inner edge) with outer corners that follow the
    frame radius. The SVG background is kept (transparent) so PlasmoidHeading's
    inset/padding logic, and therefore the layout, is unchanged.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: band

    // The PlasmoidHeading this band belongs to
    required property Item heading
    property bool footer: false

    parent: heading
    z: -1
    x: heading.background ? heading.background.x : 0
    y: heading.background ? heading.background.y : 0
    width: heading.background ? heading.background.width : 0
    height: heading.background ? heading.background.height : 0

    // Only round a corner where the popup frame itself has that corner
    readonly property int allEdges: Qt.LeftEdge | Qt.TopEdge | Qt.RightEdge | Qt.BottomEdge
    readonly property int windowBorders: (Window.window && Window.window.borders !== undefined)
        ? Window.window.borders : allEdges
    readonly property int headingBorders: heading.enabledBorders !== undefined ? heading.enabledBorders : allEdges
    readonly property bool outerEdge: (windowBorders & (footer ? Qt.BottomEdge : Qt.TopEdge)) !== 0
    readonly property real leftRadius: outerEdge && (windowBorders & Qt.LeftEdge) && (headingBorders & Qt.LeftEdge)
        ? NobaraStyle.frameRadius : 0
    readonly property real rightRadius: outerEdge && (windowBorders & Qt.RightEdge) && (headingBorders & Qt.RightEdge)
        ? NobaraStyle.frameRadius : 0

    Rectangle {
        anchors.fill: parent
        // The SVG was tinted by the Plasma theme's ColorScheme-Background
        // (Nobara-Enhanced colors: 0,0,0); Kirigami.Theme here follows the app
        // color scheme instead (#111111), which looked lighter, so pin it.
        color: "#000000"
        opacity: 0.75
        antialiasing: true
        topLeftRadius: band.footer ? 0 : band.leftRadius
        topRightRadius: band.footer ? 0 : band.rightRadius
        bottomLeftRadius: band.footer ? band.leftRadius : 0
        bottomRightRadius: band.footer ? band.rightRadius : 0
    }

    // Hairline on the inner edge (bottom of the header, top of the footer)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        y: band.footer ? 0 : parent.height - height
        height: 1
        color: Kirigami.Theme.textColor
        opacity: 0.15
    }
}
