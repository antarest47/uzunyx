# Calamares job: installs the extended selection of apps ("Aplicaciones" page,
# packagechooser_apps = "extended") with /usr/libexec/uzunyx-install-apps,
# and shows what apt is doing in the status line and the progress bar.
# Downloading LibreOffice, Thunderbird, GIMP… takes a while, and with
# contextualprocess the page sat at 94 % without a word (0.2.2). It never
# fails the installation: without internet the default install stays.
import os
import select
import subprocess

import libcalamares

status = "Instalando las aplicaciones elegidas…"


def pretty_name():
    return "Instalar las aplicaciones elegidas"


def pretty_status_message():
    return status


def report(message, fraction):
    global status
    status = message
    libcalamares.job.setprogress(max(0.0, min(1.0, fraction)))


def wanted():
    choice = libcalamares.globalstorage.value("packagechooser_apps")
    if isinstance(choice, (list, tuple)):
        return "extended" in choice
    return "extended" in str(choice or "").split(",")


def handle(line, state):
    """One line of the script's fd 3: its own marks and apt's Status-Fd."""
    kind, _, rest = line.partition(":")
    if kind == "uzunyx":
        if rest == "update":
            report("Actualizando la lista de paquetes…", 0.02)
        elif rest == "install":
            report("Preparando la descarga de las aplicaciones…", 0.05)
        elif rest == "finish":
            report("Terminando la instalación de las aplicaciones…", 0.99)
        libcalamares.utils.debug("uzunyxapps: " + rest)
        return
    if kind not in ("dlstatus", "pmstatus"):
        return
    fields = rest.split(":", 2)
    if len(fields) < 2:
        return
    try:
        percent = float(fields[1])
    except ValueError:
        return
    whole = int(percent)
    if (kind, whole) == state.get("last"):
        return
    state["last"] = (kind, whole)
    if kind == "dlstatus":
        report("Descargando las aplicaciones… %d %%" % whole, 0.05 + 0.55 * percent / 100)
    else:
        report("Instalando las aplicaciones… %d %%" % whole, 0.60 + 0.39 * percent / 100)
    if whole % 10 == 0:
        libcalamares.utils.debug("uzunyxapps: %s %d %%" % (kind, whole))


def follow(process, state):
    """Reads the progress until the script ends. Not until the pipe closes: a
    daemon started by a package's postinst could keep it open forever."""
    fd = process.stdout.fileno()
    pending = b""
    while True:
        ready, _, _ = select.select([fd], [], [], 1.0)
        if ready:
            chunk = os.read(fd, 65536)
            if not chunk:
                process.wait()
                break
            pending += chunk
            *lines, pending = pending.split(b"\n")
            for line in lines:
                handle(line.decode("utf-8", "replace").strip(), state)
        elif process.poll() is not None:
            break
    process.stdout.close()


def run():
    if not wanted():
        libcalamares.utils.debug("uzunyxapps: instalación por defecto")
        return None
    root = libcalamares.globalstorage.value("rootMountPoint")
    if not root:
        libcalamares.utils.warning("uzunyxapps: no rootMountPoint")
        return None
    report("Instalando las aplicaciones elegidas…", 0.0)
    state = {}
    try:
        process = subprocess.Popen(["/usr/libexec/uzunyx-install-apps", root],
                                   stdin=subprocess.DEVNULL, stdout=subprocess.PIPE)
        follow(process, state)
    except OSError as error:
        libcalamares.utils.warning("uzunyxapps: %s" % error)
    report("Aplicaciones instaladas", 1.0)
    return None
