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
- Con `uzunyx-maxgesture` (Shift + clic o mantener apretado maximizar), la
  pantalla completa llega después de que el script ya ajustó la ventana al
  área: en Wayland las dos cosas son pedidos que la app responde, y KWin la
  devolvería ocupando el área al salir. Si la pantalla completa llega hasta
  1 s después de un maximizado suave, al salir de ella la ventana recupera
  el tamaño de antes (0.15.4; KWin 6.6 ignora el tamaño que se le da a una
  ventana en pantalla completa, así que se le da al salir). Comprobado en
  la VM con Ubuntu 26.04 y una ventana GTK3 con barra propia.
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

Desde 0.15.10, en una pantalla que no es la principal es pantalla completa común,
sin escritorio propio: los escritorios solo están en la principal (`uzunyxdesktops`
de `uzunyx-tiling` ≥ 0.10.0, y `PerOutputVirtualDesktops=false` en `/etc/xdg/kwinrc`,
que hasta 0.15.9 era `true`).

## Vista de ventanas `uzunyxwindowview`

Desde 0.16.0 (variante B de las maquetas, elegida por el usuario el 2026-11-20), en lugar
de la Vista general de KWin, que queda apagada (`overviewEnabled=false` en
`/etc/xdg/kwinrc`): Super+Tab o cuatro dedos hacia arriba (abajo la cierran) muestran
todas las ventanas del escritorio actual en miniatura y en vivo, en una cuadrícula sobre el
fondo difuminado, con un buscador arriba y el panel a la vista. Script QML
(`declarativescript`; la carpeta se llama como su Id, si no KWin no la encuentra), sin C++.

- Abre y cierra como el Alt+Tab: el primer cuadro es una copia del escritorio, cada ventana
  donde está, y de ahí vuela a su lugar en la cuadrícula mientras el fondo se difumina
  (`KWin.DesktopBackground` + `MultiEffect`). Las minimizadas aparecen en la cuadrícula,
  más tenues.
- La cuadrícula prueba cada cantidad de columnas y se queda con la que deja las ventanas más
  grandes (nunca más que su tamaño real); filas centradas, en orden de lectura de su lugar
  real, para que se muevan poco.
- Elegir: clic, o Enter sobre la seleccionada (aro en el acento; al empezar, la activa; Tab
  y las flechas la cambian, el puntero también). La elegida pasa al frente y crece hasta su
  lugar. Esc, un clic en el fondo o en el panel vuelven sin cambiar nada. La bola de cerrar
  aparece al pasar el ratón.
- El buscador filtra por título y por app en todas las pantallas; está en la pantalla
  desde la que se abrió.
- Una ventana por pantalla: los escritorios solo están en la principal, así que cada una
  muestra las suyas.
- Las ventanas propias de la vista (título `Uzunyx window view`) se dejan fuera, y los
  demás scripts de Uzunyx (`softmaximize`, `macfullscreen`, el mosaico y los escritorios de
  `uzunyx-tiling` ≥ 0.10.1) y `uzunyx-outline` ≥ 0.4.3 las ignoran por ese título.

Desde 0.16.1 (visto por el usuario el 2026-11-20 con la 0.16.0: no se podía escribir, el
panel era una copia inerte y al cerrar una ventana desde la vista parpadeaba a su tamaño):

- **El panel es el real y funciona.** Las ventanas de un script van siempre en la capa más
  alta de KWin (encima del panel), lleven o no `BypassWindowManagerHint`, así que la vista
  le deja un hueco: la ventana del panel menos los 8 px de su margen flotante, en píxeles
  enteros (el panel puede quedar en medio píxel y dejaba una línea). La vista es una ventana
  hasta el borde de arriba del panel y piezas a sus lados y debajo, cada una con el fondo
  de toda la pantalla difuminado y recortado, así que no se nota la unión. Si se activa otra
  ventana (una tarea del panel, Tsunyx), la vista se va y la deja así.
- **El teclado.** KWin no le da nunca el foco a las ventanas de un script (ni con
  `activeWindow`, ni con `requestActivate`, ni como diálogo), y tampoco a una superficie
  layer-shell que lo pide en exclusiva (probado en un KWin anidado). Lo recibe
  `uzunyx-windowview-keys` (`/usr/libexec`, Python + GTK3, activado por D-Bus,
  `org.uzunyx.WindowViewKeys`: `Start`, `Stop`, `Poll`): una ventana común de 1 px, sin
  bordes, que el script deja transparente debajo de la vista y hace activa; guarda lo que se
  escribe con un `IMContextSimple` (acentos con tecla muerta) y el script lo lee cada 40 ms.
  Enter, Esc, Tab y las flechas llegan como eventos. Se va sola tras diez minutos sin uso.
  Comprobado en un Plasma anidado con un teclado simulado (`org_kde_kwin_fake_input`).
- **Cerrar una ventana desde la vista** la deja transparente antes de cerrarla
  (`uzunyx-openclose` dibuja encima de todo la ventana que se cierra); si sigue ahí 1,5 s
  después (pregunta si guardar), vuelve a verse.
- La ventana elegida se activa al terminar la animación (activarla antes la subía encima
  de la vista); con Esc vuelve a estar activa la que lo estaba al abrir.

Desde 0.16.2 (pedido por el usuario el 2026-11-20): Esc con algo escrito solo lo borra (lo
hace el ayudante del teclado); con el buscador vacío cierra la vista. Y una ventana que se
cierra con la vista abierta (desde ella o por su cuenta) no rehace la cuadrícula de golpe: se
queda en la lista marcada como cerrada (`removed`, o `leaving` mientras se la cierra desde la
vista), su miniatura se desvanece y se achica, y las demás se mueven y cambian de tamaño hasta
su lugar en la cuadrícula nueva. Cerrando desde la vista, la ventana real se cierra después
de esa animación. Comprobado en un Plasma anidado.

Desde 0.16.3: el ayudante del teclado arranca de cero en cada apertura (activación de
D-Bus con `Start`) y termina al cerrarse la vista (`Stop`). Un ayudante iniciado con la
sesión y reutilizado tenía el foco de KWin pero nunca recibía teclas (visto por el usuario
el 2026-11-20 tras volver a iniciar sesión, con la 0.16.2); uno recién iniciado siempre
funcionó. Si la vista se vuelve a abrir antes de 100 ms, el mismo sigue.

Comprobado en un Plasma anidado (también con dos pantallas, con el filtro y eligiendo una
ventana por temporizadores de prueba, porque ahí no se puede teclear).

Desde 0.17.0 (variante C de las maquetas, elegida por el usuario el 2026-11-21): **los
escritorios dentro de la vista.**

- **Tira de escritorios** debajo del buscador, solo en la pantalla principal: cada escritorio
  con su fondo y sus ventanas en pequeño (`KWin.DesktopBackground` y `WindowThumbnail`
  escalados), el número debajo (los `⛶` de `macfullscreen`, con su nombre y más tenues) y
  un «+» al final. El que está a la vista lleva el aro del acento.
- **Una página por escritorio.** Clic en la tira, la rueda sobre ella, Ctrl+← → o Re Pág /
  Av Pág (el ayudante manda `desktop-left` / `desktop-right`) deslizan las páginas sin
  cerrar la vista. El escritorio de KWin no cambia mientras tanto: al cerrar, KWin pasa al
  escritorio a la vista (Esc o clic en el fondo) o al de la ventana elegida, mientras la vista
  todavía tapa todo, y la vista espera 540 ms en vez de 340 para que no se vea el
  deslizamiento de KWin (500 ms). La que estaba activa al abrir solo vuelve a estarlo si está
  en ese escritorio. Si KWin cambia de escritorio con la vista abierta (tres dedos, Alt+A/D),
  la vista lo sigue; para eso sus ventanas, y la del ayudante del teclado, están en todos los
  escritorios, y la del ayudante sigue activa.
- **El buscador busca en todos los escritorios.** Cada página tiene todas las ventanas de su
  pantalla: primero las de su escritorio, después las demás por escritorio; sin texto solo
  se ven las suyas. Al buscar, cada resultado lleva el número de su escritorio (gris en el
  actual, en el acento en los otros) y la tira cuenta los encontrados en cada uno. Elegir
  uno de otro escritorio va a ese escritorio; al cerrar, las de otros escritorios se
  desvanecen en vez de volar (no tienen lugar en pantalla).
- **Arrastrar una miniatura a la tira** la lleva a ese escritorio (`desktops = [d]`); sobre
  «+», a uno nuevo, al que va la vista. Mientras se arrastra, una copia con borde claro sigue
  al puntero, más chica sobre la tira, y el destino se marca en blanco.
- «+» crea un escritorio al final, `Escritorio N`, como Alt+D (`uzunyxdesktops`), salvo
  que el último ya esté vacío; un escritorio vacío que no está en pantalla lo sigue borrando
  `uzunyxdesktops`, y la vista vuelve entonces al actual.
- La lista de páginas se rehace si cambian los escritorios; las entradas de cada página se
  toman una vez, así que mover una ventana de escritorio solo la anima fuera de su página.

Comprobado en un Plasma anidado con tres escritorios, ratón y teclado simulados
(`org_kde_kwin_fake_input`): tira, clic, rueda, Ctrl+→, búsqueda con resultados de otros
escritorios y elegir uno, arrastrar a otro escritorio y a «+», Esc tras cambiar de página,
seguir un cambio de escritorio de KWin, y con dos pantallas.

## Selector de Alt+Tab `uzunyx_cover`

Estilo Cover Switch (`kwin/tabbox/uzunyx_cover`, solo QML; `[TabBox] LayoutName` en
`/etc/xdg/kwinrc`): vistas en vivo, la elegida de frente y las demás giradas a los
lados. Desde 0.15.5 (maqueta aprobada por el usuario el 2026-11-20), al abrirlo cada
ventana que está en pantalla sale desde su lugar real y vuela a su sitio en la fila, así
que la actual se achica hasta el centro, mientras el fondo de pantalla se difumina como
en la Vista general (`KWin.DesktopBackground` con `MultiEffect`; el panel queda
debajo). Las que no están en pantalla (minimizadas, de otro escritorio) aparecen con un
fundido. La geometría sale de `KWin.Workspace.stackingOrder` por `internalId`, tomada una
vez al crear cada tapa (como binding hacía un bucle). Al soltar Alt KWin cierra el
selector enseguida, sin animación de vuelta. En 0.15.5 los `Behavior` animaban también el primer cambio (cuando cada tapa recibe su lugar real), así que las ventanas aparecían con un fundido en la fila; desde 0.15.6 están apagados hasta el primer cuadro (`frameSwapped`). Además hace falta `uzunyx-openclose` ≥ 0.2.3, que ya no hace emerger la ventana del selector (ni deja que la anime Escala). Desde 0.15.7 (pedido por el usuario el 2026-11-20): la ventana actual va a la izquierda (un empate en la distancia va a la izquierda, y si KWin todavía no movió la selección se espera hasta 60 ms); al soltar Alt el selector no desaparece: con `automaticallyHide: false` KWin solo avisa (`aboutToHide`), la ventana que quedó activa (`Workspace.activeWindow`, leída con `Qt.callLater`; con Esc es la de antes) crece hasta su lugar, las demás vuelven a los suyos, el difuminado se va, y recién entonces el selector se oculta (`visible = false`; KWin oculta y destruye su ventana cuando lo hace él). El fondo ya no deja un margen sin difuminar: `MultiEffect` con `autoPaddingEnabled` dejaba los bordes transparentes y se veía el escritorio y el panel detrás; sin relleno y con un fondo opaco debajo, el panel queda tapado mientras está abierto. Desde 0.15.8 (pedido por el usuario el 2026-11-20): Alt+Tab rápido sigue cambiando al instante (el selector solo aparece si Alt se mantiene, `DelayTime`); cuando aparece, empieza en la ventana actual (`currentIndex = 0`, que también mueve la selección de KWin), al frente en el centro, y las demás salen por detrás hacia los costados; Tab avanza desde ahí, y soltar Alt sin Tab deja la misma ventana. KWin puede volver a mover la selección un instante después: mientras no empezó la animación, se la devuelve a 0. Desde 0.15.9 (pedido por el usuario el 2026-11-20): todo queda invisible (opacidad 0,001, para que se dibuje) hasta el tercer cuadro, porque las miniaturas en vivo tardan en tener imagen y la ventana actual parpadeaba antes de achicarse; mientras tanto se ve el escritorio real detrás, que es la misma imagen. Y los paneles de esa pantalla (`dock`) no desaparecen de golpe: copias en vivo (`WindowThumbnail`) bajan y se desvanecen al abrir, y vuelven al cerrar. Comprobado en KWin y Plasma anidados, con
`org_kde_kwin_fake_input` sosteniendo Alt (el cliente tiene que seguir conectado: al
cerrarse, KWin suelta sus teclas).
