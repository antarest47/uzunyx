# uzunyx-grub

Tema de GRUB de Uzunyx y menú oculto, como Ubuntu o Linux Mint (decidido
con el usuario el 2026-10-29).

- **Tema** (`theme/theme.txt`): neutro y oscuro, el mismo para Akane y
  Sora. Fondo `#111318` (el de Plymouth), menú centrado sin iconos en Noto
  Sans 20, el elemento elegido con el marco de las ventanas (superficie
  `#20232B`, borde del texto al 25 %, esquinas de 8 px: `select_*.png` en 9
  piezas, de `gen-grub.py`), los demás en gris, y abajo la cuenta atrás y
  las teclas. Las fuentes `.pf2` las hace `grub-mkfont` (latín, español
  incluido; GRUB carga todas las del directorio del tema). Reemplaza el
  fondo azul de `desktop-base`.
- **Menú oculto** (`/etc/default/grub.d/uzunyx-grub.cfg`):
  `GRUB_TIMEOUT_STYLE=hidden`, `GRUB_TIMEOUT=1`: GRUB espera un segundo y
  arranca; **Esc** (o F4, o mantener Shift) muestra el menú. Si os-prober
  está activado (`GRUB_DISABLE_OS_PROBER=false`: hay otros sistemas para
  elegir) el menú se muestra como siempre. Debian no trae el «mostrar el
  menú si el arranque anterior falló» de Ubuntu (`recordfail`).
- **Sin «Cargando Linux…» antes de Plymouth** (0.2.0): Debian arma
  `/etc/grub.d/10_linux` (de `grub2-common`) con `quiet_boot="0"` fijo, y
  GRUB escribe «Loading Linux …» y «Loading initial ramdisk …» en pantalla
  justo antes de la de arranque (Ubuntu lo trae en 1). El `preinst` lo
  desvía con `dpkg-divert` a `10_linux.dpkg-uzunyx` (grub-mkconfig salta los
  `*.dpkg-*`) y el `postinst` pone en su lugar una copia con
  `quiet_boot="1"`; un disparador sobre el archivo desviado la rehace cuando
  `grub2-common` lo actualiza. Al desinstalar, el `postrm` devuelve el
  original. El submenú «Opciones avanzadas» sigue mostrando los mensajes.
- El `postinst` copia el tema a `/boot/grub/themes/uzunyx` (GRUB siempre
  puede leer `/boot`; `/usr` puede estar en una raíz cifrada) y corre
  `update-grub`. El `.cfg` solo pone el tema si esa copia existe.
- El `.cfg` se lee después de `/etc/default/grub` y le gana: para cambiar
  algo, otro archivo en `grub.d` que vaya después (p. ej. `zz-local.cfg`).

Las entradas del menú dicen «Debian GNU/Linux» (`GRUB_DISTRIBUTOR` sale de
`/etc/os-release`); cambiarlo es parte de la tarea del nombre (fastfetch).

## Generar e instalar

Necesita `grub-common` (`grub-mkfont`), `fonts-noto-core`,
`fonts-dejavu-core` y `python3-cairo`.

    make deb
    sudo apt install ./build/uzunyx-grub_<versión>_all.deb

Solo se ve al reiniciar (apretando Esc para el menú).
