# Plasmoids

| Folder | What | Origin / license | On CachyOS |
|---|---|---|---|
| `local.lpnovi.taskiconhover/` | **Task Icon Hover (local)**: invisible helper applet in the bottom dock. It finds the stock Icon-only Task Manager's delegates in the same panel and attaches a Scale (1.08) + Translate (2.5 px away from the edge) transform, 140 ms OutCubic, on hover. The task manager itself is not copied or modified. `Plasmoid.status = HiddenStatus`, so it takes no panel space (visible only in Edit Mode). | user-made, GPL-2.0-or-later | installed by `./install.sh` to `~/.local/share/plasma/plasmoids/` |
| `org.kde.plasma.windowtitlereborn/` | **Window Title Reborn** 1.0.0-plasma6.6, the active window title in the top bar | [ShrekBytes/window-title-reborn](https://github.com/ShrekBytes/window-title-reborn), GPL-3.0-or-later, vendored unmodified because there is no AUR package | installed by `./install.sh`; alternatively "Get New Widgets" → KDE Store |

Not vendored (installed as packages):
- **PlasMusic Toolbar** 4.3.1 (`plasmusic-toolbar`) → AUR `plasma6-applets-plasmusic-toolbar`
- **Panel Colorizer** 8.0.0 is installed on the laptop but **not on any panel** → not part of the rice
  (AUR `plasma6-applets-panel-colorizer` if wanted)

Why a helper instead of a patched task manager: Plasma 6.7 compiles the task manager QML into
`org.kde.plasma.taskmanager.so` (qrc), so a user-local QML copy can't override it.
The helper relies on these delegate properties of the stock task manager: `tasksRoot`, `inPopup`,
`highlighted`, `smartLauncherItem` (all still present in Plasma 6.7.5). If a Plasma update renames them,
the helper silently does nothing; nothing breaks.

Remove the helper: panel Edit Mode → remove "Task Icon Hover (local)", or `./uninstall.sh`.
