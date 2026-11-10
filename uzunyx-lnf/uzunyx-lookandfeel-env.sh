# Sourced by startplasma (plasma-workspace/env) before it sets up the global
# theme. Plasma only rewrites ~/.config/kdedefaults when the global theme's
# *name* changes, so users would never get the new defaults of an updated
# Uzunyx package. When the installed version differs from the one last
# seen, forget the applied theme so startplasma writes the defaults again.
# Both editions (org.uzunyx.desktop = Akane, org.uzunyx.sora) share the
# package version.
# Must print nothing: startplasma reads this script's output as environment.

_uzunyx_config="${XDG_CONFIG_HOME:-$HOME/.config}"
_uzunyx_version=$(sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' \
    /usr/share/plasma/look-and-feel/org.uzunyx.desktop/metadata.json 2>/dev/null)
_uzunyx_seen="$_uzunyx_config/uzunyx/lookandfeel-version"

if [ -n "$_uzunyx_version" ] && [ "$(cat "$_uzunyx_seen" 2>/dev/null)" != "$_uzunyx_version" ]; then
    case "$(cat "$_uzunyx_config/kdedefaults/package" 2>/dev/null)" in
        org.uzunyx.desktop|org.uzunyx.sora) rm -f "$_uzunyx_config/kdedefaults/package" ;;
    esac
    mkdir -p "$_uzunyx_config/uzunyx" && printf '%s\n' "$_uzunyx_version" > "$_uzunyx_seen"
fi

unset _uzunyx_config _uzunyx_version _uzunyx_seen
