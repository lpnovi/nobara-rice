# Quick Tile Glide (local) — `local_quicktile_glide`

User-made KWin **JavaScript** effect (no compiled code, survives KWin updates). KWin 6.7 has no native
animation for Quick Tiling (Meta+←/→ or dragging to a screen edge); this effect smoothly moves and resizes
the window from its old geometry into the tile (and back out), cross-fading contents like KWin's
built-in *Stretch/maximize* effect.

- Duration 180 ms, OutCubic, deliberately **not** scaled by the global animation speed
- Heuristic (KWin doesn't tell effects *why* geometry changed): non-interactive change, size changes by
  ≥ 24 px, old or new geometry touches the left/right screen edge (±16 px) and is reasonably large;
  windows opened < 1.5 s ago and maximize/fullscreen changes (< 1 s) are left alone
- `EnabledByDefault: false`; enabled via `kwinrc [Plugins] local_quicktile_glideEnabled=true`

Install: copy this folder to `~/.local/share/kwin/effects/` and enable it (`./install.sh` does both), then
`qdbus6 org.kde.KWin /KWin reconfigure` or log out/in.
Remove: disable in System Settings → Window Management → Desktop Effects, delete the folder.
License: GPL-2.0-or-later.
