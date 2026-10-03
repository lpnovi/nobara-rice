#!/usr/bin/env python3
"""Build the user-local "Nobara Enhanced" Kickoff fork.

Source:  upstream-6.7.4/   pristine Kickoff QML from plasma-desktop 6.7.4
         nobara/           new files (palette, highlight, metadata.json)
Output:  ~/.local/share/plasma/plasmoids/local.lpnovi.kickoff/

Every patch below is an exact string replacement that must match exactly
once; if a future upstream copy differs, the build stops instead of
producing a half-styled launcher. Re-run after editing, then restart
plasmashell (systemctl --user restart plasma-plasmashell).
"""
import json, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "upstream-6.7.4")
NB = os.path.join(HERE, "nobara")
# KICKOFF_OUT overrides the destination (used by the repo installer / for test builds).
OUT = os.environ.get("KICKOFF_OUT") or os.path.expanduser("~/.local/share/plasma/plasmoids/local.lpnovi.kickoff")

THEME = """
    // Nobara: launcher-scoped purple accent. The Plasma theme's own colors
    // file is Breeze blue; overriding here keeps the rest of Plasma untouched.
    Kirigami.Theme.highlightColor: NobaraStyle.accent
    Kirigami.Theme.highlightedTextColor: NobaraStyle.highlightedText
    Kirigami.Theme.hoverColor: NobaraStyle.accentHover
    Kirigami.Theme.focusColor: NobaraStyle.accentFocus
"""

HEADER_BAND = '''
    // Nobara: rounder outer corners. The theme heading SVG (kept for its
    // metrics, but hidden) uses ~3px corners that mask the frame's corner.
    background.opacity: 0
    NobaraHeadingBackground { heading: root }
'''
FOOTER_BAND = '''
    // Nobara: rounder outer corners. The theme heading SVG (kept for its
    // metrics, but hidden) uses ~3px corners that mask the frame's corner.
    background.opacity: 0
    NobaraHeadingBackground { heading: root; footer: true }
'''

ICON_HOVER = """            animated: false
            // Nobara: restrained hover response; a transform, so no layout change
            scale: root.mouseArea.containsMouse && root.enabled%s ? NobaraStyle.%s : 1
            Behavior on scale {
                NumberAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
            }"""

PATCHES = {
    "FullRepresentation.qml": [
        ("EmptyPage {\n    id: root\n", "EmptyPage {\n    id: root\n" + THEME),
    ],
    "Header.qml": [
        ("    spacing: kickoff.backgroundMetrics.spacing\n",
         "    spacing: kickoff.backgroundMetrics.spacing\n" + THEME + HEADER_BAND),
        ("""                PlasmaExtras.SearchField {
                    id: searchField
""", """                PlasmaExtras.SearchField {
                    id: searchField
                    // Nobara: rounded field; the stock lineedit SVG uses the theme's blue ViewFocus
                    Kirigami.Theme.highlightColor: NobaraStyle.accent
                    Kirigami.Theme.highlightedTextColor: NobaraStyle.highlightedText
                    background: Rectangle {
                        // TextField/SearchField derive their padding from background.margins
                        readonly property QtObject margins: QtObject {
                            readonly property real left: Kirigami.Units.smallSpacing + 2
                            readonly property real right: Kirigami.Units.smallSpacing + 2
                            readonly property real top: Kirigami.Units.smallSpacing + 3
                            readonly property real bottom: Kirigami.Units.smallSpacing + 3
                        }
                        radius: NobaraStyle.radius
                        antialiasing: true
                        color: NobaraStyle.fieldFill
                        border.width: 1
                        border.color: searchField.activeFocus ? NobaraStyle.accent
                            : searchField.hovered ? NobaraStyle.fieldBorderHover : NobaraStyle.fieldBorder
                        Behavior on border.color {
                            ColorAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
                        }
                    }
"""),
    ],
    "Footer.qml": [
        ("    position: PC3.ToolBar.Footer\n", "    position: PC3.ToolBar.Footer\n" + THEME + FOOTER_BAND),
        ("""            highlight: KSvg.FrameSvgItem {
                anchors.top: tabBarListView.contentItem.top
                anchors.bottom: tabBarListView.contentItem.bottom
                anchors.topMargin: -root.topPadding
                anchors.bottomMargin: -root.bottomPadding
                imagePath: "widgets/tabbar"
                prefix: tabBar.position === PC3.TabBar.Header ? "north-active-tab" : "south-active-tab"
            }""", """            // Nobara: rounded purple pill instead of the blue tab-bar underline
            highlight: Item {
                anchors.top: tabBarListView.contentItem.top
                anchors.bottom: tabBarListView.contentItem.bottom
                anchors.topMargin: -root.topPadding
                anchors.bottomMargin: -root.bottomPadding
                NobaraHighlight {
                    anchors.fill: parent
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.bottomMargin: Kirigami.Units.smallSpacing
                    inset: 0
                    active: tabBar.activeFocus
                }
            }"""),
    ],
    "AbstractKickoffItemDelegate.qml": [
        ("""    background: Loader {
        active: (root.GridView?.isCurrentItem || root.ListView?.isCurrentItem) ?? false
        sourceComponent: PlasmaExtras.Highlight {
            anchors.fill: parent
            z: (root.Drag.active ?? false) ? 3 : 0
            hovered: true

            pressed: root.down  && !root.isCategoryListItem

            active: root.view.activeFocus ||
                    (kickoff.contentArea === root && kickoff.searchField.activeFocus)
        }
    }""", """    // Nobara: always-present rounded highlight that fades with the current
    // item (instead of a Loader), so moving the selection cross-fades.
    readonly property bool nobaraIsCurrent: (root.GridView?.isCurrentItem || root.ListView?.isCurrentItem) ?? false
    background: NobaraHighlight {
        z: (root.Drag.active ?? false) ? 3 : 0
        inset: root.view instanceof GridView ? 3 : 1
        opacity: root.nobaraIsCurrent ? 1 : 0
        visible: opacity > 0
        hovered: true

        pressed: root.down  && !root.isCategoryListItem

        // guarded: unlike the upstream Loader, this also exists in the hidden
        // sizing delegates, which have no view (and no kickoff id in scope)
        active: root.view !== null && (root.view.activeFocus ||
                (kickoff.contentArea === root && kickoff.searchField.activeFocus))

        Behavior on opacity {
            NumberAnimation { duration: NobaraStyle.duration; easing.type: Easing.OutCubic }
        }
    }"""),
    ],
    "ApplicationsPage.qml": [
        ("""            background: PlasmaExtras.Highlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                active: false
                hovered: sideBarDelegate.mouseArea.containsMouse || (flashFavoriteAnimation.running && sideBarDelegate.index === 0) || ((dropAreaLoader.item as DropArea)?.containsAcceptableDrag ?? false) || sideBarDelegate.ListView.isCurrentItem
                visible: !sideBarDelegate.isSeparator && hovered
""", """            background: NobaraHighlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                // Nobara: current category = selected pill (stronger while the
                // sidebar has focus); pointer-only = faint hover tint
                readonly property bool emphasized: (flashFavoriteAnimation.running && sideBarDelegate.index === 0) || ((dropAreaLoader.item as DropArea)?.containsAcceptableDrag ?? false) || sideBarDelegate.ListView.isCurrentItem
                sidebar: true
                active: sideBarDelegate.ListView.view?.activeFocus ?? false
                hovered: emphasized
                visible: !sideBarDelegate.isSeparator && (emphasized || sideBarDelegate.mouseArea.containsMouse)
"""),
    ],
    "PlacesPage.qml": [
        ("""            background: PlasmaExtras.Highlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                active: false
                hovered: delegate.mouseArea.containsMouse || delegate.ListView.isCurrentItem
                visible: !delegate.isSeparator && hovered
            }""", """            background: NobaraHighlight {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                sidebar: true
                active: delegate.ListView.view?.activeFocus ?? false
                hovered: delegate.ListView.isCurrentItem
                visible: !delegate.isSeparator && (hovered || delegate.mouseArea.containsMouse)
            }"""),
    ],
    "ListOfGridsViewDelegate.qml": [
        ("""            sourceComponent: PlasmaExtras.Highlight {
                anchors.fill: parent
""", """            sourceComponent: NobaraHighlight {
                anchors.fill: parent
                inset: 3
"""),
    ],
    "SectionView.qml": [
        ("""            sourceComponent: PlasmaExtras.Highlight {
                anchors.fill: parent
""", """            sourceComponent: NobaraHighlight {
                anchors.fill: parent
                inset: 2
"""),
    ],
    "KickoffGridDelegate.qml": [
        ("            animated: false", ICON_HOVER % ("", "gridIconHoverScale")),
    ],
    "KickoffListDelegate.qml": [
        ("            animated: false", ICON_HOVER % (" && !root.isCategoryListItem", "listIconHoverScale")),
        ("""        sourceComponent: KSvg.SvgItem {
            width: parent.width
            height: KickoffSingleton.lineSvg.horLineHeight

            svg: KickoffSingleton.lineSvg
            elementId: "horizontal-line"
        }""", """        // Nobara: softer, inset hairline instead of the theme line SVG
        sourceComponent: Item {
            height: KickoffSingleton.lineSvg.horLineHeight
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                color: NobaraStyle.separator
            }
        }"""),
    ],
    "BasePage.qml": [
        ("import org.kde.ksvg as KSvg\n", "import org.kde.ksvg as KSvg\nimport org.kde.kirigami as Kirigami\n"),
        ("""    KSvg.SvgItem {
        id: separator
        anchors {
            top: parent.top
            left: sideBarFilter.right
            bottom: parent.bottom
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        implicitWidth: naturalSize.width
        implicitHeight: implicitWidth
        elementId: "vertical-line"
        svg: KickoffSingleton.lineSvg
    }""", """    // Nobara: softer hairline, inset from top/bottom; same width as the theme line
    Item {
        id: separator
        anchors {
            top: parent.top
            left: sideBarFilter.right
            bottom: parent.bottom
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        implicitWidth: KickoffSingleton.lineSvg.vertLineWidth
        implicitHeight: implicitWidth
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            color: NobaraStyle.separator
        }
    }"""),
    ],
}

PATCHES["Header.qml"] += [
    ("                PC3.ToolButton {\n                    id: configureButton\n",
     "                NobaraToolButton { // Nobara: QML-drawn frame (stock SVG hover/pressed is Breeze blue)\n                    id: configureButton\n"),
    ("                PC3.ToolButton {\n                    id: pinButton\n",
     "                NobaraToolButton { // Nobara: QML-drawn frame (stock SVG hover/pressed is Breeze blue)\n                    id: pinButton\n"),
]
PATCHES["LeaveButtons.qml"] = [
    ("            delegate: PC3.ToolButton {\n",
     "            delegate: NobaraToolButton { // Nobara: QML-drawn frame (stock SVG hover/pressed is Breeze blue)\n"),
    ("    component OverflowMenuButton : PC3.ToolButton {\n",
     "    component OverflowMenuButton : NobaraToolButton { // Nobara: QML-drawn frame (stock SVG hover/pressed is Breeze blue)\n"),
]
for _view in ("KickoffListView.qml", "KickoffGridView.qml"):
    PATCHES.setdefault(_view, []).append(
        ("        PC3.ScrollBar.vertical: PC3.ScrollBar {\n",
         "        // Nobara: rounded QML scrollbar, same 18px metrics as the stock one\n"
         "        PC3.ScrollBar.vertical: NobaraScrollBar {\n"))

NEW_TYPES = ["singleton NobaraStyle 1.0 NobaraStyle.qml", "NobaraHighlight 1.0 NobaraHighlight.qml",
             "NobaraToolButton 1.0 NobaraToolButton.qml", "NobaraScrollBar 1.0 NobaraScrollBar.qml",
             "NobaraHeadingBackground 1.0 NobaraHeadingBackground.qml"]


def main():
    tmp = OUT + ".building"
    shutil.rmtree(tmp, ignore_errors=True)
    ui = os.path.join(tmp, "contents", "ui")
    cfg = os.path.join(tmp, "contents", "config")
    os.makedirs(os.path.join(ui, "code"))
    os.makedirs(cfg)

    for f in sorted(os.listdir(UP)):
        if f.endswith(".qml") and f != "config.qml":
            shutil.copy(os.path.join(UP, f), ui)
    shutil.copy(os.path.join(UP, "config.qml"), cfg)
    shutil.copy(os.path.join(UP, "main.xml"), cfg)
    shutil.copy(os.path.join(UP, "code", "tools.js"), os.path.join(ui, "code"))
    for f in ("NobaraStyle.qml", "NobaraHighlight.qml", "NobaraToolButton.qml", "NobaraScrollBar.qml", "NobaraHeadingBackground.qml"):
        shutil.copy(os.path.join(NB, f), ui)
    shutil.copy(os.path.join(NB, "metadata.json"), tmp)

    for name, patches in PATCHES.items():
        path = os.path.join(ui, name)
        src = open(path).read()
        for old, new in patches:
            n = src.count(old)
            if n != 1:
                sys.exit(f"patch mismatch in {name}: expected 1 match, found {n}:\n{old[:120]}")
            src = src.replace(old, new)
        open(path, "w").write(src)

    # qmldir: in the compiled plugin these types come from CMake; a plain QML
    # package needs them listed (singletons must be declared here).
    lines = []
    for f in sorted(os.listdir(ui)):
        if not f.endswith(".qml") or f == "main.qml" or f.startswith("Nobara"):
            continue
        n = f[:-4]
        prefix = "singleton " if n in ("KickoffSingleton", "ActionMenu") else ""
        lines.append(f"{prefix}{n} 1.0 {f}")
    open(os.path.join(ui, "qmldir"), "w").write("\n".join(lines + NEW_TYPES) + "\n")

    json.load(open(os.path.join(tmp, "metadata.json")))  # sanity
    shutil.rmtree(OUT, ignore_errors=True)
    os.rename(tmp, OUT)
    print("built", OUT)


if __name__ == "__main__":
    main()
