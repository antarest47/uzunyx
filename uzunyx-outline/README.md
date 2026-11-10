# uzunyx-outline

Efecto de KWin en C++ que dibuja un borde de 1 px (blanco al 25 %, 12 % sin
foco) con esquinas de 8 px alrededor de las ventanas que dibujan su propio
marco (Firefox, Electron, GTK/libadwaita), igual que el contorno de la
decoración uzunyx. Las ventanas con decoración del servidor no se tocan.

Sin borde: ventanas con decoración del servidor, a pantalla completa o que
ocupan una pantalla entera sin estarlo (juegos, reproductores), menús y
ventanas emergentes, las superficies de `edge-gaps`, las de Plasma (Tsunyx,
KRunner), la pantalla de inicio (`ksplashqml`) y la de salida
(`ksmserver`); estas dos últimas desde 0.2.1 (el splash mostraba el borde).

## Cómo funciona

No pinta nada por su cuenta: a cada ventana le cuelga un
`OutlinedBorderItem` (el elemento de escena que KWin usa para el contorno de
las decoraciones, como el de Breeze) como hijo de su `WindowItem`. KWin lo
dibuja en vivo junto con la ventana, también dentro de otros efectos
(lámpara mágica, desvanecido) y lo oculta con ella al minimizar.

Se probó antes con un efecto en JavaScript y un shader: no sirve, porque los
efectos JS aplican el shader a una foto fija de la ventana (ver `CLAUDE.md`).

## Versión de KWin

Se compila contra el KWin instalado (`kwin-dev`) y solo carga en esa versión
exacta: KWin compara la versión en el IID del plugin y rechaza los demás sin
fallar. Por eso el paquete depende de esa versión
(`kwin-wayland (>= 4:6.7.4), (<< 4:6.7.4.~)`) y lleva la versión de KWin en
la suya (`0.1.1+kwin6.7.4`). **Tras cada actualización de KWin hay que
volver a compilarlo e instalarlo.**

## Compilar

    sudo apt install --no-install-recommends kwin-dev cmake extra-cmake-modules
    make deb
    sudo apt install ./build/uzunyx-outline_*.deb

Cargarlo sin cerrar sesión (activo por defecto en las siguientes):

    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect uzunyxoutline

Con el mosaico encendido (`[Script-uzunyxtiling] Mode` en `kwinrc`), la ventana activa lleva 3 px en el acento de la edición (`[Colors:View] DecorationFocus` de `kdeglobals`). `KConfigWatcher` avisa del cambio: `uzunyx-tiling` escribe con `--notify`. Necesita además `libkf6config-dev`.
