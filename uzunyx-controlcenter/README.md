# uzunyx-controlcenter

Centro de control al estilo de GNOME (`org.uzunyx.controlcenter`, solo QML): una
píldora en el panel con red, volumen y batería abre las barras de volumen y brillo,
los interruptores de wifi, Bluetooth, enfoque, mosaico, no molestar y luz nocturna,
el reproductor y el pie con batería, ajustes, bloquear y salir. Arriba de todo, los
temporizadores de `uzunyx-timer` en marcha, uno por píldora ancha en el acento (como la
del reloj en el panel), con lo que falta y un botón para cancelarlos (0.9.0).

Red por cable (0.9.6, pedido por el usuario el 2026-11-08): las interfaces salen de
`nmcli device`. La píldora muestra una sola: wifi si está conectada, si no el cable si lo
está. En el centro, el interruptor de wifi solo si hay wifi, y el de «Cable» si hay
cable conectado o si no hay wifi (abre la configuración de red).

Usa módulos de Plasma (algunos privados). Luz
nocturna sin configurar abre su módulo. Wifi y Bluetooth tienen una flecha que abre la lista de
redes y dispositivos, y la barra de volumen otra con la salida y la entrada de
sonido. Trae también las apps en segundo plano (clic abre, clic derecho muestra su menú), el
portapapeles, con imágenes, y los dispositivos extraíbles, con `uzunyx-controlcenter-helper`.

La bandeja de Plasma sigue corriendo pero no se ve en el panel; «Más» abre sus widgets
restantes dentro del centro de control.
