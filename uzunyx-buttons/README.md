# uzunyx-buttons

Botones de ventana de Uzunyx (desde 0.7.0): los tres son una bola negra
brillante con luna creciente blanca abajo a la izquierda, destello arriba a
la izquierda y brillo arriba a la derecha, y un símbolo con resplandor: barra
(minimizar), anillo (maximizar, también para restaurar: no cambia de forma) y
cruz (cerrar). Minimizar y maximizar son **blancos** (aro y símbolo) y cerrar
**rojo** (aro `#FF5A4E`→`#A3100C`, cruz rojo claro). Son los mismos en las
dos ediciones (Akane y Sora): neutros para ir con cualquier acento.
Historia: hasta 0.5.0, azul, ámbar y rojo; 0.5.1–0.6.0, aro carmesí y
símbolo rosa (0.6.0 tuvo además una versión cian para Sora, con su propio
tema de iconos y decoración; se descartó). Todo en el historial de git.
Al pasar el ratón llevan un aro de 2 px por fuera de la bola, rosa en cerrar
(`#fe919d`) y blanco cálido en los demás (`#c2b6b0`): es el que Electron
(Claude Desktop) dibuja por su cuenta alrededor de sus botones. Electron lo
tiene fijo en su código (`freedesktop_nav_button_provider.cc`, estilo
Breeze: el de cerrar es una constante, los demás salen del color de la barra
de la app), no lo cambia ningún tema; por eso cerrar es rojo, para que ese
rosa combine. No va en el
SVG: lo ponen la decoración (`UzunyxButton.qml`) y el CSS de GTK
(`box-shadow`), así el hover se ve igual en Dolphin, GTK y Claude.

- `gen-buttons.py` → `svg/<botón>-<estado>.svg` (`make svg`; están en el
  repo). Estados: `normal`, `hover`, `active` (presionado), `backdrop`
  (ventana inactiva, en gris). El resplandor son trazos translúcidos, sin
  filtros SVG, para que Qt SVG y librsvg los dibujen igual.
- La decoración `uzunyx-deco` copia estos SVG.

## Qué instala el paquete

| Ruta | Para qué |
|---|---|
| `/usr/share/themes/Breeze-Uzunyx` | Tema GTK 3/4: `@import` de Breeze GTK + CSS de los botones (`gen-gtk-css.py`), con los SVG en `buttons/`. El nombre empieza por «Breeze» a propósito: Electron (p. ej. Claude Desktop) elige el estilo de sus botones de ventana por el nombre del tema GTK; con «Breeze…» los junta como Breeze (círculo de 18 px, 22 px entre centros), con cualquier otro usa el de GNOME (24 px y 37 px entre centros, con un círculo gris detrás). kde-gtk-config solo inyecta sus botones (vacíos con Aurorae QML) si el nombre es exactamente `Breeze`. |
| `/usr/share/icons/uzunyx` | Tema de iconos (`gen-icons.py`): hereda de `kora` y trae `window-{minimize,maximize,restore,close}-symbolic.png` a 16, 24 y 32 px (y @2x), las carpetas (genérica y de la carpeta personal) en `places/scalable` y el icono de Dolphin en `apps/scalable`, con los colores del logo de Akane, con los nombres alternativos que piden las apps (enlaces: `folder-public` para Dolphin/KIO, `folder-downloads`, `folder-desktop`, `folder-home`, `inode-directory`, `system-file-manager`). Sus versiones `-symbolic` (y las de los alias) son enlaces a las de Kora en `places/symbolic` y `apps/symbolic`: al pedir un icono `-symbolic` que no tiene, el buscador prueba primero el nombre sin sufijo **en el mismo tema** antes de pasar a Kora, y saldría la carpeta de color (pasaba con «Mostrar escritorio», `user-desktop-symbolic`). Lo demás sale de Kora (también `folder-open` y las variantes `-open`). |
| `/usr/share/icons/uzunyx-sora` | Las mismas carpetas y el mismo Dolphin con los colores del logo de Sora; hereda de `uzunyx` (botones y lo demás). Lo elige el tema global «Uzunyx Sora». |
| (`gen-folders.py`) | Dibuja las carpetas de cada edición (pestaña de atrás en el acento, frente gris oscuro con brillo arriba, curvas blanca y del acento abajo a la derecha, como los mechones del logo, y borde blanco tenue; colores de los logos de Akane y Sora; modelo del usuario y variante «C» elegida por él, 2026-11-08) y les pone el emblema de cada SVG de `../icons/iconos-carpetas-v2`. El icono de Dolphin no es una carpeta: el delfín blanco sobre una bola brillante oscura con aro del acento, como los botones de ventana (idea «3», elegida por el usuario el 2026-11-08). Se genera al instalar, en `build/folders`. |
| `/usr/bin/uzunyx-gtk-theme-setup` + `/etc/xdg/autostart/` | Al iniciar sesión, una sola vez por usuario, cambia el tema GTK de Breeze (o ninguno) a Breeze-Uzunyx. Marca: `~/.config/uzunyx/gtk-theme-set`. |

## Por qué así

- **Apps GTK3/GTK4 con barra propia:** kde-gtk-config solo inyecta sus
  botones (`window_decorations.css` y `assets/`) si el tema GTK se llama
  `Breeze`, y con una decoración Aurorae QML los genera vacíos (botones
  invisibles). Con un tema propio no los inyecta y vale nuestro CSS. Los
  selectores igualan o superan los de Breeze GTK
  (`window headerbar button.titlebutton.close`, más las variantes de
  Chromium y de ventana maximizada).
- **Firefox:** no usa el CSS de GTK: dibuja
  `-moz-symbolic-icon(window-*-symbolic)` del tema de iconos (y maximizar
  también para restaurar). **Chromium/Electron** (Claude Desktop) también
  los pide al tema de iconos. GTK repinta de un color los `-symbolic.svg`,
  pero los PNG conservan sus colores. Solo se ve el estado normal (cada app
  pone su propio fondo al pasar el ratón). Van en carpetas de tamaño fijo
  porque Chromium dibuja el PNG a su tamaño real.
- **Tema GTK por defecto:** el tema global no puede fijarlo, y el
  `kconf_update` de kde-gtk-config pone Breeze a los usuarios nuevos; por
  eso el script de autoarranque. Cambia el tema por D-Bus
  (`org.kde.GtkConfig.setGtkTheme`), igual que la configuración del sistema.
- **libadwaita** ignora los temas GTK; sus botones usan los iconos
  `window-*-symbolic`, así que deberían salir de colores por el tema de
  iconos (sin probar).
- Otros usos de esos iconos (p. ej. una «x» de cerrar dentro de una app GTK)
  también salen de colores.

Requiere `breeze-gtk-theme` y `kora-icon-theme`. Para construir:
`python3-gi` con GdkPixbuf y librsvg.
