#!/usr/bin/python3
"""Genera los esquemas de color de Uzunyx (KDE .colors) y los de Konsole.

Dos ediciones, solo oscuras: Akane (carmesí, el del logo y los botones) y
Sora (cian). Comparten los neutros y cambian solo los acentos. La estructura
y los colores de estado (positivo, neutro, negativo) siguen a Breeze Oscuro.

Uso: gen-colors.py [directorio] [directorio de Konsole]
     (por defecto ./color-schemes y ./konsole)
"""

import os
import sys

# Neutros comunes. Ventana = paneles y ventanas; vista = zonas de contenido
# (listas, campos de texto), un poco más oscura, como en Breeze; superficie =
# menús, botones y emergentes; borde = divisores y alternos.
NEUTRAL = {
    "view": "#0d0e12",
    "view_alt": "#15171c",
    "window": "#111318",
    "window_alt": "#181a20",
    "header": "#181a20",
    "surface": "#20232b",
    "border": "#343944",
    "text": "#f2f2f7",
    "text_inactive": "#a0a4b0",
}

# Acentos de cada edición, de ChatGPT. Los de Akane, girados 9° hacia el
# carmesí del logo (#f00050) conservando saturación y brillo; los originales
# en el comentario.
EDITIONS = {
    "Akane": {
        "accent": "#e62967",      # Magenta     #E62983
        "bright": "#ff5c90",      # Rosa vivo   #FF5CA8
        "light": "#ffb5cc",       # Rosa claro  #FFB5D7
        "selected": "#a51e4e",    # Frambuesa   #A51E62
        "soft": "#651a3b",        # Ciruela     #651A46
        "charcoal": "#29171d",    # Carbón rosado #291720
    },
    "Sora": {
        "accent": "#16cde0",      # Cian
        "bright": "#32e6f2",      # Cian eléctrico
        "light": "#a3f5f5",       # Cian claro
        "selected": "#078fa8",    # Turquesa
        "soft": "#14536d",        # Azul profundo
        "charcoal": "#12212b",    # Carbón azulado
    },
}

# Colores de estado, los de Breeze Oscuro (normal y sobre selección).
STATUS = {
    "negative": "#da4453", "neutral": "#f67400", "positive": "#27ae60",
}
STATUS_ON_SELECTION = {
    "negative": "#b03745", "neutral": "#c65c00", "positive": "#176839",
}


def rgb(h):
    h = h.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def group(name, bg, bg_alt, acc, *, on_selection=False):
    n = NEUTRAL
    status = STATUS_ON_SELECTION if on_selection else STATUS
    keys = {
        "BackgroundAlternate": bg_alt,
        "BackgroundNormal": bg,
        "DecorationFocus": acc["accent"],
        "DecorationHover": acc["bright"],
        "ForegroundActive": n["text"] if on_selection else acc["bright"],
        "ForegroundInactive": acc["light"] if on_selection else n["text_inactive"],
        "ForegroundLink": n["text"] if on_selection else acc["bright"],
        "ForegroundNegative": status["negative"],
        "ForegroundNeutral": status["neutral"],
        "ForegroundNormal": n["text"],
        "ForegroundPositive": status["positive"],
        "ForegroundVisited": acc["light"],
    }
    lines = [f"[Colors:{name}]"]
    lines += [f"{k}={rgb(v)}" for k, v in keys.items()]
    return "\n".join(lines)


def scheme(edition, acc):
    n = NEUTRAL
    parts = [f"""# Uzunyx {edition}, generado por gen-colors.py; no editar a mano.
# SPDX-License-Identifier: LGPL-2.0-or-later

[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0
"""]
    parts.append(group("Button", n["surface"], acc["soft"], acc))
    # Complementario: pantalla de bloqueo, OSD, fondo del lanzador.
    parts.append(group("Complementary", acc["charcoal"], acc["soft"], acc))
    parts.append(group("Header", n["header"], n["window"], acc))
    parts.append(group("Header][Inactive", n["window"], n["header"], acc))
    parts.append(group("Selection", acc["selected"], acc["soft"], acc,
                       on_selection=True))
    parts.append(group("Tooltip", n["surface"], n["window_alt"], acc))
    parts.append(group("View", n["view"], n["view_alt"], acc))
    parts.append(group("Window", n["window"], n["window_alt"], acc))
    parts.append(f"""[General]
ColorScheme=Uzunyx{edition}
Name=Uzunyx {edition}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={rgb(n["header"])}
activeBlend={rgb(n["text"])}
activeForeground={rgb(n["text"])}
inactiveBackground={rgb(n["window"])}
inactiveBlend={rgb(n["text_inactive"])}
inactiveForeground={rgb(n["text_inactive"])}
""")
    return "\n\n".join(p.rstrip("\n") for p in parts) + "\n"


# ANSI de Konsole: normal, intenso. Las letras llevan la edición: el texto un
# poco teñido, y verde (el prompt de bash) y azul (carpetas) en sus tonos; el
# rojo se aparta del acento para seguir siendo error, y el amarillo no cambia.
ANSI_COMMON = {
    0: ("#20232b", "#6b7080"),
    3: ("#d9a441", "#f2c661"),
    7: ("#d4d6de", "#ffffff"),
}
ANSI_EDITION = {
    "Akane": {
        1: ("#f0653a", "#ff8a5c"),
        2: ("#e62967", "#ff5c90"),
        4: ("#b57bd6", "#d8a8f0"),
        5: ("#ff5c90", "#ffb5cc"),
        6: ("#4bbcc9", "#7fd8e2"),
    },
    "Sora": {
        1: ("#e5534b", "#ff7b72"),
        2: ("#16cde0", "#32e6f2"),
        4: ("#4f8fe6", "#7fb0f5"),
        5: ("#b77fe0", "#d3a5f0"),
        6: ("#32d6b0", "#6feccb"),
    },
}
KONSOLE_TEXT = {"Akane": "#ffe6ee", "Sora": "#e2fbfd"}


def faint(h):
    h = h.lstrip("#")
    return "#" + "".join(f"{int(h[i:i + 2], 16) * 2 // 3:02x}" for i in (0, 2, 4))


def konsole_scheme(edition):
    n = NEUTRAL
    ansi = {**ANSI_COMMON, **ANSI_EDITION[edition]}
    parts = [f"# Uzunyx {edition}, generado por gen-colors.py; no editar a mano."]

    def color(name, value):
        parts.append(f"[{name}]\nColor={rgb(value)}")

    color("Background", n["window"])
    color("BackgroundFaint", n["window"])
    color("BackgroundIntense", n["window_alt"])
    for i, (normal, intense) in sorted(ansi.items()):
        color(f"Color{i}", normal)
        color(f"Color{i}Faint", faint(normal))
        color(f"Color{i}Intense", intense)
    color("Foreground", KONSOLE_TEXT[edition])
    color("ForegroundFaint", n["text_inactive"])
    color("ForegroundIntense", EDITIONS[edition]["light"])
    parts.append(f"[General]\nBlur=false\nColorRandomization=false\n"
                 f"Description=Uzunyx {edition}\nOpacity=1\nWallpaper=")
    return "\n\n".join(parts) + "\n"


def konsole_profile(edition):
    return f"""[Appearance]
ColorScheme=Uzunyx{edition}

[General]
Command=/usr/bin/zsh
Environment=TERM=xterm-256color,COLORTERM=truecolor,ZDOTDIR=/usr/share/uzunyx-terminal/zsh
Name=Uzunyx {edition}
Parent=FALLBACK/
"""


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "color-schemes"
    konsole = sys.argv[2] if len(sys.argv) > 2 else "konsole"
    os.makedirs(konsole, exist_ok=True)
    for edition in EDITIONS:
        for name, text in ((f"Uzunyx{edition}.colorscheme", konsole_scheme(edition)),
                           (f"Uzunyx{edition}.profile", konsole_profile(edition))):
            path = os.path.join(konsole, name)
            with open(path, "w") as f:
                f.write(text)
            print(path)
    os.makedirs(out, exist_ok=True)
    for edition, acc in EDITIONS.items():
        path = os.path.join(out, f"Uzunyx{edition}.colors")
        with open(path, "w") as f:
            f.write(scheme(edition, acc))
        print(path)


if __name__ == "__main__":
    main()
