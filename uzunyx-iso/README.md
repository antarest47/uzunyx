# uzunyx-iso

ISO en vivo e instalable de Uzunyx sobre Debian `forky`, para BIOS y UEFI.
Se construye sin root (`mmdebstrap --mode=unshare`, hacen falta `subuid` y `subgid`):

    sudo apt install mmdebstrap uidmap squashfs-tools xorriso mtools grub-pc-bin grub-efi-amd64-bin
    make -C ../uzunyx-installer deb
    make iso
    make test

La VM (`test-vm.sh`, QEMU, 6 GB de RAM): `make test` arranca la ISO más nueva con el
disco de la VM como esté, `make test-fresh` borra antes el disco para instalar desde
cero, `make test-installed` arranca el sistema instalado sin la ISO y `make vm-delete`
borra el disco. El disco (`build/disk.qcow2`) y las variables de UEFI
(`build/uefi-vars.fd`, donde queda la entrada de arranque que escribe el instalador) se
guardan entre una vez y otra; `make iso` los borra con el resto de `build/`. Con `bios`
como primer argumento arranca sin UEFI.

`make iso` instala Uzunyx con el mismo `uzunyx-install` que un Debian normal, así
que también lo prueba. `packages.list` es lo que se suma (sesión en vivo, Calamares,
firmware, apps). Sin `grub-pc-bin` la ISO sale solo para UEFI, sin avisar.

- Con `Recommends`, como un Debian normal (`--aptopt`; mmdebstrap los apaga y a la ISO le
  faltaba `xdg-user-dirs`, el que crea las carpetas del usuario, 2026-11-08). Los más
  pesados quedan fuera solo al armarla (`iso-excludes.pref`: fuentes Noto «extra»,
  `ibus-data`, `vlc`, Konqueror, la ayuda de KDE, cuentas en línea) para que la ISO no
  pase de 2 GiB: con todo eran 2,30 GiB, así 1,92. El motor web de Qt se queda: lo
  necesita `plasma-nm`.
- `customize-hook.sh` corre dentro del sistema nuevo. Todo entra y sale con `sync-in`
  y `sync-out`: el root del espacio de nombres es un uid subordinado y no lee `~`.
- `calamares/` es la marca, el huso por defecto (`locale.conf`: sin él el sistema
  queda en inglés) y las fuentes finales (la copia de Debian nombra una versión vieja).
- Bienvenida y presentación (maqueta aprobada por el usuario el 2026-11-08): Akane y Sora
  en la primera página (`productWelcome`) y, mientras instala, `calamares/show.qml`, siete
  diapositivas que pasan solas cada 8 s con un fundido (saludo, Akane, Sora, el panel con
  la píldora del centro de control ampliada, el centro de control, Tsunyx y los atajos).
  Las imágenes van en `calamares/slides/`: `gen-slides.sh` hace la de Tsunyx en un Plasma
  anidado, o la recorta de una captura dada (`gen-slides.sh captura.png`; la del repo es
  Tsunyx en una instalación completa, captura del usuario del 2026-11-09, sin las apps de
  este PC);
  `crop-panel.py` recorta el panel y la píldora de una captura de una sesión real a escala
  2 (el KWin anidado solo captura a 1× y ampliada se veía borrosa; captura del usuario
  del 2026-11-08); y `build-iso.sh` suma los fondos, el saludo y el centro de control de
  `uzunyx-welcome`.
- Barra lateral propia en QML (`calamares/calamares-sidebar.qml`, `sidebar: qml`; variante
  A de la maqueta, elegida por el usuario el 2026-11-08): pasos numerados del mismo
  tamaño, los hechos con un tilde en el acento y el actual en una píldora tenue. La de
  widgets achicaba el texto que no entraba y cortaba «Primeros pasos». No trae «Acerca
  de». Se puede ver sin Calamares con módulos `io.calamares.ui` de prueba
  (`ViewManager` como `ListModel`, `Branding` con un `enum`). El QML se puede ver sin Calamares con un `QQuickView` y la ruta de
  importación de `usr/share/calamares/qml` del `.deb` de `build-calamares/`.
- Página «Aplicaciones» después de Usuarios (maqueta aprobada por el usuario el
  2026-11-08): instalación por defecto (marcada) o selección ampliada (LibreOffice,
  Thunderbird, VLC, Elisa, GIMP, KCalc y sus traducciones). Es `packagechooserq@apps` con
  su QML propio (`calamares/uzunyx-apps.qml`, por `qmlFilename` en `uzunyx-apps.conf`);
  la elección queda en Global Storage como `packagechooser_apps`, y
  `contextualprocess@uzunyx-apps` (`uzunyx-install-apps.conf`) corre
  `/usr/libexec/uzunyx-install-apps` si es `extended`, después de `sources-final`: antes
  apt solo ve el repositorio de la ISO. Se descargan, para que la ISO quede por debajo de
  2 GiB (límite por archivo de las releases de GitHub); sin internet no falla y queda la
  instalación por defecto, con el registro en `/var/log/uzunyx-install-apps.log` del
  sistema nuevo. La primera página avisa si no hay internet (`internet` en `check` de
  `welcome.conf`, no en `required`). `customize-hook.sh` agrega la página, el paso y las
  `instances` a `settings.conf`.
- La bienvenida nombra a Calamares (`welcomeStyleCalamares: true`; se probó sin él y el
  usuario prefirió dejarlo). Archivo de intercambio por defecto (`initialSwapChoice: file`;
  Debian trae `none`), y además zram desde `uzunyx-desktop`; decidido con el usuario el
  2026-11-08.
- Tema oscuro: `pkexec` borra el entorno, así que Calamares corre por
  `/usr/libexec/uzunyx-calamares` (con su acción de polkit) con los colores de Akane en
  `/etc/calamares/theme/kdeglobals`. Calamares pinta la leyenda de particiones en negro
  fijo: `calamares/legend-colours.patch` usa los colores del tema. `make calamares`
  compila con él el Calamares de Debian en un sistema descartable (`build-calamares/`,
  no hace falta root) y `make iso` instala ese `.deb`: hay que hacerlo antes de la
  primera ISO, y otra vez si `libkpmcore` cambia de versión mayor en Debian.
- Para publicarla: `make iso SOURCES=1` deja también `packages.txt` y las fuentes de los
  paquetes de Debian en partes de 1,9 GB (`missing.txt` lista las que no pudo bajar).
  `make publish` sube primero las fuentes, la lista y `SHA256SUMS` a la release
  `v<versión>` de GitHub (con `gh`; `GITHUB=` para otro repositorio) y después la ISO,
  `SHA256SUMS` y `FUENTES.txt` (con el enlace a la release) a Cloudflare R2, en
  `iso/<versión>/` del bucket `uzunyx`, servido en `https://dl.uzunyx.com`. Las claves
  quedan en `gh auth login` y en el remoto `CloudflareR2` de `rclone config` (`REMOTE=`
  para otro); el token de R2 solo llega a ese bucket, así que va con
  `--s3-no-check-bucket`. Sin fuentes se niega: la GPL pide publicarlas con la ISO, y
  no se borra una release mientras su ISO siga publicada.
- El instalador se abre solo al entrar en la sesión en vivo (`/etc/xdg/autostart/uzunyx-install.desktop`,
  pedido por el usuario el 2026-11-08); el sistema instalado es una copia y también lo
  trae, así que solo corre con `boot=live`. La página «Aplicaciones» tiene su fondo
  propio: un `QQuickWidget` es blanco debajo.
- Icono: el del logo de Akane, fijado primero en el panel (`uzunyx-lookandfeel` lo fija
  si existe el `.desktop`, que solo hay en la sesión en vivo).
- El cargador se instala desde un repositorio en la propia ISO (`pool/`, `dists/`),
  porque depende de la máquina: GRUB para BIOS o para UEFI.
- Secure Boot no está probado; con él apagado arranca. La ISO usa el GRUB sin firmar
  de `grub-mkrescue`.
- `/etc/os-release` sigue diciendo Debian, a propósito (ver `uzunyx-terminal`).

Comprobado en QEMU el 2026-11-01, UEFI y BIOS: sesión en vivo, instalación sobre un
disco vacío, arranque desde el disco y escritorio. Sin red real, Wi-Fi ni hardware físico.
