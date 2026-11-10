#!/usr/bin/python3
"""Makes the pill's battery icons: Kora's, with its 1 px outline on whole pixels.

Kora's battery outline is 0.7 px wide and starts at x = 2.44, so at 16 px it is
smeared over two grey pixels and looks dimmer than the volume icon next to it.
Same design here (cap on top, rounded body, the charge filled in at 30 %, a bolt
while charging, an exclamation mark when empty), drawn on the pixel grid.

    gen-battery-icons.py OUTDIR
"""

import os
import sys

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">\n'
# The outer edge of the body and the cap, on whole pixels; the line is 1 px.
OUTLINE = ("M6 0h4a1 1 0 0 1 1 1v1h1a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-8a2 2 0 0 1-2-2v-10"
           "a2 2 0 0 1 2-2h1v-1a1 1 0 0 1 1-1z"
           "M4 3a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-10a1 1 0 0 0-1-1z")
# Inside the line: x 3-13, y 3-15.
INNER_TOP, INNER_BOTTOM = 3, 15
BOLT = "M8.5 4.5 5.5 9.5h2.5l-.5 4 3-5h-2.5z"
EXCLAMATION = "M7.25 5h1.5l-.25 5h-1zM7.25 11.5h1.5v1.5h-1.5z"


def icon(percent, charging):
    parts = [HEAD]
    height = round((INNER_BOTTOM - INNER_TOP) * percent / 100)
    if height > 0:
        top = INNER_BOTTOM - height
        # The whole inside, up to the line, as in Kora.
        parts.append(f' <path style="opacity:0.3;fill:#ffffff" d="M3 {top}h10v{height - 1}a1 1 0 0 1-1 1h-8'
                     f'a1 1 0 0 1-1-1z"/>\n' if height > 1 else
                     f' <path style="opacity:0.3;fill:#ffffff" d="M3 {top}h10v1h-10z"/>\n')
    shape = OUTLINE
    if charging:
        shape += BOLT
    elif percent == 0:
        shape += EXCLAMATION
    parts.append(f' <path style="fill:#ffffff" fill-rule="evenodd" d="{shape}"/>\n')
    parts.append("</svg>\n")
    return "".join(parts)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for percent in range(0, 101, 10):
        for charging in (False, True):
            name = f"battery-{percent:03d}{'-charging' if charging else ''}.svg"
            with open(os.path.join(out, name), "w") as f:
                f.write(icon(percent, charging))


if __name__ == "__main__":
    main()
