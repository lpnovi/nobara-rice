# Fonts

The font files are **not** stored here. They're packaged, and the Geist license (SIL OFL 1.1)
should travel with the files anyway.

| Role | Font | Size |
|---|---|---|
| General, menu, toolbar | Geist | 11 |
| Small | Geist | 9 |
| Window titles | Geist | 10 |
| Fixed width | Geist Mono | 10 |
| Terminal (Ghostty) | JetBrains Mono (Ghostty's built-in default) | 10 |

Install:
```bash
sudo dnf install geist-font geist-font-mono        # Terra repo (on by default on Nobara)
```
or download from <https://github.com/vercel/geist-font/releases> into `~/.local/share/fonts/Geist/`
and run `fc-cache -f`.

Rendering (`kdeglobals`): antialiasing on, hinting **slight**, subpixel **RGB**.
