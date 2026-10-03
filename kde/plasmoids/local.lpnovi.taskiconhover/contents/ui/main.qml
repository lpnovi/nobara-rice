/*
    Task Icon Hover (local)

    Invisible helper applet. Placed in the same panel as the stock
    org.kde.plasma.icontasks widget, it finds that widget's task delegates in
    the panel's item tree and attaches a Scale + Translate transform to each
    icon box. The task manager itself is not copied or modified.

    Plasmoid.status is HiddenStatus, so the panel does not lay this applet
    out at all (it only shows up in panel Edit Mode, where it can be removed).
*/
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.status: PlasmaCore.Types.HiddenStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // Lift away from the panel edge, ~2.5 px.
    readonly property real lift: 2.5
    readonly property real liftX: Plasmoid.location === PlasmaCore.Types.LeftEdge ? lift
                                : Plasmoid.location === PlasmaCore.Types.RightEdge ? -lift : 0
    readonly property real liftY: Plasmoid.location === PlasmaCore.Types.TopEdge ? lift
                                : Plasmoid.location === PlasmaCore.Types.BottomEdge ? -lift : 0

    property var hookedContainers: []
    property bool hooked: false
    readonly property Component fxComponent: Qt.createComponent("HoverFx.qml")

    fullRepresentation: Item {
        implicitWidth: 0
        implicitHeight: 0
    }

    function isTaskDelegate(item: Item): bool {
        return item.tasksRoot !== undefined
            && item.inPopup !== undefined
            && item.highlighted !== undefined
            && item.smartLauncherItem !== undefined;
    }

    // The Loader that holds the task's Kirigami.Icon.
    function iconBoxOf(task: Item): Item {
        for (const child of task.children) {
            for (const grandChild of child.children) {
                if (grandChild.roundToIconSize !== undefined && grandChild.source !== undefined) {
                    return child;
                }
            }
        }
        return null;
    }

    function patch(task: Item): void {
        const box = iconBoxOf(task);
        if (!box || box.transform.length > 0) {
            return; // not ready yet, or already patched
        }
        const fx = fxComponent.createObject(box, {
            target: box,
            task: task,
            liftX: Qt.binding(() => root.liftX),
            liftY: Qt.binding(() => root.liftY),
        });
        if (fx) {
            box.transform = [fx.scale, fx.translate];
        }
    }

    function scan(item: Item): void {
        if (!item) {
            return;
        }
        if (isTaskDelegate(item)) {
            patch(item);
            const list = item.parent;
            if (list && !hookedContainers.includes(list)) {
                hookedContainers.push(list);
                hooked = true;
                list.childrenChanged.connect(() => Qt.callLater(root.rescan));
            }
            return;
        }
        for (const child of item.children) {
            scan(child);
        }
    }

    function rescan(): void {
        if (fxComponent.status !== Component.Ready) {
            if (fxComponent.status === Component.Error) {
                console.warn("taskiconhover:", fxComponent.errorString());
            }
            return;
        }
        let top = root;
        while (top.parent) {
            top = top.parent;
        }
        scan(top);
    }

    // Initial pickup (the task manager may load after us) and a slow safety net
    // in case delegates are recreated without a childrenChanged we're hooked to.
    Timer {
        interval: root.hooked ? 5000 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.rescan()
    }
}
