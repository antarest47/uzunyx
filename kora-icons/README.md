# kora-icons

Receta para empaquetar el tema de iconos [Kora](https://github.com/bikass/kora)
(GPL-3.0): iconos SVG redondeados, con degradados y relieve, y carpetas azules
redondeadas. Incluye las variantes `kora` y `kora-pgrey` (carpetas grises). Lo
que le falta lo hereda de Breeze.

El proyecto original no publica versiones, así que el `Makefile` fija un commit
(`KORA_COMMIT`) y la versión del paquete lleva su fecha y hash. El árbol
original (~55 MB, ~23 000 archivos) no se copia a este repositorio:

    make fetch    # clona github.com/bikass/kora en ../../kora-upstream (o KORA_SRC=...)
    make deb      # comprueba que la copia está exactamente en ese commit y genera el .deb
    sudo apt install ./build/kora-icon-theme_*_all.deb

Al copiarlo se quitan el script `create-new-icon-theme.cache.sh` y la
`icon-theme.cache` antigua del original, y se normalizan los permisos (algunos
SVG venían como ejecutables).

Para actualizar: cambiar `KORA_COMMIT` y `KORA_DATE`, `make fetch`, revisar el
cambio y `make deb`.
