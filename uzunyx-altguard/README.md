# uzunyx-altguard

Plugin de KWin en C++ (`uzunyxaltguard`, activo por defecto) para que las
apps no abran su menú después de un atajo con Alt.

Firefox, las apps Electron, LibreOffice y otras abren su menú cuando Alt se
aprieta y se suelta sin otra tecla en el medio. Con un atajo global (Alt+W,
Alt+1…) o al mover una ventana con Alt y el ratón, KWin se queda con la otra
tecla o el clic, así que la app solo ve Alt y abre el menú. Alt+Tab no lo
sufre porque el selector le quita el foco a la ventana.

El plugin es un filtro de entrada de KWin, antes de los atajos globales:
anota si mientras Alt estaba apretado se tocó otra tecla, un botón del ratón
o la rueda, y si fue así le manda a la ventana con foco (solo a ella, por el
`SeatInterface`, sin pasar por los atajos) F24 apretada y suelta justo antes
de que suelte Alt, como la «menu mask key» de AutoHotkey en Windows. F24 no
la usa casi ninguna app. Alt solo y Alt+letra dentro de las apps (Alt+A,
«Archivo») siguen igual. `UZUNYX_ALTGUARD_KEY` en el entorno de KWin cambia
la tecla (código evdev), para pruebas.

Comprobado en un KWin anidado con Firefox ESR, con teclas simuladas por el
protocolo `org_kde_kwin_fake_input` (`KWIN_WAYLAND_NO_PERMISSION_CHECKS=1`):
sin el plugin Alt+W (con un atajo de maximizar) abre la barra de menú; con
él, no. Alt solo la sigue abriendo y Alt+A abre «Archivo». Comprobado también por el usuario en su sesión, con Firefox y Claude Desktop (2026-11-08).

## Versión de KWin

Como `uzunyx-outline`: se compila contra el KWin instalado (`kwin-dev`), solo
carga en esa versión exacta y el paquete depende de ella. Recompilar e
publicar tras cada actualización de KWin. Necesita
`kwin-dev cmake extra-cmake-modules libdrm-dev pkgconf`.

KWin carga sus plugins al iniciar la sesión: tras instalar, cerrar sesión.
También se puede cargar en caliente con
`qdbus6 org.kde.KWin /Plugins org.kde.KWin.Plugins.LoadPlugin uzunyxaltguard`.
