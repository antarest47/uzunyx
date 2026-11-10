# uzunyx-plasmatheme

Tema de escritorio de Plasma `uzunyx`: Breeze, con los indicadores del
gestor de tareas al estilo Unity / dash de GNOME.

- Un punto blanco bajo el icono de cada aplicación abierta, con o sin foco
  (más tenue si está minimizada, naranja si pide atención), en lugar de la
  línea en el borde del panel. Igual de blanco que la píldora de los grupos,
  que no puede cambiar con el foco.
- Tarea activa (desde 0.7.0): fondo redondeado con el color de resaltado
  del esquema al 50 % (carmesí con Uzunyx Akane, cian con Uzunyx Sora; 60 %
  con el ratón encima) y un borde de 1 px del mismo color que el del panel (color del texto al
  25 %), un anillo relleno y no un trazo. Sigue al esquema
  activo (clase `ColorScheme-Highlight`), sin un tema por edición.
- Fondo redondeado gris al pasar el ratón por las demás; el punto se
  mantiene en hover.
- Aplicaciones con varias ventanas agrupadas: el punto se estira en una
  píldora redondeada, en lugar del «+» de Breeze. No indica cuántas ventanas
  hay: el indicador de grupo (`group-expander-<borde>`, que
  `GroupExpanderOverlay.qml` dibuja centrado sobre el marco) es una imagen
  fija, opaca para que el punto de debajo no se note.
- Fondo de escritorio por defecto: `UzunyxAkane` (`plasmarc`, paquete
  `uzunyx-wallpapers`).
- Panel con borde: una línea de 1 px con el color del texto al 25 % (blanco
  con Breeze Oscuro) en el borde exterior del fondo del panel, siguiendo las
  esquinas redondeadas, como el contorno de las ventanas (decoración
  uzunyx y `uzunyx-outline`). En las cuatro variantes del fondo del
  panel (`widgets/`, `solid/`, `translucent/`, `opaque/`), que el panel
  elige según su opacidad: con el panel opaco y composición se usa
  `solid/`; `opaque/` es para cuando no hay composición.
- Solo trae `tasks.svgz`, los `panel-background.svgz` y `plasmarc`; todo lo
  demás lo hereda de Breeze (`default`) y del esquema de colores.

## Cómo está hecho

`gen-tasks-svg.py` parte del `tasks.svg` de Breeze (conserva la barra de
progreso, las flechas de grupo y las pistas de márgenes del icono) y sustituye
los marcos de estado por un único elemento `<estado>-center` de 53×46, el
tamaño de un botón del gestor de tareas solo iconos en un panel de 46 px, para
que el punto no se deforme. En paneles de otra altura el punto se estira un
poco. El gestor de tareas busca primero `<estado>-hover` al pasar el ratón
(`taskPrefixHovered` en `TaskTools.js`), por eso hay elementos combinados.

`gen-panel-svg.py` parte de cada `panel-background.svg` de Breeze y añade a
las ocho piezas del marco una banda rellena de 1 px (un cuarto de anillo en
las esquinas). Tiene que quedar dentro de cada pieza: Plasma mide la pieza
por su caja, y un trazo que sobresale (los extremos de una línea) estira la
esquina y deja costuras. La variante `opaque/` ya tiene esa línea, en el
color de marco: se recolorea.

Los `.svgz` están en el repositorio; para regenerarlos:

    make svg

## Instalar

    make deb
    sudo apt install ./build/uzunyx-plasmatheme_0.5.0_all.deb

El tema global `uzunyx` (paquete `uzunyx-lookandfeel`) lo usa.

Desde 0.8.0, `dialogs/background.svgz` (y sus variantes) lleva el mismo borde que el panel. Es lo que usan las notificaciones: su ventana está compilada en Plasma, así que no se puede cambiar solo para ellas, y el borde alcanza a las demás ventanas emergentes que usen ese fondo.
