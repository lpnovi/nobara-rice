/*
    Quick Tile Glide (local)

    Smoothly moves + resizes a window from its previous geometry into its new
    Quick Tile geometry (and back out when un-tiling). Modelled on KWin's own
    "maximize" (Stretch) effect. Purely visual: KWin has already applied the
    final geometry; this only animates how the window is drawn meanwhile.

    KWin does not tell effects *why* a geometry changed, so a change is treated
    as a quick tile when it is not interactive, not a maximize/fullscreen change,
    changes the size noticeably, and the old or new geometry is tile-shaped
    (touches the left or right screen edge and is reasonably large).
*/

"use strict";

const DURATION = 180;        // ms, deliberately not scaled by the global animation speed
const EDGE_TOLERANCE = 16;   // px, allows for tile padding
const MIN_SIZE_DELTA = 24;   // px, ignore small app-initiated resizes
const NEW_WINDOW_GRACE = 1500;  // ms, leave freshly opened windows alone
const STATE_CHANGE_GRACE = 1000; // ms, leave maximize/fullscreen changes to their own effects
const CROSS_FADE = true;     // blend old contents into new, like KWin's Stretch effect

class QuickTileGlideEffect {
    constructor() {
        effect.animationEnded.connect(this.onAnimationEnded.bind(this));

        effects.windowAdded.connect((window) => {
            window.qtgAddedAt = Date.now();
            this.manage(window);
        });
        for (const window of effects.stackingOrder) {
            this.manage(window);
        }
    }

    manage(window) {
        window.windowFrameGeometryAboutToChange.connect(this.onGeometryAboutToChange.bind(this));
        window.windowFrameGeometryChanged.connect(this.onGeometryChanged.bind(this));

        const markStateChange = (w) => { w.qtgStateChangedAt = Date.now(); };
        window.windowMaximizedStateAboutToChange.connect(markStateChange);
        window.windowMaximizedStateChanged.connect(markStateChange);
        window.windowFullScreenChanged.connect(markStateChange);
    }

    isCandidate(window) {
        const now = Date.now();
        return window.visible
            && window.managed
            && window.normalWindow
            && !window.deleted
            && !window.minimized
            && !window.fullScreen
            && !window.move
            && !window.resize
            && !(window.qtgAddedAt && now - window.qtgAddedAt < NEW_WINDOW_GRACE)
            && !(window.qtgStateChangedAt && now - window.qtgStateChangedAt < STATE_CHANGE_GRACE);
    }

    isTileShaped(geometry, screen) {
        if (!screen) {
            return false;
        }
        const area = screen.geometry;
        const touchesLeft = Math.abs(geometry.x - area.x) <= EDGE_TOLERANCE;
        const touchesRight = Math.abs((geometry.x + geometry.width) - (area.x + area.width)) <= EDGE_TOLERANCE;
        return (touchesLeft || touchesRight)
            && geometry.height >= area.height * 0.4
            && geometry.width >= area.width * 0.2;
    }

    cancelRunning(window) {
        if (window.qtgMorph) {
            cancel(window.qtgMorph);
            delete window.qtgMorph;
        }
        if (window.qtgFade) {
            cancel(window.qtgFade);
            delete window.qtgFade;
        }
    }

    // Called before KWin swaps in the new geometry: remember where the window
    // was and, if cross-fading, keep its old contents around.
    onGeometryAboutToChange(window) {
        if (!this.isCandidate(window)) {
            return;
        }
        this.cancelRunning(window);
        window.qtgOldGeometry = Object.assign({}, window.geometry);
        if (CROSS_FADE) {
            window.qtgFade = animate({
                window: window,
                duration: DURATION,
                animations: [{
                    type: Effect.CrossFadePrevious,
                    from: 0.0,
                    to: 1.0,
                    curve: QEasingCurve.OutCubic
                }]
            });
        }
    }

    onGeometryChanged(window, oldGeometry) {
        const from = window.qtgOldGeometry;
        delete window.qtgOldGeometry;
        if (!from) {
            return;
        }
        const to = window.geometry;

        const sizeChanged = Math.abs(to.width - from.width) >= MIN_SIZE_DELTA
            || Math.abs(to.height - from.height) >= MIN_SIZE_DELTA;
        const tileRelated = this.isTileShaped(to, window.screen) || this.isTileShaped(from, window.screen);

        if (!sizeChanged || !tileRelated || !this.isCandidate(window)) {
            // Not a quick tile: drop the cross-fade we started, nothing was painted yet.
            this.cancelRunning(window);
            return;
        }

        window.setData(Effect.WindowForceBlurRole, true);
        window.qtgMorph = animate({
            window: window,
            duration: DURATION,
            animations: [{
                type: Effect.Size,
                from: { value1: from.width, value2: from.height },
                to: { value1: to.width, value2: to.height },
                curve: QEasingCurve.OutCubic
            }, {
                type: Effect.Translation,
                from: {
                    value1: from.x - to.x - (to.width / 2 - from.width / 2),
                    value2: from.y - to.y - (to.height / 2 - from.height / 2)
                },
                to: { value1: 0, value2: 0 },
                curve: QEasingCurve.OutCubic
            }]
        });

        // End both animations on the same frame.
        if (window.qtgFade) {
            retarget(window.qtgFade, 1.0, DURATION);
        }
    }

    onAnimationEnded(window, animationId) {
        if (animationId === window.qtgMorph) {
            delete window.qtgMorph;
            window.setData(Effect.WindowForceBlurRole, null);
        } else if (animationId === window.qtgFade) {
            delete window.qtgFade;
        }
    }
}

new QuickTileGlideEffect();
