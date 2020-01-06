#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

rm -rf --one-file-system "$ROOT"/debinst
rm -f "$ROOT"/rootfs.squashfs
mkdir -p "$ROOT"/debinst

# install a minimal OS
debootstrap --arch amd64 buster "$ROOT"/debinst http://ftp.us.debian.org/debian

# apply overrides
chown -R root:root rootfs_overrides
cp -rv rootfs_overrides/* "$ROOT"/debinst/

function cr() {
	chroot "$ROOT"/debinst "$@"
}

# fix things
cr passwd -d root
cr apt-get update -y

# packages
cr apt-get install -y ca-certificates
cr apt-get install -y acpi acpi-support acpid cpufrequtils

cr sh -c "dpkg --get-selections | grep -v deinstall" > "$ROOT"/packages.txt

# remove apt cache
cr apt-get clean -y
cr apt-get autoremove -y
rm -rf "$ROOT"/debinst/var/lib/apt/lists/*

# pack rootfs
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz -noappend
ls -alh "$ROOT"/rootfs.squashfs
