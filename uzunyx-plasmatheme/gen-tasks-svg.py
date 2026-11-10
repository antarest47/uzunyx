#!/usr/bin/python3
"""Generate widgets/tasks.svg for the Uzunyx Plasma theme.

Starts from Breeze's tasks.svg (progress bar, group expander arrows and the
icon margin hints are kept) and replaces the task state frames with a
Unity/GNOME-dash look: a dot under the icon of running apps and rounded
backgrounds for the active and hovered task, instead of Breeze's line along
the panel edge. The active task's background takes the colour scheme's
highlight colour (crimson with Uzunyx Akane, cyan with Uzunyx Sora) and has
a thin outline in the same colour as the panel's (text colour at 25 %).

Each state is a single "<state>-center" element (no borders), sized like an
icons-only task button in a default-height panel (53x46), so the frame is
stretched about proportionally and the dot stays round. The task manager
looks up "<state>-hover" first while hovering (TaskTools.js
taskPrefixHovered), so hover can keep the running dot.

Usage: gen-tasks-svg.py BREEZE_TASKS.svg OUT.svg
"""
import re
import sys
import xml.etree.ElementTree as ET

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

W, H = 53, 46               # cell size (icons-only task in a 46 px panel)
DOT_R, DOT_Y = 2.4, H - 4.5  # running indicator, under the icon
BG_X, BG_Y, BG_RX = 3, 2, 9  # rounded background inset and corner radius

STATE_ELEMENT = re.compile(
    r"^(north-|south-|east-|west-)?(normal|focus|hover|attention|minimized)-"
    r"(top|bottom|left|right|topleft|topright|bottomleft|bottomright|center)$"
    r"|^group-expander-(top|bottom|left|right)$")

# Group indicator (GroupExpanderOverlay.qml draws "group-expander-<edge>" at
# its natural size, centred under the icon and anchored to the button's
# panel-side edge, over the state frame). Instead of Breeze's "+" badge it
# stretches the running dot into a rounded dash covering it, meaning "several
# windows" without implying a count (it's a static image, it can't know it).
# Opaque, so the dot underneath doesn't show through as a brighter middle.
DASH_LEN = 14
GROUP_LEN = DASH_LEN + 2
GROUP_DEPTH = 2 * (H - DOT_Y)  # dash centre lands on the frame's dot

# state -> (background opacity or None, background colour class,
#           outline opacity or None, dot opacity or None, dot colour class)
TEXT, NEUTRAL = "ColorScheme-Text", "ColorScheme-NeutralText"
HIGHLIGHT = "ColorScheme-Highlight"
OUTLINE_W = 1  # outline of the active task, a filled ring
OUTLINE = 0.25  # same as the panel's outline (gen-panel-svg.py)
STATES = {
    "normal":          (None, None, None, 1.00, TEXT),
    "minimized":       (None, None, None, 0.40, TEXT),
    "focus":           (0.50, HIGHLIGHT, OUTLINE, 1.00, TEXT),
    "attention":       (0.28, NEUTRAL, None, 1.00, NEUTRAL),
    "normal-hover":    (0.10, TEXT, None, 1.00, TEXT),
    "minimized-hover": (0.10, TEXT, None, 0.40, TEXT),
    "focus-hover":     (0.60, HIGHLIGHT, OUTLINE, 1.00, TEXT),
    "attention-hover": (0.36, NEUTRAL, None, 1.00, NEUTRAL),
    "launcher-hover":  (0.10, TEXT, None, None, None),  # pinned app without windows
    "hover":           (0.10, TEXT, None, None, None),
}


def rounded_rect(x, y, w, h, r):
    return (f"M{x + r},{y}h{w - 2 * r}a{r},{r} 0 0 1 {r},{r}v{h - 2 * r}"
            f"a{r},{r} 0 0 1 {-r},{r}h{2 * r - w}a{r},{r} 0 0 1 {-r},{-r}"
            f"v{2 * r - h}a{r},{r} 0 0 1 {r},{-r}z")


def element(tag, **attrs):
    return ET.Element(f"{{{SVG_NS}}}{tag}", {k.replace("_", "-"): str(v) for k, v in attrs.items()})


def main(src, out):
    tree = ET.parse(src)
    root = tree.getroot()

    for parent in list(root.iter()):
        for child in list(parent):
            if STATE_ELEMENT.match(child.get("id") or ""):
                parent.remove(child)

    x0, y0 = 150, 0
    per_row = 6
    for n, (state, (bg, bg_cls, outline, dot, dot_cls)) in enumerate(STATES.items()):
        x = x0 + (n % per_row) * (W + 4)
        y = y0 + (n // per_row) * (H + 4)
        g = element("g", id=f"{state}-center")
        # Invisible box fixing the element's size to the whole cell.
        g.append(element("rect", x=x, y=y, width=W, height=H, fill="#000000", opacity=0))
        bx, by, bw, bh = x + BG_X, y + BG_Y, W - 2 * BG_X, H - 2 * BG_Y
        if bg is not None:
            g.append(element("rect", x=bx, y=by, width=bw, height=bh,
                             rx=BG_RX, ry=BG_RX, fill="currentColor", opacity=bg, **{"class": bg_cls}))
        if outline is not None:
            # A filled ring rather than a stroke, so it stays inside the box.
            t = OUTLINE_W
            d = rounded_rect(bx, by, bw, bh, BG_RX) + rounded_rect(bx + t, by + t, bw - 2 * t, bh - 2 * t, BG_RX - t)
            g.append(element("path", d=d, fill="currentColor", fill_rule="evenodd", opacity=outline,
                             **{"class": TEXT}))
        if dot is not None:
            g.append(element("circle", cx=x + W / 2, cy=y + DOT_Y, r=DOT_R,
                             fill="currentColor", opacity=dot, **{"class": dot_cls}))
        root.append(g)

    rows = (len(STATES) + per_row - 1) // per_row

    gy = y0 + rows * (H + 4)
    for n, edge in enumerate(("bottom", "top", "left", "right")):
        horizontal = edge in ("bottom", "top")
        w, h = (GROUP_LEN, GROUP_DEPTH) if horizontal else (GROUP_DEPTH, GROUP_LEN)
        x = x0 + n * (GROUP_LEN + 4)
        g = element("g", id=f"group-expander-{edge}")
        g.append(element("rect", x=x, y=gy, width=w, height=h, fill="#000000", opacity=0))
        dw, dh = (DASH_LEN, 2 * DOT_R) if horizontal else (2 * DOT_R, DASH_LEN)
        g.append(element("rect", x=x + (w - dw) / 2, y=gy + (h - dh) / 2, width=dw, height=dh,
                         rx=DOT_R, ry=DOT_R, fill="currentColor", **{"class": TEXT}))
        root.append(g)
    rows += 1
    width = max(144, x0 + per_row * (W + 4))
    height = max(126, rows * (H + 4))
    root.set("viewBox", f"0 0 {width} {height}")
    tree.write(out, xml_declaration=True, encoding="UTF-8")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
