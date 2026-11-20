# uzunyx-maxgesture

Plugin de KWin en C++ (`uzunyxmaxgesture`, activo por defecto): el botón de
maximizar de cualquier ventana también pone pantalla completa.

| Gesto en el botón maximizar | Resultado |
|---|---|
| Clic | Maximiza / restaura, como siempre |
| Shift + clic | Pantalla completa |
| Mantener apretado 450 ms sin mover el puntero | Pantalla completa, sin esperar a soltar |

Las apps que dibujan su propia barra (GTK, libadwaita, Electron, Firefox) no
admiten un cuarto botón, pero su botón de maximizar solo le *pide* a KWin que
maximice; la decoración de KWin hace lo mismo. El plugin es un filtro de
entrada (`InputEventFilter`): anota el último clic izquierdo (Shift, cuánto se
mantuvo, si se arrastró) y, cuando una ventana cambia de maximizado justo
después (hasta 300 ms tras soltar), deshace el maximizado y la pone en
pantalla completa.

Mantener apretado actúa sin soltar: en la zona de los botones (la barra de la
decoración de KWin, o los 56 px de arriba de una ventana que dibuja su barra,
a menos de 160 px de un extremo), a los 450 ms sin moverse el plugin le
suelta el botón a la app (`PointerInputRedirection::processButton` y
`processFrame`: sin el *frame*, GTK guarda el soltado y no hace nada). Si era
maximizar, la app lo pide en ese momento y la ventana pasa a pantalla
completa con el botón todavía apretado; el soltado de verdad, después, se
descarta. Si no era maximizar, el clic termina ahí: para arrastrar la ventana
desde esa zona hay que volver a hacer clic (decidido por el usuario el
2026-11-19: volver a apretar en el mismo lugar podía leerse como doble clic,
que en la barra maximiza). Fuera de la zona, mantener apretado sigue contando
al soltar. Con `macfullscreen` de `uzunyx-deco` (0.14.1 o posterior)
la ventana se va a un escritorio propio.

Solo cuenta un cambio de maximizado que llega enseguida de un clic: los
atajos de teclado (Meta+RePág…) y las apps que se maximizan solas no se
tocan. Arrastrar una ventana al borde superior también maximiza al soltar,
por eso un clic largo con más de 8 px de movimiento no cuenta. Super + clic
no sirve: KWin lo usa para mover ventanas y la app nunca lo recibe.

Comprobado en un KWin anidado (2026-11-19) con clics y Shift simulados con
`org_kde_kwin_fake_input` (`KWIN_WAYLAND_NO_PERMISSION_CHECKS=1`), en el botón
de verdad de una barra GTK 4 (`HeaderBar`) y en el de la decoración uzunyx
(kwrite): clic → maximizada y otra vez → restaurada; Shift + clic →
pantalla completa; 750 ms apretado → pantalla completa *antes* de soltar, en
un escritorio `⛶`; apretar el centro de la barra 700 ms y arrastrar → la
ventana se mueve; apretar la zona de botones fuera de un botón y arrastrar →
no se mueve (lo esperado).

La 0.1.0 (mantener apretado contaba al soltar) y la 0.2.0 las comprobó el usuario en su
sesión el mismo día.

## Versión de KWin

Como `uzunyx-altguard`: se compila contra el KWin instalado (`kwin-dev`),
solo carga en esa versión exacta y el paquete depende de ella. Recompilar y
publicar tras cada actualización de KWin. Necesita
`kwin-dev cmake extra-cmake-modules libdrm-dev pkgconf`.

KWin carga sus plugins al iniciar la sesión: tras instalar, cerrar sesión, o
cargarlo en caliente con
`qdbus6 org.kde.KWin /Plugins org.kde.KWin.Plugins.LoadPlugin uzunyxmaxgesture`.
