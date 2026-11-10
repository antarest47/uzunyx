#!/usr/bin/python3
"""Makes "Uzunyx Powerline", a font with only the round Powerline ends
(U+E0B4 right, U+E0B6 left), as tall as the terminal's cell.

Hack, Konsole's font, has the triangles (U+E0B0-E0B3) but not the round ends,
which then come from a fallback font (Symbols Nerd Font) at that font's size,
smaller than the rest of the prompt. These are drawn on Hack's metrics, from
its descender to its ascender and as wide as its cell; fontconfig puts this
font right after Hack (uzunyx-powerline.conf).

    gen-powerline-font.py OUT.ttf
"""

import math
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib.tables.O_S_2f_2 import Panose

# Hack's metrics (head, hhea and OS/2 of Hack-Regular.ttf).
UPM = 2048
ASCENT = 1901
DESCENT = 483
WIDTH = 1233
STEPS = 64
# The flat side goes this far into the next cell, so no seam shows between
# the cap and the band next to it.
OVERLAP = 32


def half_ellipse(pen, facing_left):
    """Half an ellipse filling the cell, flat on one side and round on the other."""
    cy = (ASCENT - DESCENT) / 2
    ry = (ASCENT + DESCENT) / 2
    flat = WIDTH + OVERLAP if facing_left else -OVERLAP
    points = []
    for i in range(STEPS + 1):
        angle = math.pi / 2 + math.pi * i / STEPS
        x = flat + (WIDTH + OVERLAP) * math.cos(angle) * (1 if facing_left else -1)
        y = cy + ry * math.sin(angle)
        points.append((round(x), round(y)))
    # Clockwise, as TrueType wants an outer contour.
    if facing_left:
        points.reverse()
    pen.moveTo(points[0])
    for point in points[1:]:
        pen.lineTo(point)
    pen.closePath()


def glyph(draw=None):
    pen = TTGlyphPen(None)
    if draw:
        draw(pen)
    return pen.glyph()


def main():
    names = [".notdef", "uniE0B4", "uniE0B6"]
    builder = FontBuilder(UPM, isTTF=True)
    builder.setupGlyphOrder(names)
    builder.setupCharacterMap({0xE0B4: "uniE0B4", 0xE0B6: "uniE0B6"})
    builder.setupGlyf({
        ".notdef": glyph(),
        "uniE0B4": glyph(lambda pen: half_ellipse(pen, False)),
        "uniE0B6": glyph(lambda pen: half_ellipse(pen, True)),
    })
    builder.setupHorizontalMetrics({name: (WIDTH, 0) for name in names})
    builder.setupHorizontalHeader(ascent=ASCENT, descent=-DESCENT)
    builder.setupNameTable({
        "familyName": "Uzunyx Powerline",
        "styleName": "Regular",
        "uniqueFontIdentifier": "Uzunyx Powerline Regular",
        "fullName": "Uzunyx Powerline",
        "psName": "UzunyxPowerline-Regular",
        "version": "Version 1.0",
        "licenseDescription": "GPL-3.0-or-later",
    })
    builder.setupOS2(sTypoAscender=ASCENT, sTypoDescender=-DESCENT, sTypoLineGap=0,
                     usWinAscent=ASCENT, usWinDescent=DESCENT, xAvgCharWidth=WIDTH,
                     panose=Panose(bFamilyType=2, bProportion=9))
    builder.setupPost(isFixedPitch=1)
    builder.save(sys.argv[1])


if __name__ == "__main__":
    main()
