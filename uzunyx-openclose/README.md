# uzunyx-openclose

Efecto de KWin en C++ (`uzunyxopenclose`, activo por defecto) que anima
abrir y cerrar ventanas: **emergen** (suben 16 px, crecen de 97 % a 100 % y
aparecen, 240 ms, `OutCubic`) y al cerrarse **se hunden** (lo inverso,
200 ms, `InCubic`). Elegido por el usuario el 2026-10-29 entre los mockups
(«Emerger»).

- **Ventana encima mientras anima** (`effects->setElevatedWindow`): al
  cerrar, KWin activa y sube otra ventana, y con Escala la animación de
  cierre quedaba tapada (la ventana parecía desaparecer de golpe; lo mismo
  pasaba al minimizar con la lámpara).
- **Reemplaza la animación de maximizar** en las apps que se abren
  maximizadas (Gwenview, Claude): justo después de aparecer, el efecto
  Maximize de KWin las agranda desde el centro. Este efecto va después en
  la cadena (posición 70, Maximize es 60) y fija la escala y la traslación
  (no las multiplica) mientras anima.
- **Convive con Escala**: reclama la apertura y el cierre
  (`WindowAddedGrabRole` / `WindowClosedGrabRole`) y Escala cancela la suya
  sola; si otro efecto reclama la ventana después (Genie Anywhere con
  Tsunyx), le deja la animación. Elige las mismas ventanas que Escala.
  En Configuración del sistema → Efectos aparece en la categoría exclusiva
  de abrir y cerrar.
- La ventana cerrada se retiene con `refWindow()`/`unrefWindow()` a mano,
  no con `EffectWindowDeletedRef`: al cerrar KWin destruye las ventanas
  aunque estén animando, y soltar esa referencia desde `windowDeleted` las
  liberaba dos veces (KWin se caía al cerrar sesión).

Diagnóstico: `[Effect-uzunyxopenclose] Debug=true` en `kwinrc` escribe en
el journal de la sesión qué decide con cada ventana.

## Historia

0.1.x probó que las ventanas salieran del botón de su app en el panel
(`iconGeometry`) y emergieran si no tenía. El gestor de tareas informa el
botón de una ventana nueva entre 45 y más de 210 ms después de que aparece,
y al cerrar ya lo quitó; hacía falta esperar, leer las apps ancladas y
recordar el último botón. Se descartó por simple (0.2.0).

## Compilar e instalar

Como `uzunyx-outline`: compilado contra el KWin instalado y fijado a esa
versión (**recompilar tras cada actualización de KWin**). Necesita
`kwin-dev cmake extra-cmake-modules libdrm-dev pkgconf`.

    make deb
    sudo apt install ./build/uzunyx-openclose_<versión>_amd64.deb

Tras reinstalar el `.so` hay que cerrar sesión (KWin sigue usando la
biblioteca vieja).
