# Notes for AI agents working on this repo

This repo is the **canonical backup** of a KDE Plasma 6 Wayland rice whose source laptop (Nobara 44,
Plasma/KWin 6.7.4) has been retired. Target: **CachyOS KDE / Arch**. The owner wants the new machine to
look and behave like the laptop as closely as practical.

## Read first
1. `README.md` — what the rice is, dependencies, caveats.
2. `docs/audit.md` — the live inventory taken on 2026-10-02 (the source of truth for "what was running"),
   with every component classified as portable config / user-local resource / external package /
   external theme / machine-specific.
3. `docs/setup.md` — manual reproduction, step by step (what `install.sh` automates).

## Reproducing on CachyOS
```bash
./install.sh --dry-run            # always first
./install.sh --replace-panels     # interactive; --yes for defaults
```
then log out/in. Verify (Wayland session):
```bash
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadedEffects | grep -E 'shapecorners|ripple|quicktile|magiclamp|wobbly'
kreadconfig6 --file kdeglobals --group KDE --key widgetStyle      # kvantum
kreadconfig6 --file plasmarc --group Theme --key name             # Nobara
```
Expected loaded effects include `kwin4_effect_shapecorners`, `kwin6_effect_ripple`, `local_quicktile_glide`,
`magiclamp`, `wobblywindows`, `translucency`, `blur`, `maximize`, `slide`, `overview`, `windowview`.

## Invariants (owner's preferences — keep them)
- Never copy whole `~/.config`; write KDE settings key by key (`kwriteconfig6`), back up before replacing.
- Never edit `/usr/share` theme files; user-local copies only (`~/.local/share/...`).
- Steam and Helium keep their own integrated top areas: **no** KWin rules or Breeze overrides adding
  titlebars. Rounded corners come only from KDE-Rounded-Corners (`[Round-Corners] Size=10`, rest default).
- Ghostty: keep font family default (JetBrains Mono), size 10, padding 5×5, `right-click-action = paste`.
  Don't add a KWin "Remember size" rule for Ghostty (it fights the `ghostty-geometry` script; it was broken on KWin 6.7 Wayland).
- Launcher fork: purple app-selection strength was deliberately left as is; sidebar pill ~20 % stronger.
- Commits: no "Co-Authored-By: Claude/AI" footer (owner's explicit rule). Repo stays **private** — never
  make it public without explicit approval (Nobara logo terms). Never commit wallpapers (copyright), the
  weather location, personal paths, or anything from browser/Steam/Discord profiles.
- Compiled KWin plugins (rounded corners, InputActions) are installed from AUR/source — never commit `.so` files.

## Where things are
| Want to change | Edit | Then |
|---|---|---|
| Kvantum app theme colors | `kde/kvantum/gen_kvantum.py` palette (+ `kde/color-schemes/NobaraEnhancedPurple.colors`) | `python3 kde/kvantum/gen_kvantum.py` (or `KVANTUM_OUT=kde/kvantum/NobaraEnhancedPurple …` to refresh the committed copy) |
| Launcher look | `kde/launcher/nobara/*.qml` or patches in `kde/launcher/build.py` | `python3 kde/launcher/build.py && systemctl --user restart plasma-plasmashell` |
| Dock hover lift | `kde/plasmoids/local.lpnovi.taskiconhover/contents/ui/{main,HoverFx}.qml` | reinstall folder, restart plasmashell |
| Quick-tile animation | `kde/kwin/effects/local_quicktile_glide/contents/code/main.js` | reinstall, toggle effect or relog |
| Panels | `kde/panels/layout.js` | `install.sh` step 12 |
| Plasma Style corners | `kde/plasma-style/tools/gen.py` → Nobara-Enhanced | see `docs/setup.md` |

Testing visuals without touching the user's session: run a nested
`dbus-run-session kwin_wayland --virtual … --exit-with-session` with a **separate XDG_CONFIG_HOME copy**
(a nested KWin writes to the real `kwinoutputconfig.json` and `kwinrc` otherwise). Plasmoids can be
tested with `plasmawindowed <id>`. Never click power/session buttons in tests.
