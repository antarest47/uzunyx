# uzunyx-lnf

Temas globales de Plasma (look-and-feel) de Uzunyx, en dos ediciones
oscuras con la misma estética:

| | Uzunyx Akane | Uzunyx Sora |
|---|---|---|
| Id | `org.uzunyx.desktop` (por defecto; el id es anterior a las ediciones) | `org.uzunyx.sora` |
| Esquema de color (`uzunyx-colors`) | `UzunyxAkane` | `UzunyxSora` |
| Fondo (`uzunyx-wallpapers`) | `UzunyxAkane` (`wallpaper-uzunyx-akane-lll.jpeg`) | `UzunyxSora` (`wallpaper-uzunyx-sora-lll.jpeg`) |
| Logo del lanzador | `uzunyx-akane` (`../icons/uzunyx-icon-akane.png`) | `uzunyx-sora` (`../icons/uzunyx-icon-sora.png`) |

`package/` es la edición Akane; el `Makefile` instala Sora a partir de ella
cambiando el id, el nombre, la descripción, `ColorScheme`, `Image` y el
icono del lanzador (lista `EDITIONS`). Lo demás (decoración, botones,
iconos, tema de escritorio, disposición) es igual en las dos. Los logos se
instalan como iconos de aplicación en `hicolor` (`gen-logos.py`, de 16 a
512 px). El logo solo llega al panel con la disposición del tema (usuario
nuevo o «Usar la disposición del escritorio del tema»); al cambiar de
edición sin ella, el botón conserva su icono.

- `package/contents/defaults`: copia de los valores de Breeze Oscuro con el
  esquema de color de la edición, la decoración `uzunyx` y el tema de escritorio `uzunyx` (paquete
  `uzunyx-plasmatheme`: indicadores del gestor de tareas estilo Unity) y
  el tema de iconos `uzunyx` (paquete `uzunyx-buttons`): los iconos Kora
  (paquete `kora-icon-theme`, receta en `../kora-icons`) más los botones de
  ventana de colores que usan Firefox y Electron. Aquí irá el resto del
  esquema.
- `package/contents/layouts/org.kde.plasma.desktop-layout.js`: panel inferior
  flotante, centrado y ajustado al contenido, con Tsunyx Launcher (paquete
  `tsunyx-launcher`) como menú, o Kickoff si no está instalado, seguido del
  cuadro de búsqueda Tsunyx Search (mismo paquete), el gestor de tareas (al
  hacer clic en un grupo de ventanas muestra sus miniaturas:
  `groupedTaskVisualization=1`), el indicador de Bloq Mayús / Bloq Num
  (`org.uzunyx.lockkeys`, paquete `uzunyx-lockkeys`, si está instalado)
  antes de la bandeja, y reloj en 24
  horas con fecha corta personalizada (`ddd, d 'de' MMM`). Al final, un botón
  «Salir…» (`lock_logout`) que abre la pantalla de apagar/reiniciar/cerrar
  sesión. En el escritorio, los iconos van en columnas desde arriba a la
  derecha, como en macOS (`arrangement=1`, `alignment=1` en `[General]`;
  desde 0.29.0). Se usa en el
  primer inicio de sesión de un usuario nuevo, o al aplicar el tema marcando
  «Usar la disposición del escritorio del tema» (eso reemplaza los paneles).
- `uzunyx-lookandfeel-env.sh` → `/etc/xdg/plasma-workspace/env/`: Plasma
  solo reescribe `~/.config/kdedefaults` cuando cambia el *nombre* del tema
  global, así que una actualización de este paquete no llegaría a los
  usuarios que ya lo usan. `startplasma` ejecuta este script antes de aplicar
  el tema; si la versión instalada cambió desde la última vista
  (`~/.config/uzunyx/lookandfeel-version`), borra
  `~/.config/kdedefaults/package` (si es una de las dos ediciones) y Plasma
  vuelve a escribir los valores.
- `dolphin/dolphinui.rc` → `/usr/share/kxmlgui5/dolphin/`: la barra de
  herramientas de Dolphin 26.08 con el botón «Arriba» tras «Adelante».
  KXmlGui elige el archivo de mayor `version` y, si empatan, el primero (los
  del disco antes que el compilado en Dolphin): con la misma versión (49)
  gana este; cuando Dolphin suba la suya vuelve la de Dolphin (sin el botón,
  pero sin romper nada) y hay que actualizar la copia. Las personalizaciones
  del usuario (`~/.local/share/kxmlgui5/dolphin/`) siguen mandando.
- Las vistas previas son las de Breeze Oscuro, provisionales.

## Pantalla de inicio (KSplash)

Desde 0.19.0 cada edición trae su pantalla de inicio (`contents/splash/`,
`[ksplashrc] Theme=<id>` en `defaults`): la misma imagen que la pantalla de
arranque de `uzunyx-plymouth`, para que arranque, inicio de sesión y
escritorio se vean como una sola secuencia. Fondo `#111318`, icono de la
edición y debajo el nombre con un brillo que lo recorre (franja blanca
inclinada enmascarada con el alfa del logo, `MultiEffect` de
`QtQuick.Effects`, paquete `qml6-module-qtquick-effects`) y destellos del
acento en sus estrellas. `Splash.qml` es común; `gen-splash.py` genera
`icon.png`, `logo.png` (de `../icons` y `../uzunyx-plymouth/art`) y
`glint.png` (con el código de `uzunyx-plymouth/gen-theme.py`) para cada
edición. El PNG del nombre tiene motas casi transparentes alrededor: la
máscara las ignora (`maskThresholdMin` 0,4), si no el brillo asomaba fuera
del nombre. Probar sin instalar:

    make deb
    XDG_DATA_DIRS=$PWD/build/root/usr/share:$XDG_DATA_DIRS ksplashqml --test --window org.uzunyx.sora

## Instalar

    make deb
    sudo apt install ./build/uzunyx-lookandfeel_0.15.1_all.deb

Instala `/usr/share/plasma/look-and-feel/org.uzunyx.desktop` y lo deja como
tema global por defecto en `/etc/xdg/kdeglobals` (`[KDE] LookAndFeelPackage`),
que tiene prioridad sobre el de Debian (`desktop-base`, `org.debian.desktop`).

- Usuarios nuevos: lo reciben en su primer inicio de sesión (`startplasma`
  escribe sus valores en `~/.config/kdedefaults`).
- Usuarios que ya eligieron un tema global lo conservan. Para cambiar:
  Preferencias del sistema → Colores y temas → Tema global, o

      plasma-apply-lookandfeel -a org.uzunyx.desktop

## Por qué un tema global

La decoración que KWin usa sale de `~/.config/kdedefaults/kwinrc`, que
`startplasma` reescribe en cada inicio de sesión desde el tema global activo y
que tiene prioridad sobre `/etc/xdg`. Por eso la decoración por defecto solo se
puede fijar a través del tema global.

El panel flotante sigue flotando aunque una ventana lo toque (desde 0.27.12).
Plasma solo lo hace con los paneles que no son siempre visibles: el paquete desvía
`/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml` y
`postinst` lo rehace con `sed` desde la copia de Plasma (`Panel.qml.distrib`),
también por disparador cuando Plasma la actualiza. Si la línea cambia en un Plasma
nuevo, queda el panel de Plasma tal cual.

Desde 0.29.1, ese `Panel.qml` lleva además `UzunyxPanelWatch.qml` (se instala al
lado): en Wayland, a veces la ventana del panel se queda con el tamaño viejo después
de que Plasma pidió otro (hueco vacío al final del panel, visto al cerrarse una
tarea) y Plasma no lo vuelve a pedir. Cada 2 s compara la ventana con la geometría
que Plasma quiere (`panel.geometryByDistance(0)`) y, si no coinciden dos veces
seguidas, mueve el largo un píxel y lo devuelve, que lo vuelve a pedir. Deja una
línea `uzunyx: panel window is …` en el registro de `plasmashell`.
