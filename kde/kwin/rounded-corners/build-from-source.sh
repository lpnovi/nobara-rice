#!/usr/bin/env bash
# Build + install KDE-Rounded-Corners from source, pinned to the commit the source laptop runs.
# Use only if the AUR package (kwin-effect-rounded-corners-git) is unavailable or broken.
# Must be re-run after every kwin package update.
#   usage: build-from-source.sh [--dry-run] [commit-or-tag]   (default: ee200dd, use "master" for latest)
set -euo pipefail
DRY=0; [[ ${1:-} == --dry-run ]] && { DRY=1; shift; }
REF=${1:-ee200dd456995d93c0a0f4709175a21af3fe1b8a}
SRC=${XDG_CACHE_HOME:-$HOME/.cache}/nobara-rice/KDE-Rounded-Corners
run() { if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi; }

run sudo pacman -S --needed git cmake extra-cmake-modules base-devel ninja vulkan-headers kwin qt6-tools
if [[ -d $SRC/.git ]]; then run git -C "$SRC" fetch --tags origin
else run git clone https://github.com/matinlotfali/KDE-Rounded-Corners.git "$SRC"; fi
run git -C "$SRC" checkout --detach "$REF"
run cmake -S "$SRC" -B "$SRC/build" -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
run cmake --build "$SRC/build"
run sudo cmake --install "$SRC/build"
echo "Installed. Log out/in (or: qdbus6 org.kde.KWin /KWin reconfigure)."
echo "Uninstall later with: sudo cmake --build '$SRC/build' --target uninstall"
