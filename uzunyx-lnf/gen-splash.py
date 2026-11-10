#!/usr/bin/python3
"""Genera las imágenes de la pantalla de inicio (KSplash) de una edición.

Uso: gen-splash.py <icono PNG> <nombre PNG> <color de acento> <directorio>

Escribe icon.png, logo.png y glint.png al doble del tamaño con que se ven en
una pantalla de 1200 px de alto (Splash.qml las escala a la pantalla). Son
los mismos dibujos que la pantalla de arranque (uzunyx-plymouth): el
destello sale de su gen-theme.py, para que los dos se vean iguales.
"""

import importlib.util
import os
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ICON_W = 220 * 2
LOGO_W = 520 * 2
GLINT = 56 * 2


def scaled(src, width, dest):
    pixbuf = GdkPixbuf.Pixbuf.new_from_file(src)
    height = round(pixbuf.get_height() * width / pixbuf.get_width())
    pixbuf.scale_simple(width, height, GdkPixbuf.InterpType.HYPER).savev(dest, "png", [], [])
    os.chmod(dest, 0o644)


def main():
    icon, logo, accent, outdir = sys.argv[1:5]
    os.makedirs(outdir, exist_ok=True)
    scaled(icon, ICON_W, os.path.join(outdir, "icon.png"))
    scaled(logo, LOGO_W, os.path.join(outdir, "logo.png"))

    spec = importlib.util.spec_from_file_location(
        "plymouth_theme", os.path.join(HERE, "..", "uzunyx-plymouth", "gen-theme.py"))
    plymouth = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(plymouth)
    path = os.path.join(outdir, "glint.png")
    plymouth.glint(GLINT, accent).write_to_png(path)
    os.chmod(path, 0o644)


if __name__ == "__main__":
    main()
