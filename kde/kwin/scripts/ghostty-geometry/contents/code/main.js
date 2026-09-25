// Remembers the last user-set geometry of Ghostty windows and applies it to new ones.
// Persistence: each change is logged as "GHOSTTY_GEOMETRY x,y,w,h"; the user service
// ghostty-geometry-sync writes it to kwinrc [Script-ghostty-geometry] geometry=...,
// which is read here when the script loads (i.e. at login).
const APP = "com.mitchellh.ghostty";
const TAG = "GHOSTTY_GEOMETRY";
const FALLBACK = "324,187,1151,749";

function parse(str) {
    const p = String(str).split(",").map(Number);
    if (p.length !== 4 || p.some(n => !isFinite(n)) || p[2] < 200 || p[3] < 150) return null;
    return { x: p[0], y: p[1], width: p[2], height: p[3] };
}

let saved = parse(readConfig("geometry", FALLBACK)) || parse(FALLBACK);

function isGhostty(w) {
    return w && w.resourceClass === APP && w.normalWindow && !w.transient;
}

function record(w) {
    if (!isGhostty(w) || w.fullScreen || w.maximizeMode !== 0 || w.minimized) return;
    if (w.tile) return; // quick-tiled / custom-tiled layouts are not the "normal" size
    const g = w.frameGeometry;
    const next = { x: Math.round(g.x), y: Math.round(g.y),
                   width: Math.round(g.width), height: Math.round(g.height) };
    if (next.width < 200 || next.height < 150) return;
    if (saved && next.x === saved.x && next.y === saved.y
        && next.width === saved.width && next.height === saved.height) return;
    saved = next;
    console.warn(TAG + " " + [next.x, next.y, next.width, next.height].join(","));
}

function apply(w) {
    if (!saved) return;
    const area = workspace.clientArea(KWin.PlacementArea, w);
    const width = Math.min(saved.width, area.width);
    const height = Math.min(saved.height, area.height);
    const x = Math.max(area.x, Math.min(saved.x, area.x + area.width - width));
    const y = Math.max(area.y, Math.min(saved.y, area.y + area.height - height));
    w.frameGeometry = { x: x, y: y, width: width, height: height };
}

function track(w) {
    w.interactiveMoveResizeFinished.connect(() => record(w));
}

for (const w of workspace.windowList()) {
    if (isGhostty(w)) track(w);
}

workspace.windowAdded.connect(w => {
    if (!isGhostty(w)) return;
    apply(w);
    track(w);
});

workspace.windowRemoved.connect(w => record(w));
