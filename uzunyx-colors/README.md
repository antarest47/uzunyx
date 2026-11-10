# uzunyx-colors

Esquemas de color de KDE de Uzunyx, solo oscuros, en dos ediciones con la
misma estética:

- **Uzunyx Akane** (`UzunyxAkane`): carmesí, a juego con el logo.
- **Uzunyx Sora** (`UzunyxSora`): cian.

Los dos comparten los neutros gris azulados (fondo `#111318`, superficie
`#20232B`, bordes `#343944`, texto `#F2F2F7`) y solo cambian los acentos. La
paleta de partida salió de ChatGPT. Los acentos de Akane están girados 9°
hacia el carmesí del logo (`#F00050`), conservando saturación y brillo:
Magenta `#E62983` → `#E62967`, Frambuesa `#A51E62` → `#A51E4E`, etc.

| Papel | Akane | Sora | Dónde |
|---|---|---|---|
| Acento | `#E62967` | `#16CDE0` | foco, `DecorationFocus` |
| Vivo | `#FF5C90` | `#32E6F2` | hover, enlaces, texto activo |
| Claro | `#FFB5CC` | `#A3F5F5` | enlaces visitados, texto inactivo sobre selección |
| Seleccionado | `#A51E4E` | `#078FA8` | fondo de la selección |
| Suave | `#651A3B` | `#14536D` | fondos alternos (selección, botones) |
| Carbón | `#29171D` | `#12212B` | grupo complementario (bloqueo, OSD) |

Las zonas de contenido (`View`) son un poco más oscuras que la ventana
(`#0D0E12`), como en Breeze. Los colores de estado (positivo, neutro y
negativo) son los de Breeze Oscuro. Las apps GTK los reciben a través de
kde-gtk-config, y la decoración uzunyx y el tema de escritorio los toman
del esquema.

## Generar e instalar

`gen-colors.py` tiene las paletas y escribe `color-schemes/*.colors`
(`make colors`). Los `.colors` generados están en el repositorio.

    make deb
    sudo apt install ./build/uzunyx-colors_0.1.0_all.deb
    plasma-apply-colorscheme UzunyxAkane   # o UzunyxSora
