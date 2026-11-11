# lunyx

Receta del paquete de Lunyx (repo aparte, https://github.com/antarest47/lunyx; `make
fetch` lo clona en `~/claude/lunyx` la primera vez, lo pone en el commit fijado y baja
las dependencias; `LUNYX_URL=` para otra dirección). Sin Flatpak:
usa PySide6, libVLC y `keyring` de Debian, y lleva dentro `smbprotocol` y `pyspnego`,
que no están en Debian (Python puro, con SHA256 en `fetch-wheels.py`). Para pasar a
una versión nueva de Lunyx, cambiar `LUNYX_COMMIT` en el `Makefile`.

Corre en XWayland porque libVLC embebe el video por X11. El id de la ventana es el del
Flatpak (`io.github.antarest47.Lunyx`), que Lunyx fija en `main.py`: el `.desktop` y el
icono llevan ese nombre para que el gestor de tareas los reconozca.
