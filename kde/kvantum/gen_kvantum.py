#!/usr/bin/env python3
"""Generate the "NobaraEnhancedPurple" Kvantum theme.

Base: KvSimplicityDark by Tsu Jan (kvantum-data 1.1.6, GPL-3.0-or-later),
see base/COPYING-kvantum-data-GPL3. Elements that are rarely visible (dial,
dock, splitter/resize grips, tab-close, MDI buttons...) are taken from the base
and recolored to the violet/near-black palette. Every element that is visible
in Dolphin / System Settings is regenerated here as exact rounded 9-slices.

Output: ~/.config/Kvantum/NobaraEnhancedPurple/NobaraEnhancedPurple.{svg,kvconfig}
Re-run this script after editing the palette below; then restart the app.
"""
import colorsys, os, re
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
NAME = "NobaraEnhancedPurple"
# KVANTUM_OUT overrides the destination (used by the repo installer / for test builds).
OUT = os.environ.get("KVANTUM_OUT") or os.path.expanduser(f"~/.config/Kvantum/{NAME}")

# ---------------------------------------------------------------- palette ---
# Keep in sync with kde/color-schemes/NobaraEnhancedPurple.colors
# (installed to ~/.local/share/color-schemes/)
P = dict(
    window="#111015", view="#16151c", viewalt="#1b1a22",
    btn="#211f2a", btn_b="#2f2c3b",
    btn_h="#282534", btn_hb="#54457f",
    btn_p="#1a1822", btn_pb="#6c54aa",
    btn_t="#33294f", btn_tb="#6c54aa",
    btn_ti="#2a2438", btn_tib="#3d3456",
    btn_d="#18171e", btn_db="#22202a",
    edit="#0f0e14", edit_b="#2a2836", edit_fb="#8c73d2", edit_f="#121118",
    sel="#54438c", sel_b="#6c54aa", selh="#5f4c9e", selh_b="#7a63c0",
    sel_i="#372f55", sel_ib="#45396a",
    accent="#6c54aa", accent2="#7a63c0", accent3="#8c73d2", lavender="#b4a2f0",
    menu="#16151c", menu_b="#2e2b3a",
    line="#25232e", header="#16151c",
    text="#dedde6", text_dim="#b9b5c9", text_dis="#6f6c80", white="#ffffff",
)
HOVER = ("#968be1", 0.13)       # item-view hover tint (rgba)
TOOLHOVER = ("#968be1", 0.12)   # flat tool button hover
TOOLPRESS = ("#968be1", 0.22)

# ------------------------------------------------------------ svg helpers ---
SIDES = ("topleft", "top", "topright", "left", "", "right",
         "bottomleft", "bottom", "bottomright")
_cells = []


def cell(w, h):
    """Allocate a free spot on the canvas (simple shelf packing)."""
    n = len(_cells)
    x = 20 + (n % 12) * 60
    y = 20 + (n // 12) * 60
    _cells.append((x, y))
    return x, y


def paint(c):
    """(color, alpha) or '#rrggbb' or None -> svg attrs."""
    if c is None:
        return 'fill="#000000" fill-opacity="0"'
    if isinstance(c, tuple):
        return f'fill="{c[0]}" fill-opacity="{c[1]}"'
    return f'fill="{c}"'


def nine(eid, f, fill, border=None, sides="tblr", c=8, sw=1.0, rounded=True):
    """9-slice element: ids eid-topleft ... eid (centre) ... eid-bottomright.

    f = frame size == corner radius (px). A border, if given, is a ring of
    width sw that never overlaps the fill, so translucent colors compose right.
    """
    x0, y0 = cell(2 * f + c, 2 * f + c)
    S = 2 * f + c
    out = []
    r = f if rounded else 0
    bw = sw if border else 0
    for name in SIDES:
        pid = f"{eid}-{name}" if name else eid
        # piece rectangle
        px = {"left": 0, "": f, "right": f + c}
        py = {"top": 0, "": f, "bottom": f + c}
        hx = "left" if "left" in name else "right" if "right" in name else ""
        vy = "top" if "top" in name else "bottom" if "bottom" in name else ""
        X, Y = x0 + px[hx], y0 + py[vy]
        W = f if hx else c
        H = f if vy else c
        g = [f'<g id="{pid}">',
             f'<rect x="{X}" y="{Y}" width="{W}" height="{H}" fill="#000000" fill-opacity="0"/>']
        corner = bool(hx and vy)
        if corner and r > 0:
            # centre of the arc = inner corner of the piece
            cx = X + (W if hx == "left" else 0)
            cy = Y + (H if vy == "top" else 0)
            ox = X if hx == "left" else X + W        # outer x
            oy = Y if vy == "top" else Y + H         # outer y
            sweep = 1 if (hx, vy) in (("left", "top"), ("right", "bottom")) else 0

            def pie(rad):
                ax = cx + (ox - cx) * rad / r
                ay = cy + (oy - cy) * rad / r
                return (f"M {cx},{cy} L {ax},{cy} A {rad},{rad} 0 0 {sweep} {cx},{ay} Z")
            if border and ("t" if vy == "top" else "b") in sides and ("l" if hx == "left" else "r") in sides:
                g.append(f'<path d="{pie(r)} {pie(r - bw)}" fill-rule="evenodd" {paint(border)}/>')
                g.append(f'<path d="{pie(r - bw)}" {paint(fill)}/>')
            else:
                g.append(f'<path d="{pie(r)}" {paint(fill)}/>')
        else:
            # rectangle piece; border strips on the outer edges that want one
            fx, fy, fw, fh = X, Y, W, H
            strips = []
            if border:
                if vy == "top" and "t" in sides:
                    strips.append((X, Y, W, bw)); fy += bw; fh -= bw
                if vy == "bottom" and "b" in sides:
                    strips.append((X, Y + H - bw, W, bw)); fh -= bw
                if hx == "left" and "l" in sides:
                    strips.append((X, fy, bw, fh)); fx += bw; fw -= bw
                if hx == "right" and "r" in sides:
                    strips.append((X + W - bw, fy, bw, fh)); fw -= bw
            g.append(f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" {paint(fill)}/>')
            for (a, b, w, h) in strips:
                g.append(f'<rect x="{a}" y="{b}" width="{w}" height="{h}" {paint(border)}/>')
        g.append("</g>")
        out.append("".join(g))
    return "\n".join(out)


def edges(eid, color, sw=1.0, c=8):
    """Focus frame: only eid-top/-bottom/-left/-right strips."""
    x0, y0 = cell(c + 2, c + 2)
    return "\n".join([
        f'<rect id="{eid}-top" x="{x0}" y="{y0}" width="{c}" height="{sw}" {paint(color)}/>',
        f'<rect id="{eid}-bottom" x="{x0}" y="{y0 + 4}" width="{c}" height="{sw}" {paint(color)}/>',
        f'<rect id="{eid}-left" x="{x0 + 12}" y="{y0}" width="{sw}" height="{c}" {paint(color)}/>',
        f'<rect id="{eid}-right" x="{x0 + 16}" y="{y0}" width="{sw}" height="{c}" {paint(color)}/>',
    ])


def icon(eid, size, body):
    x0, y0 = cell(size, size)
    return (f'<g id="{eid}" transform="translate({x0},{y0})">'
            f'<rect width="{size}" height="{size}" fill="#000000" fill-opacity="0"/>{body}</g>')


def arrow(direction, color, s=12):
    pts = {"down": "3,4.5 6,7.5 9,4.5", "up": "3,7.5 6,4.5 9,7.5",
           "right": "4.5,3 7.5,6 4.5,9", "left": "7.5,3 4.5,6 7.5,9"}[direction]
    k = s / 12
    return (f'<polyline points="{pts}" transform="scale({k})" fill="none" stroke="{color}" '
            f'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>')


# ------------------------------------------------------------ elements ------
def generated():
    E = []
    # push buttons, combo boxes, spin buttons, (non-flat) tool buttons
    E += [nine("button-normal", 6, P["btn"], P["btn_b"]),
          nine("button-focused", 6, P["btn_h"], P["btn_hb"]),
          nine("button-pressed", 6, P["btn_p"], P["btn_pb"]),
          nine("button-toggled", 6, P["btn_t"], P["btn_tb"]),
          nine("button-toggled-inactive", 6, P["btn_ti"], P["btn_tib"]),
          nine("button-disabled", 6, P["btn_d"], P["btn_db"])]
    # flat tool buttons (toolbars, Kirigami ToolButton): invisible until hovered
    E += [nine("tbutton-normal", 6, None),
          nine("tbutton-focused", 6, TOOLHOVER),
          nine("tbutton-pressed", 6, TOOLPRESS),
          nine("tbutton-toggled", 6, P["btn_t"], P["btn_tb"]),
          nine("tbutton-toggled-inactive", 6, P["btn_ti"], P["btn_tib"]),
          nine("tbutton-disabled", 6, None)]
    # line edits (Dolphin location bar/search, System Settings text fields)
    E += [nine("lineedit-normal", 6, P["edit"], P["edit_b"]),
          nine("lineedit-focused", 6, P["edit_f"], P["edit_fb"]),
          nine("lineedit-disabled", 6, P["btn_d"], P["btn_db"])]
    # item views: Dolphin files & Places, System Settings sidebar rows
    E += [nine("itemview-normal", 6, None),
          nine("itemview-focused", 6, HOVER),
          nine("itemview-toggled", 6, P["sel"], P["sel_b"]),
          nine("itemview-pressed", 6, P["selh"], P["selh_b"]),
          nine("itemview-toggled-inactive", 6, P["sel_i"], P["sel_ib"]),
          nine("itemview-pressed-inactive", 6, P["sel_i"], P["sel_ib"])]
    # menus (Qt Widgets menus; QML menus are drawn by Kirigami)
    E += [nine("menu-normal", 8, P["menu"], P["menu_b"])]
    E += [nine(f"menuitem-{s}", 5, P["sel"]) for s in ("focused", "pressed", "toggled")]
    E += [nine("menubar-normal", 1, P["window"], rounded=False)]
    E += [nine("menubaritem-normal", 5, None),
          nine("menubaritem-focused", 5, TOOLHOVER),
          nine("menubaritem-pressed", 5, P["sel"]),
          nine("menubaritem-toggled", 5, P["sel"])]
    E += [nine("toolbar-normal", 1, P["window"], rounded=False)]
    E += [nine("tooltip-normal", 6, P["viewalt"], P["menu_b"])]
    # tabs: pill for the current tab, nothing for the others
    E += [nine("tab-normal", 6, None),
          nine("tab-focused", 6, ("#ffffff", 0.045)),
          nine("tab-pressed", 6, P["btn_h"]),
          nine("tab-toggled", 6, P["btn"], P["btn_b"]),
          nine("tab-toggled-inactive", 6, P["btn"], P["line"])]
    E += [nine("tabframe-normal", 6, None, P["line"]),
          nine("common-normal", 6, None, P["line"]),
          nine("group-normal", 8, ("#ffffff", 0.012), P["line"])]
    # column headers (Dolphin details view): flat, hairline separators
    E += [nine("header-normal", 1, P["header"], P["line"], sides="br", rounded=False),
          nine("header-focused", 1, P["viewalt"], P["line"], sides="br", rounded=False),
          nine("header-pressed", 1, P["btn"], P["line"], sides="br", rounded=False),
          nine("header-toggled", 1, P["header"], P["line"], sides="br", rounded=False)]
    # scrollbars: slim pills, no groove
    E += [nine("scrollbarslider-normal", 4, ("#bdb4dc", 0.26)),
          nine("scrollbarslider-focused", 4, ("#a08ae6", 0.60)),
          nine("scrollbarslider-pressed", 4, P["accent3"]),
          nine("scrollbarslider-disabled", 4, ("#bdb4dc", 0.08))]
    # sliders
    E += [nine("slider-normal", 2, "#2a2836"),
          nine("slider-focused", 2, "#2f2c3c"),
          nine("slider-disabled", 2, "#1e1c25"),
          nine("slider-toggled", 2, P["accent2"]),
          nine("slider-toggled-disabled", 2, "#3a3350")]
    for s, fc, bc in (("normal", "#cfc4f2", P["accent3"]), ("focused", "#e2dbfa", P["lavender"]),
                      ("pressed", P["lavender"], P["accent"]), ("disabled", "#3a3748", "#2a2836")):
        E.append(icon(f"slidercursor-{s}", 18,
                      f'<circle cx="9" cy="9" r="8" fill="{fc}" stroke="{bc}" stroke-width="1.5"/>'))
    # progress bars
    E += [nine("progress-normal", 3, P["btn"]),
          nine("progress-pattern-normal", 3, P["accent2"]),
          nine("progress-pattern-disabled", 3, "#3a3350")]
    # focus ring (keyboard focus)
    E.append(edges("focus", (P["accent3"], 0.7)))
    # check boxes & radio buttons
    check = '<path d="M4.5,8.3 L7,10.8 L11.6,5.6" fill="none" stroke="#ffffff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>'
    dash = '<rect x="4.5" y="7.2" width="7" height="1.8" rx="0.9" fill="#ffffff"/>'
    box = {"normal": (P["view"], "#4a4659"), "focused": ("#1b1a24", P["accent3"]),
           "pressed": ("#2a2440", P["accent3"]), "disabled": ("#141318", "#2a2833")}
    on = {"normal": P["accent2"], "focused": P["accent3"], "pressed": P["accent"], "disabled": "#3a3350"}
    for s, (fc, bc) in box.items():
        E.append(icon(f"checkbox-{s}", 16,
                      f'<rect x="0.75" y="0.75" width="14.5" height="14.5" rx="4" fill="{fc}" stroke="{bc}" stroke-width="1.5"/>'))
        E.append(icon(f"radio-{s}", 16,
                      f'<circle cx="8" cy="8" r="7.25" fill="{fc}" stroke="{bc}" stroke-width="1.5"/>'))
    for s, fc in on.items():
        mark = check if s != "disabled" else check.replace("#ffffff", "#8a8698")
        dmark = dash if s != "disabled" else dash.replace("#ffffff", "#8a8698")
        base = f'<rect x="0" y="0" width="16" height="16" rx="4.5" fill="{fc}"/>'
        E.append(icon(f"checkbox-checked-{s}", 16, base + mark))
        E.append(icon(f"checkbox-tristate-{s}", 16, base + dmark))
        dot = "#ffffff" if s != "disabled" else "#8a8698"
        E.append(icon(f"radio-checked-{s}", 16,
                      f'<circle cx="8" cy="8" r="8" fill="{fc}"/><circle cx="8" cy="8" r="3.2" fill="{dot}"/>'))
    # arrows (combo boxes, spin boxes, tree expanders, sub-menus)
    for d in ("up", "down", "left", "right"):
        for s, col in (("normal", P["text_dim"]), ("focused", "#ddd4ff"), ("pressed", P["white"]),
                       ("toggled", P["white"]), ("disabled", "#56535f")):
            E.append(icon(f"arrow-{d}-{s}", 12, arrow(d, col)))
    # plus/minus for tree expanders in case a view asks for them
    for s, col in (("normal", P["text_dim"]), ("focused", "#ddd4ff"), ("pressed", P["white"]), ("disabled", "#56535f")):
        E.append(icon(f"arrow-plus-{s}", 12, arrow("right", col)))
        E.append(icon(f"arrow-minus-{s}", 12, arrow("down", col)))
    # sub-menu arrows (MenuItem indicator.element=menuitem)
    for s, col in (("normal", P["text_dim"]), ("focused", P["white"]), ("pressed", P["white"]),
                   ("toggled", P["white"]), ("disabled", "#56535f")):
        E.append(icon(f"menuitem-right-{s}", 12, arrow("right", col)))
        E.append(icon(f"menuitem-left-{s}", 12, arrow("left", col)))
    # tab close "x" and a neutral default-button marker (base versions looked off)
    for s, col, bg in (("normal", P["text_dim"], None), ("focused", P["white"], ("#ffffff", 0.10)),
                       ("pressed", P["white"], ("#968be1", 0.30)), ("disabled", "#56535f", None)):
        circ = f'<circle cx="8" cy="8" r="7.5" {paint(bg)}/>' if bg else ""
        E.append(icon(f"tab-close-{s}", 16, circ +
                      f'<path d="M5.3,5.3 L10.7,10.7 M10.7,5.3 L5.3,10.7" stroke="{col}" stroke-width="1.5" stroke-linecap="round"/>'))
    E.append(icon("button-default-indicator", 4, ""))
    E.append(icon("header-separator", 4, f'<rect x="1.5" y="0" width="1" height="4" fill="{P["line"]}"/>'))
    return E


# ---------------------------------------------------------- base recolor ---
def recolor(hexcol):
    h = hexcol.lstrip("#")
    if len(h) == 3:
        h = "".join(ch * 2 for ch in h)
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    if ss < 0.15 or ll < 0.04 or ll > 0.96:
        # neutral grey -> violet-tinted near-black ramp
        L = ll * 255
        pts = [(0, 8), (20, 14), (40, 22), (62, 33), (100, 58), (150, 118), (200, 190), (255, 245)]
        for (a, fa), (b2, fb) in zip(pts, pts[1:]):
            if a <= L <= b2:
                v = fa + (fb - fa) * (L - a) / (b2 - a)
                break
        R, G, B = v * 0.97, v * 0.94, v * 1.12
    else:
        # any hue (Kvantum blues mostly) -> muted violet, same lightness
        R, G, B = (c * 255 for c in colorsys.hls_to_rgb(258 / 360, ll, min(ss, 0.55)))
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(c))) for c in (R, G, B))


def recolor_text(s):
    return re.sub(r"#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b", lambda m: recolor(m.group(0)), s)


PIECE = r"(-inactive)?(-(topleft|topright|bottomleft|bottomright|top|bottom|left|right))?$"


def build_svg():
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    for p, u in (("inkscape", "http://www.inkscape.org/namespaces/inkscape"),
                 ("sodipodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"),
                 ("xlink", "http://www.w3.org/1999/xlink"),
                 ("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#"),
                 ("cc", "http://creativecommons.org/ns#"),
                 ("dc", "http://purl.org/dc/elements/1.1/")):
        ET.register_namespace(p, u)
    base_txt = open(os.path.join(HERE, "base", "KvSimplicityDark.svg"), encoding="utf-8").read()
    root = ET.fromstring(recolor_text(base_txt))
    gen = "\n".join(generated())
    new_ids = set(re.findall(r'id="([^"]+)"', gen))
    families = {re.sub(PIECE, "", i) for i in new_ids}
    fam_re = re.compile("^(" + "|".join(re.escape(f) for f in sorted(families, key=len, reverse=True)) + ")" + PIECE)
    stripped = 0
    for el in root.iter():
        i = el.get("id")
        if i and (i in new_ids or fam_re.match(i)):
            el.attrib.pop("id")          # superseded: never referenced any more
            stripped += 1
    ns = "{http://www.w3.org/2000/svg}"
    layer = ET.fromstring(f'<g xmlns="http://www.w3.org/2000/svg" transform="translate(0,-2000)">{gen}</g>')
    # generated pieces live off-canvas above the base art; Kvantum renders by id only
    root.append(layer)
    ET.indent(root, space=" ")
    svg = ET.tostring(root, encoding="unicode")
    header = ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
              "<!-- NobaraEnhancedPurple Kvantum theme. Derived from KvSimplicityDark by Tsu Jan "
              "(kvantum-data, GPL-3.0-or-later); see COPYING. Generated by "
              "~/.local/share/nobara-enhanced-apptheme/gen_kvantum.py -->\n")
    return header + svg, stripped, len(new_ids)


# ------------------------------------------------------------- kvconfig ---
def kv_escape(v):
    return v


def build_kvconfig():
    t, w = P["text"], P["white"]
    return f"""[%General]
author=lpnovi (local), based on KvSimplicityDark by Tsu Jan
comment=Nobara Enhanced Purple: near-black with muted violet accents. Derived from KvSimplicityDark (GPL-3.0-or-later).
x11drag=true
alt_mnemonic=true
left_tabs=false
attach_active_tab=false
embedded_tabs=false
mirror_doc_tabs=false
center_doc_tabs=false
center_normal_tabs=false
joined_inactive_tabs=false
no_inactive_tab_expansion=true
bold_active_tab=false
group_toolbar_buttons=false
toolbar_item_spacing=2
toolbar_interior_spacing=3
toolbar_separator_thickness=1
spread_progressbar=true
composite=true
menu_shadow_depth=0
tooltip_shadow_depth=0
menu_blur_radius=0
tooltip_blur_radius=0
reduce_menu_opacity=0
spread_menuitems=true
menu_separator_height=7
scroll_width=10
scroll_arrows=false
scroll_min_extent=48
transient_scrollbar=true
transient_groove=true
center_scrollbar_indicator=true
slider_width=4
slider_handle_width=18
slider_handle_length=18
tickless_slider_handle_size=18
center_toolbar_handle=true
check_size=16
textless_progressbar=false
progressbar_thickness=6
menubar_mouse_tracking=true
toolbutton_style=0
click_behavior=0
translucent_windows=false
reduce_window_opacity=0
popup_opaque=kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,smplayer,smplayer2,avidemux,avidemux2_qt4,avidemux3_qt4,avidemux3_qt5,kamoso,QtCreator,VirtualBox,VirtualBoxVM,trojita,dragon,digikam,lyx
vertical_spin_indicators=false
inline_spin_indicators=true
inline_spin_separator=false
fill_rubberband=true
merge_menubar_with_toolbar=false
small_icon_size=16
large_icon_size=32
button_icon_size=16
toolbar_icon_size=22
combo_as_lineedit=true
combo_menu=true
combo_focus_rect=false
hide_combo_checkboxes=true
square_combo_button=false
groupbox_top_label=true
remove_extra_frames=true
layout_spacing=6
layout_margin=9
submenu_overlap=0
submenu_delay=250
tooltip_delay=-1
animate_states=true
no_window_pattern=true
dialog_button_layout=0
scrollbar_in_view=true
tree_branch_line=false
splitter_width=1

[GeneralColors]
window.color={P["window"]}
base.color={P["view"]}
alt.base.color={P["viewalt"]}
button.color={P["btn"]}
light.color=#2f2c3b
mid.light.color=#26242f
dark.color=#0b0a0e
mid.color=#1d1b25
highlight.color={P["accent"]}
inactive.highlight.color={P["sel_i"]}
tooltip.base.color={P["viewalt"]}
text.color={t}
window.text.color={t}
button.text.color={t}
disabled.text.color={P["text_dis"]}
tooltip.text.color={t}
highlight.text.color={w}
link.color={P["lavender"]}
link.visited.color=#c8b8ff
progress.indicator.text.color={w}
progress.inactive.indicator.text.color={t}

[Hacks]
transparent_ktitle_label=true
transparent_dolphin_view=false
transparent_pcmanfm_sidepane=false
transparent_pcmanfm_view=false
blur_translucent=false
transparent_menutitle=true
respect_darkness=true
force_size_grip=false
iconless_pushbutton=false
iconless_menu=false
disabled_icon_opacity=60
lxqtmainmenu_iconsize=22
normal_default_pushbutton=true
single_top_toolbar=true
tint_on_mouseover=0
transparent_arrow_button=true
no_selection_tint=true
centered_forms=false
middle_click_scroll=false
style_vertical_toolbars=false
blur_only_active_window=false

[PanelButtonCommand]
frame=true
frame.element=button
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
frame.expansion=0
interior=true
interior.element=button
indicator.size=12
indicator.element=arrow
text.normal.color={t}
text.focus.color={w}
text.press.color={w}
text.toggle.color={w}
text.shadow=0
text.margin=1
text.iconspacing=6
text.margin.top=0
text.margin.bottom=0
text.margin.left=4
text.margin.right=4

[PanelButtonTool]
inherits=PanelButtonCommand
frame.element=tbutton
interior.element=tbutton
text.margin.left=2
text.margin.right=2

[ToolbarButton]
inherits=PanelButtonTool

[Dock]
inherits=PanelButtonCommand
interior.element=dock
frame.element=dock
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.normal.color={t}

[DockTitle]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={P["text_dim"]}
text.focus.color={w}
text.bold=true

[IndicatorSpinBox]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow
indicator.size=12
text.normal.color={t}

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio
text.normal.color={t}
text.focus.color={w}

[CheckBox]
inherits=PanelButtonCommand
frame=false
interior.element=checkbox
text.normal.color={t}
text.focus.color={w}

[Focus]
inherits=PanelButtonCommand
frame=true
frame.element=focus
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
interior=false

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6

[LineEdit]
inherits=PanelButtonCommand
frame.element=lineedit
interior.element=lineedit
text.margin.top=2
text.margin.bottom=2
text.margin.left=2
text.margin.right=2

[DropDownButton]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.element=arrow-down

[IndicatorArrow]
indicator.element=arrow
indicator.size=12

[ToolboxTab]
inherits=PanelButtonCommand
text.normal.color={t}
text.press.color={w}
text.focus.color={w}

[Tab]
inherits=PanelButtonCommand
interior.element=tab
frame.element=tab
indicator.element=tab
indicator.size=12
text.margin.left=10
text.margin.right=10
text.margin.top=2
text.margin.bottom=2
text.normal.color={P["text_dim"]}
text.focus.color={t}
text.press.color={w}
text.toggle.color={w}
focusFrame=false
min_height=1.9font

[TabFrame]
inherits=PanelButtonCommand
frame=true
frame.element=tabframe
interior=false

[TabBarFrame]
inherits=GenericFrame
frame=false
interior=false
text.shadow=0

[TreeExpander]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.size=12
indicator.element=arrow

[HeaderSection]
inherits=PanelButtonCommand
frame.element=header
interior.element=header
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.margin.top=4
text.margin.bottom=4
text.margin.left=6
text.margin.right=6
text.normal.color={P["text_dim"]}
text.focus.color={t}
text.press.color={w}
text.toggle.color={t}
indicator.element=arrow
indicator.size=10

[SizeGrip]
indicator.element=resize-grip

[Toolbar]
inherits=PanelButtonCommand
indicator.element=toolbar
indicator.size=5
text.margin=0
interior.element=toolbar
frame.element=toolbar
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.normal.color={t}
text.focus.color={w}

[Slider]
inherits=PanelButtonCommand
frame.element=slider
interior.element=slider
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2

[SliderCursor]
inherits=PanelButtonCommand
frame=false
interior.element=slidercursor

[Progressbar]
inherits=PanelButtonCommand
frame.element=progress
interior.element=progress
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3
text.margin=0
text.normal.color={t}
text.focus.color={w}
text.press.color={w}
text.toggle.color={w}
text.bold=false

[ProgressbarContents]
inherits=PanelButtonCommand
frame=true
frame.element=progress-pattern
interior.element=progress-pattern
frame.top=3
frame.bottom=3
frame.left=3
frame.right=3

[ItemView]
inherits=PanelButtonCommand
text.margin=true
frame.element=itemview
interior.element=itemview
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
text.margin.top=2
text.margin.bottom=2
text.margin.left=4
text.margin.right=4
text.normal.color={t}
text.focus.color={w}
text.press.color={w}
text.toggle.color={w}

[Splitter]
indicator.size=32

[Scrollbar]
inherits=PanelButtonCommand
indicator.element=arrow
indicator.size=10

[ScrollbarSlider]
inherits=PanelButtonCommand
frame.element=scrollbarslider
interior.element=scrollbarslider
frame.left=4
frame.right=4
frame.top=4
frame.bottom=4
indicator.element=grip
indicator.size=0

[ScrollbarGroove]
inherits=PanelButtonCommand
interior=false
frame=false

[MenuItem]
inherits=PanelButtonCommand
frame=true
frame.element=menuitem
interior.element=menuitem
indicator.element=menuitem
frame.top=5
frame.bottom=5
frame.left=5
frame.right=5
text.normal.color={t}
text.focus.color={w}
text.press.color={w}
text.toggle.color={w}
text.margin.top=0
text.margin.bottom=0
text.margin.left=4
text.margin.right=4
min_height=26

[MenuBar]
inherits=PanelButtonCommand
frame.element=menubar
interior.element=menubar
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1

[MenuBarItem]
inherits=PanelButtonCommand
interior=true
interior.element=menubaritem
frame.element=menubaritem
frame.top=5
frame.bottom=5
frame.left=5
frame.right=5
text.margin.left=4
text.margin.right=4
text.margin.top=0
text.margin.bottom=0
text.normal.color={t}
text.focus.color={w}
text.press.color={w}
text.toggle.color={w}

[TitleBar]
inherits=PanelButtonCommand
frame=false
interior=false
indicator.size=12
indicator.element=mdi
text.normal.color={P["text_dis"]}
text.focus.color={t}
text.bold=true

[ComboBox]
inherits=PanelButtonCommand
text.margin.left=6
text.margin.right=4

[Menu]
inherits=PanelButtonCommand
frame.top=8
frame.bottom=8
frame.left=8
frame.right=8
frame.element=menu
interior.element=menu
text.normal.color={t}
text.shadow=0

[GroupBox]
inherits=GenericFrame
frame=true
frame.element=group
interior=false
text.shadow=0
text.margin=0
frame.top=8
frame.bottom=8
frame.left=8
frame.right=8
text.normal.color={t}
text.press.color={t}
text.focus.color={t}
text.bold=true

[ToolTip]
inherits=GenericFrame
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
interior=true
text.shadow=0
text.margin=2
interior.element=tooltip
frame.element=tooltip
text.normal.color={t}

[StatusBar]
inherits=GenericFrame
frame=false
interior=false

[Window]
interior=false
frame=false

[Dialog]
interior=false
frame=false
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    svg, stripped, n = build_svg()
    with open(os.path.join(OUT, f"{NAME}.svg"), "w", encoding="utf-8") as f:
        f.write(svg)
    with open(os.path.join(OUT, f"{NAME}.kvconfig"), "w", encoding="utf-8") as f:
        f.write(build_kvconfig())
    import shutil
    shutil.copy(os.path.join(HERE, "base", "COPYING-kvantum-data-GPL3"), os.path.join(OUT, "COPYING"))
    print(f"wrote {OUT}: {n} generated ids, {stripped} superseded base ids stripped")


if __name__ == "__main__":
    main()
