#!/bin/bash
# Takes Tsunyx's picture for Calamares' slideshow from a real desktop: a
# nested KWin and Plasma (Akane) with an empty home, with Tsunyx open. Leaves
# slides/tsunyx.png, kept in git. Run it from a Plasma session with the Uzunyx
# packages installed. The apps in Tsunyx are the ones installed there: better
# run it in the live session of the ISO. With a screenshot as the argument
# (gen-slides.sh shot.png) it only scales and crops that one: the one in git is
# Tsunyx in a full install, taken by the user. The panel and the pill come from a
# screenshot at scale 2 (crop-panel.py): shown enlarged, a nested KWin's 1x
# blurs, and it ignores --scale and kscreen-doctor (QT_SCALE_FACTOR misplaces
# the panel).
set -e
here=$(cd "$(dirname "$0")" && pwd)
out=$here/slides
theme=org.uzunyx.desktop
shot=$1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
home=$tmp/home
mkdir -p "$home/.config/kdedefaults" "$home/.local/share" "$home/.cache" "$out"

# The global theme's defaults, as startplasma writes them (gen-previews.sh).
python3 -I - "/usr/share/plasma/look-and-feel/$theme/contents/defaults" \
    "$home/.config/kdedefaults" <<'EOF'
import re, sys
out, name = {}, None
for line in open(sys.argv[1]):
    line = line.strip()
    m = re.fullmatch(r"\[(\w+)\]\[(.+)\]", line)
    if m:
        name = m[1]
        out.setdefault(name, []).append(f"[{m[2]}]")
    elif line.startswith("["):
        name = None
    elif line and name:
        out[name].append(line)
for name, lines in out.items():
    open(f"{sys.argv[2]}/{name}", "w").write("\n".join(lines) + "\n")
EOF
printf '\n[KDE]\nLookAndFeelPackage=%s\n' "$theme" >> "$home/.config/kdedefaults/kdeglobals"
scheme=$(sed -n 's/^ColorScheme=//p' "$home/.config/kdedefaults/kdeglobals")
{ cat "/usr/share/color-schemes/$scheme.colors"
  printf '\n[KDE]\nLookAndFeelPackage=%s\n' "$theme"; } > "$home/.config/kdeglobals"
printf '[General]\nLastSeenVersion=99.0.0\nShouldShow=false\n' > "$home/.config/plasma-welcomerc"

if [ -z "$shot" ]; then
shot=$home/shot.png
cat > "$tmp/session.sh" <<'EOF'
kwin_wayland --wayland-display "$WAYLAND_DISPLAY" --socket uzunyx-slides --width 1920 --height 1080 >/dev/null 2>&1 &
sleep 4
export WAYLAND_DISPLAY=uzunyx-slides
uzunyx-edition sync >/dev/null 2>&1
plasmashell --no-respawn >/dev/null 2>&1 &
sleep 15
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu >/dev/null 2>&1
sleep 5
spectacle -b -n -f -o "$HOME/shot.png" >/dev/null 2>&1
sleep 2
kill $(jobs -p) 2>/dev/null
sleep 2
EOF
HOME=$home XDG_CONFIG_HOME=$home/.config XDG_DATA_HOME=$home/.local/share \
    XDG_CACHE_HOME=$home/.cache XDG_CONFIG_DIRS=$home/.config/kdedefaults:/etc/xdg \
    timeout 60 dbus-run-session bash "$tmp/session.sh" >/dev/null 2>&1 || true
fi

python3 -I - "$shot" "$out" <<'EOF'
import sys
import gi
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf
shot = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
# Cut to 1220:686 at the sides or top and bottom, centred.
w, h = shot.get_width(), shot.get_height()
cw, ch = min(w, round(h * 1220 / 686)), min(h, round(w * 686 / 1220))
shot = shot.new_subpixbuf((w - cw) // 2, (h - ch) // 2, cw, ch)
shot.scale_simple(1220, 686, GdkPixbuf.InterpType.HYPER).savev(sys.argv[2] + "/tsunyx.png", "png", [], [])
EOF
