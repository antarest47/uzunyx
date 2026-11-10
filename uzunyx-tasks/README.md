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
