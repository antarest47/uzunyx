# uzunyx-welcome

Ventana de bienvenida (Python + GTK3): elegir Akane o Sora, el teclado, los atajos
principales, qué hacen los buscadores y el centro de control. También en el menú, «Bienvenida a
Uzunyx».

Sale sola solo en el primer inicio de sesión de un usuario nuevo. La marca es
`/etc/skel/.config/uzunyx/welcome-pending`: solo la reciben los usuarios creados
después de instalar el paquete, así que a los que ya existen no les aparece. En la
sesión en vivo (`boot=live`) no sale; se borra al abrirse, aunque no se termine.

Los atajos salen de `/usr/bin/uzunyx-keys`, con las teclas reales. Elegir una edición
cambia el escritorio al momento con `uzunyx-edition set`; «Siguiente» cambia además la
pantalla de inicio de sesión y la de arranque (`--sddm --plymouth`), con «Aplicando…»
mientras tanto. Eso pide contraseña, salvo que ya estén en esa edición. Si se cancela
o el usuario no tiene permiso, lo avisa y deja seguir.

Solo en el primer inicio, elegir una edición cambia también la imagen del usuario (`~/.face` y `SetIconFile` de AccountsService con esa copia, sin contraseña). Abierta después desde el menú no la toca.

La bienvenida de KDE no sale: `/etc/xdg/plasma-welcomerc` trae `LastSeenVersion=99.0.0` (`plasma-desktop` depende de `plasma-welcome`, y `autoload=false` en `kded6rc` no apaga su módulo).

`art/` son copias reducidas de `icons/Dúo de Catgirls Kawaii Magenta y Cian.png` y de
`uzunyx-plymouth/art/`.

«Tu teclado» (desde 0.4.0, maqueta aprobada por el usuario el 2026-11-08): con o sin
teclado numérico, dibujados con cairo, y la píldora que va a quedar en el panel. Elegir
cambia al momento la opción «Bloq Mayús y Bloq Num / Solo Bloq Mayús» de los widgets
del panel que la tienen (`org.uzunyx.controlcenter`, `org.uzunyx.lockkeys`), por el
script de escritorio de Plasma (`writeConfig` y `reloadConfig`: la píldora cambia en
vivo), y `NumLock` en el `kcminputrc` del usuario (0 o 2), por si no hay widget. Viene
marcada la opción que ya tiene el widget.

`uzunyx-welcome --page N` abre esa página (0–4), para probar. Si cambia el centro de
control, rehacer `control-center.png`.
