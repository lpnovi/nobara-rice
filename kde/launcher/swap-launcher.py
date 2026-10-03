#!/usr/bin/env python3
"""Switch the panel's launcher applet between stock Kickoff and the local fork.

usage: swap-launcher.py fork|stock

Only the `plugin=` line of the launcher applet section is changed; applet id,
position, size, settings and favorites (stored per applet id) stay as they
are. Must run while plasmashell is stopped, or it overwrites the file on exit.
"""
import os, re, subprocess, sys

RC = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
STOCK, FORK = "org.kde.plasma.kickoff", "local.lpnovi.kickoff"

target = {"fork": FORK, "stock": STOCK}.get(sys.argv[1] if len(sys.argv) > 1 else "")
if not target:
    sys.exit(__doc__)
if subprocess.run(["pgrep", "-x", "plasmashell"], capture_output=True).returncode == 0:
    sys.exit("plasmashell is running; stop it first (systemctl --user stop plasma-plasmashell)")

source = STOCK if target == FORK else FORK
lines = open(RC).read().split("\n")
section, hits = None, []
for i, line in enumerate(lines):
    if line.startswith("["):
        section = line
    elif line == f"plugin={source}" and re.fullmatch(r"\[Containments\]\[\d+\]\[Applets\]\[\d+\]", section or ""):
        hits.append(i)

if not hits:
    already = any(l == f"plugin={target}" for l in lines)
    sys.exit(0 if already else f"no applet with plugin={source} found")
if len(hits) != 1:
    sys.exit(f"expected one {source} applet, found {len(hits)}; not touching anything")

lines[hits[0]] = f"plugin={target}"
tmp = RC + ".swap-tmp"
open(tmp, "w").write("\n".join(lines))
os.replace(tmp, RC)
print(f"launcher applet -> {target}")
