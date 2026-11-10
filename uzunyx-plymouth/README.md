# uzunyx-plymouth

Pantalla de arranque (Plymouth) de Uzunyx, un tema por edición:
`uzunyx-akane` (por defecto) y `uzunyx-sora`, en
`/usr/share/plymouth/themes/`.

- Fondo liso `#111318` (el de la paleta), que pinta el propio Plymouth
  (`Window.SetBackground*Color`), sin imagen.
- Icono de la edición (`../icons/uzunyx-icon-<edición>.png`) fijo y, debajo,
  el nombre (`art/uzunyx-logo-<edición>.png`), centrados un poco por encima
  de la mitad. Entran con un fundido de medio segundo.
- Un reflejo blanco inclinado recorre el nombre en 1,4 s cada 3,6 s, y las
  estrellas y perlas del nombre titilan escalonadas con un destello del
  acento (`#E62967` Akane, `#16CDE0` Sora, los de `uzunyx-colors`).
- Contraseña de disco cifrado: campo `#20232B` con borde del texto al 25 %
  y esquinas de 8 px, como las ventanas, con puntos del acento. Mensajes
  del sistema (fsck) abajo, tenues.

Usa el plugin `script` de Plymouth (viene en `plymouth`; `two-step` está en
`plymouth-themes`, que no se pide). Plymouth no puede recortar ni mezclar
imágenes en vivo, así que el brillo son 36 cuadros generados de antemano
(`shine-NN.png`: capas blancas ya recortadas con la forma del nombre) que el
script pone encima, uno cada dos refrescos (25 cuadros/s). Las posiciones
de los destellos están en el script, relativas al logo: si cambia el
dibujo del nombre, hay que actualizarlas.

Las imágenes van en dos tamaños: el de una pantalla de 1200 px de alto
(`logo.png`) y el doble para HiDPI (`logo@2x.png`, pantallas de 1800 px o
más). El script toma el juego más cercano y solo escala la diferencia (nada
si es menor al 5 %). **Plymouth escala mal la transparencia**: el negro de
los píxeles transparentes se mete en los bordes, y hasta 0.1.0 (imágenes a
1,5× achicadas al cargar) el nombre salía dentado y con puntos oscuros.
Como eso no alcanzó (0.2.0 seguía igual en la pantalla real), desde 0.2.1
el nombre y el icono van ya mezclados sobre el fondo `#111318`, opacos: el
fondo es liso y el rectángulo no se ve. El brillo y los destellos siguen
con transparencia. El contorno rojo oscuro de las letras es parte del dibujo. Cada tema ocupa
unos 1,4 MB dentro del initramfs.

## Generar, ver e instalar

    make images     # build/<edición>/*.png (necesita python3-cairo)
    make preview    # build/uzunyx-<edición>.webp y build/still-<edición>/ (con imagemagick)
    make deb        # build/uzunyx-plymouth_<versión>_all.deb

`preview.py` reproduce con cairo la disposición y los tiempos del script;
es una aproximación, no Plymouth.

## Qué hace el paquete

- **Al instalarlo por primera vez** deja `uzunyx-akane` como tema
  (`plymouth-set-default-theme`) y regenera el menú de GRUB. En las
  actualizaciones respeta el tema elegido.
- `/etc/default/grub.d/uzunyx-splash.cfg` añade `splash` a
  `GRUB_CMDLINE_LINUX_DEFAULT` si falta, sin tocar `/etc/default/grub`.
  Sin `splash` (Debian arranca solo con `quiet`) Plymouth no muestra ningún
  tema.
- El initramfs (Plymouth corre desde ahí) se regenera con el disparador
  `update-initramfs` en cada instalación o actualización (`debian/triggers`).
- Al desinstalarlo, si el tema era uno de los nuestros, vuelve al de
  Debian (`--reset`) y regenera el initramfs; al purgarlo se va el archivo
  de `grub.d` y se regenera el menú de GRUB.

Cambiar de edición a mano:

    sudo plymouth-set-default-theme -R uzunyx-sora

## Probar sin reiniciar

Desde una consola de texto (Ctrl+Alt+F3), no desde la sesión gráfica:

    sudo plymouthd; sudo plymouth --show-splash; sleep 8; sudo plymouth --quit

Para ver el pedido de contraseña, entre `--show-splash` y `--quit`:
`sudo plymouth ask-for-password --prompt="Prueba"`.
