# rEFInd theme sources

- `build-theme.sh`: builds `./nobara-purple/` (background, selection rings, font, theme.conf, then the v2 icons)
- `build-icons-v2.sh`: gradient Nobara icon (from `assets/nobara-logo.png`, override with `NOBARA_LOGO=`), blue Windows icon, green GRUB icon, plus preview renders in `./v2-preview/`
- `win.svg`, `grub.svg`: the icon sources as generated (Windows pane path from Papirus, GPL-3.0)

Needs ImageMagick 7 (`magick`), Inkscape, `papirus-icon-theme` and `rEFInd-tools` (for the font).
Both output folders are git-ignored. Copy the results into `../theme/nobara-purple/` yourself.
