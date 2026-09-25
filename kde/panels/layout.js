// Plasma 6 desktop script: recreates the two panels of this rice.
//   top    — 36 px, full width: launcher | window title | spacer | media | tray | weather | clock
//   bottom — 50 px floating dock (fit to content): pinned app launchers
//
// Run through scripts/install.sh (which backs up your panel config first), or by hand:
//   qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat layout.js)"
//
// install.sh prepends two variables:
//   REPLACE_PANELS (bool) — remove existing panels first (otherwise panels are added)
//   KICKOFF_ICON   (string) — absolute path to the launcher icon, or "" for the default
// Not set here (see docs/setup.md, "Panels"): panel opacity (Translucent),
// "floating applets" on the top panel, weather location, tray hidden items.

if (typeof REPLACE_PANELS === "undefined") var REPLACE_PANELS = false;
if (typeof KICKOFF_ICON === "undefined") var KICKOFF_ICON = "";

if (REPLACE_PANELS) {
    panels().forEach(function (p) { p.remove(); });
}

// ---- top bar ---------------------------------------------------------------
var top = new Panel;
top.location = "top";
top.height = 36;
top.floating = false;
top.hiding = "dodgewindows";

var kickoff = top.addWidget("org.kde.plasma.kickoff");
if (KICKOFF_ICON) {
    kickoff.currentConfigGroup = ["General"];
    kickoff.writeConfig("icon", KICKOFF_ICON);
}

// Third-party plasmoid (KDE Store "Window Title Reborn"); skipped if missing.
if (knownWidgetTypes.indexOf("org.kde.plasma.windowtitlereborn") !== -1) {
    var title = top.addWidget("org.kde.plasma.windowtitlereborn");
    title.currentConfigGroup = ["Appearance"];
    title.writeConfig("customSize", 27);
    title.writeConfig("fixedLength", 438);
    title.writeConfig("hideWhenUnavailable", true);
    title.writeConfig("horizontalAlignment", 0);
    title.writeConfig("lengthKind", 1);
}

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.mediacontroller");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.weather");
top.addWidget("org.kde.plasma.digitalclock");

// ---- bottom dock -------------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = 50;
dock.floating = true;
dock.lengthMode = "fit";
dock.hiding = "dodgewindows";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("iconSpacing", 0);
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
