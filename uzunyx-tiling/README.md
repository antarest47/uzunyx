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

## Gestos

El script `uzunyxgestures` (QML, desde 0.8.0) suma dos gestos de tres dedos en el touchpad a los de KWin:

- Hacia arriba abre el lanzador del panel (Tsunyx), como Super, y hacia abajo lo cierra (0.8.1). Se sabe si está abierto por su ventana, que solo existe mientras lo está.
- Hacia la izquierda, en el último escritorio, hace lo de Alt+D: crea otro y va a él. En los demás escritorios cambia KWin, como siempre (los dedos llevan el escritorio: a la izquierda va al siguiente).

Los dos llaman a atajos globales por kglobalaccel (`activate application launcher` de plasmashell y `UzunyxDesktopNext`).

## Con el ratón

Redimensionar una ventana del mosaico mueve las divisiones que toca, y sus vecinas la siguen en vivo. Desde 0.9.0, cada división tiene una franja invisible de 6 px (la separación y 2 px a cada lado) con el cursor ↔ o ↕: se arrastra y la división sigue al puntero. KWin no da bordes a las ventanas sin decoración, así que las franjas son superficies layer-shell de `uzunyx-tiling-handles` (Python, arranca por activación de D-Bus); el script le manda dónde van (`callDBus`) y se enteran del arrastre por dos atajos sin teclas (`UzunyxTilingDragStart`/`End`). Donde algo tapa la división (una ventana flotante, un menú, Tsunyx) no hay franja. También sirve Super + botón derecho cerca del borde; las apps que dibujan su marco (Firefox, Electron) también se pueden tomar de él. Super+Shift+Z vuelve a los tamaños por defecto del escritorio y la pantalla de la ventana activa. Los tamaños son por escritorio y pantalla; al cambiar la cantidad de ventanas o el modo solo se conserva el del lugar principal, y no se guardan al cerrar sesión.

Una ventana nueva queda invisible hasta tener el tamaño de su lugar (500 ms como máximo), para que no se vea el salto.

## Animación

Desde 0.9.0, con el mosaico encendido, el efecto `uzunyxtilemotion` (JS) anima los cambios de lugar: la ventana se desliza y cambia de tamaño desde el lugar anterior (220 ms; el contenido se estira, como en Estirar de KWin al maximizar). Una ventana nueva espera 180 ms a que las demás le hagan lugar y aparece creciendo, como en Hyprland. El script carga el efecto al encender el mosaico y lo descarga al apagarlo, y también mientras se arrastra una división. Deja quietas las ventanas que se mueven con el ratón, las que se maximizan o pasan a pantalla completa y las recién abiertas.
