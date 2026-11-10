# uzunyx-pager

Paginador de escritorios para el panel (`org.uzunyx.pager`), solo en QML: una
píldora de vidrio con un punto por escritorio y el actual, más largo, con el color
de la edición. Con un solo escritorio se oculta, salvo al editar el panel.

Clic: va a ese escritorio. Rueda: los recorre. Pasar el ratón: miniatura del
escritorio con sus ventanas en vivo, armada con un `TasksModel` filtrado por
escritorio. Menú del panel: añadir, quitar y configurar, con las traducciones del
paginador de Plasma.

`VirtualDesktopInfo` no cambia de escritorio: se usa D-Bus de KWin (`setCurrentDesktop`
en `/KWin`, `createDesktop` y `removeDesktop` en `/VirtualDesktopManager`).
