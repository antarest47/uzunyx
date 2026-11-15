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
# the machine from it, so those can't be chosen ahead of time. Its helper
# (calamares-bootloader-config) asks for the grub-efi metapackage: without it
# here, a UEFI install without internet had no GRUB modules and grub-install
# failed at the end (0.2.1 and 0.2.2).
pool=/var/cache/uzunyx-iso-pool
mkdir -p "$pool/partial"
for packages in "grub-pc" "grub-efi grub-efi-amd64 grub-efi-amd64-signed shim-signed" "cryptsetup-initramfs keyutils"; do
    apt-get -y --download-only -o Dir::Cache::archives="$pool" install $packages
done
rm -rf "$pool/partial" "$pool/lock"
mkdir -p "$tree/pool" "$tree/dists/testing/main/binary-amd64"
mv "$pool"/*.deb "$tree/pool/"
rmdir "$pool"
ls "$tree"/pool/grub-efi_*.deb "$tree"/pool/grub-pc_*.deb >/dev/null
(cd "$tree" && apt-ftparchive packages pool > dists/testing/main/binary-amd64/Packages)

# Calamares from Debian, as Uzunyx.
cal=/etc/calamares
mkdir -p "$cal/branding/uzunyx"
cp "$in/calamares/locale.conf" "$cal/modules/locale.conf"
cp "$in/calamares/keyboard.conf" "$cal/modules/keyboard.conf"
cp -r "$in/calamares/branding.desc" "$in/calamares/show.qml" "$in/calamares/slides" "$cal/branding/uzunyx/"
cp "$in/logo.png" "$cal/branding/uzunyx/logo.png"
sed -i 's/^branding: .*/branding: uzunyx/' "$cal/settings.conf"
# The installed system leaves out Calamares and uzunyx-installer (its local
# repository is the live session's; the system updates from dl.uzunyx.com).
sed -i 's/^\( *\)- .calamares-settings-debian.$/&\n\1- '"'"'calamares'"'"'\n\1- '"'"'uzunyx-installer'"'"'/' "$cal/modules/packages.conf"
grep -q "^ *- 'uzunyx-installer'$" "$cal/modules/packages.conf"
# Nor the live-task-* that Debian's list removes: they aren't on this ISO, and
# without internet apt doesn't know them and the whole removal failed (100).
sed -i "/^ *- 'live-task-/d" "$cal/modules/packages.conf"
! grep -q "live-task-" "$cal/modules/packages.conf"
helpers=/usr/share/calamares/helpers
sed -i 's/^RELEASE=.*/RELEASE="testing"/' "$helpers/calamares-sources-media"
# The installed system is copied from the squashfs, whose resolv.conf is not the
# live session's: without this, apt in it had no DNS even with internet, and
# grub-efi and the removal of the live packages failed (0.2.1, 0.2.2). The
# squashfs had the build machine's (build-iso.sh now empties it). NetworkManager
# rewrites it on the installed system.
sed -i 's#^rm -f \$CHROOT/etc/apt/sources.list.d/base.list$#&\ncp -L /etc/resolv.conf $CHROOT/etc/resolv.conf || true#' "$helpers/calamares-sources-media"
grep -q '^cp -L /etc/resolv.conf' "$helpers/calamares-sources-media"
cp "$in/calamares/calamares-sources-final" "$helpers/calamares-sources-final"
chmod 755 "$helpers/calamares-sources-final"
# "Aplicaciones" page after Users, and the extended selection downloaded once
# Debian's sources are written (before that apt only sees the ISO).
# "Conexión" page after the welcome: Calamares only checks for internet, it
# doesn't connect. networkcfg copies the connection to the installed system.
cp "$in/calamares/uzunyx-apps.qml" "$in/calamares/uzunyx-network.qml" "$in/calamares/calamares-sidebar.qml" "$cal/branding/uzunyx/"
cp "$in/calamares/uzunyx-apps.conf" "$in/calamares/uzunyx-network.conf" "$cal/modules/"
install -Dm755 "$in/calamares/uzunyx-install-apps" /usr/libexec/uzunyx-install-apps
# A Python job and not contextualprocess: it shows apt's progress (0.2.2 sat
# at 94 % without a word while downloading) and has no time limit.
install -Dm644 -t /usr/lib/calamares/modules/uzunyxapps "$in/calamares/uzunyxapps/module.desc" "$in/calamares/uzunyxapps/main.py"
install -Dm755 "$in/calamares/uzunyx-calamares-network" /usr/libexec/uzunyx-calamares-network
# "Teclado" right after the welcome too, as Ubuntu: it changes the layout as it
# is chosen, so the Wi-Fi, user and encryption passwords are typed with it.
# Only the first "keyboard" (the page; the second one is the job) moves.
sed -i -e '0,/^  - keyboard$/{/^  - keyboard$/d}' "$cal/settings.conf"
sed -i -e '0,/^  - welcome$/s//  - welcome\n  - keyboard\n  - notesqml@network/' \
    -e '0,/^  - users$/s//  - users\n  - packagechooserq@apps/' \
    -e 's/^  - sources-final$/&\n  - uzunyxapps/' "$cal/settings.conf"
grep -q '^  - notesqml@network$' "$cal/settings.conf"
grep -q '^  - uzunyxapps$' "$cal/settings.conf"
[ "$(grep -c "^  - keyboard$" "$cal/settings.conf")" = 2 ]
cat >> "$cal/settings.conf" <<'EOF'

instances:
- id: network
  module: notesqml
  config: uzunyx-network.conf
- id: apps
  module: packagechooserq
  config: uzunyx-apps.conf
EOF
grep -q '^instances:' "$cal/settings.conf" && [ "$(grep -c '^instances:' "$cal/settings.conf")" = 1 ] ||
    { echo "settings.conf already had instances" >&2; exit 1; }
# A swap file by default (Debian's is none): no partition to size, and the
# user can still choose another.
sed -i 's/^initialSwapChoice: .*/initialSwapChoice: file/' "$cal/modules/partition.conf"
grep -q '^initialSwapChoice: file$' "$cal/modules/partition.conf"
# /boot apart and never encrypted, as Ubuntu: with it inside the encrypted
# system, GRUB asked for the password in text over the firmware's logo and
# rejected it (Argon2 of LUKS2, 0.2.2 on a laptop). This way the system asks in
# the initramfs, on the Plymouth screen, and Calamares leaves out the keyfile
# and GRUB_ENABLE_CRYPTODISK by itself. "unknown" is the filesystem the user
# picks.
! grep -q '^partitionLayout:' "$cal/modules/partition.conf"
cat >> "$cal/modules/partition.conf" <<'EOF'

partitionLayout:
    - name: "boot"
      filesystem: "ext4"
      noEncrypt: true
      mountPoint: "/boot"
      size: 1G
    - name: "root"
      filesystem: "unknown"
      mountPoint: "/"
      size: 100%
EOF
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

# The live session turns the screen off but doesn't lock it: not everyone knows
# the password ("live"). Also a copy in the installed system, which checks the
# kernel's command line like the autostart above.
mkdir -p /etc/xdg/plasma-workspace/env
cat > /etc/xdg/plasma-workspace/env/uzunyx-live.sh <<'EOF'
if grep -qw boot=live /proc/cmdline; then
    kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
    kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume false
fi
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
    # source; the patch is in calamares/ next to it. Those already in the
    # cache (cached.txt, sources-cache.sh) aren't downloaded again; needed.txt
    # says which ones the ISO takes from there.
    awk '{print $3 "=" $4}' "$tree/packages.txt" | sed 's/+uzunyx[0-9]*$//' | sort -u |
    while read -r source; do
        version=${source#*=}
        dsc=${source%%=*}_${version#*:}.dsc
        echo "$dsc" >> needed.txt
        grep -qxF "$dsc" "$in/cached.txt" && continue
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
