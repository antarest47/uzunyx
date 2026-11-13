# uzunyx-installer

Un solo `.deb` para instalar Uzunyx en un Debian normal:

    sudo apt install ./uzunyx-installer_*.deb
    sudo uzunyx-install

Trae todos los paquetes en un repositorio APT local
(`/usr/share/uzunyx-installer/repo`, sin red para lo propio; lo demás sale de
los espejos de Debian). `uzunyx-install` pasa los repositorios a `testing` si el
sistema está en otra versión (pregunta antes y guarda copia en `/var/backups`;
los repositorios ajenos a Debian se quedan), instala Plasma si falta y después
`uzunyx-desktop`.

No lo hace el `postinst` porque dpkg tiene el bloqueo de apt mientras corre, y
porque cambiar de versión de Debian no debe pasar sin preguntar.

Los efectos en C++ van fijados a una versión de KWin. Si el sistema tiene otra,
apt los omite (son `Recommends`) y `uzunyx-install` lo avisa. Cuando Debian sube
KWin, hay que recompilarlos y publicarlos en el repositorio (`../uzunyx-repo`).

`make deb` recoge el `.deb` de cada carpeta en la versión de su `Makefile` y falla
si falta alguno.
