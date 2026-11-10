#!/usr/bin/python3
"""Genera las imágenes del tema Plymouth de una edición de Uzunyx.

    gen-theme.py <edición> <dir. de salida> [--preview <dir>]

El tema (uzunyx.script) es el mismo para las dos ediciones; aquí cambian los
colores y el logo. Plymouth no puede recortar ni mezclar en vivo, así que el
brillo que recorre el nombre se genera de antemano: shine-NN.png son capas
blancas semitransparentes, ya recortadas con la forma del logo, que el script
pone encima del nombre una tras otra.

Cada imagen va en dos tamaños: el que tiene en una pantalla de 1200 px de alto
(«logo.png») y el doble para HiDPI («logo@2x.png»). El script elige el juego
según la altura de la pantalla y solo escala lo que falta: Plymouth escala
mal la transparencia (el negro de los píxeles transparentes se mete en los
bordes, que salían dentados y con puntos oscuros cuando las imágenes iban a
1,5× y se achicaban al cargar).
"""
import math
import os
import sys

import cairo

HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.join(HERE, '..', 'icons')

# Paleta de la distro (la de uzunyx-colors: en Akane, los acentos están
# girados hacia el carmesí del logo). El fondo,
# #111318 liso, lo pone uzunyx.script con Window.SetBackground*Color.
BG = '#111318'
SURFACE = '#20232B'
BORDER = '#343944'
TEXT = '#F2F2F7'
EDITIONS = {
    'akane': {'accent': '#E62967'},
    'sora': {'accent': '#16CDE0'},
}

SCALES = {'': 1, '@2x': 2}  # sufijo: tamaño respecto a una pantalla de 1200 px
SCALE = 1            # el del juego que se está generando (main)
LOGO_W = 520         # ancho del nombre en esa pantalla
ICON_W = 220         # ancho del icono
FRAMES = 36          # cuadros de la pasada del brillo
BAND = 0.16          # ancho de la banda de brillo (fracción del ancho del logo)
SLANT = 0.35         # inclinación de la banda (desplazamiento x por unidad de y)
PEAK = 0.62          # opacidad máxima del brillo



def rgb(h, a=1.0):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)) + (a,)


def on_background(surface):
    """La imagen ya mezclada sobre el fondo #111318, opaca: Plymouth mezcla
    mal la transparencia (los bordes del nombre salían dentados y con puntos
    oscuros aun sin escalar) y el fondo es liso, así que no se nota el
    rectángulo."""
    out = cairo.ImageSurface(cairo.FORMAT_RGB24, surface.get_width(), surface.get_height())
    cr = cairo.Context(out)
    cr.set_source_rgb(*rgb(BG)[:3])
    cr.paint()
    cr.set_source_surface(surface, 0, 0)
    cr.paint()
    return out


def load_scaled(path, width):
    src = cairo.ImageSurface.create_from_png(path)
    s = width / src.get_width()
    w, h = round(src.get_width() * s), round(src.get_height() * s)
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(out)
    cr.scale(s, s)
    cr.set_source_surface(src, 0, 0)
    cr.get_source().set_filter(cairo.FILTER_BEST)
    cr.paint()
    return out


def shine_frame(logo, t):
    """Capa de brillo en el instante t (0..1) de la pasada."""
    w, h = logo.get_width(), logo.get_height()
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(out)
    band = BAND * w
    # Centro de la banda a media altura, de fuera por la izquierda a fuera
    # por la derecha (contando la inclinación).
    span = w + 2 * band + SLANT * h
    cx = -band - SLANT * h / 2 + t * span
    # Gradiente perpendicular a la banda inclinada.
    dx, dy = 1.0, -SLANT
    n = math.hypot(dx, dy)
    dx, dy = dx / n, dy / n
    half = band / 2
    g = cairo.LinearGradient(cx - dx * half, h / 2 - dy * half,
                             cx + dx * half, h / 2 + dy * half)
    for stop, a in ((0, 0), (0.35, 0.55), (0.5, 1), (0.65, 0.55), (1, 0)):
        g.add_color_stop_rgba(stop, 1, 1, 1, a * PEAK)
    cr.set_source(g)
    cr.mask_surface(logo, 0, 0)
    return out


def glint(size, color):
    """Destello de cuatro puntas con halo, del color dado."""
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    cr = cairo.Context(out)
    c = size / 2
    r, g_, b, _ = rgb(color)
    halo = cairo.RadialGradient(c, c, 0, c, c, c * 0.55)
    halo.add_color_stop_rgba(0, r, g_, b, 0.55)
    halo.add_color_stop_rgba(1, r, g_, b, 0)
    cr.set_source(halo)
    cr.paint()
    # Puntas: rombos finos, blancos en el centro.
    for ang in (0, math.pi / 2):
        cr.save()
        cr.translate(c, c)
        cr.rotate(ang)
        cr.move_to(-c, 0)
        cr.curve_to(-c * 0.15, -c * 0.035, -c * 0.035, -c * 0.035, 0, -c * 0.06)
        cr.curve_to(c * 0.035, -c * 0.035, c * 0.15, -c * 0.035, c, 0)
        cr.curve_to(c * 0.15, c * 0.035, c * 0.035, c * 0.035, 0, c * 0.06)
        cr.curve_to(-c * 0.035, c * 0.035, -c * 0.15, c * 0.035, -c, 0)
        cr.close_path()
        lg = cairo.LinearGradient(-c, 0, c, 0)
        lg.add_color_stop_rgba(0, 1, 1, 1, 0)
        lg.add_color_stop_rgba(0.5, 1, 1, 1, 1)
        lg.add_color_stop_rgba(1, 1, 1, 1, 0)
        cr.set_source(lg)
        cr.fill()
        cr.restore()
    core = cairo.RadialGradient(c, c, 0, c, c, c * 0.12)
    core.add_color_stop_rgba(0, 1, 1, 1, 1)
    core.add_color_stop_rgba(1, 1, 1, 1, 0)
    cr.set_source(core)
    cr.paint()
    return out


def rounded(cr, x, y, w, h, r):
    cr.new_sub_path()
    cr.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    cr.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    cr.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    cr.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    cr.close_path()


def entry(w=300, h=40):
    """Campo de contraseña: superficie elevada, borde del texto al 25 % y
    esquinas de 8 px, como las ventanas."""
    w, h, r = round(w * SCALE), round(h * SCALE), 8 * SCALE
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(out)
    rounded(cr, 0, 0, w, h, r)
    cr.set_source_rgba(*rgb(TEXT, 0.25))
    cr.fill()
    rounded(cr, SCALE, SCALE, w - 2 * SCALE, h - 2 * SCALE, r - SCALE)
    cr.set_source_rgba(*rgb(SURFACE))
    cr.fill()
    return out


def bullet(color, d=10):
    d = round(d * SCALE)
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, d, d)
    cr = cairo.Context(out)
    cr.arc(d / 2, d / 2, d / 2, 0, 2 * math.pi)
    cr.set_source_rgba(*rgb(color))
    cr.fill()
    return out


def main():
    global SCALE
    edition, outdir = sys.argv[1], sys.argv[2]
    ed = EDITIONS[edition]
    os.makedirs(outdir, exist_ok=True)

    for suffix, SCALE in SCALES.items():
        def out(name):
            return os.path.join(outdir, f'{name}{suffix}.png')

        logo = load_scaled(os.path.join(HERE, 'art', f'uzunyx-logo-{edition}.png'),
                           round(LOGO_W * SCALE))
        on_background(logo).write_to_png(out('logo'))
        on_background(load_scaled(os.path.join(ICONS, f'uzunyx-icon-{edition}.png'),
                                  round(ICON_W * SCALE))).write_to_png(out('icon'))
        for i in range(FRAMES):
            shine_frame(logo, i / (FRAMES - 1)).write_to_png(out(f'shine-{i:02d}'))
        glint(round(56 * SCALE), ed['accent']).write_to_png(out('glint'))
        entry().write_to_png(out('entry'))
        bullet(ed['accent']).write_to_png(out('bullet'))



if __name__ == '__main__':
    main()
