# uzunyx-genie (Genie Anywhere)

Efecto de minimizar de KWin 6 (`genieanywhere`, «Lámpara mágica libre»),
basado en la lámpara mágica de KWin, con la forma de la de macOS y con un
destino elegible. Lo escribió Claude web para KWin 6.3; en Uzunyx se portó a
6.7 y se le cambió la forma (2026-10-29).

- **Forma estilo macOS, en dos fases** (`apply()`): primero un **embudo**
  (el primer 40 %): el lado de la ventana que da al panel se estira hasta
  el icono y se angosta a su ancho, con los costados en S (smootherstep), y
  el borde opuesto queda en su lugar; después la ventana **se escurre** por
  el embudo hasta el icono. La de KWin baja cada fila por una sola curva
  cúbica y los costados quedan cóncavos. Funciona hacia los cuatro lados.
- **450 ms** por defecto (KWin trae 250; elegido por el usuario).
- **Encima de todo mientras anima** (`setElevatedWindow`): al minimizar,
  KWin activa otra ventana y la sube, y la animación quedaba tapada (le
  pasa también a la lámpara de KWin).
- **Reemplaza a la lámpara de KWin solo mientras está cargado:** al cargar,
  descarga `magiclamp` y `squash`, que siguen activados en la configuración
  (`/etc/xdg/kwinrc` de `uzunyx-deco`). Si este efecto no carga (por
  ejemplo tras una actualización de KWin, hasta recompilarlo), vuelve la
  lámpara de siempre en vez de quedar sin animación.
- **Tsunyx en modo lámpara:** la regla de abrir/cerrar
  `Tsunyx Launcher (lamp)` (`org.kde.plasmashell`) viene incluida en el
  código: Tsunyx ≥ 1.8 con «Abrir y cerrar: lámpara mágica» sale del botón
  del panel y vuelve a él.
  Desde 0.1.1, una ventana con regla de abrir/cerrar puede decir dónde está
  su lámpara: un título que termina en `x,y` (un punto en coordenadas de
  la ventana) es el destino, antes que cualquier otro. Tsunyx ≥ 1.8.1 pone
  ahí el centro de su botón (`Tsunyx Launcher (lamp) 652,1172`): KWin no ve
  dentro del panel, y así la lámpara sale del botón aunque Tsunyx se abra
  con Super.

## Uso

| Atajo | Qué hace |
|---|---|
| `Super+Ctrl+L` | Elegir destino para la **app activa**: aparece una mira, hacés clic en el ítem del panel. `Esc` cancela. |
| `Super+Ctrl+Shift+L` | Elegir el **destino global** (para todas las ventanas sin regla propia). |
| `Super+Ctrl+Alt+L` | Quitar el destino de la app activa. |
| *(sin atajo)* | Quitar el destino global, y animar o no la apertura y el cierre de la ventana activa. Asignables en Atajos → KWin. |

Orden de prioridad del destino:

1. Regla de la app (por clase de ventana, p. ej. `org.kde.dolphin`)
2. Destino global
3. Icono en el gestor de tareas (lo mismo que hace la lámpara de KWin)
4. Cursor del ratón, si no hay nada de lo anterior

Si el clic cae sobre un panel, el destino se ajusta para quedar dentro del
panel y la dirección de la animación se deduce del panel, incluso en otro
monitor u oculto. Si cae fuera, la ventana va hacia el lado donde está el
punto.

### Menús y ventanas que se abren y cierran

Además de minimizar, puede animar la **apertura y el cierre** de las ventanas
que se le indiquen (por título o parte del título, y clase): al abrir salen
de la lámpara y al cerrar vuelven a entrar, desde donde estaba el cursor al
abrirse o desde el destino elegido con `Super+Ctrl+L`. Reclama la apertura y
el cierre, así que Escala, Desvanecer y `uzunyx-openclose` se apartan.

```bash
kwriteconfig6 --file kwinrc --group Effect-genieanywhere --group OpenClose \
    --key "Título" org.kde.plasmashell
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect genieanywhere
```

## Configuración en `~/.config/kwinrc`

```ini
[Effect-genieanywhere]
AnimationDuration=450          ; ms (0 = 450 por defecto)
TargetSize=32                  ; tamaño en px del área destino
DefaultOverridesTaskbar=true   ; false = el destino global solo si la ventana no tiene icono en la barra
DefaultTarget=1840,1050,32,32  ; x,y,ancho,alto (lo escribe el atajo)

[Effect-genieanywhere][Targets]
org.kde.dolphin=1500,1050,32,32
```

Después de editar a mano:
`qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect genieanywhere`.

Las coordenadas son absolutas: si se mueve el panel o cambia la resolución,
hay que volver a elegir los destinos.

## Compilar e instalar

Como `uzunyx-outline`: compilado contra el KWin instalado y fijado a esa
versión (**recompilar e instalar tras cada actualización de KWin**). Necesita
`kwin-dev cmake extra-cmake-modules libdrm-dev pkgconf libkf6globalaccel-dev
libkf6windowsystem-dev`.

    make deb
    sudo apt install ./build/uzunyx-genie_<versión>_amd64.deb

Tras instalar o reinstalar hay que cerrar sesión. El paquete reemplaza al de
prueba `kwin-effect-genieanywhere`.

Licencia: GPL-2.0-or-later (deriva del código de Magic Lamp de KWin).
