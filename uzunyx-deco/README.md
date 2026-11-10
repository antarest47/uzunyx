# uzunyx-deco

Decoración de ventanas QML para KWin (motor Aurorae, Plasma 6.7) que mantiene
las esquinas redondeadas (8 px, como el panel) también en ventanas
**maximizadas de verdad**: el área de la aplicación es un rectángulo dentro de
un borde de 4 px y las esquinas se redondean en la propia decoración.

Ventanas normales con sombra (dibujada en el `padding`, que Aurorae convierte
en sombra nativa de KWin); las maximizadas no tienen sombra.

Botones de minimizar, maximizar/restaurar y cerrar: bola negra, blanca
en minimizar y maximizar y roja en cerrar (estados normal, encima, presionado e inactiva). Son los SVG de
`../uzunyx-buttons/svg` (`make svg` allí), que también usa el paquete
`uzunyx-buttons` para GTK, Firefox y Electron. Maximizar y restaurar se ven
iguales. Los demás botones (mantener encima, ayuda…) usan iconos simbólicos
del tema de iconos.

Requiere `kwin-style-aurorae`, `qml6-module-org-kde-kirigami` y Qt ≥ 6.9
(`RectangularShadow`, en `qml6-module-qtquick-effects`).

## Instalar

Debian / derivados:

    make deb
    sudo apt install ./build/uzunyx-deco_0.5.0_all.deb

Otras distros:

    sudo make install

Se instala en `/usr/share/kwin/decorations/uzunyx`. Para usarla:

- Instalar `uzunyx-lookandfeel` (en `../uzunyx-lnf`), cuyo tema global la
  usa y queda como tema por defecto del sistema.
- O elegirla a mano en Preferencias del sistema → Colores y temas →
  Decoraciones de ventanas.

No sirve ponerla en `/etc/xdg/kwinrc`: en Plasma, `startplasma` escribe los
valores del tema global en `~/.config/kdedefaults`, que tiene prioridad sobre
`/etc/xdg`. Ese archivo sí sirve para lo que el tema global no fija: desde la
0.5.0 trae `[Plugins]` con la animación de minimizar «lámpara mágica»
(`magiclamp`) en lugar de `squash`, y desde la 0.7.2 su duración en 300 ms
como en macOS (`[Effect-magiclamp] AnimationDuration`; KWin usa 250 ms por
defecto, y se multiplica por la velocidad global de animaciones).

## Maximizado suave (script de KWin)

Las aplicaciones que dibujan su propio marco (Firefox, Electron como Claude
Desktop, libadwaita…) no usan esta decoración y dibujan esquinas rectas al
maximizar. El paquete incluye el script de KWin `softmaximize`, activo por
defecto, que solo actúa sobre esas ventanas: al maximizarlas las deja como
ventana normal que ocupa el área de maximizado, así la aplicación sigue
dibujando su marco redondeado. Volver a maximizar restaura el tamaño anterior,
y también arrastrarla: como una maximizada de verdad, recupera su tamaño
alrededor del cursor (KWin guarda el punto de agarre como proporción del
tamaño). Redimensionarla a mano la deja como ventana normal de ese tamaño.

- Su botón de maximizar sigue mostrando «maximizar» (lo dibuja la aplicación).
- Una ventana tapada aplica el cambio cuando vuelve a dibujarse.
- Las ventanas con esta decoración no se tocan: se maximizan de verdad.
- Si cambia el área de maximizado (paneles, márgenes de edge-gaps,
  `uzunyx-mode`), las ventanas suavemente maximizadas se reajustan: KWin no
  avisa de ese cambio a los scripts, así que se comprueba cada segundo.
- Arreglo aparte: si una ventana con esta decoración aparece ya maximizada,
  el script le recrea la decoración una vez (`noBorder` sí y no). Aurorae a
  veces no llega a pintar la decoración creada en ese momento (barra de
  título y bordes transparentes); le pasaba a Configuración del sistema al
  reabrirse maximizada.

Desactivarlo para un usuario:

    kwriteconfig6 --file kwinrc --group Plugins --key softmaximizeEnabled false
    qdbus6 org.kde.KWin /KWin reconfigure

## Desarrollo

Para probar cambios sin instalar el paquete:

    cp -r package ~/.local/share/kwin/decorations/uzunyx

KWin guarda el QML en caché: tras cambiar los archivos, cambia a Breeze y
vuelve para recargarlo.

## Script `panelconfigretry`

«Mostrar configuración del panel», desde los menús de Plasma, empieza justo al
cerrarse el menú: el foco vuelve a la ventana de arriba y la configuración, que
se oculta al perder el foco, se abre y se cierra en un milisegundo, y deja el
panel ensanchado. El script detecta esa ventana de vida corta y pide la
configuración otra vez 300 ms después, con `evaluateScript`. Activo por defecto;
para desactivarlo:

    kwriteconfig6 --file kwinrc --group Plugins --key panelconfigretryEnabled false

## Script `macfullscreen`

Pantalla completa como en macOS: con `Super+F` o la opción del menú de la
ventana, esta pasa a pantalla completa en un escritorio virtual nuevo y la vista
se desliza hasta él. Al repetirlo, salir de pantalla completa o cerrar la ventana,
vuelve a sus escritorios, se borra el creado y se regresa al de antes. Al arrancar
borra los escritorios vacíos que hayan quedado (empiezan por `⛶`). Con el puntero
contra el borde inferior, la ventana baja de capa (`keepBelow`) y se ve el panel,
hasta que el puntero se aleja.
