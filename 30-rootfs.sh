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
cr apt-get install -y --no-install-recommends $APT_OPTIONS acpi acpi-support-base acpi-fakekey cpufrequtils
cr apt-get install -y $APT_OPTIONS $ADD_PACKAGES
cr apt-get install -y $APT_OPTIONS -t unstable $ADD_PACKAGES_UNSTABLE

for item in "${SYSTEMD_ENABLE_UNITS[@]}"; do
	cr systemctl enable "$item"
done

for item in "${SYSTEMD_DISABLE_UNITS[@]}"; do
	cr systemctl disable "$item"
done

# FRRouting
cr sed -i "s/=no/=yes/g" /etc/frr/daemons

# install kernel modules but remove the kernel
cr apt-get install -y --no-install-recommends linux-image-amd64
rm -rf "$ROOT"/debinst/boot/* "$ROOT"/debinst/vmlinuz{,.old} "$ROOT"/debinst/initrd.img{,.old}

# generate a list of packages
cr sh -c "dpkg --get-selections | grep -v deinstall" > "$ROOT"/packages.txt

# remove apt cache
cr apt-get clean -y
cr apt-get autoremove -y
rm -rf "$ROOT"/debinst/var/lib/apt/lists/*

# remove uuid
rm -f "$ROOT"/debinst/etc/machine-id

# pack rootfs
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz -noappend
ls -alh "$ROOT"/rootfs.squashfs
