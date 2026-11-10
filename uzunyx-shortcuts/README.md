# uzunyx-shortcuts

Atajos globales de Uzunyx. `uzunyx-shortcuts-setup` los **suma** a los
que ya tiene el usuario (no quita ninguno salvo Super+Escape del Monitor del
sistema):

| Atajo | Acción | Componente / acción de kglobalaccel |
|---|---|---|
| Alt+W / Alt+S | Subir / bajar volumen | `kmix` `increase_volume` / `decrease_volume` |
| Alt+→ / Alt+← | Subir / bajar el brillo de la pantalla (desde 0.8.0; dejan de ser adelante/atrás en Firefox y Dolphin, decidido por el usuario) | `org_kde_powerdevil` `Increase Screen Brightness` / `Decrease Screen Brightness` |
| Alt+2 | Maximizar | `kwin` `Window Maximize` |
| Alt+1 / Alt+3 | Mosaico izquierda / derecha | `kwin` `Window Quick Tile Left` / `Right` |
| Alt+Escape | Cerrar ventana | `kwin` `Window Close` |
| Alt+A / Alt+D | Escritorio de la izquierda / derecha | `kwin` `Switch One Desktop to the Left` / `Right` |
| Alt+X | Reproducir / pausar | `mediacontrol` `playpausemedia` |
| Alt+Z / Alt+C | Pista anterior / siguiente | `mediacontrol` `previousmedia` / `nextmedia` |
| Ctrl+Shift+S | Captura de una región rectangular | `org.kde.spectacle.desktop` `RectangularRegionScreenShot` |
| Super+W/A/S/D | Pasar el foco a la ventana de arriba / izquierda / abajo / derecha | `kwin` `Switch Window Up` / `Left` / `Down` / `Right` |
| Super+Tab | Vista general (en vez de Super+W) | `kwin` `Overview` |
| Super+Q | Mostrar escritorio (en vez de Super+D) | `kwin` `Show Desktop` |
| Super+Escape | Bloquear la pantalla | `ksmserver` `Lock Session` (se quita de `org.kde.plasma-systemmonitor.desktop` `_launch`) |

## Botones del ratón

Atrás baja el volumen y adelante lo sube, en todos los ratones que tengan esos
botones (p. ej. Logitech M575). Dejan de ir atrás y adelante en Firefox y Dolphin.
Usa la reasignación de botones de KWin: `[ButtonRebinds][Mouse]` en el `kcminputrc`
del usuario, con `ExtraButton1=Key,Volume Down` y `ExtraButton2=Key,Volume Up`. Se
escribe una vez por versión, por usuario y no en `/etc/xdg`, porque ese archivo es de
`uzunyx-lockkeys`; un botón que el usuario ya reasignó no se toca. Se aplica en vivo.

## Cómo se aplican

- Por D-Bus a kglobalaccel (`shortcutKeys` / `setForeignShortcutKeys`, con
  `busctl`), como la configuración del sistema; kglobalaccel los guarda en
  `~/.config/kglobalshortcutsrc`. En Wayland kglobalaccel vive dentro de
  KWin, así que editar ese archivo en plena sesión no sirve.
- Las teclas van como códigos de Qt (`Qt::Key` | modificadores): p. ej.
  Alt = 0x08000000, Meta = 0x10000000, Escape = 0x01000000.
- Primero las quitas y después las sumas, para poder pasar Super+Escape del
  Monitor del sistema al bloqueo.
- Autoarranque (fase 2) una vez por versión de la lista (`VERSION` en el
  script; marca en `~/.config/uzunyx/shortcuts-version`): si el usuario
  cambia o quita un atajo después, no se le vuelve a poner. Si algún
  componente todavía no está (p. ej. `kmix` lo registra plasmashell),
  reintenta un rato y si no, en el siguiente inicio de sesión.
  `uzunyx-shortcuts-setup --force` los vuelve a aplicar.

## Conflictos a tener en cuenta

Un atajo global le gana al de la aplicación: Alt+1/2/3 ya no cambian de
pestaña en Firefox o Konsole, Ctrl+Shift+S ya no es «Guardar como» (Kate,
LibreOffice…) y Alt+W/S/X/Z/C/A/D dejan de abrir menús por su letra subrayada.

Alt+D también le gana a «ir a la barra de direcciones» de Firefox (queda Ctrl+L).

Super+Escape es el único atajo para bloquear: Super+L queda libre.

Super+Q deja de gestionar actividades y Super+Tab de recorrer ventanas (Alt+Tab sigue). Los atajos del mosaico y Alt+E/Q son de `uzunyx-tiling`; aquí se les asegura la tecla, quitándosela a Spectacle (Super+R, Super+Shift+S) y a Dolphin (Super+E): KWin no le da a un script una tecla que ya tiene otra acción.
