#!/usr/bin/env bash
# privacy-check.sh — scan the repo for things that should not be published.
# Read-only. Exit code 1 if anything suspicious is found. Run before every commit/push.
set -uo pipefail
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
cd "$REPO"
hits=0
check() { # label regex [extra file to exclude]
  local out
  out=$(grep -rInE --exclude-dir=.git --exclude=privacy-check.sh --exclude='*.png' \
        --exclude='*.jpg' --exclude='*.svgz' ${3:+--exclude="$3"} -e "$2" . 2>/dev/null | head -20)
  if [[ -n $out ]]; then printf '\n\033[1;33m[%s]\033[0m\n%s\n' "$1" "$out"; hits=1; fi
}

check "home paths"        "/home/[a-z_][a-z0-9_-]*|/Users/[A-Za-z]"
# LICENSE intentionally names the copyright holder (the GitHub account that owns the repo).
check "this user's name"  "\\b$(id -un)\\b" LICENSE
check "e-mail addresses"  "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
check "private keys"      "BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE"
check "tokens / API keys" "(gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-|AIza[0-9A-Za-z_-]{30,})"
check "secret-like keys"  "(password|passwd|secret|token|api[_-]?key|psk)\\s*[=:]"
check "disk UUIDs"        "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
check "MAC addresses"     "\\b([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\\b"
check "location / weather station" "placeInfo|placeDisplayName|latitude|longitude"

# Image metadata (EXIF can carry GPS, camera serials, user names)
if command -v exiftool >/dev/null; then
  meta=$(exiftool -q -q -r -if '$GPSLatitude or $Artist or $OwnerName or $SerialNumber' \
         -GPSLatitude -Artist -OwnerName -SerialNumber -ext jpg -ext png . 2>/dev/null)
  [[ -n $meta ]] && { printf '\n\033[1;33m[image metadata]\033[0m\n%s\n' "$meta"; hits=1; }
elif command -v identify >/dev/null; then
  for f in $(find . -path ./.git -prune -o \( -name '*.jpg' -o -name '*.png' \) -print); do
    identify -verbose "$f" 2>/dev/null | grep -qiE 'exif:(GPS|Artist|Owner|BodySerial)' \
      && { echo "[image metadata] $f"; hits=1; }
  done
fi

# Large files
big=$(find . -path ./.git -prune -o -type f -size +5M -print)
[[ -n $big ]] && { printf '\n\033[1;33m[files > 5 MB]\033[0m\n%s\n' "$big"; hits=1; }

(( hits )) && echo -e "\nReview the matches above (some may be intentional, e.g. documentation)." \
           || echo "privacy-check: nothing suspicious found"
exit $hits
