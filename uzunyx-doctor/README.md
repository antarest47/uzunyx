# uzunyx-doctor

Actualiza el sistema y comprueba que Uzunyx siga funcionando. Se abre desde el
menú («Uzunyx Doctor») o con `uzunyx-doctor`, y solo pregunta cuando hace falta.

1. Revisa cómo está todo.
2. Consulta las actualizaciones y simula cuáles haría.
3. Hace una copia con Timeshift, si está configurado.
4. Actualiza. Si cambia KWin, quita `uzunyx-outline`, `uzunyx-openclose` y
   `uzunyx-genie`, actualiza y los recompila contra el KWin nuevo.
5. Si cambió el escritorio, compila todos los paquetes y pide cerrar sesión. Al
   volver a entrar se abre solo y termina con unas preguntas rápidas.

Se detiene sin actualizar si la simulación quiere eliminar un paquete propio o
del escritorio, y pregunta por cualquier otro paquete a eliminar. Si algo falla,
dice qué archivo pasarle a Claude (`~/.local/state/uzunyx-doctor/informe-*.txt`).
Si pasan 30 días sin usarlo, avisa al iniciar sesión.

Otros modos: `--check` solo comprueba (sin contraseña ni cambios) y `--build`
además compila todos los paquetes. El código se busca en `~/claude/waifbian` y
`~/claude/tsunyx-launcher` (`UZUNYX_SOURCE`, `TSUNYX_SOURCE`); sin él, no puede
recompilar los efectos ni compilar los paquetes.

`make test` prueba sus decisiones con salidas de apt inventadas, sin tocar nada.
