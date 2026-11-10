#!/usr/bin/python3
"""Genera las imágenes del tema de GRUB de Uzunyx.

    gen-grub.py <directorio>

- select_*.png: el fondo del elemento elegido del menú, en 9 piezas (GRUB
  estira los lados y el centro): superficie #20232B, borde de 1 px del
  texto al 25 % y esquinas de 8 px, como las ventanas de Uzunyx.
- terminal_box_*.png: el mismo marco para la consola y el editor.
- background.png: #111318 liso, el fondo de la paleta (también lo que se ve
  mientras el menú está oculto, igual que en Plymouth).
"""
import os
import sys

import cairo

BG = (0x11 / 255, 0x13 / 255, 0x18 / 255)
SURFACE = (0x20 / 255, 0x23 / 255, 0x2B / 255)
TEXT = (0xF2 / 255, 0xF2 / 255, 0xF7 / 255)
R = 8           # radio de las esquinas
SIZE = 2 * R + 1


def box():
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, SIZE, SIZE)
    cr = cairo.Context(surface)

    def rounded(inset, radius):
        x = y = inset
        w = h = SIZE - 2 * inset
        cr.new_sub_path()
        cr.arc(x + w - radius, y + radius, radius, -1.5708, 0)
        cr.arc(x + w - radius, y + h - radius, radius, 0, 1.5708)
        cr.arc(x + radius, y + h - radius, radius, 1.5708, 3.1416)
        cr.arc(x + radius, y + radius, radius, 3.1416, 4.7124)
        cr.close_path()

    # Borde: el anillo entre el contorno y 1 px adentro, relleno (como el
    # del panel), sobre la superficie.
    rounded(0, R)
    cr.set_source_rgb(*SURFACE)
    cr.fill()
    rounded(0, R)
    rounded(1, R - 1)
    cr.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    cr.set_source_rgba(*TEXT, 0.25)
    cr.fill()
    return surface


def piece(src, x, y, w, h, path):
    out = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(out)
    cr.set_source_surface(src, -x, -y)
    cr.paint()
    out.write_to_png(path)


def main():
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    src = box()
    # nombre: x, y, ancho, alto dentro de la caja de SIZE×SIZE
    pieces = {
        'nw': (0, 0, R, R), 'n': (R, 0, 1, R), 'ne': (R + 1, 0, R, R),
        'w': (0, R, R, 1), 'c': (R, R, 1, 1), 'e': (R + 1, R, R, 1),
        'sw': (0, R + 1, R, R), 's': (R, R + 1, 1, R), 'se': (R + 1, R + 1, R, R),
    }
    for prefix in ('select', 'terminal_box'):
        for name, (x, y, w, h) in pieces.items():
            piece(src, x, y, w, h, os.path.join(outdir, f'{prefix}_{name}.png'))

    bg = cairo.ImageSurface(cairo.FORMAT_RGB24, 64, 64)
    cr = cairo.Context(bg)
    cr.set_source_rgb(*BG)
    cr.paint()
    bg.write_to_png(os.path.join(outdir, 'background.png'))


if __name__ == '__main__':
    main()
