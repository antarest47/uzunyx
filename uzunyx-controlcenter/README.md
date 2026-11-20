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

**Dispositivos** (0.10.0, maqueta aprobada por el usuario el 2026-11-20): lo que hacía la
ventana de dispositivos de Plasma, dentro del centro. Cada partición con sistema de archivos
de un disco extraíble es una fila: montado (en el acento, con lo libre) se abre o se expulsa;
sin montar lleva «Montar»; cifrado (LUKS o BitLocker) y bloqueado lleva «Desbloquear».
Clic derecho: abrir, montar o desbloquear, desmontar (y bloquear, si está cifrado) y
expulsar; arriba, «Expulsar todo». La contraseña la pide el diálogo de KDE (el de kded,
`soliduiserver`, que usan Dolphin y Plasma): el ayudante le pasa su objeto de D-Bus,
responde a su `Introspect` y recibe `passphraseReply` sin interfaz (vacío al cancelar), y
desbloquea con `Encrypted.Unlock` de UDisks; la contraseña no pasa nunca por una línea de
órdenes. Al conectar un dispositivo el centro se abre solo en esta página, sobre su
píldora: el ayudante espera las señales de UDisks (`usb-wait`, sin sondear) y la ventana
emergente de Plasma, que con la bandeja oculta salía a la izquierda del panel, queda
apagada (`popupOnNewDevice=false` en el widget de dispositivos de la bandeja, puesto por el
centro de control).

**Notificaciones** (0.10.0, misma maqueta): las copias y descargas en marcha van arriba de
todo, como los temporizadores, con su progreso, pausa y cancelar (`Notifications` de
`org.kde.notificationmanager`, solo trabajos; `suspendJob`, `resumeJob`, `killJob`), y la
píldora muestra un anillo en el acento con el progreso mientras haya alguna: una
notificación de copia minimizada ya no se pierde. Debajo, la fila «Notificaciones» con la
cantidad, la última y «Borrar todo», que cierra todas (las del historial y las que están en
pantalla) menos los trabajos en marcha; su página lista el historial, con la acción de cada
una al hacer clic y una cruz para cerrarla. El modelo solo tiene datos dentro de
plasmashell (el servidor de notificaciones es el widget de la bandeja): con
`plasmawindowed` sale vacío. Comprobado en un Plasma anidado, con un trabajo falso por
`org.kde.JobViewServerV2` y dispositivos falsos; comprobado por el usuario en su sesión el mismo día con USB reales.

El wifi de la píldora sigue la señal con los niveles de Kora; encendido sin conectar se ve
gris, y conectado sin internet lleva una exclamación amarilla. En la lista de redes, clic
en la conectada la desconecta y clic derecho en una guardada permite olvidarla (borra la
conexión y la contraseña).

El ancho se puede cambiar arrastrando el borde, y Plasma guarda el tamaño (`popupWidth` en el
appletsrc). La 0.9.8 lo fijó y la 0.9.9 lo volvió a dejar libre: mejor personalizable
(decidido por el usuario el 2026-11-16).
