# uzunyx-repo

El repositorio APT de Uzunyx, en `https://dl.uzunyx.com/repo` (bucket `uzunyx` de
Cloudflare R2, carpeta `repo/`), suite `forky`, componente `main`. No es un paquete: los
sistemas lo usan por `uzunyx-archive-keyring`, que trae la clave pública y el `.sources`.

    make repo      # arma build/repo y lo firma (gpg pide la contraseña de la clave)
    make publish   # lo arma y lo sube con rclone (remoto CloudflareR2, REMOTE= para otro)

Lleva el `.deb` de cada carpeta que lleva `uzunyx-installer` (su lista `FOLDERS`), en la
versión de su `Makefile`: antes, `make deb` en cada una. `make-repo.sh` usa
`apt-ftparchive` (ya en Debian, sin reprepro): `pool/main` y un solo índice,
`dists/forky/main/binary-amd64`, que también trae los paquetes `all`; por eso `Release`
dice solo `amd64` (con `all`, apt buscaría un índice `binary-all`). Firma `InRelease` y
`Release.gpg` con la clave `971A62FD88B6D53B860FB7DD05D19D028CE7A0BC`, cuya parte
privada no está en git.

Cloudflare guarda en caché los `.gz` y los `.deb` durante horas: un `Packages.gz` viejo
con un `InRelease` nuevo hizo fallar a apt («File has unexpected size») y con él el
armado de la ISO. Por eso el índice también va por su hash (`Acquire-By-Hash: yes`,
copias en `by-hash/SHA256` y `by-hash/SHA512`; apt pide por el más fuerte), como en
Debian: esas direcciones nunca cambian de contenido. Por lo mismo, **un paquete
publicado no se vuelve a armar con la misma versión**: la caché seguiría dando el viejo.

Al subir, primero se copian los paquetes nuevos y las copias por hash, después el índice y al final se borran
los viejos, para que el índice nunca nombre un archivo que no está. Solo queda la última
versión de cada paquete.

Las versiones tienen que subir siempre, o apt no actualiza: un hash solo no sirve
(Lunyx pasó a `+git.<fecha>.<hash>`).

Para probarlo sin tocar el sistema, apt con listas y caché en una carpeta propia:

    apt-get -o Dir::State::Lists=$T/lists -o Dir::Cache=$T/cache \
        -o Dir::Etc::SourceList=/dev/null -o Dir::Etc::SourceParts=$T \
        -o APT::Sandbox::User=$USER -o Debug::NoLocking=1 update
