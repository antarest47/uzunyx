# uzunyx-desktop

Metapaquete que instala todo Uzunyx (para el instalador o la ISO).

- **Depends:** temas globales Akane y Sora (`uzunyx-lookandfeel`) con su
  esquema de color, decoración, tema de Plasma, botones, iconos Kora y
  fondos; `uzunyx-editions`, `edge-gaps`, `uzunyx-lockkeys`,
  `uzunyx-shortcuts` y `tsunyx-launcher`. También `xdg-user-dirs` (0.1.17), que crea
  Documentos, Descargas y las demás carpetas del usuario: en Debian solo llega como
  recomendado de GLib, y la ISO se arma sin recomendados.
  Y `systemd-zram-generator` (0.1.18, decidido con el usuario el 2026-11-08) con
  `zram/uzunyx.conf` en `/usr/lib/systemd/zram-generator.conf.d/`: swap comprimido en la
  RAM (la mitad, 8 GiB como máximo, zstd) con prioridad sobre el archivo de intercambio
  que propone el instalador. Se cambia en `/etc/systemd/zram-generator.conf`.
- **Recommends** (apt los instala por defecto, pero se pueden quitar sin
  llevarse el resto): los efectos de KWin en C++ (`uzunyx-outline`,
  `uzunyx-openclose`, `uzunyx-genie`), que van fijados a una versión de
  KWin y hay que quitarlos o recompilarlos cuando KWin se actualiza; la
  pantalla de arranque (`uzunyx-plymouth`) y GRUB (`uzunyx-grub`), que
  cambian cómo arranca el PC.

Los paquetes están en el repositorio APT de Uzunyx (`https://dl.uzunyx.com/repo`,
ver `uzunyx-archive-keyring`), que `uzunyx-installer` y la ISO dejan configurado.
Para probar los que se construyen aquí (`make deb` en cada carpeta, y Tsunyx en
su propio repositorio, al lado de este):

    sudo apt install ./uzunyx-desktop/build/uzunyx-desktop_*_all.deb \
        ./*/build/*.deb ../tsunyx-launcher/build/*.deb
