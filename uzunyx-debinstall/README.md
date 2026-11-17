# uzunyx-debinstall

Instala paquetes `.deb` locales desde el administrador de archivos.

- Clic derecho en uno o varios `.deb` (Dolphin o escritorio) → **Instalar
  paquete** (menú de servicio en `/usr/share/kio/servicemenus`).
- También en «Abrir con» como «Instalador de paquetes»
  (`org.uzunyx.debinstall.desktop`, `MimeType=application/vnd.debian.binary-package`).
  Es también la del doble clic: lo pone `uzunyx-lookandfeel` ≥ 0.29.4 en
  `/etc/xdg/mimeapps.list` (con Discover de respaldo). Quien haya elegido
  otra app en `~/.config/mimeapps.list` conserva la suya.

Abre Konsole (o `x-terminal-emulator`), muestra nombre, versión y
descripción de cada paquete y ejecuta `sudo apt install /ruta/paquete.deb`,
así apt resuelve las dependencias y pide la contraseña y la confirmación como
siempre. Al terminar espera una tecla para que se pueda leer el resultado.

Desde la terminal: `uzunyx-debinstall archivo.deb [...]`.

`make deb` arma el paquete.
