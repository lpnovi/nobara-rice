#!/usr/bin/env bash
# Switch the panel launcher to the Nobara Enhanced Kickoff fork (local.lpnovi.kickoff).
# Builds the fork first if it isn't installed. Only the launcher applet's plugin= line changes.
set -euo pipefail
HERE=$(dirname "$(readlink -f "$0")")
PKG=${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/local.lpnovi.kickoff
[[ -f $PKG/metadata.json ]] || python3 "$HERE/build.py"
B=${XDG_STATE_HOME:-$HOME/.local/state}/nobara-rice/launcher-apply-$(date +%Y%m%d-%H%M%S)
mkdir -p "$B" && cp -a "${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc" "$B/"
systemctl --user stop plasma-plasmashell
while pgrep -x plasmashell >/dev/null; do sleep 0.2; done
python3 "$HERE/swap-launcher.py" fork || true
systemctl --user start plasma-plasmashell
echo "applied (appletsrc backup: $B)"
