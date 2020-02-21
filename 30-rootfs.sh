#!/bin/bash
set -Eeuo pipefail
set -x

source ./config.sh

function cr() {
	chroot "$ROOT"/debinst "$@"
}

rm -rf --one-file-system "$ROOT"/debinst
rm -f "$ROOT"/rootfs.squashfs
mkdir -p "$ROOT"/debinst

# install a minimal OS
debootstrap --arch amd64 buster "$ROOT"/debinst http://ftp.us.debian.org/debian
# install ca-certificates ASAP because as long as you have HTTPS transport in apt config overrides, the following apt-get update is going to fail
cr apt-get install -y --no-install-recommends ca-certificates apt-transport-https

# apply overrides
chown -R root:root rootfs_overrides
cp -rv rootfs_overrides/* "$ROOT"/debinst/

# fix things
cr passwd -d root
cr apt-get update -y

# packages
cr apt-get install -y --no-install-recommends acpi acpi-support-base acpi-fakekey cpufrequtils
cr systemctl enable acpid
cr apt-get install -y --no-install-recommends $ADD_PACKAGES

# FRRouting
cr sed -ie "s/=no/=yes/g" /etc/frr/daemons

# install kernel modules but remove the kernel
cr apt-get install -y --no-install-recommends linux-image-amd64
rm -rf "$ROOT"/debinst/boot/* "$ROOT"/debinst/vmlinuz{,.old} "$ROOT"/debinst/initrd.img{,.old}

# generate a list of packages
cr sh -c "dpkg --get-selections | grep -v deinstall" > "$ROOT"/packages.txt

# remove apt cache
cr apt-get clean -y
cr apt-get autoremove -y
rm -rf "$ROOT"/debinst/var/lib/apt/lists/*

# pack rootfs
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz -noappend
ls -alh "$ROOT"/rootfs.squashfs
