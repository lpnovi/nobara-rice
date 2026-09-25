# Licensing

This repository mixes my original work with third-party material. **The MIT license in
[`LICENSE`](LICENSE) covers only my original work.** Everything else keeps its own license, or
is not licensed by me at all.

> **Scope of the MIT license.** [`LICENSE`](LICENSE) covers only the original work of the
> copyright holder named in `LICENSE`. It does **not** cover:
> - the Nobara-Enhanced Plasma Style, which stays GPL-2.0-or-later (§2)
> - other third-party code and assets, which keep their own licenses (§3)
> - the Nobara logo, the Windows logo, or other third-party artwork and trademarks, which
>   remain the property of their respective owners (§4)

## 1. My original work — MIT ([`LICENSE`](LICENSE))

- all scripts: `scripts/`, `refind/install-refind-theme.sh`, `refind/src/*.sh`,
  `kde/plasma-style/tools/gen.py`
- configuration: `kde/config/*.ini`, `kde/panels/`, `ghostty/` (config and the
  `nobara-enhanced` color palette), `extras/inputactions/config.yaml`,
  `refind/config/*.template`, `refind/theme/nobara-purple/theme.conf`
- the Ghostty geometry KWin script and its service: `kde/kwin/scripts/`
- the splash code: `kde/splash/nobara-enhanced.splash/metadata.json` and `Splash.qml`
  (but **not** its `images/logo.png`, see §4)
- my local patch to the Ripple effect: `kde/kwin/effects/kwin6_effect_ripple/local-changes.diff`
- original rEFInd artwork: `refind/theme/nobara-purple/background.png`,
  `selection_big.png`, `selection_small.png`, and the GRUB icon (`refind/src/grub.svg`,
  `icons/os_grub.png`, an original drawing whose layout is modeled on Papirus'
  terminal icon)
- documentation: `README.md`, `LICENSING.md`, `docs/`, and every other `README.md` / `UPSTREAM.md`

## 2. Nobara-Enhanced Plasma Style — GPL-2.0-or-later (not MIT)

`kde/plasma-style/Nobara-Enhanced/` is a modified copy of the **Nobara** Plasma Style by
GloriousEggroll / the Nobara Project (itself based on KDE's Breeze theme). It is distributed
under the **GNU General Public License, version 2 or (at your option) any later version**, the
same as the original. Full text: [`LICENSES/GPL-2.0-or-later.txt`](LICENSES/GPL-2.0-or-later.txt).

My changes (released under the same GPL-2.0-or-later terms as part of this derivative) are:
`widgets/panel-background.svgz`, `dialogs/background.svgz`,
`widgets/translucentbackground.svgz`, and the description in `metadata.json` / `metadata.desktop`.
The original author credit in the metadata is kept. See [`kde/plasma-style/COPYING.md`](kde/plasma-style/COPYING.md).

## 3. Other third-party code and assets (their own licenses)

| Path | Origin | License |
|---|---|---|
| `kde/kwin/effects/kwin6_effect_ripple/` (except `local-changes.diff`) | [kwin-niri-shaders-port](https://github.com/mj0x0/kwin-niri-shaders-port) by liixini and mj0x0 | MIT, see its own [`LICENSE`](kde/kwin/effects/kwin6_effect_ripple/LICENSE) |
| `refind/theme/nobara-purple/font.png` | rEFInd's packaged `liberation-mono-regular-28.png` (glyphs rendered from Liberation Mono) | rEFInd: GPL-3.0-or-later ([`LICENSES/GPL-3.0.txt`](LICENSES/GPL-3.0.txt)); Liberation fonts: SIL OFL 1.1 ([`LICENSES/OFL-1.1.txt`](LICENSES/OFL-1.1.txt)) |
| Window pane geometry in `refind/src/win.svg` and `refind/theme/nobara-purple/icons/os_win.png`, `os_win8.png` | [Papirus icon theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) `distributor-logo-windows.svg` | GPL-3.0 ([`LICENSES/GPL-3.0.txt`](LICENSES/GPL-3.0.txt)). The Windows logo is also a trademark of Microsoft Corporation (see §4). |

## 4. Logos and trademarks — NOT licensed by me

These files contain logos or artwork that belong to their owners. **They aren't covered by my
MIT license, and I grant no rights to them.** They're included only to document and reproduce
a personal desktop setup:

- **Nobara logo** (Nobara Project): `assets/nobara-logo.png`,
  `kde/splash/nobara-enhanced.splash/contents/splash/images/logo.png`,
  `refind/theme/nobara-purple/icons/os_nobara.png`, `os_linux.png`, `os_fedora.png`
- **Windows logo** (Microsoft Corporation): `refind/theme/nobara-purple/icons/os_win.png`,
  `os_win8.png`, `refind/src/win.svg`
- **Screenshots and preview renders** that show those logos: `screenshots/*.png`
- Names such as Nobara, Fedora, Windows, KDE, Plasma and GRUB are trademarks of their
  respective owners.

If you redistribute or fork this repository, check the terms of those projects, or replace
these images with your own.

## 5. Not included

Fonts (Geist, SIL OFL 1.1), icon themes (candy-icons), cursors (Catppuccin), wallpapers and
other dependencies aren't stored here. They're installed from their original sources, under
their own licenses.
