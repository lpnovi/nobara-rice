#!/usr/bin/bash
# Builds the "nobara-purple" rEFInd theme from local, trusted sources:
#   - Nobara mark: /usr/share/icons/hicolor/scalable/places/start-here.svg (nobara-logos RPM)
#   - Windows + GRUB glyphs: simple geometry drawn here
# Output: ./nobara-purple/  (copied to /boot/efi/EFI/refind/themes/nobara-purple/ by phase1)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ACCENT='#A77BFF'   # icon fill
GLOW='#9D6BFF'     # selection ring
DIM='#6E55A8'      # GRUB / advanced (unobtrusive)
T=nobara-purple
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$T/icons"

# Center a glyph PNG on a transparent 256x256 canvas
canvas() { magick -size 256x256 xc:none "$1" -gravity center -composite "$2"; }

# --- Nobara: recolor the packaged vector mark -----------------------------
inkscape /usr/share/icons/hicolor/scalable/places/start-here.svg \
  --export-type=png --export-width=150 --export-filename="$TMP/nobara-w.png" >/dev/null 2>&1
magick "$TMP/nobara-w.png" -fill "$ACCENT" -colorize 100 "$TMP/nobara.png"
canvas "$TMP/nobara.png" "$T/icons/os_linux.png"
cp "$T/icons/os_linux.png" "$T/icons/os_nobara.png"
cp "$T/icons/os_linux.png" "$T/icons/os_fedora.png"

# --- Windows: four panes ---------------------------------------------------
cat >"$TMP/win.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <g fill="$ACCENT">
    <rect x="64"  y="64"  width="61" height="61" rx="5"/>
    <rect x="131" y="64"  width="61" height="61" rx="5"/>
    <rect x="64"  y="131" width="61" height="61" rx="5"/>
    <rect x="131" y="131" width="61" height="61" rx="5"/>
  </g>
</svg>
EOF
inkscape "$TMP/win.svg" --export-type=png --export-width=256 --export-filename="$T/icons/os_win.png" >/dev/null 2>&1
cp "$T/icons/os_win.png" "$T/icons/os_win8.png"

# --- GRUB / Advanced: small, dim terminal glyph ----------------------------
cat >"$TMP/grub.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <g fill="none" stroke="$DIM" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="78" y="88" width="100" height="80" rx="12"/>
    <polyline points="98,112 114,126 98,140"/>
    <line x1="122" y1="146" x2="148" y2="146"/>
  </g>
</svg>
EOF
inkscape "$TMP/grub.svg" --export-type=png --export-width=256 --export-filename="$T/icons/os_grub.png" >/dev/null 2>&1

# --- Selection: soft purple ring with glow (tile = icon*9/8, small = icon*4/3)
ring() { # size radius stroke out
  local s=$1 c=$(( $1 / 2 ))
  magick -size ${s}x${s} xc:none -fill none -stroke "$GLOW" -strokewidth $(( $3 * 3 )) \
    -draw "circle $c,$c $c,$(( c - $2 ))" -channel A -evaluate multiply 0.35 +channel -blur 0x$(( $3 * 2 )) \
    \( -size ${s}x${s} xc:none -fill none -stroke "$GLOW" -strokewidth $3 -draw "circle $c,$c $c,$(( c - $2 ))" \) \
    -composite "$4"
}
ring 288 118 4 "$T/selection_big.png"
ring 128 52 3 "$T/selection_small.png"

# --- Background: pure black at native panel resolution ----------------------
magick -size 2880x1800 xc:black -define png:color-type=2 "$T/background.png"

# --- Font: packaged rEFInd font, larger for the 2880x1800 panel -------------
cp /usr/share/rEFInd/fonts/liberation-mono-regular-28.png "$T/font.png" 2>/dev/null \
  || cp "${REFIND_PKG_ROOT:-}/usr/share/rEFInd/fonts/liberation-mono-regular-28.png" "$T/font.png"

cat >"$T/theme.conf" <<'EOF'
# nobara-purple: black background, purple icons, ring selection, almost no text
icons_dir themes/nobara-purple/icons
banner themes/nobara-purple/background.png
banner_scale fillscreen
selection_big themes/nobara-purple/selection_big.png
selection_small themes/nobara-purple/selection_small.png
font themes/nobara-purple/font.png
big_icon_size 256
small_icon_size 96
hideui hints,arrows,badges,label,singleuser,safemode,hwtest
EOF
# --- v2 main icons (gradient Nobara logo, blue Windows, green GRUB) replace the v1 glyphs above
bash ./build-icons-v2.sh >/dev/null
for n in os_nobara os_linux os_fedora; do cp v2-preview/icons/os_nobara.png "$T/icons/$n.png"; done
for n in os_win os_win8;              do cp v2-preview/icons/os_win.png    "$T/icons/$n.png"; done
cp v2-preview/icons/os_grub.png "$T/icons/os_grub.png"

echo "built: $(find "$T" -type f | wc -l) files, $(du -sh "$T" | cut -f1)"
