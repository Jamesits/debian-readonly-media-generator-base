#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
IMAGE=debian.img

rm -f "$ROOT/$IMAGE"
fallocate -l 1G "$ROOT/$IMAGE"

losetup /dev/loop0 "$ROOT/$IMAGE"
udevadm settle
sleep 1

sgdisk --zap-all /dev/loop0
sgdisk --clear --mbrtogpt /dev/loop0
# 1M
sgdisk --new 1:2048:4095 --change-name 1:"GRUB" --typecode 1:ef02 /dev/loop0
# 512M
sgdisk --new 2:4096:1050623 --change-name 2:"EFI" --typecode 2:ef00 --attributes "2:set:2" /dev/loop0
sgdisk --print /dev/loop0
partprobe /dev/loop0
sleep 1

mkdir -p "$ROOT"/bootpart
mkfs.fat -F 32 -h 4096 -n "EFI" /dev/loop0p2
mount -t vfat /dev/loop0p2 "$ROOT"/bootpart

# install kernel & initramfs
mkdir -p "$ROOT"/bootpart/boot
cp "$ROOT"/boot/* "$ROOT"/bootpart/boot

# install rootfs
mkdir -p "$ROOT"/bootpart/live
cp "$ROOT"/rootfs.squashfs "$ROOT"/bootpart/live/rootfs.squashfs

# install grub
grub-install /dev/loop0 --skip-fs-probe --boot-directory="$ROOT"/bootpart/boot

cat > "$ROOT"/bootpart/boot/grub/grub.cfg <<EOF
menuentry "Debian" {
    # load_video
    insmod gzio
    insmod part_msdos
    set root=(hd0,2)
    set gfxpayload=keep
    echo 'Loading Linux...'
    linux /boot/vmlinuz-4.19.0-6-amd64 noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off boot=live console=ttyS0
    echo 'Loading initramfs...'
    initrd /boot/initrd.img-4.19.0-6-amd64
    boot
}
EOF

umount "$ROOT"/bootpart
losetup -d /dev/loop0

ls -alh "$ROOT"/"$IMAGE"
