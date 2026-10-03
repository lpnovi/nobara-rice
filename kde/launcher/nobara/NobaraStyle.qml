/*
    Nobara Enhanced Purple palette for the local Kickoff fork.
    Keep in sync with ~/.local/share/color-schemes/NobaraEnhancedPurple.colors
    and the palette in ~/.local/share/nobara-enhanced-apptheme/gen_kvantum.py.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma Singleton

import QtQuick

QtObject {
    // Base palette
    readonly property color accent: "#6c54aa"
    readonly property color accentHover: "#7a63c0"
    readonly property color accentFocus: "#8c73d2"
    readonly property color lavender: "#b4a2f0"
    readonly property color text: "#dedde6"
    readonly property color highlightedText: "#ffffff"
    readonly property color disabledText: "#6f6c80"

    // Item highlight states (drawn over the near-black popup background)
    readonly property color selectedFill: Qt.rgba(108 / 255, 84 / 255, 170 / 255, 0.34)
    readonly property color selectedBorder: Qt.rgba(140 / 255, 115 / 255, 210 / 255, 0.55)
    readonly property color inactiveFill: Qt.rgba(108 / 255, 84 / 255, 170 / 255, 0.17)
    readonly property color inactiveBorder: Qt.rgba(140 / 255, 115 / 255, 210 / 255, 0.24)
    // Sidebar category highlight: ~20% stronger than the app selection so the
    // current category stays obvious while browsing apps
    readonly property color sidebarSelectedFill: Qt.rgba(108 / 255, 84 / 255, 170 / 255, 0.41)
    readonly property color sidebarSelectedBorder: Qt.rgba(140 / 255, 115 / 255, 210 / 255, 0.66)
    readonly property color sidebarInactiveFill: Qt.rgba(108 / 255, 84 / 255, 170 / 255, 0.21)
    readonly property color sidebarInactiveBorder: Qt.rgba(140 / 255, 115 / 255, 210 / 255, 0.29)
    readonly property color hoverFill: Qt.rgba(150 / 255, 139 / 255, 225 / 255, 0.10)
    readonly property color pressedFill: Qt.rgba(108 / 255, 84 / 255, 170 / 255, 0.52)

    // Search field
    readonly property color fieldFill: "#15141b"
    readonly property color fieldBorder: "#2a2836"
    readonly property color fieldBorderHover: "#3d3456"

    // Separators
    readonly property color separator: Qt.rgba(1, 1, 1, 0.07)

    // Geometry and motion
    readonly property real radius: 10
    // Outer popup corner; must match the dialogs/background radius of the
    // Nobara-Enhanced Plasma theme (gen.py: dialog R = 10)
    readonly property real frameRadius: 10
    readonly property int duration: 130
    readonly property real gridIconHoverScale: 1.06
    readonly property real listIconHoverScale: 1.05
}
