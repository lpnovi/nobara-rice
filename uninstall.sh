#!/usr/bin/env bash
# uninstall.sh — undo one ./install.sh run using the manifest it wrote.
#
#   ./uninstall.sh --dry-run            show what would be restored/removed
#   ./uninstall.sh                      undo the most recent install
#   ./uninstall.sh <backup-dir>         undo a specific run (~/.local/state/nobara-rice/backup-<ts>)
#
# For every path the installer touched:
#   replaced <path>  -> the backed-up original is copied back
#   created  <path>  -> the path is deleted (it did not exist before)
# Whole files are restored, so KDE settings you changed in those files AFTER the install are lost too.
# Packages are NOT removed automatically; the commands to do it are printed at the end.
set -euo pipefail

STATE=${XDG_STATE_HOME:-$HOME/.local/state}/nobara-rice
DRY=0 BK=""
for a in "$@"; do
  case $a in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) BK=$a ;;
  esac
done
if [[ -z $BK ]]; then
  BK=$(ls -1d "$STATE"/backup-* 2>/dev/null | sort | tail -1 || true)
fi
[[ -n $BK && -f $BK/manifest.txt ]] || { echo "No install manifest found (looked in $STATE/backup-*)."; exit 1; }

run()  { if (( DRY )); then echo "  [dry-run] $*"; else "$@"; fi; }
echo "Undoing install recorded in: $BK"
(( DRY )) && echo "(dry run — nothing is changed)"

if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
  echo "Stopping plasmashell while panel files are restored…"
  run systemctl --user stop plasma-plasmashell.service
  RESTART_SHELL=1
else RESTART_SHELL=0; fi

# Reverse order, so the newest change is undone first.
tac "$BK/manifest.txt" | while read -r kind rel; do
  [[ $kind == replaced || $kind == created ]] || continue
  [[ -n $rel && $rel != /* && $rel != *..* ]] || { echo "  skipping suspicious entry: $rel"; continue; }
  dst=$HOME/$rel
  case $kind in
    replaced)
      run rm -rf -- "$dst"
      run mkdir -p "$(dirname "$dst")"
      run cp -a "$BK/files/$rel" "$dst"
      echo "  restored ~/$rel" ;;
    created)
      if [[ -e $dst || -L $dst ]]; then run rm -rf -- "$dst"; echo "  removed  ~/$rel"; fi ;;
  esac
done

if [[ -f $HOME/.config/systemd/user/ghostty-geometry-sync.service ]]; then :; else
  run systemctl --user disable --now ghostty-geometry-sync.service 2>/dev/null || true
fi
run systemctl --user daemon-reload || true
(( RESTART_SHELL )) && run systemctl --user start plasma-plasmashell.service
command -v qdbus6 >/dev/null && run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

cat <<'EOF'

Done. Log out and back in so KWin, fonts and themes reload.
Packages were left installed. To remove them as well:
  sudo pacman -Rns kvantum                       # if nothing else uses it
  paru -Rns kwin-effect-rounded-corners-git ttf-geist ttf-geist-mono candy-icons-git \
            catppuccin-cursors-mocha inputactions-kwin plasma6-applets-plasmusic-toolbar
EOF
