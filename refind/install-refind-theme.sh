#!/usr/bin/env bash
# install-refind-theme.sh — copy the nobara-purple theme into an EXISTING rEFInd install.
#
# What it does (only with --apply; the default is a dry run that changes nothing):
#   1. backs up  <ESP>/EFI/refind/refind.conf and any existing themes/nobara-purple/
#      to /var/backups/nobara-rice-refind-<timestamp>/
#   2. copies    refind/theme/nobara-purple/ -> <ESP>/EFI/refind/themes/nobara-purple/
#   3. appends   "include themes/nobara-purple/theme.conf" to refind.conf if it is missing
#                (asks first)
#
# What it NEVER does: install rEFInd, run refind-install or efibootmgr, change
# BootOrder/BootNext/NVRAM, edit refind_linux.conf, or touch EFI/fedora,
# EFI/BOOT or EFI/Microsoft. See refind/README.md for those manual steps.
#
# Usage: sudo refind/install-refind-theme.sh [--apply] [--esp /boot/efi]
set -euo pipefail

HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
SRC=$HERE/theme/nobara-purple
ESP=/boot/efi
APPLY=0
while (( $# )); do
  case $1 in
    --apply) APPLY=1 ;;
    --esp)   ESP=$2; shift ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac; shift
done
R=$ESP/EFI/refind
DST=$R/themes/nobara-purple
BK=/var/backups/nobara-rice-refind-$(date +%Y%m%d-%H%M%S)

die()  { echo "ABORT: $*" >&2; exit 1; }
run()  { if (( APPLY )); then "$@"; else echo "  [dry-run] $*"; fi; }

echo "== Pre-flight"
[[ $EUID -eq 0 ]]           || die "run as root (sudo or pkexec) — the ESP is root-only"
[[ -d /sys/firmware/efi ]]  || die "not booted in UEFI mode"
findmnt -n "$ESP" >/dev/null || die "$ESP is not a mount point"
[[ $(findmnt -no FSTYPE "$ESP") == vfat ]] || die "$ESP is not a FAT (EFI system) partition"
[[ -f $R/refind.conf ]]     || die "no $R/refind.conf — install rEFInd first (refind/README.md)"
ls "$R"/refind_x64.efi >/dev/null 2>&1 || die "no refind_x64.efi in $R"
for f in theme.conf background.png selection_big.png selection_small.png font.png \
         icons/os_nobara.png icons/os_linux.png icons/os_win.png icons/os_grub.png; do
  [[ -s $SRC/$f ]] || die "missing $SRC/$f"
done
need=$(du -sk "$SRC" | cut -f1); free=$(df -Pk "$ESP" | awk 'NR==2{print $4}')
(( free > need * 2 )) || die "not enough space on $ESP (${free} KiB free, need ~${need} KiB)"
echo "ok: rEFInd found at $R, ${free} KiB free on the ESP"
(( APPLY )) || echo "DRY RUN — re-run with --apply to make changes"

echo "== Backup -> $BK"
run install -d -m 700 "$BK"
run cp -p "$R/refind.conf" "$BK/refind.conf"
[[ -d $DST ]] && run cp -a "$DST" "$BK/nobara-purple.previous"

echo "== Copy theme -> $DST"
run install -d -m 700 "$DST/icons"
run install -m 600 "$SRC"/*.png "$SRC"/theme.conf "$DST"/
run install -m 600 "$SRC"/icons/*.png "$DST"/icons/
run sync

if grep -qE '^\s*include\s+themes/nobara-purple/theme\.conf' "$R/refind.conf"; then
  echo "== refind.conf already includes the theme"
else
  echo "== refind.conf does not include the theme yet"
  read -r -p "Append 'include themes/nobara-purple/theme.conf' to refind.conf? [y/N] " a || a=""
  if [[ $a =~ ^[Yy] ]]; then
    run sh -c "printf '\n# nobara-rice theme\ninclude themes/nobara-purple/theme.conf\n' >> '$R/refind.conf'"
  else echo "  skipped — add the line yourself when ready"; fi
fi

if (( APPLY )); then
  for f in "$SRC"/*.png "$SRC"/theme.conf "$SRC"/icons/*.png; do
    cmp -s "$f" "$DST/${f#"$SRC"/}" || die "verify failed for ${f#"$SRC"/}"
  done
  echo "== Verified. Undo: cp -p $BK/refind.conf $R/refind.conf"
  [[ -d $BK/nobara-purple.previous ]] && echo "   and: rm -rf $DST && cp -a $BK/nobara-purple.previous $DST"
fi
echo "Boot entries and BootOrder were not touched."
