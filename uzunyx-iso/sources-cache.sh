#!/bin/sh
# Keeps Debian's sources between builds (make iso SOURCES=1), so each build
# only downloads those whose version changed: all of them took 2 hours.
#   sources-cache.sh list CACHE OUT      .dsc names in the cache, for the hook
#   sources-cache.sh merge CACHE SOURCES the build's new sources into the cache
#                                        and the cached ones it needs into SOURCES;
#                                        then drops what no longer is on the ISO
set -e
cmd=$1
cache=$2
mkdir -p "$cache"

# Same disk as the build: links, not copies.
put() { cp -l "$1" "$2" 2>/dev/null || cp "$1" "$2"; }

# The files a .dsc names (its Files: block), and the .dsc itself.
dsc_files() {
    echo "$1"
    awk '/^Files:/ { f = 1; next } /^[^ ]/ { f = 0 } f && NF == 3 { print $3 }' "$cache/$1"
}

case "$cmd" in
list)
    (cd "$cache" && ls -- *.dsc 2>/dev/null || true) > "$3"
    ;;
merge)
    sources=$3
    needed=$sources/needed.txt
    [ -f "$needed" ] || { echo "Falta $needed" >&2; exit 1; }
    for f in "$sources"/*; do
        case "${f##*/}" in needed.txt|missing.txt|LEEME.txt) continue ;; esac
        [ -e "$cache/${f##*/}" ] || put "$f" "$cache/"
    done
    keep=$(mktemp)
    while read -r dsc; do
        [ -f "$cache/$dsc" ] || continue
        dsc_files "$dsc" | while read -r f; do
            echo "$f" >> "$keep"
            [ -e "$sources/$f" ] || put "$cache/$f" "$sources/"
        done
    done < "$needed"
    # Every source the ISO needs is there, or in missing.txt (not Debian's).
    lost=$(while read -r dsc; do
        [ -f "$sources/$dsc" ] && continue
        name=${dsc%%_*}
        grep -q "^$name=" "$sources/missing.txt" 2>/dev/null || echo "$dsc"
    done < "$needed")
    [ -z "$lost" ] || { echo "Faltan fuentes: $lost" >&2; exit 1; }
    (cd "$cache" && ls) | sort > "$keep.all"
    sort -u "$keep" | comm -23 "$keep.all" - | while read -r f; do rm -f "$cache/$f"; done
    rm -f "$keep" "$keep.all" "$needed"
    echo "Caché de fuentes: $(ls "$cache" | grep -c '\.dsc$') paquetes, $(du -sh "$cache" | cut -f1)."
    ;;
*)
    echo "Uso: $0 list|merge CACHE …" >&2
    exit 1
    ;;
esac
