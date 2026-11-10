# uzunyx-terminal

zsh con Oh My Zsh y zsh-autocomplete (commits fijados, MIT; `make fetch`),
resaltado de Debian y Starship con un tema estilo Powerline en los colores de
Akane y Sora (`make starship`). El prompt elige el tema leyendo el tema global
en `kdeglobals`, así que cambia con `uzunyx-edition`, también en pestañas abiertas.

Konsole abre zsh desde los perfiles de `uzunyx-colors`, con `ZDOTDIR` en
`/usr/share/uzunyx-terminal/zsh`. No cambia el shell de inicio de sesión ni
crea configuración en el home (solo historial, caché y lo que crea Atuin). `~/.zshrc` y
`~/.config/starship.toml` mandan si existen.

El prompt empieza con una medialuna (desde 0.7.0). Hack, la fuente de Konsole, trae
los triángulos de Powerline pero no las medialunas, que salían más chicas de otra fuente
de respaldo. `gen-powerline-font.py` (con `python3-fonttools`, al armar el paquete) hace
«Uzunyx Powerline», con solo `\ue0b4` y `\ue0b6` dibujadas con las medidas de Hack, de
punta a punta de la celda y un poco metidas en la siguiente para que no quede una línea;
`60-uzunyx-powerline.conf` la pone en fontconfig justo después de Hack.

Un comando que llega en `UZUNYX_TERMINAL_RUN` (Tsunyx ≥ 1.13.2 lo usa) se escribe en el
primer prompt y se ejecuta, como si se hubiera tecleado: quedan a la vista el prompt y el
comando, y entra en el historial.

«Abrir en la terminal» (desde 0.6.0): en el menú del clic derecho de una carpeta, en
Dolphin y en el escritorio, y en el fondo de una carpeta de Dolphin (menú de servicio
`uzunyx-open-terminal.desktop`). Abre Konsole en esa carpeta, con zsh. El fondo del
escritorio no lleva menús de servicio ni «Abrir con»: desde 0.6.1 tiene «Abrir terminal»
de Plasma (acción `_open_terminal` del menú `org.kde.contextmenu`, apagada por defecto;
abre en la carpeta personal). Plasma lee su archivo de widgets sin `/etc/xdg`, así que
la enciende `/etc/xdg/plasma-workspace/env/uzunyx-terminal.sh`, una vez por usuario y
antes de que arranque plasmashell (marca `~/.config/uzunyx/desktop-terminal-set`).

Fastfetch: en zsh dentro de Konsole muestra el PNG de la edición (modo `kitty`,
con ImageMagick; `sixel` deja fondo negro y `kitty-direct` no funciona en
Konsole). En otros casos, `/etc/xdg/fastfetch/config.jsonc` con el logo ASCII
(`make logo`), el
nombre y las etiquetas en verde ANSI, el acento en los esquemas de Konsole.
`/etc/os-release` sigue siendo de Debian porque `GRUB_DISTRIBUTOR` sale de su
`NAME` y decide la carpeta EFI; otros programas siguen viendo Debian.

Ctrl+R y la flecha arriba abren Atuin, con la lista de comandos recientes; se
filtra escribiendo, Enter ejecuta y Tab deja el comando para editarlo. Solo
sincroniza si se inicia sesión en una cuenta.
