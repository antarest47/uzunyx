#!/usr/bin/python3
"""Vista previa del tema sin Plymouth: reproduce con cairo lo que hace
uzunyx.script (misma disposición y tiempos) y escribe los cuadros en PNG.

    preview.py <dir. de imágenes generadas> <dir. de salida> [ancho alto]

Con «--password» dibuja además el campo de contraseña con 6 caracteres.
"""
import math
import os
import sys

import cairo

FRAMES, TPF, PAUSE, FADE_IN = 36, 2, 110, 25
CYCLE = FRAMES * TPF + PAUSE
GLINTS = [(0.0925, 0.5925, 1.0), (0.5401, 0.7196, 1.0), (0.9406, 0.4461, 0.6),
          (0.9558, 0.5580, 0.45), (0.1326, 0.6823, 0.45), (0.6552, 0.6823, 0.45)]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    password = '--password' in sys.argv
    src, out = args[0], args[1]
    W, H = (int(args[2]), int(args[3])) if len(args) > 3 else (1920, 1200)
    suffix, base = ('@2x', 2) if H >= 1800 else ('', 1)
    S = H / 1200 / base
    if 0.95 < S < 1.05:
        S = 1
    os.makedirs(out, exist_ok=True)
    img = {n: cairo.ImageSurface.create_from_png(os.path.join(src, n + suffix + '.png'))
           for n in ('icon', 'logo', 'glint', 'entry', 'bullet')}
    shine = [cairo.ImageSurface.create_from_png(os.path.join(src, f'shine-{i:02d}{suffix}.png'))
             for i in range(FRAMES)]

    iw, ih = img['icon'].get_width() * S, img['icon'].get_height() * S
    lw, lh = img['logo'].get_width() * S, img['logo'].get_height() * S
    gap = int(24 * H / 1200)
    top = int((H - (ih + gap + lh)) / 2 - H * 0.03)
    LX, LY = int((W - lw) / 2), top + ih + gap

    def put(cr, surf, x, y, scale, alpha=1.0):
        cr.save()
        cr.translate(x, y)
        cr.scale(scale, scale)
        cr.set_source_surface(surf, 0, 0)
        cr.get_source().set_filter(cairo.FILTER_GOOD)
        cr.paint_with_alpha(alpha)
        cr.restore()

    ticks = range(TPF, FADE_IN + CYCLE + 1, TPF) if not password else [FADE_IN + FRAMES * TPF]
    for k, tick in enumerate(ticks):
        surf = cairo.ImageSurface(cairo.FORMAT_RGB24, W, H)
        cr = cairo.Context(surf)
        cr.set_source_rgb(0x11 / 255, 0x13 / 255, 0x18 / 255)
        cr.paint()
        fade = min(tick / FADE_IN, 1)
        put(cr, img['icon'], int((W - iw) / 2), top, S, fade)
        put(cr, img['logo'], LX, LY, S, fade)
        f = (tick % CYCLE) // TPF
        if tick > FADE_IN and f < FRAMES:
            put(cr, shine[f], LX, LY, S)
        g = img['glint']
        for i, (gx, gy, gs) in enumerate(GLINTS):
            p = ((tick + i * 31) % 160) / 40
            a = math.sin(p * math.pi) if p < 1 else 0
            d = g.get_width() * S * gs
            put(cr, g, LX + gx * lw - d / 2, LY + gy * lh - d / 2, S * gs, a * a * fade)
        if password:
            e, b = img['entry'], img['bullet']
            ew, eh = e.get_width() * S, e.get_height() * S
            EX, EY = int((W - ew) / 2), LY + lh + int(32 * H / 1200)
            put(cr, e, EX, EY, S)
            cr.select_font_face('Noto Sans')
            cr.set_font_size(16 * H / 1200)
            cr.set_source_rgba(0.95, 0.95, 0.97, 1)
            text = 'Contraseña para desbloquear el disco'
            ext = cr.text_extents(text)
            cr.move_to((W - ext.width) / 2, EY - 10 * H / 1200 - 4)
            cr.show_text(text)
            bw = b.get_width() * S
            step = int(bw * 1.8)
            x0 = int((W - 6 * step) / 2 + (step - bw) / 2)
            for i in range(6):
                put(cr, b, x0 + i * step, EY + (eh - bw) / 2, S)
        surf.write_to_png(os.path.join(out, f'frame-{k:03d}.png'))


if __name__ == '__main__':
    main()
