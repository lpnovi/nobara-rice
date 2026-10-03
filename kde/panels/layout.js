// Plasma 6 desktop script: recreates the two panels of this rice exactly as on the source laptop.
//   top    — 36 px, full width, translucent, dodge windows, floating applets:
//            launcher (Nobara Enhanced Kickoff fork) | Window Title Reborn | spacer |
//            PlasMusic Toolbar | system tray | weather | clock
//   bottom — 50 px floating dock, fit to content, translucent, dodge windows:
//            Icon-only Task Manager (pinned apps) + hidden Task Icon Hover helper
// Reference of the live result: appletsrc.reference / plasmashellrc.reference (same folder).
//
// Run through ./install.sh (backs up your panel config first), or by hand:
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat layout.js)"
//
// install.sh prepends two variables:
//   REPLACE_PANELS (bool)   — remove existing panels first (otherwise panels are added)
//   KICKOFF_ICON   (string) — absolute path to the launcher icon, or "" for the default
// The last line prints "PANEL_IDS <top> <dock>"; install.sh uses the ids to set
// floatingApplets / panelOpacity in plasmashellrc (not all of that is scriptable).
// Not set here: weather location (personal; set it in the widget) and the wallpaper.

if (typeof REPLACE_PANELS === "undefined") var REPLACE_PANELS = false;
if (typeof KICKOFF_ICON === "undefined") var KICKOFF_ICON = "";

function known(id) { return knownWidgetTypes.indexOf(id) !== -1; }

if (REPLACE_PANELS) {
    panels().forEach(function (p) { p.remove(); });
}

// ---- top bar ---------------------------------------------------------------
var top = new Panel;
top.location = "top";
top.height = 36;
top.floating = false;
top.hiding = "dodgewindows";
top.opacity = "translucent";

// User-local Kickoff fork (kde/launcher); falls back to stock Kickoff if it isn't installed.
var kickoff = top.addWidget(known("local.lpnovi.kickoff") ? "local.lpnovi.kickoff" : "org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
if (KICKOFF_ICON) kickoff.writeConfig("icon", KICKOFF_ICON);
kickoff.writeConfig("pin", true);   // live setting: popup stays open when it loses focus

// Third-party plasmoid (vendored in kde/plasmoids); skipped if missing.
if (known("org.kde.plasma.windowtitlereborn")) {
    var title = top.addWidget("org.kde.plasma.windowtitlereborn");
    title.currentConfigGroup = ["Appearance"];
    title.writeConfig("customSize", 27);
    title.writeConfig("fixedLength", 438);
    title.writeConfig("hideWhenUnavailable", true);
    title.writeConfig("horizontalAlignment", 0);
    title.writeConfig("lengthKind", 1);
}

top.addWidget("org.kde.plasma.panelspacer");

// PlasMusic Toolbar (AUR plasma6-applets-plasmusic-toolbar); stock media controller otherwise.
if (known("plasmusic-toolbar")) {
    var music = top.addWidget("plasmusic-toolbar");
    music.currentConfigGroup = ["General"];
    music.writeConfig("customFont", "Geist,6,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0");
    music.writeConfig("fallbackToIconWhenArtNotAvailable", true);
    music.writeConfig("maxSongWidthInPanel", 150);
    music.writeConfig("panelIcon", "com.deepin.Music");
    music.writeConfig("textScrollingSpeed", 1);
    music.writeConfig("useAlbumCoverAsPanelIcon", true);
} else {
    top.addWidget("org.kde.plasma.mediacontroller");
}

var tray = top.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("scaleIconsToFit", true);
tray.writeConfig("iconSpacing", 1);
tray.writeConfig("hiddenItems", ["org.kde.plasma.notifications"]);

top.addWidget("org.kde.plasma.weather");
top.addWidget("org.kde.plasma.digitalclock");

// ---- bottom dock -------------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = 50;
dock.floating = true;
dock.lengthMode = "fit";
dock.hiding = "dodgewindows";
dock.opacity = "translucent";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("iconSpacing", 0);
// Launchers whose .desktop file doesn't exist are simply not shown.
// org.dnf.AppCenter is Nobara-only; on CachyOS it is skipped.
tasks.writeConfig("launchers", [
    "applications:systemsettings.desktop",
    "applications:org.dnf.AppCenter.desktop",
    "preferred://filemanager",
    "preferred://browser",
    "applications:discord.desktop",
    "applications:steam.desktop",
    "applications:io.github.kolunmi.Bazaar.desktop",
    "applications:dev.diegovsky.Riff.desktop",
    "applications:me.proton.Mail.desktop"
]);

// Hidden helper (kde/plasmoids/local.lpnovi.taskiconhover): hover lift for the task icons.
// Must sit in the same panel as the task manager. Invisible except in panel Edit Mode.
if (known("local.lpnovi.taskiconhover")) {
    dock.addWidget("local.lpnovi.taskiconhover");
}

print("PANEL_IDS " + top.id + " " + dock.id);
