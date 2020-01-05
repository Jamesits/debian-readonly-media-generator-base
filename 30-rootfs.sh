#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
export LANG=C.UTF-8
rm -rf --one-file-system "$ROOT"/debinst
rm -f "$ROOT"/rootfs.squashfs
mkdir -p "$ROOT"/debinst

# install a minimal OS
debootstrap --arch amd64 buster "$ROOT"/debinst http://ftp.us.debian.org/debian

# apply overrides
chown -R root:root rootfs_overrides
cp -rv rootfs_overrides/* "$ROOT"/debinst/

# fix things
chroot "$ROOT"/debinst passwd -d root
chroot "$ROOT"/debinst apt-get update -y
chroot "$ROOT"/debinst apt-get install -y acpid

# remove apt cache
chroot "$ROOT"/debinst apt-get clean -y
chroot "$ROOT"/debinst apt-get autoremove -y
rm -rf "$ROOT"/debinst/var/lib/apt/lists/*

# pack rootfs
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz -noappend
ls -alh "$ROOT"/rootfs.squashfs
