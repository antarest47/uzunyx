<p align="center">
  <img src="uzunyx-plymouth/art/uzunyx-logo-akane.png" alt="Uzunyx" width="420">
</p>

<p align="center">
  Un escritorio propio sobre <b>KDE Plasma 6.7 (Wayland)</b> y <b>Debian testing</b>,
  empaquetado entero en <code>.deb</code>.
</p>

![Uzunyx Akane](uzunyx-lnf/package/contents/previews/fullscreenpreview.jpg)

Uzunyx no es un tema para instalar a mano: es un conjunto de paquetes que deja un
Plasma recién instalado con su aspecto y su comportamiento, sin pasos en la interfaz.
Funciona en cualquier Plasma 6.7 o superior y no depende de la KDE Store.

Viene en dos ediciones que comparten todo salvo el color: **Akane** (carmesí) y
**Sora** (cian). Se cambia de una a otra en un clic, sin tocar el panel.

![Uzunyx Sora](uzunyx-lnf/previews-sora/fullscreenpreview.jpg)

## Qué trae

**Ventanas**
- Esquinas de 8 px siempre, también maximizadas, y un margen de 8 px a los bordes de
  la pantalla. Las apps que dibujan su propio marco (Firefox, Electron, libadwaita)
  reciben el mismo borde y el mismo redondeo.
- Botones de ventana de bola brillante iguales en KDE, GTK, Firefox y Electron.
- Animaciones al abrir y cerrar, minimizar con forma de genio como en macOS,
  pantalla completa en un escritorio propio y un Alt+Tab estilo Cover Switch.
- Mosaico automático opcional («Principal y pila» y «Espiral»), con atajos para la
  mano izquierda, divisiones que se arrastran y escritorios dinámicos.

**Panel**
- Flotante, centrado y ajustado al contenido, aunque haya ventanas maximizadas.
- Gestor de tareas estilo Unity con un punto por ventana, paginador, reloj propio.
- Centro de control al estilo de GNOME: wifi, Bluetooth, sonido, brillo, batería,
  reproductor, portapapeles, apps en segundo plano y dispositivos extraíbles, todo
  en una píldora del panel.

![Centro de control](uzunyx-welcome/control-center.png)

**Tsunyx**, el menú de aplicaciones a pantalla completa, con un buscador que también
ejecuta comandos, calcula e inicia temporizadores (repositorio aparte).

![Tsunyx](uzunyx-iso/calamares/slides/tsunyx.png)

**Además**
- Esquemas de color, tema de escritorio, iconos (Kora con carpetas propias), fondos,
  pantalla de bloqueo, inicio de sesión (SDDM), pantalla de salir, KSplash,
  Plymouth y GRUB a juego.
- Terminal: zsh con Oh My Zsh, autocompletado en vivo, Atuin y un prompt de Starship
  por edición, sin tocar el shell del usuario.
- Bienvenida para usuarios nuevos, una ventana con todos los atajos (`Super+Espacio`)
  y **Uzunyx Doctor**, que actualiza el sistema y comprueba que todo siga en su lugar.

## Instalar

Hace falta Debian testing (`forky`) con Plasma 6.7 o superior, o un Debian estable que
se pueda pasar a testing.

- **En un Debian ya instalado:** `uzunyx-installer` es un solo `.deb` con un repositorio
  APT local con todos los paquetes. `uzunyx-install` pasa el sistema a `forky` si hace
  falta (pregunta antes y guarda copia), instala Plasma si falta y después Uzunyx.

  ```bash
  sudo apt install ./uzunyx-installer_*.deb
  ```

  ```bash
  sudo uzunyx-install
  ```

- **Desde cero:** `uzunyx-iso` arma una ISO en vivo e instalable (BIOS y UEFI) con
  Calamares. Ver [uzunyx-iso/README.md](uzunyx-iso/README.md).

Los efectos de KWin escritos en C++ (`uzunyx-outline`, `uzunyx-openclose`,
`uzunyx-genie`, `uzunyx-altguard`) se compilan contra una versión exacta de KWin. Son
`Recommends`: si el sistema tiene otra versión, apt los omite y el resto funciona.

## Compilar

Cada carpeta es un paquete y se arma con `make deb`; el `.deb` queda en su `build/`.
Las dependencias de compilación de cada uno están en su README.

```bash
make -C uzunyx-desktop deb
```

`make -C uzunyx-installer deb` junta los `.deb` de todas las carpetas en el instalador.

## Paquetes

| Paquete | Qué hace |
|---|---|
| [`uzunyx-desktop`](uzunyx-desktop) | Metapaquete: instala el escritorio completo |
| [`uzunyx-lnf`](uzunyx-lnf) | Temas globales Akane y Sora, disposición del panel, pantallas de salir, bloqueo e inicio |
| [`uzunyx-editions`](uzunyx-editions) | Cambia de edición (`uzunyx-edition`) y su módulo en Configuración del sistema |
| [`uzunyx-deco`](uzunyx-deco) | Decoración de ventanas, scripts de KWin (maximizar suave, pantalla completa) y Alt+Tab |
| [`uzunyx-plasmatheme`](uzunyx-plasmatheme) | Tema de escritorio de Plasma |
| [`uzunyx-colors`](uzunyx-colors) | Esquemas de color de Plasma y Konsole |
| [`uzunyx-buttons`](uzunyx-buttons) | Botones de ventana, tema GTK `Breeze-Uzunyx` y tema de iconos |
| [`kora-icons`](kora-icons) | Receta para empaquetar los iconos Kora |
| [`uzunyx-wallpapers`](uzunyx-wallpapers) | Fondos y tema de SDDM |
| [`edge-gaps`](edge-gaps) | Márgenes en los bordes de la pantalla y modo enfoque |
| [`uzunyx-tasks`](uzunyx-tasks) | Gestor de tareas |
| [`uzunyx-pager`](uzunyx-pager) | Paginador |
| [`uzunyx-clock`](uzunyx-clock) | Reloj y calendario |
| [`uzunyx-controlcenter`](uzunyx-controlcenter) | Centro de control |
| [`uzunyx-lockkeys`](uzunyx-lockkeys) | Aviso de Bloq Mayús y Bloq Num |
| [`uzunyx-logout`](uzunyx-logout) | Botón de salir del panel |
| [`uzunyx-tiling`](uzunyx-tiling) | Mosaico automático, escritorios dinámicos y gestos |
| [`uzunyx-outline`](uzunyx-outline) | Efecto de KWin: borde y redondeo de ventanas sin decoración |
| [`uzunyx-openclose`](uzunyx-openclose) | Efecto de KWin: abrir y cerrar ventanas |
| [`uzunyx-genie`](uzunyx-genie) | Efecto de KWin: minimizar con forma de genio |
| [`uzunyx-altguard`](uzunyx-altguard) | Plugin de KWin: que Alt no abra el menú de la app tras un atajo |
| [`uzunyx-shortcuts`](uzunyx-shortcuts) | Atajos globales |
| [`uzunyx-keys`](uzunyx-keys) | Ventana con todos los atajos |
| [`uzunyx-timer`](uzunyx-timer) | Temporizadores |
| [`uzunyx-terminal`](uzunyx-terminal) | zsh, Starship, Atuin y fastfetch |
| [`uzunyx-welcome`](uzunyx-welcome) | Bienvenida |
| [`uzunyx-plymouth`](uzunyx-plymouth) | Pantalla de arranque |
| [`uzunyx-grub`](uzunyx-grub) | Tema y menú oculto de GRUB |
| [`uzunyx-doctor`](uzunyx-doctor) | Actualizar y comprobar el sistema |
| [`lunyx`](lunyx) | Receta para Lunyx, cliente de biblioteca de anime |
| [`uzunyx-installer`](uzunyx-installer) | Instalador en un solo `.deb` |
| [`uzunyx-iso`](uzunyx-iso) | ISO en vivo e instalable |

## Licencia

El código es GPL-3.0-or-later y las imágenes CC0-1.0. Las partes adaptadas de KDE y
de terceros conservan su licencia. Detalles en [COPYRIGHT.md](COPYRIGHT.md).

Debian, KDE, Plasma y Firefox son marcas de sus dueños. Uzunyx no es un proyecto
oficial de ninguno de ellos.
