# uzunyx-debinstall

Instala paquetes `.deb` locales desde el administrador de archivos.

- Clic derecho en uno o varios `.deb` (Dolphin o escritorio) → **Instalar
  paquete** (menú de servicio en `/usr/share/kio/servicemenus`).
- También en «Abrir con» como «Instalador de paquetes»
  (`org.uzunyx.debinstall.desktop`, `MimeType=application/vnd.debian.binary-package`).
  No se pone como predeterminado: el doble clic sigue abriendo Discover.

Abre Konsole (o `x-terminal-emulator`), muestra nombre, versión y
descripción de cada paquete y ejecuta `sudo apt install /ruta/paquete.deb`,
así apt resuelve las dependencias y pide la contraseña y la confirmación como
siempre. Al terminar espera una tecla para que se pueda leer el resultado.

Desde la terminal: `uzunyx-debinstall archivo.deb [...]`.

`make deb` arma el paquete.
