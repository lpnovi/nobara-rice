# Detailed setup

This is the manual path. `scripts/install.sh` automates steps 1–9 of the user-level parts,
with backups and prompts. Anything marked **manual** is never automated.

Tested on: Nobara 44, Plasma 6.7.4, Wayland. On other Fedora-based distros, the Nobara-specific
pieces (global theme, color scheme, logo) come from the `nobara-*` packages and may be missing.

---

## 0. Before you start

```bash
# Keep a copy of your current Plasma config
tar -C ~ -czf ~/plasma-config-before-rice.tar.gz \
  .config/kdeglobals .config/kwinrc .config/plasmarc .config/plasmashellrc \
  .config/plasma-org.kde.plasma.desktop-appletsrc .config/kcminputrc \
  .config/ksplashrc .config/kscreenlockerrc .config/breezerc
```

## 1. Packages

```bash
sudo dnf install geist-font geist-font-mono candy-icon-theme ghostty inputactions
```
Geist and InputActions come from **Terra**, which Nobara enables by default. If you're not on
Nobara, get Geist from <https://github.com/vercel/geist-font/releases> and put the files in
`~/.local/share/fonts/Geist/`, then run `fc-cache -f`.

## 2. Cursor theme

```bash
curl -fLO https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-mauve-cursors.zip
unzip catppuccin-mocha-mauve-cursors.zip -d ~/.local/share/icons/
plasma-apply-cursortheme catppuccin-mocha-mauve-cursors
```

## 3. Plasma Style (Nobara-Enhanced)

```bash
cp -r kde/plasma-style/Nobara-Enhanced ~/.local/share/plasma/desktoptheme/
plasma-apply-desktoptheme Nobara-Enhanced
```
This is a full copy of `/usr/share/plasma/desktoptheme/Nobara` with three assets changed:

| File | Change |
|---|---|
| `widgets/panel-background.svgz` | corner radius 3 → 6 |
| `dialogs/background.svgz` | radius 10, hairline border, subtle top sheen (all popups and tooltips) |
| `widgets/translucentbackground.svgz` (new) | window-snap/tile preview: 8 px radius, soft highlight tint + outline |

`kde/plasma-style/tools/gen.py` regenerates those three from the original SVGs:
```bash
T=$(mktemp -d)
zcat /usr/share/plasma/desktoptheme/Nobara/widgets/panel-background.svgz > $T/widgets_panel-background.svg
zcat /usr/share/plasma/desktoptheme/Nobara/dialogs/background.svgz      > $T/dialogs_background.svg
python3 kde/plasma-style/tools/gen.py $T      # writes $T/out_*.svg
# then gzip each out_*.svg into the matching .svgz inside Nobara-Enhanced/
```
To revert: `plasma-apply-desktoptheme Nobara`.

## 4. Colors, icons, application style, fonts

System Settings or the command line:
```bash
plasma-apply-colorscheme Nobara                 # stock Nobara colors (unmodified)
/usr/libexec/plasma-changeicons candy-icons
```
Then apply the saved keys. Each `kde/config/<file>.ini` holds only the keys this rice changes.
Write them with `kwriteconfig6`, for example:
```bash
kwriteconfig6 --file kdeglobals --group General --key font "Geist,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
```
or let `scripts/install.sh` do all of them (step 8).

| Setting | Value |
|---|---|
| General font | Geist 11 |
| Fixed-width | Geist Mono 10 |
| Small | Geist 9 |
| Toolbar / menu | Geist 11 |
| Window title | Geist 10 |
| Anti-aliasing | on, slight hinting, RGB subpixel |
| Application style | Breeze |
| Animation speed | 0.75 (`AnimationDurationFactor`) |

GTK apps follow automatically. Plasma rewrites `~/.config/gtk-3.0|4.0/settings.ini`
(Breeze GTK, dark preference, same font, icons and cursor).

## 5. Window decoration & effects

- **Decoration:** Breeze, button size *Large*, title *left*, shadow *Medium*, outline *off*,
  buttons on the right: *Keep above · Minimize · Maximize · Close* (`HIAX`), border size *Normal*.
- **Desktop Effects** (System Settings → Window Management → Desktop Effects):
  - ✅ Ripple [Niri Port] (install below), Magic Lamp, Wobbly Windows, Translucency
  - ❌ Scale, Squash, Shake Cursor
- **Screen Edges:** overview hot corner off (`BorderActivate=9`). **Touch Screen:** top edge → Lock Screen.
- **Night Light:** on, 4400 K night temperature (the schedule/location isn't saved; set it again).

### Ripple effect (patched)
```bash
cp -r kde/kwin/effects/kwin6_effect_ripple ~/.local/share/kwin/effects/
kwriteconfig6 --file kwinrc --group Plugins --key kwin6_effect_rippleEnabled true
qdbus org.kde.KWin /KWin reconfigure
```

### Rounded window corners (manual: compiled plugin, system-wide)
```bash
sudo dnf install git cmake gcc-c++ extra-cmake-modules kwin-devel kf6-kconfigwidgets-devel \
     kf6-kcmutils-devel qt6-qtbase-devel
git clone https://github.com/matinlotfali/KDE-Rounded-Corners && cd KDE-Rounded-Corners
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build -j
sudo cmake --install build
```
Then enable **ShapeCorners** in Desktop Effects and set the radius to **10**. Rebuild after
each KWin update. Check the upstream README for the current dependency list.

## 6. Splash & lock screen

```bash
cp -r kde/splash/nobara-enhanced.splash ~/.local/share/plasma/look-and-feel/
kwriteconfig6 --file ksplashrc --group KSplash --key Theme nobara-enhanced.splash
```
Lock screen: System Settings → Screen Locking → Appearance → pick your wallpaper
(or put it at `wallpapers/lockscreen.jpg` and let `install.sh` set it).

**Login screen (manual, system-level):** Nobara 44 uses **Plasma Login Manager**. Set its
wallpaper in System Settings → Colors & Themes → Login Screen. That dialog copies the image to
`/var/lib/plasmalogin/wallpapers/` and writes `/etc/plasmalogin.conf` with root rights.
On the source machine, the login screen uses the same image as the lock screen.

## 7. Panels

Either run the script (it backs up first):
```bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  "var REPLACE_PANELS=false; var KICKOFF_ICON=\"$HOME/.local/share/nobara-rice/nobara-logo.png\"; $(cat kde/panels/layout.js)"
```
…or build them by hand from `kde/panels/appletsrc.reference`:

**Top panel:** top edge, height 36, not floating, *Dodge windows*, opacity *Translucent*,
"floating applets" on. Widgets, left to right:
Application Launcher (icon: `assets/nobara-logo.png`) · Window Title Reborn
(get it from *Add Widgets → Get New Widgets*; custom size 27, fixed length 438, hide when no window) ·
Panel Spacer · Media Player · System Tray · Weather Report (set your own location) · Digital Clock.

**Bottom dock:** bottom edge, height 50, floating, width *Fit content*, *Dodge windows*,
opacity *Translucent*. One Icons-only Task Manager, icon spacing 0, with pinned launchers.

The script can't set these, so do them by hand: opacity, floating applets, weather location,
and the system tray's hidden items (Notifications is hidden in the tray on the source machine).

## 8. Ghostty

```bash
mkdir -p ~/.config/ghostty/themes
cp ghostty/config.ghostty ~/.config/ghostty/
cp ghostty/themes/nobara-enhanced ~/.config/ghostty/themes/
ghostty +validate-config
```
Font family is left at Ghostty's default (JetBrains Mono), size 10.
Set Ghostty as the default terminal: System Settings → Default Applications → Terminal.

**Geometry memory:**
```bash
cp -r kde/kwin/scripts/ghostty-geometry ~/.local/share/kwin/scripts/
install -m 755 kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync ~/.local/bin/
cp kde/kwin/scripts/ghostty-geometry-sync/ghostty-geometry-sync.service ~/.config/systemd/user/
kwriteconfig6 --file kwinrc --group Plugins --key ghostty-geometryEnabled true
systemctl --user daemon-reload && systemctl --user enable --now ghostty-geometry-sync.service
qdbus org.kde.KWin /KWin reconfigure
```

## 9. Touchpad gesture (InputActions)

```bash
mkdir -p ~/.config/inputactions && cp extras/inputactions/config.yaml ~/.config/inputactions/
kwriteconfig6 --file kwinrc --group Plugins --key kwin_gesturesEnabled true
```
A 4-finger horizontal swipe changes the volume.

## 10. GRUB theme (manual, system-level)

GRUB is the fallback behind rEFInd and uses the **Catppuccin** GRUB theme:
```bash
git clone https://github.com/catppuccin/grub && cd grub
sudo mkdir -p /boot/grub2/themes/catppuccin
sudo cp -r src/catppuccin-mocha-grub-theme/* /boot/grub2/themes/catppuccin/
sudo cp /etc/default/grub /etc/default/grub.bak
# in /etc/default/grub:
#   GRUB_THEME="/boot/grub2/themes/catppuccin/theme.txt"
#   GRUB_GFXMODE=1920x1200,auto      # your panel's mode
#   GRUB_TIMEOUT=12
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
The source machine installs the theme as `/boot/grub2/themes/catppuccin`. The flavour
(mocha/macchiato/…) couldn't be read without root. Mocha matches the rest of the rice.

## 11. rEFInd (manual, boot-critical)

See [`../refind/README.md`](../refind/README.md).

## Hardware-specific settings (not applied)

| Setting | Source machine | Where |
|---|---|---|
| Display scale | 2880×1800 panel, Xwayland scale 1.6 | System Settings → Display |
| Touchpad | natural scroll, acceleration 0.35, scroll factor 0.1 | System Settings → Touchpad |
| Mouse (Microsoft Arc) | acceleration 0.2, flat profile | System Settings → Mouse |
| Tiling layout | 25% / 50% / 25% columns, 4 px padding | Meta+T tile editor |
| Power profiles | AC performance / battery balanced / low battery power-saver | Power Management |
