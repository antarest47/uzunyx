# uzunyx-timer

Temporizadores del escritorio: el comando que usan los buscadores de Tsunyx
para iniciarlos y `uzunyx-clock` para mostrarlos.

    uzunyx-timer start 5m té
    uzunyx-timer list
    uzunyx-timer cancel <id>

Cada uno es un temporizador transitorio de systemd del usuario (`systemd-run`):
no hay ningún proceso esperando, y termina con la sesión, igual que la lista en
`$XDG_RUNTIME_DIR/uzunyx-timer/timers.json`. Al terminar deja una notificación
fija (urgencia crítica, también en «No molestar») y suena `alarm-clock-elapsed`.

`uzunyx-timer wait` espera un cambio en la lista y la imprime; el reloj y el
centro de control lo relanzan al terminar, así no sondea. Sale solo a los 30 s, por si plasmashell ya
no está.
