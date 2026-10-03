# Fonts

Font files are **not** stored here; they're packaged (and the Geist license, SIL OFL 1.1, travels with them).

| Role | Font | Size |
|---|---|---|
| General, menu, toolbar (Plasma + apps) | Geist | 11 |
| Small | Geist | 9 |
| Window titles | Geist | 10 |
| Fixed width / monospace | Geist Mono | 10 |
| Terminal (Ghostty) | JetBrains Mono — Ghostty's built-in default, no package needed | 10 |
| PlasMusic Toolbar text | Geist | 6 |

Install on CachyOS / Arch:
```bash
paru -S ttf-geist ttf-geist-mono        # AUR, pkgbase geist-font (Vercel, OFL-1.1)
```
or download from <https://github.com/vercel/geist-font/releases> into `~/.local/share/fonts/Geist/` and run
`fc-cache -f` (that's how the laptop had them: user-local OTF + TTF files).

Rendering (`kdeglobals`): antialiasing on, hinting **slight**, subpixel **RGB**.
Optional: `ttf-jetbrains-mono-nerd` (extra) if you want Nerd Font glyphs elsewhere; Ghostty doesn't need it.
