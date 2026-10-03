#!/usr/bin/env bash
# install.sh — restore the nobara-rice KDE Plasma 6 look on CachyOS / Arch (user level).
#
#   ./install.sh --dry-run        show every action, change nothing
#   ./install.sh                  interactive: asks before each step
#   ./install.sh --yes            accept each step's default answer (panels stay untouched)
#
# Options:
#   --dry-run          print actions only
#   --yes, -y          non-interactive; use the default answer for every question
#   --no-packages      skip pacman/AUR package installation
#   --with-apps        also install the optional apps (Steam, Helium) — see install/packages-optional.txt
#   --replace-panels   the panel step defaults to "yes, replace existing panels" (fresh installs)
#   --help
#
# Safety rules:
#   * Every file/folder is backed up before it is replaced, to ~/.local/state/nobara-rice/backup-<ts>/,
#     and recorded in a manifest there. ./uninstall.sh undoes an install using that manifest.
#   * KDE settings are written key by key (kwriteconfig6); other keys in the same files are untouched.
#   * Never copies whole ~/.config, never touches other applications' settings.
#   * Never runs the AUR helper as root, never touches the bootloader (rEFInd is a separate, manual step).
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}
TS=$(date +%Y%m%d-%H%M%S)
BK=$STATE/nobara-rice/backup-$TS
MANIFEST=$BK/manifest.txt
WALLDIR=$DATA/wallpapers/nobara-rice

DRY=0 YES=0 PKGS=1 APPS=0 REPLACE_DEFAULT=n
for a in "$@"; do
  case $a in
    --dry-run) DRY=1 ;;
    -y|--yes) YES=1 ;;
    --no-packages) PKGS=0 ;;
    --with-apps) APPS=1 ;;
    --replace-panels) REPLACE_DEFAULT=y ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown option: $a (see --help)"; exit 2 ;;
  esac
done

say()  { printf '\n\033[1;35m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*" >&2; }
run()  { if (( DRY )); then echo "    [dry-run] $*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

ask() { # question default(y|n)
  local def=$2 hint reply
  if (( YES )); then [[ $def == y ]]; return; fi
  if (( DRY )); then info "(dry-run: assuming default '$def' for: $1)"; [[ $def == y ]]; return; fi
  [[ $def == y ]] && hint="[Y/n]" || hint="[y/N]"
  read -r -p "$(printf '\033[1;36m  ? %s %s \033[0m' "$1" "$hint")" reply || reply=""
  [[ ${reply:-$def} =~ ^[Yy] ]]
}

# ---- backup + manifest -------------------------------------------------------------
declare -A TRACKED=()
# Record a path before it is first modified: back it up ("replaced") or note it is new ("created").
track() {
  local p rel
  for p in "$@"; do
    [[ -n ${TRACKED[$p]:-} ]] && continue
    TRACKED[$p]=1
    [[ $p == "$HOME"/* ]] || { warn "refusing to track a path outside \$HOME: $p"; continue; }
    rel=${p#"$HOME"/}
    if [[ -e $p || -L $p ]]; then
      run mkdir -p "$BK/files/$(dirname "$rel")"
      run cp -a "$p" "$BK/files/$rel"
      (( DRY )) || echo "replaced $rel" >>"$MANIFEST"
      info "backed up ~/$rel"
    else
      (( DRY )) || echo "created $rel" >>"$MANIFEST"
    fi
  done
}

install_dir() { # src dst
  track "$2"
  run mkdir -p "$(dirname "$2")"
  [[ -e $2 ]] && run rm -rf -- "$2"      # backed up by track
  run cp -r "$1" "$2"
  info "installed ${2/#$HOME/\~}"
}

install_file() { # src dst [mode]
  track "$2"
  run install -D -m "${3:-644}" "$1" "$2"
  info "installed ${2/#$HOME/\~}"
}

kwrite() { # file group... -- key value   (thin wrapper; file is relative to ~/.config unless absolute)
  local f=$1; shift
  [[ $f == /* ]] && track "$f" || track "$CFG/$f"
  run kwriteconfig6 --file "$f" "$@"
}

# Apply one kde/config/*.ini key by key. Header [A][B] -> --group A --group B.
apply_fragment() { # file.ini
  local ini=$1 rc line key val rest; rc=$(basename "$ini" .ini)
  local groups=()
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line || $line == \#* ]] && continue
    if [[ $line == \[* ]]; then
      groups=(); rest=$line
      while [[ $rest =~ ^\[([^]]*)\](.*)$ ]]; do groups+=(--group "${BASH_REMATCH[1]}"); rest=${BASH_REMATCH[2]}; done
      continue
    fi
    key=${line%%=*}; val=${line#*=}
    val=${val//@WALLPAPER_DIR@/$WALLDIR}; val=${val//@HOME@/$HOME}
    if [[ $val == file://$WALLDIR/* && ! -f ${val#file://} ]]; then
      info "skipping $rc $key: ${val#file://} not present (no wallpaper provided)"; continue
    fi
    kwrite "$rc" "${groups[@]}" --key "$key" -- "$val"
  done <"$ini"
  info "applied kde/config/$(basename "$ini") -> ~/.config/$rc"
}

QDBUS=$(command -v qdbus6 || command -v qdbus || echo /usr/lib/qt6/bin/qdbus)
restart_plasmashell() {
  if systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
    run systemctl --user restart plasma-plasmashell.service
  else
    run kquitapp6 plasmashell || true; run kstart plasmashell
  fi
}

# ===================================================================================
cat <<EOF

  nobara-rice installer (CachyOS / Arch, KDE Plasma 6, Wayland)
  repo:    $REPO
  backups: $BK
$( (( DRY )) && echo "  mode:    DRY RUN — nothing is changed")
  Undo later with: ./uninstall.sh   (restores everything backed up by this run)
EOF

# ---- 0. preflight ------------------------------------------------------------------
say "0. Checks"
. /etc/os-release 2>/dev/null || true
IS_ARCH=0
if [[ -f /etc/arch-release || " ${ID:-} ${ID_LIKE:-} " == *" arch "* ]]; then IS_ARCH=1; fi
info "distro: ${PRETTY_NAME:-unknown} (ID=${ID:-?})$( ((IS_ARCH)) && echo ' — Arch-based OK')"
[[ ${ID:-} == cachyos ]] || info "(not CachyOS; fine on any Arch-based distro)"
if (( ! IS_ARCH )); then
  warn "Not an Arch-based system: package installation is disabled. Install the equivalents by hand (see README)."
  PKGS=0
fi
have kwriteconfig6 || { echo "kwriteconfig6 not found — this needs KDE Plasma 6."; exit 1; }
if have plasmashell; then info "Plasma: $(plasmashell --version 2>/dev/null | awk '{print $2}')  (rice made on 6.7.4)"; fi
[[ ${XDG_SESSION_TYPE:-} == wayland ]] || warn "Session is '${XDG_SESSION_TYPE:-unset}', not Wayland. The rice targets Plasma Wayland."
if [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
  warn "Not running inside a Plasma session (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})."
  warn "Files can still be installed, but panel/KWin steps need a running Plasma session."
  ask "Continue anyway?" n || exit 0
fi
[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root (sudo is used only for pacman)."; exit 1; }
if (( ! DRY )); then mkdir -p "$BK"; { echo "# nobara-rice install $TS"; echo "repo $REPO"; } >"$MANIFEST"; fi

# ---- 1. packages -------------------------------------------------------------------
NOCONF=(); (( YES )) && NOCONF=(--noconfirm)
pkglist() { sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$'; }
say "1. Packages"
if (( PKGS )); then
  mapfile -t OFF < <(pkglist "$REPO/install/packages-official.txt")
  mapfile -t AUR < <(pkglist "$REPO/install/packages-aur.txt")
  info "official: ${OFF[*]}"
  info "AUR:      ${AUR[*]}"
  if ask "Install official packages with sudo pacman -S --needed?" y; then
    run sudo pacman -S --needed "${NOCONF[@]}" "${OFF[@]}" || warn "pacman reported a problem — continuing"
  fi
  HELPER=$(command -v paru || command -v yay || true)
  if [[ -z $HELPER ]]; then
    warn "No AUR helper (paru/yay) found. CachyOS ships paru: sudo pacman -S paru. Then re-run, or install by hand: ${AUR[*]}"
  elif ask "Build/install AUR packages with $(basename "$HELPER")? (rounded corners, fonts, icons, cursors, gestures, music widget)" y; then
    run "$HELPER" -S --needed "${NOCONF[@]}" "${AUR[@]}" || warn "$(basename "$HELPER") reported a problem — continuing"
  fi
  if (( APPS )); then
    mapfile -t OPT < <(pkglist "$REPO/install/packages-optional.txt")
    if [[ -n $HELPER ]] && ask "Install optional apps (${OPT[*]})?" y; then
      run "$HELPER" -S --needed "${NOCONF[@]}" "${OPT[@]}" || warn "optional apps: problem — continuing"
    fi
  fi
else
  info "skipped (--no-packages or not Arch). Required: see install/packages-*.txt"
fi

# ---- 2. Plasma Style ---------------------------------------------------------------
say "2. Plasma Style: Nobara (stock, vendored — CachyOS doesn't ship it) + Nobara-Enhanced (alternate)"
if ask "Install both styles to ~/.local/share/plasma/desktoptheme?" y; then
  install_dir "$REPO/kde/plasma-style/Nobara"          "$DATA/plasma/desktoptheme/Nobara"
  install_dir "$REPO/kde/plasma-style/Nobara-Enhanced" "$DATA/plasma/desktoptheme/Nobara-Enhanced"
fi

# ---- 3. colors + Kvantum -----------------------------------------------------------
say "3. Application theme: NobaraEnhancedPurple color scheme + Kvantum theme"
if ask "Install the color scheme and Kvantum theme?" y; then
  install_file "$REPO/kde/color-schemes/NobaraEnhancedPurple.colors" "$DATA/color-schemes/NobaraEnhancedPurple.colors"
  install_dir  "$REPO/kde/kvantum/NobaraEnhancedPurple" "$CFG/Kvantum/NobaraEnhancedPurple"
  kwrite "$CFG/Kvantum/kvantum.kvconfig" --group General --key theme NobaraEnhancedPurple
  have kvantummanager || warn "kvantum is not installed yet — widgetStyle=kvantum needs it (pacman -S kvantum)"
fi

# ---- 4. splash ---------------------------------------------------------------------
say "4. Splash screen: Nobara Enhanced Splash"
if ask "Install the splash screen?" y; then
  install_dir "$REPO/kde/splash/nobara-enhanced.splash" "$DATA/plasma/look-and-feel/nobara-enhanced.splash"
fi

# ---- 5. KWin effects + scripts -----------------------------------------------------
say "5. KWin: Ripple open/close effect, Quick Tile Glide effect, Ghostty geometry script"
if ask "Install the two JavaScript effects to ~/.local/share/kwin/effects?" y; then
  install_dir "$REPO/kde/kwin/effects/kwin6_effect_ripple"   "$DATA/kwin/effects/kwin6_effect_ripple"
  install_dir "$REPO/kde/kwin/effects/local_quicktile_glide" "$DATA/kwin/effects/local_quicktile_glide"
fi
if ask "Install the Ghostty geometry KWin script + its user service?" y; then
  install_dir  "$REPO/kde/kwin/scripts/ghostty-geometry" "$DATA/kwin/scripts/ghostty-geometry"
  install_file "$REPO/kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync" "$HOME/.local/bin/ghostty-geometry-sync" 755
  install_file "$REPO/kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync.service" \
               "$CFG/systemd/user/ghostty-geometry-sync.service"
  run systemctl --user daemon-reload
  run systemctl --user enable --now ghostty-geometry-sync.service || warn "could not start ghostty-geometry-sync"
fi

# ---- 6. plasmoids + launcher -------------------------------------------------------
say "6. Plasmoids: Task Icon Hover helper, Window Title Reborn, Nobara Enhanced Kickoff fork"
if ask "Install them to ~/.local/share/plasma/plasmoids (the Kickoff fork is built with python3)?" y; then
  install_dir "$REPO/kde/plasmoids/local.lpnovi.taskiconhover"      "$DATA/plasma/plasmoids/local.lpnovi.taskiconhover"
  install_dir "$REPO/kde/plasmoids/org.kde.plasma.windowtitlereborn" "$DATA/plasma/plasmoids/org.kde.plasma.windowtitlereborn"
  track "$DATA/plasma/plasmoids/local.lpnovi.kickoff"
  if have python3; then
    run env KICKOFF_OUT="$DATA/plasma/plasmoids/local.lpnovi.kickoff" python3 -B "$REPO/kde/launcher/build.py"
  else warn "python3 missing — Kickoff fork not built (pacman -S python, then rerun)"; fi
  info "Existing panels are not changed here. Use step 11 (panels) or kde/launcher/apply.sh to switch a launcher."
fi

# ---- 7. Ghostty --------------------------------------------------------------------
say "7. Ghostty config + nobara-enhanced color theme"
if ask "Install ~/.config/ghostty/config.ghostty and themes/nobara-enhanced?" y; then
  install_file "$REPO/ghostty/config.ghostty"           "$CFG/ghostty/config.ghostty"
  install_file "$REPO/ghostty/themes/nobara-enhanced"   "$CFG/ghostty/themes/nobara-enhanced"
  if [[ -f $CFG/ghostty/config ]]; then
    warn "~/.config/ghostty/config also exists and loads BEFORE config.ghostty; config.ghostty wins on conflicts."
  fi
  if have ghostty && ! (( DRY )); then ghostty +validate-config >/dev/null 2>&1 && info "ghostty +validate-config: OK" || warn "ghostty reported a config problem"; fi
fi

# ---- 8. InputActions ---------------------------------------------------------------
say "8. Touchpad gesture: 4-finger horizontal swipe = volume (InputActions)"
if ask "Install ~/.config/inputactions/config.yaml?" y; then
  install_file "$REPO/extras/inputactions/config.yaml" "$CFG/inputactions/config.yaml"
fi

# ---- 9. wallpapers -----------------------------------------------------------------
say "9. Wallpapers (none ship with the repo; drop desktop.jpg / lockscreen.jpg into wallpapers/)"
shopt -s nullglob; imgs=("$REPO"/wallpapers/*.{jpg,jpeg,png,webp}); shopt -u nullglob
if (( ${#imgs[@]} == 0 )); then
  info "no images in wallpapers/ — skipped"
elif ask "Copy ${#imgs[@]} image(s) to ${WALLDIR/#$HOME/\~} and set the desktop wallpaper?" y; then
  run mkdir -p "$WALLDIR"; run cp -n "${imgs[@]}" "$WALLDIR"/
  for d in "$REPO"/wallpapers/desktop.*; do
    [[ -f $d ]] || continue
    track "$CFG/plasma-org.kde.plasma.desktop-appletsrc"
    run plasma-apply-wallpaperimage "$WALLDIR/$(basename "$d")" || warn "could not set wallpaper"
  done
fi

# ---- 10. KDE settings --------------------------------------------------------------
say "10. KDE settings: fonts, icons, cursor, colors, app style, effects, decoration, splash"
info "Only the keys in kde/config/*.ini are written; everything else stays as it is."
if ask "Apply them?" y; then
  for ini in "$REPO"/kde/config/*.ini; do apply_fragment "$ini"; done
  track "$CFG/kdeglobals"
  run plasma-apply-colorscheme NobaraEnhancedPurple || warn "color scheme not applied (step 3 skipped?)"
  run plasma-apply-desktoptheme Nobara              || warn "Plasma Style Nobara not applied (step 2 skipped?)"
  run plasma-apply-cursortheme catppuccin-mocha-mauve-cursors || warn "cursor theme missing (AUR catppuccin-cursors-mocha)"
  for ci in /usr/lib/plasma-changeicons /usr/libexec/plasma-changeicons; do
    [[ -x $ci ]] && { run "$ci" candy-icons || warn "candy-icons missing (AUR candy-icons-git)"; break; }
  done
  [[ -n $(fc-list Geist 2>/dev/null) ]] || warn "Geist fonts not found (AUR ttf-geist ttf-geist-mono)"
  run "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  info "Fonts, splash, cursor and KWin plugins fully apply after logging out and back in."
fi

# ---- 11. tiling layout -------------------------------------------------------------
say "11. KWin custom tiling layout: 25% | 50% | 25%, padding 4 (Meta+T editor)"
TILES='{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'
mapfile -t TGROUPS < <(grep -oE '^\[Tiling\]\[[0-9a-f-]+\]\[[0-9a-f-]+\]$' "$CFG/kwinrc" 2>/dev/null || true)
if (( ${#TGROUPS[@]} == 0 )); then
  info "KWin hasn't created per-screen tiling groups yet (they are keyed by machine UUIDs)."
  info "Open the tile editor once (Meta+T), log out/in, then rerun — or set 25/50/25 + padding 4 by hand."
elif ask "Write the layout to ${#TGROUPS[@]} existing screen/desktop tiling group(s)? (applies after re-login)" y; then
  for g in "${TGROUPS[@]}"; do
    [[ $g =~ ^\[Tiling\]\[([0-9a-f-]+)\]\[([0-9a-f-]+)\]$ ]] || continue
    kwrite kwinrc --group Tiling --group "${BASH_REMATCH[1]}" --group "${BASH_REMATCH[2]}" --key padding 4
    kwrite kwinrc --group Tiling --group "${BASH_REMATCH[1]}" --group "${BASH_REMATCH[2]}" --key tiles "$TILES"
  done
fi

# ---- 12. panels --------------------------------------------------------------------
say "12. Panels: top bar + floating bottom dock  (MAJOR CHANGE)"
info "Rebuilds the panel layout with kde/panels/layout.js. Your panel config is backed up first."
if ask "Create the rice panels now?" "$REPLACE_DEFAULT"; then
  track "$CFG/plasma-org.kde.plasma.desktop-appletsrc" "$CFG/plasmashellrc"
  replace=false
  ask "REMOVE your existing panels first? (no = add the new ones next to them)" "$REPLACE_DEFAULT" && replace=true
  icon=$DATA/nobara-rice/nobara-logo.png
  install_file "$REPO/assets/nobara-logo.png" "$icon"
  script="var REPLACE_PANELS = $replace; var KICKOFF_ICON = \"$icon\";
$(cat "$REPO/kde/panels/layout.js")"
  if (( DRY )); then
    info "[dry-run] $QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript <layout.js>"
    info "[dry-run] then stop plasmashell, set floatingApplets=1 / panelOpacity=2 in plasmashellrc, start it"
  else
    out=$("$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" 2>&1) \
      || warn "plasmashell rejected the script: $out"
    if [[ $out =~ PANEL_IDS\ ([0-9]+)\ ([0-9]+) ]]; then
      topid=${BASH_REMATCH[1]} dockid=${BASH_REMATCH[2]}
      info "created panels: top=$topid dock=$dockid"
      sleep 2
      if systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user stop plasma-plasmashell.service
        while pgrep -x plasmashell >/dev/null; do sleep 0.2; done
        kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $topid"  --key floatingApplets 1
        kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $topid"  --key panelOpacity 2
        kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $dockid" --key panelOpacity 2
        systemctl --user start plasma-plasmashell.service
      else
        warn "plasma-plasmashell.service not found; set 'Floating applets' on the top panel by hand (Edit Mode)."
      fi
    else
      warn "could not read panel ids from plasmashell (output: ${out:-none}); set opacity/floating applets by hand."
    fi
    info "Weather location is personal: right-click the weather widget → Configure."
  fi
fi

# ------------------------------------------------------------------------------------
say "Done"
cat <<EOF
    Backups + manifest: $BK
    Undo this run:      ./uninstall.sh            (or ./uninstall.sh $BK)

    Next: log out and back in (fonts, splash, cursor, KWin effects, rounded corners).
    Check: System Settings → Desktop Effects → "Rounded Corners", "Ripple", "Quick Tile Glide" ticked.

    Not done by this script (see README / docs/setup.md):
      • display scaling, touchpad tuning, Night Light schedule details (hardware-specific)
      • weather location, wallpapers, login-screen (SDDM) theme
      • rEFInd boot menu (refind/README.md — machine-specific, manual)
      • after every kwin update: rebuild kwin-effect-rounded-corners-git and inputactions-kwin
EOF
