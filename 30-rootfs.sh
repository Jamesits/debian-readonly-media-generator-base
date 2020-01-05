#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
mkdir "$ROOT"/debinst
debootstrap --arch amd64 stretch "$ROOT"/debinst http://ftp.us.debian.org/debian
mksquashfs -comp xz "$ROOT"/debinst "$ROOT"/rootfs.squashfs
ls -alh "$ROOT"/rootfs.squashfs
