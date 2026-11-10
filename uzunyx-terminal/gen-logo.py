#!/usr/bin/env python3
"""Writes the ASCII logo for fastfetch from the Uzunyx icon.

Two fastfetch colours: $1 the white of the logo, $2 its accent. Usage:
gen-logo.py icon.png logo.txt
"""
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf

COLS, ROWS = 38, 19
RAMP = " .:-=+*#%@"


def main(src, dst):
    pix = GdkPixbuf.Pixbuf.new_from_file(src).add_alpha(False, 0, 0, 0)
    w, h, stride, data = pix.get_width(), pix.get_height(), pix.get_rowstride(), pix.get_pixels()
    lines = []
    for row in range(ROWS):
        line, current = "", None
        for col in range(COLS):
            n = cov = red = sat = 0
            for y in range(row * h // ROWS, (row + 1) * h // ROWS, 4):
                for x in range(col * w // COLS, (col + 1) * w // COLS, 4):
                    r, g, b, a = data[y * stride + x * 4:y * stride + x * 4 + 4]
                    n += 1
                    if a > 128 and max(r, g, b) > 70:
                        cov += 1
                        sat += (max(r, g, b) - min(r, g, b)) > 70
            char = RAMP[min(cov * len(RAMP) // max(n, 1), len(RAMP) - 1)]
            if char != " ":
                colour = "$2" if sat * 2 > cov else "$1"
                if colour != current:
                    line += colour
                    current = colour
            line += char
        lines.append(line.rstrip())
    open(dst, "w").write("\n".join(lines) + "\n")


main(*sys.argv[1:])
