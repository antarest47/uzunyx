#!/usr/bin/python3
"""Genera el CSS de GTK3 o GTK4 que pone los botones de Uzunyx en las barras
de título dibujadas por las apps (headerbar de GTK, Firefox, Chromium).

Uso: gen-gtk-css.py 3|4 <URL del directorio de los SVG>

La URL puede ser relativa al archivo CSS (p. ej. ../buttons).

El botón usa el SVG como fondo y el icono simbólico que GTK pone encima se
oculta, porque GTK lo repinta de un solo color.
"""

import sys

BUTTONS = ("minimize", "maximize", "close")

# Selectores del botón según la versión de GTK
SELECTORS = {
    # Igual o más específicos que los de Breeze GTK, que también tiene reglas
    # para Chromium y para ventanas maximizadas.
    "3": [
        "window headerbar button.titlebutton.{0}",
        "window .titlebar button.titlebutton.{0}",
        "dialog headerbar button.titlebutton.{0}",
        "dialog .titlebar button.titlebutton.{0}",
        "window.maximized headerbar button.titlebutton.{0}",
        "window.maximized .titlebar button.titlebutton.{0}",
        "window.background.chromium headerbar button.titlebutton.{0}",
        "window.background.chromium .titlebar button.titlebutton.{0}",
        "window.background.chromium.maximized headerbar button.titlebutton.{0}",
    ],
    "4": [
        "window headerbar windowcontrols button.{0}",
        "window windowcontrols > button.{0}",
        "window.maximized headerbar windowcontrols button.{0}",
    ],
}

# Aro de 2 px por fuera del botón al pasar el ratón, como el que dibuja
# Electron (Claude Desktop): rosa en cerrar, blanco cálido en los demás.
HOVER_RING = {"minimize": "#c2b6b0", "maximize": "#c2b6b0", "close": "#fe919d"}

STATES = [
    ("normal", ""),
    ("hover", ":hover"),
    ("active", ":active"),
    ("backdrop", ":backdrop"),
]


def css(version, svg_dir):
    sels = SELECTORS[version]
    out = []
    every = ",\n".join(s.format(b) for b in BUTTONS for s in sels)
    # Same size and spacing as Breeze GTK (18 + 1 px padding = 20 px, no
    # margin): Chromium/Electron take the spacing between buttons from here.
    out.append(f"""{every} {{
  min-width: 18px;
  min-height: 18px;
  margin: 0;
  padding: 1px;
  border: none;
  border-radius: 50%;
  box-shadow: none;
  background-color: transparent;
  background-size: 20px 20px;
  background-position: center;
  background-repeat: no-repeat;
}}
""")
    images = ",\n".join(f"{s.format(b)} image" for b in BUTTONS for s in sels)
    out.append(f"{images} {{\n  opacity: 0;\n}}\n")
    for b in BUTTONS:
        for state, pseudo in STATES:
            sel = ",\n".join(s.format(b) + pseudo for s in sels)
            out.append(f'{sel} {{\n  background-image: url("{svg_dir}/{b}-{state}.svg");\n}}\n')
        sel = ",\n".join(s.format(b) + ":hover" for s in sels)
        out.append(f"{sel} {{\n  box-shadow: 0 0 0 2px {HOVER_RING[b]};\n}}\n")
    return "\n".join(out)


if __name__ == "__main__":
    sys.stdout.write(css(sys.argv[1], sys.argv[2].rstrip("/")))
