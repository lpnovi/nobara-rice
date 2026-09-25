# Ghostty geometry memory

KWin 6 on Wayland ignores a "Remember" size window rule for Ghostty, so this
pair of pieces makes Ghostty reopen at its last size and position:

1. **KWin script** `../ghostty-geometry/` — applies the saved geometry to new
   `com.mitchellh.ghostty` windows and logs `GHOSTTY_GEOMETRY x,y,w,h` after a
   manual move/resize (maximized, fullscreen and tiled windows are ignored).
2. **User service** `ghostty-geometry-sync.service` — runs
   `ghostty-geometry-sync`, which follows KWin's journal and saves the latest
   value to `kwinrc [Script-ghostty-geometry] geometry`.

Install targets: `~/.local/share/kwin/scripts/ghostty-geometry/`,
`~/.local/bin/ghostty-geometry-sync`, `~/.config/systemd/user/`.

Debug: `journalctl --user -g GHOSTTY_GEOMETRY`.
Don't add a KWin window rule for Ghostty's geometry as well, because the two will fight.
