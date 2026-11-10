#!/bin/sh
# Builds Debian's Calamares with calamares/legend-colours.patch, in a throwaway
# system (no root, like the ISO), and leaves the .deb in build-calamares/.
set -e
ISO_DIR=$(cd "$(dirname "$0")" && pwd)
out=$ISO_DIR/build-calamares
rm -rf "$out"
mkdir -p "$out"

mmdebstrap --mode=unshare --variant=buildd --architectures=amd64 \
    --include=ca-certificates,devscripts,dpkg-dev \
    --customize-hook='mkdir -p "$1/tmp/in"' \
    --customize-hook="upload $ISO_DIR/calamares/legend-colours.patch /tmp/in/legend-colours.patch" \
    --customize-hook='chroot "$1" sh -ec "
        apt-get update
        apt-get -y build-dep calamares
        mkdir /tmp/src && cd /tmp/src
        apt-get source calamares
        cd calamares-*/
        mkdir -p debian/patches
        cp /tmp/in/legend-colours.patch debian/patches/uzunyx-legend-colours.patch
        echo uzunyx-legend-colours.patch >> debian/patches/series
        DEBFULLNAME=Uzunyx DEBEMAIL=uzunyx@localhost dch --local +uzunyx --distribution forky \"Partition legend in the palette colours.\"
        DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -uc -us -Pnocheck
        mkdir /tmp/out
        cp ../calamares_*.deb /tmp/out/
    "' \
    --customize-hook="sync-out /tmp/out $out" \
    forky /dev/null \
    "deb http://deb.debian.org/debian forky main" \
    "deb-src http://deb.debian.org/debian forky main"

ls -l "$out"
