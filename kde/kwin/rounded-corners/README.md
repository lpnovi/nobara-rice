# Rounded window corners — KDE-Rounded-Corners (`kwin4_effect_shapecorners`)

**This is the exact mechanism behind the rounded outer corners on the source laptop**, including Steam
and Helium, which draw their own integrated top area (client-side decorations) and get no KDE titlebar.

## What is running on the source laptop
| | |
|---|---|
| Effect | `kwin4_effect_shapecorners` ("Rounded Corners"), loaded by KWin (confirmed via `org.kde.KWin /Effects loadedEffects`) |
| Upstream | <https://github.com/matinlotfali/KDE-Rounded-Corners> (GPL-3.0) |
| Version | git `v0.10.0-10-gee200dd` (commit `ee200dd456995d93c0a0f4709175a21af3fe1b8a`, 2026-09-20), built from source with `CMAKE_INSTALL_PREFIX=/usr` against KWin 6.7.4 (Fedora). Not packaged; files in `/usr/lib64/qt6/plugins/kwin/effects/plugins/kwin4_effect_shapecorners.so`, `…/configs/kwin_shapecorners_config.so`, `/usr/share/kwin/shaders/shapecorners*.frag` |
| Enabled | `EnabledByDefault: true` in the plugin metadata — there is no `shapecornersEnabled` key in kwinrc |
| Config | `~/.config/kwinrc` → `[Round-Corners] Size=10` (the **only** non-default key, in `kde/config/kwinrc.ini`) |

Effective settings = upstream defaults + `Size=10`:
- active-window corner radius **10**, inactive-window radius **20** (default `InactiveCornerRadius`)
- squircle shape on (`UseSquircleShape=true`, `Squircleness=0.55`)
- applies to normal windows **and** dialogs, regardless of decoration → covers CSD/undecorated apps
  (Steam, Helium/Chromium) without adding KDE titlebars
- **not** rounded and no outline when **maximized, fullscreen or tiled** (`DisableRound*`/`DisableOutline*`
  default `true`) → no clipping or gaps at screen edges
- native decoration shadows kept (`UseNativeDecorationShadows=true`); thin dark outline + faint white second outline (defaults)

There are **no** KWin window rules (`kwinrulesrc` is empty) and no Breeze per-app overrides — Steam and
Helium keep their own top areas. The Breeze decoration itself has `RoundedCorners=false`
(`kde/config/breezerc.ini`); the rounding comes entirely from this effect, so KDE apps and CSD apps match.

## Install on CachyOS / Arch (do NOT copy the Fedora .so files)
The compiled plugin is tied to the exact KWin build, so it is never stored in this repo.

**Recommended — AUR (what `./install.sh` does):**
```bash
paru -S kwin-effect-rounded-corners-git     # builds upstream master (closest to the laptop's ee200dd)
# alternative: paru -S kwin-effect-rounded-corners   (tagged 0.10.0 release)
```
Then log out/in (or `qdbus6 org.kde.KWin /KWin reconfigure`) and check System Settings → Desktop Effects →
"Rounded Corners" is ticked. `./install.sh` writes `[Round-Corners] Size=10`.

**Fallback — from source, pinned to the laptop's commit:** `kde/kwin/rounded-corners/build-from-source.sh`

## After every KWin update — REBUILD
The effect links against KWin's private API. After `pacman -Syu` brings a new `kwin`, the old build won't
load (windows simply become square again; nothing crashes). Rebuild:
```bash
paru -S --rebuild kwin-effect-rounded-corners-git
# or rerun build-from-source.sh
```
CachyOS sometimes ships KWin updates first; check after each Plasma update. Upstream also offers
`tools/install-autorun-test.sh` (run inside its build dir) to rebuild automatically at login.

## Roll back
`paru -R kwin-effect-rounded-corners-git` (or `sudo cmake --build build --target uninstall` for a source
build), then `kwriteconfig6 --file kwinrc --group Round-Corners --key Size --delete`.

## Alternatives (if the project ever stops building)
- **LightlyShaders** (rounded corners + outline), AUR `lightlyshaders-git` (verified to exist 2026-10-02; also needs rebuilding after KWin updates).
- Breeze `RoundedCorners=true` only rounds KDE-decorated windows (not Steam/Helium), so it is not a replacement.
