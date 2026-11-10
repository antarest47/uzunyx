#!/bin/bash
# Takes the global theme previews from a real desktop: a nested KWin and
# Plasma with an empty home, using the installed themes, with Dolphin open to
# show the window decoration and the edition's colors. Run it from a Plasma
# session after installing the package; the images are kept in git.
#   ./gen-previews.sh [akane|sora]...
set -e
here=$(cd "$(dirname "$0")" && pwd)
[ $# -gt 0 ] || set -- akane sora

shoot() {
    edition=$1 theme=$2 out=$3
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN
    home=$tmp/home
    mkdir -p "$home/.config/kdedefaults" "$home/.local/share" "$home/.cache" "$out" \
        "$home/Documentos" "$home/Descargas" "$home/Imágenes" "$home/Música" "$home/Vídeos"
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
    # The scheme's colors, as the user's kdeglobals has them once a scheme is
    # applied; with only its name, views and the panel come out light.
    scheme=$(sed -n 's/^ColorScheme=//p' "$home/.config/kdedefaults/kdeglobals")
    { cat "/usr/share/color-schemes/$scheme.colors"
      printf '\n[KDE]\nLookAndFeelPackage=%s\n' "$theme"; } > "$home/.config/kdeglobals"
    # Nothing but Plasma and Dolphin on screen.
    printf '[General]\nLastSeenVersion=99.0.0\nShouldShow=false\n' > "$home/.config/plasma-welcomerc"

    cat > "$tmp/session.sh" <<'EOF'
kwin_wayland --wayland-display "$WAYLAND_DISPLAY" --socket uzunyx-preview --width 1920 --height 1080 >/dev/null 2>&1 &
sleep 4
export WAYLAND_DISPLAY=uzunyx-preview
uzunyx-edition sync >/dev/null 2>&1 # the Uzunyx launcher's icon, as at login
plasmashell --no-respawn >/dev/null 2>&1 &
sleep 15
dolphin "$HOME" >/dev/null 2>&1 &
sleep 6
spectacle -b -n -f -o "$HOME/shot.png" >/dev/null 2>&1
sleep 2
kill $(jobs -p) 2>/dev/null
EOF
    HOME=$home XDG_CONFIG_HOME=$home/.config XDG_DATA_HOME=$home/.local/share \
        XDG_CACHE_HOME=$home/.cache XDG_CONFIG_DIRS=$home/.config/kdedefaults:/etc/xdg \
        timeout 60 dbus-run-session bash "$tmp/session.sh" >/dev/null 2>&1 || true

    python3 -I - "$home/shot.png" "$out" <<'EOF'
import sys
import gi
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf
shot = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
# Without alpha: GdkPixbuf saves an RGBA screenshot as a grayscale JPEG here.
flat = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, shot.get_width(), shot.get_height())
shot.composite(flat, 0, 0, shot.get_width(), shot.get_height(), 0, 0, 1, 1, GdkPixbuf.InterpType.NEAREST, 255)
flat.savev(sys.argv[2] + "/fullscreenpreview.jpg", "jpeg", ["quality"], ["85"])
small = flat.scale_simple(600, 337, GdkPixbuf.InterpType.HYPER)
small.savev(sys.argv[2] + "/preview.png", "png", [], [])
EOF
}

for edition; do
    case $edition in
        akane) shoot akane org.uzunyx.desktop "$here/package/contents/previews" ;;
        sora) shoot sora org.uzunyx.sora "$here/previews-sora" ;;
        *) echo "Unknown edition: $edition" >&2; exit 1 ;;
    esac
done
