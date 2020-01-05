#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
IMAGE=debian.img

mkdir -p "$ROOT"

# apt-get install -y qemu-utils grub2-common dosfstools gdisk wget tar

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
mkdir -p "$ROOT"/bootpart/boot

grub-install /dev/loop0 --skip-fs-probe --boot-directory="$ROOT"/bootpart/boot

# get a rootfs from web
ROOTFS_TIME=$(wget -qO- --show-progress "https://images.linuxcontainers.org/images/debian/buster/amd64/default/?C=M;O=D" | grep -oP '(\d{8}_\d{2}:\d{2})' | head -n 1)
ROOTFS="https://images.linuxcontainers.org/images/debian/buster/amd64/default/${ROOTFS_TIME}/rootfs.squashfs"
mkdir -p "$ROOT"/bootpart/live
wget -O "$ROOT"/bootpart/live/rootfs.squashfs "$ROOTFS"

# build a rootfs


docker run --rm -it -v $(pwd):/mnt/builder -v $(realpath "$ROOT")/bootpart/boot:/mnt/build debian:buster-slim /mnt/builder/stage1.sh

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
tar -cvzf "$ROOT/$IMAGE".tar.gz "$ROOT/$IMAGE"
