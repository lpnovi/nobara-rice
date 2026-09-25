#!/usr/bin/env bash
# install.sh — apply the nobara-rice look to the current user's KDE Plasma 6 session.
#
# Safety rules this script follows:
#   * Every step asks first. Steps that are system-level or replace a layout default to "no".
#   * Every file or folder is copied to a timestamped backup before it is changed.
#   * KDE settings are written key-by-key with kwriteconfig6, so other settings
#     in the same file are left alone. Nothing unrelated is deleted.
#   * No hard-coded user names or home paths: it uses $HOME and XDG variables.
#   * The bootloader is NEVER touched here. For rEFInd, see refind/README.md.
#
# Usage: scripts/install.sh [--dry-run]
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}
BK=$STATE/nobara-rice/backup-$(date +%Y%m%d-%H%M%S)
WALLDIR=$DATA/wallpapers/nobara-rice
DRY=0; [[ ${1:-} == --dry-run ]] && DRY=1

say()  { printf '\n\033[1;35m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*" >&2; }
run()  { if (( DRY )); then echo "    [dry-run] $*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

ask() { # question default(y|n)
  local def=$2 hint reply
  [[ $def == y ]] && hint="[Y/n]" || hint="[y/N]"
  read -r -p "$(printf '\033[1;36m  ? %s %s \033[0m' "$1" "$hint")" reply || reply=""
  reply=${reply:-$def}
  [[ $reply =~ ^[Yy] ]]
}

# Copy a file or folder (path under $HOME) into the backup, keeping its relative path.
backup() {
  local p
  for p in "$@"; do
    [[ -e $p ]] || continue
    local rel=${p#"$HOME"/}
    run mkdir -p "$BK/$(dirname "$rel")"
    run cp -a "$p" "$BK/$rel"
    info "backed up ~/$rel"
  done
}

# Install a folder from the repo, backing up any existing one first.
install_dir() { # src dst
  backup "$2"
  run mkdir -p "$(dirname "$2")"
  if [[ -e $2 ]]; then run rm -rf -- "$2"; fi   # already backed up above
  run cp -r "$1" "$2"
  info "installed ${2/#$HOME/\~}"
}

install_file() { # src dst [mode]
  backup "$2"
  run install -D -m "${3:-644}" "$1" "$2"
  info "installed ${2/#$HOME/\~}"
}

# Apply one of kde/config/*.ini key by key. Group headers like [A][B] become --group A --group B.
apply_fragment() { # file.ini
  local ini=$1 rc; rc=$(basename "$ini" .ini)
  backup "$CFG/$rc"
  local groups=() line key val
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line || $line == \#* ]] && continue
    if [[ $line == \[* ]]; then
      groups=()
      local rest=$line
      while [[ $rest =~ ^\[([^]]*)\](.*)$ ]]; do groups+=(--group "${BASH_REMATCH[1]}"); rest=${BASH_REMATCH[2]}; done
      continue
    fi
    key=${line%%=*}; val=${line#*=}
    val=${val//@WALLPAPER_DIR@/$WALLDIR}
    val=${val//@HOME@/$HOME}
    if [[ $val == file://$WALLDIR/* && ! -f ${val#file://} ]] && ! (( DRY )); then
      warn "skipping $rc $key: ${val#file://} not found (no wallpaper provided)"; continue
    fi
    run kwriteconfig6 --file "$rc" "${groups[@]}" --key "$key" -- "$val"
  done <"$ini"
  info "applied $(basename "$ini") -> ~/.config/$rc"
}

# ----------------------------------------------------------------------------
cat <<EOF

  nobara-rice installer
  repo:    $REPO
  backups: $BK
$( (( DRY )) && echo "  mode:    DRY RUN (nothing is changed)")

  Each step asks before doing anything. The bootloader (rEFInd/GRUB) is never touched.
EOF

have kwriteconfig6 || { echo "kwriteconfig6 not found — this needs KDE Plasma 6."; exit 1; }
if [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
  warn "You don't seem to be in a Plasma session (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})."
  ask "Continue anyway?" n || exit 0
fi
if ! (( DRY )); then mkdir -p "$BK"; fi

# 1. Packages ------------------------------------------------------------------
say "1. Packages (system-level, uses sudo dnf)"
PKGS=(geist-font geist-font-mono candy-icon-theme ghostty inputactions git curl unzip)
info "Would install: ${PKGS[*]}"
info "(geist-font / inputactions come from the Terra repo, enabled by default on Nobara.)"
if have dnf && ask "Install these packages with sudo dnf?" n; then
  run sudo dnf install -y "${PKGS[@]}" || warn "dnf reported a problem — continuing"
else info "skipped — see docs/setup.md for manual install"; fi

# 2. Cursor theme ------------------------------------------------------------------
say "2. Cursor theme: Catppuccin Mocha Mauve (downloaded from github.com/catppuccin/cursors)"
CUR=catppuccin-mocha-mauve-cursors
if [[ -d $DATA/icons/$CUR || -d /usr/share/icons/$CUR ]]; then info "already installed"
elif ask "Download and install to ~/.local/share/icons?" y; then
  tmp=$(mktemp -d)
  run curl -fL --proto '=https' -o "$tmp/$CUR.zip" \
      "https://github.com/catppuccin/cursors/releases/latest/download/$CUR.zip"
  run mkdir -p "$DATA/icons"
  run unzip -q "$tmp/$CUR.zip" -d "$DATA/icons"
  rm -rf "$tmp"; info "installed $CUR"
fi

# 3. Plasma Style ----------------------------------------------------------------
say "3. Plasma Style: Nobara-Enhanced (rounder panel/popups/snap outline)"
if ask "Install to ~/.local/share/plasma/desktoptheme?" y; then
  install_dir "$REPO/kde/plasma-style/Nobara-Enhanced" "$DATA/plasma/desktoptheme/Nobara-Enhanced"
fi

# 4. Splash --------------------------------------------------------------------------
say "4. Splash screen: Nobara Enhanced Splash (dark background + Nobara logo)"
SPL=$DATA/plasma/look-and-feel/nobara-enhanced.splash
if ask "Install the splash screen?" y; then
  install_dir "$REPO/kde/splash/nobara-enhanced.splash" "$SPL"
fi

# 5. KWin script + effect ----------------------------------------------------------------
say "5. KWin: Ripple open/close effect + Ghostty geometry memory"
if ask "Install the Ripple effect (~/.local/share/kwin/effects)?" y; then
  install_dir "$REPO/kde/kwin/effects/kwin6_effect_ripple" "$DATA/kwin/effects/kwin6_effect_ripple"
fi
if ask "Install the Ghostty geometry script + its user service?" y; then
  install_dir  "$REPO/kde/kwin/scripts/ghostty-geometry" "$DATA/kwin/scripts/ghostty-geometry"
  install_file "$REPO/kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync" "$HOME/.local/bin/ghostty-geometry-sync" 755
  install_file "$REPO/kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync.service" \
               "$CFG/systemd/user/ghostty-geometry-sync.service"
  run systemctl --user daemon-reload
  run systemctl --user enable --now ghostty-geometry-sync.service || warn "could not start the service"
fi

# 6. Ghostty -----------------------------------------------------------------------------------
say "6. Ghostty config + nobara-enhanced color theme"
if ask "Install ~/.config/ghostty/config.ghostty and the theme?" y; then
  install_file "$REPO/ghostty/config.ghostty" "$CFG/ghostty/config.ghostty"
  install_file "$REPO/ghostty/themes/nobara-enhanced" "$CFG/ghostty/themes/nobara-enhanced"
  have ghostty && { run ghostty +validate-config || warn "ghostty reported a config problem"; }
fi

# 7. Wallpapers ------------------------------------------------------------------------------
say "7. Wallpapers (desktop + lock screen)"
# No images ship with the repo. Drop your own into wallpapers/ (git-ignored):
#   desktop.jpg      -> desktop
#   lockscreen.jpg   -> lock screen (set in step 8)
shopt -s nullglob; imgs=("$REPO"/wallpapers/*.{jpg,jpeg,png,webp}); shopt -u nullglob
if (( ${#imgs[@]} == 0 )); then
  info "no images in wallpapers/ — skipped (see wallpapers/README.md)"
elif ask "Copy ${#imgs[@]} image(s) from wallpapers/ to ${WALLDIR/#$HOME/\~}?" y; then
  run mkdir -p "$WALLDIR"
  run cp -n "${imgs[@]}" "$WALLDIR"/
  for d in "$REPO"/wallpapers/desktop.*; do
    [[ -f $d ]] || continue
    backup "$CFG/plasma-org.kde.plasma.desktop-appletsrc"
    run plasma-apply-wallpaperimage "$WALLDIR/$(basename "$d")" || warn "could not set wallpaper"
  done
fi

# 8. KDE settings --------------------------------------------------------------------------------
say "8. KDE appearance settings (fonts, icons, cursor, effects, decoration, splash, lock screen)"
info "Only the keys in kde/config/*.ini are written; everything else stays as it is."
if ask "Apply them?" y; then
  for ini in "$REPO"/kde/config/*.ini; do apply_fragment "$ini"; done
  run plasma-apply-colorscheme Nobara        || warn "Nobara color scheme not found (not on Nobara?)"
  run plasma-apply-desktoptheme Nobara-Enhanced || true
  run plasma-apply-cursortheme catppuccin-mocha-mauve-cursors || true
  [[ -x /usr/libexec/plasma-changeicons ]] && run /usr/libexec/plasma-changeicons candy-icons
  have qdbus && run qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  info "Some changes (fonts, splash) fully apply after logging out and back in."
fi

# 9. InputActions gesture ---------------------------------------------------------------------------
say "9. Touchpad gesture: 4-finger horizontal swipe = volume (InputActions)"
if ask "Install ~/.config/inputactions/config.yaml?" y; then
  install_file "$REPO/extras/inputactions/config.yaml" "$CFG/inputactions/config.yaml"
fi

# 10. Panels (major change) ------------------------------------------------------------------------
say "10. Panels: top bar + floating bottom dock  (MAJOR CHANGE)"
info "This rebuilds your panel layout with kde/panels/layout.js."
info "Your current panel config is backed up first (plasma-org.kde.plasma.desktop-appletsrc, plasmashellrc)."
if ask "Recreate the panels?" n; then
  backup "$CFG/plasma-org.kde.plasma.desktop-appletsrc" "$CFG/plasmashellrc"
  replace=false
  ask "REMOVE your existing panels first? (no = add the new ones next to them)" n && replace=true
  icon=$DATA/nobara-rice/nobara-logo.png
  run install -D -m 644 "$REPO/assets/nobara-logo.png" "$icon"
  script="var REPLACE_PANELS = $replace; var KICKOFF_ICON = \"$icon\";
$(cat "$REPO/kde/panels/layout.js")"
  if have qdbus; then
    run qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" \
      || warn "plasmashell rejected the script — restore from $BK"
    info "Finish by hand: panel opacity → Translucent, weather location (docs/setup.md)."
  else warn "qdbus not found; run layout.js from the Plasma desktop scripting console instead."; fi
fi

# ------------------------------------------------------------------------------
say "Done"
cat <<EOF
    Backups: $BK
    To undo a file: copy it back from the backup folder (same path relative to your home).

    Not done by this script (see docs/setup.md):
      • Rounded window corners (KDE-Rounded-Corners, built from source)
      • Login-screen wallpaper (System Settings → Login Screen)
      • GRUB theme (Catppuccin) and the rEFInd boot menu (refind/README.md)
      • Display scaling, Night Light schedule, touchpad tuning (hardware-specific)
EOF
