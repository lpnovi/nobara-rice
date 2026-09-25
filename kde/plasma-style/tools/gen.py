#!/usr/bin/env python3
"""Generate the three modified Nobara Enhanced assets from the original Nobara/Breeze sources."""
import sys
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
NS = {
    "": SVG,
    "xlink": "http://www.w3.org/1999/xlink",
    "inkscape": "http://www.inkscape.org/namespaces/inkscape",
    "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
}
for p, u in NS.items():
    ET.register_namespace(p, u)
XL = "{http://www.w3.org/1999/xlink}href"


def q(tag):
    return "{%s}%s" % (SVG, tag)


def by_id(root, i):
    for el in root.iter():
        if el.get("id") == i:
            return el
    raise KeyError(i)


def parent_map(root):
    return {c: p for p in root.iter() for c in p}


def remove_ids(root, ids):
    pm = parent_map(root)
    for i in ids:
        el = by_id(root, i)
        pm[el].remove(el)


def frag(xml):
    """Parse an SVG fragment (default namespace) into a list of elements."""
    wrap = ET.fromstring('<g xmlns="%s" xmlns:xlink="%s">%s</g>' % (SVG, NS["xlink"], xml))
    return list(wrap)


def corner_shadow_stops(R, span=10.0):
    """Radial stops matching Nobara's 'shadow-side' falloff, starting at the frame edge (radius R)."""
    total = R + span
    pts = [(0, 0.2), (R, 0.2), (R + span / 3, 0.1), (R + span / 2, 0.05), (R + span * 0.5833333, 0.025), (total, 0)]
    return "".join('<stop offset="%.6f" style="stop-color:#000;stop-opacity:%g"/>' % (d / total, o) for d, o in pts)


# ---------------------------------------------------------------- panel -----
def panel(src, dst):
    """Raise the corner radius 3 -> 6 inside the unchanged 6x6 corner tiles; match shadow corners."""
    tree = ET.parse(src)
    root = tree.getroot()
    R = 6
    corners = {
        "topleft": "M 6,0 A 6,6 0 0 0 0,6 H 6 Z",
        "topright": "M 0,0 A 6,6 0 0 1 6,6 H 0 Z",
        "bottomleft": "M 0,0 A 6,6 0 0 0 6,6 V 0 Z",
        "bottomright": "M 6,0 A 6,6 0 0 1 0,6 V 0 Z",
    }
    for cid, d in corners.items():
        paths = by_id(root, cid).findall(q("path"))
        assert len(paths) == 1, cid
        paths[0].set("d", d)
        paths[0].attrib.pop("{%s}nodetypes" % NS["sodipodi"], None)

    # One shared radial gradient for the four shadow corners (local bottom-right frame, arc centre 0,0).
    defs = root.find(q("defs"))
    defs.extend(frag('<radialGradient id="shadow-corner-r6" cx="0" cy="0" fx="0" fy="0" r="%d" '
                     'gradientUnits="userSpaceOnUse">%s</radialGradient>' % (R + 10, corner_shadow_stops(R))))
    for sid in ("shadow-topleft", "shadow-topright", "shadow-bottomleft", "shadow-bottomright"):
        paths = by_id(root, sid).findall(q("path"))
        assert len(paths) == 2, sid
        invisible, shade = paths
        invisible.set("d", corners["bottomright"])
        shade.set("d", "M 6,0 H 16 V 16 H 0 V 6 A 6,6 0 0 0 6,0 Z")
        shade.set("style", "fill:url(#shadow-corner-r6);fill-opacity:1;fill-rule:evenodd")
        for p in paths:
            p.attrib.pop("{%s}nodetypes" % NS["sodipodi"], None)
    tree.write(dst, xml_declaration=True, encoding="UTF-8")


# --------------------------------------------------------------- dialog -----
def dialog(src, dst):
    """10px radius frame + light hairline + faint top sheen, matching blur mask and shadow corners."""
    tree = ET.parse(src)
    root = tree.getroot()
    T = R = 10
    FILL = "opacity:0.85;fill:currentColor"          # unchanged Nobara fill
    LINE = "opacity:0.14;fill:currentColor"          # hairline (ColorScheme-Text)

    remove_ids(root, ["top", "bottom", "left", "right", "center",
                      "topleft", "topright", "bottomleft", "bottomright",
                      "mask-top", "mask-bottom", "mask-left", "mask-right", "mask-center",
                      "mask-topleft", "mask-topright", "mask-bottomleft", "mask-bottomright",
                      "shadow-topleft", "shadow-topright", "shadow-bottomleft", "shadow-bottomright"])

    # style block: add Highlight class (unused here, harmless) is not needed; Text + Background already exist.
    defs = root.find(q("defs"))
    defs.extend(frag(
        '<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="%d" gradientUnits="userSpaceOnUse">'
        '<stop offset="0" class="ColorScheme-Text" style="stop-color:currentColor;stop-opacity:0.07"/>'
        '<stop offset="1" class="ColorScheme-Text" style="stop-color:currentColor;stop-opacity:0"/>'
        '</linearGradient>' % T
        + '<radialGradient id="shadow-corner-r10" cx="0" cy="0" fx="0" fy="0" r="%d" '
          'gradientUnits="userSpaceOnUse">%s</radialGradient>' % (R + 10, corner_shadow_stops(R))))

    # Quarter shapes in a TxT tile, arc centre on the inner corner.
    tl = "M %d,0 A %d,%d 0 0 0 0,%d H %d Z" % (T, R, R, T, T)
    tr = "M 0,0 A %d,%d 0 0 1 %d,%d H 0 Z" % (R, R, T, T)
    bl = "M 0,0 A %d,%d 0 0 0 %d,%d V 0 Z" % (R, R, T, T)
    br = "M %d,0 A %d,%d 0 0 1 0,%d V 0 Z" % (T, R, R, T)
    # 1px rings along the outer arc.
    r1 = R - 1
    tl_ring = "M 0,%d A %d,%d 0 0 1 %d,0 V 1 A %d,%d 0 0 0 1,%d Z" % (T, R, R, T, r1, r1, T)
    tr_ring = "M 0,0 A %d,%d 0 0 1 %d,%d H %d A %d,%d 0 0 0 0,1 Z" % (R, R, T, T, T - 1, r1, r1)
    bl_ring = "M 0,0 A %d,%d 0 0 0 %d,%d V %d A %d,%d 0 0 1 1,0 Z" % (R, R, T, T, T - 1, r1, r1)
    br_ring = "M %d,0 A %d,%d 0 0 1 0,%d V %d A %d,%d 0 0 0 %d,0 Z" % (T, R, R, T, T - 1, r1, r1, T - 1)

    def bg(d):
        return '<path d="%s" class="ColorScheme-Background" style="%s"/>' % (d, FILL)

    def line(d):
        return '<path d="%s" class="ColorScheme-Text" style="%s"/>' % (d, LINE)

    def sheen(d):
        return '<path d="%s" style="fill:url(#sheen)"/>' % d

    def rect(x, y, w, h):
        return "M %g,%g H %g V %g H %g Z" % (x, y, x + w, y + h, x)

    X0, Y0 = 0, 80
    S = 32
    g = '<g id="%s" transform="translate(%d,%d)">%s</g>'
    frame = "".join([
        g % ("topleft", X0, Y0, bg(tl) + sheen(tl) + line(tl_ring)),
        g % ("top", X0 + T, Y0, bg(rect(0, 0, S, T)) + sheen(rect(0, 0, S, T)) + line(rect(0, 0, S, 1))),
        g % ("topright", X0 + T + S, Y0, bg(tr) + sheen(tr) + line(tr_ring)),
        g % ("left", X0, Y0 + T, bg(rect(0, 0, T, S)) + line(rect(0, 0, 1, S))),
        g % ("center", X0 + T, Y0 + T, bg(rect(0, 0, S, S))),
        g % ("right", X0 + T + S, Y0 + T, bg(rect(0, 0, T, S)) + line(rect(T - 1, 0, 1, S))),
        g % ("bottomleft", X0, Y0 + T + S, bg(bl) + line(bl_ring)),
        g % ("bottom", X0 + T, Y0 + T + S, bg(rect(0, 0, S, T)) + line(rect(0, T - 1, S, 1))),
        g % ("bottomright", X0 + T + S, Y0 + T + S, bg(br) + line(br_ring)),
    ])

    # Blur/contrast mask, same geometry, plain fill.
    MX = 60
    m = '<path id="%s" transform="translate(%d,%d)" d="%s"/>'
    masks = "".join([
        m % ("mask-topleft", MX, Y0, tl),
        m % ("mask-top", MX + T, Y0, rect(0, 0, S, T)),
        m % ("mask-topright", MX + T + S, Y0, tr),
        m % ("mask-left", MX, Y0 + T, rect(0, 0, T, S)),
        m % ("mask-center", MX + T, Y0 + T, rect(0, 0, S, S)),
        m % ("mask-right", MX + T + S, Y0 + T, rect(0, 0, T, S)),
        m % ("mask-bottomleft", MX, Y0 + T + S, bl),
        m % ("mask-bottom", MX + T, Y0 + T + S, rect(0, 0, S, T)),
        m % ("mask-bottomright", MX + T + S, Y0 + T + S, br),
    ])

    # Shadow corners: drawn in a bottom-right local frame (window corner at origin), mirrored into place.
    C = R + 10
    inv = '<path d="%s" style="opacity:0.00100002;fill:#000000;fill-opacity:0.00392157"/>' % br
    shade = '<path d="M %d,0 H %d V %d H 0 V %d A %d,%d 0 0 0 %d,0 Z" style="fill:url(#shadow-corner-r10);fill-rule:evenodd"/>' % (
        R, C, C, R, R, R, R)
    SX, SY = 120, 80
    sg = '<g id="%s" transform="matrix(%s)">' + inv + shade + "</g>"
    shadows = "".join([
        sg % ("shadow-bottomright", "1,0,0,1,%d,%d" % (SX + C, SY + C)),
        sg % ("shadow-bottomleft", "-1,0,0,1,%d,%d" % (SX + C, SY + C)),
        sg % ("shadow-topright", "1,0,0,-1,%d,%d" % (SX + C, SY + C)),
        sg % ("shadow-topleft", "-1,0,0,-1,%d,%d" % (SX + C, SY + C)),
    ])
    root.extend(frag(frame + masks + shadows))

    # Side shadow tiles: widen only their invisible inner part from 6 to R so they match the corner tiles.
    for rid, attr, pos, val in (("rect1546", "height", None, R),            # shadow-top: y 10..20
                                ("rect1546-3-7", "width", None, R),         # shadow-left: x 10..20
                                ("rect1546-6", "height", ("y", 6 - R), R),  # shadow-bottom: y -4..6
                                ("rect1546-3", "width", ("x", 6 - R), R)):  # shadow-right: x -4..6
        el = by_id(root, rid)
        el.set(attr, str(val))
        if pos:
            el.set(pos[0], str(pos[1]))
    root.set("width", "170")
    root.set("height", "140")
    root.set("viewBox", "0 0 170 140")
    tree.write(dst, xml_declaration=True, encoding="UTF-8")


# ---------------------------------------------------- snap preview outline -----
def translucent(dst):
    T = R = 8
    S = 32
    W = 1.5
    FILL = "opacity:0.45;fill:currentColor"   # ColorScheme-Background (Nobara: black)
    TINT = "opacity:0.10;fill:currentColor"   # ColorScheme-Highlight (Nobara blue)
    EDGE = "opacity:0.55;fill:currentColor"   # ColorScheme-Highlight outline
    ri = R - W

    tl = "M %d,0 A %d,%d 0 0 0 0,%d H %d Z" % (T, R, R, T, T)
    tr = "M 0,0 A %d,%d 0 0 1 %d,%d H 0 Z" % (R, R, T, T)
    bl = "M 0,0 A %d,%d 0 0 0 %d,%d V 0 Z" % (R, R, T, T)
    br = "M %d,0 A %d,%d 0 0 1 0,%d V 0 Z" % (T, R, R, T)
    tl_ring = "M 0,%d A %d,%d 0 0 1 %d,0 V %g A %g,%g 0 0 0 %g,%d Z" % (T, R, R, T, W, ri, ri, W, T)
    tr_ring = "M 0,0 A %d,%d 0 0 1 %d,%d H %g A %g,%g 0 0 0 0,%g Z" % (R, R, T, T, T - W, ri, ri, W)
    bl_ring = "M 0,0 A %d,%d 0 0 0 %d,%d V %g A %g,%g 0 0 1 %g,0 Z" % (R, R, T, T, T - W, ri, ri, W)
    br_ring = "M %d,0 A %d,%d 0 0 1 0,%d V %g A %g,%g 0 0 0 %g,0 Z" % (T, R, R, T, T - W, ri, ri, T - W)

    def rect(x, y, w, h):
        return "M %g,%g H %g V %g H %g Z" % (x, y, x + w, y + h, x)

    def body(d, edge=None):
        s = ('<path d="%s" class="ColorScheme-Background" style="%s"/>'
             '<path d="%s" class="ColorScheme-Highlight" style="%s"/>') % (d, FILL, d, TINT)
        if edge:
            s += '<path d="%s" class="ColorScheme-Highlight" style="%s"/>' % (edge, EDGE)
        return s

    g = '<g id="%s" transform="translate(%d,%d)">%s</g>'
    parts = [
        g % ("topleft", 0, 0, body(tl, tl_ring)),
        g % ("top", T, 0, body(rect(0, 0, S, T), rect(0, 0, S, W))),
        g % ("topright", T + S, 0, body(tr, tr_ring)),
        g % ("left", 0, T, body(rect(0, 0, T, S), rect(0, 0, W, S))),
        g % ("center", T, T, body(rect(0, 0, S, S))),
        g % ("right", T + S, T, body(rect(0, 0, T, S), rect(T - W, 0, W, S))),
        g % ("bottomleft", 0, T + S, body(bl, bl_ring)),
        g % ("bottom", T, T + S, body(rect(0, 0, S, T), rect(0, T - W, S, W))),
        g % ("bottomright", T + S, T + S, body(br, br_ring)),
    ]
    size = 2 * T + S
    svg = ('<?xml version="1.0" encoding="UTF-8"?>\n'
           '<!-- Nobara Enhanced: KWin snap/tile preview (widgets/translucentbackground). '
           'Derived from Breeze; colors come from the theme via ColorScheme classes. -->\n'
           '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="%d" height="%d" viewBox="0 0 %d %d">\n'
           '<defs><style type="text/css" id="current-color-scheme">\n'
           '.ColorScheme-Text { color:#232629; stop-color:#232629; }\n'
           '.ColorScheme-Background { color:#eff0f1; stop-color:#eff0f1; }\n'
           '.ColorScheme-Highlight { color:#3daee9; stop-color:#3daee9; }\n'
           '</style></defs>\n%s\n</svg>\n') % (size, size, size, size, "\n".join(parts))
    open(dst, "w").write(svg)


if __name__ == "__main__":
    tmp = sys.argv[1]
    panel(tmp + "/widgets_panel-background.svg", tmp + "/out_panel-background.svg")
    dialog(tmp + "/dialogs_background.svg", tmp + "/out_dialogs_background.svg")
    translucent(tmp + "/out_translucentbackground.svg")
    print("ok")
