#!/bin/sh
# Boots the ISO in QEMU: test-vm.sh [uefi|bios] [--fresh|--installed] [extra QEMU args]
#   (nothing)    the newest ISO, with the VM's disk as it is (empty the first time)
#   --fresh      the ISO with the disk wiped first, to test an install from scratch
#   --installed  the installed system on the disk, without the ISO
#   --delete     deletes the VM's disk and exits
# The disk is build/disk.qcow2 (40 GB at most, it grows as it is used), with
# build/uefi-vars.fd, where UEFI keeps the boot entry the installer writes (or
# the installed system wouldn't boot in a later run); make iso deletes both
# with the rest of build/.
firmware=uefi
case "$1" in uefi|bios) firmware=$1; shift ;; esac
mode=iso
case "$1" in --fresh|--installed|--delete) mode=${1#--}; shift ;; esac
dir=$(cd "$(dirname "$0")" && pwd)/build
disk=$dir/disk.qcow2
vars=$dir/uefi-vars.fd

if [ "$mode" = delete ] || [ "$mode" = fresh ]; then
    rm -f "$disk" "$vars"
    [ "$mode" = delete ] && { echo "Disco de la VM borrado."; exit 0; }
fi
if [ "$mode" = installed ]; then
    [ -e "$disk" ] || { echo "No hay nada instalado: primero instala desde la ISO." >&2; exit 1; }
    media=
else
    iso=$(ls -v "$dir"/uzunyx-*.iso 2>/dev/null | tail -1)
    [ -n "$iso" ] || { echo "No hay ISO: arma una con make iso." >&2; exit 1; }
    media="-cdrom $iso -boot once=d"
fi
[ -e "$disk" ] || qemu-img create -f qcow2 "$disk" 40G
bios=
if [ "$firmware" = uefi ]; then
    [ -e "$vars" ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$vars"
    bios="-machine q35 -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
          -drive if=pflash,format=raw,file=$vars"
fi
exec qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 6G -vga virtio $bios \
    -drive file="$disk",if=virtio $media -nic user,model=virtio "$@"
