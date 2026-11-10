# uzunyx-lockkeys

Widget de Plasma `org.uzunyx.lockkeys` («Teclas de bloqueo»): una alarma para
los teclados que ya no traen luces de Bloq Mayús y Bloq Num. Una píldora en
el panel con dos mitades, «A» para Bloq Mayús y «1» para Bloq Num (con «solo
Bloq Mayús», una píldora chica con la «A»), con el estilo de los botones de
ventana (`uzunyx-buttons`): núcleo negro brillante, aro, destello y reflejo.

- **Posición normal** (Bloq Mayús apagado, Bloq Num encendido): tranquila, en
  el color de acento de la edición (`Kirigami.Theme.focusColor`, carmesí en
  Akane y cian en Sora; cambia sola con el esquema de color).
- **Posición que conviene notar:** esa mitad se llena de rojo intenso y late,
  con un halo que sale de la píldora (0,9 s por ciclo). Elegido por el
  usuario el 2026-10-31: tiene que romper los ojos, casi molestar.

Las imágenes se dibujan en `main.qml` como SVG (`data:`) para poder usar el
color del esquema. Hasta 0.3.0 usaba las de `../icons/lock`, verde y rojo.
El halo son trazos anchos y translúcidos, sin filtros, como en los botones.

El estado sale del mismo módulo que usa el indicador de Plasma
(`org.kde.plasma.private.keyboardindicator`, `KeyState`, paquete
`qml6-module-org-kde-plasma-workspace`).

## Opción: Bloq Mayús y Bloq Num / solo Bloq Mayús

En la configuración del widget (clic derecho → Configurar):

- **Bloq Mayús y Bloq Num** (por defecto): muestra los dos y Bloq Num se
  activa al iniciar sesión.
- **Solo Bloq Mayús**: para teclados sin bloque numérico; Bloq Num se deja
  como está al iniciar sesión.

No hay forma fiable de saber si el teclado tiene bloque numérico (el teclado
interno anuncia todas las teclas numéricas lo tenga o no, y hay notebooks con
y sin él), por eso es una opción.

Cómo se aplica: KWin lee `[Keyboard] NumLock` de `kcminputrc` al iniciar la
sesión (0 activar, 1 desactivar, 2 no tocar; `src/xkb.cpp`). El paquete pone
`NumLock=0` en `/etc/xdg/kcminputrc` (valor por defecto del sistema). Al
cambiar la opción, el widget escribe el valor del usuario con `kwriteconfig6`
(0 o 2). Hace efecto en el siguiente inicio de sesión.

El widget guarda en su configuración (`appliedNumLock`) el último valor que
aplicó: cargar la configuración también dispara `showNumLockChanged`, y sin
eso escribiría `kcminputrc` en cada inicio y taparía lo que el usuario elija
después en Configuración del sistema. La primera vez solo anota la opción.

## Instalar

    make deb
    sudo apt install ./build/uzunyx-lockkeys_0.2.0_all.deb

El tema global (`uzunyx-lookandfeel`) lo pone antes de la bandeja del
sistema si está instalado. Traducción al español en `po/es.po`.
