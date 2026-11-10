#!/usr/bin/python3
"""Genera los botones de ventana de Uzunyx en SVG.

Un archivo por botón y estado: <botón>-<estado>.svg en el directorio dado
(por defecto ./svg). Los tres botones tienen la misma forma (bola negra
brillante con aro, luna creciente blanca abajo a la izquierda, destello arriba
a la izquierda y brillo arriba a la derecha) y cambia el símbolo: minimize
(barra), maximize (anillo, también para restaurar), close (cruz). Minimizar y
maximizar son blancos (neutros) y cerrar rojo, iguales en las dos ediciones
(Akane y Sora): el rojo combina con el círculo rosa fijo que Electron pone
detrás de cerrar al pasar el ratón. Estados: normal, hover, active (presionado) y backdrop (ventana
inactiva, en gris).

El resplandor se hace con trazos anchos y translúcidos debajo del símbolo, sin
filtros SVG, para que se vea igual en Qt SVG y en librsvg.
"""

import os
import sys

BUTTONS = ("minimize", "maximize", "close")

# aro (arriba, abajo), núcleo (centro, borde), luna, destello, símbolo,
# resplandor. Hasta 0.6.0: aro carmesí y símbolo rosa en los tres (Akane) o
# cian (Sora).
WHITE = (("#f4f6f8", "#7d858f"), ("#22262b", "#030405"), "#ffffff",
         "#ffffff", "#ffffff", "#dfe8f0")
RED = (("#ff5a4e", "#a3100c"), ("#2a1f1f", "#050303"), "#ffffff",
       "#ff8f80", "#ffc4bc", "#ff2b1c")
PALETTE = {"minimize": WHITE, "maximize": WHITE, "close": RED}
# Ventana inactiva: gris en los tres.
GREY = (("#a09a9d", "#5e585b"), ("#262325", "#080708"), "#d8d4d6",
        "#a8a2a5", "#d0cbcd", "#8a8487")

SYMBOLS = {
    "minimize": '<path d="M8 12h8"/>',
    "maximize": '<circle cx="12" cy="12" r="3.9"/>',
    "close": '<path d="M9 9l6 6M15 9l-6 6"/>',
}

STATES = {
    # estado: (aclarado del núcleo, opacidad del resplandor, opacidad general)
    "normal": (0.0, 0.55, 1.0),
    "hover": (0.12, 0.95, 1.0),
    "active": (0.0, 0.25, 1.0),
    "backdrop": (0.0, 0.0, 0.55),
}

# El aro que rodea el botón al pasar el ratón no va en el SVG sino por fuera,
# en la decoración (UzunyxButton.qml) y en el CSS de GTK (gen-gtk-css.py),
# copiando el que Electron (Claude Desktop) dibuja por su cuenta.


def svg(name, state):
    (rim_top, rim_bottom), (core_in, core_out), moon, sparkle, sym, glow = \
        GREY if state == "backdrop" else PALETTE[name]
    light, glow_op, opacity = STATES[state]
    symbol = SYMBOLS[name]
    # El hueco de la luna se pinta con el mismo degradado del núcleo
    # (coordenadas absolutas), así queda como un trozo de bola sin luna.
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
 <defs>
  <linearGradient id="rim" x1="0" y1="1" x2="0" y2="23" gradientUnits="userSpaceOnUse">
   <stop offset="0" stop-color="{rim_top}"/>
   <stop offset="1" stop-color="{rim_bottom}"/>
  </linearGradient>
  <radialGradient id="core" cx="13" cy="10" r="11" gradientUnits="userSpaceOnUse">
   <stop offset="0" stop-color="{core_in}"/>
   <stop offset="1" stop-color="{core_out}"/>
  </radialGradient>
  <radialGradient id="tint" cx="12" cy="12" r="8" gradientUnits="userSpaceOnUse">
   <stop offset="0" stop-color="{glow}" stop-opacity="{light:.2f}"/>
   <stop offset="1" stop-color="{glow}" stop-opacity="0"/>
  </radialGradient>
 </defs>
 <g opacity="{opacity}">
  <circle cx="12" cy="12" r="11" fill="url(#rim)"/>
  <circle cx="12" cy="12" r="9.9" fill="url(#core)"/>
  <circle cx="12" cy="12" r="9.75" fill="none" stroke="#fff" stroke-width="0.35" opacity="0.35"/>
  <circle cx="12" cy="12" r="9.9" fill="url(#tint)"/>
  <circle cx="6.6" cy="16.3" r="2.5" fill="{moon}"/>
  <circle cx="7.7" cy="15.2" r="2.25" fill="url(#core)"/>
  <path d="M7 4.6l.45 1.9 1.9.45-1.9.45-.45 1.9-.45-1.9-1.9-.45 1.9-.45z" fill="{sparkle}"/>
  <ellipse cx="16.2" cy="5.9" rx="2.3" ry="1.05" transform="rotate(30 16.2 5.9)" fill="#fff" opacity="0.75"/>
  <circle cx="18.6" cy="8.4" r="0.6" fill="#fff" opacity="0.6"/>
  <g fill="none" stroke="{glow}" stroke-linecap="round" stroke-width="4.2" opacity="{glow_op * 0.3:.2f}">{symbol}</g>
  <g fill="none" stroke="{glow}" stroke-linecap="round" stroke-width="2.8" opacity="{glow_op * 0.6:.2f}">{symbol}</g>
  <g fill="none" stroke="{sym}" stroke-linecap="round" stroke-width="1.5">{symbol}</g>
 </g>
</svg>
'''


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")
    os.makedirs(out, exist_ok=True)
    for name in BUTTONS:
        for state in STATES:
            with open(os.path.join(out, f"{name}-{state}.svg"), "w") as f:
                f.write(svg(name, state))


if __name__ == "__main__":
    main()
