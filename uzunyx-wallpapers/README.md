# uzunyx-wallpapers

Fondos de Uzunyx (imágenes en `../wallpapers/`) como paquetes de fondo de
Plasma, y la configuración del sistema que los usa:

| Paquete de fondo | Imagen | Uso |
|---|---|---|
| `UzunyxAkane`, `UzunyxSora` | `wallpaper-uzunyx-{akane,sora}-lll.jpeg` | Fondo de escritorio de cada edición (lo fija su tema global) |
| `UzunyxAkaneSky`, `UzunyxSoraSky` | `sddm-uzunyx-{akane,sora}-lll.jpeg` | Pantalla de bloqueo e inicio de sesión de cada edición; Akane por defecto (`uzunyx-edition` cambia a la de Sora) |

- **Pantalla de bloqueo:** `/etc/xdg/kscreenlockerrc`. El tema global no escribe
  esta configuración en `~/.config/kdedefaults`, así que vale para todo usuario
  que no haya elegido otro fondo de bloqueo.
- **Inicio de sesión (SDDM):** tema `uzunyx` en
  `/usr/share/sddm/themes/uzunyx`: los archivos del tema Breeze de KDE
  (paquete `sddm-theme-breeze`) enlazados, con un `theme.conf` propio que usa
  el cielo de Akane de fondo. `/etc/sddm.conf.d/uzunyx.conf` lo activa.
  `uzunyx-edition --sddm` (paquete `uzunyx-editions`) cambia el fondo con un
  `theme.conf.user` en la carpeta del tema, como hace el módulo de SDDM de
  KDE.

## Instalar

    make deb
    sudo apt install ./build/uzunyx-wallpapers_0.5.0_all.deb
