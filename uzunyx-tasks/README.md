# uzunyx-tasks

Gestor de tareas para el panel (`org.uzunyx.tasks`), solo en QML, sobre el
módulo público `org.kde.taskmanager`. No hay que compilarlo: el gestor de Plasma
lleva su QML dentro del plugin y su módulo privado no se puede importar aparte.

- Fondo de vidrio con el color de la edición (`Kirigami.Theme.focusColor`) solo
  en la ventana en foco; gris neutro en las demás, más oscuro si están
  minimizadas, como los botones de ventana; sin fondo en las ancladas.
- Un punto por ventana, hasta tres.
- Clic: activa o minimiza; en un grupo, muestra las miniaturas. Botón central
  o Ctrl+clic: ventana nueva. Botón derecho: menú. Arrastrar: reordena.
  En «Más», «Pantalla completa» es la de macOS, en un escritorio propio (el script
  `macfullscreen` de `uzunyx-deco`, por su atajo, con la ventana activada), y no
  está «Recoger» (desde 0.4.7, elegido por el usuario).
- Publica la geometría de cada botón para las animaciones de minimizar.

Las apps ancladas usan la clave `launchers`, con el mismo formato que el gestor
de Plasma.

Los textos usan las traducciones del gestor de Plasma (`plasma-desktop-data`,
más de 80 idiomas): por eso son los mismos, con su contexto, en `i18ndc`.

Las acciones de cada app y los archivos recientes del menú salen del módulo de
los lanzadores (`org.kde.plasma.private.kicker`, como en Tsunyx), y los lugares
de Dolphin, de su `ComputerModel`.

Opciones: las del gestor de Plasma que tienen sentido con solo iconos. Falta:
la opción de usar varias filas solo cuando falta espacio (hay un máximo fijo).

Audio con `org.kde.plasma.private.volume` (si falta `plasma-pa`, sin audio),
controles con `org.kde.plasma.private.mpris`. Insignias y progreso: las apps
mandan la señal `com.canonical.Unity.LauncherEntry` cada una desde su remitente y
QML solo escucha uno fijo, así que `uzunyx-task-badges` (Python, autoarranque) la
repite desde `org.uzunyx.TaskBadges` y además registra `com.canonical.Unity`.

`make deb` genera el paquete.

Con las miniaturas de una app abiertas, otro icono solo las reemplaza si el puntero se
queda 300 ms sobre él (desde 0.4.8, pedido por el usuario el 2026-11-15): en diagonal
hacia las miniaturas se suele cruzar otro icono, y antes se cerraban. Mientras tanto ese
botón tiene el tooltip apagado (`holdOff`), porque el de Plasma pasa enseguida al icono
nuevo y no tiene demora configurable por botón; `previewOwner` en `main.qml` dice de
quién son las miniaturas abiertas.
Desde 0.4.9 las miniaturas no se rearman si las ventanas no cambiaron: al volver del
cuadro al icono, Plasma vuelve a mostrar el mismo tooltip, y las miniaturas nuevas
mostraban un instante el icono de la app hasta que llegaba la imagen en vivo.
