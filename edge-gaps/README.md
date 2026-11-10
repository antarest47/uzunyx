# edge-gaps

Márgenes invisibles entre las ventanas maximizadas y los bordes de pantalla en
Plasma (Wayland, probado en Plasma 6.7.4). Usa superficies layer-shell de 1 px
que no reciben clics, así que el panel flotante de Plasma sigue flotando con
ventanas maximizadas.

## Instalar

Debian / derivados:

    make deb
    sudo apt install ./build/edge-gaps_0.1.0_all.deb

Otras distros (necesita python3-gi, python3-gi-cairo, GTK 3 y la typelib de
gtk-layer-shell):

    sudo make install

Arranca solo en sesiones de Plasma (`/etc/xdg/autostart/edge-gaps.desktop`).

## Configurar

Valores del sistema en `/etc/xdg/edge-gapsrc`, por usuario en
`~/.config/edge-gapsrc`:

    kwriteconfig6 --file edge-gapsrc --group General --key Gap 12
    kwriteconfig6 --file edge-gapsrc --group General --key BottomGap 20

- `Enabled` (true): `false` no reserva ningún margen (modo enfoque).
- `Gap` (8): margen arriba, izquierda y derecha.
- `BottomGap` (17): espacio reservado sobre el panel inferior. Con panel
  flotante debe ser ≥ 17; el hueco visible queda en `BottomGap - 8`.

Los cambios se aplican al reiniciar edge-gaps (o la sesión), o al momento
con su acción `reload` por D-Bus (es una `Gtk.Application`; `gapplication`
no sirve porque busca un `.desktop` con el id de la app):

    busctl --user call org.uzunyx.EdgeGaps /org/uzunyx/EdgeGaps \
        org.gtk.Actions Activate 'sava{sv}' reload 0 0

## uzunyx-mode

`uzunyx-mode [normal|focus|toggle|status]` alterna el diseño de Uzunyx:

- **normal:** márgenes de edge-gaps y panel inferior siempre visible.
- **focus (enfoque):** sin márgenes (`Enabled=false` en el `edge-gapsrc` del
  usuario) y el panel inferior esquiva las ventanas (`hiding=dodgewindows`,
  por el script de Plasma): se oculta cuando una ventana lo tapa.

Imprime el modo resultante. Lo usa el botón junto al buscador de Tsunyx
Launcher (≥ 1.6). El modo se conserva al reiniciar la sesión: edge-gaps lee
`Enabled` al arrancar y Plasma guarda la visibilidad del panel. Las
ventanas maximizadas mantienen las esquinas redondeadas en los dos modos;
`softmaximize` (uzunyx-deco ≥ 0.7.3) reajusta las que maximiza él cuando
cambia el área.

## Volumen con la rueda

La última fila de píxeles de cada pantalla recibe la rueda del ratón: con el
puntero contra el borde inferior, girarla sube y baja el volumen, con los atajos
de `kmix` (mismo paso e indicador en pantalla). Está en la capa superior porque
la ventana del panel flotante cubre el borde en su ancho. `VolumeEdge=false` la
quita; en modo enfoque (`Enabled=false`) no existe, porque el panel llega al borde.
