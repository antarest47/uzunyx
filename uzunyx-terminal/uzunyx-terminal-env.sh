# Sourced by startplasma (plasma-workspace/env) before plasmashell starts.
# Turns on "Open Terminal" in the desktop's right-click menu, once per user:
# it belongs to Plasma's context menu plugin (org.kde.contextmenu), off by
# default, and Plasma reads its applets file without /etc/xdg, so it can only
# be set in the user's own. A user who turns it off again keeps it off.
# Must print nothing: startplasma reads this script's output as environment.

_uzunyx_config="${XDG_CONFIG_HOME:-$HOME/.config}"
_uzunyx_mark="$_uzunyx_config/uzunyx/desktop-terminal-set"
_uzunyx_file=plasma-org.kde.plasma.desktop-appletsrc

if [ ! -e "$_uzunyx_mark" ] && command -v kwriteconfig6 >/dev/null 2>&1; then
    # A new user has no file yet: Plasma's own mouse actions go in too, or the
    # desktop would be left with only this one.
    if ! grep -q '^\[ActionPlugins\]\[0\]$' "$_uzunyx_config/$_uzunyx_file" 2>/dev/null; then
        kwriteconfig6 --file "$_uzunyx_file" --group ActionPlugins --group 0 --key "MiddleButton;NoModifier" org.kde.paste
        kwriteconfig6 --file "$_uzunyx_file" --group ActionPlugins --group 0 --key "RightButton;NoModifier" org.kde.contextmenu
        kwriteconfig6 --file "$_uzunyx_file" --group ActionPlugins --group 1 --key "RightButton;NoModifier" org.kde.contextmenu
    fi
    kwriteconfig6 --file "$_uzunyx_file" --group ActionPlugins --group 0 --group "RightButton;NoModifier" --key _open_terminal true
    mkdir -p "$_uzunyx_config/uzunyx" && : > "$_uzunyx_mark"
fi

unset _uzunyx_config _uzunyx_mark _uzunyx_file
