#!/bin/sh
# Runs inside the new system, from /tmp/uzunyx-iso (see build-iso.sh): installs
# Uzunyx with the same command a normal Debian would use, then the ISO's own
# pieces. What goes on the ISO itself is left in tree/.
set -e
export DEBIAN_FRONTEND=noninteractive
in=/tmp/uzunyx-iso
tree=$in/tree
mkdir -p "$tree/live" "$tree/boot/grub/themes"

apt-get -y install "$in/uzunyx-installer.deb"
uzunyx-install --yes

apt-get -y --install-recommends install $(grep -v '^#' "$in/packages.list")
# With the partition legend in the theme's colours (build-calamares.sh).
apt-get -y --allow-downgrades install "$in/calamares.deb"

cat > /etc/locale.gen <<LOCALES
es_UY.UTF-8 UTF-8
es_ES.UTF-8 UTF-8
en_US.UTF-8 UTF-8
LOCALES
locale-gen

# Offline repository on the ISO: Calamares installs the bootloader that fits
# the machine from it, so those can't be chosen ahead of time.
pool=/var/cache/uzunyx-iso-pool
mkdir -p "$pool/partial"
for packages in "grub-pc" "grub-efi-amd64 grub-efi-amd64-signed shim-signed" "cryptsetup-initramfs keyutils"; do
    apt-get -y --download-only -o Dir::Cache::archives="$pool" install $packages
done
rm -rf "$pool/partial" "$pool/lock"
mkdir -p "$tree/pool" "$tree/dists/testing/main/binary-amd64"
mv "$pool"/*.deb "$tree/pool/"
rmdir "$pool"
(cd "$tree" && apt-ftparchive packages pool > dists/testing/main/binary-amd64/Packages)

# Calamares from Debian, as Uzunyx.
cal=/etc/calamares
mkdir -p "$cal/branding/uzunyx"
cp "$in/calamares/locale.conf" "$cal/modules/locale.conf"
cp -r "$in/calamares/branding.desc" "$in/calamares/show.qml" "$in/calamares/slides" "$cal/branding/uzunyx/"
cp "$in/logo.png" "$cal/branding/uzunyx/logo.png"
sed -i 's/^branding: .*/branding: uzunyx/' "$cal/settings.conf"
sed -i 's/^\( *\)- .calamares-settings-debian.$/&\n\1- '"'"'calamares'"'"'/' "$cal/modules/packages.conf"
helpers=/usr/share/calamares/helpers
sed -i 's/^RELEASE=.*/RELEASE="testing"/' "$helpers/calamares-sources-media"
cp "$in/calamares/calamares-sources-final" "$helpers/calamares-sources-final"
chmod 755 "$helpers/calamares-sources-final"
# "Aplicaciones" page after Users, and the extended selection downloaded once
# Debian's sources are written (before that apt only sees the ISO).
cp "$in/calamares/uzunyx-apps.qml" "$in/calamares/calamares-sidebar.qml" "$cal/branding/uzunyx/"
cp "$in/calamares/uzunyx-apps.conf" "$in/calamares/uzunyx-install-apps.conf" "$cal/modules/"
install -Dm755 "$in/calamares/uzunyx-install-apps" /usr/libexec/uzunyx-install-apps
sed -i -e '0,/^  - users$/s//  - users\n  - packagechooserq@apps/' \
    -e 's/^  - sources-final$/&\n  - contextualprocess@uzunyx-apps/' "$cal/settings.conf"
cat >> "$cal/settings.conf" <<'EOF'

instances:
- id: apps
  module: packagechooserq
  config: uzunyx-apps.conf
- id: uzunyx-apps
  module: contextualprocess
  config: uzunyx-install-apps.conf
EOF
grep -q '^instances:' "$cal/settings.conf" && [ "$(grep -c '^instances:' "$cal/settings.conf")" = 1 ] ||
    { echo "settings.conf already had instances" >&2; exit 1; }
# Warns on the first page when there is no internet (not required).
sed -i '0,/^        - root$/s//        - root\n        - internet/' "$cal/modules/welcome.conf"
# A swap file by default (Debian's is none): no partition to size, and the
# user can still choose another.
sed -i 's/^initialSwapChoice: .*/initialSwapChoice: file/' "$cal/modules/partition.conf"
grep -q '^initialSwapChoice: file$' "$cal/modules/partition.conf"
sed -e 's/^Name=.*/Name=Instalar Uzunyx/' -e '/^Name\[/d' -e '/^GenericName/d' -e '/^Comment/d' \
    -e 's/^Icon=.*/Icon=uzunyx-akane/' -i "/usr/share/applications/calamares-install-debian.desktop"

# Dark like the rest: pkexec clears the environment, so Calamares runs through
# a script of its own with Akane's colours as its only configuration.
mkdir -p /etc/calamares/theme
{
    cat /usr/share/color-schemes/UzunyxAkane.colors
    printf '\n[General]\nColorScheme=UzunyxAkane\n\n[Icons]\nTheme=uzunyx\n\n[KDE]\nwidgetStyle=Breeze\n'
} > /etc/calamares/theme/kdeglobals
install -Dm755 "$in/calamares/uzunyx-calamares" /usr/libexec/uzunyx-calamares
install -Dm644 "$in/calamares/org.uzunyx.calamares.policy" /usr/share/polkit-1/actions/org.uzunyx.calamares.policy
sed -i 's#^pkexec calamares#pkexec /usr/libexec/uzunyx-calamares#' /usr/bin/calamares-install-debian
# The installer opens by itself in the live session. The installed system is a
# copy of this one, so it checks the kernel's command line.
cat > /etc/xdg/autostart/uzunyx-install.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Instalar Uzunyx
Icon=uzunyx-akane
Exec=sh -c 'grep -qw boot=live /proc/cmdline && exec calamares-install-debian'
OnlyShowIn=KDE;
NoDisplay=true
X-KDE-autostart-phase=2
EOF

# On shutdown, the medium is ejected without waiting for Enter.
install -Dm644 "$in/calamares/live-tools.conf" /etc/live/tools.conf

# What the bootloader on the ISO boots.
cp -L /vmlinuz "$tree/live/vmlinuz"
cp -L /initrd.img "$tree/live/initrd.img"
mkdir -p "$tree/boot/grub/themes"
cp -r /boot/grub/themes/uzunyx "$tree/boot/grub/themes/uzunyx"

# The exact contents, published with the ISO, and optionally Debian's sources.
dpkg-query -W -f '${Package} ${Version} ${source:Package} ${source:Version}\n' > "$tree/packages.txt"
if [ -f "$in/with-sources" ]; then
    cat > /etc/apt/sources.list.d/uzunyx-src.list <<SOURCES
deb-src http://deb.debian.org/debian testing main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security testing-security main contrib non-free non-free-firmware
SOURCES
    apt-get update
    mkdir -p "$in/sources"
    cd "$in/sources"
    # A Debian package rebuilt with a patch (calamares +uzunyx1): Debian's
    # source; the patch is in calamares/ next to it.
    awk '{print $3 "=" $4}' "$tree/packages.txt" | sed 's/+uzunyx[0-9]*$//' | sort -u |
    while read -r source; do
        apt-get --download-only source "$source" || echo "$source" >> missing.txt
    done
    # The rest isn't in Debian: where its code is.
    cat > LEEME.txt <<README
Código fuente de los paquetes de Debian que trae esta ISO (apt-get source).
Los que no son de Debian (missing.txt) tienen el código en:

- uzunyx-*, edge-gaps, recetas de kora-icon-theme y lunyx:
  https://github.com/antarest47/uzunyx
- tsunyx-launcher: https://github.com/antarest47/tsunyx-launcher
- lunyx: https://github.com/antarest47/lunyx
- kora-icon-theme: https://github.com/bikass/kora (commit en kora-icons/Makefile)
- calamares: la fuente de Debian de arriba más legend-colours.patch
README
    cd /
    rm /etc/apt/sources.list.d/uzunyx-src.list
    apt-get update
fi

apt-get clean
