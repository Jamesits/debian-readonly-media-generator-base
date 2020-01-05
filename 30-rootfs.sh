#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
mkdir -p "$ROOT"/debinst
debootstrap --arch amd64 stretch "$ROOT"/debinst http://ftp.us.debian.org/debian
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz
ls -alh "$ROOT"/rootfs.squashfs
