#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
IMAGE=debian.img
KERNEL_ARGS_FAST="noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
KERNEL_ARGS_LIVE="boot=live"
KERNEL_ARGS_MISC="console=ttyS0 console=tty1"
GRUB_MODULES="nativedisk biosdisk disk part_msdos part_gpt fat file ehci uhci usb linux normal configfile test search search_fs_uuid search_fs_file true iso9660 search_label gfxterm gfxmenu gfxterm_menu cat echo ls memdisk tar ata pata scsi serial ahci acpi all_video lspci lvm pci reboot video"

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
cp -v "$ROOT"/boot/{vmlinuz,initrd.img}* "$ROOT"/bootpart/boot

# install rootfs
mkdir -p "$ROOT"/bootpart/live
cp "$ROOT"/rootfs.squashfs "$ROOT"/bootpart/live/rootfs.squashfs

# install GRUB2 CSM
# The plain old method that is device-specific doesn't work on every device:
#grub-install --force --skip-fs-probe --target=i386-pc --boot-directory="$ROOT"/bootpart/boot /dev/loop0
# Override core.img to insert gpt modules:
# http://www.dolda2000.com/~fredrik/doc/grub2
cp -r /usr/lib/grub "$ROOT"/grub
grub-mkimage -O i386-pc -o "$ROOT"/grub/i386-pc/core.img -c grub/earlyconfig.cfg $GRUB_MODULES
# we cannot install grub-pc on Ubuntu 16.04 because of a dependency hell so a symlink is missing
# we have to use the original absolute path
/usr/lib/grub/i386-pc/grub-bios-setup --force --skip-fs-probe --directory="$ROOT"/grub/i386-pc /dev/loop0

# install GRUB2 UEFI
grub-install --force --skip-fs-probe --target=x86_64-efi --boot-directory="$ROOT"/bootpart/boot --efi-directory="$ROOT"/bootpart --bootloader-id=GRUB --uefi-secure-boot --removable --no-nvram

# populate GRUB2 config
KERNEL_FILENAME=$(basename `ls "$ROOT"/boot/vmlinuz-* | head -n 1 `)
INITRD_FILENAME=$(basename `ls "$ROOT"/boot/initrd.img* | head -n 1 `)
echo "kernel: $KERNEL_FILENAME"
echo "initrd: $INITRD_FILENAME"
cat > "$ROOT"/bootpart/boot/grub/grub.cfg <<EOF
default=0
timeout=3
serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1
terminal_input console serial
terminal_output console serial
fallback="1"

insmod part_gpt
insmod part_msdos

menuentry "Debian" {
    insmod gzio
    
    search --no-floppy --file --set=root /boot/grub/grub.cfg
    set gfxpayload=keep
    
    echo 'Loading Linux...'
    linux /boot/$KERNEL_FILENAME $KERNEL_ARGS_FAST $KERNEL_ARGS_LIVE $KERNEL_ARGS_MISC
    echo 'Loading initramfs...'
    initrd /boot/$INITRD_FILENAME
    
    boot
}

submenu 'Advanced boot' --unrestricted {
    menuentry 'Boot from next partition' {
        chainloader +1
    }

    menuentry 'UEFI firmware setup' {
        fwsetup
    }

    menuentry 'Reboot' {
        reboot
    }

    menuentry 'Poweroff' {
        halt
    }
}
EOF

cp grub/earlyconfig.cfg "$ROOT"/bootpart/EFI/BOOT/grub.cfg

umount "$ROOT"/bootpart
losetup -d /dev/loop0

ls -alh "$ROOT"/"$IMAGE"
