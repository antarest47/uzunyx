#!/bin/sh
# Builds the ISO: the system as a tarball with mmdebstrap (no root, in a user
# namespace), to squashfs with sqfstar so owners survive, then GRUB and xorriso.
set -e
version=$1
ISO_DIR=$(cd "$(dirname "$0")" && pwd)
build=$ISO_DIR/build
ISO_TREE=$build/tree
INSTALLER_DEB=$(ls -v "$ISO_DIR"/../uzunyx-installer/build/uzunyx-installer_*_all.deb | tail -1)

rm -rf "$build"
# The namespace's root is a subordinate uid that can't read the home folder:
# everything goes in and out through mmdebstrap's sync-in and sync-out.
in=$build/in
mkdir -p "$in"
cp "$INSTALLER_DEB" "$in/uzunyx-installer.deb"
cp "$(ls -v "$ISO_DIR"/build-calamares/calamares_*_amd64.deb | tail -1)" "$in/calamares.deb"
cp -r "$ISO_DIR/customize-hook.sh" "$ISO_DIR/packages.list" "$ISO_DIR/calamares" "$in/"
cp "$ISO_DIR/../icons/uzunyx-icon-akane.png" "$in/logo.png"
# Calamares' welcome picture and slideshow (calamares/show.qml).
slides=$in/calamares/slides
cp "$ISO_DIR/../wallpapers/wallpaper-uzunyx-akane-lll.jpeg" "$slides/akane.jpeg"
cp "$ISO_DIR/../wallpapers/wallpaper-uzunyx-sora-lll.jpeg" "$slides/sora.jpeg"
cp "$ISO_DIR/../uzunyx-welcome/art/akane-sora.png" "$ISO_DIR/../uzunyx-welcome/control-center.png" "$slides/"
mkdir -p "$ISO_TREE"
# SOURCES=1: also the sources of Debian's packages, for publishing the ISO.
sources_out=true
if [ "$SOURCES" = 1 ]; then
    touch "$in/with-sources"
    sources_out="sync-out /tmp/uzunyx-iso/sources $build/sources"
fi

# With Recommends, as a normal Debian: mmdebstrap leaves them out by default
# (the ISO lacked xdg-user-dirs, Plasma's addons…). The heaviest are kept out
# while building only (iso-excludes.pref).
mmdebstrap --mode=unshare --variant=important --architectures=amd64 \
    --components="main contrib non-free non-free-firmware" \
    --include=apt-utils,ca-certificates,dbus,systemd-sysv \
    --aptopt='Apt::Install-Recommends "true"' \
    --setup-hook='mkdir -p "$1/etc/apt/preferences.d"' \
    --setup-hook="upload $ISO_DIR/iso-excludes.pref /etc/apt/preferences.d/uzunyx-iso" \
    --customize-hook='mkdir "$1/tmp/uzunyx-iso"' \
    --customize-hook="sync-in $in /tmp/uzunyx-iso" \
    --customize-hook='chroot "$1" sh /tmp/uzunyx-iso/customize-hook.sh' \
    --customize-hook="sync-out /tmp/uzunyx-iso/tree $ISO_TREE" \
    --customize-hook="$sources_out" \
    --customize-hook='rm -rf "$1/tmp/uzunyx-iso" "$1/etc/apt/preferences.d/uzunyx-iso"' \
    forky "$build/rootfs.tar" \
    "deb http://deb.debian.org/debian forky main contrib non-free non-free-firmware" \
    "deb http://deb.debian.org/debian forky-updates main contrib non-free non-free-firmware" \
    "deb http://deb.debian.org/debian-security forky-security main contrib non-free non-free-firmware"

sqfstar -comp zstd -Xcompression-level 15 "$ISO_TREE/live/filesystem.squashfs" < "$build/rootfs.tar"
rm "$build/rootfs.tar"

cp "$ISO_DIR/grub.cfg" "$ISO_TREE/boot/grub/grub.cfg"
grub-mkrescue -o "$build/uzunyx-$version-amd64.iso" "$ISO_TREE" -- -volid UZUNYX
cp "$ISO_TREE/packages.txt" "$build/uzunyx-$version-packages.txt"
ls -l "$build/uzunyx-$version-amd64.iso"
if [ "$SOURCES" = 1 ]; then
    # GitHub takes files up to 2 GiB. The patch is Calamares' only change.
    cp "$ISO_DIR/calamares/legend-colours.patch" "$build/sources/"
    tar -C "$build" -cf - sources | split -b 1900M -d - "$build/uzunyx-$version-sources.tar."
    rm -rf "$build/sources"
    ls -l "$build"/uzunyx-"$version"-sources.tar.*
fi
