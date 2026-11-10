#!/bin/sh
# Uploads a built ISO to Cloudflare R2 with rclone: the ISO, its package list,
# the Debian sources (make iso SOURCES=1) and SHA256SUMS, in iso/<version>/.
# The rclone remote holds the keys (rclone config); nothing secret is here.
# Usage: publish.sh <version> <remote:bucket>
set -eu

version=$1
dest=$2/iso/$version
build=$(dirname "$0")/build
iso=uzunyx-$version-amd64.iso

if [ ! -f "$build/$iso" ]; then
    echo "No está $build/$iso: primero make iso." >&2
    exit 1
fi
cd "$build"

files="$iso uzunyx-$version-packages.txt"
sources=$(ls uzunyx-"$version"-sources.tar.* 2>/dev/null || true)
if [ -z "$sources" ] && [ "${ALLOW_NO_SOURCES:-}" != 1 ]; then
    echo "Faltan las fuentes (make iso SOURCES=1): la GPL pide publicarlas con la ISO." >&2
    echo "Para subirla igual: ALLOW_NO_SOURCES=1." >&2
    exit 1
fi
files="$files $sources"

echo "Calculando SHA256SUMS…"
# shellcheck disable=SC2086
sha256sum $files > "uzunyx-$version-SHA256SUMS"

# The R2 token only reaches this bucket: don't check or create it.
for f in $files "uzunyx-$version-SHA256SUMS"; do
    rclone copyto --progress --s3-no-check-bucket "$f" "$dest/$f"
done
echo "Subida a $dest"
