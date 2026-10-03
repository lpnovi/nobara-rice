# Nobara Enhanced Purple — application theme (Kvantum + color scheme)

Qt application look (Dolphin, System Settings, Kate, …) on the source laptop:

| Layer | Repo path | Installed to | Controls |
|---|---|---|---|
| KDE color scheme | `kde/color-schemes/NobaraEnhancedPurple.colors` | `~/.local/share/color-schemes/` | Kirigami/QML parts, KColorScheme lookups, titlebar colors (`kdeglobals [General] ColorScheme`) |
| Kvantum theme | `kde/kvantum/NobaraEnhancedPurple/` (generated, committed) | `~/.config/Kvantum/NobaraEnhancedPurple/` | Qt Widgets + every QQC2 control drawn through QStyle |
| Kvantum selection | `kde/kvantum/kvantum.kvconfig` | `~/.config/Kvantum/kvantum.kvconfig` | `theme=NobaraEnhancedPurple` |
| App style | `kde/config/kdeglobals.ini` | `kdeglobals [KDE] widgetStyle=kvantum`, `frameContrast=0.12` | global Qt 6 style |

Needs the `kvantum` package (Arch `extra/kvantum`; it provides the Qt 6 style plugin).

## Editing
The palette is at the top of `gen_kvantum.py`; keep it in sync with the `.colors` file.
```bash
python3 kde/kvantum/gen_kvantum.py                                  # writes ~/.config/Kvantum/NobaraEnhancedPurple
KVANTUM_OUT=kde/kvantum/NobaraEnhancedPurple python3 kde/kvantum/gen_kvantum.py   # refresh the committed copy
```
Restart the app afterwards. Output was verified byte-identical to the live theme.

Base: **KvSimplicityDark** by Tsu Jan (kvantum-data 1.1.6, GPL-3.0-or-later) in `base/`. Only rarely
visible elements come from it (recolored); everything visible in Dolphin/System Settings is generated.
The generated theme is therefore GPL-3.0-or-later as well (`NobaraEnhancedPurple/COPYING`).

## Revert
```bash
plasma-apply-colorscheme BreezeDark
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
```
or run `./uninstall.sh` (restores the files backed up by `./install.sh`).
