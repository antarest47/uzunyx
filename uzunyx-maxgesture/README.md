# uzunyx-maxgesture

Plugin de KWin en C++ (`uzunyxmaxgesture`, activo por defecto): el botón de
maximizar de cualquier ventana también pone pantalla completa.

| Gesto en el botón maximizar | Resultado |
|---|---|
| Clic | Maximiza / restaura, como siempre |
| Shift + clic | Pantalla completa |
| Mantener apretado ≥ 450 ms, sin arrastrar | Pantalla completa |

Las apps que dibujan su propia barra (GTK, libadwaita, Electron, Firefox) no
admiten un cuarto botón, pero su botón de maximizar solo le *pide* a KWin que
maximice; la decoración de KWin hace lo mismo. El plugin es un espía de
entrada (`InputEventSpy`): anota el último clic izquierdo (Shift, cuánto se
mantuvo, si se arrastró) y, cuando una ventana cambia de maximizado justo
después (hasta 300 ms tras soltar), deshace el maximizado y la pone en
pantalla completa. Con `macfullscreen` de `uzunyx-deco` (0.14.1 o posterior)
la ventana se va a un escritorio propio.

Solo cuenta un cambio de maximizado que llega enseguida de un clic: los
atajos de teclado (Meta+RePág…) y las apps que se maximizan solas no se
tocan. Arrastrar una ventana al borde superior también maximiza al soltar,
por eso un clic largo con más de 8 px de movimiento no cuenta. Super + clic
no sirve: KWin lo usa para mover ventanas y la app nunca lo recibe.

Comprobado en un KWin anidado (2026-11-19) con una ventana GTK 4 cuyo botón
pide maximizar, y clics y Shift simulados con `org_kde_kwin_fake_input`
(`KWIN_WAYLAND_NO_PERMISSION_CHECKS=1`): clic → maximizada; Shift + clic y
700 ms apretado → pantalla completa en un escritorio `⛶`; 700 ms arrastrando
40 px → maximizada. Comprobado también por el usuario en su sesión el mismo día.

## Versión de KWin

Como `uzunyx-altguard`: se compila contra el KWin instalado (`kwin-dev`),
solo carga en esa versión exacta y el paquete depende de ella. Recompilar y
publicar tras cada actualización de KWin. Necesita
`kwin-dev cmake extra-cmake-modules libdrm-dev pkgconf`.

KWin carga sus plugins al iniciar la sesión: tras instalar, cerrar sesión, o
cargarlo en caliente con
`qdbus6 org.kde.KWin /Plugins org.kde.KWin.Plugins.LoadPlugin uzunyxmaxgesture`.
