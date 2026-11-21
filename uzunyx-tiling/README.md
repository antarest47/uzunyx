# uzunyx-tiling

Mosaico automático: apagado por defecto. Un clic en el icono de la bandeja rota
entre apagado, principal y pila (`MonadTall` de Qtile) y espiral (`dwindle` de Hyprland); el clic derecho abre un
menú con esas opciones y los modos normal y enfoque de `uzunyx-mode`. También
`uzunyx-tiling [off|stack|spiral|cycle|status]`.

Usa el área de maximizar: en modo normal, 2 px entre ventanas dentro de los
márgenes; en modo enfoque el área es toda la pantalla y no hay separación.
Las ventanas pierden la decoración, y `uzunyx-outline` ≥ 0.3.0 las redondea.
Las apps que dibujan su propia barra la conservan. Al soltar una ventana sobre
otra se intercambian. Quedan flotando los diálogos, las de tamaño fijo, las de
todos los escritorios y las de pantalla completa.

El mosaico funciona como una sola ventana (desde 0.9.2): al activar una de sus
ventanas (gestor de tareas, Alt+Tab, clic), las demás del mismo escritorio y
pantalla también vienen al frente, debajo de ella, y una ventana flotante que
las tapaba queda detrás de todo el mosaico. Las que flotan con Super+Shift+E
siguen encima (`keepAbove`). Desde 0.9.3 vale también con el mosaico de
Uzunyx apagado, para las zonas del propio KDE (Shift al arrastrar una ventana,
Super+T para editarlas, y el mosaico rápido de Super+flechas o Alt+1/Alt+3):
las ventanas cuyas zonas comparten raíz (una por pantalla y escritorio,
`w.tile` y sus `parent`) vienen juntas. Comprobado en un KWin anidado.

## Atajos

Todos con la mano izquierda:

| Atajo | Con mosaico | Sin mosaico |
|---|---|---|
| Super+Shift+W/A/S | Intercambiar con la ventana vecina | Pegar la ventana a ese borde |
| Super+Shift+E | Flotar la ventana o volverla al mosaico | — |
| Super+R | Al lugar principal; desde ahí, lo toma la siguiente | — |
| Super+Z / Super+X | Achicar / agrandar el lugar principal | — |
| Super+Shift+Z | Volver a los tamaños por defecto | — |
| Super+E | Rotar la ventana por los lugares; al completar la vuelta, todo queda como estaba | — |
| Alt+E | Llevar la ventana al escritorio siguiente y seguirla; si no hay, lo crea | Igual |
| Alt+Q | Llevar la ventana al escritorio anterior y seguirla | Igual |
| Super+C | Cambiar de modo (como un clic en el icono) | Igual |

Super+C es `org.uzunyx.tiling-cycle.desktop`, porque el script no puede guardar el
modo. El tamaño del lugar principal es por escritorio y pantalla, y no se guarda.

## Escritorios dinámicos

El script `uzunyxdesktops`, activo siempre, con o sin mosaico: un escritorio vacío que no está en pantalla se borra, al cambiar de escritorio o al cerrarse o moverse una ventana. Mientras estás en él se queda, aunque cierres su última ventana. Las ventanas minimizadas cuentan como ocupado; las de todos los escritorios y las de Plasma, no. Nunca se borra el último, y nada se borra en los primeros 30 s de la sesión ni mientras haya un escritorio de pantalla completa (`⛶ `), porque esa ventana vuelve al suyo.

Alt+D va al siguiente y, en el último, crea uno si ese tiene ventanas. No hay un escritorio de reserva, como en GNOME.

**Escritorios solo en la pantalla principal** (desde 0.10.0, pedido por el usuario el 2026-11-20), como en GNOME: con varias pantallas, los escritorios son los mismos para todas (`PerOutputVirtualDesktops=false`, en el `kwinrc` de `uzunyx-deco` ≥ 0.15.10), pero solo cambia la principal, porque `uzunyxdesktops` pone en todos los escritorios las ventanas que están en otra pantalla. Al llevar una a la principal vuelve a un solo escritorio, el actual; solo a las que puso el script (una que el usuario fijó en todos, sigue así). La principal es la primera de `workspace.screenOrder` (la de la laptop, salvo que se elija otra como principal). En una pantalla secundaria el mosaico arma una sola disposición (`groupKey` con `all`), Alt+E/Alt+Q no hacen nada y `macfullscreen` hace pantalla completa común. Los diálogos que dependen de otra ventana y las ventanas en pantalla completa se dejan como están. Hasta 0.9.3, con escritorios por pantalla, cada pantalla cambiaba por su lado pero los escritorios se creaban en todas a la vez. Comprobado en un KWin anidado con dos salidas (`--output-count 2`). Si se reinicia la sesión con una ventana en la secundaria, KWin la restaura en todos los escritorios y el script ya no sabe que la puso él: al llevarla a la principal sigue en todos.

## Gestos

El script `uzunyxgestures` (QML, desde 0.8.0) suma dos gestos de tres dedos en el touchpad a los de KWin:

- Hacia arriba abre el lanzador del panel (Tsunyx), como Super, y hacia abajo lo cierra (0.8.1); desde 0.11.0, siguiendo a los dedos (ver abajo).
- Hacia la izquierda, en el último escritorio, hace lo de Alt+D: crea otro y va a él. En los demás escritorios cambia KWin, como siempre (los dedos llevan el escritorio: a la izquierda va al siguiente).

El de la izquierda llama a un atajo global por kglobalaccel (`UzunyxDesktopNext`).

Desde 0.11.0 (pedido por el usuario el 2026-11-21), **Tsunyx sigue a los dedos**: mientras se mueven, los iconos vuelan del botón del panel (o vuelven a él) tanto como avanzó el gesto, y al levantarlos termina hacia el lado que pasó la mitad. El script ya no llama al atajo: manda el avance (`SwipeGestureHandler.progress`), con «move», «done» o «cancel» y el nombre de la pantalla, a `uzunyx-gesture-relay` (`/usr/libexec`, Python, activado por D-Bus, `org.uzunyx.GestureRelay`, método `Send`), que lo repite como la señal `Gesture`: un script de KWin no puede emitir señales y el `SignalWatcher` de QML solo escucha a un remitente fijo. Lo escucha Tsunyx Launcher ≥ 1.14.0 (con uno más viejo los gestos no hacen nada: `Breaks: tsunyx-launcher (<< 1.14.0)`); solo el de la pantalla del puntero. Comprobado en un Plasma anidado mandando `Send` con `qdbus6` (el anidado no hace gestos de touchpad).

## Con el ratón

Redimensionar una ventana del mosaico mueve las divisiones que toca, y sus vecinas la siguen en vivo. Desde 0.9.0, cada división tiene una franja invisible de 6 px (la separación y 2 px a cada lado) con el cursor ↔ o ↕: se arrastra y la división sigue al puntero. KWin no da bordes a las ventanas sin decoración, así que las franjas son superficies layer-shell de `uzunyx-tiling-handles` (Python, arranca por activación de D-Bus); el script le manda dónde van (`callDBus`) y se enteran del arrastre por dos atajos sin teclas (`UzunyxTilingDragStart`/`End`). Donde algo tapa la división (una ventana flotante, un menú, Tsunyx) no hay franja. También sirve Super + botón derecho cerca del borde; las apps que dibujan su marco (Firefox, Electron) también se pueden tomar de él. Super+Shift+Z vuelve a los tamaños por defecto del escritorio y la pantalla de la ventana activa. Los tamaños son por escritorio y pantalla; al cambiar la cantidad de ventanas o el modo solo se conserva el del lugar principal, y no se guardan al cerrar sesión.

Una ventana nueva queda invisible hasta tener el tamaño de su lugar (500 ms como máximo), para que no se vea el salto.

## Animación

Desde 0.9.0, con el mosaico encendido, el efecto `uzunyxtilemotion` (JS) anima los cambios de lugar: la ventana se desliza y cambia de tamaño desde el lugar anterior (220 ms; el contenido se estira, como en Estirar de KWin al maximizar). Una ventana nueva espera 180 ms a que las demás le hagan lugar y aparece creciendo, como en Hyprland. El script carga el efecto al encender el mosaico y lo descarga al apagarlo, y también mientras se arrastra una división. Deja quietas las ventanas que se mueven con el ratón, las que se maximizan o pasan a pantalla completa y las recién abiertas.

Desde 0.11.1: `uzunyxdesktops` borra los escritorios vacíos en cuanto termina su espera de inicio (30 s, para las ventanas que la sesión anterior todavía está abriendo). Antes esperaba al siguiente cambio de escritorio o de ventana, y un escritorio vacío de la sesión anterior quedaba ahí (visto por el usuario el 2026-11-21). Comprobado en un KWin anidado que arrancó con un cuarto escritorio vacío.

Desde 0.11.2 ya no hay espera: los escritorios vacíos de la sesión anterior se borran apenas arranca el script. La espera de 30 s era para las ventanas que la sesión anterior vuelve a abrir, pero en Wayland Plasma las abre todas en el escritorio actual, no en el suyo (lo comprobó el usuario el 2026-11-21 reiniciando con Dolphin, Konsole y Firefox en tres escritorios), así que solo dejaba escritorios vacíos medio minuto. Comprobado en un KWin anidado que arrancó con cuatro escritorios vacíos: a los 4 s quedaba uno. Guardar el escritorio de cada app y devolverla a él al iniciar sesión queda como idea (por app, inexacto con varias ventanas de la misma).
