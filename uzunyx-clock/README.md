# uzunyx-clock

Reloj para el panel (`org.uzunyx.clock`), solo en QML: la hora en grande, con los
minutos en el acento de la edición (aclarado, porque el acento puro se lee mal en
trazos finos) y los dos puntos que parpadean, y la fecha debajo, sin caja. Siempre
en 24 horas. Opción D de las maquetas, elegida por el usuario el 2026-11-01.

Clic: abre el calendario, `MonthView` de `org.kde.plasma.workspace.calendar`, que
es público (el mismo de Plasma, sin festivos ni eventos: no se le pasa un
`eventPluginsManager`). Menú del panel: ajustar fecha y hora (`kcm_clock`).

La fecha sale de `Qt.locale().toString`: `Qt.formatDate` da inglés. Se le quitan
los puntos de las abreviaturas de Qt («nov.»).

Los temporizadores de `uzunyx-timer` en marcha suman una píldora con el tiempo
que falta del más próximo. Desde 0.3.0 se listan arriba del centro de control
(`uzunyx-controlcenter` ≥ 0.9.0), con un botón para cancelarlos, y no sobre el
calendario; desde 0.3.1 un clic en la píldora abre el centro de control (con
`activated()` del widget, como su atajo global) y en la hora, el calendario.
