# uzunyx-archive-keyring

Agrega a APT el repositorio de Uzunyx, `https://dl.uzunyx.com/repo` (suite `forky`,
componente `main`), y la clave pública con la que está firmado, para que los paquetes de
Uzunyx se actualicen con `apt upgrade` como el resto del sistema.

| Archivo | Qué es |
|---|---|
| `/usr/share/keyrings/uzunyx-archive-keyring.gpg` | Clave pública «Uzunyx Archive Signing Key», `971A 62FD 88B6 D53B 860F  B7DD 05D1 9D02 8CE7 A0BC` (ed25519, sin vencimiento) |
| `/etc/apt/sources.list.d/uzunyx-archive.sources` | El repositorio, con `Signed-By` a esa clave (solo vale para este repositorio) |

La clave privada la tiene solo quien publica el repositorio, fuera de git. El repositorio
se arma y se sube con `../uzunyx-repo` (`make publish`).

Para comprobar la clave a mano:

    gpg --show-keys /usr/share/keyrings/uzunyx-archive-keyring.gpg
