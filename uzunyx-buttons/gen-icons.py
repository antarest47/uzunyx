#!/usr/bin/python3
"""Genera el tema de iconos «uzunyx», que hereda de Kora y solo trae:

- window-{minimize,maximize,restore,close}-symbolic en PNG (botones de
  ventana de colores).
- Las carpetas (genérica y de la carpeta personal) y el icono de Dolphin, en
  SVG, más los nombres alternativos con que las piden algunas apps.
- Sus versiones -symbolic, enlazadas a las de Kora. Sin ellas, al pedir p. ej.
  user-desktop-symbolic («Mostrar escritorio» del panel) se busca primero
  user-desktop en este tema, antes que en Kora, y sale la carpeta de color.

Uso: gen-icons.py <SVG de los botones> <SVG de las carpetas> <directorio del tema>
     gen-icons.py - <SVG de las carpetas> <directorio del tema> <nombre>

La segunda forma hace un tema con solo las carpetas que hereda de «uzunyx»
(«uzunyx-sora»: las carpetas de Sora; «uzunyx» trae las de Akane).

Firefox y Chromium/Electron dibujan sus botones de ventana con esos iconos.
GTK repinta de un solo color los iconos simbólicos en SVG, pero no los PNG,
que conservan sus colores. Van en carpetas de tamaño fijo porque Chromium los
dibuja a su tamaño real (un PNG grande se recorta). Restaurar usa la misma
imagen que maximizar.
"""

import os
import shutil
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

BUTTON_ICONS = {
    "window-minimize-symbolic": "minimize",
    "window-maximize-symbolic": "maximize",
    "window-restore-symbolic": "maximize",
    "window-close-symbolic": "close",
}
BUTTON_SIZES = (16, 24, 32)
BUTTON_SCALES = (1, 2)

# Carpetas: icono -> nombres alternativos (los mismos que tiene Kora)
PLACES = {
    "folder": ["inode-directory"],
    "folder-documents": [],
    "folder-download": ["folder-downloads"],
    "folder-music": [],
    "folder-pictures": [],
    "folder-publicshare": ["folder-public"],
    "folder-templates": [],
    "folder-videos": [],
    "user-desktop": ["folder-desktop"],
    "user-home": ["folder-home"],
}
APPS = {
    "org.kde.dolphin": ["system-file-manager"],
}
# Versión simbólica de Kora para cada icono de arriba (y sus alias)
KORA = "/usr/share/icons/kora"
KORA_SYMBOLIC = {
    "folder": "places/symbolic/folder-symbolic.svg",
    "folder-documents": "places/symbolic/folder-documents-symbolic.svg",
    "folder-download": "places/symbolic/folder-download-symbolic.svg",
    "folder-music": "places/symbolic/folder-music-symbolic.svg",
    "folder-pictures": "places/symbolic/folder-pictures-symbolic.svg",
    "folder-publicshare": "places/symbolic/folder-publicshare-symbolic.svg",
    "folder-templates": "places/symbolic/folder-templates-symbolic.svg",
    "folder-videos": "places/symbolic/folder-videos-symbolic.svg",
    "user-desktop": "places/symbolic/user-desktop-symbolic.svg",
    "user-home": "places/symbolic/user-home-symbolic.svg",
    "org.kde.dolphin": "apps/symbolic/system-file-manager-symbolic.svg",
}

INDEX = """[Icon Theme]
Name=Uzunyx
Comment=Kora with the Uzunyx folders and window buttons
Comment[es]=Kora con las carpetas y los botones de ventana de Uzunyx
Inherits=kora,breeze,hicolor
Example=folder
Directories={dirs}
"""

FOLDERS_INDEX = """[Icon Theme]
Name={name}
Comment=Uzunyx with the {edition} folders
Comment[es]=Uzunyx con las carpetas de {edition}
Inherits=uzunyx,kora,breeze,hicolor
Example=folder
Directories={dirs}
"""

FIXED = """
[{dir}]
Size={size}
Scale={scale}
Context=Actions
Type=Fixed
"""

SCALABLE = """
[{dir}]
Size={size}
MinSize=8
MaxSize=512
Context={context}
Type=Scalable
"""


def button_dir(size, scale):
    return f"actions/{size}" + (f"@{scale}x" if scale > 1 else "")


def install_scalable(src, out, subdir, icons):
    d = os.path.join(out, subdir)
    os.makedirs(d, exist_ok=True)
    for icon, aliases in icons.items():
        shutil.copyfile(os.path.join(src, icon + ".svg"), os.path.join(d, icon + ".svg"))
        for alias in aliases:
            os.symlink(icon + ".svg", os.path.join(d, alias + ".svg"))


def install_symbolic(out, subdir, icons):
    """Enlaces <icono>-symbolic.svg (y de sus alias) a los de Kora."""
    d = os.path.join(out, subdir)
    os.makedirs(d, exist_ok=True)
    for icon, aliases in icons.items():
        target = KORA_SYMBOLIC[icon]
        if not os.path.exists(os.path.join(KORA, target)):
            sys.exit(f"falta {KORA}/{target}")
        installed = os.path.join("/usr/share/icons", os.path.basename(os.path.normpath(out)), subdir)
        link = os.path.relpath(os.path.join(KORA, target), installed)
        for name in [icon] + aliases:
            os.symlink(link, os.path.join(d, name + "-symbolic.svg"))


def write_folder_dirs(f):
    f.write(SCALABLE.format(dir="places/scalable", size=22, context="Places"))
    f.write(SCALABLE.format(dir="apps/scalable", size=16, context="Applications"))
    f.write(SCALABLE.format(dir="places/symbolic", size=16, context="Places"))
    f.write(SCALABLE.format(dir="apps/symbolic", size=16, context="Applications"))


def install_folders(folders, out):
    install_scalable(folders, out, "places/scalable", PLACES)
    install_scalable(folders, out, "apps/scalable", APPS)
    install_symbolic(out, "places/symbolic", PLACES)
    install_symbolic(out, "apps/symbolic", APPS)


def main():
    buttons, folders, out = sys.argv[1:4]
    extra = ["places/scalable", "apps/scalable", "places/symbolic", "apps/symbolic"]
    if buttons == "-":
        install_folders(folders, out)
        edition = sys.argv[4].split("-")[-1].capitalize()
        with open(os.path.join(out, "index.theme"), "w") as f:
            f.write(FOLDERS_INDEX.format(name="Uzunyx " + edition, edition=edition, dirs=",".join(extra)))
            write_folder_dirs(f)
        return
    dirs = [button_dir(size, scale) for size in BUTTON_SIZES for scale in BUTTON_SCALES]
    for size in BUTTON_SIZES:
        for scale in BUTTON_SCALES:
            d = os.path.join(out, button_dir(size, scale))
            os.makedirs(d, exist_ok=True)
            px = size * scale
            for icon, button in BUTTON_ICONS.items():
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                    os.path.join(buttons, f"{button}-normal.svg"), px, px)
                pixbuf.savev(os.path.join(d, icon + ".png"), "png", [], [])
    install_folders(folders, out)
    with open(os.path.join(out, "index.theme"), "w") as f:
        f.write(INDEX.format(dirs=",".join(dirs + extra)))
        for size in BUTTON_SIZES:
            for scale in BUTTON_SCALES:
                f.write(FIXED.format(dir=button_dir(size, scale), size=size, scale=scale))
        write_folder_dirs(f)


if __name__ == "__main__":
    main()
