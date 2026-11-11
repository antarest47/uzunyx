#!/usr/bin/python3
"""Carpetas de cada edición (Akane y Sora).

Uso: gen-folders.py <iconos-carpetas-v2> <salida>

Escribe <salida>/akane y <salida>/sora. Toma el emblema (el grupo con
fill="url(#gg)") de cada SVG de iconos-carpetas-v2, y el delfín de Dolphin, y
los pone sobre la carpeta: pestaña de atrás en el acento, frente gris oscuro
con brillo arriba, curvas blanca y del acento abajo a la derecha (como los
mechones del logo) y borde blanco tenue. Modelo del usuario (2026-11-08);
variante «C» de la maqueta, elegida por el usuario el mismo día.

La carpeta común y Dolphin llevan los colores del logo de cada edición; las
carpetas de la carpeta personal, un color propio cada una, el mismo en las
dos ediciones (PLACES; elegido por el usuario el 2026-11-10).
"""

import colorsys
import os
import re
import sys

# Colores sacados de los logos (icons/uzunyx-icon-{akane,sora}.png)
LOGO = {
    "akane": {"white": "#FBF6F8", "pearl": "#EFE5EA", "shade": "#CDA8B7",
              "accent": "#E81557", "bright": "#FF3D78", "dark": "#A30926", "deep": "#600C17",
              "ink": "#3B3236", "ink2": "#231D20"},
    "sora": {"white": "#F7FAFE", "pearl": "#E9F1FA", "shade": "#ABD4EF",
             "accent": "#2AA9D6", "bright": "#0EE8F9", "dark": "#0B689E", "deep": "#144063",
             "ink": "#30353D", "ink2": "#1C1F25"},
}

# Un color por lugar, igual en Akane y Sora, con un gris neutro en el frente
PLACES = {
    "user-home": "#F5B700",           # ámbar
    "user-desktop": "#6366F1",        # índigo
    "folder-documents": "#3B82F6",    # azul
    "folder-download": "#22C55E",     # verde
    "folder-music": "#FF7A1F",        # naranja
    "folder-pictures": "#A855F7",     # violeta
    "folder-videos": "#EF4444",       # rojo
    "folder-publicshare": "#14B8A6",  # turquesa
    "folder-templates": "#84CC16",    # lima
}
NEUTRAL_INK = ("#36353A", "#201F23")


def place_colours(hexc):
    """Los mismos tonos que LOGO, sacados de un solo color."""
    r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)

    def tone(light, sat=s):
        r, g, b = colorsys.hls_to_rgb(h, max(0, min(1, light)), max(0, min(1, sat)))
        return "#%02X%02X%02X" % (round(r * 255), round(g * 255), round(b * 255))

    return {"white": tone(.97, .6), "pearl": tone(.92, .5), "shade": tone(.80, .55),
            "accent": hexc, "bright": tone(l + .10), "dark": tone(l - .22),
            "deep": tone(l - .32), "ink": NEUTRAL_INK[0], "ink2": NEUTRAL_INK[1]}


def palette(c):
    """Colores de cada parte de la carpeta (variante «C»)."""
    return dict(back0=c["bright"], back1=c["dark"], glow=c["white"], glowa=".35",
                lip0=c["white"], lip1=c["white"],
                front0=c["ink"], front1=c["ink2"],
                sw1=c["accent"], sw1b=c["dark"], sw2=c["white"], sw2a="1",
                emb0=c["white"], emb1=c["shade"], edge="#FFFFFF", edgea=".3",
                detail=c["ink2"])


# 216 x 208 en 256: más alta que el modelo (pedido por el usuario), con la
# misma franja de arriba (pestaña y borde claro).
BACK = ("M20,40 Q20,26 34,26 L86,26 Q92,26 96,30 L108,43 Q112,47 118,47 "
        "L222,47 Q236,47 236,61 L236,220 Q236,234 222,234 L34,234 Q20,234 20,220 Z")
FRONT = ("M20,92 Q20,80 32,80 L100,80 Q106,80 110,76 L113,73 Q118,67 125,67 "
         "L224,67 Q236,67 236,79 L236,222 Q236,234 224,234 L32,234 Q20,234 20,222 Z")
SWOOSH = "M136,236 Q212,219 238,141 L238,163 Q220,221 158,236 Z"
# Curva blanca más fina, por dentro de la del acento (como el pelo del logo)
SWOOSH2 = "M118,236 Q200,222 238,128 L238,138 Q206,226 132,236 Z"

TEMPLATE = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="ub" x1="0" y1="0" x2="0.4" y2="1">
      <stop offset="0" stop-color="{back0}"/><stop offset="1" stop-color="{back1}"/>
    </linearGradient>
    <radialGradient id="ug" gradientUnits="userSpaceOnUse" cx="70" cy="40" r="60">
      <stop offset="0" stop-color="{glow}" stop-opacity="{glowa}"/><stop offset="1" stop-color="{glow}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="ul" gradientUnits="userSpaceOnUse" x1="20" y1="0" x2="236" y2="0">
      <stop offset="0" stop-color="{lip0}" stop-opacity=".7"/><stop offset="1" stop-color="{lip1}"/>
    </linearGradient>
    <linearGradient id="uf" x1="0" y1="0" x2="0.3" y2="1">
      <stop offset="0" stop-color="{front0}"/><stop offset="1" stop-color="{front1}"/>
    </linearGradient>
    <linearGradient id="uk" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity=".28"/><stop offset=".35" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="us" gradientUnits="userSpaceOnUse" x1="150" y1="235" x2="236" y2="153">
      <stop offset="0" stop-color="{sw1}" stop-opacity=".3"/><stop offset=".55" stop-color="{sw1}"/>
      <stop offset="1" stop-color="{sw1b}"/>
    </linearGradient>
    <linearGradient id="gg" gradientUnits="userSpaceOnUse" x1="0" y1="138" x2="0" y2="202">
      <stop offset="0" stop-color="{emb0}"/><stop offset="1" stop-color="{emb1}"/>
    </linearGradient>
    <clipPath id="uc"><path d="{front}"/></clipPath>
    <path id="pf" d="{front}"/>
  </defs>
  <path d="{back}" fill="url(#ub)"/>
  <path d="{back}" fill="url(#ug)"/>
  <path d="{back}" fill="none" stroke="{edge}" stroke-opacity="{edgea}" stroke-width="1.5"/>
  <use href="#pf" transform="translate(0,-5)" fill="url(#ul)"/>
  <use href="#pf" fill="url(#uf)"/>
  <use href="#pf" fill="url(#uk)"/>
  <path d="{swoosh2}" fill="{sw2}" fill-opacity="{sw2a}" clip-path="url(#uc)"/>
  <path d="{swoosh}" fill="url(#us)" clip-path="url(#uc)"/>
  <use href="#pf" fill="none" stroke="{edge}" stroke-opacity="{edgea}" stroke-width="1.5"/>
{emblem}</svg>
"""

EMBLEM = re.compile(r'(  <g transform="translate\(0,-16\)">.*?\n  </g>\n)', re.S)


def dolphin(text, c):
    """Icono de Dolphin: la carpeta al revés, con el frente del acento y el
    delfín blanco, para que se distinga de las demás (idea «4» de la maqueta,
    elegida por el usuario el 2026-11-10; en 0.8.2 era una bola)."""
    defs = re.search(r'(    <g id="body">.*?</g>\n)', text, re.S).group(1)
    body = re.search(r'(  <g transform="translate\(58,82\).*?\n  </g>\n)', text, re.S).group(1)
    body = (body.replace('transform="translate(58,82) scale(0.117)"',
                         'transform="translate(128,152) rotate(-8) scale(0.13) translate(-600,-592)"')
            .replace("url(#gd)", c["white"]).replace("#a9d8ff", c["shade"])
            .replace("#8cc8f5", c["shade"]).replace("url(#gfin)", c["white"])
            .replace("#0a2f8f", c["dark"]))
    p = palette(c)
    p.update(front0=c["bright"], front1=c["dark"], back0=c["ink"], back1=c["ink2"],
             sw1=c["white"], sw1b=c["shade"], sw2=c["ink2"], edgea=".45")
    return TEMPLATE.format(back=BACK, front=FRONT, swoosh=SWOOSH, swoosh2=SWOOSH2,
                           emblem="  <defs>\n" + defs + "  </defs>\n" + body, **p)


def main(src, out):
    for ed, logo in LOGO.items():
        d = os.path.join(out, ed)
        os.makedirs(d, exist_ok=True)
        for name in sorted(os.listdir(src)):
            if not name.endswith(".svg"):
                continue
            with open(os.path.join(src, name)) as f:
                text = f.read()
            icon = name[:-len(".svg")]
            c = place_colours(PLACES[icon]) if icon in PLACES else logo
            p = palette(c)
            if icon == "org.kde.dolphin":
                svg = dolphin(text, c)
            else:
                m = EMBLEM.search(text)
                emblem = m.group(1) if m else ""
                # Detalles con color fijo: el del emblema y el fondo de la carpeta
                emblem = emblem.replace("#d552ea", p["emb1"]).replace("#2f3643", p["detail"])
                svg = TEMPLATE.format(back=BACK, front=FRONT, swoosh=SWOOSH, swoosh2=SWOOSH2,
                                      emblem=emblem, **p)
            with open(os.path.join(d, name), "w") as f:
                f.write(svg)


if __name__ == "__main__":
    main(*sys.argv[1:])
