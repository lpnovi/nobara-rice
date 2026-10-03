# Manual setup on CachyOS / Arch (KDE Plasma 6, Wayland)

`./install.sh` automates all of this with backups and prompts. This is the same procedure by hand, for
when you want to apply only parts of it or debug a step. Run everything from the repo root as your normal
user, inside a Plasma **Wayland** session. Paths: `~/.config` = `$XDG_CONFIG_HOME`, `~/.local/share` = `$XDG_DATA_HOME`.

## 0. Before you start
```bash
tar -C ~ -czf ~/plasma-config-before-rice.tar.gz \
  .config/kdeglobals .config/kwinrc .config/plasmarc .config/plasmashellrc \
  .config/plasma-org.kde.plasma.desktop-appletsrc .config/kcminputrc \
  .config/ksplashrc .config/kscreenlockerrc .config/breezerc 2>/dev/null
```

## 1. Packages
```bash
sudo pacman -S --needed kvantum ghostty python rsync git curl unzip kdeplasma-addons qt6-tools
paru -S --needed kwin-effect-rounded-corners-git ttf-geist ttf-geist-mono candy-icons-git \
     catppuccin-cursors-mocha inputactions-kwin plasma6-applets-plasmusic-toolbar
# optional apps: sudo pacman -S steam ; paru -S helium-browser-bin
```
(`paru` ships with CachyOS; `yay` works the same.) Package names were verified against archlinux.org and
the AUR on 2026-10-02.

## 2. Plasma Style
```bash
mkdir -p ~/.local/share/plasma/desktoptheme
cp -r kde/plasma-style/Nobara kde/plasma-style/Nobara-Enhanced ~/.local/share/plasma/desktoptheme/
plasma-apply-desktoptheme Nobara          # the live choice; Nobara-Enhanced is the rounder alternate
```
`Nobara` is the unmodified stock style from Nobara's `kde-nobara` 6.7.4 package (GPLv2+), vendored because
Arch doesn't have it. `Nobara-Enhanced` differs in three SVGs (panel radius 6, popup radius 10 with hairline
and sheen, rounded snap outline); regenerate them with `kde/plasma-style/tools/gen.py`:
```bash
T=$(mktemp -d)
zcat kde/plasma-style/Nobara/widgets/panel-background.svgz > $T/widgets_panel-background.svg
zcat kde/plasma-style/Nobara/dialogs/background.svgz      > $T/dialogs_background.svg
python3 kde/plasma-style/tools/gen.py $T      # writes $T/out_*.svg; gzip into Nobara-Enhanced/*.svgz
```

## 3. Colors + application style (Kvantum)
```bash
install -Dm644 kde/color-schemes/NobaraEnhancedPurple.colors ~/.local/share/color-schemes/NobaraEnhancedPurple.colors
plasma-apply-colorscheme NobaraEnhancedPurple
mkdir -p ~/.config/Kvantum && cp -r kde/kvantum/NobaraEnhancedPurple ~/.config/Kvantum/
kwriteconfig6 --file ~/.config/Kvantum/kvantum.kvconfig --group General --key theme NobaraEnhancedPurple
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
kwriteconfig6 --file kdeglobals --group KDE --key frameContrast 0.12
```
Restart apps to see it. To regenerate the theme after palette edits: `python3 kde/kvantum/gen_kvantum.py`.

## 4. Icons, cursor, fonts and the remaining keys
```bash
/usr/lib/plasma-changeicons candy-icons
plasma-apply-cursortheme catppuccin-mocha-mauve-cursors
```
Every other rice key is in `kde/config/<rcfile>.ini` (only the keys this rice changes). Apply each with
`kwriteconfig6 --file <rcfile> --group <Group> --key <key> <value>`, e.g.
```bash
kwriteconfig6 --file kdeglobals --group General --key font "Geist,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
```
| Setting | Value |
|---|---|
| General / menu / toolbar font | Geist 11 |
| Fixed-width | Geist Mono 10 |
| Small | Geist 9 |
| Window title | Geist 10 |
| Rendering | antialias on, hinting slight, subpixel RGB |
| Animation speed | 0.75 (`AnimationDurationFactor`, in kdeglobals and kwinrc) |
| Decoration | Breeze, button size Large, title left, shadow Medium, outline off, buttons right `HIAX`, border Normal |
| Default terminal | Ghostty (`TerminalApplication=/usr/bin/ghostty --gtk-single-instance=true`) |

GTK apps follow automatically (Plasma rewrites `~/.config/gtk-{3,4}.0/settings.ini`).

## 5. KWin effects, rounded corners, tiling
```bash
mkdir -p ~/.local/share/kwin/effects
cp -r kde/kwin/effects/kwin6_effect_ripple kde/kwin/effects/local_quicktile_glide ~/.local/share/kwin/effects/
# kde/config/kwinrc.ini sets: blur, ripple, local_quicktile_glide, magiclamp, wobblywindows, translucency on;
# scale, squash, shakecursor off; kwin_gestures, ghostty-geometry on; [Round-Corners] Size=10;
# overview hot corner off; touch top edge = lock screen; Night Light 4400 K.
qdbus6 org.kde.KWin /KWin reconfigure
```
- **Rounded corners**: provided by `kwin-effect-rounded-corners-git` (step 1). See
  `kde/kwin/rounded-corners/README.md` for exactly how it produces the Steam/Helium corners, the
  source-build fallback and the **rebuild-after-kwin-update** requirement.
- **Tiling layout** (Meta+T): three columns 25 % / 50 % / 25 %, padding 4. KWin stores it per desktop/screen
  UUID in `kwinrc [Tiling][<desktop>][<output>]` as
  `tiles={"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}`, `padding=4`.
  Set it in the editor, or let `install.sh` write it into the existing groups, then relog.

## 6. Splash, lock screen, login screen
```bash
cp -r kde/splash/nobara-enhanced.splash ~/.local/share/plasma/look-and-feel/
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file ksplashrc --group KSplash --key Theme nobara-enhanced.splash
```
Lock screen: System Settings → Screen Locking → Appearance (or `wallpapers/lockscreen.jpg` + `install.sh`).
Login screen: CachyOS's display manager is configured separately (System Settings → Login Screen); on the
laptop it showed the lock-screen image. Not automated.

## 7. Plasmoids and the launcher fork
```bash
mkdir -p ~/.local/share/plasma/plasmoids
cp -r kde/plasmoids/local.lpnovi.taskiconhover kde/plasmoids/org.kde.plasma.windowtitlereborn ~/.local/share/plasma/plasmoids/
python3 kde/launcher/build.py     # builds ~/.local/share/plasma/plasmoids/local.lpnovi.kickoff
```
To switch an existing Kickoff to the fork: `kde/launcher/apply.sh`; back: `kde/launcher/revert.sh [--purge]`.

## 8. Panels
Either the script (back up `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` first):
```bash
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  "var REPLACE_PANELS=true; var KICKOFF_ICON=\"$HOME/.local/share/nobara-rice/nobara-logo.png\"; $(cat kde/panels/layout.js)"
```
(copy `assets/nobara-logo.png` to that path first). It prints `PANEL_IDS <top> <dock>`. Then, with plasmashell stopped:
```bash
systemctl --user stop plasma-plasmashell
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel <top>" --key floatingApplets 1
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel <top>" --key panelOpacity 2
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel <dock>" --key panelOpacity 2
systemctl --user start plasma-plasmashell
```
…or build them by hand from `kde/panels/appletsrc.reference` / `plasmashellrc.reference`:
- **Top**: top edge, 36 px, not floating, floating applets on, translucent, dodge windows. Kickoff fork
  (icon `assets/nobara-logo.png`) · Window Title Reborn (custom size 27, fixed length 438, hide when no
  window) · spacer · PlasMusic Toolbar · System Tray (Notifications hidden) · Weather (your location) · Digital Clock.
- **Bottom**: bottom edge, 50 px, floating, fit content, translucent, dodge windows. Icon-only Task Manager
  (spacing 0, pinned apps) + "Task Icon Hover (local)" (invisible except in Edit Mode).

## 9. Ghostty
```bash
mkdir -p ~/.config/ghostty/themes
cp ghostty/config.ghostty ~/.config/ghostty/ && cp ghostty/themes/nobara-enhanced ~/.config/ghostty/themes/
ghostty +validate-config
```
Geometry memory (reopens at last size/position):
```bash
cp -r kde/kwin/scripts/ghostty-geometry ~/.local/share/kwin/scripts/
install -Dm755 kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync ~/.local/bin/ghostty-geometry-sync
install -Dm644 kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync.service ~/.config/systemd/user/ghostty-geometry-sync.service
kwriteconfig6 --file kwinrc --group Plugins --key ghostty-geometryEnabled true
systemctl --user daemon-reload && systemctl --user enable --now ghostty-geometry-sync.service
```
Don't add a KWin "Remember size" window rule for Ghostty — it fights the script.

## 10. Touchpad gesture (InputActions)
```bash
install -Dm644 extras/inputactions/config.yaml ~/.config/inputactions/config.yaml
kwriteconfig6 --file kwinrc --group Plugins --key kwin_gesturesEnabled true
```
4-finger horizontal swipe = volume. `inputactions-kwin` must be rebuilt after kwin updates.

## 11. Log out and back in.

## Hardware-specific values from the laptop (re-tune on the new PC)
| Setting | Laptop | Where |
|---|---|---|
| Display | 2880×1800, Xwayland scale 1.6 | System Settings → Display |
| Touchpad | natural scroll, acceleration 0.35, scroll factor 0.1 | System Settings → Touchpad |
| Mouse | acceleration 0.2, flat profile | System Settings → Mouse |
| Virtual desktops | 1 | System Settings → Virtual Desktops |

## Boot menu
The old laptop used a themed rEFInd (`refind/`). It is machine-specific (UUIDs, two ESPs) and not part of
the CachyOS restore. See `refind/README.md` only if you deliberately want rEFInd again.
