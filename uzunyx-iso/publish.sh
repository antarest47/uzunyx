#!/bin/sh
# Publishes a built ISO: the Debian sources (make iso SOURCES=1), the package
# list and SHA256SUMS go to a GitHub release v<version>, first; then the ISO,
# SHA256SUMS and FUENTES.txt, which points to that release, go to Cloudflare R2
# in iso/<version>/. The keys stay in rclone and gh; nothing secret is here.
# Usage: publish.sh <version> <remote:bucket> <owner/repo>
set -eu

version=$1
dest=$2/iso/$version
repo=$3
tag=v$version
build=$(dirname "$0")/build
iso=uzunyx-$version-amd64.iso
list=uzunyx-$version-packages.txt
sums=uzunyx-$version-SHA256SUMS
release_url=https://github.com/$repo/releases/tag/$tag
iso_url=https://dl.uzunyx.com/iso/$version/$iso

if [ ! -f "$build/$iso" ]; then
    echo "No está $build/$iso: primero make iso SOURCES=1." >&2
    exit 1
fi
cd "$build"
sources=$(ls uzunyx-"$version"-sources.tar.* 2>/dev/null || true)
if [ -z "$sources" ]; then
    echo "Faltan las fuentes (make iso SOURCES=1): la GPL pide publicarlas con la ISO." >&2
    exit 1
fi
command -v gh >/dev/null || { echo "Falta gh: sudo apt install gh, y gh auth login." >&2; exit 1; }

echo "Calculando SHA256SUMS…"
# shellcheck disable=SC2086
sha256sum $iso $list $sources > "$sums"

cat > FUENTES.txt <<EOF
Uzunyx $version

Código fuente de los paquetes de Debian que trae esta ISO (GPL y otras
licencias), con la lista de paquetes y las sumas SHA256:
Source code of the Debian packages in this ISO, with the package list and
SHA256 sums:

  $release_url

Para unir las partes / to join the parts:
  cat uzunyx-$version-sources.tar.* | tar -x

El código de Uzunyx / Uzunyx's own code: https://github.com/$repo
EOF

# Sources first: the ISO never goes up without them.
if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    echo "La release $tag ya existe: se reemplazan sus archivos."
else
    gh release create "$tag" --repo "$repo" --target main --title "Uzunyx $version" \
        --notes "ISO: $iso_url

SHA256SUMS: https://dl.uzunyx.com/iso/$version/$sums

Esta release trae el código fuente de los paquetes de Debian incluidos en la ISO,
en partes de 1,9 GB. Para unirlas: \`cat uzunyx-$version-sources.tar.* | tar -x\`"
fi
# shellcheck disable=SC2086
gh release upload "$tag" --repo "$repo" --clobber $list $sums $sources

# The R2 token only reaches this bucket: don't check or create it.
for f in "$sums" FUENTES.txt "$iso"; do
    rclone copyto --progress --s3-no-check-bucket "$f" "$dest/$f"
done
echo "Fuentes: $release_url"
echo "ISO: $iso_url"
