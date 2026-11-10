#!/usr/bin/python3
"""Generate panel-background.svg and dialogs/background.svg for the Uzunyx
Plasma theme (the same drawing in Breeze: the popups get the panel's outline).

Starts from one of Breeze's panel-background.svg variants (widgets/, and
opaque/, translucent/ and solid/, picked by the panel's opacity setting) and
gives the panel frame a 1 px outline along its outer edge, following the
rounded corners: the text colour at 25 %, like the outline of the uzunyx
window decoration and of uzunyx-outline (white with Breeze Dark).
Everything else (background, shadows, blur masks, margin hints) is Breeze's.

The opaque variant already has that line, in the frame colour (almost the
background colour with Breeze Dark): it is recoloured. The others get a new
line drawn over the edge of each piece.

Usage: gen-panel-svg.py BREEZE_PANEL_BACKGROUND.svg OUT.svg
"""
import sys
import xml.etree.ElementTree as ET

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

OUTLINE_OPACITY = 0.25
TEXT = "ColorScheme-Text"
FRAME = "ColorScheme-Frame"

# Breeze's frame pieces are 6 px deep (corners 6x6 with a 6 px radius, edges
# 32 px long), each in its own group translated to its place. The outline is
# a filled 1 px band on the outer side, in the piece's own coordinates. It
# must stay inside the piece: Plasma sizes each piece by its bounding box,
# so anything sticking out (like the caps of a stroke) stretches the piece
# and leaves seams.
B = 6        # border depth
L = 32       # edge length
W = 1        # outline width
K = 0.55228  # cubic Bézier circle constant


def ring(cx, cy, sx, sy):
    """Quarter ring of radius B..B-W around (cx, cy), bulging towards
    (cx + sx*B, cy + sy*B)."""
    def arc(r, reverse):
        a = (cx + sx * r, cy)                   # on the horizontal radius
        b = (cx, cy + sy * r)                   # on the vertical radius
        c1 = (cx + sx * r, cy + sy * r * K)
        c2 = (cx + sx * r * K, cy + sy * r)
        if reverse:
            a, b, c1, c2 = b, a, c2, c1
        return a, f"C {c1[0]:g},{c1[1]:g} {c2[0]:g},{c2[1]:g} {b[0]:g},{b[1]:g}"
    start, outer = arc(B, False)
    inner_start, inner = arc(B - W, True)
    return (f"M {start[0]:g},{start[1]:g} {outer} "
            f"L {inner_start[0]:g},{inner_start[1]:g} {inner} Z")


OUTLINES = {
    "top":         f"M 0,0 H {L} V {W} H 0 Z",
    "bottom":      f"M 0,{B - W} H {L} V {B} H 0 Z",
    "left":        f"M 0,0 H {W} V {L} H 0 Z",
    "right":       f"M {B - W},0 H {B} V {L} H {B - W} Z",
    "topleft":     ring(B, B, -1, -1),
    "topright":    ring(0, B, 1, -1),
    "bottomleft":  ring(B, 0, -1, 1),
    "bottomright": ring(0, 0, 1, 1),
}


def main(src, dst):
    tree = ET.parse(src)
    groups = {e.get("id"): e for e in tree.iter(f"{{{SVG_NS}}}g")}
    for piece, d in OUTLINES.items():
        group = groups.get(piece)
        if group is None:
            sys.exit(f"{src}: no <g id=\"{piece}\">")
        frames = [e for e in group.iter() if e.get("class") == FRAME]
        if frames:
            for e in frames:
                e.set("class", TEXT)
                e.set("style", f"{e.get('style', '').rstrip(';')};opacity:{OUTLINE_OPACITY}")
            continue
        ET.SubElement(group, f"{{{SVG_NS}}}path", {
            "id": f"{piece}-outline",
            "d": d,
            "class": TEXT,
            "style": f"fill:currentColor;stroke:none;opacity:{OUTLINE_OPACITY}",
        })
    tree.write(dst, xml_declaration=True, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
