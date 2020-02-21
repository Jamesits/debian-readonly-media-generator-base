#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
IMAGE=debian.img
KERNEL_ARGS_FAST="noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
KERNEL_ARGS_LIVE="boot=live forcefsck ignore_uuid live-media-path=/system nopersistence swap=true noeject" 
KERNEL_ARGS_MISC="console=ttyS0,9600 console=tty1 lockdown"
KERNEL_ARGS_NORM="panic=5"
GRUB_MODULES="nativedisk biosdisk pci ata pata scsi ahci usb ehci uhci usbms disk part_gpt fat file configfile search search_fs_file echo ls reboot usb_keyboard at_keyboard minicmd"

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
mkdir -p "$ROOT"/bootpart/system
cp "$ROOT"/rootfs.squashfs "$ROOT"/bootpart/system/rootfs.squashfs

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
timeout=3

terminal_output --append console
terminal_input --append console

insmod serial
serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1
terminal_output --append serial
terminal_input --append serial

insmod font
font="/boot/grub/unicode.pf2"
if loadfont \$font ; then
  set gfxmode=auto
  insmod all_video
  insmod gfxterm
  set locale_dir=\$prefix/locale
  set lang=en_US
  insmod gettext
  terminal_output --append gfxterm
  terminal_output --remove console
else
  echo "Font load failed"
fi

fallback="1"

insmod part_gpt
insmod part_msdos
insmod fat
insmod acpi
insmod loadenv
insmod test

if [ -s \$prefix/grubenv ]; then
  set have_grubenv=true
  load_env
fi
if [ "\${next_entry}" ] ; then
   set default="\${next_entry}"
   set next_entry=
   save_env next_entry
   set boot_once=true
else
   set default="0"
fi

if [ "\${prev_saved_entry}" ]; then
  set saved_entry="\${prev_saved_entry}"
  save_env saved_entry
  set prev_saved_entry=
  save_env prev_saved_entry
  set boot_once=true
fi

function savedefault {
  if [ -z "\${boot_once}" ]; then
    saved_entry="\${chosen}"
    save_env saved_entry
  fi
}

insmod linux
insmod gzio
insmod xzio
insmod lzopio

menuentry "Debian" {
    savedefault

    search --no-floppy --file --set=root /boot/grub/grub.cfg
    set gfxpayload=keep
    
    echo 'Loading Linux...'
    linux /boot/$KERNEL_FILENAME $KERNEL_ARGS_FAST $KERNEL_ARGS_LIVE $KERNEL_ARGS_MISC $KERNEL_ARGS_NORM
    echo 'Loading initramfs...'
    initrd /boot/$INITRD_FILENAME
    
    boot
}

menuentry "Debian (load to system memory)" {
    savedefault

    search --no-floppy --file --set=root /boot/grub/grub.cfg
    set gfxpayload=keep
    
    echo 'Loading Linux...'
    linux /boot/$KERNEL_FILENAME $KERNEL_ARGS_FAST $KERNEL_ARGS_LIVE toram $KERNEL_ARGS_MISC $KERNEL_ARGS_NORM
    echo 'Loading initramfs...'
    initrd /boot/$INITRD_FILENAME
    
    boot
}

menuentry "Debian (single user mode)" {
    search --no-floppy --file --set=root /boot/grub/grub.cfg
    set gfxpayload=keep
    
    echo 'Loading Linux...'
    linux /boot/$KERNEL_FILENAME single $KERNEL_ARGS_FAST $KERNEL_ARGS_LIVE $KERNEL_ARGS_MISC
    echo 'Loading initramfs...'
    initrd /boot/$INITRD_FILENAME
    
    boot
}

menuentry "Verify file integrity" {
    search --no-floppy --file --set=root /boot/grub/grub.cfg
    set gfxpayload=keep
    
    echo 'Loading Linux...'
    linux /boot/$KERNEL_FILENAME verify-checksums $KERNEL_ARGS_FAST $KERNEL_ARGS_LIVE $KERNEL_ARGS_MISC
    echo 'Loading initramfs...'
    initrd /boot/$INITRD_FILENAME
    
    boot
}

submenu 'Advanced boot' {
    menuentry 'Boot from next partition' {
        insmod chain
        chainloader +1
    }

    menuentry 'UEFI firmware setup' {
        fwsetup
    }

    menuentry 'Reboot' {
        insmod reboot
        reboot
    }

    menuentry 'Poweroff' {
        insmod halt
        halt
    }
}
EOF

cp grub/earlyconfig.cfg "$ROOT"/bootpart/EFI/BOOT/grub.cfg
# workaround GRUB2 legacy modules missing
cp -r /usr/lib/grub/i386-pc "$ROOT"/bootpart/boot/grub/i386-pc
# Unicode font
cp /usr/share/grub/unicode.pf2 "$ROOT"/bootpart/boot/grub/unicode.pf2

# calculate checksums
pushd "$ROOT"/bootpart
rm -f md5sum.txt
find . ! -name 'md5sum.txt' ! -name 'grubenv' -exec md5sum {} \; 2>/dev/null | tee md5sum.txt
popd

# clean up
umount "$ROOT"/bootpart
losetup -d /dev/loop0

ls -alh "$ROOT"/"$IMAGE"
