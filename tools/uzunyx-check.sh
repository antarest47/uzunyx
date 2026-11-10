#!/bin/sh
# Reports how a Plasma session came out with Uzunyx: run it inside the
# session of the user to check (e.g. a brand new one) and it writes
# /tmp/uzunyx-check-<user>.txt, readable by other users to compare.
out=/tmp/uzunyx-check-$(id -un).txt
cfg() { kreadconfig6 "$@" 2>/dev/null; }
{
    echo "== usuario: $(id -un) - $(date '+%F %T')"
    echo "== tema global: $(cfg --file kdeglobals --group KDE --key LookAndFeelPackage) (kdedefaults: $(cat ~/.config/kdedefaults/package 2>/dev/null))"
    echo "== esquema de color: $(cfg --file kdeglobals --group General --key ColorScheme)"
    echo "== decoración: $(cfg --file kwinrc --group org.kde.kdecoration2 --key theme)"
    echo "== iconos: $(cfg --file kdeglobals --group Icons --key Theme)"
    echo "== tema de Plasma: $(cfg --file plasmarc --group Theme --key name)"
    echo "== pantalla de inicio: $(cfg --file ksplashrc --group KSplash --key Theme)"
    echo "== GTK:"; grep -h 'gtk-theme-name\|gtk-icon-theme-name' ~/.config/gtk-3.0/settings.ini 2>/dev/null
    echo "== efectos de KWin:"
    for e in uzunyxoutline uzunyxopenclose genieanywhere magiclamp scale blur; do
        echo "  $e=$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded $e 2>/dev/null)"
    done
    echo "== scripts de KWin:"
    for s in softmaximize panelconfigretry tsunyxlauncherskiptaskbar; do
        echo "  $s=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded $s 2>/dev/null)"
    done
    echo "== edge-gaps: $(pgrep -af edge-gaps | head -1)"
    echo "== ayudante de insignias: $(pgrep -af uzunyx-task-badges | head -1)"
    echo "== notificaciones (PopupPosition): $(cfg --file plasmanotifyrc --group Notifications --key PopupPosition)"
    echo "== gestor de tareas: $(grep -c '^plugin=org.uzunyx.tasks' ~/.config/plasma-org.kde.plasma.desktop-appletsrc) org.uzunyx.tasks, $(grep -c '^plugin=org.kde.plasma.icontasks' ~/.config/plasma-org.kde.plasma.desktop-appletsrc) icontasks"
    echo "== apps ancladas: $(grep -h '^launchers=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null)"
    echo "== paneles:"
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        'panels().forEach(function (p) { print("  " + p.location + " alto=" + p.height + " flotante=" + p.floating + " " + p.widgets().map(function (w) { return w.type; }).join(", ")); })' 2>/dev/null
    echo "== atajos (marca): $(cat ~/.config/uzunyx/shortcuts-version 2>/dev/null)"
    echo "== fondo:"; grep -h '^Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null | sort -u
    echo "== bloqueo: $(cfg --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image)"
    echo "== Bloq Num (kcminputrc): $(cfg --file kcminputrc --group Keyboard --key NumLock)"
} > "$out" 2>&1
chmod 644 "$out"
echo "Listo: $out"
