#!/usr/bin/env bash
# Restore stock Kickoff in the panel.   revert.sh [--purge]  (--purge also deletes the fork)
set -euo pipefail
HERE=$(dirname "$(readlink -f "$0")")
systemctl --user stop plasma-plasmashell
while pgrep -x plasmashell >/dev/null; do sleep 0.2; done
python3 "$HERE/swap-launcher.py" stock || true
systemctl --user start plasma-plasmashell
if [[ ${1:-} == --purge ]]; then
    rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/local.lpnovi.kickoff"
    echo "fork removed from ~/.local/share/plasma/plasmoids"
fi
echo "stock Kickoff restored"
