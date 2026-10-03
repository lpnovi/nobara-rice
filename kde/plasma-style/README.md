# Plasma Styles

| Folder | Status on the laptop | What |
|---|---|---|
| `Nobara/` | **active** (`plasmarc [Theme] name=Nobara`) | unmodified stock "Nobara" Plasma Style from Nobara's `kde-nobara` 6.7.4 package (GPLv2+, GloriousEggroll / Nobara Project, based on Breeze). Vendored because CachyOS/Arch doesn't ship it. |
| `Nobara-Enhanced/` | installed, alternate | my derivative of Nobara: panel corner radius 6, popup/tooltip radius 10 with hairline + top sheen, rounded window-snap preview. |

- Install: `cp -r Nobara Nobara-Enhanced ~/.local/share/plasma/desktoptheme/ && plasma-apply-desktoptheme Nobara`
- Try the alternate: `plasma-apply-desktoptheme Nobara-Enhanced`
- Regenerate the three changed SVGs of Nobara-Enhanced: `tools/gen.py` (see `docs/setup.md` §2)

Note: the Nobara-Enhanced Kickoff fork draws its own 10 px header/footer corners; its outer popup frame
follows the active Plasma Style's dialog background (sharper with stock Nobara, 10 px with Nobara-Enhanced).
