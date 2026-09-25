# Nobara-Enhanced Plasma Style

A user-local copy of Nobara's Plasma Style (GPLv2+, by GloriousEggroll / Nobara Project)
with three assets changed: panel corner radius 6, popup/tooltip background radius 10 with a
hairline border and top sheen, and a new rounded window-snap preview. `/usr/share` is never edited.

- Install: `cp -r Nobara-Enhanced ~/.local/share/plasma/desktoptheme/ && plasma-apply-desktoptheme Nobara-Enhanced`
- Revert: `plasma-apply-desktoptheme Nobara`
- Regenerate the changed SVGs: `tools/gen.py` (see `docs/setup.md` §3)
