#!/bin/sh
# Builds Debian's Calamares with our patches (calamares/*.patch: the partition
# legend in the theme's colours, an eye in the password fields), in a
# throwaway system (no root, like the ISO), and leaves the .deb in
# build-calamares/.
set -e
ISO_DIR=$(cd "$(dirname "$0")" && pwd)
out=$ISO_DIR/build-calamares
rm -rf "$out"
mkdir -p "$out"

mmdebstrap --mode=unshare --variant=buildd --architectures=amd64 \
    --include=ca-certificates,devscripts,dpkg-dev \
    --customize-hook='mkdir -p "$1/tmp/in"' \
    --customize-hook="upload $ISO_DIR/calamares/legend-colours.patch /tmp/in/legend-colours.patch" \
    --customize-hook="upload $ISO_DIR/calamares/password-reveal.patch /tmp/in/password-reveal.patch" \
    --customize-hook='chroot "$1" sh -ec "
        apt-get update
        apt-get -y build-dep calamares
        mkdir /tmp/src && cd /tmp/src
        apt-get source calamares
        cd calamares-*/
        mkdir -p debian/patches
        cp /tmp/in/legend-colours.patch debian/patches/uzunyx-legend-colours.patch
        echo uzunyx-legend-colours.patch >> debian/patches/series
        cp /tmp/in/password-reveal.patch debian/patches/uzunyx-password-reveal.patch
        echo uzunyx-password-reveal.patch >> debian/patches/series
        DEBFULLNAME=Uzunyx DEBEMAIL=uzunyx@localhost dch --local +uzunyx --distribution testing \"Partition legend in the palette colours; an eye in the password fields.\"
        DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -uc -us -Pnocheck
        mkdir /tmp/out
        cp ../calamares_*.deb /tmp/out/
    "' \
    --customize-hook="sync-out /tmp/out $out" \
    testing /dev/null \
    "deb http://deb.debian.org/debian testing main" \
    "deb-src http://deb.debian.org/debian testing main"

ls -l "$out"
