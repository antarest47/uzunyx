#!/usr/bin/env python3
"""The panel and the control center's pill for Calamares' slideshow, from a
full screenshot of a real session at scale 2 (sharper than gen-slides.sh's
nested KWin, which only captures at 1x):

    crop-panel.py shot.png PANEL PILL

PANEL and PILL are x,y,width,height in the screenshot, outer border included
(the 1 px border is 2 px at scale 2; find it with a few pixel reads). Writes
slides/panel.png and slides/pill.png, each alone with its rounded ends
see-through (the wallpaper around the panel was too loud), and
slides/PillPlace.qml (where the pill is in panel.png, for the ring in
show.qml)."""
import os
import sys

import gi
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, GLib

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "slides")
shot = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
px, py, pw, ph = (int(v) for v in sys.argv[2].split(","))
qx, qy, qw, qh = (int(v) for v in sys.argv[3].split(","))


def rounded(x, y, width, height, radius, name):
    """Cuts a rounded rectangle out of the screenshot, corners see-through."""
    part = shot.new_subpixbuf(x, y, width, height).add_alpha(False, 0, 0, 0)
    stride = part.get_rowstride()
    pixels = bytearray(part.get_pixels())
    for py in range(height):
        for px in range(width):
            cx = min(max(px + 0.5, radius), width - radius)
            cy = min(max(py + 0.5, radius), height - radius)
            d = ((px + 0.5 - cx) ** 2 + (py + 0.5 - cy) ** 2) ** 0.5
            i = py * stride + px * 4 + 3
            pixels[i] = int(pixels[i] * max(0.0, min(1.0, radius - d + 0.5)))
    GdkPixbuf.Pixbuf.new_from_bytes(GLib.Bytes(bytes(pixels)), GdkPixbuf.Colorspace.RGB, True, 8,
                                    width, height, stride).savev(f"{out}/{name}.png", "png", [], [])


# The panel's corners are 8 px, 16 at scale 2; the pill is round.
rounded(px, py, pw, ph, 16, "panel")
rounded(qx, qy, qw, qh, qh / 2, "pill")
left, top = px, py
open(out + "/PillPlace.qml", "w").write(
    "// Written by crop-panel.py: the pill's place in panel.png.\n"
    "import QtQuick\n\n"
    f"QtObject {{\n    readonly property real x: {qx - left}\n    readonly property real y: {qy - top}\n"
    f"    readonly property real width: {qw}\n    readonly property real height: {qh}\n}}\n")
