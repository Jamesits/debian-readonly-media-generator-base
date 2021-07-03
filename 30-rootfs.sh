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

# kernel modules (srext)
cr apt-get install -y build-essential git
cr sh -c "cd /tmp; git clone https://github.com/netgroup/SRv6-net-prog.git; cd SRv6-net-prog/srext; make; make install; cd /tmp; rm -rf SRv6-net-prog"

# install kernel modules but remove the kernel
cr apt-get install -y --no-install-recommends linux-image-amd64
rm -rf "$ROOT"/debinst/boot/* "$ROOT"/debinst/vmlinuz{,.old} "$ROOT"/debinst/initrd.img{,.old}

# generate a list of packages
cr sh -c "dpkg --get-selections | grep -v deinstall" > "$ROOT"/packages.txt

# remove apt cache
cr apt-get clean -y
cr apt-get autoremove -y
rm -rf "$ROOT"/debinst/var/lib/apt/lists/*

# remove machind id to make sure a different one is generated for every instance
# note: this will trigger systemd's unpopulated /etc code which resets the enable/disable status of all units
# so if you want to manually enable/disable a unit, you must use systemd.preset
# See:
# https://www.humblec.com/running_with_unpopulated_etc/
# http://0pointer.net/blog/projects/stateless.html
rm -f "$ROOT"/debinst/etc/machine-id

# pack rootfs
mksquashfs "$ROOT"/debinst "$ROOT"/rootfs.squashfs -comp xz -noappend
ls -alh "$ROOT"/rootfs.squashfs
