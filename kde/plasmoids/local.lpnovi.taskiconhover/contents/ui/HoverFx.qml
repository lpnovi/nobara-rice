/*
    Per-icon hover transform attached to a stock task manager delegate.
    Created as a child of the task's icon box, so it is destroyed with it.
    Transforms don't participate in layout: neighbours and the panel never move.
*/
import QtQuick

QtObject {
    id: fx

    required property Item target   // the task's icon box (Kirigami.Icon + badge)
    required property Item task     // the task delegate
    required property real liftX
    required property real liftY

    readonly property bool hovered: !!task && !task.inPopup && task.highlighted

    readonly property int duration: 140
    readonly property real hoverScale: 1.08

    readonly property Scale scale: Scale {
        origin.x: fx.target.width / 2
        origin.y: fx.target.height / 2
        xScale: fx.hovered ? fx.hoverScale : 1
        yScale: xScale
        Behavior on xScale {
            NumberAnimation { duration: fx.duration; easing.type: Easing.OutCubic }
        }
    }

    readonly property Translate translate: Translate {
        x: fx.hovered ? fx.liftX : 0
        y: fx.hovered ? fx.liftY : 0
        Behavior on x {
            NumberAnimation { duration: fx.duration; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: fx.duration; easing.type: Easing.OutCubic }
        }
    }
}
