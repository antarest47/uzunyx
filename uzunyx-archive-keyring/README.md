# uzunyx-archive-keyring

Agrega a APT el repositorio de Uzunyx, `https://dl.uzunyx.com/repo` (suite `testing`,
componente `main`), y la clave pública con la que está firmado, para que los paquetes de
Uzunyx se actualicen con `apt upgrade` como el resto del sistema.

| Archivo | Qué es |
|---|---|
| `/usr/share/keyrings/uzunyx-archive-keyring.gpg` | Clave pública «Uzunyx Archive Signing Key», `971A 62FD 88B6 D53B 860F  B7DD 05D1 9D02 8CE7 A0BC` (ed25519, sin vencimiento) |
| `/etc/apt/sources.list.d/uzunyx-archive.sources` | El repositorio, con `Signed-By` a esa clave (solo vale para este repositorio) |

Uzunyx sigue a Debian `testing`. Hasta 0.1.0 seguía a `forky`: al instalar 0.2.0 por
primera vez o al actualizar desde una versión anterior, el `postinst` pasa una sola vez
los repositorios de Debian (`sources.list`, `*.list` y `*.sources`, solo las líneas o
bloques de un espejo de `debian.org`) de `forky`, `forky-updates` y `forky-security` a
`testing`, `testing-updates` y `testing-security`, con copia en
`/var/backups/uzunyx-archive-keyring-apt-<fecha>`. Si después se vuelve a `forky` a mano,
no lo repite.

La clave privada la tiene solo quien publica el repositorio, fuera de git. El repositorio
se arma y se sube con `../uzunyx-repo` (`make publish`).

Para comprobar la clave a mano:

    gpg --show-keys /usr/share/keyrings/uzunyx-archive-keyring.gpg
