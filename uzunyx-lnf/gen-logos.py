#!/usr/bin/python3
"""Instala un logo de Uzunyx como icono de aplicación en hicolor.

Uso: gen-logos.py <PNG cuadrado> <nombre del icono> <directorio hicolor>

Escribe <hicolor>/<N>x<N>/apps/<nombre>.png para cada tamaño. El botón del
lanzador del panel lo pide por nombre (uzunyx-akane, uzunyx-sora).
"""

import os
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

SIZES = (16, 22, 24, 32, 48, 64, 128, 256, 512)


def main():
    src, name, hicolor = sys.argv[1:4]
    for size in SIZES:
        d = os.path.join(hicolor, f"{size}x{size}", "apps")
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, name + ".png")
        GdkPixbuf.Pixbuf.new_from_file_at_size(src, size, size).savev(path, "png", [], [])
        os.chmod(path, 0o644)


if __name__ == "__main__":
    main()
