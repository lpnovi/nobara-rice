#!/usr/bin/bash
# v2 main-screen icons (preview only). Writes to ./v2-preview/, never to nobara-purple/ or the ESP.
#   Nobara : user-supplied logo (WebP despite .png name) -> true RGBA PNG, gradient preserved
#   Windows: Papirus distributor-logo-windows.svg pane geometry, blue gradient + depth
#   GRUB   : Papirus utilities-terminal layout (tile, chevron, underscore), green gradient + depth
# All outputs: 256x256 RGBA PNG (big_icon_size 256), glyph centered like v1.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
NOBARA_SRC="${NOBARA_LOGO:-../../assets/nobara-logo.png}"
WIN_SRC=/usr/share/icons/Papirus/64x64/apps/distributor-logo-windows.svg
O=v2-preview; mkdir -p "$O/icons"
PNG32=(-strip -define png:color-type=6 -define png:bit-depth=8)

# --- Nobara -----------------------------------------------------------------
# Same glyph box as v1 (150 px), aspect preserved, alpha preserved.
magick "$NOBARA_SRC" -trim +repage -filter Lanczos -resize 150x150 \
  -background none -gravity center -extent 256x256 "${PNG32[@]}" "$O/icons/os_nobara.png"

# --- Windows ----------------------------------------------------------------
# Pane path taken verbatim from Papirus (64-unit space, logo box x13-52 y12-51),
# scaled 3.5x -> ~137 px and centered on 256.
PANES=$(grep -o 'fill:#0078d6" d="[^"]*' "$WIN_SRC" | sed 's/.*d="//')
[[ -n $PANES ]] || { echo "could not read pane path from $WIN_SRC"; exit 1; }
cat >"$O/win.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="blue" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0"    stop-color="#6FD0FF"/>
      <stop offset="0.45" stop-color="#1E8CF2"/>
      <stop offset="1"    stop-color="#0052C2"/>
    </linearGradient>
    <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0"    stop-color="#FFFFFF" stop-opacity="0.30"/>
      <stop offset="0.48" stop-color="#FFFFFF" stop-opacity="0.04"/>
      <stop offset="0.52" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <g transform="translate(14.25 17.75) scale(3.5)">
    <path d="$PANES" fill="#082A66" transform="translate(0 1.3)"/>
    <path d="$PANES" fill="url(#blue)"/>
    <path d="$PANES" fill="url(#sheen)"/>
  </g>
</svg>
EOF
inkscape "$O/win.svg" --export-type=png --export-width=256 --export-filename="$O/win-raw.png" >/dev/null 2>&1
magick "$O/win-raw.png" "${PNG32[@]}" "$O/icons/os_win.png"

# --- GRUB / Advanced ----------------------------------------------------------
# Smaller than Nobara/Windows (116 px wide) so it stays secondary.
cat >"$O/grub.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2C8A4C"/>
      <stop offset="1" stop-color="#124A27"/>
    </linearGradient>
    <linearGradient id="glyph" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#B6FFCB"/>
      <stop offset="1" stop-color="#46D57C"/>
    </linearGradient>
    <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0"    stop-color="#FFFFFF" stop-opacity="0.16"/>
      <stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect x="70" y="89" width="116" height="90" rx="14" fill="#06280F"/>
  <rect x="70" y="84" width="116" height="90" rx="14" fill="url(#tile)"/>
  <rect x="70" y="84" width="116" height="90" rx="14" fill="url(#sheen)"/>
  <rect x="71.5" y="85.5" width="113" height="87" rx="12.5" fill="none" stroke="#6BE699" stroke-opacity="0.35" stroke-width="2"/>
  <g fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="9">
    <polyline points="93,110 110,127 93,144" stroke="#0A3318" stroke-opacity="0.6" transform="translate(0 2)"/>
    <line x1="119" y1="146" x2="146" y2="146" stroke="#0A3318" stroke-opacity="0.6" transform="translate(0 2)"/>
    <polyline points="93,110 110,127 93,144" stroke="url(#glyph)"/>
    <line x1="119" y1="146" x2="146" y2="146" stroke="url(#glyph)"/>
  </g>
</svg>
EOF
inkscape "$O/grub.svg" --export-type=png --export-width=256 --export-filename="$O/grub-raw.png" >/dev/null 2>&1
magick "$O/grub-raw.png" "${PNG32[@]}" "$O/icons/os_grub.png"
rm -f "$O"/*-raw.png

# --- Previews: simulate the rEFInd main screen (live theme background + ring) ---
BG=nobara-purple/background.png; RING=nobara-purple/selection_big.png
scene() { # selected-index out [icondir]
  local d=${3:-$O/icons} x0=952 step=360 i=0 args=()
  args=("$BG")
  args+=("$RING" -geometry +$(( x0 - 16 + $1 * step ))+756 -composite)
  for ic in os_nobara os_win os_grub; do
    local f=$d/$ic.png; [[ -f $f ]] || f=$d/os_linux.png
    args+=("$f" -geometry +$(( x0 + i * step ))+772 -composite); i=$((i+1))
  done
  magick "${args[@]}" "$2"
}
scene 0 "$O/preview-full-nobara-selected.png"
scene 1 "$O/preview-full-windows-selected.png"
scene 2 "$O/preview-full-grub-selected.png"
scene 0 "$O/preview-full-v1-current.png" nobara-purple/icons
# 1:1 crops of the icon row (what the 2880x1800 panel actually shows)
for n in nobara windows grub; do
  magick "$O/preview-full-$n-selected.png" -crop 1100x340+890+730 +repage "$O/preview-crop-$n-selected.png"
done
magick "$O/preview-full-v1-current.png" -crop 1100x340+890+730 +repage "$O/preview-crop-v1-current.png"
magick "$O/preview-crop-v1-current.png" "$O/preview-crop-nobara-selected.png" \
       "$O/preview-crop-windows-selected.png" "$O/preview-crop-grub-selected.png" \
       -background '#333' -splice 0x6 -append "$O/preview-compare.png"
for f in "$O"/icons/*.png; do identify -format '%f %wx%h %[channels] %[type]\n' "$f"; done
