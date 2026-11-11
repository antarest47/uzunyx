# uzunyx-editions

Cambia entre las ediciones de Uzunyx, **Akane** y **Sora**, sin tocar los
paneles ni los iconos.

Hace falta porque Plasma 6.7 solo aplica el fondo de un tema global junto
con su disposición del escritorio, que reemplaza los paneles
(`libklookandfeel/klookandfeelmanager.cpp`: la marca `Wallpaper` se detecta
pero `save()` no la aplica). Al elegir el tema global en la configuración
normal solo cambian los colores y la decoración.

| | Akane | Sora |
|---|---|---|
| Tema global | `org.uzunyx.desktop` | `org.uzunyx.sora` |
| Fondo de escritorio | `UzunyxAkane` | `UzunyxSora` |
| Bloqueo e inicio de sesión | `UzunyxAkaneSky` | `UzunyxSoraSky` |
| Logo del lanzador | `uzunyx-akane` | `uzunyx-sora` |
| Pantalla de arranque | `uzunyx-akane` | `uzunyx-sora` |

(Fondos de `uzunyx-wallpapers`, temas globales y logos de
`uzunyx-lookandfeel`, temas Plymouth de `uzunyx-plymouth`.)

## Partes

- **`uzunyx-edition`** (`/usr/bin`, Python): hace el trabajo; sirve también
  desde la terminal o un instalador.

      uzunyx-edition status            # akane, sora u other
      uzunyx-edition set sora          # tema, fondo, bloqueo y lanzador
      uzunyx-edition set akane --sddm  # además, la pantalla de inicio de sesión
      uzunyx-edition set sora --sddm --plymouth  # y la de arranque
      uzunyx-edition set sora --no-wallpaper --no-lock

  - Tema: `plasma-apply-lookandfeel --apply` (sin `--resetLayout`: no toca
    paneles).
  - Fondo: `plasma-apply-wallpaperimage` con el paquete de fondo (todos los
    escritorios).
  - Bloqueo: `[Greeter][Wallpaper][org.kde.image][General]` `Image` y
    `PreviewImage` en el `kscreenlockerrc` del usuario (el valor del sistema,
    Akane, está en `/etc/xdg/kscreenlockerrc`).
  - Lanzador: script de plasmashell (`evaluateScript` por D-Bus) que pone el
    logo en `icon` de cada `local.tsunyxlauncher` u `org.kde.plasma.kickoff`.
  - Con `--sddm` y/o `--plymouth`: una sola llamada
    `pkexec /usr/libexec/uzunyx-system-edition <edición> sddm plymouth`
    (una sola contraseña).
  - Si un paso falla, sigue con los demás y sale con 1.
- **`uzunyx-system-edition`** (`/usr/libexec`, sh, como root; hasta 0.1.0
  era `uzunyx-sddm-edition`, solo SDDM): solo acepta `akane` o `sora` y las
  partes `sddm` y `plymouth`.
  - `sddm`: escribe `theme.conf.user` (`[General] background=…`) en el tema
    SDDM `uzunyx`; SDDM lo lee por encima de `theme.conf`, como hace el
    módulo de SDDM de KDE. El `postrm` borra ese archivo al desinstalar.
  - `plymouth`: `plymouth-set-default-theme -R uzunyx-<edición>` (regenera
    el initramfs, 10–30 s; no hace nada si ya es ese tema). Falla si no
    está `uzunyx-plymouth`.
  - Acción de polkit `org.uzunyx.edition.system` (`auth_admin_keep`).
    Antes, `org.uzunyx.edition.sddm`.
- **Módulo «Edición de Uzunyx»** (`kcm_uzunyx_editions`, en Configuración
  del sistema > Colores y temas; `kcmshell6 kcm_uzunyx_editions`): C++
  (`kcm/src/kcm.cpp`, `KQuickConfigModule`) + QML (`kcm/ui/main.qml`). Dos
  tarjetas con el fondo y el logo de cada edición (marca la actual, leída de
  `LookAndFeelPackage` en `kdeglobals`) y casillas: tema y colores, fondo,
  bloqueo, icono del lanzador (marcadas), pantalla de inicio de sesión y
  pantalla de arranque (desmarcadas: afectan a todos y piden contraseña;
  la de arranque solo aparece si está `uzunyx-plymouth`). Ni SDDM ni
  Plymouth se leen para marcar la edición actual: siempre se ofrecen. «Aplicar» ejecuta
  `uzunyx-edition` y muestra su error si falla.
  Debajo, desde 0.4.0, **«Foco de las ventanas»**: clic para enfocar (el de
  KWin), el foco sigue al ratón (`[Windows] FocusPolicy=FocusFollowsMouse`
  en el `kwinrc` del usuario: la ventana recibe el teclado pero no sube al
  frente hasta el clic; al pasar al escritorio o al panel la última conserva
  el foco) o además pasa al frente (`AutoRaise=true`,
  `AutoRaiseInterval=300`; KWin trae 750 ms). Volver al clic borra esas
  claves. Se aplica en caliente con la señal `reloadConfig` de `/KWin`, sin
  ejecutar `uzunyx-edition` si no cambió la edición. Textos en inglés con
  traducción `po/es.po` (dominio `kcm_uzunyx_editions`).

Compilado contra KF6 (no depende de la versión de KWin): solo hay que
recompilar si cambia la ABI de KF6/Qt, como cualquier paquete.

## Compilar e instalar

Necesita `cmake extra-cmake-modules qt6-base-dev qt6-declarative-dev
libkf6kcmutils-dev libkf6i18n-dev libkf6config-dev gettext`.

    make deb
    sudo apt install ./build/uzunyx-editions_0.4.0_amd64.deb

Para probar el módulo sin instalarlo (`make compile` antes):

    PATH=$PWD:$PATH QT_PLUGIN_PATH=$PWD/build/cmake/bin kcmshell6 kcm_uzunyx_editions

El menú de aplicaciones trae el lanzador «Uzunyx», que abre este módulo con el
logo de la edición. `uzunyx-edition sync` lo ajusta al tema global; corre al
iniciar sesión.
